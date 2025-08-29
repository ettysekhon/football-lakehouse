# execute through the trino container (catalog = "football" from football.properties)
docker compose exec -T trino trino < sql/recreate_football_schema.sql

# quick checks
docker compose exec trino trino --execute "SHOW SCHEMAS FROM football"
docker compose exec trino trino --execute "SHOW TABLES FROM football.base"
docker compose exec trino trino --execute "SELECT * FROM football.base._probe"