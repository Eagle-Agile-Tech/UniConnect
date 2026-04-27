#!/usr/bin/env python3
"""Deterministically split a dataset into train/test files.

Supported strategies:
- `user`: user-held-out split. All rows for a user live in only one split.
- `warm-user`: each eligible user appears in both splits, with later rows held
  out for test. This is useful for warm-start evaluation of ID-based models.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime
import hashlib
import json
from pathlib import Path

from ml.pipelines.dataset_provenance import load_rows


def iter_jsonl_rows(path: Path):
    yield from load_rows(path)


def stable_bucket(user_id: str, seed: str) -> float:
    h = hashlib.sha256(f"{seed}::{user_id}".encode("utf-8")).hexdigest()
    # Use 48 bits to get a stable uniform-ish float in [0,1).
    n = int(h[:12], 16)
    return n / float(16**12)


def parse_row_time(row: dict) -> tuple[int, str]:
    for key in ("latestInteractionAt", "lastInteractionAt", "createdAt", "firstInteractionAt"):
        raw = str(row.get(key) or "").strip()
        if not raw:
            continue
        try:
            parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
            return (int(parsed.timestamp()), raw)
        except Exception:
            continue
    fallback = json.dumps(row, sort_keys=True)
    digest = hashlib.sha256(fallback.encode("utf-8")).hexdigest()
    return (0, digest)


def split_user_held_out(rows: list[dict], test_ratio: float, seed: str) -> tuple[list[dict], list[dict], dict]:
    train_rows: list[dict] = []
    test_rows: list[dict] = []
    train_users: set[str] = set()
    test_users: set[str] = set()

    for row in rows:
        user_id = str(row.get("userId") or "").strip()
        if not user_id:
            continue
        bucket = stable_bucket(user_id, seed)
        is_test = bucket < test_ratio
        if is_test:
            test_rows.append(row)
            test_users.add(user_id)
        else:
            train_rows.append(row)
            train_users.add(user_id)

    return train_rows, test_rows, {
        "train_users": len(train_users),
        "test_users": len(test_users),
        "warm_start_users": 0,
    }


def split_warm_user(rows: list[dict], test_ratio: float) -> tuple[list[dict], list[dict], dict]:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        user_id = str(row.get("userId") or "").strip()
        if user_id:
            grouped[user_id].append(row)

    train_rows: list[dict] = []
    test_rows: list[dict] = []
    train_users: set[str] = set()
    test_users: set[str] = set()
    warm_start_users = 0

    for user_id, user_rows in grouped.items():
        ordered = sorted(user_rows, key=parse_row_time)
        if len(ordered) < 2:
            train_rows.extend(ordered)
            train_users.add(user_id)
            continue

        test_count = max(1, int(round(len(ordered) * test_ratio)))
        test_count = min(test_count, len(ordered) - 1)
        split_at = len(ordered) - test_count
        train_slice = ordered[:split_at]
        test_slice = ordered[split_at:]

        train_rows.extend(train_slice)
        test_rows.extend(test_slice)
        train_users.add(user_id)
        test_users.add(user_id)
        warm_start_users += 1

    return train_rows, test_rows, {
        "train_users": len(train_users),
        "test_users": len(test_users),
        "warm_start_users": warm_start_users,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=str, help="Input JSONL path")
    ap.add_argument("--out-train", required=True, type=str, help="Output train JSONL")
    ap.add_argument("--out-test", required=True, type=str, help="Output test JSONL")
    ap.add_argument("--test-ratio", type=float, default=0.2)
    ap.add_argument("--seed", type=str, default="42")
    ap.add_argument(
        "--strategy",
        type=str,
        default="user",
        choices=("user", "warm-user"),
        help="Split strategy: user-held-out or warm-start user split.",
    )
    args = ap.parse_args()

    in_path = Path(args.data)
    out_train = Path(args.out_train)
    out_test = Path(args.out_test)

    test_ratio = float(args.test_ratio)
    if not (0.0 < test_ratio < 1.0):
        raise SystemExit("--test-ratio must be between 0 and 1")

    out_train.parent.mkdir(parents=True, exist_ok=True)
    out_test.parent.mkdir(parents=True, exist_ok=True)

    rows = list(iter_jsonl_rows(in_path))
    if args.strategy == "warm-user":
        train_rows_data, test_rows_data, summary = split_warm_user(rows, test_ratio)
    else:
        train_rows_data, test_rows_data, summary = split_user_held_out(rows, test_ratio, args.seed)

    with out_train.open("w", encoding="utf-8") as train_h, out_test.open(
        "w", encoding="utf-8"
    ) as test_h:
        for row in train_rows_data:
            train_h.write(json.dumps(row) + "\n")
        for row in test_rows_data:
            test_h.write(json.dumps(row) + "\n")

    print(
        json.dumps(
            {
                "input": str(in_path.resolve()),
                "out_train": str(out_train.resolve()),
                "out_test": str(out_test.resolve()),
                "strategy": args.strategy,
                "test_ratio": test_ratio,
                "seed": args.seed,
                "train_rows": len(train_rows_data),
                "test_rows": len(test_rows_data),
                "train_users": summary["train_users"],
                "test_users": summary["test_users"],
                "warm_start_users": summary["warm_start_users"],
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
