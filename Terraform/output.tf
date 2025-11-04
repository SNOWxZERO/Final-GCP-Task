output "vpc_name" {
  description = "VPC network name"
  value       = module.networking.vpc_name
}

output "management_subnet_name" {
  description = "Management subnet name"
  value       = module.networking.management_subnet_name
}

output "restricted_subnet_name" {
  description = "Restricted subnet name"
  value       = module.networking.restricted_subnet_name
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository ID"
  value       = module.artifact_registry.repository_id
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.artifact_registry.repository_url
}

output "management_vm_name" {
  description = "Management VM instance name"
  value       = module.compute.vm_name
}

output "management_vm_internal_ip" {
  description = "Management VM internal IP"
  value       = module.compute.vm_internal_ip
}

output "gke_service_account_email" {
  description = "GKE node service account email"
  value       = module.gke.service_account_email
}

output "vm_service_account_email" {
  description = "VM service account email"
  value       = module.compute.service_account_email
}

output "connect_to_vm_command" {
  description = "Command to connect to the management VM via IAP"
  value       = "gcloud compute ssh ${module.compute.vm_name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
}

output "get_gke_credentials_command" {
  description = "Command to get GKE credentials (run from management VM)"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region=${var.region} --project=${var.project_id} --internal-ip"
}

output "copy_deploy_script_command" {
  description = "Command to copy deploy.sh script to management VM"
  value       = "gcloud compute scp deploy.sh ${module.compute.vm_name}:~/home/USERNAME --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
}

output "get_loadbalancer_ip_command" {
  description = "Command to get the Load Balancer IP (run from management VM after deployment)"
  value       = "gcloud compute ssh ${module.compute.vm_name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id} --command='kubectl get service demo-app-service -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\"'"
}