from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    "owner": "faza",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="transjakarta_pipeline",
    default_args=default_args,
    description="Pipeline harian: upload -> load -> dbt transform -> dbt test",
    start_date=datetime(2023, 4, 1),
    end_date=datetime(2023, 4, 30),
    schedule_interval="@daily",
    catchup=False,
) as dag:

    upload_task = BashOperator(
        task_id="upload_to_gcs",
        bash_command="python /opt/airflow/ingestion/upload_to_gcs.py {{ ds }}",
    )

    load_task = BashOperator(
        task_id="load_to_bigquery",
        bash_command="python /opt/airflow/ingestion/load_to_bigquery.py {{ ds }}",
    )

    dbt_run_task = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/airflow/dbt/transjakarta_dbt && dbt run",
    )

    dbt_test_task = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/airflow/dbt/transjakarta_dbt && dbt test",
    )

    upload_task >> load_task >> dbt_run_task >> dbt_test_task