output "vm_name" {
  description = "Management VM name"
  value       = google_compute_instance.private_vm.name
}

output "vm_internal_ip" {
  description = "Management VM internal IP"
  value       = google_compute_instance.private_vm.network_interface[0].network_ip
}

output "service_account_email" {
  description = "VM service account email"
  value       = google_service_account.vm_sa.email
}

output "deployment_trigger" {
  description = "Deployment trigger status"
  value       = null_resource.deploy_app.id
}
