output "network_id" {
  description = "GKE network id"
  value       = google_compute_network.vpc_network.id
}

output "network_name" {
  description = "GKE netowrk name"
  value       = google_compute_network.vpc_network.name
}

output "subnet_id" {
  description = "GKE subnet id"
  value       = google_compute_subnetwork.vpc_subnet.id
}

output "subnet_name" {
  description = "GKE subnet name"
  value       = google_compute_subnetwork.vpc_subnet.name
}

output "pod_range_name" {
  description = "GKE pod range"
  value       = var.pod_range_name
}

output "service_range_name" {
  description = "GKE service range name"
  value       = var.services_range_name
}
