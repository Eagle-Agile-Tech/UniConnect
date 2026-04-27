#!/usr/bin/env python3
"""Write trained ID-based user/item embeddings into pgvector-backed tables."""

from __future__ import annotations

import argparse
import json
import os
import uuid
from pathlib import Path
from typing import Any

import psycopg2
from pgvector.psycopg2 import register_vector


ROOT = Path(__file__).resolve().parents[2]

EMBEDDING_SOURCE = "id-two-tower"


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
        raise SystemExit("Set DATABASE_URL before syncing embeddings.")
    if "schema=" in dsn.lower():
        return dsn.split("?")[0]
    return dsn


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise SystemExit(f"Missing file: {path}")
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))
    return rows


def fetch_existing_user_ml(cur, user_id: str) -> dict[str, Any] | None:
    cur.execute(
        """
        SELECT "userId", "interests", "skills", "preferredCategories"
        FROM "UserProfileML"
        WHERE "userId" = %s
        LIMIT 1
        """,
        (user_id,),
    )
    row = cur.fetchone()
    if not row:
        return None
    return {
        "userId": row[0],
        "interests": row[1] or [],
        "skills": row[2] or [],
        "preferredCategories": row[3] or [],
    }


def user_exists(cur, user_id: str) -> bool:
    cur.execute(
        """
        SELECT 1
        FROM "User"
        WHERE "id" = %s
        LIMIT 1
        """,
        (user_id,),
    )
    return cur.fetchone() is not None


def fetch_profile_defaults(cur, user_id: str) -> dict[str, Any]:
    cur.execute(
        """
        SELECT COALESCE("interests", ARRAY[]::text[]) AS interests
        FROM "UserProfile"
        WHERE "userId" = %s
        LIMIT 1
        """,
        (user_id,),
    )
    row = cur.fetchone()
    return {
        "interests": row[0] if row and row[0] is not None else [],
        "skills": [],
        "preferredCategories": [],
    }


def upsert_user_embedding(cur, user_id: str, embedding: list[float]) -> None:
    existing = fetch_existing_user_ml(cur, user_id)
    values = existing or {"userId": user_id, **fetch_profile_defaults(cur, user_id)}
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
            values["interests"],
            values["skills"],
            values["preferredCategories"],
            embedding,
            EMBEDDING_SOURCE,
        ),
    )


def replace_content_embedding(
    cur,
    target_type: str,
    target_id: str,
    embedding: list[float],
) -> None:
    cur.execute(
        """
        DELETE FROM "ContentEmbedding"
        WHERE "contentType" = %s AND "contentId" = %s
        """,
        (target_type, target_id),
    )
    cur.execute(
        """
        INSERT INTO "ContentEmbedding" ("id", "contentType", "contentId", "embedding", "embeddingSource", "createdAt", "updatedAt")
        VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
        """,
        (str(uuid.uuid4()), target_type, target_id, embedding, EMBEDDING_SOURCE),
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=str(ROOT / "ml" / "two_tower" / "checkpoints" / "id_two_tower_run"),
        help="Directory created by train_id_two_tower.py",
    )
    parser.add_argument("--skip-users", action="store_true")
    parser.add_argument("--skip-items", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    checkpoint_dir = Path(args.checkpoint)
    user_rows = load_jsonl(checkpoint_dir / "user_embeddings.jsonl")
    item_rows = load_jsonl(checkpoint_dir / "item_embeddings.jsonl")

    if args.dry_run:
        print(
            json.dumps(
                {
                    "checkpoint": str(checkpoint_dir.resolve()),
                    "users": 0 if args.skip_users else len(user_rows),
                    "items": 0 if args.skip_items else len(item_rows),
                },
                indent=2,
            )
        )
        return

    conn = psycopg2.connect(connect_dsn())
    register_vector(conn)
    synced_users = 0
    skipped_users = 0
    try:
        with conn.cursor() as cur:
            if not args.skip_users:
                for row in user_rows:
                    user_id = str(row["userId"])
                    if not user_exists(cur, user_id):
                        skipped_users += 1
                        continue
                    upsert_user_embedding(cur, user_id, list(row["embedding"]))
                    synced_users += 1

            if not args.skip_items:
                for row in item_rows:
                    replace_content_embedding(
                        cur,
                        str(row["targetType"]),
                        str(row["targetId"]),
                        list(row["embedding"]),
                    )

        conn.commit()
        print(
            json.dumps(
                {
                    "syncedUsers": 0 if args.skip_users else synced_users,
                    "skippedUsers": 0 if args.skip_users else skipped_users,
                    "syncedItems": 0 if args.skip_items else len(item_rows),
                    "checkpoint": str(checkpoint_dir.resolve()),
                },
                indent=2,
            )
        )
    finally:
        conn.close()


if __name__ == "__main__":
    main()
