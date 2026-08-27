variable "project_id" {
  description = "project ID of the account"
  type        = string
}

variable "region" {
  description = "GKE region"
  type        = string
  default     = "us-central1"
}

variable "network" {
  description = "GKE network"
  type        = string
}

variable "node_zone" {
  description = "GKE nodes zone"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "subnet" {
  description = "GKE subnet"
  type        = string
}


variable "pod_range_name" {
  description = "GKE pods name range"
  type        = string
}

variable "services_range_name" {
  description = "services name"
  type        = string
}

variable "service_account_id" {
  description = "GKE node service account"
  type        = string
}

variable "disk_type" {
  description = "GKE node disk type"
  type        = string
}

variable "disk_size_gb" {
  description = "GKE node disk size gb"
  type        = string
}

variable "system_max_node_count" {
  description = "GKE node max count"
  type        = string
}

variable "system_min_node_count" {
  description = "GKE node min count"
  type        = string
}

variable "system_machine_type" {
  description = "GKE machine type"
  type        = string
}

variable "system_node_pool_name" {
  description = "GKE node pool name"
  type        = string
}


variable "spot_max_node_count" {
  description = "GKE node max count"
  type        = string
}

variable "spot_min_node_count" {
  description = "GKE node min count"
  type        = string
}

variable "spot_machine_type" {
  description = "GKE machine type"
  type        = string
}

variable "spot_node_pool_name" {
  description = "GKE node pool name"
  type        = string
}
