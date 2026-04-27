#!/usr/bin/env python3
"""Run offline recommendation benchmarks across available recommenders."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from ml.pipelines.dataset_provenance import build_dataset_provenance


ROOT = Path(__file__).resolve().parents[2]
ID_EVAL = ROOT / "ml" / "pipelines" / "evaluate_id_two_tower.py"
SEMANTIC_EVAL = ROOT / "ml" / "models" / "two_tower" / "evaluate.py"
DEFAULT_DATA = ROOT / "ml" / "eda" / "refreshed" / "training_data.test.jsonl"
DEFAULT_ID_CKPT = ROOT / "ml" / "two_tower" / "checkpoints" / "id_two_tower_run"
DEFAULT_SEMANTIC_CKPT = ROOT / "ml" / "two_tower" / "checkpoints" / "two_tower_run"
DEFAULT_VENV_SITE_PACKAGES = (
    ROOT / "ml" / "two_tower" / ".venv" / "lib" / f"python{sys.version_info.major}.{sys.version_info.minor}" / "site-packages"
)


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    pythonpath_parts = [str(ROOT)]
    if DEFAULT_VENV_SITE_PACKAGES.exists():
        pythonpath_parts.append(str(DEFAULT_VENV_SITE_PACKAGES))
    extra_pythonpath = ":".join(pythonpath_parts)
    env["PYTHONPATH"] = (
        f"{extra_pythonpath}:{env['PYTHONPATH']}"
        if env.get("PYTHONPATH")
        else extra_pythonpath
    )
    return subprocess.run(
        args,
        cwd=str(ROOT),
        env=env,
        text=True,
        capture_output=True,
    )


def parse_semantic_metrics(stdout: str) -> dict[str, Any]:
    cleaned = " ".join(stdout.strip().split())
    metrics = {}
    for key in ["Precision@10", "Recall@20", "MRR@10", "MAP@10", "nDCG@10"]:
        match = re.search(rf"{re.escape(key)}=([0-9.]+)", cleaned)
        if match:
            metrics[key] = float(match.group(1))
    users_match = re.search(r"users=([0-9]+)", cleaned)
    items_match = re.search(r"items=([0-9]+)", cleaned)
    if users_match:
        metrics["users"] = int(users_match.group(1))
    if items_match:
        metrics["items"] = int(items_match.group(1))
    metrics["raw"] = stdout.strip()
    return metrics


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=str, default=str(DEFAULT_DATA))
    parser.add_argument("--id-checkpoint", type=str, default=str(DEFAULT_ID_CKPT))
    parser.add_argument("--semantic-checkpoint", type=str, default=str(DEFAULT_SEMANTIC_CKPT))
    parser.add_argument("--python", type=str, default=sys.executable)
    args = parser.parse_args()

    dataset = build_dataset_provenance(args.data)
    results: dict[str, Any] = {
        "dataset": dataset,
        "runs": {},
    }

    id_proc = run(
        [
            args.python,
            str(ID_EVAL),
            "--data",
            args.data,
            "--checkpoint",
            args.id_checkpoint,
            "--k",
            "10",
        ]
    )
    if id_proc.returncode == 0:
        results["runs"]["id_two_tower"] = {
            "ok": True,
            "metrics": json.loads(id_proc.stdout),
        }
    else:
        results["runs"]["id_two_tower"] = {
            "ok": False,
            "error": id_proc.stdout.strip() or id_proc.stderr.strip(),
        }

    semantic_proc = run(
        [
            args.python,
            str(SEMANTIC_EVAL),
            "--data",
            args.data,
            "--checkpoint",
            args.semantic_checkpoint,
            "--k-precision",
            "10",
            "--k-recall",
            "20",
            "--k-mrr",
            "10",
            "--k-map",
            "10",
            "--k-ndcg",
            "10",
        ]
    )
    if semantic_proc.returncode == 0:
        results["runs"]["semantic_two_tower"] = {
            "ok": True,
            "metrics": parse_semantic_metrics(semantic_proc.stdout),
            "stderr": semantic_proc.stderr.strip() or None,
        }
    else:
        results["runs"]["semantic_two_tower"] = {
            "ok": False,
            "error": semantic_proc.stdout.strip() or semantic_proc.stderr.strip(),
        }

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
