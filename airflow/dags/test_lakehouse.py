from datetime import datetime, timedelta

import boto3

import trino
from airflow import DAG
from airflow.operators.python import PythonOperator


def test_minio():
    s3 = boto3.client(
        "s3",
        endpoint_url="http://minio:9000",
        aws_access_key_id="admin",
        aws_secret_access_key="password",
        region_name="us-east-1",
    )
    buckets = s3.list_buckets()
    print(f"Available buckets: {[bucket['Name'] for bucket in buckets['Buckets']]}")
    # List objects in warehouse/football/base/matches
    response = s3.list_objects_v2(Bucket="warehouse", Prefix="football/base/matches/")
    print(f"Objects in matches: {[obj['Key'] for obj in response.get('Contents', [])]}")


def test_trino():
    conn = trino.dbapi.connect(
        host="trino",
        port=8080,
        user="airflow",
    )
    cur = conn.cursor()
    cur.execute("SELECT * FROM football.base._probe")
    result = cur.fetchall()
    print(f"Trino _probe result: {result}")
    cur.execute("SELECT match_id, home_team, away_team FROM football.base.matches")
    matches = cur.fetchall()
    print(f"Trino matches result: {matches}")
    print(f"Matches count: {len(matches)}")
    for i, match in enumerate(matches):
        print(f"Match {i}: {match}")


default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    "test_lakehouse",
    default_args=default_args,
    description="Test connectivity to lakehouse with MinIO and Trino",
    schedule=None,
    start_date=datetime(2025, 8, 1),
    catchup=False,
) as dag:
    minio_task = PythonOperator(
        task_id="test_minio",
        python_callable=test_minio,
    )
    trino_task = PythonOperator(
        task_id="test_trino",
        python_callable=test_trino,
    )
    minio_task >> trino_task
