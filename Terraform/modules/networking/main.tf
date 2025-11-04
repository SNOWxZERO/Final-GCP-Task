# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Management Subnet (for private VM with internet access via NAT)
resource "google_compute_subnetwork" "management" {
  name          = "${var.prefix}-management-subnet"
  ip_cidr_range = var.management_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
}

# Restricted Subnet (No internet access)
resource "google_compute_subnetwork" "restricted" {
  name          = "${var.prefix}-restricted-subnet"
  ip_cidr_range = var.restricted_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
  
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.gke_pods_cidr
  }
  
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.gke_services_cidr
  }
}

# Cloud Router for NAT (Management subnet only)
resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# NAT Gateway for Management Subnet
resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = google_compute_subnetwork.management.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Firewall rule: Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.prefix}-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP IP range
  target_tags   = ["private-vm"]
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.management_subnet_cidr,
    var.restricted_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr
  ]
}

# Firewall rule: Allow health checks for load balancer
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.prefix}-allow-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"] # GCP health check ranges
  target_tags   = ["gke-node"]
}
