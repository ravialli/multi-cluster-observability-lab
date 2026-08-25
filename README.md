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
- [x] Stage 3 - Instrumentation audit
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

## Stage 3 - Instrumentation Audit

The Astronomy Shop workload was audited before adding another telemetry collection layer.

The audit confirmed:

- traces are reaching the collector
- metrics are reaching the collector
- logs are reaching the collector
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

No additional application instrumentation is required for the lab at this stage. The existing OpenTelemetry instrumentation is kept unchanged.

Cluster and environment identity will be added centrally in Grafana Alloy instead of being duplicated across individual services:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

Profiles are intentionally deferred until the Pyroscope stage.

## Repository Structure

```text
.
├── docs/
│   ├── stage-1-2.md
│   └── instrumentation.md
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

See [Instrumentation](docs/instrumentation.md) for the Stage 3 telemetry audit and instrumentation decisions.

## Planned Stack

Grafana Alloy · Prometheus · Mimir · Loki · Tempo · Pyroscope · Grafana

## Current Status

Stage 1, Stage 2, and Stage 3 are complete.

The workload is already producing traces, metrics, and logs through a mix of OTLP/gRPC and OTLP/HTTP. No additional application source instrumentation is required.

The next step is Grafana Alloy, which will become the telemetry collection and processing layer before the centralized observability backends are introduced.
