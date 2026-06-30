from google.cloud import storage
import os
import sys

# Konfigurasi
BUCKET_NAME = "transjakarta-raw-data"
LOCAL_DIR = "/opt/airflow/data/daily"
GCS_PREFIX = "raw/transjakarta"

# Terima tanggal dari argument (format: 2023-04-01)
# Kalau dijalankan manual tanpa argument, default ke tanggal 1 (buat testing)
target_date = sys.argv[1] if len(sys.argv) > 1 else "2023-04-01"

client = storage.Client()
bucket = client.bucket(BUCKET_NAME)

filename = f"transjakarta_{target_date}.csv"
local_path = os.path.join(LOCAL_DIR, filename)

if not os.path.exists(local_path):
    print(f"File tidak ditemukan: {local_path}")
    sys.exit(1)

year, month, day = target_date.split("-")
gcs_path = f"{GCS_PREFIX}/{year}/{month}/{day}/data.csv"

blob = bucket.blob(gcs_path)
blob.upload_from_filename(local_path)
print(f"Upload selesai: {filename} -> gs://{BUCKET_NAME}/{gcs_path}")