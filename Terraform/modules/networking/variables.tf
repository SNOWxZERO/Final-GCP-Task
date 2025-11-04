variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "management_subnet_cidr" {
  description = "CIDR range for management subnet"
  type        = string
}

variable "restricted_subnet_cidr" {
  description = "CIDR range for restricted subnet"
  type        = string
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
}
