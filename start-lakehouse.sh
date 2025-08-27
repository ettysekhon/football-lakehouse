#!/usr/bin/env bash
set -euo pipefail

WITHOUT_THRIFT=false
if [[ "${1:-}" == "WITHOUT_THRIFT" ]]; then
  WITHOUT_THRIFT=true
fi

echo "Starting Football Lakehouse..."
echo

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker first."
  exit 1
fi

docker compose up -d

echo "Waiting for core services to be healthy..."
until curl -fsS http://localhost:8181/v1/config >/dev/null 2>&1; do sleep 1; done
until curl -fsS http://localhost:8080/v1/info   >/dev/null 2>&1; do sleep 1; done

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
echo "Trino Web UI:      http://localhost:8080/ui/"
echo "MinIO Console:     http://localhost:9001"
echo "Iceberg REST info: http://localhost:8181/v1/config"
if [[ -n "$JUPYTER_TOKEN" ]]; then
  echo "Jupyter Lab:       http://localhost:8888/?token=${JUPYTER_TOKEN}"
else
  echo "Jupyter Lab:       http://localhost:8888/"
fi
if ! $WITHOUT_THRIFT; then
  echo "Spark UI:          http://localhost:8081/ (kept alive by ThriftServer)"
else
  echo "Spark UI:          http://localhost:8081/ (only while a Spark job runs)"
fi
echo
echo "To inspect logs:"
echo "  docker compose exec spark bash -lc 'tail -n 50 /tmp/jupyter.log'"
if ! $WITHOUT_THRIFT; then
  echo "  docker compose exec spark bash -lc 'tail -n 50 /tmp/thriftserver.log'"
fi
echo
echo "To stop everything: ./stop-lakehouse.sh"
