module "prod_monitoring_network" {
  source = "../../modules/networks"

  project_id   = var.project_id
  region       = var.region
  network_name = "prod-monitoring-vpc"
  router_name  = "prod-monitoring-router"
  nat_name     = "prod-monitoring-nat"
  subnet_name  = "prod-monitoring-subnet"

  node_cidr    = "10.40.0.0/20"
  pod_cidr     = "10.50.0.0/16"
  service_cidr = "10.60.0.0/20"

  pod_range_name      = "prod-monitoring-pods"
  services_range_name = "prod-monitoring-services"
}

module "prod_monitoring_gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  cluster_name = "prod-monitoring-gke"
  region       = var.region

  network   = module.prod_monitoring_network.network_id
  subnet    = module.prod_monitoring_network.subnet_id
  node_zone = ["us-central1-a"]

  pod_range_name      = module.prod_monitoring_network.pod_range_name
  services_range_name = module.prod_monitoring_network.service_range_name
  service_account_id  = "prod-monitoring-gke-nodes"

  spot_node_pool_name       = "monitoring-pool"
  spot_machine_type         = "e2-standard-4"
  workload_spot             = false
  spot_total_min_node_count = 1
  spot_total_max_node_count = 2

  system_node_pool_name = "system-pool"
  system_machine_type   = "e2-standard-2"
  system_min_node_count = 1
  system_max_node_count = 1
  disk_size_gb          = 50
  disk_type             = "pd-balanced"
  cluster_label         = "prod-monitoring"
  system_workload_label = "system"
  workload_label        = "observability"
}
