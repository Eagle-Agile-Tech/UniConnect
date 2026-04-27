#!/usr/bin/env python3
"""Run the full ID-based recommendation training pipeline end to end."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import random
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import importlib.util

from ml.pipelines.dataset_provenance import build_dataset_provenance


ROOT = Path(__file__).resolve().parents[2]
DATASET_GENERATOR = ROOT / "src" / "modules" / "ai-recommendation-service" / "generate-training-dataset.js"
EDA_SCRIPT = Path(__file__).resolve().parent / "eda_dataset.py"
TRAIN_SCRIPT = Path(__file__).resolve().parent / "train_id_two_tower.py"
EVALUATE_SCRIPT = Path(__file__).resolve().parent / "evaluate_id_two_tower.py"
SYNC_SCRIPT = Path(__file__).resolve().parent / "sync_id_embeddings.py"


def esc_json(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: esc_json(v) for k, v in value.items()}
    if isinstance(value, list):
        return [esc_json(v) for v in value]
    if isinstance(value, Path):
        return str(value.resolve())
    return value


def run_command(args: list[str], *, cwd: Path | None = None, capture_output: bool = False) -> subprocess.CompletedProcess[str]:
    print("\n$ " + " ".join(args))
    return subprocess.run(
        args,
        cwd=str(cwd or ROOT),
        text=True,
        capture_output=capture_output,
        check=True,
        env=os.environ.copy(),
    )


def parse_list(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def missing_modules(module_names: list[str]) -> list[str]:
    return [name for name in module_names if importlib.util.find_spec(name) is None]


def has_module(name: str) -> bool:
    return importlib.util.find_spec(name) is not None


def normalize_dataset_to_jsonl(source_path: Path, target_path: Path) -> int:
    if not source_path.exists():
        raise FileNotFoundError(f"Missing dataset path: {source_path}")

    text = source_path.read_text(encoding="utf-8").strip()
    if not text:
        target_path.write_text("", encoding="utf-8")
        return 0

    rows: list[dict[str, Any]]
    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict) and isinstance(parsed.get("rows"), list):
            rows = parsed["rows"]
        elif isinstance(parsed, list):
            rows = parsed
        else:
            rows = [parsed]
    except json.JSONDecodeError:
        rows = []
        for line in text.splitlines():
            line = line.strip()
            if line:
                rows.append(json.loads(line))

    with target_path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row) + "\n")
    return len(rows)


def _seed_from_text(text: str, seed: int) -> int:
    digest = hashlib.sha256(f"{seed}|{text}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _sigmoid(x: float) -> float:
    if x >= 0:
        z = math.exp(-x)
        return 1.0 / (1.0 + z)
    z = math.exp(x)
    return z / (1.0 + z)


def _dot(a: list[float], b: list[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def _norm(v: list[float]) -> float:
    return math.sqrt(sum(x * x for x in v)) or 1.0


def _normalize(v: list[float]) -> list[float]:
    scale = _norm(v)
    return [x / scale for x in v]


def _init_vector(key: str, dim: int, seed: int) -> list[float]:
    rng = random.Random(_seed_from_text(key, seed))
    return [rng.uniform(-0.01, 0.01) for _ in range(dim)]


def _export_vectors(path: Path, rows: list[tuple[str, int, list[float]]], *, kind: str) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for item_id, index, embedding in rows:
            payload = {
                "userId": item_id if kind == "user" else None,
                "itemId": item_id if kind == "item" else None,
                "index": index,
                "embedding": embedding,
            }
            if kind == "item":
                target_type, target_id = item_id.split("::", 1)
                payload.update(
                    {
                        "targetType": target_type,
                        "targetId": target_id,
                    }
                )
            handle.write(json.dumps(payload) + "\n")


def _read_embeddings(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def _build_mappings(examples: list[dict[str, Any]]) -> tuple[dict[str, int], dict[str, int]]:
    user_ids = sorted({str(example["user_id"]) for example in examples})
    item_ids = sorted({str(example["item_id"]) for example in examples})
    return (
        {user_id: index for index, user_id in enumerate(user_ids)},
        {item_id: index for index, item_id in enumerate(item_ids)},
    )


def light_train_and_export(
    train_examples: list[dict[str, Any]],
    out_dir: Path,
    *,
    epochs: int,
    batch_size: int,
    lr: float,
    embedding_dim: int,
    seed: int,
    balance_data: bool = True,
    dataset_provenance: dict[str, Any] | None = None,
) -> dict[str, Any]:
    from ml.features.id_dataset import balance_training_examples

    examples = balance_training_examples(train_examples, seed=seed) if balance_data else list(train_examples)
    if not examples:
        raise SystemExit("No training examples available for the lightweight trainer.")

    user_to_index, item_to_index = _build_mappings(examples)
    user_vectors = {user_id: _init_vector(user_id, embedding_dim, seed) for user_id in user_to_index}
    item_vectors = {item_id: _init_vector(item_id, embedding_dim, seed + 17) for item_id in item_to_index}

    reg = 1e-4
    history: list[dict[str, float]] = []

    for epoch in range(epochs):
        rng = random.Random(seed + epoch)
        shuffled = examples[:]
        rng.shuffle(shuffled)

        epoch_loss = 0.0
        steps = 0
        for example in shuffled:
            user_id = example["user_id"]
            item_id = example["item_id"]
            label = float(example["label"])
            u = user_vectors[user_id]
            v = item_vectors[item_id]
            score = _dot(u, v) / math.sqrt(max(1, embedding_dim))
            pred = _sigmoid(score)
            error = label - pred
            eps = 1e-12
            epoch_loss += -(
                label * math.log(max(pred, eps)) + (1.0 - label) * math.log(max(1.0 - pred, eps))
            )
            steps += 1

            u_old = u[:]
            v_old = v[:]
            for i in range(embedding_dim):
                ui = u_old[i]
                vi = v_old[i]
                u[i] = ui + lr * (error * vi - reg * ui)
                v[i] = vi + lr * (error * ui - reg * vi)

        average_loss = epoch_loss / max(1, steps)
        history.append({"epoch": epoch + 1, "loss": average_loss})
        print(f"epoch {epoch + 1}/{epochs} loss={average_loss:.6f}")

    normalized_users = {user_id: _normalize(vec) for user_id, vec in user_vectors.items()}
    normalized_items = {item_id: _normalize(vec) for item_id, vec in item_vectors.items()}

    out_dir.mkdir(parents=True, exist_ok=True)
    _export_vectors(
        out_dir / "user_embeddings.jsonl",
        [(user_id, user_to_index[user_id], normalized_users[user_id]) for user_id in sorted(user_to_index, key=user_to_index.get)],
        kind="user",
    )
    _export_vectors(
        out_dir / "item_embeddings.jsonl",
        [(item_id, item_to_index[item_id], normalized_items[item_id]) for item_id in sorted(item_to_index, key=item_to_index.get)],
        kind="item",
    )
    (out_dir / "id_mappings.json").write_text(
        json.dumps({"user_to_index": user_to_index, "item_to_index": item_to_index}, indent=2),
        encoding="utf-8",
    )
    (out_dir / "meta.json").write_text(
        json.dumps(
            {
                "model_type": "id_two_tower_light",
                "embedding_dim": embedding_dim,
                "num_users": len(user_to_index),
                "num_items": len(item_to_index),
                "epochs_trained": len(history),
                "history": history,
                "trainer": "lightweight-pure-python",
                "dataset": dataset_provenance,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (out_dir / "training_history.json").write_text(json.dumps(history, indent=2), encoding="utf-8")

    # Simple SVG loss chart.
    losses = [float(item["loss"]) for item in history]
    width, height = 960, 420
    pad_l, pad_r, pad_t, pad_b = 80, 30, 60, 80
    plot_w = max(10, width - pad_l - pad_r)
    plot_h = max(10, height - pad_t - pad_b)
    min_loss = min(losses)
    max_loss = max(losses) if max(losses) != min(losses) else min(losses) + 1.0
    step = plot_w / max(len(losses) - 1, 1)
    points = []
    for idx, loss in enumerate(losses):
        x = pad_l + idx * step
        y = pad_t + plot_h - ((loss - min_loss) / (max_loss - min_loss)) * plot_h
        points.append(f"{x:.1f},{y:.1f}")
    svg = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}'>",
        "<rect x='0' y='0' width='100%' height='100%' fill='#f8fafc'/>",
        "<text x='480' y='32' text-anchor='middle' font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' font-size='18' fill='#0f172a'>Training Loss by Epoch</text>",
        f"<line x1='{pad_l}' y1='{pad_t}' x2='{pad_l}' y2='{pad_t+plot_h}' stroke='#0f172a' stroke-width='1'/>",
        f"<line x1='{pad_l}' y1='{pad_t+plot_h}' x2='{pad_l+plot_w}' y2='{pad_t+plot_h}' stroke='#0f172a' stroke-width='1'/>",
        f"<polyline fill='none' stroke='#2563eb' stroke-width='3' points='{' '.join(points)}'/>",
    ]
    for idx, loss in enumerate(losses):
        x = pad_l + idx * step
        y = pad_t + plot_h - ((loss - min_loss) / (max_loss - min_loss)) * plot_h
        svg.append(f"<circle cx='{x:.1f}' cy='{y:.1f}' r='4.5' fill='#1d4ed8'/>")
        svg.append(f"<text x='{x:.1f}' y='{max(pad_t + 12, y - 10):.1f}' text-anchor='middle' font-family='ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial' font-size='11' fill='#0f172a'>{loss:.4f}</text>")
    svg.append("</svg>")
    (out_dir / "training_curve.svg").write_text("\n".join(svg) + "\n", encoding="utf-8")

    return {
        "user_to_index": user_to_index,
        "item_to_index": item_to_index,
        "user_vectors": normalized_users,
        "item_vectors": normalized_items,
        "history": history,
    }


def light_evaluate(
    rows: list[dict[str, Any]],
    user_to_index: dict[str, int],
    item_to_index: dict[str, int],
    user_vectors: dict[str, list[float]],
    item_vectors: dict[str, list[float]],
) -> dict[str, Any]:
    from collections import defaultdict

    scores: list[float] = []
    labels: list[int] = []
    logloss_sum = 0.0
    correct = 0
    n = 0
    relevant_by_user: dict[str, set[str]] = defaultdict(set)

    for row in rows:
        uid = str(row.get("userId") or "").strip()
        tid = str(row.get("targetId") or "").strip()
        ttype = str(row.get("targetType") or "").strip().upper()
        if not uid or not tid or not ttype:
            continue
        item_key = f"{ttype}::{tid}"
        label = 1 if float(row.get("label", 0) or 0) > 0 else 0
        if label == 1:
            relevant_by_user[uid].add(item_key)
        if uid not in user_vectors or item_key not in item_vectors:
            continue
        score = _dot(user_vectors[uid], item_vectors[item_key])
        pred = _sigmoid(score)
        scores.append(pred)
        labels.append(label)
        eps = 1e-12
        logloss_sum += -(label * math.log(max(pred, eps)) + (1 - label) * math.log(max(1 - pred, eps)))
        correct += 1 if (pred >= 0.5) == bool(label) else 0
        n += 1

    def roc_auc(vals: list[float], labs: list[int]) -> float:
        paired = [(s, int(l)) for s, l in zip(vals, labs)]
        pos = sum(1 for _s, l in paired if l == 1)
        neg = len(paired) - pos
        if pos == 0 or neg == 0:
            return 0.0
        paired.sort(key=lambda x: x[0])
        ranks = [0.0] * len(paired)
        i = 0
        while i < len(paired):
            j = i + 1
            while j < len(paired) and paired[j][0] == paired[i][0]:
                j += 1
            avg_rank = (i + 1 + j) / 2.0
            for k in range(i, j):
                ranks[k] = avg_rank
            i = j
        sum_ranks_pos = sum(r for r, (_s, l) in zip(ranks, paired) if l == 1)
        return float((sum_ranks_pos - (pos * (pos + 1) / 2.0)) / (pos * neg))

    def precision_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
        if k <= 0 or not ranked:
            return 0.0
        return sum(1 for x in ranked[:k] if x in relevant) / float(k)

    def recall_at_k(ranked: list[str], relevant: set[str], k: int) -> float:
        if not relevant:
            return 0.0
        return sum(1 for x in ranked[:k] if x in relevant) / float(len(relevant))

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
        return dcg / idcg if idcg else 0.0

    auc = roc_auc(scores, labels) if n else 0.0
    accuracy = (correct / n) if n else 0.0
    logloss = (logloss_sum / n) if n else 0.0

    eval_users = [u for u, rel in relevant_by_user.items() if rel]
    item_keys = list(item_to_index.keys())

    p_scores: list[float] = []
    r_scores: list[float] = []
    ap_scores: list[float] = []
    ndcg_scores: list[float] = []
    for uid in eval_users:
        if uid not in user_vectors:
            continue
        rel = relevant_by_user.get(uid, set())
        ranked = sorted(
            item_keys,
            key=lambda key: _dot(user_vectors[uid], item_vectors[key]),
            reverse=True,
        )
        p_scores.append(precision_at_k(ranked, rel, 10))
        r_scores.append(recall_at_k(ranked, rel, 10))
        ap_scores.append(average_precision_at_k(ranked, rel, 10))
        ndcg_scores.append(ndcg_at_k(ranked, rel, 10))

    return {
        "rows": len(rows),
        "pairsEvaluated": n,
        "classification": {
            "accuracy": accuracy,
            "logloss": logloss,
            "rocAuc": auc,
        },
        "retrieval": {
            "usersEvaluated": len(eval_users),
            "precision@10": (sum(p_scores) / max(1, len(p_scores))) if p_scores else 0.0,
            "recall@10": (sum(r_scores) / max(1, len(r_scores))) if r_scores else 0.0,
            "map@10": (sum(ap_scores) / max(1, len(ap_scores))) if ap_scores else 0.0,
            "ndcg@10": (sum(ndcg_scores) / max(1, len(ndcg_scores))) if ndcg_scores else 0.0,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-dir",
        type=str,
        default=str(ROOT / "ml" / "runs" / "id_two_tower"),
        help="Directory where the full pipeline run will be written",
    )
    parser.add_argument("--days", type=int, default=None)
    parser.add_argument("--limit", type=int, default=5000)
    parser.add_argument("--target-types", type=str, default="")
    parser.add_argument("--user-ids", type=str, default="")
    parser.add_argument(
        "--dataset-path",
        type=str,
        default="",
        help="Use an existing exported dataset instead of generating one live",
    )
    parser.add_argument("--raw", action="store_true", help="Export raw interaction rows instead of aggregated rows")
    parser.add_argument(
        "--skip-generate",
        action="store_true",
        help="Skip live dataset generation and use --dataset-path",
    )
    parser.add_argument("--test-ratio", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--epochs", type=int, default=10)
    parser.add_argument("--batch-size", type=int, default=128)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--embedding-dim", type=int, default=1536)
    parser.add_argument("--skip-sync", action="store_true")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = out_dir / run_id
    dataset_path = run_dir / "training_data.jsonl"
    eda_dir = run_dir / "eda"
    checkpoint_dir = run_dir / "checkpoints"
    run_dir.mkdir(parents=True, exist_ok=True)

    target_types = parse_list(args.target_types)
    user_ids = parse_list(args.user_ids)
    torch_available = has_module("torch")
    sync_modules_available = has_module("psycopg2") and has_module("pgvector")

    pipeline_config = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "root": ROOT,
        "runDir": run_dir,
        "datasetPath": dataset_path,
        "edaDir": eda_dir,
        "checkpointDir": checkpoint_dir,
        "options": {
            "days": args.days,
            "limit": args.limit,
            "targetTypes": target_types,
            "userIds": user_ids,
            "datasetPath": args.dataset_path or None,
            "skipGenerate": args.skip_generate,
            "torchAvailable": torch_available,
            "raw": args.raw,
            "testRatio": args.test_ratio,
            "seed": args.seed,
            "epochs": args.epochs,
            "batchSize": args.batch_size,
            "lr": args.lr,
            "embeddingDim": args.embedding_dim,
            "skipSync": args.skip_sync,
        },
    }

    write_json(run_dir / "pipeline_config.json", esc_json(pipeline_config))

    if args.skip_generate:
        if not args.dataset_path:
            raise SystemExit("--skip-generate requires --dataset-path")
        source_dataset = Path(args.dataset_path).expanduser()
        if not source_dataset.is_absolute():
            source_dataset = (ROOT / source_dataset).resolve()
        print(f"Using existing dataset: {source_dataset}")
        rows_written = normalize_dataset_to_jsonl(source_dataset, dataset_path)
    else:
        generate_args = [
            "node",
            str(DATASET_GENERATOR),
            "--format",
            "jsonl",
            "--output",
            str(dataset_path),
            "--limit",
            str(args.limit),
        ]
        if args.days is not None:
            generate_args += ["--days", str(args.days)]
        if target_types:
            generate_args += ["--target-types", ",".join(target_types)]
        if user_ids:
            generate_args += ["--user-ids", ",".join(user_ids)]
        if args.raw:
            generate_args.append("--raw")

        print("Generating training data from live interactions...")
        run_command(generate_args, cwd=ROOT)
        with dataset_path.open("r", encoding="utf-8") as handle:
            rows_written = sum(1 for _ in handle)

    dataset_provenance = build_dataset_provenance(dataset_path)

    print("Building dataset EDA, charts, and train/test split...")
    run_command(
        [
            sys.executable,
            str(EDA_SCRIPT),
            "--data",
            str(dataset_path),
            "--out-dir",
            str(eda_dir),
            "--split",
            "--test-ratio",
            str(args.test_ratio),
            "--seed",
            str(args.seed),
        ],
        cwd=ROOT,
    )

    train_path = eda_dir / f"{dataset_path.stem}.train.jsonl"
    test_path = eda_dir / f"{dataset_path.stem}.test.jsonl"

    if torch_available:
        print("Training the ID-based two-tower model...")
        run_command(
            [
                sys.executable,
                str(TRAIN_SCRIPT),
                "--data",
                str(train_path),
                "--out",
                str(checkpoint_dir),
                "--epochs",
                str(args.epochs),
                "--batch-size",
                str(args.batch_size),
                "--lr",
                str(args.lr),
                "--embedding-dim",
                str(args.embedding_dim),
                "--seed",
                str(args.seed),
            ],
            cwd=ROOT,
        )
    else:
        print("Training the lightweight pure-Python fallback model...")
        from ml.features.id_dataset import load_training_examples

        train_examples = load_training_examples(train_path)
        light_train_and_export(
            train_examples,
            checkpoint_dir,
            epochs=args.epochs,
            batch_size=args.batch_size,
            lr=args.lr,
            embedding_dim=args.embedding_dim,
            seed=args.seed,
            dataset_provenance=dataset_provenance,
        )

    evaluation: dict[str, Any] | None = None
    if test_path.exists():
        print("Evaluating on the held-out split...")
        if torch_available:
            result = run_command(
                [
                    sys.executable,
                    str(EVALUATE_SCRIPT),
                    "--data",
                    str(test_path),
                    "--checkpoint",
                    str(checkpoint_dir),
                ],
                cwd=ROOT,
                capture_output=True,
            )
            print(result.stdout.strip())
            evaluation = json.loads(result.stdout)
        else:
            from ml.features.id_dataset import load_rows

            test_rows = load_rows(test_path)
            train_rows = load_rows(train_path)
            user_to_index = json.loads((checkpoint_dir / "id_mappings.json").read_text(encoding="utf-8"))["user_to_index"]
            item_to_index = json.loads((checkpoint_dir / "id_mappings.json").read_text(encoding="utf-8"))["item_to_index"]
            user_vectors = {
                row["userId"]: row["embedding"]
                for row in _read_embeddings(checkpoint_dir / "user_embeddings.jsonl")
            }
            item_vectors = {
                f'{row["targetType"]}::{row["targetId"]}': row["embedding"]
                for row in _read_embeddings(checkpoint_dir / "item_embeddings.jsonl")
            }
            evaluation = light_evaluate(
                test_rows,
                user_to_index,
                item_to_index,
                user_vectors,
                item_vectors,
            )
            if evaluation["pairsEvaluated"] == 0:
                evaluation = light_evaluate(
                    train_rows,
                    user_to_index,
                    item_to_index,
                    user_vectors,
                    item_vectors,
                )
                evaluation["evaluationDataset"] = "train-proxy"
            print(json.dumps(evaluation, indent=2))
    else:
        print("No test split was created, skipping evaluation.")

    sync_result: dict[str, Any] | None = None
    if not args.skip_sync and sync_modules_available:
        print("Syncing trained embeddings into pgvector-backed tables...")
        result = run_command(
            [
                sys.executable,
                str(SYNC_SCRIPT),
                "--checkpoint",
                str(checkpoint_dir),
            ],
            cwd=ROOT,
            capture_output=True,
        )
        print(result.stdout.strip())
        sync_result = json.loads(result.stdout)
    elif not args.skip_sync:
        print("Skipping pgvector sync because psycopg2/pgvector are not installed.")

    eda_summary_path = eda_dir / "eda_summary.json"
    split_info_json_path = eda_dir / "split_info.json"
    history_path = checkpoint_dir / "training_history.json"
    meta_path = checkpoint_dir / "meta.json"

    pipeline_summary = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "runDir": run_dir,
        "dataset": {
            "path": dataset_path,
            "source": str(Path(args.dataset_path).expanduser().resolve()) if args.dataset_path else None,
            "rowsWritten": rows_written,
            "summary": json.loads(eda_summary_path.read_text(encoding="utf-8")) if eda_summary_path.exists() else None,
        },
        "split": json.loads(split_info_json_path.read_text(encoding="utf-8")) if split_info_json_path.exists() else None,
        "training": json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else None,
        "history": json.loads(history_path.read_text(encoding="utf-8")) if history_path.exists() else None,
        "evaluation": evaluation,
        "sync": sync_result,
        "artifacts": {
            "dataset": dataset_path,
            "edaDir": eda_dir,
            "checkpointDir": checkpoint_dir,
            "trainingCurve": checkpoint_dir / "training_curve.svg",
        },
    }
    write_json(run_dir / "pipeline_summary.json", esc_json(pipeline_summary))

    print("\nPipeline complete.")
    print(f"Run directory: {run_dir.resolve()}")
    print(f"Training curve: {(checkpoint_dir / 'training_curve.svg').resolve()}")
    print(f"EDA charts: {eda_dir.resolve()}")


if __name__ == "__main__":
    main()
