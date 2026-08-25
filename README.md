# Multi-Cluster Observability Lab

A Kubernetes observability lab built with two Kind clusters.

The **workload cluster** runs the OpenTelemetry Astronomy Shop and collects telemetry. The **monitoring cluster** stores and visualizes that telemetry.

## Architecture

```text
workload-cluster

Astronomy Shop
      |
      v
Grafana Alloy
  /     |      \
metrics logs   traces
  |      |       |
  v      v       v
Mimir   Loki   Tempo
    \    |     /
       Grafana

Prometheus -> Mimir -> Grafana

Application processes
      |
      v
alloy-profiles
      |
      v
Pyroscope -> Grafana
```

## Stack

```text
Terraform
Kind
OpenTelemetry Astronomy Shop
Grafana Alloy
Prometheus
Mimir
Loki
Tempo
Pyroscope
Grafana
```

## Completed Stages

- [x] Stage 1 - Infrastructure
- [x] Stage 2 - Astronomy Shop
- [x] Stage 3 - Instrumentation
- [x] Stage 4a - Grafana Alloy
- [x] Stage 4b - Prometheus
- [x] Stage 4c - Mimir
- [x] Stage 4d - Loki
- [x] Stage 4e - Tempo
- [x] Stage 4f - Pyroscope
- [x] Stage 4g - Grafana
- [x] Stage 4h - Dashboards
- [ ] Stage 4i - Alerting
- [ ] Stage 4j - SLOs
- [ ] Stage 4k - Automation scripts

## Current Telemetry Flow

```text
Metrics  -> Mimir -> Grafana
Logs     -> Loki -> Grafana
Traces   -> Tempo -> Grafana
Profiles -> Pyroscope -> Grafana
```

Prometheus also sends Kubernetes and node metrics to Mimir using remote write.

## Grafana Dashboards

The lab currently has two provisioned dashboards.

### Application RED - Astronomy Shop

Focuses on:

```text
Request rate
5xx errors
Availability
Latency
Traffic by service
HTTP status codes
Top routes
```

The current HTTP metric coverage includes the `cart` and `shipping` services.

### Kubernetes USE - Workload Cluster

Focuses on:

```text
Pod health
Restarts
CPU
Memory
CPU throttling
Deployment readiness
Node count
```

Both dashboards are stored in:

```text
observability/grafana/dashboards/
```

and are provisioned automatically into the Grafana folder:

```text
Observability Lab
```

## Repository Layout

```text
.
├── docs/
│   ├── infra-and-service.md
│   ├── instrumentation.md
│   ├── alloy.md
│   ├── prometheus.md
│   ├── mimir.md
│   ├── loki.md
│   ├── tempo.md
│   ├── pyroscope.md
│   ├── grafana.md
│   └── dashboards.md
├── infra/
│   └── kind/
├── observability/
│   ├── alloy/
│   ├── prometheus/
│   ├── mimir/
│   ├── loki/
│   ├── tempo/
│   ├── pyroscope/
│   └── grafana/
│       ├── values.yaml
│       ├── dashboards-configmap.yaml
│       └── dashboards/
│           ├── application-red.json
│           └── kubernetes-use.json
└── service/
    └── otel-demo/
```

## Current Status

The lab now has centralized metrics, logs, traces, profiling infrastructure, Grafana, and two working dashboards across separate workload and monitoring clusters.

Next:

```text
Stage 4i - Alerting
```
