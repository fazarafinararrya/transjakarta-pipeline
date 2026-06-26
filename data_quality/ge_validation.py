import great_expectations as gx
from google.cloud import bigquery
import pandas as pd

PROJECT_ID = "transjakarta-pipeline"
DATASET = "transjakarta"
TABLE = "fact_transactions"

# 1. Ambil data dari BigQuery ke pandas
print("Mengambil data dari BigQuery...")
client = bigquery.Client(project=PROJECT_ID)
query = f"SELECT * FROM `{PROJECT_ID}.{DATASET}.{TABLE}`"
df = client.query(query).to_dataframe()
print(f"Data diambil: {len(df)} baris\n")

# 2. Buat konteks GE & masukkan data
context = gx.get_context()
data_source = context.data_sources.add_pandas("transjakarta_source")
data_asset = data_source.add_dataframe_asset(name="fact_transactions")
batch_definition = data_asset.add_batch_definition_whole_dataframe("batch")
batch = batch_definition.get_batch(batch_parameters={"dataframe": df})

# 3. Definisikan expectations (aturan kualitas data)
suite = gx.ExpectationSuite(name="transjakarta_quality")
suite = context.suites.add(suite)

# transID harus unik & tidak null
suite.add_expectation(gx.expectations.ExpectColumnValuesToBeUnique(column="transID"))
suite.add_expectation(gx.expectations.ExpectColumnValuesToNotBeNull(column="transID"))

# payAmount harus di rentang masuk akal (0 - 50000)
suite.add_expectation(gx.expectations.ExpectColumnValuesToBeBetween(
    column="payAmount", min_value=0, max_value=50000))

# corridorID tidak boleh null
suite.add_expectation(gx.expectations.ExpectColumnValuesToNotBeNull(column="corridorID"))

# gender cuma boleh M atau F
suite.add_expectation(gx.expectations.ExpectColumnValuesToBeInSet(
    column="payCardSex", value_set=["M", "F"]))

# is_complete_trip tidak null
suite.add_expectation(gx.expectations.ExpectColumnValuesToNotBeNull(column="is_complete_trip"))

# 4. Jalankan validasi
print("Menjalankan validasi...")
validation_definition = gx.ValidationDefinition(
    data=batch_definition, suite=suite, name="validasi_transjakarta")
validation_definition = context.validation_definitions.add(validation_definition)
results = validation_definition.run(batch_parameters={"dataframe": df})

# 5. Tampilkan hasil ringkas
print(f"\nHasil validasi: {'LULUS SEMUA' if results.success else 'ADA YANG GAGAL'}")
for r in results.results:
    status = "PASS" if r.success else "FAIL"
    exp_type = r.expectation_config.type
    col = r.expectation_config.kwargs.get("column", "")
    print(f"  [{status}] {exp_type} - {col}")

# 6. Generate laporan HTML
context.build_data_docs()
print("\nLaporan HTML dibuat & dibuka di browser!")
context.open_data_docs()