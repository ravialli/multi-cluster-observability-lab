# Stage 4c: Grafana Mimir

## Overview

This stage introduces **Grafana Mimir** as the centralized metrics backend running in the monitoring cluster.

Two metric streams now converge in Mimir:

1. **Infrastructure metrics** scraped by Prometheus in the workload cluster and sent through Prometheus `remote_write`.
2. **Application metrics** received by Grafana Alloy over OTLP and exported directly to Mimir using OTLP/HTTP.

This is the first stage where telemetry crosses the workload-cluster / monitoring-cluster boundary and is stored centrally.

## Architecture

```text
workload-cluster

Application metrics
Astronomy Shop
      |
      | OTLP/gRPC + OTLP/HTTP
      v
Grafana Alloy
      |
      | OTLP/HTTP
      v
================ cluster boundary ================
      |
      v
Grafana Mimir
monitoring-cluster


Infrastructure metrics
Kubernetes / nodes / containers / Alloy
      |
      v
Prometheus
      |
      | remote_write
      v
================ cluster boundary ================
      |
      v
Grafana Mimir
monitoring-cluster
```

## Deployment Model

Mimir runs in **monolithic mode** using:

```text
-target=all
```

This keeps the local Kind lab lightweight while still providing a real Prometheus-compatible centralized metrics backend.

Filesystem storage is used for this lab instead of object storage.

## Directory

Configuration is stored under:

```text
observability/mimir/
```

Primary manifest:

```text
observability/mimir/mimir.yaml
```

## Mimir Configuration

Key settings:

```yaml
multitenancy_enabled: false

usage_stats:
  enabled: false

limits:
  promote_otel_resource_attributes: "k8s.cluster.name,deployment.environment.name,service.version,service.criticality"

blocks_storage:
  backend: filesystem

  bucket_store:
    sync_dir: /tmp/mimir/tsdb-sync

  filesystem:
    dir: /tmp/mimir/data/tsdb

  tsdb:
    dir: /tmp/mimir/tsdb

compactor:
  data_dir: /tmp/mimir/compactor

  sharding_ring:
    kvstore:
      store: memberlist

distributor:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: memberlist

ingester:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: memberlist
    replication_factor: 1

ruler_storage:
  backend: filesystem
  filesystem:
    dir: /tmp/mimir/rules

server:
  http_listen_port: 9009
  log_level: info

store_gateway:
  sharding_ring:
    replication_factor: 1
```

## Deployment

The Mimir Deployment uses:

```yaml
image: grafana/mimir:3.1.4
```

with:

```yaml
args:
  - -config.file=/etc/mimir/mimir.yaml
  - -target=all
```

The service exposes Mimir through:

```text
service port: 9009
NodePort:     30909
```

## Cross-Cluster Networking

The workload and monitoring Kind clusters share Docker's `kind` network.

Validation showed all four Kind nodes attached to the same Docker network:

```text
workload-cluster-control-plane
workload-cluster-worker
monitoring-cluster-control-plane
monitoring-cluster-worker
```

A pod inside the workload cluster successfully reached:

```text
http://monitoring-cluster-worker:30909/ready
```

and received:

```text
ready
```

This proves the explicit cross-cluster path:

```text
workload-cluster pod
        |
        v
monitoring-cluster-worker:30909
        |
        v
NodePort
        |
        v
Mimir :9009
```

Kubernetes service DNS is not used across clusters.

## Validate Mimir

Port-forward:

```bash
KM=~/.kube/kind-config-monitoring

kubectl --kubeconfig $KM \
  -n observability \
  port-forward svc/mimir 9009:9009
```

Readiness:

```bash
curl -s http://localhost:9009/ready
```

Validated result:

```text
ready
```

Build information:

```bash
curl -s http://localhost:9009/api/v1/status/buildinfo
```

Validated version:

```text
Grafana Mimir 3.1.4
```

## Prometheus -> Mimir

Prometheus sends infrastructure metrics using `remote_write` to:

```text
http://monitoring-cluster-worker:30909/api/v1/push
```

Prometheus retains its external labels:

```yaml
external_labels:
  cluster: workload-cluster
  environment: lab
```

These labels are preserved in Mimir.

### Validate Prometheus Metrics in Mimir

Alloy target:

```bash
curl -sG http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode 'query=up{job="alloy"}'
```

Validated result:

```text
up=1
cluster="workload-cluster"
environment="lab"
```

Astronomy Shop pod count:

```bash
curl -sG http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode \
  'query=count(kube_pod_info{namespace="otel-demo",cluster="workload-cluster"})'
```

