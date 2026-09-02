data "google_compute_network" "prod_app_a" {
  name    = "prod-app-a-vpc"
  project = var.project_id
}

data "google_compute_network" "prod_monitoring" {
  name    = "prod-monitoring-vpc"
  project = var.project_id
}

resource "google_compute_network_peering" "app_a_to_monitoring" {
  name = "prod-app-a-to-monitoring"

  network      = data.google_compute_network.prod_app_a.self_link
  peer_network = data.google_compute_network.prod_monitoring.self_link
}

resource "google_compute_network_peering" "monitoring_to_app_a" {
  name = "prod-monitoring-to-app-a"

  network      = data.google_compute_network.prod_monitoring.self_link
  peer_network = data.google_compute_network.prod_app_a.self_link
}