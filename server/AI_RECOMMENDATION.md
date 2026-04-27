# AI Recommendation Integration

The recommendation pipeline is now wired end to end:

1. User behavior is captured in `UserInteraction`.
2. Training data is exported from live interaction/context data.
3. The two-tower model trains on the generated dataset.
4. Trained embeddings are synced into `UserProfileML.embedding` and `ContentEmbedding.embedding`.
5. The API serves personalized recommendations when embeddings exist, and automatically falls back to non-personalized content when they do not.

## API Endpoints

- `POST /api/v1/interactions`
- `GET /api/v1/interactions`
- `GET /api/v1/recommendations`
- `GET /api/v1/recommendations/:userId`
- `GET /api/v1/recommendations/status`
- `GET /api/admin/recommendations/training-dataset`

## Common Commands

Run from `server/`:

```bash
npm run dataset:training:jsonl
npm run ai:pipeline:id
```

By default the dataset exporter will also add lightweight negative samples (unseen items per user) so the two-tower model has contrast during training. You can disable that if you want:

```bash
node src/modules/ai-recommendation-service/generate-training-dataset.js --format jsonl --output ml/training_data.jsonl --negatives-per-positive 0
```

Full ID-based pipeline with EDA charts and training visualization:

```bash
npm run ai:pipeline:id
```

If you only want the ID-based training stack, install the lighter environment:

```bash
python3 -m venv server/.venv
server/.venv/bin/pip install -r server/ml/models/two_tower/requirements-id.txt
```

ID-based pipeline stages if you want to run them manually:

```bash
npm run ml:eda:id
npm run ml:train:id
npm run ml:evaluate:id
npm run ml:sync:id
```

To tell the API which embedding pipeline is intended to be active:

```bash
export RECOMMENDATION_EMBEDDING_SOURCE=id-two-tower
```

Supported values:

- `legacy-semantic`
- `id-two-tower`

## Notes

- Personalized recommendations require both user and content embeddings.
- If embeddings are missing or pgvector-backed scoring is unavailable, the API still returns fallback recommendations instead of failing.
- `GET /api/v1/recommendations/status` is the quickest way to confirm whether the personalized path is ready.
- `GET /api/v1/recommendations/status` now also reports the configured and active embedding source so you can confirm rollout state before changing traffic.
- The original SentenceTransformer projection pipeline remains intact and can continue to act as the fallback source of embeddings.
- The ID-based two-tower path writes trained vectors into the same pgvector-backed tables, so the serving API does not need to change.
- In Docker, the default now uses `RECOMMENDATION_EMBEDDING_SOURCE=id-two-tower`, so the API and `ml` service boot into the ID-based path unless you override it.
- The ID-based trainer now writes `training_history.json` and `training_curve.svg` into the checkpoint directory.

### Small User Base (Cold Start)

If your user base is still small (for example ~42 users), the interaction graph is sparse and a pure ID-based recommender can overfit or fail to generalize.

In that phase, prioritize the **optimized ranking model**:

- Ensure `UserProfileML.embedding` + `ContentEmbedding.embedding` are synced (pgvector).
- Serve real-time vector ranking via `GET /api/v1/recommend/:userId` (user vector → cosine search → ranked items).
