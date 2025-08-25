#!/bin/bash

set -e

echo "Football Lakehouse - Metastore Initialisation"
echo "================================================="
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED} Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${BLUE} Initialising PostgreSQL-based Hive Metastore...${NC}"
echo ""

# Step 1: Stop any existing services
echo -e "${YELLOW} Stopping existing services...${NC}"
docker compose down 2>/dev/null || true

# Step 2: Start PostgreSQL first
echo -e "${BLUE}  Starting PostgreSQL database...${NC}"
docker compose up -d postgres

# Wait for PostgreSQL to be ready
echo -e "${YELLOW} Waiting for PostgreSQL to be ready...${NC}"
sleep 8

# Check if PostgreSQL is ready
for i in {1..30}; do
    if docker compose exec postgres pg_isready -U hive -d metastore_db > /dev/null 2>&1; then
        echo -e "${GREEN} PostgreSQL is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED} PostgreSQL failed to start. Check logs: docker compose logs postgres${NC}"
        exit 1
    fi
    sleep 2
done

# Step 3: Start metastore service
echo -e "${BLUE} Starting Hive Metastore service...${NC}"
docker compose up -d metastore

# Wait for metastore to be ready
echo -e "${YELLOW} Waiting for metastore service to start...${NC}"
sleep 5

# Step 4: Check if schema already exists
echo -e "${BLUE} Checking if metastore schema exists...${NC}"
TABLE_COUNT=$(docker compose exec postgres psql -U hive -d metastore_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN} Metastore schema already exists ($TABLE_COUNT tables found).${NC}"
else
    echo -e "${YELLOW} Initialising metastore schema in PostgreSQL...${NC}"
    
    # Initialise the PostgreSQL schema using the official Hive script
    if docker compose exec metastore cat /opt/hive/scripts/metastore/upgrade/postgres/hive-schema-4.1.0.postgres.sql | docker compose exec -T postgres psql -U hive -d metastore_db > /dev/null 2>&1; then
        echo -e "${GREEN} Metastore schema initialised successfully!${NC}"
    else
        echo -e "${RED} Failed to initialise metastore schema. Check logs: docker compose logs metastore${NC}"
        exit 1
    fi
fi

# Step 5: Verify schema
echo -e "${BLUE}🔍 Verifying metastore schema...${NC}"
FINAL_TABLE_COUNT=$(docker compose exec postgres psql -U hive -d metastore_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

if [ "$FINAL_TABLE_COUNT" -ge 80 ]; then
    echo -e "${GREEN} Schema verification successful! Found $FINAL_TABLE_COUNT tables.${NC}"
else
    echo -e "${RED} Schema verification failed. Expected ~83 tables, found $FINAL_TABLE_COUNT${NC}"
    exit 1
fi

# Step 6: Start remaining services
echo -e "${BLUE} Starting remaining services...${NC}"
docker compose up -d

# Wait for all services
echo -e "${YELLOW} Waiting for all services to start...${NC}"
sleep 10

# Check service status
echo -e "${BLUE} Service Status:${NC}"
docker compose ps

echo ""
echo -e "${GREEN} SUCCESS: PostgreSQL-based Hive Metastore initialised!${NC}"
echo ""
echo -e "${BLUE} Access your services:${NC}"
echo "   • Trino Web UI:   http://localhost:8081"
echo "   • MinIO Console:  http://localhost:9001 (admin/password)"  
echo "   • PgAdmin:        http://localhost:5050 (admin@example.com/admin)"
echo ""
echo -e "${YELLOW} Next steps:${NC}"
echo "   1. Start Jupyter Lab: docker compose exec -d spark jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/home/iceberg/notebooks"
echo "   2. Get Jupyter token: docker compose exec spark jupyter lab list"
echo "   3. Verify metastore in pgAdmin:"
echo "      - Connect to PostgreSQL server: postgres:5432"
echo "      - Database: metastore_db, User: hive, Password: password"
echo "      - Check tables like 'DBS', 'TBLS', 'COLUMNS_V2'"
echo ""
echo -e "${GREEN} Ready for football analytics!${NC}"
