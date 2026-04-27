#!/usr/bin/env python3
"""Lightweight EDA + train/test split for recommendation training datasets.

Reads JSONL rows produced by the API training dataset exporter.
Avoids heavy dependencies: generates simple SVG charts directly.
"""

from __future__ import annotations

import argparse
import json
import math
import random
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable


def iter_jsonl(path: str | Path) -> Iterable[dict[str, Any]]:
    p = Path(path)
    with p.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            yield json.loads(line)


def safe_float(value: object, default: float = 0.0) -> float:
    try:
        return float(value)  # type: ignore[arg-type]
    except Exception:
        return default


def safe_str(value: object) -> str:
    return str(value) if value is not None else ""


def parse_iso_date(value: object) -> str:
    """Return YYYY-MM-DD for a value that may be ISO string, else empty string."""
    if not value:
        return ""
    s = safe_str(value).strip()
    if not s:
        return ""
    try:
        # Handles '2026-04-22T06:32:42.591Z' and similar.
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        return dt.date().isoformat()
    except Exception:
        # Fallback: try first 10 chars if it looks like YYYY-MM-DD...
        if len(s) >= 10 and s[4] == "-" and s[7] == "-":
            return s[:10]
        return ""


def quantiles(values: list[int], qs: list[float]) -> dict[str, float]:
    if not values:
        return {f"q{int(q*100)}": 0.0 for q in qs}
    values_sorted = sorted(values)
    n = len(values_sorted)
    out: dict[str, float] = {}
    for q in qs:
        q = min(max(q, 0.0), 1.0)
        idx = int(round(q * (n - 1)))
        out[f"q{int(q*100)}"] = float(values_sorted[idx])
    return out


