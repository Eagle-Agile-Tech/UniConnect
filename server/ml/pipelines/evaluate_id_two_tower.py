#!/usr/bin/env python3
"""Evaluate ID-based two-tower checkpoint on a JSON/JSONL dataset.

Metrics:
- Classification: accuracy, logloss, ROC-AUC (no sklearn).
- Retrieval: Precision@K, Recall@K, MAP@K, NDCG@K (per-user, averaged).
"""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from pathlib import Path
from typing import Any

import torch

from ml.features.id_dataset import load_rows
from ml.pipelines.dataset_provenance import (
    build_dataset_provenance,
    evaluate_mapping_overlap,
)


def sigmoid(x: torch.Tensor) -> torch.Tensor:
    return 1.0 / (1.0 + torch.exp(-x))


def load_checkpoint_mappings(ckpt_dir: Path) -> tuple[dict[str, int] | None, dict[str, int] | None]:
    mapping_path = ckpt_dir / "id_mappings.json"
    if not mapping_path.exists():
        return None, None

    try:
        raw = json.loads(mapping_path.read_text(encoding="utf-8"))
    except Exception:
        return None, None

    user_to_index = raw.get("user_to_index")
    item_to_index = raw.get("item_to_index")
    if not isinstance(user_to_index, dict) or not isinstance(item_to_index, dict):
        return None, None
    return (
        {str(key): int(value) for key, value in user_to_index.items()},
        {str(key): int(value) for key, value in item_to_index.items()},
    )


def roc_auc(scores: list[float], labels: list[int]) -> float:
    """Compute ROC-AUC via rank statistic (Mann–Whitney U)."""
    paired = [(s, int(l)) for s, l in zip(scores, labels)]
    pos = sum(1 for _s, l in paired if l == 1)
    neg = len(paired) - pos
    if pos == 0 or neg == 0:
        return 0.0

    # Sort ascending by score; average ranks for ties.
    paired.sort(key=lambda x: x[0])
    ranks = [0.0] * len(paired)
    i = 0
    while i < len(paired):
        j = i + 1
        while j < len(paired) and paired[j][0] == paired[i][0]:
            j += 1
        avg_rank = (i + 1 + j) / 2.0  # 1-based ranks
        for k in range(i, j):
            ranks[k] = avg_rank
        i = j

    sum_ranks_pos = 0.0
    for r, (_s, l) in zip(ranks, paired):
        if l == 1:
            sum_ranks_pos += r

    auc = (sum_ranks_pos - (pos * (pos + 1) / 2.0)) / (pos * neg)
    return float(auc)


def precision_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0:
        return 0.0
    topk = ranked[:k]
    if not topk:
        return 0.0
    hits = sum(1 for x in topk if x in relevant)
    return hits / float(k)


def recall_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if not relevant:
        return 0.0
    topk = ranked[:k]
    hits = sum(1 for x in topk if x in relevant)
    return hits / float(len(relevant))


def average_precision_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0 or not relevant:
        return 0.0
    hits = 0
    score = 0.0
    for i, item in enumerate(ranked[:k], start=1):
        if item in relevant:
            hits += 1
            score += hits / float(i)
    return score / float(min(len(relevant), k))


