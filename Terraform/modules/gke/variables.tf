variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "restricted_subnet_name" {
  description = "Restricted subnet name"
  type        = string
}

variable "management_subnet_cidr" {
  description = "Management subnet CIDR for master authorized networks"
  type        = string
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master"
  type        = string
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = false
}

variable "node_disk_size_gb" {
  description = "Boot disk size (GB) for GKE nodes"
  type        = number
  default     = 20
}
