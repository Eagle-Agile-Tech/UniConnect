"""Load training rows from JSON (envelope) or JSONL."""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any

from ml.features.feature_text import row_to_pair


def load_rows(path: str | Path) -> list[dict[str, Any]]:
    p = Path(path)
    text = p.read_text(encoding="utf-8").strip()
    if not text:
        return []

    try:
        data = json.loads(text)
        if isinstance(data, dict) and "rows" in data:
            rows = data["rows"]
            return rows if isinstance(rows, list) else []
        if isinstance(data, list):
            return data
        # If it's a single object, wrap in list
        return [data]
    except json.JSONDecodeError:
        # Assume JSONL
        rows_out: list[dict[str, Any]] = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            rows_out.append(json.loads(line))
        return rows_out


def load_training_pairs(
    path: str | Path,
    negatives_per_positive: int = 3,
    hard_negative_ratio: float = 0.67,
    balance_classes: bool = True,
    balance_seed: int | None = 42,
) -> tuple[list[str], list[str], list[float], list[str], list[str]]:
    raw = load_rows(path)
    raw = augment_negative_rows(
        raw,
        negatives_per_positive=negatives_per_positive,
        hard_negative_ratio=hard_negative_ratio,
    )
    if balance_classes:
        raw = balance_binary_rows(raw, seed=balance_seed)
    user_texts: list[str] = []
    item_texts: list[str] = []
    labels: list[float] = []
    user_ids: list[str] = []
    item_keys: list[str] = []
    for row in raw:
        pair = row_to_pair(row)
        if pair is None:
            continue
        u, v, lab = pair
        user_id = str(row.get("userId") or "")
        item_id = str(row.get("targetId") or "")
        item_type = str(row.get("targetType") or "")
        if not user_id or not item_id or not item_type:
            continue
        user_texts.append(u)
        item_texts.append(v)
        labels.append(lab)
        user_ids.append(user_id)
        item_keys.append(f"{item_type}::{item_id}")
    return user_texts, item_texts, labels, user_ids, item_keys


def balance_binary_rows(
    rows: list[dict[str, Any]],
    seed: int | None = 42,
) -> list[dict[str, Any]]:
    """Return a class-balanced copy of rows with equal positive and negative counts."""
    positives = [row for row in rows if float(row.get("label", 0) or 0) > 0]
    negatives = [row for row in rows if float(row.get("label", 0) or 0) <= 0]

    if not positives or not negatives:
        return rows

    target = min(len(positives), len(negatives))
    if target <= 0:
        return rows

    rng = random.Random(seed)
    positives_sample = positives[:]
    negatives_sample = negatives[:]
    rng.shuffle(positives_sample)
    rng.shuffle(negatives_sample)

    balanced = positives_sample[:target] + negatives_sample[:target]
    rng.shuffle(balanced)
    return balanced


TOKEN_RE = re.compile(r"[a-z0-9]+")


def _tokenize(values: list[object]) -> set[str]:
    tokens: set[str] = set()
    for value in values:
        if value is None:
            continue
        if isinstance(value, list):
            for item in value:
                tokens.update(_tokenize([item]))
            continue
        for token in TOKEN_RE.findall(str(value).lower()):
            if len(token) > 1:
                tokens.add(token)
    return tokens


def _user_tokens(row: dict[str, Any]) -> set[str]:
    features = row.get("userFeatures")
    if not isinstance(features, dict):
        return set()
    return _tokenize([features.get("interests"), features.get("skills")])


def _target_tokens(row: dict[str, Any]) -> set[str]:
    features = row.get("targetFeatures")
    if not isinstance(features, dict):
        return set()
    return _tokenize(
        [
            row.get("targetType"),
            features.get("type"),
            features.get("title"),
            features.get("description"),
            features.get("content"),
            features.get("tags"),
            features.get("category"),
            features.get("university"),
        ]
    )


def _candidate_score(user_tokens: set[str], target_tokens: set[str]) -> tuple[int, int]:
    overlap = len(user_tokens & target_tokens)
    return overlap, len(target_tokens)


def augment_negative_rows(
    rows: list[dict[str, Any]],
    negatives_per_positive: int = 3,
    hard_negative_ratio: float = 0.67,
) -> list[dict[str, Any]]:
    """
    Preserve existing labels and add extra negatives for each positive pair.
    Hard negatives come from same-type items whose metadata overlaps user interests/skills.
    """
    if not rows or negatives_per_positive <= 0:
        return rows

    by_type: dict[str, list[dict[str, Any]]] = {}
    seen_by_user_type: dict[tuple[str, str], set[str]] = {}
    for row in rows:
        t = str(row.get("targetType") or "")
        target_id = str(row.get("targetId") or "")
        user_id = str(row.get("userId") or "")
        if not t or not target_id or not user_id:
            continue
        by_type.setdefault(t, []).append(row)
        seen_by_user_type.setdefault((user_id, t), set()).add(target_id)

    negatives: list[dict[str, Any]] = []
    hard_negative_ratio = min(max(hard_negative_ratio, 0.0), 1.0)
    for row in rows:
        if float(row.get("label", 0) or 0) <= 0:
            continue
        t = str(row.get("targetType") or "")
        user_id = str(row.get("userId") or "")
        target_id = str(row.get("targetId") or "")
        if not t or not user_id or not target_id:
            continue
        pool = by_type.get(t, [])
        if len(pool) < 2:
            continue
        seen = seen_by_user_type.get((user_id, t), set())
        user_tokens = _user_tokens(row)
        candidates: list[tuple[tuple[int, int], dict[str, Any], str]] = []
        fallback: list[tuple[dict[str, Any], str]] = []
        for candidate in pool:
            candidate_id = str(candidate.get("targetId") or "")
            if not candidate_id or candidate_id in seen:
                continue
            fallback.append((candidate, candidate_id))
            score = _candidate_score(user_tokens, _target_tokens(candidate))
            candidates.append((score, candidate, candidate_id))

        if not fallback:
            continue

        candidates.sort(key=lambda entry: entry[0], reverse=True)
        hard_target = min(len(candidates), round(negatives_per_positive * hard_negative_ratio))
        selected_ids: set[str] = set()
        selected_candidates: list[tuple[dict[str, Any], str]] = []

        for score, candidate, candidate_id in candidates:
            if len(selected_candidates) >= hard_target:
                break
            if candidate_id in selected_ids:
                continue
            # Require some token signal for a negative to count as "hard".
            if score[0] <= 0:
                continue
            selected_candidates.append((candidate, candidate_id))
            selected_ids.add(candidate_id)

        random.shuffle(fallback)
        for candidate, candidate_id in fallback:
            if len(selected_candidates) >= negatives_per_positive:
                break
            if candidate_id in selected_ids:
                continue
            selected_candidates.append((candidate, candidate_id))
            selected_ids.add(candidate_id)

        for candidate, candidate_id in selected_candidates:
            neg = {
                "userId": user_id,
                "targetId": candidate_id,
                "targetType": t,
                "label": 0,
                "totalScore": 0,
                "interactionBreakdown": {},
                "latestInteractionAt": row.get("latestInteractionAt"),
                "userFeatures": row.get("userFeatures"),
                "targetFeatures": candidate.get("targetFeatures"),
            }
            negatives.append(neg)
            seen.add(candidate_id)

    return rows + negatives
