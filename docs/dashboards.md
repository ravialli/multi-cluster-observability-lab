# Stage 4h: Grafana Dashboards

## Overview

This stage adds two Grafana dashboards for the observability lab:

- **Application RED - Astronomy Shop**
- **Kubernetes USE - Workload Cluster**

Both dashboards are stored as JSON in the repository and provisioned automatically through Grafana.

## Application RED Dashboard

The RED dashboard focuses on application traffic and currently uses the HTTP metrics available for the `cart` and `shipping` services.

It includes:

- Request rate
- 5xx error rate
- HTTP availability
- p95 latency
- Request throughput by service
- p50 / p95 / p99 latency
- Responses by status code
- Top routes by request rate

Main metric family:

```text
http_server_request_duration_count
http_server_request_duration_bucket
```

Main labels:

```text
job
http_response_status_code
http_route
http_request_method
k8s_cluster_name
deployment_environment_name
```

Dashboard file:

```text
observability/grafana/dashboards/application-red.json
```

## Kubernetes USE Dashboard

The USE dashboard focuses on workload-cluster health and resource usage.

It includes:

- Running pods
- Container restarts
- Unavailable replicas
- Cluster nodes
- CPU usage by pod
- Memory working set by pod
- CPU throttling by pod
- Deployment readiness

Main metrics include:

```text
container_cpu_usage_seconds_total
container_memory_working_set_bytes
container_cpu_cfs_throttled_periods_total
container_cpu_cfs_periods_total
kube_pod_status_phase
kube_pod_container_status_restarts_total
kube_deployment_status_replicas_ready
kube_deployment_status_replicas_unavailable
```

Dashboard file:

```text
observability/grafana/dashboards/kubernetes-use.json
```

## Provisioning

Both dashboards are loaded from the same ConfigMap:

```text
grafana-observability-dashboards
```

Grafana places them under:

```text
Observability Lab
```

The dashboards are provisioned from Git-managed files rather than created manually in the UI.

## Validation

Both dashboards were validated through the Grafana API.

```text
Application RED - Astronomy Shop
UID: application-red
Panels: 8
Provisioned: true

Kubernetes USE - Workload Cluster
UID: kubernetes-use
Panels: 8
Provisioned: true
```

Grafana logs also showed no dashboard provisioning errors.

## Stage Status

```text
Stage 4h - Dashboards: COMPLETE
```

Next:

```text
Stage 4i - Alerting
```
