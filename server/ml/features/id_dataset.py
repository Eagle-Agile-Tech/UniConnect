"""Dataset helpers for ID-based two-tower training."""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any


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
        return [data]
    except json.JSONDecodeError:
        rows_out: list[dict[str, Any]] = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            rows_out.append(json.loads(line))
        return rows_out


def row_to_training_example(row: dict[str, Any]) -> dict[str, Any] | None:
    user_id = str(row.get("userId") or "").strip()
    target_id = str(row.get("targetId") or "").strip()
    target_type = str(row.get("targetType") or "").strip().upper()
    if not user_id or not target_id or not target_type:
        return None

    try:
        label = float(row.get("label", 0) or 0)
    except Exception:
        label = 0.0

    return {
        "user_id": user_id,
        "item_id": f"{target_type}::{target_id}",
        "label": 1.0 if label > 0 else 0.0,
        "target_type": target_type,
        "target_id": target_id,
    }


def load_training_examples(path: str | Path, shuffle: bool = True) -> list[dict[str, Any]]:
    rows = load_rows(path)
    examples = []
    for row in rows:
        example = row_to_training_example(row)
        if example is not None:
            examples.append(example)

    if shuffle:
        random.shuffle(examples)

    return examples


def balance_training_examples(
    examples: list[dict[str, Any]],
    seed: int | None = 42,
) -> list[dict[str, Any]]:
    """Return a class-balanced copy of binary training examples."""
    positives = [example for example in examples if float(example.get("label", 0) or 0) > 0]
    negatives = [example for example in examples if float(example.get("label", 0) or 0) <= 0]

    if not positives or not negatives:
        return examples

    target = min(len(positives), len(negatives))
    if target <= 0:
        return examples

    rng = random.Random(seed)
    positives_sample = positives[:]
    negatives_sample = negatives[:]
    rng.shuffle(positives_sample)
    rng.shuffle(negatives_sample)

    balanced = positives_sample[:target] + negatives_sample[:target]
    rng.shuffle(balanced)
    return balanced


def build_id_mappings(
    examples: list[dict[str, Any]],
) -> tuple[dict[str, int], dict[str, int]]:
    user_ids = sorted({example["user_id"] for example in examples})
    item_ids = sorted({example["item_id"] for example in examples})
    user_to_index = {user_id: index for index, user_id in enumerate(user_ids)}
    item_to_index = {item_id: index for index, item_id in enumerate(item_ids)}
    return user_to_index, item_to_index
