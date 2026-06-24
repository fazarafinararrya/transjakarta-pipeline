output "bucket_name" {
  description = "GCS Bucket Name"
  value       = google_storage_bucket.raw_data.name
}

output "bigquery_dataset" {
  description = "BigQuery Dataset ID"
  value       = google_bigquery_dataset.transjakarta.dataset_id
}