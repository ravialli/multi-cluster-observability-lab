# Multi-Cluster Observability Lab

A hands-on Kubernetes lab for building centralized observability across multiple clusters.

## Architecture

```text
workload-cluster

Astronomy Shop
     |
     v
Grafana Alloy
  /    |    \
metrics logs traces
  |     |     |
  v     v     v
Mimir  Loki  Tempo
   \    |    /
      Grafana

Application processes
     |
     | eBPF
     v
alloy-profiles
     |
     v
Pyroscope
     |
     v
Grafana
```

## Project Stages

- [x] Stage 1 - Multi-cluster infrastructure with Terraform + Kind
- [x] Stage 2 - OpenTelemetry Astronomy Shop workload
- [x] Stage 3 - Instrumentation audit
- [x] Stage 4a - Grafana Alloy
- [x] Stage 4b - Prometheus
- [x] Stage 4c - Grafana Mimir
- [x] Stage 4d - Grafana Loki
- [x] Stage 4e - Grafana Tempo
- [x] Stage 4f - Grafana Pyroscope
- [x] Stage 4g - Grafana
- [ ] Stage 4h - Dashboards
- [ ] Stage 4i - Alerting
- [ ] Stage 4j - SLOs
- [ ] Stage 4k - Automation scripts

## Current Telemetry Flow

```text
Metrics:  Astronomy Shop -> Alloy -> Mimir -> Grafana
Infra:    Kubernetes -> Prometheus -> Mimir -> Grafana
Logs:     Astronomy Shop -> Alloy -> Loki -> Grafana
Traces:   Astronomy Shop -> Alloy -> Tempo -> Grafana
Profiles: Processes -> alloy-profiles -> Pyroscope -> Grafana
```

## Stage 4c - Grafana Mimir

Centralized metrics backend in the monitoring cluster.

```text
monitoring-cluster-worker:30909
```

## Stage 4d - Grafana Loki

Centralized log backend in the monitoring cluster.

```text
monitoring-cluster-worker:31080
```

## Stage 4e - Grafana Tempo

Centralized trace backend in the monitoring cluster.

```text
API:       monitoring-cluster-worker:32080
OTLP/HTTP: monitoring-cluster-worker:30418
```

## Stage 4f - Grafana Pyroscope

Centralized profiling backend in the monitoring cluster.

```text
monitoring-cluster-worker:30440
```

Validated:

```text
Pyroscope 2.2.0
eBPF tracer loaded
69 active profiling targets
0 failed profiling sessions
0 dropped pprof profiles
```

Deep profile-content validation is deferred for later.

## Stage 4g - Grafana

Grafana runs in the monitoring cluster as the unified exploration layer.

Helm chart:

```text
grafana-community/grafana 12.10.0
```

Validated Grafana app version:

```text
13.2.0
```

Provisioned data sources:

```text
Mimir       -> metrics
Loki        -> logs
Tempo       -> traces
Pyroscope   -> profiles
```

All four data sources passed Grafana health checks.

Validated through Grafana:

```text
Mimir       up{job="alloy"} = 1
Loki        real opentelemetry-demo logs
Tempo       real cart -> flagd traces
Pyroscope   datasource connectivity OK
```

## Repository Structure

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
│   └── grafana.md
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
│       └── values.yaml
└── service/
    └── otel-demo/
```

## Current Status

```text
Stage 1   Infrastructure       COMPLETE
Stage 2   Service              COMPLETE
Stage 3   Instrumentation      COMPLETE
Stage 4a  Grafana Alloy        COMPLETE
Stage 4b  Prometheus           COMPLETE
Stage 4c  Grafana Mimir        COMPLETE
Stage 4d  Grafana Loki         COMPLETE
Stage 4e  Grafana Tempo        COMPLETE
Stage 4f  Grafana Pyroscope    COMPLETE
Stage 4g  Grafana              COMPLETE
```

The lab now centralizes metrics, logs, traces, profiling infrastructure, and visualization across two Kubernetes clusters.

The next stage is **Stage 4h - Dashboards**, where RED and USE views will be built.
