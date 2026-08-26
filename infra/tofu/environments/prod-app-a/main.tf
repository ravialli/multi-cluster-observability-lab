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

  pod_range_name     = "prod-app-a-pods"
  service_range_name = "prod-app-a-services"
}