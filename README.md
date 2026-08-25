# Multi-Cluster Observability Lab

A hands-on Kubernetes lab for building centralized observability across multiple clusters.

The project uses a separate **workload cluster** and **monitoring cluster** to explore telemetry collection, enrichment, routing, metrics scraping, centralized storage, visualization, alerting, and SLOs.

## Architecture

```text
monitoring-cluster                           workload-cluster
------------------                           ----------------
Grafana Mimir                                OpenTelemetry Astronomy Shop
     ^                                               |
     |                                               | OTLP
     |                                               v
     |                                         Grafana Alloy
     |                                               |
     |                          application metrics  |
     +-----------------------------------------------+
     |
     | remote_write
     |
Prometheus <----- Kubernetes / nodes / containers / Alloy
```

The workload cluster runs the application and local telemetry collection components. The monitoring cluster hosts centralized observability backends.

## Project Stages

- [x] Stage 1 - Multi-cluster infrastructure with Terraform + Kind
- [x] Stage 2 - OpenTelemetry Astronomy Shop workload
- [x] Stage 3 - Instrumentation audit

### Stage 4 - Observability Stack

- [x] Stage 4a - Grafana Alloy
- [x] Stage 4b - Prometheus
- [x] Stage 4c - Grafana Mimir
- [ ] Stage 4d - Grafana Loki
- [ ] Stage 4e - Grafana Tempo
- [ ] Stage 4f - Grafana Pyroscope
- [ ] Stage 4g - Grafana
- [ ] Stage 4h - Dashboards
- [ ] Stage 4i - Alerting
- [ ] Stage 4j - SLOs
- [ ] Stage 4k - Automation scripts

## Current Telemetry Flow

### Application Telemetry

```text
Astronomy Shop
      |
      | OTLP/gRPC + OTLP/HTTP
      v
Grafana Alloy
      |
      +------ metrics ------> Grafana Mimir
      |
      +------ logs ---------> Temporary OTel Collector
      |
      +------ traces -------> Temporary OTel Collector
```

Grafana Alloy is the application telemetry gateway.

It enriches telemetry with:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

and normalizes `service.namespace` to `opentelemetry-demo` when needed.

Application metrics are now stored centrally in Mimir.

### Infrastructure Metrics

```text
Kubernetes API
kube-state-metrics
node-exporter
kubelet / cAdvisor
Alloy /metrics
      |
      v
Prometheus
      |
      | remote_write
      v
Grafana Mimir
```

Prometheus remains the workload-cluster scraper and short-term metrics store.

Mimir is now the centralized metrics backend for both application and infrastructure metrics.

## Stage 3 - Instrumentation Audit

The Astronomy Shop workload was audited before introducing another telemetry collection layer.

The audit confirmed:

- traces are reaching the telemetry pipeline
- metrics are reaching the telemetry pipeline
- logs are reaching the telemetry pipeline
- services use both OTLP/gRPC and OTLP/HTTP
- `service.name` is derived from the Kubernetes workload component label
- `service.namespace` is set to `opentelemetry-demo`
- application telemetry includes `service.version`
- services include `service.criticality` where configured

Example transport patterns:

```text
cart / payment          -> OTLP/gRPC on 4317
checkout / shipping     -> OTLP/HTTP on 4318
```

No additional application source instrumentation is required.

Profiles are intentionally deferred until the Pyroscope stage.

## Stage 4a - Grafana Alloy

Grafana Alloy runs as a telemetry gateway in the workload cluster.

Validation confirmed:

```text
OTLP/gRPC logs       PASS
OTLP/HTTP logs       PASS
OTLP/gRPC metrics    PASS
OTLP/HTTP metrics    PASS
OTLP/gRPC traces     PASS
OTLP/HTTP traces     PASS
```

Resource enrichment was validated downstream:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

No persistent transform or OTTL errors were observed.

## Stage 4b - Prometheus

Prometheus runs in the workload cluster and scrapes:

- kube-state-metrics
- node-exporter
- Kubernetes API
- kubelet / cAdvisor
- Alloy self-metrics

Validated examples:

