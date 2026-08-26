resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "vpc_subnet" {
  project                  = var.project_id
  name                     = var.subnet_name
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = var.node_cidr
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = var.pod_range_name
    ip_cidr_range = var.pod_cidr
  }
  secondary_ip_range {
    range_name    = var.service_range_name
    ip_cidr_range = var.service_cidr
  }
}
resource "google_compute_router" "my_router" {
  project = var.project_id
  name    = var.router_name
  network = google_compute_network.vpc_network.name
  region  = var.region
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.my_router.name
  region                             = google_compute_router.my_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}