variable "project_id" {
  description = "GCP Project ID"
  default     = "transjakarta-pipeline"
}

variable "region" {
  description = "GCP Region"
  default     = "asia-southeast2"
}

variable "bucket_name" {
  description = "GCS Bucket Name"
  default     = "transjakarta-raw-data"
}

variable "bq_dataset" {
  description = "BigQuery Dataset Name"
  default     = "transjakarta"
}