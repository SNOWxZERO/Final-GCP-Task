terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  prefix                   = var.prefix
  region                   = var.region
  management_subnet_cidr   = var.management_subnet_cidr
  restricted_subnet_cidr   = var.restricted_subnet_cidr
  gke_pods_cidr            = var.gke_pods_cidr
  gke_services_cidr        = var.gke_services_cidr
}

# GKE Module
module "gke" {
  source = "./modules/gke"
  
  prefix                   = var.prefix
  project_id               = var.project_id
  region                   = var.region
  vpc_name                 = module.networking.vpc_name
  restricted_subnet_name   = module.networking.restricted_subnet_name
  management_subnet_cidr   = var.management_subnet_cidr
  gke_master_cidr          = var.gke_master_cidr
  machine_type             = var.gke_machine_type
  node_count               = var.gke_node_count
  use_preemptible_nodes    = var.use_preemptible_nodes
  node_disk_size_gb        = var.gke_node_disk_size_gb
}

# Compute Module (Management VM)
module "compute" {
  source = "./modules/compute"
  
  prefix                   = var.prefix
  project_id               = var.project_id
  zone                     = var.zone
  vpc_name                 = module.networking.vpc_name
  management_subnet_name   = module.networking.management_subnet_name
  machine_type             = var.vm_machine_type
  # Because of the dependency on the GKE cluster in the deployment script
  depends_on                = [module.gke]
}

# Artifact Registry Module
module "artifact_registry" {
  source = "./modules/artifact-registry"
  
  prefix = var.prefix
  region = var.region
}
