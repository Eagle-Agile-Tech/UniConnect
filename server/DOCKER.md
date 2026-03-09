# Backend Docker Setup

This setup runs:
- `api` (Node/Express backend)
- `db` (PostgreSQL 16 with pgvector)
- `redis` (Redis 7)

## 1) Create Docker env file

From `server/`:

```bash
cp .env.docker.example .env.docker
```

Update `.env.docker` values (at minimum `JWT_SECRET` and `JWT_REFRESH_SECRET`).

## 2) Start all services

```bash
docker compose up --build
```

API runs at `http://localhost:3000`.
Default host ports are:
- API: `3000`
- Postgres: `5433` (container still uses `5432` internally)
- Redis: `6380` (container still uses `6379` internally)

## 3) Run in background

```bash
docker compose up --build -d
```

## 4) Stop services

```bash
docker compose down
```

To also remove persisted DB/Redis data:

```bash
docker compose down -v
```

## Notes

- On startup, `api` runs Prisma migrations with:
  - `npx prisma generate --schema prisma/schema.prisma`
  - `npx prisma migrate deploy --schema prisma/schema.prisma`
- The database image is `pgvector/pgvector:pg16` because your schema/migrations use `CREATE EXTENSION vector`.
