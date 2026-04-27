#!/usr/bin/env python3
"""Helpers for dataset provenance and checkpoint/eval hygiene."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


def load_rows(path: str | Path) -> list[dict[str, Any]]:
    source = Path(path).expanduser().resolve()
    text = source.read_text(encoding="utf-8").strip()
    if not text:
        return []

    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        rows: list[dict[str, Any]] = []
        for line in text.splitlines():
            line = line.strip()
            if line:
                rows.append(json.loads(line))
        return rows

    if isinstance(parsed, dict) and isinstance(parsed.get("rows"), list):
        return list(parsed["rows"])
    if isinstance(parsed, list):
        return list(parsed)
    if isinstance(parsed, dict):
        return [parsed]
    return []


def _stable_target_key(row: dict[str, Any]) -> str | None:
    target_type = str(row.get("targetType") or "").strip().upper()
    target_id = str(row.get("targetId") or "").strip()
    if not target_type or not target_id:
        return None
    return f"{target_type}::{target_id}"


def summarize_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    user_ids = sorted({str(row.get("userId") or "").strip() for row in rows if str(row.get("userId") or "").strip()})
    item_keys = sorted({key for row in rows if (key := _stable_target_key(row))})
    target_types = sorted({str(row.get("targetType") or "").strip().upper() for row in rows if str(row.get("targetType") or "").strip()})
    return {
        "rows": len(rows),
        "uniqueUsers": len(user_ids),
        "uniqueItems": len(item_keys),
        "targetTypes": target_types,
        "userIds": user_ids,
        "itemKeys": item_keys,
    }


def fingerprint_rows(rows: list[dict[str, Any]]) -> str:
    canonical_lines = [
        json.dumps(row, sort_keys=True, ensure_ascii=True, separators=(",", ":"))
        for row in rows
    ]
    payload = "\n".join(canonical_lines).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def infer_split_info_path(data_path: str | Path) -> Path | None:
    source = Path(data_path).expanduser().resolve()
    candidate = source.parent / "split_info.json"
    return candidate if candidate.exists() else None


def build_dataset_provenance(data_path: str | Path) -> dict[str, Any]:
    source = Path(data_path).expanduser().resolve()
    rows = load_rows(source)
    summary = summarize_rows(rows)
    split_info_path = infer_split_info_path(source)
    split_info = None
    if split_info_path is not None:
        try:
            split_info = json.loads(split_info_path.read_text(encoding="utf-8"))
        except Exception:
            split_info = None

    return {
        "path": str(source),
        "fileName": source.name,
        "sha256": fingerprint_rows(rows),
        "rows": summary["rows"],
        "uniqueUsers": summary["uniqueUsers"],
        "uniqueItems": summary["uniqueItems"],
        "targetTypes": summary["targetTypes"],
        "splitInfoPath": str(split_info_path) if split_info_path else None,
        "splitInfo": split_info,
    }


def evaluate_mapping_overlap(
    rows: list[dict[str, Any]],
    *,
    user_ids: set[str] | None = None,
    item_keys: set[str] | None = None,
) -> dict[str, Any]:
    user_ids = user_ids or set()
    item_keys = item_keys or set()

    row_user_hits = 0
    row_item_hits = 0
    row_pair_hits = 0
    dataset_users = set()
    dataset_items = set()

    for row in rows:
        uid = str(row.get("userId") or "").strip()
        item_key = _stable_target_key(row)
        if uid:
            dataset_users.add(uid)
        if item_key:
            dataset_items.add(item_key)
        if uid and uid in user_ids:
            row_user_hits += 1
        if item_key and item_key in item_keys:
            row_item_hits += 1
        if uid and item_key and uid in user_ids and item_key in item_keys:
            row_pair_hits += 1

    user_overlap = len(dataset_users & user_ids) if user_ids else 0
    item_overlap = len(dataset_items & item_keys) if item_keys else 0

    return {
        "datasetUsers": len(dataset_users),
        "datasetItems": len(dataset_items),
        "checkpointUsers": len(user_ids),
        "checkpointItems": len(item_keys),
        "overlapUsers": user_overlap,
        "overlapItems": item_overlap,
        "rowUserHits": row_user_hits,
        "rowItemHits": row_item_hits,
        "rowPairHits": row_pair_hits,
    }
