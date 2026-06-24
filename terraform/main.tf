terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GCS Bucket (Raw Data Layer)
resource "google_storage_bucket" "raw_data" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# BigQuery Dataset
resource "google_bigquery_dataset" "transjakarta" {
  dataset_id    = var.bq_dataset
  friendly_name = "Transjakarta Pipeline"
  description   = "Dataset for Transjakarta ELT Pipeline"
  location      = var.region
}