### --- Networking ---

resource "google_compute_network" "vpc" {
  name                    = "pg-platform-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "pg-platform-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  # Secondary ranges are required for a VPC-native (alias IP) GKE cluster
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

### --- GKE cluster (zonal, to waive the mgmt fee) ---

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # Create the cluster with no default node pool; we manage nodes explicitly below.
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  deletion_protection = false # so `terraform destroy` works cleanly during the sprint
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    spot         = false # ~60-90% cheaper than on-demand; fine for a learning project, not for prod

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = "pg-platform-sprint"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }
}

### --- GCS bucket for Postgres backups ---

resource "google_storage_bucket" "backups" {
  name     = var.backup_bucket_name
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy                = true # allows `terraform destroy` even if backups exist inside

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 14
    }
    action {
      type = "Delete"
    }
  }
}
