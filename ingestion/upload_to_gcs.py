from google.cloud import storage
import os

# Konfigurasi
BUCKET_NAME = "transjakarta-raw-data"
LOCAL_DIR = "data/daily"
GCS_PREFIX = "raw/transjakarta"

# Inisialisasi client GCS
client = storage.Client()
bucket = client.bucket(BUCKET_NAME)

print(f"Mulai upload ke bucket: {BUCKET_NAME}\n")

# Loop semua file di folder daily
files = sorted(os.listdir(LOCAL_DIR))
for filename in files:
    if filename.endswith(".csv"):
        local_path = os.path.join(LOCAL_DIR, filename)
        
        # Ambil tanggal dari nama file: transjakarta_2023-04-01.csv
        date_part = filename.replace("transjakarta_", "").replace(".csv", "")
        year, month, day = date_part.split("-")
        
        # Struktur folder di GCS: raw/transjakarta/2023/04/01/data.csv
        gcs_path = f"{GCS_PREFIX}/{year}/{month}/{day}/data.csv"
        
        # Upload
        blob = bucket.blob(gcs_path)
        blob.upload_from_filename(local_path)
        print(f"  {filename} -> gs://{BUCKET_NAME}/{gcs_path}")

print(f"\nSelesai! {len(files)} file ter-upload ke GCS.")