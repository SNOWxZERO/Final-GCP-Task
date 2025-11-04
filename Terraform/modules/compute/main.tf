# Service Account for VM
resource "google_service_account" "vm_sa" {
  account_id   = "${var.prefix}-vm-sa"
  display_name = "Management VM Service Account"
}

# IAM roles for VM Service Account
resource "google_project_iam_member" "vm_sa_roles" {
  for_each = toset([
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Private VM Instance in Management Subnet
resource "google_compute_instance" "private_vm" {
  name         = "${var.prefix}-management-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.management_subnet_name
    # No external IP - private VM
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("${path.module}/StartupScript.sh")

  tags = ["private-vm"]
}

# Deploy application after VM is ready
resource "null_resource" "deploy_app" {
  depends_on = [google_compute_instance.private_vm]

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Waiting for VM to be fully ready..."
      sleep 60
      
      echo "Copying deploy script to VM..."
      gcloud compute scp ${path.module}/deploy.sh ${google_compute_instance.private_vm.name}:/tmp/deploy.sh \
        --zone=${var.zone} \
        --tunnel-through-iap \
        --project=${var.project_id} \
        --quiet \
        --strict-host-key-checking=no
      
      echo "Running deployment script..."
      gcloud compute ssh ${google_compute_instance.private_vm.name} \
        --zone=${var.zone} \
        --tunnel-through-iap \
        --project=${var.project_id} \
        --quiet \
        --strict-host-key-checking=no \
        --command="chmod +x /tmp/deploy.sh && /tmp/deploy.sh"
    EOT
    interpreter = ["bash", "-c"]
  }

  triggers = {
    vm_id        = google_compute_instance.private_vm.id
    deploy_script = filemd5("${path.module}/deploy.sh")
  }
}