def svg_bar_chart(
    title: str,
    labels: list[str],
    values: list[int],
    out_path: Path,
    width: int = 900,
    height: int = 420,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if not labels or not values or len(labels) != len(values):
        out_path.write_text("<svg xmlns='http://www.w3.org/2000/svg'></svg>\n", encoding="utf-8")
        return

    max_v = max(values) if values else 1
    max_v = max(max_v, 1)
    pad_l, pad_r, pad_t, pad_b = 70, 30, 60, 90
    plot_w = max(10, width - pad_l - pad_r)
    plot_h = max(10, height - pad_t - pad_b)

    n = len(values)
    gap = 10
    bar_w = max(6, int((plot_w - gap * (n - 1)) / max(n, 1)))
    total_w = n * bar_w + gap * (n - 1)
    x0 = pad_l + max(0, (plot_w - total_w) // 2)

    def esc(s: str) -> str:
        return (
            s.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;")
        )

    # Basic, readable styling.
    parts: list[str] = []
    parts.append(f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}'>")
    parts.append("<rect x='0' y='0' width='100%' height='100%' fill='#ffffff'/>")
    parts.append(
        f"<text x='{width//2}' y='32' text-anchor='middle' "
        "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
        "font-size='18' fill='#111827'>"
        f"{esc(title)}</text>"
    )

    # Axes
    parts.append(f"<line x1='{pad_l}' y1='{pad_t}' x2='{pad_l}' y2='{pad_t+plot_h}' stroke='#111827' stroke-width='1'/>")
    parts.append(f"<line x1='{pad_l}' y1='{pad_t+plot_h}' x2='{pad_l+plot_w}' y2='{pad_t+plot_h}' stroke='#111827' stroke-width='1'/>")

    # Y ticks (0, 25%, 50%, 75%, 100%)
    for frac in [0.0, 0.25, 0.5, 0.75, 1.0]:
        y = pad_t + plot_h - int(frac * plot_h)
        v = int(round(frac * max_v))
        parts.append(f"<line x1='{pad_l-6}' y1='{y}' x2='{pad_l}' y2='{y}' stroke='#111827' stroke-width='1'/>")
        parts.append(
            f"<text x='{pad_l-10}' y='{y+4}' text-anchor='end' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='12' fill='#111827'>"
            f"{v}</text>"
        )
        parts.append(f"<line x1='{pad_l}' y1='{y}' x2='{pad_l+plot_w}' y2='{y}' stroke='#e5e7eb' stroke-width='1'/>")

    # Bars + labels
    for i, (lab, val) in enumerate(zip(labels, values)):
        h = int(round((val / max_v) * plot_h))
        x = x0 + i * (bar_w + gap)
        y = pad_t + plot_h - h
        parts.append(f"<rect x='{x}' y='{y}' width='{bar_w}' height='{h}' fill='#2563eb' opacity='0.9'/>")

        # value on top (only if it fits reasonably)
        parts.append(
            f"<text x='{x + bar_w/2:.1f}' y='{max(pad_t+12, y-6)}' text-anchor='middle' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='11' fill='#111827'>"
            f"{val}</text>"
        )

        # x label (rotated)
        parts.append(
            f"<g transform='translate({x + bar_w/2:.1f},{pad_t+plot_h+12}) rotate(35)'>"
            "<text text-anchor='start' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='12' fill='#111827'>"
            f"{esc(lab)}</text></g>"
        )

    parts.append("</svg>")
    out_path.write_text("\n".join(parts) + "\n", encoding="utf-8")


def svg_line_chart(
    title: str,
    labels: list[str],
    values: list[float],
    out_path: Path,
    width: int = 900,
    height: int = 420,
    y_label: str = "",
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if not labels or not values or len(labels) != len(values):
        out_path.write_text("<svg xmlns='http://www.w3.org/2000/svg'></svg>\n", encoding="utf-8")
        return

    max_v = max(values)
    min_v = min(values)
    if max_v == min_v:
        max_v = min_v + 1.0

    pad_l, pad_r, pad_t, pad_b = 70, 30, 60, 90
    plot_w = max(10, width - pad_l - pad_r)
    plot_h = max(10, height - pad_t - pad_b)
    n = len(values)
    step = plot_w / max(n - 1, 1)

    def esc(s: str) -> str:
        return (
            s.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;")
        )

    def scale(v: float) -> float:
        return pad_t + plot_h - ((v - min_v) / (max_v - min_v)) * plot_h

    points = []
    for i, v in enumerate(values):
        x = pad_l + i * step
        y = scale(v)
        points.append((x, y))

    parts: list[str] = []
    parts.append(f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}'>")
    parts.append("<rect x='0' y='0' width='100%' height='100%' fill='#ffffff'/>")
    parts.append(
        f"<text x='{width//2}' y='32' text-anchor='middle' "
        "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
        "font-size='18' fill='#111827'>"
        f"{esc(title)}</text>"
    )

    parts.append(f"<line x1='{pad_l}' y1='{pad_t}' x2='{pad_l}' y2='{pad_t+plot_h}' stroke='#111827' stroke-width='1'/>")
    parts.append(f"<line x1='{pad_l}' y1='{pad_t+plot_h}' x2='{pad_l+plot_w}' y2='{pad_t+plot_h}' stroke='#111827' stroke-width='1'/>")

    for frac in [0.0, 0.25, 0.5, 0.75, 1.0]:
        y = pad_t + plot_h - int(frac * plot_h)
        val = min_v + frac * (max_v - min_v)
        parts.append(f"<line x1='{pad_l-6}' y1='{y}' x2='{pad_l}' y2='{y}' stroke='#111827' stroke-width='1'/>")
        parts.append(
            f"<text x='{pad_l-10}' y='{y+4}' text-anchor='end' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='12' fill='#111827'>"
            f"{val:.2f}</text>"
        )
        parts.append(f"<line x1='{pad_l}' y1='{y}' x2='{pad_l+plot_w}' y2='{y}' stroke='#e5e7eb' stroke-width='1'/>")

    if y_label:
        parts.append(
            f"<text x='{18}' y='{pad_t + plot_h/2:.1f}' transform='rotate(-90 18 {pad_t + plot_h/2:.1f})' "
            "text-anchor='middle' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='12' fill='#111827'>"
            f"{esc(y_label)}</text>"
        )

    polyline = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    parts.append(
        f"<polyline fill='none' stroke='#2563eb' stroke-width='3' points='{polyline}'/>"
    )

    for i, (lab, val) in enumerate(zip(labels, values)):
        x, y = points[i]
        parts.append(f"<circle cx='{x:.1f}' cy='{y:.1f}' r='4.5' fill='#1d4ed8'/>")
        parts.append(
            f"<text x='{x:.1f}' y='{max(pad_t+12, y-8):.1f}' text-anchor='middle' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='11' fill='#111827'>"
            f"{val:.2f}</text>"
        )
        if n <= 15 or i % max(1, n // 10) == 0 or i == n - 1:
            parts.append(
                f"<g transform='translate({x:.1f},{pad_t+plot_h+12}) rotate(35)'>"
                "<text text-anchor='start' "
                "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
                "font-size='12' fill='#111827'>"
                f"{esc(lab)}</text></g>"
            )

    parts.append("</svg>")
    out_path.write_text("\n".join(parts) + "\n", encoding="utf-8")


def split_users(
    user_ids: list[str],
    test_ratio: float,
    seed: int,
) -> tuple[set[str], set[str]]:
    unique = sorted({u for u in user_ids if u})
    rng = random.Random(seed)
    rng.shuffle(unique)
    n_test = int(round(len(unique) * min(max(test_ratio, 0.0), 1.0)))
    test_users = set(unique[:n_test])
    train_users = set(unique[n_test:])
    return train_users, test_users


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=str, help="Path to dataset JSONL")
    ap.add_argument("--out-dir", required=True, type=str, help="Directory for outputs")
    ap.add_argument("--max-rows", type=int, default=0, help="Optional cap for faster EDA (0=all)")
    ap.add_argument("--split", action="store_true", help="Write train/test split JSONL files")
    ap.add_argument("--test-ratio", type=float, default=0.2)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    data_path = Path(args.data)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    total_rows = 0
    pos_rows = 0
    neg_rows = 0
    target_type_counts: Counter[str] = Counter()
    day_counts: Counter[str] = Counter()
    day_pos_counts: Counter[str] = Counter()
    day_neg_counts: Counter[str] = Counter()

    # Basic per-user and per-item stats (positives only)
    pos_by_user: Counter[str] = Counter()
    pos_by_item: Counter[str] = Counter()

    # Split helpers
    all_user_ids: list[str] = []

    for row in iter_jsonl(data_path):
        total_rows += 1
        if args.max_rows and total_rows > args.max_rows:
            break

        uid = safe_str(row.get("userId")).strip()
        ttype = safe_str(row.get("targetType")).strip().upper()
        tid = safe_str(row.get("targetId")).strip()
        lab = safe_float(row.get("label", 0.0), 0.0)

        all_user_ids.append(uid)
        if ttype:
            target_type_counts[ttype] += 1

        day = parse_iso_date(row.get("latestInteractionAt") or row.get("createdAt"))
        if day:
            day_counts[day] += 1

        if lab > 0:
            pos_rows += 1
            if day:
                day_pos_counts[day] += 1
            if uid:
                pos_by_user[uid] += 1
            if ttype and tid:
                pos_by_item[f"{ttype}::{tid}"] += 1
        else:
            neg_rows += 1
            if day:
                day_neg_counts[day] += 1

    users = sorted({u for u in all_user_ids if u})
    pos_counts_per_user = [pos_by_user[u] for u in users]

    summary = {
        "generatedAt": datetime.now().astimezone().isoformat(timespec="seconds"),
        "sourceDataset": str(data_path.resolve()),
        "rows": {
            "total": total_rows,
            "positive": pos_rows,
            "negative": neg_rows,
            "positiveRate": (pos_rows / total_rows) if total_rows else 0.0,
        },
        "users": {
            "uniqueUsers": len(users),
            "usersWithPositive": len([u for u in users if pos_by_user[u] > 0]),
            "positivesPerUser": {
                "min": int(min(pos_counts_per_user)) if pos_counts_per_user else 0,
                "mean": (sum(pos_counts_per_user) / len(pos_counts_per_user))
                if pos_counts_per_user
                else 0.0,
                "max": int(max(pos_counts_per_user)) if pos_counts_per_user else 0,
                **quantiles(pos_counts_per_user, [0.5, 0.9, 0.95, 0.99]),
            },
        },
        "targets": {
            "uniqueItems": len(pos_by_item),
            "targetTypeCounts": dict(target_type_counts),
        },
        "time": {
            "distinctDays": len(day_counts),
            "minDay": min(day_counts.keys()) if day_counts else "",
            "maxDay": max(day_counts.keys()) if day_counts else "",
        },
    }

    (out_dir / "eda_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    # Charts
    if target_type_counts:
        labels = list(target_type_counts.keys())
        values = [int(target_type_counts[k]) for k in labels]
        svg_bar_chart("Rows by Target Type", labels, values, out_dir / "rows_by_target_type.svg")

    svg_bar_chart(
        "Label Distribution",
        ["negative (0)", "positive (1)"],
        [int(neg_rows), int(pos_rows)],
        out_dir / "label_distribution.svg",
    )

    # Extra visualizations with more analytical value.
    if day_counts:
        day_labels = sorted(day_counts.keys())
        day_values = [int(day_counts[k]) for k in day_labels]
        svg_line_chart(
            "Interactions Over Time",
            day_labels,
            [float(v) for v in day_values],
            out_dir / "interactions_over_time.svg",
            y_label="rows",
        )

        positive_rates = []
        for day in day_labels:
            total = day_counts[day]
            positive_rates.append(
                (day_pos_counts.get(day, 0) / total) if total else 0.0
            )
        svg_line_chart(
            "Daily Positive Rate",
            day_labels,
            positive_rates,
            out_dir / "daily_positive_rate.svg",
            y_label="positive rate",
        )

    if pos_by_item:
        top_items = pos_by_item.most_common(15)
        item_labels = [item for item, _count in top_items]
        item_values = [int(count) for _item, count in top_items]
        svg_bar_chart(
            "Top Items by Positive Interactions",
            item_labels,
            item_values,
            out_dir / "top_positive_items.svg",
        )

    # Positives-per-user histogram buckets
    if pos_counts_per_user:
        buckets = defaultdict(int)
        for c in pos_counts_per_user:
            if c <= 0:
                buckets["0"] += 1
            elif c <= 5:
                buckets["1-5"] += 1
            elif c <= 10:
                buckets["6-10"] += 1
            elif c <= 25:
                buckets["11-25"] += 1
            elif c <= 50:
                buckets["26-50"] += 1
            else:
                buckets["51+"] += 1
        bucket_labels = ["0", "1-5", "6-10", "11-25", "26-50", "51+"]
        bucket_values = [int(buckets.get(k, 0)) for k in bucket_labels]
        svg_bar_chart(
            "Users by #Positive Interactions",
            bucket_labels,
            bucket_values,
            out_dir / "users_by_positive_count.svg",
        )

        sorted_counts = sorted(pos_counts_per_user, reverse=True)
        cumulative = []
        running = 0
        total_positive_users = sum(sorted_counts) or 1
        for count in sorted_counts:
            running += count
            cumulative.append(running / total_positive_users)
        pareto_labels = [str(i + 1) for i in range(len(cumulative))]
        svg_line_chart(
            "Cumulative Positive Coverage by User Rank",
            pareto_labels,
            cumulative,
            out_dir / "positive_coverage_pareto.svg",
            y_label="cumulative share",
        )

    # Optional split
    if args.split:
        train_users, test_users = split_users(all_user_ids, args.test_ratio, args.seed)
        train_path = out_dir / f"{data_path.stem}.train.jsonl"
        test_path = out_dir / f"{data_path.stem}.test.jsonl"

        train_handle = train_path.open("w", encoding="utf-8")
        test_handle = test_path.open("w", encoding="utf-8")
        try:
            for row in iter_jsonl(data_path):
                uid = safe_str(row.get("userId")).strip()
                handle = test_handle if uid in test_users else train_handle
                handle.write(json.dumps(row) + "\n")
        finally:
            train_handle.close()
            test_handle.close()

        split_info = {
            "seed": args.seed,
            "testRatio": args.test_ratio,
            "trainUsers": len(train_users),
            "testUsers": len(test_users),
            "trainPath": str(train_path.resolve()),
            "testPath": str(test_path.resolve()),
        }
        (out_dir / "split_info.json").write_text(json.dumps(split_info, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
