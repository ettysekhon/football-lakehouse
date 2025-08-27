#!/usr/bin/env bash
set -euo pipefail

SPARK_BIN=/opt/spark/bin/spark-sql
MC_BIN=/usr/bin/mc
TRINO_BIN=trino

CATALOG=football
SCHEMA=football_ref
TABLE=players
NS_PATH="${SCHEMA}"
S3_PREFIX="minio/warehouse/${SCHEMA}/${TABLE}"

echo "Checking core services..."
until curl -fsS http://localhost:8181/v1/config >/dev/null 2>&1; do sleep 1; done
until curl -fsS http://localhost:8080/v1/info   >/dev/null 2>&1; do sleep 1; done

docker compose exec -T spark bash -lc "test -x ${SPARK_BIN} || { echo 'spark-sql not found at ${SPARK_BIN}'; exit 1; }" >/dev/null
docker compose exec -T mc    bash -lc "test -x ${MC_BIN}    || { echo 'mc not found at ${MC_BIN}'; exit 1; }" >/dev/null

# Show mc aliases for visibility
docker compose exec -T mc ${MC_BIN} alias list

run_sql() {
  local sql="$1"
  docker compose exec -T spark bash -lc "
    ${SPARK_BIN} \
      --conf spark.sql.catalogImplementation=in-memory \
      --conf spark.sql.defaultCatalog=${CATALOG} \
      --conf spark.sql.catalog.${CATALOG}.s3.endpoint=http://minio:9000 \
      --conf spark.sql.catalog.${CATALOG}.s3.path-style-access=true \
      --conf spark.sql.catalog.${CATALOG}.s3.region=us-east-1 \
      -e \"${sql}\"
  "
}

echo "Creating schema ${CATALOG}.${SCHEMA}..."
run_sql "CREATE SCHEMA IF NOT EXISTS ${CATALOG}.${SCHEMA};"

echo "Creating table ${CATALOG}.${SCHEMA}.${TABLE}..."
run_sql "CREATE OR REPLACE TABLE ${CATALOG}.${SCHEMA}.${TABLE} (
  player_id INT,
  name STRING,
  position STRING,
  nationality STRING,
  club STRING,
  height_cm INT,
  weight_kg INT
);"

# Show current objects (useful across repeated runs)
docker compose exec -T mc ${MC_BIN} ls -r "${S3_PREFIX}/" || true

echo "Inserting one test row..."
run_sql "INSERT OVERWRITE TABLE ${CATALOG}.${SCHEMA}.${TABLE} VALUES
  (10, 'Ada Lovelace', 'MF', 'GBR', 'Analytical FC', 168, 60);"

echo "Querying via Spark..."
run_sql "SELECT * FROM ${CATALOG}.${SCHEMA}.${TABLE};"

echo "Checking Iceberg REST lists the namespace and table..."
curl -fsS http://localhost:8181/v1/config >/dev/null
NS_LIST="$(curl -fsS http://localhost:8181/v1/namespaces || true)"
echo "$NS_LIST" | grep -q "\"${SCHEMA}\"" || { echo "Namespace ${SCHEMA} not in REST list"; exit 1; }
TBL_LIST="$(curl -fsS "http://localhost:8181/v1/namespaces/${NS_PATH}/tables" || true)"
echo "$TBL_LIST" | grep -q "\"${TABLE}\"" || { echo "Table ${TABLE} not in REST list"; exit 1; }
echo "REST catalog lists ${SCHEMA}.${TABLE}."

echo "Querying via Trino..."
docker compose exec -T trino ${TRINO_BIN} --server http://localhost:8080 --execute \
  "SELECT * FROM ${CATALOG}.${SCHEMA}.${TABLE};"

echo "Checking MinIO objects under s3://warehouse/${SCHEMA}/${TABLE}/ ..."
MC_LIST=$(docker compose exec -T mc ${MC_BIN} ls -r "${S3_PREFIX}/" 2>/dev/null || true)
if [[ -n "${MC_LIST}" ]]; then
  echo "Objects present in MinIO:"
  echo "${MC_LIST}"
else
  echo "No objects listed (unexpected if insert succeeded)"
fi

echo "Running Iceberg GC (expire snapshots only)..."
# This keeps the latest snapshot and expires older ones; safe for tests
run_sql "CALL ${CATALOG}.system.expire_snapshots('${SCHEMA}.${TABLE}');"

echo "Cleaning up (drop table and schema)..."
run_sql "DROP TABLE IF EXISTS ${CATALOG}.${SCHEMA}.${TABLE};"
run_sql "DROP SCHEMA IF EXISTS ${CATALOG}.${SCHEMA} CASCADE;"

echo "Explicitly cleaning MinIO prefix (test-only cleanup)..."
# Remove any leftover files for a fully clean slate next run
docker compose exec -T mc ${MC_BIN} rm -r --force "${S3_PREFIX}/" || true

echo "Verifying cleanup in REST..."
POST_TBL_LIST="$(curl -fsS -o- -w '%{http_code}' "http://localhost:8181/v1/namespaces/${NS_PATH}/tables" || true)"
if [[ "$POST_TBL_LIST" == *"404" ]]; then
  echo "Namespace ${SCHEMA} no longer exists in REST (expected after drop)."
else
  echo "$POST_TBL_LIST" | grep -q "\"${TABLE}\"" \
    && { echo "Table still listed in REST after drop"; exit 1; } \
    || echo "Table no longer listed in REST."
fi

echo "Verifying MinIO prefix post-drop..."
MC_POST=$(docker compose exec -T mc ${MC_BIN} ls -r "${S3_PREFIX}/" 2>/dev/null || true)
if [[ -n "${MC_POST}" ]]; then
  echo "Warning: objects still present under s3://warehouse/${SCHEMA}/${TABLE}/"
  echo "${MC_POST}" | head -50
else
  echo "No remaining objects listed under s3://warehouse/${SCHEMA}/${TABLE}/."
fi

echo "E2E test completed successfully."
