resource "google_container_cluster" "gke" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  node_locations           = [var.node_zone]
  network                  = var.network
  subnetwork               = var.subnet
  networking_mode          = "VPC_NATIVE"

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
    ip_endpoints_config {
      enabled = false
    }
  }
  private_cluster_config {
    enable_private_nodes = true
  }
  datapath_provider     = "ADVANCED_DATAPATH"
  enable_shielded_nodes = true
  deletion_protection   = true
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  release_channel {
    channel = "REGULAR"
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = false
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.services_range_name
  }
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "GKE node service account"
}

resource "google_project_iam_member" "default" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_container_node_pool" "gke_system_node_pool" {
  depends_on = [google_project_iam_member.default]
  cluster = google_container_cluster.gke.id
  name = var.system_node_pool_name
  project = var.project_id
  location = var.region
  node_locations = [var.node_zone]
  autoscaling {
    min_node_count = var.system_min_node_count
    max_node_count = var.system_max_node_count
  }
  
  node_config {
    machine_type = var.system_machine_type
    disk_type = var.disk_type
    spot = false
    disk_size_gb = var.disk_size_gb
    image_type = "COS_CONTAINERD"
    service_account = google_service_account.service_account.email
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    labels = {
      "environment" = "prod"
      "workload"    = "system"
      "cluster"     = "prod-app-a"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  management {
    auto_repair = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "gke_app_node_pool" {
  depends_on = [google_project_iam_member.default]
  cluster = google_container_cluster.gke.id
  name = var.spot_node_pool_name
  project = var.project_id
  location = var.region
  node_locations = [var.node_zone]
  autoscaling {
    min_node_count = var.spot_min_node_count
    max_node_count = var.spot_max_node_count
  }
  
  node_config {
    machine_type = var.spot_machine_type
    disk_type = var.disk_type
    spot = true
    disk_size_gb = var.disk_size_gb
    image_type = "COS_CONTAINERD"
    service_account = google_service_account.service_account.email
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    labels = {
      "environment" = "prod"
      "workload"    = "application"
      "cluster"     = "prod-app-a"
    }
    taint {
      key    = "cloud.google.com/gke-spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  management {
    auto_repair = true
    auto_upgrade = true
  }
}