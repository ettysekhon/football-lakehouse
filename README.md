# football-lakehouse

Minimal, local lakehouse for football analytics with:

- **Apache Iceberg** (REST Catalog) on **MinIO (S3)**
- **Trino** for fast SQL
- **Spark (PySpark)** for ingestion/transforms
- **Streamlit** UI
- **uv 0.8.8** workspaces (single lockfile; multiple packages)

## Prerequisites

- Python 3.12+
- `uv` 0.8.8 or newer
- Docker (with Compose)

---

## Install dependencies (workspace)

From the repo root:

```bash
uv lock
uv sync
```

## Bring up infrastructure

```bash
cd docker
docker compose up -d
```