Observed result:

```text
26
```

Node count:

```bash
curl -sG http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode \
  'query=count(node_uname_info{cluster="workload-cluster"})'
```

Observed result:

```text
2
```

## Alloy -> Mimir

Application metrics are exported from Alloy directly to Mimir using OTLP/HTTP.

The Alloy batch processor sends metrics to both the temporary OpenTelemetry Collector and Grafana Mimir, while logs and traces continue only to the temporary collector.

Relevant Alloy exporter:

```river
otelcol.exporter.otlphttp "mimir_metrics" {
  client {
    endpoint = "http://monitoring-cluster-worker:30909/otlp"
  }
}
```

The resulting Mimir endpoint is:

```text
http://monitoring-cluster-worker:30909/otlp/v1/metrics
```

## Resource Attribute Promotion

Mimir promotes selected OpenTelemetry resource attributes into Prometheus labels:

```text
k8s.cluster.name
deployment.environment.name
service.version
service.criticality
```

After OTLP conversion, these become:

```text
k8s_cluster_name
deployment_environment_name
service_version
service_criticality
```

## Validate Alloy Metrics Export

```bash
curl -s localhost:12345/metrics |
grep 'otelcol_exporter_sent_metric_points_total' |
grep 'mimir_metrics'
```

Observed counter progression:

```text
4,888
12,631
16,267
```

This proves metric export is continuous.

No `otelcol_exporter_send_failed_metric_points_total` series was observed for the Mimir exporter during the final validation.

## Validate Application Metrics in Mimir

Application jobs discovered in Mimir included:

```text
opentelemetry-demo/accounting
opentelemetry-demo/ad
opentelemetry-demo/cart
opentelemetry-demo/currency
opentelemetry-demo/email
opentelemetry-demo/fraud-detection
opentelemetry-demo/frontend
opentelemetry-demo/kafka
opentelemetry-demo/load-generator
opentelemetry-demo/mcp
opentelemetry-demo/payment
opentelemetry-demo/recommendation
opentelemetry-demo/shipping
```

Query by service:

```bash
curl -sG \
  http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode \
  'query=count by (job) ({job=~"opentelemetry-demo/.+",k8s_cluster_name="workload-cluster"})'
```

## Validate Cluster and Environment Identity

```bash
curl -sG \
  http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode \
  'query=count({job=~"opentelemetry-demo/.+",k8s_cluster_name="workload-cluster"})'
```

Observed result:

```text
2516
```

Environment query:

```bash
curl -sG \
  http://localhost:9009/prometheus/api/v1/query \
  --data-urlencode \
  'query=count({job=~"opentelemetry-demo/.+",k8s_cluster_name="workload-cluster",deployment_environment_name="lab"})'
```

Observed result:

```text
2516
```

This proves the Stage 4a Alloy enrichment survived the complete path into centralized storage.

## Validate Service Criticality

```bash
curl -s \
  http://localhost:9009/prometheus/api/v1/label/service_criticality/values
```

Validated values:

```text
critical
high
low
medium
```

## Transient Ingestion Error

During Mimir reconfiguration, one temporary ingestion error was observed:

```text
httpCode=503
failed pushing to ingester
context deadline exceeded
```

Follow-up validation confirmed:

```text
Mimir pod              1/1 Running
Mimir readiness        ready
Recent errors          none
Alloy failed exports   none observed
Metric export counter  continued increasing
Application query      successful
```

The error was classified as a transient startup/reconfiguration event rather than an ongoing ingestion failure.

## Stage 4c Validation Results

```text
Mimir 3.1.4 running                         PASS
Mimir readiness                             PASS
Monitoring-cluster placement                PASS
Cross-cluster NodePort connectivity         PASS

Prometheus remote_write                     PASS
Infrastructure metrics in Mimir             PASS
Alloy self-metrics in Mimir                 PASS
Kubernetes pod metrics in Mimir             PASS
Node metrics in Mimir                       PASS
Prometheus cluster/environment labels       PASS

Alloy OTLP/HTTP metrics export              PASS
Application metrics in Mimir                PASS
k8s_cluster_name                            PASS
deployment_environment_name                 PASS
service_criticality                         PASS
Continuous metric export                    PASS
Persistent export failures                  NONE
Recent persistent Mimir errors              NONE
```

## What Is Intentionally Deferred

```text
Loki
Tempo
Pyroscope
Grafana dashboards
Alerting
SLOs
Persistent production-grade object storage
High-availability Mimir deployment
```

**Stage 4c status: Complete.**
