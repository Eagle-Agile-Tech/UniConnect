#!/usr/bin/env python3
"""Train an ID-based two-tower model and export vector mappings."""

from __future__ import annotations

import argparse
import json
import random
from math import ceil
from pathlib import Path

import torch
import torch.nn as nn
from torch.optim import Adam
from torch.utils.data import DataLoader, TensorDataset

from ml.pipelines.dataset_provenance import build_dataset_provenance
from ml.features.id_dataset import balance_training_examples, build_id_mappings, load_training_examples


ROOT = Path(__file__).resolve().parents[2]


class TwoTowerModel(nn.Module):
    def __init__(self, num_users: int, num_items: int, embedding_dim: int = 1536):
        super().__init__()
        self.user_embedding = nn.Embedding(num_users, embedding_dim)
        self.item_embedding = nn.Embedding(num_items, embedding_dim)

    def forward(self, user_ids: torch.Tensor, item_ids: torch.Tensor) -> torch.Tensor:
        user_vec = self.user_embedding(user_ids)
        item_vec = self.item_embedding(item_ids)
        return (user_vec * item_vec).sum(dim=1)

    @torch.no_grad()
    def normalized_user_embeddings(self) -> torch.Tensor:
        return torch.nn.functional.normalize(self.user_embedding.weight, dim=1)

    @torch.no_grad()
    def normalized_item_embeddings(self) -> torch.Tensor:
        return torch.nn.functional.normalize(self.item_embedding.weight, dim=1)


