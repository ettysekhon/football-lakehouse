# Football Lakehouse - Docker Scripts

This directory contains the Docker setup and helper scripts for the Football Lakehouse.

## Quick Start

```bash
# Recommended: Smart startup with PostgreSQL initialisation
./start-lakehouse.sh
```

## Helper Scripts

### `./start-lakehouse.sh`

**Smart startup script** - Detects if PostgreSQL metastore needs initialisation and handles it automatically.

- Best for regular use
- Auto-detects database setup
- Starts all services properly

### `./init-metastore.sh`

**PostgreSQL metastore initialisation** - Sets up PostgreSQL-based Hive Metastore properly.

- Use for first-time setup
- Use to fix Derby fallback issues
- Ensures 83 metastore tables are created

### `./check-database.sh` 🔍

**Database status checker** - Verifies PostgreSQL setup and detects Derby usage.

- Check current database status
- Detect Derby fallback issues
- Show metastore table count

## Common Usage Patterns

### First Time Setup

```bash
./init-metastore.sh
```

### Regular Startup

```bash
./start-lakehouse.sh
```

### Troubleshooting Database Issues

```bash
# Check current status
./check-database.sh

# Fix PostgreSQL setup if needed
./init-metastore.sh
```

### Complete Reset

```bash
docker compose down
./init-metastore.sh
```

## Database Setup (PostgreSQL vs Derby)

### PostgreSQL (Recommended)

- **Persistent data** across container restarts
- **Multi-user access** via pgAdmin
- **Better performance** for production workloads
- **Full SQL features** and compatibility

### Derby (Avoid)

- **Embedded database** with limitations
- **Single-user access** only
- **Lost data** when containers restart
- **Performance issues** with larger datasets

### Signs You're Using Derby (Bad)

- Metastore logs show `jdbc:derby:;databaseName=metastore_db`
- No tables visible in pgAdmin at <http://localhost:5050>
- Poor query performance
- Connection errors with multiple users

### Signs You're Using PostgreSQL (Good)

- Metastore logs show `jdbc:postgresql://postgres:5432/metastore_db`
- 83 metastore tables visible in pgAdmin
- Good performance
- Multiple concurrent connections work

## Port Mappings

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Trino | 8081 | <http://localhost:8081> | SQL query engine |
| MinIO Console | 9001 | <http://localhost:9001> | Object storage admin |
| Jupyter Lab | 8888 | <http://localhost:8888> | Notebook environment |
| pgAdmin | 5050 | <http://localhost:5050> | Database admin |
| PostgreSQL | 5432 | localhost:5432 | Database server |
| Spark UI | 8082 | <http://localhost:8082> | Spark application UI |

## Service Dependencies

```text
PostgreSQL (must start first)
    ↓
Metastore (depends on PostgreSQL)
    ↓
Trino, Spark (depend on Metastore)
    ↓
MinIO (S3-compatible storage)
```

## Configuration Files

- **`compose.yml`** - Docker services definition
- **`metastore-site.xml`** - Hive Metastore configuration (PostgreSQL settings)
- **`postgresql.jar`** - PostgreSQL JDBC driver
- **`../catalog/trino/iceberg.properties`** - Trino catalog configuration

## Troubleshooting

### Container Issues

```bash
# Check service status
docker compose ps

# Check logs
docker compose logs <service-name>

# Restart specific service
docker compose restart <service-name>
```

### Database Issues

```bash
# Check database setup
./check-database.sh

# Fix PostgreSQL setup
./init-metastore.sh

# Manual PostgreSQL connection test
docker compose exec postgres psql -U hive -d metastore_db -c "SELECT COUNT(*) FROM pg_tables;"
```

### Reset everything

```bash
docker compose down -v
docker system prune -f
./init-metastore.sh
```

## Environment Variables

The following environment variables are set in `compose.yml`:

### PostgreSQL

- `POSTGRES_DB=metastore_db`
- `POSTGRES_USER=hive`  
- `POSTGRES_PASSWORD=password`

### Metastore

- `SKIP_SCHEMA_INIT=true` (we handle schema manually)
- Database connection details

### MinIO

- `MINIO_ROOT_USER=admin`
- `MINIO_ROOT_PASSWORD=password`

### Trino & Spark

- AWS/S3 configuration for MinIO integration
