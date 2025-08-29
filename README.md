# football-lakehouse

This setup uses Apache Iceberg with an open REST catalog, the lakehouse allows multiple query engines like Spark and Trino to concurrently and safely work on the same tables. This provides a flexible and scalable analytics environment without vendor lock-in.

- **Apache Iceberg** (with REST Catalog)
- **Trino** for fast SQL queries
- **Spark (PySpark)** for ingestion/transforms with Jupyter Lab
- **MinIO** for S3-compatible object storage
- **Streamlit** UI
- **uv 0.8.8** workspaces (single lockfile; multiple packages)

## Issues

This repo is based on the [Databricks Docker Spark Iceberg Repo](https://github.com/databricks/docker-spark-iceberg/blob/main/docker-compose.yml) - if you come across issues related to versioning then please raise an issue on that repo or raise it on this one if issue is specfically with this repo.

## Quick Start

Get the entire lakehouse running in one command:

```bash
make start
```

**All services will be available at:**

- **Trino**: <http://localhost:8080/ui/>
- **MinIO Console**: <http://localhost:9001> (admin/password)
- **Jupyter Lab**: <http://localhost:8888?token={token_id}> (get token with `docker compose exec spark jupyter lab list`)
- **Iceberg REST Catalog**: <http://localhost:8181/v1/config>
- **Superset**:<http://localhost:8089/sqllab/>
- **Spark UI**: <http://localhost:8081> (kept alive by ThriftServer)

**To stop everything:**

```bash
make stop
```

## Architecture Overview

The simplified lakehouse consists of:

```text
┌───────────────────────────────────────────────────┐
│                   Query/Processing                │
│                                                   │
│   ┌─────────────┐        ┌──────────────┐         │
│   │Spark Iceberg│        │    Trino     │         │
│   │   (Jupyter) │        │ (SQL Engine) │         │
│   └─────────────┘        └──────────────┘         │
│          ▲                      ▲                 │
│          │ metadata & data      │ metadata & data │
└──────────┼──────────────────────┼─────────────────┘
           │                      │
┌──────────┼──────────────────────┼─────────────────┐
│          ▼                      ▼                 │
│                   Lakehouse Platform              │
│                                                   │
│   ┌──────────────┐        ┌─────────────┐         │
│   │ Iceberg REST │        │    MinIO    │         │
│   │  (Catalog)   │───────>│ (S3 Storage)│         │
│   └──────────────┘        └─────────────┘         │
│     (metadata)             (table data)           │
└───────────────────────────────────────────────────┘
```

## Test the Setup

```bash
make test
```

## Configuration Files

- **Trino catalog**: `trino/catalog/football.properties`
- **Spark config**: `spark/conf/spark-defaults.conf`
- **Docker services**: `docker-compose.yml`
