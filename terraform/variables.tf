variable "project_id" {
  description = "Your GCP project ID (from the console, not the project name)"
  type        = string
}

variable "region" {
  description = "Region for the VPC/subnet"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone for the GKE zonal cluster (waives the $0.10/hr mgmt fee as your first zonal cluster)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "pg-platform-cluster"
}

variable "node_count" {
  description = "Number of nodes in the default pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "backup_bucket_name" {
  description = "Globally-unique GCS bucket name for Postgres backups"
  type        = string
}
