variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for VM"
  type        = string
  default     = "us-central1-a"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "devops-challenge"
}

variable "management_subnet_cidr" {
  description = "CIDR range for management subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "restricted_subnet_cidr" {
  description = "CIDR range for restricted subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "gke_node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_node_disk_size_gb" {
  description = "Boot disk size (GB) for GKE nodes"
  type        = number
  default     = 20
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = false
}

variable "vm_machine_type" {
  description = "Machine type for management VM"
  type        = string
  default     = "e2-medium"
}