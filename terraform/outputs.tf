output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_zone" {
  value = google_container_cluster.primary.location
}

output "backup_bucket" {
  value = google_storage_bucket.backups.name
}

output "get_credentials_command" {
  description = "Run this to configure kubectl against the new cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
}
