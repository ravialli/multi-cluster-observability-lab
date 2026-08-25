# Stage 4b: Prometheus

## Overview

This stage introduces **Prometheus** as the workload-cluster metrics scraper.

Grafana Alloy continues to handle application telemetry received over OTLP, while Prometheus focuses on pull-based Kubernetes, node, container, and Alloy operational metrics.

Prometheus is intentionally configured as short-term local storage. Centralized long-term metrics storage will be introduced later with Grafana Mimir.

## Architecture

```text
workload-cluster

Astronomy Shop
     |
     | OTLP
     v
   Alloy
     |
     | application telemetry pipeline
     v
Temporary OpenTelemetry Collector


Kubernetes API ---------+
kube-state-metrics -----+
node-exporter ----------+
cAdvisor ---------------+
Alloy /metrics ---------+
                        |
                        v
                   Prometheus
                        |
                        v
                 Short-term TSDB
```

At this stage, Prometheus does not remote-write metrics to Mimir yet.

## Responsibilities

Prometheus is responsible for scraping:

- Kubernetes API and control-plane metrics
- kube-state-metrics
- node-exporter
- kubelet and cAdvisor metrics
- Grafana Alloy self-metrics

Application OTLP telemetry continues through Alloy and is not routed into Prometheus.

## Directory

Configuration is stored under:

```text
observability/prometheus/
```

Primary values file:

```text
observability/prometheus/values.yaml
```

## Prometheus Helm Configuration

```yaml
alertmanager:
  enabled: false

prometheus-pushgateway:
  enabled: false

kube-state-metrics:
  enabled: true

prometheus-node-exporter:
  enabled: true

server:
  persistentVolume:
    enabled: false

  retention: "6h"

  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      memory: 512Mi

  global:
    scrape_interval: 15s
    scrape_timeout: 10s
    evaluation_interval: 15s

    external_labels:
      cluster: workload-cluster
      environment: lab

extraScrapeConfigs: |
  - job_name: alloy
    scrape_interval: 15s

    static_configs:
      - targets:
          - alloy.observability.svc.cluster.local:12345

        labels:
          component: telemetry-gateway
          cluster: workload-cluster
```

## Design Decisions

### Short-Term Local Storage

Prometheus persistence is disabled:

```yaml
persistentVolume:
  enabled: false
```

The local retention window is limited to:

```yaml
retention: "6h"
```

This keeps the lab lightweight. Mimir will later become the long-term centralized metrics backend.

### Alertmanager Disabled

```yaml
alertmanager:
  enabled: false
```

Alerting is intentionally deferred to the later alerts stage.

### Pushgateway Disabled

```yaml
prometheus-pushgateway:
  enabled: false
```

There is currently no requirement for push-based batch-job metrics.

### Kubernetes Metrics Enabled

Both Kubernetes state and node metrics are enabled:

```yaml
kube-state-metrics:
  enabled: true

prometheus-node-exporter:
  enabled: true
```

This provides object-state, node, container, CPU, memory, and related infrastructure metrics.

### Alloy Self-Monitoring

Prometheus also scrapes Grafana Alloy:

```text
alloy.observability.svc.cluster.local:12345
```

This gives Prometheus visibility into Alloy receiver and exporter behavior.

## Install Prometheus

Add the Prometheus community Helm repository:

```bash
helm repo add prometheus-community   https://prometheus-community.github.io/helm-charts

helm repo update
```

Set the workload-cluster kubeconfig:

```bash
K=~/.kube/kind-config-workload
```

Install Prometheus:

```bash
helm upgrade --install prometheus   prometheus-community/prometheus   --version 29.21.0   --namespace observability   --kubeconfig $K   --values observability/prometheus/values.yaml
```

## Validate the Deployment

Check all observability pods:

```bash
kubectl --kubeconfig $K   -n observability   get pods
```

Validated deployment:

```text
alloy                                         Running
prometheus-kube-state-metrics                 Running
prometheus-prometheus-node-exporter           Running
prometheus-prometheus-node-exporter           Running
prometheus-server                             Running
```

Two node-exporter pods are expected because the Kind workload cluster has two Kubernetes nodes.

## Access Prometheus

Port-forward the Prometheus service:

```bash
kubectl --kubeconfig $K   -n observability   port-forward svc/prometheus-server 9090:80
```

Prometheus is then available locally at:

