#!/usr/bin/env bash
set -euo pipefail

echo "Stopping Football Lakehouse..."
docker compose down
echo "All services stopped."