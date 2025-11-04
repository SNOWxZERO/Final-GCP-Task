output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "management_subnet_name" {
  description = "Management subnet name"
  value       = google_compute_subnetwork.management.name
}

output "management_subnet_id" {
  description = "Management subnet ID"
  value       = google_compute_subnetwork.management.id
}

output "restricted_subnet_name" {
  description = "Restricted subnet name"
  value       = google_compute_subnetwork.restricted.name
}

output "restricted_subnet_id" {
  description = "Restricted subnet ID"
  value       = google_compute_subnetwork.restricted.id
}

output "management_subnet_cidr" {
  description = "Management subnet CIDR"
  value       = var.management_subnet_cidr
}
