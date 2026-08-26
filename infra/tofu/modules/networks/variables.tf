variable "project_id" {
  description = "project ID of the account"
  type        = string
}

variable "region" {
  description = "GKE region"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "GKE network name"
  type        = string
}

variable "subnet_name" {
  description = "GKE subnet name"
  type        = string
}

variable "node_cidr" {
  description = "GKE nodes CIDR range"
  type        = string
}

variable "pod_cidr" {
  description = "GKE pods CIDR range"
  type        = string
}

variable "service_cidr" {
  description = "GKE service cidr range"
  type        = string
}

variable "pod_range_name" {
  description = "GKE pods name range"
  type        = string
}

variable "service_range_name" {
  description = "services name"
  type        = string
}

variable "router_name" {
  description = "GKE cloud router name"
  type = string
}

variable "nat_name" {
  description = "GKE nat name"
  type = string
}