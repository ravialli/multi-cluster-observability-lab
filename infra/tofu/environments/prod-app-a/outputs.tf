output "network_id" {
  description = "GKE network ID"
  value       = module.prod_app_a_network.network_id
}

output "subnet_id" {
  description = "GKE subnet ID"
  value       = module.prod_app_a_network.subnet_id
}

output "pod_range_name" {
  description = "GKE pod range name"
  value       = module.prod_app_a_network.pod_range_name
}

output "service_range_name" {
  description = "GKE service range name"
  value       = module.prod_app_a_network.service_range_name
}
