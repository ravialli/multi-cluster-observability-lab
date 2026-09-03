locals {
  observability_endpoints = {
    mimir = "mimir-ilb-ip"
    loki  = "loki-ilb-ip"
    tempo = "tempo-ilb-ip"
  }
}

data "google_compute_address" "observability_ilb" {
  for_each = local.observability_endpoints

  project = var.project_id
  region  = var.region
  name    = each.value
}

resource "google_dns_managed_zone" "observability" {
  project     = var.project_id
  name        = "observability-internal"
  dns_name    = "observability.internal."
  description = "Private DNS for centralized observability endpoints"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.prod_app_a.id
    }

    networks {
      network_url = data.google_compute_network.prod_monitoring.id
    }
  }
}

resource "google_dns_record_set" "observability" {
  for_each = local.observability_endpoints

  project      = var.project_id
  managed_zone = google_dns_managed_zone.observability.name

  name = "${each.key}.observability.internal."
  type = "A"
  ttl  = 30

  rrdatas = [
    data.google_compute_address.observability_ilb[each.key].address
  ]
}