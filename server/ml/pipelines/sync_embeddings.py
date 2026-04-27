#!/usr/bin/env python3
"""Compute embeddings with trained two-tower heads and write to UserProfileML + ContentEmbedding."""

from __future__ import annotations

import argparse
import os
import uuid
from pathlib import Path
from typing import Any

import psycopg2
import torch
import torch.nn.functional as F
from pgvector.psycopg2 import register_vector
from tqdm import tqdm

from ml.features.feature_text import target_features_to_text, user_features_to_text
from ml.models.two_tower.model import build_encoder, encode_batch, load_projections

EMBEDDING_SOURCE = "legacy-semantic"


def load_database_url_from_repo_env() -> str | None:
    env_path = Path(__file__).resolve().parents[2] / "Database" / ".env"
    if not env_path.exists():
        return None

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() != "DATABASE_URL":
            continue
        value = value.strip().strip("\"'")
        return value or None
    return None


def connect_dsn() -> str:
    dsn = os.environ.get("DATABASE_URL") or load_database_url_from_repo_env()
    if not dsn:
        raise SystemExit("Set DATABASE_URL (e.g. postgresql://user:pass@host:5432/db?schema=public)")
    if "schema=" in dsn.lower():
        base = dsn.split("?")[0]
        return base
    return dsn


def fetch_users(conn) -> list[dict[str, Any]]:
    q = """
    SELECT u."id"::text AS id,
           COALESCE(up."interests", ml."interests", ARRAY[]::text[]) AS interests,
           COALESCE(ml."skills", ARRAY[]::text[]) AS skills,
           COALESCE(ml."preferredCategories", ARRAY[]::text[]) AS "preferredCategories"
    FROM "User" u
    LEFT JOIN "UserProfile" up ON up."userId" = u."id"
    LEFT JOIN "UserProfileML" ml ON ml."userId" = u."id"
    WHERE COALESCE(u."isDeleted", false) = false
    """
    with conn.cursor() as cur:
        cur.execute(q)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def fetch_posts(conn) -> list[dict[str, Any]]:
    q = """
    SELECT "id"::text AS id, "content", "tags",
           "category"::text AS category
    FROM "Post"
    WHERE COALESCE("isDeleted", false) = false
    """
    with conn.cursor() as cur:
        cur.execute(q)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def fetch_events(conn) -> list[dict[str, Any]]:
    q = """
    SELECT "id"::text AS id, "title", "university"
    FROM "Event"
    """
    with conn.cursor() as cur:
        cur.execute(q)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def fetch_courses(conn) -> list[dict[str, Any]]:
    q = """
    SELECT "id"::text AS id, "title", "description", "price"
    FROM "Course"
    """
    with conn.cursor() as cur:
        cur.execute(q)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def upsert_user_embedding(
    cur,
    user_id: str,
    interests: list,
    skills: list,
    preferred_categories: list,
    embedding,
) -> None:
    cur.execute(
        """
        INSERT INTO "UserProfileML" ("userId", "interests", "skills", "preferredCategories", "embedding", "embeddingSource", "updatedAt")
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
        ON CONFLICT ("userId") DO UPDATE SET
          "embedding" = EXCLUDED."embedding",
          "embeddingSource" = EXCLUDED."embeddingSource",
          "updatedAt" = NOW()
        """,
        (
            user_id,
            interests or [],
            skills or [],
            preferred_categories or [],
            embedding,
            EMBEDDING_SOURCE,
        ),
    )


def fetch_user_history_item_vectors(conn, user_ids: list[str]) -> dict[str, list[list[float]]]:
    if not user_ids:
        return {}
    q = """
    SELECT ui."userId"::text AS "userId",
           ce."embedding" AS embedding,
           ui."interactionType"::text AS "interactionType",
           ui."value"::float8 AS value
    FROM "UserInteraction" ui
    JOIN "ContentEmbedding" ce
      ON ce."contentType" = ui."targetType"
     AND ce."contentId" = ui."targetId"
    WHERE ui."userId" = ANY(%s::text[])
    ORDER BY ui."createdAt" DESC
    LIMIT 20000
    """
    interaction_weights = {
        "VIEW": 1.0,
        "CLICK": 1.6,
        "LIKE": 2.4,
        "SAVE": 2.8,
        "COMMENT": 2.8,
        "SHARE": 3.0,
    }

    out: dict[str, list[list[float]]] = {}
    with conn.cursor() as cur:
        cur.execute(q, (user_ids,))
        for user_id, emb, interaction_type, value in cur.fetchall():
            if emb is None:
                continue
            w = interaction_weights.get(str(interaction_type or "").upper(), 1.0)
            try:
                val = float(value) if value is not None else 1.0
            except Exception:
                val = 1.0
            # Repeat weighted contribution by scaling the vector value directly.
            weighted = [float(x) * max(0.1, w * max(0.1, val)) for x in emb]
            out.setdefault(user_id, []).append(weighted)
    return out


def blend_user_embedding(
    profile_embedding: torch.Tensor,
    history_vectors: list[list[float]] | None,
    history_alpha: float,
) -> torch.Tensor:
    if not history_vectors:
        return profile_embedding
    hist = torch.tensor(history_vectors, dtype=profile_embedding.dtype, device=profile_embedding.device)
    hist_mean = F.normalize(torch.mean(hist, dim=0), dim=-1)
    alpha = min(max(history_alpha, 0.0), 1.0)
    mixed = F.normalize((1.0 - alpha) * profile_embedding + alpha * hist_mean, dim=-1)
    return mixed


