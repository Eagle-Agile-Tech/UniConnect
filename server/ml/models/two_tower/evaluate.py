#!/usr/bin/env python3
"""Quick offline evaluator for two-tower retrieval quality."""

from __future__ import annotations

import argparse
from collections import defaultdict
import math

import torch
from tqdm import tqdm

from ml.features.dataset import load_rows
from ml.features.feature_text import row_to_pair
from ml.pipelines.dataset_provenance import build_dataset_provenance
from ml.models.two_tower.model import build_encoder, load_projections, precompute_embeddings


def build_eval_rows(path: str) -> list[dict]:
    rows = load_rows(path)
    out = []
    for row in rows:
        pair = row_to_pair(row)
        if pair is None:
            continue
        user_text, item_text, _soft_label = pair
        uid = str(row.get("userId") or "")
        iid = str(row.get("targetId") or "")
        itype = str(row.get("targetType") or "")
        if not uid or not iid or not itype:
            continue
        try:
            hard_label = float(row.get("label", 0) or 0)
        except Exception:
            hard_label = 0.0
        out.append(
            {
                "userId": uid,
                "itemKey": f"{itype}::{iid}",
                "itemText": item_text,
                "userText": user_text,
                "label": hard_label,
            }
        )
    return out


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


def mrr_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0:
        return 0.0
    for idx, item in enumerate(ranked[:k], start=1):
        if item in relevant:
            return 1.0 / float(idx)
    return 0.0


def ap_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0 or not relevant:
        return 0.0
    hits = 0
    sum_prec = 0.0
    for i, item in enumerate(ranked[:k], start=1):
        if item in relevant:
            hits += 1
            sum_prec += hits / float(i)
    denom = min(len(relevant), k)
    return sum_prec / float(max(1, denom))


def ndcg_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
    if k <= 0:
        return 0.0
    dcg = 0.0
    for i, item in enumerate(ranked[:k], start=1):
        if item in relevant:
            dcg += 1.0 / math.log2(i + 1.0)
    ideal_hits = min(len(relevant), k)
    if ideal_hits <= 0:
        return 0.0
    idcg = sum(1.0 / math.log2(i + 1.0) for i in range(1, ideal_hits + 1))
    return dcg / float(idcg)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=str, help="Dataset JSON/JSONL path")
    ap.add_argument(
        "--checkpoint",
        required=True,
        type=str,
        help="Directory containing two_tower.pt and meta.json",
    )
    ap.add_argument("--batch-size", type=int, default=64)
    ap.add_argument("--k-precision", type=int, default=10)
    ap.add_argument("--k-recall", type=int, default=20)
    ap.add_argument("--k-mrr", type=int, default=10)
    ap.add_argument("--k-map", type=int, default=10)
    ap.add_argument("--k-ndcg", type=int, default=10)
    ap.add_argument(
        "--positive-threshold",
        type=float,
        default=0.5,
        help="Rows with label >= threshold are treated as relevant",
    )
    ap.add_argument(
        "--min-users",
        type=int,
        default=2,
        help="Minimum number of evaluable users required for the reported metrics to be considered valid.",
    )
    args = ap.parse_args()

    rows = build_eval_rows(args.data)
    if not rows:
        raise SystemExit("No evaluable rows found.")
    dataset_provenance = build_dataset_provenance(args.data)

    user_text_by_id: dict[str, str] = {}
    item_text_by_key: dict[str, str] = {}
    relevant_by_user: dict[str, set[str]] = defaultdict(set)
    for r in rows:
        user_text_by_id[r["userId"]] = r["userText"]
        item_text_by_key[r["itemKey"]] = r["itemText"]
        if r["label"] >= args.positive_threshold:
            relevant_by_user[r["userId"]].add(r["itemKey"])

    eval_users = [u for u, rel in relevant_by_user.items() if rel]
    if not eval_users:
        raise SystemExit("No users with relevant items under positive-threshold.")
    if len(eval_users) < args.min_users:
        raise SystemExit(
            f"Only {len(eval_users)} evaluable users found in {args.data}; need at least {args.min_users}."
        )

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    projections, enc_name, _src, _out = load_projections(args.checkpoint, device)
    encoder = build_encoder(enc_name, device)

    item_keys = list(item_text_by_key.keys())
    item_texts = [item_text_by_key[k] for k in item_keys]
    user_ids = eval_users
    user_texts = [user_text_by_id[u] for u in user_ids]

    with torch.no_grad():
        user_raw = precompute_embeddings(encoder, user_texts, args.batch_size, device)
        item_raw = precompute_embeddings(encoder, item_texts, args.batch_size, device)
        user_vec = projections.forward_user(user_raw)
        item_vec = projections.forward_item(item_raw)
        sim = torch.matmul(user_vec, item_vec.T)

    p_scores: list[float] = []
    r_scores: list[float] = []
    mrr_scores: list[float] = []
    map_scores: list[float] = []
    ndcg_scores: list[float] = []
    for i, uid in enumerate(tqdm(user_ids, desc="evaluating users")):
        ranked_idx = torch.argsort(sim[i], descending=True).tolist()
        ranked_items = [item_keys[j] for j in ranked_idx]
        relevant = relevant_by_user.get(uid, set())
        p_scores.append(precision_at_k(ranked_items, relevant, args.k_precision))
        r_scores.append(recall_at_k(ranked_items, relevant, args.k_recall))
        mrr_scores.append(mrr_at_k(ranked_items, relevant, args.k_mrr))
        map_scores.append(ap_at_k(ranked_items, relevant, args.k_map))
        ndcg_scores.append(ndcg_at_k(ranked_items, relevant, args.k_ndcg))

    p_at_k = sum(p_scores) / max(1, len(p_scores))
    r_at_k = sum(r_scores) / max(1, len(r_scores))
    mrr = sum(mrr_scores) / max(1, len(mrr_scores))
    mean_ap = sum(map_scores) / max(1, len(map_scores))
    ndcg = sum(ndcg_scores) / max(1, len(ndcg_scores))
    print(
        f"dataset={dataset_provenance['fileName']} "
        f"users={len(user_ids)} "
        f"items={len(item_keys)} "
        f"Precision@{args.k_precision}={p_at_k:.4f} "
        f"Recall@{args.k_recall}={r_at_k:.4f} "
        f"MRR@{args.k_mrr}={mrr:.4f} "
        f"MAP@{args.k_map}={mean_ap:.4f} "
        f"nDCG@{args.k_ndcg}={ndcg:.4f}"
    )


if __name__ == "__main__":
    main()
