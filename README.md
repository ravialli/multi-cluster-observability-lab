# Multi-Cluster Observability Lab

A hands-on Kubernetes lab for building centralized observability across multiple clusters.

The project uses a separate **workload cluster** and **monitoring cluster** to explore telemetry collection, enrichment, routing, metrics scraping, centralized storage, visualization, alerting, and SLOs.

## Architecture

```text
monitoring-cluster                         workload-cluster
------------------                         ----------------
Central observability                      OpenTelemetry Astronomy Shop
backends (planned)                                 |
                                                    | OTLP/gRPC + OTLP/HTTP
                                                    v
                                              Grafana Alloy
                                                    |
                                                    | enriched OTLP
                                                    v
                                         Temporary OTel Collector

                                          Kubernetes / node metrics
                                                    |
                          +-------------------------+----------------------+
                          |                         |                      |
                  kube-state-metrics          node-exporter           cAdvisor
                          |                         |                      |
                          +-------------------------+----------------------+
                                                    |
                                                    v
                                                Prometheus
```

The monitoring cluster will host the centralized observability backends as the project progresses.

## Project Stages

- [x] Stage 1 - Multi-cluster infrastructure with Terraform + Kind
- [x] Stage 2 - OpenTelemetry Astronomy Shop workload
- [x] Stage 3 - Instrumentation audit

### Stage 4 - Observability Stack

- [x] Stage 4a - Grafana Alloy
- [x] Stage 4b - Prometheus
- [ ] Stage 4c - Grafana Mimir
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
      | OTLP/gRPC :4317
      | OTLP/HTTP :4318
      v
Grafana Alloy
      |
      | resource enrichment
      | batching
      v
Temporary OpenTelemetry Collector
      |
      v
Debug exporter
```

Grafana Alloy is now the application telemetry gateway.

It enriches telemetry with:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

and normalizes `service.namespace` to `opentelemetry-demo` when the attribute is missing.

The standalone OpenTelemetry Collector remains temporary and is used only as a validation sink until the real telemetry backends are connected.

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
      v
6-hour local TSDB
```

Prometheus is responsible for pull-based Kubernetes, node, container, and Alloy operational metrics.

Long-term centralized metrics storage is intentionally deferred to Grafana Mimir.

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

No additional application source instrumentation is required for the lab.

Profiles are intentionally deferred until the Pyroscope stage.

## Stage 4a - Grafana Alloy

Grafana Alloy was deployed as a single-replica telemetry gateway in the workload cluster.

Validation confirmed that Alloy receives all three major telemetry signals over both OTLP transports:

```text
Logs     -> OTLP/gRPC + OTLP/HTTP
Metrics  -> OTLP/gRPC + OTLP/HTTP
Traces   -> OTLP/gRPC + OTLP/HTTP
```

Alloy also successfully forwards telemetry to the temporary OpenTelemetry Collector.

Resource enrichment was validated downstream:

```text
k8s.cluster.name: Str(workload-cluster)
deployment.environment.name: Str(lab)
```

No Alloy transform or OTTL errors were observed during validation.

## Stage 4b - Prometheus

Prometheus was added as the workload-cluster metrics scraper.

The deployment includes:

- Prometheus server
- kube-state-metrics
- node-exporter on both Kind nodes
- Kubernetes API / kubelet / cAdvisor scraping
- Alloy self-metrics scraping

Validated examples:

```text
Alloy target UP                         -> 1
otel-demo pod count                     -> 26
node_uname_info count                   -> 2
container CPU metric series             -> 79
container working-set memory series     -> 79
```

Prometheus external labels are configured as:

```yaml
cluster: workload-cluster
environment: lab
```

These labels will be used when Prometheus begins sending metrics to the centralized Mimir backend.

Prometheus currently uses a short local retention window:

```text
6 hours
```

Persistent storage and remote write are intentionally deferred.

## Repository Structure

```text
.
├── docs/
│   ├── infra-and-service.md
│   ├── instrumentation.md
│   ├── alloy.md
│   └── prometheus.md
├── infra/
│   └── kind/
│       ├── main.tf
│       └── .terraform.lock.hcl
├── observability/
│   ├── alloy/
│   │   └── values.yaml
│   └── prometheus/
│       └── values.yaml
└── service/
    └── otel-demo/
        ├── values.yaml
        └── collector-values.yaml
```

## Documentation

- [Infra and Service](docs/infra-and-service.md) - Kind infrastructure, Terraform, and Astronomy Shop deployment
- [Instrumentation](docs/instrumentation.md) - Stage 3 telemetry audit and instrumentation decisions
- [Grafana Alloy](docs/alloy.md) - Stage 4a Alloy deployment, routing, enrichment, and validation
- [Prometheus](docs/prometheus.md) - Stage 4b metrics scraping, PromQL validation, and design decisions

## Planned Stack

Grafana Alloy · Prometheus · Mimir · Loki · Tempo · Pyroscope · Grafana

## Current Status

Completed:

```text
Stage 1   Infrastructure       COMPLETE
Stage 2   Service              COMPLETE
Stage 3   Instrumentation      COMPLETE
Stage 4a  Grafana Alloy        COMPLETE
Stage 4b  Prometheus           COMPLETE
```

The workload cluster is now producing and collecting two complementary telemetry streams:

1. **Application telemetry** flows from Astronomy Shop through Grafana Alloy.
2. **Infrastructure metrics** are scraped by Prometheus from Kubernetes, nodes, containers, and Alloy itself.

The next stage is **Stage 4c - Grafana Mimir**, which will introduce centralized metrics storage and connect the workload-cluster metrics pipeline to the monitoring cluster.
