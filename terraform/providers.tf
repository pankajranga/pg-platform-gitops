terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Using local state for Day 1 to keep things simple and fast.
  # Optional stretch goal later in the week: migrate this to a GCS backend
  # once the bucket below exists (classic chicken-and-egg problem otherwise).
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
