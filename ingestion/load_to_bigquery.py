from google.cloud import bigquery
import sys

PROJECT_ID = "transjakarta-pipeline"
DATASET = "transjakarta"
TABLE = "staging_transjakarta_raw"
BUCKET_NAME = "transjakarta-raw-data"

# Terima tanggal dari argument
target_date = sys.argv[1] if len(sys.argv) > 1 else "2023-04-01"
year, month, day = target_date.split("-")

GCS_URI = f"gs://{BUCKET_NAME}/raw/transjakarta/{year}/{month}/{day}/data.csv"

client = bigquery.Client(project=PROJECT_ID)
table_id = f"{PROJECT_ID}.{DATASET}.{TABLE}"

schema = [
    bigquery.SchemaField("transID", "STRING"),
    bigquery.SchemaField("payCardID", "STRING"),
    bigquery.SchemaField("payCardBank", "STRING"),
    bigquery.SchemaField("payCardName", "STRING"),
    bigquery.SchemaField("payCardSex", "STRING"),
    bigquery.SchemaField("payCardBirthDate", "STRING"),
    bigquery.SchemaField("corridorID", "STRING"),
    bigquery.SchemaField("corridorName", "STRING"),
    bigquery.SchemaField("direction", "STRING"),
    bigquery.SchemaField("tapInStops", "STRING"),
    bigquery.SchemaField("tapInStopsName", "STRING"),
    bigquery.SchemaField("tapInStopsLat", "STRING"),
    bigquery.SchemaField("tapInStopsLon", "STRING"),
    bigquery.SchemaField("stopStartSeq", "STRING"),
    bigquery.SchemaField("tapInTime", "STRING"),
    bigquery.SchemaField("tapOutStops", "STRING"),
    bigquery.SchemaField("tapOutStopsName", "STRING"),
    bigquery.SchemaField("tapOutStopsLat", "STRING"),
    bigquery.SchemaField("tapOutStopsLon", "STRING"),
    bigquery.SchemaField("stopEndSeq", "STRING"),
    bigquery.SchemaField("tapOutTime", "STRING"),
    bigquery.SchemaField("payAmount", "STRING"),
]

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    schema=schema,
    write_disposition="WRITE_APPEND",
    allow_quoted_newlines=True,
)

print(f"Loading data tanggal {target_date} dari GCS ke BigQuery...")
load_job = client.load_table_from_uri(GCS_URI, table_id, job_config=job_config)
load_job.result()

table = client.get_table(table_id)
print(f"Selesai! Total {table.num_rows} rows di {table_id}")