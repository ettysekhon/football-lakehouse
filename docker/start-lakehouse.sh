#!/bin/bash

set -e

echo "Starting Football Lakehouse..."
echo ""

if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if metastore is already initialised
echo "🔍 Checking metastore initialisation..."
if docker compose ps postgres 2>/dev/null | grep -q "Up" && docker compose exec postgres psql -U hive -d metastore_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | grep -q "[8-9][0-9]\|[1-9][0-9][0-9]"; then
    echo "Metastore already initialised, starting services..."
    docker compose up -d
else
    echo "Metastore not initialised. Running PostgreSQL setup..."
    ./init-metastore.sh
    # Services are already started by init-metastore.sh
fi

echo "Waiting for services to start..."
sleep 5

echo ""
echo "Service Status:"
docker compose ps

# Start Jupyter Lab
echo ""
echo "Starting Jupyter Lab..."
docker compose exec -d spark jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/home/iceberg/notebooks

# Wait a moment for Jupyter to start
sleep 5

# Get Jupyter token
echo "Getting Jupyter access token..."
JUPYTER_TOKEN=$(docker compose exec spark jupyter lab list 2>/dev/null | grep -o 'token=[^[:space:]]*' | head -1 | cut -d= -f2)

echo ""
echo "Football Lakehouse is ready!"
echo ""
echo "Access your services at:"
echo "   • Trino Web UI:   http://localhost:8081"
echo "   • MinIO Console:  http://localhost:9001 (admin/password)"
echo "   • Jupyter Lab:    http://localhost:8888/?token=$JUPYTER_TOKEN"
echo "   • PgAdmin:        http://localhost:5050 (admin@example.com/admin)"
echo ""
echo "To start Spark UI (optional):"
echo "   docker compose exec spark pyspark --conf spark.ui.enabled=true --conf spark.ui.port=8080 --conf spark.ui.host=0.0.0.0 --conf spark.driver.host=0.0.0.0"
echo "   Then access: http://localhost:8082"
echo ""
echo "To stop everything:"
echo "   docker compose down"
echo ""
echo "Ready for football analytics"
