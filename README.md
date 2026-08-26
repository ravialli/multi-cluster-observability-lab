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
- [x] Stage 4i - Alerting
- [x] Stage 4j - SLOs
- [ ] Stage 4k - Automation scripts

## Telemetry Flow

```text
Metrics  -> Mimir -> Grafana
Logs     -> Loki -> Grafana
Traces   -> Tempo -> Grafana
Profiles -> Pyroscope -> Grafana
```

Prometheus also sends Kubernetes and node metrics to Mimir using remote write.

## Grafana Dashboards

The lab currently has three provisioned dashboards:

```text
Application RED - Astronomy Shop
Kubernetes USE - Workload Cluster
Service SLO - Astronomy Shop
```

They are stored in:

```text
observability/grafana/dashboards/
```

and loaded automatically into the Grafana folder:

```text
Observability Lab
```

The RED dashboard focuses on request rate, errors, availability, latency, status codes, and top routes.

The Kubernetes USE dashboard focuses on pod health, restarts, CPU, memory, throttling, deployment readiness, and node count.

The SLO dashboard tracks 99% availability and 95% latency targets for the validated HTTP metrics on the `cart` and `shipping` services.

## Alerting

Grafana alert rules are provisioned from:

```text
observability/grafana/alerting/alert-rules.yaml
```

Current rules cover:

```text
HTTP 5xx error rate
HTTP p95 latency
Pod restarts
Unavailable deployment replicas
Availability burn rate
Latency burn rate
```

The alerting flow was validated with a real pod restart event that moved from firing back to normal.

## SLOs

The lab uses two simple service objectives:

```text
Availability: 99%
Latency:      95% of requests under 500 ms
```

For this local lab, SLO calculations use short evaluation windows rather than a production-style monthly window.

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
│   ├── dashboards.md
│   ├── alerting.md
│   └── slo.md
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
│       ├── alerting/
│       │   ├── alert-rules.yaml
│       │   └── alert-rules-configmap.yaml
│       └── dashboards/
│           ├── application-red.json
│           ├── kubernetes-use.json
│           └── service-slo.json
└── service/
    └── otel-demo/
```

## Current Status

The lab now has centralized metrics, logs, traces, profiling infrastructure, Grafana dashboards, alerting, and basic SLO tracking across separate workload and monitoring clusters.

Next:

```text
Stage 4k - Automation scripts
```
