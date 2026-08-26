variable "project_id" {
  description = "project id"
  type        = string
}

variable "region" {
  description = "GCloud region"
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Name of the GCS bucket used for OpenTofu remote state"
  type        = string
}

