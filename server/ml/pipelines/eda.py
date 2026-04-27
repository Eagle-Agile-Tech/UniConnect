#!/usr/bin/env python3
"""Lightweight EDA over recommendation training JSONL.

Computes summary stats and (optionally) saves a few plots if matplotlib exists.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def iter_jsonl_rows(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            yield json.loads(line)


def safe_int(value, default=0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=str, help="Input JSONL path")
    ap.add_argument("--out-dir", required=True, type=str, help="Directory for outputs")
    ap.add_argument("--max-rows", type=int, default=0, help="0 means all rows")
    args = ap.parse_args()

    in_path = Path(args.data)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    total_rows = 0
    label_counts = Counter()
    type_counts = Counter()
    users = set()
    items = set()
    interactions = Counter()
    positives_per_user = Counter()

    for row in iter_jsonl_rows(in_path):
        total_rows += 1
        if args.max_rows and total_rows >= args.max_rows:
            break

        uid = str(row.get("userId") or "").strip()
        tid = str(row.get("targetId") or "").strip()
        ttype = str(row.get("targetType") or "").strip().upper()
        if uid:
            users.add(uid)
        if tid and ttype:
            items.add(f"{ttype}::{tid}")

        label = 1 if float(row.get("label", 0) or 0) > 0 else 0
        label_counts[str(label)] += 1
        if ttype:
            type_counts[ttype] += 1

        breakdown = row.get("interactionBreakdown")
        if isinstance(breakdown, dict):
            for k, v in breakdown.items():
                interactions[str(k).upper()] += safe_int(v, 0)

        if uid and label == 1:
            positives_per_user[uid] += 1

    positive_rows = label_counts.get("1", 0)
    negative_rows = label_counts.get("0", 0)
    pos_rate = positive_rows / float(max(1, total_rows))

    summary = {
        "data": str(in_path.resolve()),
        "rows": total_rows,
        "users": len(users),
        "items": len(items),
        "positive_rows": positive_rows,
        "negative_rows": negative_rows,
        "positive_rate": round(pos_rate, 6),
        "target_type_counts": dict(type_counts),
        "interaction_breakdown_counts": dict(interactions),
        "positives_per_user": {
            "min": min(positives_per_user.values() or [0]),
            "p50": 0,
            "p90": 0,
            "max": max(positives_per_user.values() or [0]),
        },
    }

    # Compute a few percentiles without extra deps.
    if positives_per_user:
        vals = sorted(positives_per_user.values())
        def pct(p: float) -> int:
            i = int(round((len(vals) - 1) * p))
            return int(vals[max(0, min(len(vals) - 1, i))])
        summary["positives_per_user"]["p50"] = pct(0.50)
        summary["positives_per_user"]["p90"] = pct(0.90)

    (out_dir / "eda_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    # Optional plots.
    try:
        import matplotlib.pyplot as plt  # type: ignore
    except Exception:
        (out_dir / "plots_skipped.txt").write_text(
            "matplotlib not available; skipping plots\n", encoding="utf-8"
        )
        print(json.dumps(summary, indent=2))
        return

    # Target type bar chart.
    if type_counts:
        labels = list(type_counts.keys())
        values = [type_counts[k] for k in labels]
        plt.figure(figsize=(7, 4))
        plt.bar(labels, values)
        plt.title("Rows by targetType")
        plt.xlabel("targetType")
        plt.ylabel("rows")
        plt.tight_layout()
        plt.savefig(out_dir / "rows_by_target_type.png", dpi=160)
        plt.close()

    # Label distribution.
    plt.figure(figsize=(6, 4))
    plt.bar(["0", "1"], [negative_rows, positive_rows])
    plt.title("Label distribution")
    plt.xlabel("label")
    plt.ylabel("rows")
    plt.tight_layout()
    plt.savefig(out_dir / "label_distribution.png", dpi=160)
    plt.close()

    # Positives per user histogram.
    if positives_per_user:
        vals = list(positives_per_user.values())
        plt.figure(figsize=(7, 4))
        plt.hist(vals, bins=30)
        plt.title("Positives per user (hist)")
        plt.xlabel("positive rows per user")
        plt.ylabel("users")
        plt.tight_layout()
        plt.savefig(out_dir / "positives_per_user_hist.png", dpi=160)
        plt.close()

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()

