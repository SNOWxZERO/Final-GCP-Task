# Service Account for GKE Nodes
resource "google_service_account" "gke_sa" {
  account_id   = "${var.prefix}-gke-sa"
  display_name = "GKE Node Service Account"
}

# IAM roles for GKE Service Account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Private GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.prefix}-gke-cluster"
  location = var.region
  deletion_protection = false
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.vpc_name
  subnetwork = var.restricted_subnet_name
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.gke_master_cidr
  }
  
  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  
  # Master authorized networks (Management subnet only)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.management_subnet_cidr
      display_name = "Management Subnet"
    }
  }
  
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# GKE Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.prefix}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  
  node_config {
    preemptible  = var.use_preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-standard"
    
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    tags = ["gke-node", "${var.prefix}-gke-node"]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
