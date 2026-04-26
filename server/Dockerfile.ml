FROM node:20-bookworm-slim

WORKDIR /app

# Python is used for the ML pipelines. Node is already present in this base image.
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-pip python3-venv ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Lightweight deps: enables embedding sync into Postgres (psycopg2 + pgvector).
# If you want torch training inside the container, install it separately or extend this image.
# Bookworm images mark the system Python as "externally managed" (PEP 668), so install
# Python deps into a virtualenv instead of site-packages.
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python3 -m venv "${VIRTUAL_ENV}" \
  && pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir psycopg2-binary pgvector

ENV PYTHONPATH=/app

# Default: stay alive so you can run pipelines via `docker compose exec ml ...`.
CMD ["bash", "-lc", "sleep infinity"]
