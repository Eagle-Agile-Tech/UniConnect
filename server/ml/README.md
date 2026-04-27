# ML Recommendation Layout

This directory isolates the AI recommendation workflow from the Node.js app code and gives us a place to keep training, inference, and exports cleanly separated.

## Current Reality

Today the pipeline is split across:

- `server/src/modules/ai-recommendation-service/` for dataset export and API serving
- `server/ml/features/` for row parsing and dataset shaping
- `server/ml/models/two_tower/` for the PyTorch model and projection training
- `server/ml/pipelines/` for CLI entrypoints and orchestration
- `server/ml/two_tower/` for checkpoints, virtualenvs, and other artifacts
- `server/ml/eda/` and `server/ml/runs/` for generated analysis and pipeline outputs

That works, but it is still too flat for long-term maintenance.

## Recommended Production Layout

```text
server/ml/
  README.md
  .gitignore
  data/
    raw/
    processed/
    exports/
  features/
    dataset.py
    feature_text.py
    id_dataset.py
  pipelines/
    eda.py
    eda_dataset.py
    split_dataset.py
    train_id_two_tower.py
    evaluate_id_two_tower.py
    sync_embeddings.py
    sync_id_embeddings.py
    run_id_pipeline.py
  models/
    two_tower/
      model.py
      train.py
      evaluate.py
      requirements.txt
      requirements-id.txt
  two_tower/
    checkpoints/
    .venv/
  eda/
  runs/
```

## What Belongs Where

- `features/` should own row parsing, feature normalization, negative sampling, and dataset shaping.
- `models/two_tower/` should own the actual PyTorch model and training logic.
- `pipelines/` should be thin command-line entrypoints that orchestrate the steps end to end.
- `serving/` should contain shared runtime helpers used by the API when resolving embeddings and checkpoints.
- `artifacts/` should hold anything generated at runtime: checkpoints, plots, split datasets, and run metadata.
- `data/` should hold exported training datasets and other persisted inputs that are not source code.

## Recommended Rules

- Keep `.venv/` only in one place per developer machine, and never commit it.
- Keep generated data out of `git status` by writing it under `server/ml/two_tower/checkpoints/`, `server/ml/eda/`, or `server/ml/runs/`.
- Keep API-serving code in `server/src/modules/ai-recommendation-service/` and use the `ml/pipelines` scripts as the handoff point into Python.

## Existing Ignore Policy

The repository already ignores:

- `.venv/`
- `server/.venv/`
- `server/ml/two_tower/.venv/`
- `server/ml/eda/`
- `server/ml/runs/`
- `server/ml/training_data*.jsonl`
- `server/ml/two_tower/checkpoints/`

That means the repo can keep the source files tracked while the generated training outputs stay local.
