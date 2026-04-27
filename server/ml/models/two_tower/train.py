#!/usr/bin/env python3
"""Train two-tower projection heads (encoder frozen)."""

from __future__ import annotations

import argparse
import random
from pathlib import Path

import numpy as np
import torch
from torch.optim import AdamW
from torch.optim.lr_scheduler import LambdaLR
from tqdm import tqdm

from ml.features.dataset import load_training_pairs
from ml.pipelines.dataset_provenance import build_dataset_provenance
from ml.models.two_tower.model import (
    TwoTowerProjections,
    build_encoder,
    precompute_embeddings,
    save_checkpoint,
    train_step_from_embeddings,
)


ROOT = Path(__file__).resolve().parents[3]


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--data",
        type=str,
        required=True,
        help="Path to training JSON (with rows[]) or JSONL of row objects",
    )
    p.add_argument(
        "--out",
        type=str,
        default=str(ROOT / "ml" / "two_tower" / "checkpoints" / "two_tower_run"),
    )
    p.add_argument("--encoder", type=str, default="all-MiniLM-L6-v2")
    p.add_argument("--epochs", type=int, default=16)
    p.add_argument("--batch-size", type=int, default=64)
    p.add_argument("--encode-batch-size", type=int, default=64)
    p.add_argument("--lr", type=float, default=5e-4)
    p.add_argument("--temperature", type=float, default=12.0)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--out-dim", type=int, default=1536)
    p.add_argument(
        "--negatives-per-positive",
        type=int,
        default=3,
        help="Additional sampled negatives to generate for each positive row",
    )
    p.add_argument(
        "--hard-negative-ratio",
        type=float,
        default=0.67,
        help="Fraction of sampled negatives that should favor semantically similar items",
    )
    p.add_argument(
        "--no-balance-data",
        action="store_true",
        help="Keep the loaded dataset class-imbalanced instead of downsampling to 1:1",
    )
    p.add_argument(
        "--warmup-ratio",
        type=float,
        default=0.1,
        help="Fraction of optimization steps used for learning-rate warmup",
    )
    p.add_argument(
        "--min-lr-scale",
        type=float,
        default=0.1,
        help="Final learning rate as a fraction of the base learning rate",
    )
    p.add_argument(
        "--ranking-weight",
        type=float,
        default=1.0,
        help="Weight for in-batch contrastive ranking loss",
    )
    p.add_argument(
        "--bce-weight",
        type=float,
        default=0.5,
        help="Weight for BCE pairwise calibration loss",
    )
    args = p.parse_args()

    set_seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    dataset_provenance = build_dataset_provenance(args.data)

    user_texts, item_texts, labels, user_ids, item_keys = load_training_pairs(
        args.data,
        negatives_per_positive=args.negatives_per_positive,
        hard_negative_ratio=args.hard_negative_ratio,
        balance_classes=not args.no_balance_data,
        balance_seed=args.seed,
    )
    if not user_texts:
        raise SystemExit("No training pairs loaded. Check --data path and row format.")

    encoder = build_encoder(args.encoder, device)
    source_dim = encoder.get_sentence_embedding_dimension()
    print("precomputing frozen encoder embeddings...")
    user_emb = precompute_embeddings(encoder, user_texts, args.encode_batch_size, device)
    item_emb = precompute_embeddings(encoder, item_texts, args.encode_batch_size, device)
    del encoder

    projections = TwoTowerProjections(source_dim, args.out_dim).to(device)
    opt = AdamW(projections.parameters(), lr=args.lr, weight_decay=1e-4)

    n = len(labels)
    idx = list(range(n))
    batches = max(1, (n + args.batch_size - 1) // args.batch_size)
    total_steps = max(1, args.epochs * batches)
    warmup_steps = min(total_steps - 1, int(total_steps * max(args.warmup_ratio, 0.0)))

    def lr_lambda(current_step: int) -> float:
        if warmup_steps > 0 and current_step < warmup_steps:
            return float(current_step + 1) / float(warmup_steps)
        if total_steps <= warmup_steps:
            return 1.0
        progress = (current_step - warmup_steps) / float(max(1, total_steps - warmup_steps))
        cosine = 0.5 * (1.0 + np.cos(np.pi * progress))
        return args.min_lr_scale + (1.0 - args.min_lr_scale) * cosine

    scheduler = LambdaLR(opt, lr_lambda=lr_lambda)

    out_dir = Path(args.out)
    best_loss = float("inf")

    for epoch in range(args.epochs):
        random.shuffle(idx)
        epoch_loss = 0.0
        epoch_rank = 0.0
        epoch_bce = 0.0
        steps = 0
        progress = tqdm(range(0, n, args.batch_size), desc=f"epoch {epoch + 1}/{args.epochs}")
        for start in progress:
            batch_i = idx[start : start + args.batch_size]
            bi = torch.tensor(batch_i, device=device, dtype=torch.long)
            u_raw = user_emb.index_select(0, bi)
            v_raw = item_emb.index_select(0, bi)
            y = torch.tensor([labels[i] for i in batch_i], device=device, dtype=torch.float32)

            opt.zero_grad()
            loss, metrics = train_step_from_embeddings(
                projections,
                u_raw,
                v_raw,
                y,
                [user_ids[i] for i in batch_i],
                [item_keys[i] for i in batch_i],
                args.temperature,
                ranking_weight=args.ranking_weight,
                bce_weight=args.bce_weight,
            )
            loss.backward()
            torch.nn.utils.clip_grad_norm_(projections.parameters(), 1.0)
            opt.step()
            scheduler.step()

            lv = loss.item()
            epoch_loss += lv
            epoch_rank += metrics["ranking_loss"]
            epoch_bce += metrics["bce_loss"]
            steps += 1
            progress.set_postfix(
                loss=f"{lv:.4f}",
                rank=f"{metrics['ranking_loss']:.4f}",
                bce=f"{metrics['bce_loss']:.4f}",
            )

        avg = epoch_loss / max(steps, 1)
        avg_rank = epoch_rank / max(steps, 1)
        avg_bce = epoch_bce / max(steps, 1)
        print(
            f"epoch {epoch + 1} mean loss: {avg:.6f} "
            f"(rank={avg_rank:.6f}, bce={avg_bce:.6f})"
        )
        if avg < best_loss:
            best_loss = avg
            save_checkpoint(
                out_dir,
                args.encoder,
                projections,
                source_dim,
                args.out_dim,
                dataset_provenance,
            )
            print(f"  saved checkpoint to {out_dir}")

    print("done. best avg loss:", best_loss)


if __name__ == "__main__":
    main()
