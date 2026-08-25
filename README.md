# Multi-Cluster Observability Lab

A hands-on Kubernetes lab for building centralized observability across multiple clusters.

The project uses a separate workload cluster and monitoring cluster to explore telemetry collection, routing, storage, visualization, alerting, and SLOs.

## Architecture

```text
monitoring-cluster                   workload-cluster
------------------                   ----------------
Observability stack                  Astronomy Shop
        ^                                  |
        |                                  | OTLP
        |                                  v
        +----------------------------- telemetry
```

## Project Stages

- [x] Stage 1 - Multi-cluster infrastructure with Terraform + Kind
- [x] Stage 2 - OpenTelemetry Astronomy Shop workload
- [ ] Stage 3 - Instrumentation audit
- [ ] Stage 4 - Grafana Alloy
- [ ] Stage 5 - Prometheus / Mimir
- [ ] Stage 6 - Loki
- [ ] Stage 7 - Tempo
- [ ] Stage 8 - Pyroscope
- [ ] Stage 9 - Grafana dashboards
- [ ] Stage 10 - Alerting
- [ ] Stage 11 - SLOs
- [ ] Stage 12 - Automation scripts

## Current Telemetry Flow

```text
Astronomy Shop
      |
      | OTLP gRPC / HTTP
      v
OpenTelemetry Collector
      |
      v
Debug exporter
```

The standalone collector is temporary. It is currently used to validate application telemetry before Grafana Alloy and the centralized observability backends are introduced.

## Repository Structure

```text
.
├── docs/
│   └── stage-1-2.md
├── infra/
│   └── kind/
│       ├── main.tf
│       └── .terraform.lock.hcl
└── service/
    └── otel-demo/
        ├── values.yaml
        └── collector-values.yaml
```

## Documentation

See [Infra and Service](docs/infra-and-service.md) for setup details, architecture, commands, and validation steps.

## Planned Stack

Grafana Alloy · Prometheus · Mimir · Loki · Tempo · Pyroscope · Grafana

## Current Status

Stage 1 and Stage 2 are complete.

The next step is an instrumentation audit to identify:

- services emitting traces
- services emitting metrics
- services emitting logs
- OTLP protocol usage
- resource attributes
- automatic vs manual instrumentation
- instrumentation gaps