def collect_content_items(conn) -> list[tuple[str, str, dict[str, Any]]]:
    items: list[tuple[str, str, dict[str, Any]]] = []
    for p in fetch_posts(conn):
        tf = {
            "id": p["id"],
            "type": "POST",
            "content": p["content"],
            "tags": list(p["tags"] or []),
            "category": p["category"],
        }
        items.append(("POST", p["id"], tf))
    for e in fetch_events(conn):
        tf = {
            "id": e["id"],
            "type": "EVENT",
            "title": e["title"],
            "university": e["university"],
        }
        items.append(("EVENT", e["id"], tf))
    for c in fetch_courses(conn):
        tf = {
            "id": c["id"],
            "type": "COURSE",
            "title": c["title"],
            "description": c["description"],
            "price": float(c["price"]) if c["price"] is not None else None,
        }
        items.append(("COURSE", c["id"], tf))
    return items


def replace_content_embedding(cur, content_type: str, content_id: str, embedding) -> None:
    cur.execute(
        """
        DELETE FROM "ContentEmbedding"
        WHERE "contentType" = %s AND "contentId" = %s
        """,
        (content_type, content_id),
    )
    cur.execute(
        """
        INSERT INTO "ContentEmbedding" ("id", "contentType", "contentId", "embedding", "embeddingSource", "createdAt", "updatedAt")
        VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
        """,
        (str(uuid.uuid4()), content_type, content_id, embedding, EMBEDDING_SOURCE),
    )


def run_sync(
    ckpt_dir: str,
    batch_size: int,
    users: bool,
    content: bool,
    dry_run: bool,
    history_alpha: float,
) -> None:
    dsn = connect_dsn()
    conn = psycopg2.connect(dsn)
    register_vector(conn)

    if dry_run:
        try:
            if users:
                print(f"users to embed: {len(fetch_users(conn))}")
            if content:
                print(f"content items to embed: {len(collect_content_items(conn))}")
        finally:
            conn.close()
        return

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    projections, enc_name, _source_dim, _out_dim = load_projections(
        Path(ckpt_dir), device
    )

    encoder = build_encoder(enc_name, device)

    try:
        # Write content vectors first so user history can reuse them.
        if content:
            items = collect_content_items(conn)
            print(f"content items to embed: {len(items)}")
            if items:
                with conn.cursor() as cur:
                    for i in tqdm(range(0, len(items), batch_size), desc="content"):
                        chunk = items[i : i + batch_size]
                        texts = [
                            target_features_to_text(ct, tf) for ct, _id, tf in chunk
                        ]
                        raw = encode_batch(encoder, texts, batch_size).to(device)
                        with torch.no_grad():
                            emb = projections.forward_item(raw).cpu().numpy()
                        for j, (ct, cid, _tf) in enumerate(chunk):
                            replace_content_embedding(cur, ct, cid, emb[j].tolist())
                conn.commit()
                print("ContentEmbedding rows written.")

        if users:
            rows = fetch_users(conn)
            print(f"users to embed: {len(rows)}")
            if rows:
                user_ids = [str(r["id"]) for r in rows]
                history_by_user = fetch_user_history_item_vectors(conn, user_ids)
                with conn.cursor() as cur:
                    for i in tqdm(range(0, len(rows), batch_size), desc="users"):
                        chunk = rows[i : i + batch_size]
                        texts = []
                        for r in chunk:
                            uf = {
                                "id": r["id"],
                                "interests": list(r["interests"] or []),
                                "skills": list(r["skills"] or []),
                            }
                            texts.append(user_features_to_text(uf))
                        raw = encode_batch(encoder, texts, batch_size).to(device)
                        with torch.no_grad():
                            emb = projections.forward_user(raw)
                        for j, r in enumerate(chunk):
                            uid = str(r["id"])
                            mixed = blend_user_embedding(
                                emb[j],
                                history_by_user.get(uid),
                                history_alpha=history_alpha,
                            )
                            upsert_user_embedding(
                                cur,
                                uid,
                                list(r["interests"] or []),
                                list(r["skills"] or []),
                                list(r.get("preferredCategories") or []),
                                mixed.cpu().tolist(),
                            )
                conn.commit()
                print("UserProfileML embeddings updated.")
    finally:
        conn.close()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--checkpoint",
        type=str,
        default=None,
        help="Directory containing two_tower.pt and meta.json (not needed with --dry-run)",
    )
    ap.add_argument("--batch-size", type=int, default=64)
    ap.add_argument("--users-only", action="store_true")
    ap.add_argument("--content-only", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--history-alpha",
        type=float,
        default=0.35,
        help="Blend weight for interaction-history item vectors into user embeddings (0..1)",
    )
    args = ap.parse_args()

    if not args.dry_run and not args.checkpoint:
        ap.error("--checkpoint is required unless you use --dry-run")

    users = True
    content = True
    if args.users_only:
        content = False
    if args.content_only:
        users = False

    run_sync(
        args.checkpoint or "",
        args.batch_size,
        users,
        content,
        args.dry_run,
        args.history_alpha,
    )


if __name__ == "__main__":
    main()
