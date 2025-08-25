#!/bin/bash

echo "🔍 Football Lakehouse - Database Status Check"
echo "============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if services are running
echo -e "${BLUE} Service Status:${NC}"
docker compose ps

echo ""
echo -e "${BLUE}  Database Information:${NC}"

# Check PostgreSQL connection
if docker compose exec postgres pg_isready -U hive -d metastore_db > /dev/null 2>&1; then
    echo -e "${GREEN} PostgreSQL: Connected${NC}"
    
    # Count tables
    TABLE_COUNT=$(docker compose exec postgres psql -U hive -d metastore_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)
    echo -e "${GREEN} Metastore tables: $TABLE_COUNT${NC}"
    
    if [ "$TABLE_COUNT" -ge 80 ]; then
        echo -e "${GREEN} Metastore: Properly initialised (PostgreSQL)${NC}"
        
        # Show key tables
        echo ""
        echo -e "${BLUE} Key Metastore Tables:${NC}"
        docker compose exec postgres psql -U hive -d metastore_db -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('DBS', 'TBLS', 'COLUMNS_V2', 'PARTITIONS', 'SERDES') ORDER BY tablename;" 2>/dev/null
        
        # Show database count
        echo ""
        echo -e "${BLUE} Databases in metastore:${NC}"
        DB_COUNT=$(docker compose exec postgres psql -U hive -d metastore_db -t -c "SELECT COUNT(*) FROM \"DBS\";" 2>/dev/null | xargs)
        echo "   Total databases: $DB_COUNT"
        
    elif [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}  Metastore: Partially initialised ($TABLE_COUNT tables)${NC}"
        echo -e "${YELLOW} Run './init-metastore.sh' to fix${NC}"
    else
        echo -e "${RED} Metastore: No tables found${NC}"
        echo -e "${YELLOW} Run './init-metastore.sh' to initialise${NC}"
    fi
    
else
    echo -e "${RED} PostgreSQL: Not accessible${NC}"
    echo -e "${YELLOW} Check if services are running: docker compose up -d postgres${NC}"
fi

# Check for Derby (warning)
echo ""
echo -e "${BLUE} Checking for Derby usage (should not be present):${NC}"
if docker compose logs metastore 2>/dev/null | grep -q "jdbc:derby"; then
    echo -e "${RED}  WARNING: Derby detected in metastore logs!${NC}"
    echo -e "${RED}   This means PostgreSQL initialisation may have failed.${NC}"
    echo -e "${YELLOW} Run './init-metastore.sh' to fix PostgreSQL setup${NC}"
else
    echo -e "${GREEN} No Derby usage detected${NC}"
fi

echo ""
echo -e "${BLUE} Access URLs:${NC}"
echo "   • PgAdmin (database admin): http://localhost:5050"
echo "     - Server: postgres, Port: 5432"
echo "     - Database: metastore_db, User: hive, Password: password"
echo "   • Trino (query engine):     http://localhost:8081"
echo ""
echo -e "${YELLOW} Troubleshooting:${NC}"
echo "   • Initialise PostgreSQL:    ./init-metastore.sh"
echo "   • Reset everything:         docker compose down && ./init-metastore.sh"
echo "   • Check metastore logs:     docker compose logs metastore"
