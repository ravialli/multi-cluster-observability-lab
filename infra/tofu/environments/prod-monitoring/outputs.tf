output "network_id" {
  description = "GKE monitoring network ID"
  value       = module.prod_monitoring_network.network_id
}

output "subnet_id" {
  description = "GKE monitoring subnet ID"
  value       = module.prod_monitoring_network.subnet_id
}

output "pod_range_name" {
  description = "GKE monitoring pod range name"
  value       = module.prod_monitoring_network.pod_range_name
}

output "service_range_name" {
  description = "GKE monitoring service range name"
  value       = module.prod_monitoring_network.service_range_name
}

output "observability_bucket_names_map" {
  description = "A map of local keys to their respective bucket names."
  value       = { for k, bucket in google_storage_bucket.observability : k => bucket.name }
}