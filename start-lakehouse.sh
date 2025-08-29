#!/usr/bin/env bash
set -euo pipefail

WITHOUT_THRIFT=false
if [[ "${1:-}" == "WITHOUT_THRIFT" ]]; then
  WITHOUT_THRIFT=true
fi

TRINO_UI_URL="http://localhost:8080/ui/"
MINIO_CONSOLE_URL="http://localhost:9001"
ICEBERG_REST_URL="http://localhost:8181/v1/config"
JUPYTER_URL_BASE="http://localhost:8888"
SPARK_UI_URL="http://localhost:8081"
SUPERSET_URL="http://localhost:8089"
SUPERSET_HEALTH="${SUPERSET_URL}/health"

echo "Starting Football Lakehouse..."
echo

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker first."
  exit 1
fi

docker compose up -d --pull=always

echo "Waiting for core services to be healthy..."
until curl -fsS "${ICEBERG_REST_URL}" >/dev/null 2>&1; do sleep 1; done
until curl -fsS http://localhost:8080/v1/info >/dev/null 2>&1; do sleep 1; done

if docker compose ps superset >/dev/null 2>&1; then
  echo "Waiting for Superset..."
  until curl -fsS "${SUPERSET_HEALTH}" >/dev/null 2>&1; do sleep 2; done
fi

docker compose exec -T spark bash -lc 'mkdir -p /tmp/spark-events'

echo "Starting Jupyter Lab..."
docker compose exec -d spark jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --notebook-dir=/home/iceberg/notebooks

sleep 3

JUPYTER_TOKEN="$(docker compose exec spark jupyter lab list 2>/dev/null | awk -F'token=' '/token=/{print $2; exit}' || true)"

if ! $WITHOUT_THRIFT; then
  echo "Starting Spark ThriftServer..."
  docker compose exec -d spark bash -lc \
    "\${SPARK_HOME}/sbin/start-thriftserver.sh \
       --hiveconf hive.server2.thrift.port=10000 \
       --hiveconf hive.server2.thrift.http.port=10001 \
       --driver-java-options '-Dspark.ui.port=8080' \
       >/tmp/thriftserver.log 2>&1"
fi

docker compose ps
echo
echo "Football Lakehouse is ready!"
echo
echo "Trino Web UI:      ${TRINO_UI_URL}"
echo "MinIO Console:     ${MINIO_CONSOLE_URL}"
echo "Iceberg REST info: ${ICEBERG_REST_URL}"
if [[ -n "$JUPYTER_TOKEN" ]]; then
  echo "Jupyter Lab:       ${JUPYTER_URL_BASE}/?token=${JUPYTER_TOKEN}"
else
  echo "Jupyter Lab:       ${JUPYTER_URL_BASE}/"
fi
if docker compose ps superset >/dev/null 2>&1; then
  echo "Superset:          ${SUPERSET_URL}/ (login: admin / admin)"
fi
if ! $WITHOUT_THRIFT; then
  echo "Spark UI:          ${SPARK_UI_URL} (kept alive by ThriftServer)"
else
  echo "Spark UI:          ${SPARK_UI_URL} (only while a Spark job runs)"
fi
echo
echo "To inspect logs:"
echo "  docker compose logs -f trino"
echo "  docker compose logs -f iceberg-rest"
echo "  docker compose exec spark bash -lc 'tail -n 50 /tmp/jupyter.log' || true"
if ! $WITHOUT_THRIFT; then
  echo "  docker compose exec spark bash -lc 'tail -n 50 /tmp/thriftserver.log' || true"
fi
if docker compose ps superset >/dev/null 2>&1; then
  echo "  docker compose logs -f superset"
fi
echo
echo "To stop everything: ./stop-lakehouse.sh"