```text
http://localhost:9090
```

Readiness can be checked with:

```bash
curl -s http://localhost:9090/-/ready
```

## Validate Alloy Scraping

Query:

```bash
curl -sG http://localhost:9090/api/v1/query   --data-urlencode 'query=up{job="alloy"}'
```

Validated result:

```text
job="alloy"
instance="alloy.observability.svc.cluster.local:12345"
cluster="workload-cluster"
component="telemetry-gateway"
up=1
```

This confirms Prometheus can successfully scrape Alloy.

## Validate Kubernetes Pod Metrics

Query:

```bash
curl -sG http://localhost:9090/api/v1/query   --data-urlencode   'query=count(kube_pod_info{namespace="otel-demo"})'
```

Observed validation snapshot:

```text
26
```

This confirms kube-state-metrics is exposing Astronomy Shop pod information.

The number can change if workloads are added, removed, or restarted.

## Validate Node Metrics

Query:

```bash
curl -sG http://localhost:9090/api/v1/query   --data-urlencode   'query=count(node_uname_info)'
```

Observed result:

```text
2
```

This matches the two-node Kind workload cluster.

## Validate cAdvisor CPU Metrics

Query:

```bash
curl -sG http://localhost:9090/api/v1/query   --data-urlencode   'query=count(container_cpu_usage_seconds_total{namespace="otel-demo"})'
```

Observed validation snapshot:

```text
79
```

This confirms container CPU metrics are available for the Astronomy Shop namespace.

## Validate cAdvisor Memory Metrics

Query:

```bash
curl -sG http://localhost:9090/api/v1/query   --data-urlencode   'query=count(container_memory_working_set_bytes{namespace="otel-demo"})'
```

Observed validation snapshot:

```text
79
```

This confirms container working-set memory metrics are available.

## Validate External Labels

Inspect the rendered Prometheus configuration:

```bash
kubectl --kubeconfig $K   -n observability   get configmap prometheus-server   -o yaml |
grep -A5 external_labels
```

Validated configuration:

```yaml
external_labels:
  cluster: workload-cluster
  environment: lab
```

These labels will become important when Prometheus begins remote-writing metrics to centralized Mimir storage.

## Useful PromQL Checks

### Alloy Availability

```promql
up{job="alloy"}
```

Expected:

```text
1
```

### Alloy Accepted Spans

```promql
otelcol_receiver_accepted_spans_total
```

### Alloy Span Rate by Transport

```promql
sum by (transport) (
  rate(otelcol_receiver_accepted_spans_total[1m])
)
```

### Astronomy Shop Pods

```promql
kube_pod_info{namespace="otel-demo"}
```

### Pod Count

```promql
count(kube_pod_info{namespace="otel-demo"})
```

### Node Information

```promql
node_uname_info
```

### Node CPU

```promql
rate(node_cpu_seconds_total{mode!="idle"}[1m])
```

### Available Node Memory

```promql
node_memory_MemAvailable_bytes
```

### Container CPU

```promql
container_cpu_usage_seconds_total{
  namespace="otel-demo"
}
```

### Container Working-Set Memory

```promql
container_memory_working_set_bytes{
  namespace="otel-demo"
}
```

## Stage 4b Validation Results

```text
Prometheus server Running             PASS
kube-state-metrics Running            PASS
node-exporter Running                 PASS
Alloy scrape target UP                PASS
Kubernetes pod metrics available      PASS
Node metrics available                PASS
cAdvisor CPU metrics available        PASS
cAdvisor memory metrics available     PASS
Cluster external label configured     PASS
Environment external label configured PASS
```

## Current Observability Flow

```text
workload-cluster

Application telemetry
Astronomy Shop
     |
     | OTLP/gRPC + OTLP/HTTP
     v
Grafana Alloy
     |
     v
Temporary OpenTelemetry Collector


Infrastructure telemetry
Kubernetes API
kube-state-metrics
node-exporter
kubelet / cAdvisor
Alloy /metrics
     |
     v
Prometheus
     |
     v
6-hour local TSDB
```

## What Is Intentionally Deferred

The following are not part of Stage 4b:

```text
Prometheus remote_write -> Mimir
Long-term metrics retention
Centralized metrics storage
Grafana dashboards
Alertmanager configuration
Alert rules
SLOs
```

These belong to later observability stages.

**Stage 4b status: Complete.**
