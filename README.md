# football-lakehouse

Minimal, local lakehouse for football analytics with:

- **Apache Iceberg** (Hive Metastore HMS)
- **Trino** for fast SQL queries
- **Spark (PySpark)** for ingestion/transforms with Jupyter Lab
- **MinIO** for S3-compatible object storage
- **PostgreSQL** for Hive Metastore database
- **PgAdmin** for database administration
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

## Start Jupyter Lab (for Spark notebooks)

After the containers are running, start Jupyter Lab manually:

```bash
docker compose exec -d spark jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/home/iceberg/notebooks
```

Get the access token:

```bash
docker compose exec spark jupyter lab list
```

## Access Services

Once all services are running, you can access:

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| **Trino Web UI** | [http://localhost:8081](http://localhost:8081) | None | SQL query interface |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001) | admin/password | Object storage admin |
| **Jupyter Lab** | [http://localhost:8888](http://localhost:8888) | Use token from above | Spark notebooks |
| **PgAdmin** | [http://localhost:5050](http://localhost:5050) | <admin@example.com>/admin | Database administration |

## Service Status

Check if all services are running:

```bash
docker compose ps
```

You should see all services as "Up" and Trino as "healthy".

## Create the schema

```bash
docker compose exec trino trino --execute "SHOW CATALOGS"

docker compose exec trino trino --execute "SHOW SCHEMAS FROM iceberg"

docker compose exec trino trino --execute "CREATE SCHEMA IF NOT EXISTS iceberg.football"

docker compose exec trino trino --execute "SHOW SCHEMAS FROM iceberg"

docker compose exec trino trino --execute "SHOW TABLES FROM iceberg.football"
```

## Architecture Overview

The lakehouse consists of:

```text
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Jupyter   │    │    Trino     │    │   PgAdmin   │
│  (Spark)    │    │ (SQL Engine) │    │ (DB Admin)  │
│ port: 8888  │    │ port: 8081   │    │ port: 5050  │
└─────────────┘    └──────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│    MinIO    │    │     Hive     │    │ PostgreSQL  │
│ (S3 Storage)│◄──►│  Metastore   │◄──►│ (HMS DB)    │
│port:9000/01 │    │ port: 9083   │    │ port: 5432  │
└─────────────┘    └──────────────┘    └─────────────┘
```

## Troubleshooting

### Common Issues

1. Trino fails to start with S3 configuration errors

    - The Trino S3 configuration is handled via environment variables in the Docker Compose file
    - S3 properties should NOT be in the `iceberg.properties` file

2. Jupyter Lab not accessible

    - Jupyter needs to be started manually after containers are up
    - Use the commands in the "Start Jupyter Lab" section above

3. Services not starting properly

- Check container status: `docker compose ps`
- Check logs: `docker compose logs <service-name>`
- Restart in order: `docker compose up -d postgres minio metastore trino`

### Complete Reset

To completely reset the environment:

```bash
cd docker
docker compose down
docker compose up -d postgres
docker compose rm -sf metastore
docker compose up -d metastore

# Wait for metastore to initialise, then start other services
docker compose up -d minio trino

# Start remaining services
docker compose up -d
```

### Manual Metastore Initialization

If the metastore fails to initialise automatically:

```bash
# Verify files are mounted correctly
docker compose exec metastore ls -l /opt/hive-metastore/conf/metastore-site.xml
docker compose exec metastore ls -l /opt/hive-metastore/lib/postgresql.jar

# Initialise schema manually (first time only)
docker compose exec metastore schematool -dbType postgres -initSchema --verbose
```

### Configuration Files

- **Trino catalog**: `catalog/trino/iceberg.properties`
- **Hive Metastore**: `docker/metastore-site.xml`
- **Docker services**: `docker/compose.yml`
- **PostgreSQL JAR**: `docker/postgresql.jar`

### Port Mappings

- **8081**: Trino Web UI
- **9000**: MinIO S3 API
- **9001**: MinIO Console
- **8888**: Jupyter Lab
- **5050**: PgAdmin
- **5432**: PostgreSQL
- **9083**: Hive Metastore (internal)
- **8082**: Spark UI (if enabled)
