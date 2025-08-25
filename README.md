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

## Quick Start

### Option 1: Quick Start

```bash
cd docker
./start-lakehouse.sh
```

### Option 2: Manual Start

Get the entire lakehouse running in 3 commands:

```bash
# 1. Start all infrastructure
cd docker
docker compose up -d

# 2. Start Jupyter Lab
docker compose exec -d spark jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/home/iceberg/notebooks

# 3. Start Spark UI (optional - in new terminal)
docker compose exec spark pyspark --conf spark.ui.enabled=true --conf spark.ui.port=8080 --conf spark.ui.host=0.0.0.0 --conf spark.driver.host=0.0.0.0
```

**All services will be available at:**

- **Trino**: <http://localhost:8081>
- **MinIO Console**: <http://localhost:9001> (admin/password)
- **Jupyter Lab**: <http://localhost:8888> (get token with `docker compose exec spark jupyter lab list`)
- **PgAdmin**: <http://localhost:5050> (<admin@example.com>/admin)
- **Spark UI**: <http://localhost:8082> (when PySpark is running)

**To stop everything:**

```bash
docker compose down
```

---

## Install dependencies (workspace)

From the repo root:

```bash
uv lock
uv sync
```

## Using Spark

To run Spark applications and access the Spark UI:

### **Method 1: Interactive PySpark shell with UI**

```bash
docker compose exec spark pyspark --conf spark.ui.enabled=true --conf spark.ui.port=8080 --conf spark.ui.host=0.0.0.0 --conf spark.driver.host=0.0.0.0
```

**Spark UI will be available at: <http://localhost:8082>**

### **Method 2: Python script with SparkSession**

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("FootballAnalytics") \
    .config("spark.ui.enabled", "true") \
    .config("spark.ui.port", "8080") \
    .config("spark.ui.host", "0.0.0.0") \
    .config("spark.driver.host", "0.0.0.0") \
    .getOrCreate()

# Your Spark code here
print("Spark UI URL:", spark.sparkContext.uiWebUrl)
```

### **Method 3: Jupyter notebooks**

When you create a SparkSession in Jupyter with the above configuration, the UI will be accessible at <http://localhost:8082>

**Note**: If port 8080 is busy inside the container, Spark will automatically use port 8081, which is mapped to host port 8083.

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
    - Use the commands in the "Quick Start" section above

3. Spark UI not accessible at <http://localhost:8082>

    - The Spark UI only appears when Spark applications are running
    - Start a PySpark shell or run Spark code in Jupyter to activate it
    - See the "Using Spark" section above for examples

4. Services not starting properly

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
- **8082**: Spark UI (primary, when Spark applications are running)
- **8083**: Spark UI (fallback port, if 8080 is busy inside container)
