"""Two towers: frozen encoder + separate linear projections to 1536-d (pgvector)."""

from __future__ import annotations

import json
import os
from hashlib import sha256
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from sentence_transformers import SentenceTransformer


class TwoTowerProjections(nn.Module):
    def __init__(self, source_dim: int, out_dim: int = 1536):
        super().__init__()
        self.out_dim = out_dim
        self.user_proj = nn.Sequential(
            nn.Linear(source_dim, out_dim),
            nn.Tanh(),
        )
        self.item_proj = nn.Sequential(
            nn.Linear(source_dim, out_dim),
            nn.Tanh(),
        )

    def forward_user(self, x: torch.Tensor) -> torch.Tensor:
        return F.normalize(self.user_proj(x), dim=-1)

    def forward_item(self, x: torch.Tensor) -> torch.Tensor:
        return F.normalize(self.item_proj(x), dim=-1)


class LocalTextEncoder:
    """Offline-safe deterministic encoder with a SentenceTransformer-like interface."""

    def __init__(self, model_name: str, device: torch.device, dim: int = 384):
        self.model_name = model_name
        self.device = device
        self.dim = dim

    def get_sentence_embedding_dimension(self) -> int:
        return self.dim

    def _encode_one(self, text: str) -> np.ndarray:
        text = str(text or "")
        if not text:
            return np.zeros(self.dim, dtype=np.float32)

        vec = np.zeros(self.dim, dtype=np.float32)
        tokens = text.lower().split()
        for index, token in enumerate(tokens):
            key = f"{self.model_name}|{index}|{token}".encode("utf-8")
            digest = sha256(key).digest()
            bucket = int.from_bytes(digest[:4], "big") % self.dim
            sign = 1.0 if digest[4] % 2 == 0 else -1.0
            magnitude = 0.5 + (digest[5] / 255.0)
            vec[bucket] += sign * magnitude

        norm = np.linalg.norm(vec)
        if norm > 0:
            vec /= norm
        return vec

    def encode(
        self,
        texts: list[str],
        batch_size: int = 32,
        convert_to_tensor: bool = True,
        show_progress_bar: bool = False,
    ) -> torch.Tensor | np.ndarray:
        del batch_size, show_progress_bar
        vectors = [self._encode_one(text) for text in texts]
        arr = np.stack(vectors) if vectors else np.zeros((0, self.dim), dtype=np.float32)
        if not convert_to_tensor:
            return arr
        return torch.tensor(arr, dtype=torch.float32, device=self.device)


def build_encoder(model_name: str, device: torch.device) -> SentenceTransformer | LocalTextEncoder:
    offline_only = os.environ.get("HF_HUB_OFFLINE", "").lower() in {"1", "true", "yes"}
    try:
        enc = SentenceTransformer(
            model_name,
            device=str(device),
            local_files_only=offline_only,
        )
    except Exception as exc:
        print(
            f"Warning: falling back to LocalTextEncoder because '{model_name}' could not be loaded: {exc}"
        )
        return LocalTextEncoder(model_name, device=device, dim=384)

    enc.eval()
    for p in enc.parameters():
        p.requires_grad = False
    return enc


@torch.no_grad()
def encode_batch(
    encoder: SentenceTransformer | LocalTextEncoder, texts: list[str], batch_size: int
) -> torch.Tensor:
    """Frozen encoder; returns float32 tensor on CPU or same device as encoder."""
    emb = encoder.encode(
        texts,
        batch_size=batch_size,
        convert_to_tensor=True,
        show_progress_bar=False,
    )
    # Normalize frozen encoder outputs so projection heads train against a stable scale.
    return F.normalize(emb.float(), dim=-1)


def train_step(
    encoder: SentenceTransformer | LocalTextEncoder,
    projections: TwoTowerProjections,
    user_texts: list[str],
    item_texts: list[str],
    labels: torch.Tensor,
    device: torch.device,
    encode_batch_size: int,
    temperature: float,
) -> torch.Tensor:
    """Single batch; encoder frozen, grads only on projections."""
    u_raw = encode_batch(encoder, user_texts, encode_batch_size).to(device)
    v_raw = encode_batch(encoder, item_texts, encode_batch_size).to(device)
    u = projections.forward_user(u_raw)
    v = projections.forward_item(v_raw)
    logits = (u * v).sum(dim=-1) * temperature
    loss = F.binary_cross_entropy_with_logits(logits, labels)
    return loss


@torch.no_grad()
def precompute_embeddings(
    encoder: SentenceTransformer | LocalTextEncoder,
    texts: list[str],
    encode_batch_size: int,
    device: torch.device,
) -> torch.Tensor:
    """
    Encode all texts once with frozen encoder, keep on training device.
    This removes repeated encoder calls in every optimization step.
    """
    emb = encode_batch(encoder, texts, encode_batch_size)
    return emb.to(device)


