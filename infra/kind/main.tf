terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.0.12"
    }
  }
}

provider "kind" {}

# Cluster 1: Centralized monitoring / observability
resource "kind_cluster" "monitoring_cluster" {
  name            = "monitoring-cluster"
  node_image      = "kindest/node:v1.29.2"
  wait_for_ready  = true
  kubeconfig_path = pathexpand("~/.kube/kind-config-monitoring")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }
  }
}

# Cluster 2: Application workloads
resource "kind_cluster" "workload_cluster" {
  name            = "workload-cluster"
  node_image      = "kindest/node:v1.29.2"
  wait_for_ready  = true
  kubeconfig_path = pathexpand("~/.kube/kind-config-workload")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }
  }
}

output "monitoring_cluster_endpoint" {
  value       = kind_cluster.monitoring_cluster.endpoint
  description = "Monitoring Kubernetes API server endpoint"
}

output "workload_cluster_endpoint" {
  value       = kind_cluster.workload_cluster.endpoint
  description = "Workload Kubernetes API server endpoint"
}