def set_seed(seed: int) -> None:
    random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def _esc_svg(text: str) -> str:
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def write_training_curve_svg(out_path: Path, history: list[dict[str, float]]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if not history:
        out_path.write_text("<svg xmlns='http://www.w3.org/2000/svg'></svg>\n", encoding="utf-8")
        return

    width = 960
    height = 420
    pad_l, pad_r, pad_t, pad_b = 80, 30, 60, 80
    plot_w = max(10, width - pad_l - pad_r)
    plot_h = max(10, height - pad_t - pad_b)

    epochs = [int(item.get("epoch", 0) or 0) for item in history]
    losses = [float(item.get("loss", 0.0) or 0.0) for item in history]
    min_loss = min(losses)
    max_loss = max(losses)
    if min_loss == max_loss:
        max_loss = min_loss + 1.0

    def scale_loss(value: float) -> float:
        return pad_t + plot_h - ((value - min_loss) / (max_loss - min_loss)) * plot_h

    step = plot_w / max(len(history) - 1, 1)
    points: list[str] = []
    for index, loss in enumerate(losses):
        x = pad_l + index * step
        y = scale_loss(loss)
        points.append(f"{x:.1f},{y:.1f}")

    parts: list[str] = []
    parts.append(f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}'>")
    parts.append("<rect x='0' y='0' width='100%' height='100%' fill='#f8fafc'/>")
    parts.append(
        f"<text x='{width//2}' y='32' text-anchor='middle' "
        "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
        "font-size='18' fill='#0f172a'>"
        "Training Loss by Epoch</text>"
    )
    parts.append(f"<line x1='{pad_l}' y1='{pad_t}' x2='{pad_l}' y2='{pad_t+plot_h}' stroke='#0f172a' stroke-width='1'/>")
    parts.append(f"<line x1='{pad_l}' y1='{pad_t+plot_h}' x2='{pad_l+plot_w}' y2='{pad_t+plot_h}' stroke='#0f172a' stroke-width='1'/>")

    for frac in [0.0, 0.25, 0.5, 0.75, 1.0]:
        y = pad_t + plot_h - int(frac * plot_h)
        value = min_loss + frac * (max_loss - min_loss)
        parts.append(f"<line x1='{pad_l-6}' y1='{y}' x2='{pad_l}' y2='{y}' stroke='#0f172a' stroke-width='1'/>")
        parts.append(
            f"<text x='{pad_l-12}' y='{y+4}' text-anchor='end' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='12' fill='#0f172a'>"
            f"{value:.4f}</text>"
        )
        parts.append(f"<line x1='{pad_l}' y1='{y}' x2='{pad_l+plot_w}' y2='{y}' stroke='#e2e8f0' stroke-width='1'/>")

    if len(points) > 1:
        parts.append(
            f"<polyline fill='none' stroke='#2563eb' stroke-width='3' points='{' '.join(points)}'/>"
        )

    for index, loss in enumerate(losses):
        x = pad_l + index * step
        y = scale_loss(loss)
        parts.append(f"<circle cx='{x:.1f}' cy='{y:.1f}' r='4.5' fill='#1d4ed8'/>")
        parts.append(
            f"<text x='{x:.1f}' y='{max(pad_t + 12, y - 10):.1f}' text-anchor='middle' "
            "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
            "font-size='11' fill='#0f172a'>"
            f"{loss:.4f}</text>"
        )
        if len(history) <= 14 or index == 0 or index == len(history) - 1 or index % max(1, ceil(len(history) / 8)) == 0:
            parts.append(
                f"<g transform='translate({x:.1f},{pad_t+plot_h+14}) rotate(35)'>"
                "<text text-anchor='start' "
                "font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
                "font-size='12' fill='#0f172a'>"
                f"Epoch {epochs[index]}</text></g>"
            )

    parts.append(
        f"<text x='{pad_l}' y='{height-18}' font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' "
        "font-size='12' fill='#475569'>"
        f"Start {losses[0]:.4f} -> Best {min_loss:.4f} -> End {losses[-1]:.4f}</text>"
    )
    parts.append("</svg>")
    out_path.write_text("\n".join(parts) + "\n", encoding="utf-8")


def save_outputs(
    out_dir: Path,
    model: TwoTowerModel,
    user_to_index: dict[str, int],
    item_to_index: dict[str, int],
    history: list[dict[str, float]],
    embedding_dim: int,
    dataset_provenance: dict[str, object] | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    torch.save(
        {
            "state_dict": model.state_dict(),
            "embedding_dim": embedding_dim,
            "num_users": len(user_to_index),
            "num_items": len(item_to_index),
        },
        out_dir / "id_two_tower.pt",
    )

    user_vectors = model.normalized_user_embeddings().detach().cpu().numpy()
    item_vectors = model.normalized_item_embeddings().detach().cpu().numpy()

    with (out_dir / "user_embeddings.jsonl").open("w", encoding="utf-8") as handle:
        for user_id, index in user_to_index.items():
            handle.write(
                json.dumps(
                    {
                        "userId": user_id,
                        "index": index,
                        "embedding": user_vectors[index].tolist(),
                    }
                )
                + "\n"
            )

    with (out_dir / "item_embeddings.jsonl").open("w", encoding="utf-8") as handle:
        for item_id, index in item_to_index.items():
            target_type, target_id = item_id.split("::", 1)
            handle.write(
                json.dumps(
                    {
                        "itemId": item_id,
                        "targetType": target_type,
                        "targetId": target_id,
                        "index": index,
                        "embedding": item_vectors[index].tolist(),
                    }
                )
                + "\n"
            )

    (out_dir / "id_mappings.json").write_text(
        json.dumps(
            {
                "user_to_index": user_to_index,
                "item_to_index": item_to_index,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (out_dir / "meta.json").write_text(
        json.dumps(
            {
                "model_type": "id_two_tower",
                "embedding_dim": embedding_dim,
                "num_users": len(user_to_index),
                "num_items": len(item_to_index),
                "epochs_trained": len(history),
                "history": history,
                "dataset": dataset_provenance,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (out_dir / "training_history.json").write_text(
        json.dumps(history, indent=2),
        encoding="utf-8",
    )
    write_training_curve_svg(out_dir / "training_curve.svg", history)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=str, help="Path to training JSON/JSONL")
    parser.add_argument(
        "--out",
        type=str,
        default=str(ROOT / "ml" / "two_tower" / "checkpoints" / "id_two_tower_run"),
        help="Directory for model weights, mappings, and exported embeddings",
    )
    parser.add_argument("--epochs", type=int, default=10)
    parser.add_argument("--batch-size", type=int, default=128)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--embedding-dim", type=int, default=1536)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--no-balance-data",
        action="store_true",
        help="Keep the loaded dataset class-imbalanced instead of downsampling to 1:1",
    )
    args = parser.parse_args()

    set_seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    dataset_provenance = build_dataset_provenance(args.data)

    examples = load_training_examples(args.data)
    if not args.no_balance_data:
        examples = balance_training_examples(examples, seed=args.seed)
    if not examples:
        raise SystemExit("No valid training examples were found.")

    user_to_index, item_to_index = build_id_mappings(examples)
    user_tensor = torch.tensor(
        [user_to_index[example["user_id"]] for example in examples],
        dtype=torch.long,
    )
    item_tensor = torch.tensor(
        [item_to_index[example["item_id"]] for example in examples],
        dtype=torch.long,
    )
    label_tensor = torch.tensor(
        [float(example["label"]) for example in examples],
        dtype=torch.float32,
    )

    loader = DataLoader(
        TensorDataset(user_tensor, item_tensor, label_tensor),
        batch_size=args.batch_size,
        shuffle=True,
    )

    model = TwoTowerModel(
        num_users=len(user_to_index),
        num_items=len(item_to_index),
        embedding_dim=args.embedding_dim,
    ).to(device)
    optimizer = Adam(model.parameters(), lr=args.lr)
    loss_fn = nn.BCEWithLogitsLoss()

    history: list[dict[str, float]] = []
    for epoch in range(args.epochs):
        model.train()
        epoch_loss = 0.0
        batch_count = 0
        for user_batch, item_batch, label_batch in loader:
            user_batch = user_batch.to(device)
            item_batch = item_batch.to(device)
            label_batch = label_batch.to(device)

            predictions = model(user_batch, item_batch)
            loss = loss_fn(predictions, label_batch)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            epoch_loss += float(loss.item())
            batch_count += 1

        average_loss = epoch_loss / max(batch_count, 1)
        history.append({"epoch": epoch + 1, "loss": average_loss})
        print(f"epoch {epoch + 1}/{args.epochs} loss={average_loss:.6f}")

    save_outputs(
        Path(args.out),
        model,
        user_to_index,
        item_to_index,
        history,
        args.embedding_dim,
        dataset_provenance,
    )
    print(
        f"saved id-based two-tower checkpoint to {Path(args.out).resolve()} "
        f"(users={len(user_to_index)}, items={len(item_to_index)})"
    )


if __name__ == "__main__":
    main()
