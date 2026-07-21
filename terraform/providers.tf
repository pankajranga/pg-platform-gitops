terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "panka-tf-state-2026"
    prefix = "pg-platform"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}