output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "management_subnet_name" {
  description = "Management subnet name"
  value       = google_compute_subnetwork.management.name
}

output "restricted_subnet_name" {
  description = "Restricted subnet name"
  value       = google_compute_subnetwork.restricted.name
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository name"
  value       = google_artifact_registry_repository.repo.name
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "management_vm_name" {
  description = "Management VM instance name"
  value       = google_compute_instance.private_vm.name
}

output "management_vm_internal_ip" {
  description = "Management VM internal IP"
  value       = google_compute_instance.private_vm.network_interface[0].network_ip
}

output "gke_service_account_email" {
  description = "GKE node service account email"
  value       = google_service_account.gke_sa.email
}

output "vm_service_account_email" {
  description = "VM service account email"
  value       = google_service_account.vm_sa.email
}

output "connect_to_vm_command" {
  description = "Command to connect to the management VM via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.private_vm.name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
}

output "get_gke_credentials_command" {
  description = "Command to get GKE credentials (run from management VM)"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region=${var.region} --project=${var.project_id} --internal-ip"
}

output "copy_deploy_script_command" {
  description = "Command to copy deploy.sh script to management VM"
  value       = "gcloud compute scp deploy.sh ${google_compute_instance.private_vm.name}:~/home/USERNAME --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
}