```text
Alloy target UP                     -> 1
otel-demo pod count                 -> 26
node_uname_info count               -> 2
container CPU metric series         -> 79
container memory metric series      -> 79
```

Prometheus external labels:

```yaml
cluster: workload-cluster
environment: lab
```

Local retention remains intentionally short:

```text
6 hours
```

## Stage 4c - Grafana Mimir

Grafana Mimir runs in the monitoring cluster as the centralized metrics backend.

For this Kind lab, Mimir runs in monolithic mode:

```text
-target=all
```

and uses filesystem storage.

### Cross-Cluster Path

The Kind clusters share Docker's `kind` network.

The workload cluster reaches Mimir through:

```text
monitoring-cluster-worker:30909
```

which maps to Mimir's HTTP port:

```text
9009
```

This avoids incorrectly relying on Kubernetes service DNS across clusters.

### Prometheus -> Mimir

Prometheus sends infrastructure metrics using `remote_write` to:

```text
http://monitoring-cluster-worker:30909/api/v1/push
```

Validated centrally in Mimir:

```text
Alloy target UP       -> 1
otel-demo pods        -> 26
Kind nodes            -> 2
```

with:

```text
cluster="workload-cluster"
environment="lab"
```

### Alloy -> Mimir

Application metrics are exported from Alloy using OTLP/HTTP:

```text
http://monitoring-cluster-worker:30909/otlp/v1/metrics
```

Mimir promotes selected OpenTelemetry resource attributes into Prometheus labels:

```text
k8s.cluster.name             -> k8s_cluster_name
deployment.environment.name  -> deployment_environment_name
service.version              -> service_version
service.criticality          -> service_criticality
```

Application metric validation returned:

```text
2516 series
```

for:

```text
k8s_cluster_name="workload-cluster"
deployment_environment_name="lab"
```

Observed service criticality values:

```text
critical
high
medium
low
```

Alloy's Mimir exporter counter increased from:

```text
4,888 -> 12,631 -> 16,267
```

confirming continuous application metric delivery.

No persistent Alloy export failures or recent persistent Mimir errors remained after validation.

## Repository Structure

```text
.
├── docs/
│   ├── infra-and-service.md
│   ├── instrumentation.md
│   ├── alloy.md
│   ├── prometheus.md
│   └── mimir.md
├── infra/
│   └── kind/
│       ├── main.tf
│       └── .terraform.lock.hcl
├── observability/
│   ├── alloy/
│   │   └── values.yaml
│   ├── prometheus/
│   │   └── values.yaml
│   └── mimir/
│       └── mimir.yaml
└── service/
    └── otel-demo/
        ├── values.yaml
        └── collector-values.yaml
```

## Documentation

- [Infra and Service](docs/infra-and-service.md) - Kind infrastructure, Terraform, and Astronomy Shop deployment
- [Instrumentation](docs/instrumentation.md) - Stage 3 telemetry audit and instrumentation decisions
- [Grafana Alloy](docs/alloy.md) - Stage 4a routing, enrichment, and validation
- [Prometheus](docs/prometheus.md) - Stage 4b metrics scraping and PromQL validation
- [Grafana Mimir](docs/mimir.md) - Stage 4c centralized metrics storage, remote write, OTLP ingestion, and cross-cluster validation

## Planned Stack

Grafana Alloy · Prometheus · Mimir · Loki · Tempo · Pyroscope · Grafana

## Current Status

```text
Stage 1   Infrastructure       COMPLETE
Stage 2   Service              COMPLETE
Stage 3   Instrumentation      COMPLETE
Stage 4a  Grafana Alloy        COMPLETE
Stage 4b  Prometheus           COMPLETE
Stage 4c  Grafana Mimir        COMPLETE
```

The lab now has centralized metrics storage across two Kubernetes clusters.

Two independent metric paths converge in Mimir:

1. **Infrastructure metrics** are scraped by Prometheus and sent using remote write.
2. **Application metrics** are received and enriched by Alloy, then exported using OTLP/HTTP.

The next stage is **Stage 4d - Grafana Loki**, which will introduce centralized log storage.