def ndcg_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0 or not relevant:
        return 0.0
    dcg = 0.0
    for i, item in enumerate(ranked[:k], start=1):
        if item in relevant:
            dcg += 1.0 / math.log2(i + 1)
    ideal_hits = min(len(relevant), k)
    idcg = sum(1.0 / math.log2(i + 1) for i in range(1, ideal_hits + 1))
    return dcg / idcg if idcg > 0 else 0.0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=str, help="Dataset JSON/JSONL path")
    ap.add_argument("--checkpoint", required=True, type=str, help="Directory with id_two_tower.pt")
    ap.add_argument("--k", type=int, default=10)
    ap.add_argument("--positive-threshold", type=float, default=0.5)
    ap.add_argument("--max-users", type=int, default=0, help="Optional cap for retrieval eval (0=all)")
    ap.add_argument(
        "--allow-zero-overlap",
        action="store_true",
        help="Return metrics even when the dataset and checkpoint mappings do not overlap.",
    )
    args = ap.parse_args()

    rows = load_rows(args.data)
    if not rows:
        raise SystemExit("No rows found.")
    dataset_provenance = build_dataset_provenance(args.data)

    ckpt_dir = Path(args.checkpoint)
    ckpt = torch.load(ckpt_dir / "id_two_tower.pt", map_location="cpu")
    state = ckpt["state_dict"]
    embedding_dim = int(ckpt.get("embedding_dim", 1536))

    # Pull embeddings directly from checkpoint weights.
    user_w = state["user_embedding.weight"].float()
    item_w = state["item_embedding.weight"].float()
    user_w = torch.nn.functional.normalize(user_w, dim=1)
    item_w = torch.nn.functional.normalize(item_w, dim=1)

    user_to_index, item_to_index = load_checkpoint_mappings(ckpt_dir)
    if user_to_index is None or item_to_index is None:
        # Fallback for older checkpoints without mapping metadata.
        user_ids = sorted(
            {str(r.get("userId") or "").strip() for r in rows if str(r.get("userId") or "").strip()}
        )
        item_ids = sorted(
            {
                f"{str(r.get('targetType') or '').strip().upper()}::{str(r.get('targetId') or '').strip()}"
                for r in rows
                if str(r.get("targetType") or "").strip() and str(r.get("targetId") or "").strip()
            }
        )
        user_to_index = {u: i for i, u in enumerate(user_ids)}
        item_to_index = {it: i for i, it in enumerate(item_ids)}

    user_ids = list(user_to_index.keys())
    item_ids = list(item_to_index.keys())
    overlap = evaluate_mapping_overlap(
        rows,
        user_ids=set(user_to_index.keys()),
        item_keys=set(item_to_index.keys()),
    )
    if overlap["rowPairHits"] == 0 and not args.allow_zero_overlap:
        checkpoint_meta = {}
        meta_path = ckpt_dir / "meta.json"
        if meta_path.exists():
            try:
                checkpoint_meta = json.loads(meta_path.read_text(encoding="utf-8"))
            except Exception:
                checkpoint_meta = {}
        raise SystemExit(
            json.dumps(
                {
                    "error": "No overlap between evaluation dataset and checkpoint mappings.",
                    "hint": "Use a checkpoint trained from the same dataset family or retrain before evaluating.",
                    "dataset": dataset_provenance,
                    "checkpoint": {
                        "path": str(ckpt_dir.resolve()),
                        "meta": checkpoint_meta,
                    },
                    "mappingOverlap": overlap,
                },
                indent=2,
            )
        )

    # Classification metrics over observed pairs
    scores: list[float] = []
    labels: list[int] = []
    logloss_sum = 0.0
    correct = 0
    n = 0

    relevant_by_user: dict[str, set[str]] = defaultdict(set)
    for r in rows:
        uid = str(r.get("userId") or "").strip()
        tid = str(r.get("targetId") or "").strip()
        ttype = str(r.get("targetType") or "").strip().upper()
        if not uid or not tid or not ttype:
            continue
        item_key = f"{ttype}::{tid}"
        y = 1 if float(r.get("label", 0) or 0) >= args.positive_threshold else 0
        if y == 1:
            relevant_by_user[uid].add(item_key)

        ui = user_to_index.get(uid)
        ii = item_to_index.get(item_key)
        if ui is None or ii is None:
            continue
        if ui >= user_w.shape[0] or ii >= item_w.shape[0]:
            # If the checkpoint doesn't cover this mapping size, skip.
            continue

        logit = float(torch.dot(user_w[ui], item_w[ii]).item() * math.sqrt(float(embedding_dim)))
        p = 1.0 / (1.0 + math.exp(-logit))
        scores.append(p)
        labels.append(y)

        # log loss
        eps = 1e-12
        logloss_sum += -(y * math.log(max(p, eps)) + (1 - y) * math.log(max(1 - p, eps)))
        pred = 1 if p >= 0.5 else 0
        correct += 1 if pred == y else 0
        n += 1

    auc = roc_auc(scores, labels) if n else 0.0
    acc = (correct / n) if n else 0.0
    logloss = (logloss_sum / n) if n else 0.0

    # Retrieval metrics (rank all items for each user with at least 1 relevant item)
    eval_users = [u for u, rel in relevant_by_user.items() if rel]
    if args.max_users and args.max_users > 0:
        eval_users = eval_users[: args.max_users]

    item_keys = item_ids
    item_mat = item_w

    p_scores: list[float] = []
    r_scores: list[float] = []
    ap_scores: list[float] = []
    ndcg_scores: list[float] = []

    for uid in eval_users:
        ui = user_to_index.get(uid)
        if ui is None or ui >= user_w.shape[0]:
            continue
        rel = relevant_by_user.get(uid, set())
        if not rel:
            continue

        sims = torch.mv(item_mat, user_w[ui])
        ranked_idx = torch.argsort(sims, descending=True).tolist()
        ranked_items = [item_keys[j] for j in ranked_idx]

        p_scores.append(precision_at_k(ranked_items, rel, args.k))
        r_scores.append(recall_at_k(ranked_items, rel, args.k))
        ap_scores.append(average_precision_at_k(ranked_items, rel, args.k))
        ndcg_scores.append(ndcg_at_k(ranked_items, rel, args.k))

    out = {
        "dataset": str(Path(args.data).resolve()),
        "datasetProvenance": dataset_provenance,
        "checkpoint": str(ckpt_dir.resolve()),
        "mappingOverlap": overlap,
        "rows": len(rows),
        "pairsEvaluated": n,
        "classification": {
            "accuracy": acc,
            "logloss": logloss,
            "rocAuc": auc,
        },
        "retrieval": {
            "usersEvaluated": len(eval_users),
            f"precision@{args.k}": (sum(p_scores) / max(1, len(p_scores))) if p_scores else 0.0,
            f"recall@{args.k}": (sum(r_scores) / max(1, len(r_scores))) if r_scores else 0.0,
            f"map@{args.k}": (sum(ap_scores) / max(1, len(ap_scores))) if ap_scores else 0.0,
            f"ndcg@{args.k}": (sum(ndcg_scores) / max(1, len(ndcg_scores))) if ndcg_scores else 0.0,
        },
    }

    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
