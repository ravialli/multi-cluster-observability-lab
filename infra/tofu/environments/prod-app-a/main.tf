module "prod_app_a_network" {
  source = "../../modules/networks"

  project_id   = var.project_id
  region       = var.region
  network_name = "prod-app-a-vpc"
  router_name  = "prod-app-a-router"
  nat_name     = "prod-app-a-nat"
  subnet_name  = "prod-app-a-subnet"

  node_cidr    = "10.10.0.0/20"
  pod_cidr     = "10.20.0.0/16"
  service_cidr = "10.30.0.0/20"

  pod_range_name      = "prod-app-a-pods"
  services_range_name = "prod-app-a-services"
}

module "prod_app_a_gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  cluster_name = "prod-app-a-gke"
  region       = var.region

  network   = module.prod_app_a_network.network_id
  subnet    = module.prod_app_a_network.subnet_id
  node_zone = "us-central1-a"

  pod_range_name      = module.prod_app_a_network.pod_range_name
  services_range_name = module.prod_app_a_network.service_range_name
  service_account_id  = "prod-app-a-gke-nodes"

  spot_node_pool_name = "app-pool"
  spot_machine_type   = "e2-standard-4"
  spot_min_node_count = 0
  spot_max_node_count = 2

  system_node_pool_name = "system-pool"
  system_machine_type   = "e2-standard-2"
  system_min_node_count = 1
  system_max_node_count = 1
  disk_size_gb          = 50
  disk_type             = "pd-balanced"
}