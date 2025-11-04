variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone for VM"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "management_subnet_name" {
  description = "Management subnet name"
  type        = string
}

variable "machine_type" {
  description = "Machine type for management VM"
  type        = string
  default     = "e2-medium"
}