def train_step_from_embeddings(
    projections: TwoTowerProjections,
    user_raw: torch.Tensor,
    item_raw: torch.Tensor,
    labels: torch.Tensor,
    user_keys: list[str],
    item_keys: list[str],
    temperature: float,
    ranking_weight: float = 1.0,
    bce_weight: float = 0.5,
) -> tuple[torch.Tensor, dict[str, float]]:
    """
    Train from cached encoder embeddings using:
    - in-batch contrastive ranking loss (InfoNCE style)
    - optional BCE on paired logits for soft labels
    """
    u = projections.forward_user(user_raw)
    v = projections.forward_item(item_raw)

    sim = torch.matmul(u, v.T) * temperature
    positive_flags = [bool(x > 0) for x in labels.detach().tolist()]

    user_positive_mask = torch.tensor(
        [
            [
                positive_flags[row]
                and positive_flags[col]
                and user_keys[row] == user_keys[col]
                for col in range(len(user_keys))
            ]
            for row in range(len(user_keys))
        ],
        device=sim.device,
        dtype=torch.bool,
    )
    item_positive_mask = torch.tensor(
        [
            [
                positive_flags[row]
                and positive_flags[col]
                and item_keys[col] == item_keys[row]
                for col in range(len(item_keys))
            ]
            for row in range(len(item_keys))
        ],
        device=sim.device,
        dtype=torch.bool,
    )

    row_has_positive = user_positive_mask.any(dim=1)
    col_has_positive = item_positive_mask.any(dim=1)

    row_log_denom = torch.logsumexp(sim, dim=1)
    row_pos_logits = sim.masked_fill(~user_positive_mask, float("-inf"))
    row_log_num = torch.logsumexp(row_pos_logits, dim=1)
    row_loss = -(row_log_num - row_log_denom)

    col_log_denom = torch.logsumexp(sim.T, dim=1)
    col_pos_logits = sim.T.masked_fill(~item_positive_mask, float("-inf"))
    col_log_num = torch.logsumexp(col_pos_logits, dim=1)
    col_loss = -(col_log_num - col_log_denom)

    row_weights = labels.clamp(0.0, 1.0)
    col_weights = labels.clamp(0.0, 1.0)

    row_weight_total = row_weights[row_has_positive].sum()
    col_weight_total = col_weights[col_has_positive].sum()

    row_ranking_loss = (
        (row_loss[row_has_positive] * row_weights[row_has_positive]).sum()
        / row_weight_total.clamp_min(1e-8)
    )
    col_ranking_loss = (
        (col_loss[col_has_positive] * col_weights[col_has_positive]).sum()
        / col_weight_total.clamp_min(1e-8)
    )
    ranking_loss = 0.5 * (row_ranking_loss + col_ranking_loss)

    pair_logits = sim.diagonal()
    bce_loss = F.binary_cross_entropy_with_logits(pair_logits, labels)
    total = ranking_weight * ranking_loss + bce_weight * bce_loss
    metrics = {
        "ranking_loss": float(ranking_loss.detach().item()),
        "bce_loss": float(bce_loss.detach().item()),
        "total_loss": float(total.detach().item()),
    }
    return total, metrics


def save_checkpoint(
    out_dir: Path,
    encoder_name: str,
    projections: TwoTowerProjections,
    source_dim: int,
    out_dim: int,
    dataset_provenance: dict | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    torch.save(
        {
            "user_proj": projections.user_proj.state_dict(),
            "item_proj": projections.item_proj.state_dict(),
            "encoder_name": encoder_name,
            "source_dim": source_dim,
            "out_dim": out_dim,
        },
        out_dir / "two_tower.pt",
    )
    meta = {
        "encoder_name": encoder_name,
        "source_dim": source_dim,
        "out_dim": out_dim,
        "dataset": dataset_provenance,
    }
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")


def load_projections(
    ckpt_dir: Path, device: torch.device
) -> tuple[TwoTowerProjections, str, int, int]:
    ckpt_dir = Path(ckpt_dir)
    ckpt = torch.load(ckpt_dir / "two_tower.pt", map_location=device)
    enc_name = ckpt["encoder_name"]
    source_dim = int(ckpt["source_dim"])
    out_dim = int(ckpt["out_dim"])
    m = TwoTowerProjections(source_dim, out_dim)
    m.user_proj.load_state_dict(ckpt["user_proj"])
    m.item_proj.load_state_dict(ckpt["item_proj"])
    m.to(device)
    m.eval()
    return m, enc_name, source_dim, out_dim
