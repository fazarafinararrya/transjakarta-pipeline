import pandas as pd
import os

# Path file CSV asli
INPUT_FILE = "data/dfTransjakarta180kRows.csv"
OUTPUT_DIR = "data/daily"

# Buat folder output kalau belum ada
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("Membaca dataset...")
df = pd.read_csv(INPUT_FILE)
print(f"Total rows: {len(df)}")

# Convert tapInTime jadi datetime, lalu ambil tanggalnya
df['tapInTime'] = pd.to_datetime(df['tapInTime'], format='mixed')
df['date'] = df['tapInTime'].dt.date

# Split per tanggal
print("\nMemisahkan data per tanggal...")
for date, group in df.groupby('date'):
    group_to_save = group.drop(columns=['date'])
    filename = f"transjakarta_{date}.csv"
    filepath = os.path.join(OUTPUT_DIR, filename)
    group_to_save.to_csv(filepath, index=False)
    print(f"  {filename} -> {len(group)} rows")

print(f"\nSelesai! {df['date'].nunique()} file tersimpan di {OUTPUT_DIR}")