# Airflow 3 Docker setup

## Getting started

Run the following commands

```bash
echo -e "AIRFLOW_UID=$(id -u)" > .env
docker compose build
# Initialise
docker compose up airflow-init
docker compose up -d
```

Once docker compose services are all running open [Airflow](http://localhost:9080/)
