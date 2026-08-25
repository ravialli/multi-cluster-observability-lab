# Multi-Cluster Observability Lab

A hands-on Kubernetes lab for building centralized observability across multiple clusters.

The project uses separate **workload** and **monitoring** clusters to explore telemetry collection, enrichment, routing, centralized storage, visualization, alerting, profiling, and SLOs.

## Architecture

```text
workload-cluster

OpenTelemetry Astronomy Shop
          |
          v
     Grafana Alloy
      /    |    \
 metrics  logs  traces
   |       |      |
   v       v      v
 Mimir    Loki   Tempo
      monitoring-cluster

Application processes
          |
          | eBPF
          v
   alloy-profiles
          |
          v
      Pyroscope
  monitoring-cluster

Kubernetes / nodes / containers / Alloy
          |
          v
      Prometheus
          |
          | remote_write
          v
        Mimir
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
- [ ] Stage 4g - Grafana
- [ ] Stage 4h - Dashboards
- [ ] Stage 4i - Alerting
- [ ] Stage 4j - SLOs
- [ ] Stage 4k - Automation scripts

## Current Telemetry Flow

### Metrics
```text
Astronomy Shop -> Alloy -> Mimir
Kubernetes / nodes / containers -> Prometheus -> Mimir
```

### Logs
```text
Astronomy Shop -> Alloy -> Loki
                       -> Temporary OTel Collector
```

### Traces
```text
Astronomy Shop -> Alloy -> Tempo
                       -> Temporary OTel Collector
```

### Profiles
```text
Application processes -> alloy-profiles -> Pyroscope
```

## Stage 4c - Grafana Mimir

Mimir runs in the monitoring cluster as the centralized metrics backend.

```text
monitoring-cluster-worker:30909
```

Prometheus sends infrastructure metrics through remote write, while Alloy sends application metrics through OTLP/HTTP.

## Stage 4d - Grafana Loki

Loki runs in the monitoring cluster as the centralized log backend.

```text
monitoring-cluster-worker:31080
```

Alloy sends application logs through native OTLP/HTTP.

## Stage 4e - Grafana Tempo

Tempo runs in the monitoring cluster as the centralized trace backend.

```text
API:       monitoring-cluster-worker:32080
OTLP/HTTP: monitoring-cluster-worker:30418
```

TraceQL returned real distributed traces across Astronomy Shop services, and full trace retrieval preserved service, cluster, environment, version, criticality, RPC, and HTTP metadata.

## Stage 4f - Grafana Pyroscope

Pyroscope runs in the monitoring cluster as the centralized continuous-profiling backend.

Cross-cluster endpoint:

```text
monitoring-cluster-worker:30440
```

A dedicated profiling collector is used:

```text
alloy            -> metrics / logs / traces
alloy-profiles   -> eBPF profiling
```

Validated profiling infrastructure:

```text
Pyroscope 2.2.0                      PASS
Pyroscope readiness                  PASS
Cross-cluster connectivity           PASS
Dedicated Alloy profiler             PASS
Kernel 7.0.12-linuxkit               PASS
arm64                                PASS
eBPF tracer loaded                   PASS
Active profiling targets             69
Failed profiling sessions            0
Dropped pprof profiles               0
Profiler -> writer graph             PASS
```

The load generator was scaled to zero during the final validation window, so full stored-profile and flame-graph validation is deferred for a later revisit.

For the current project milestone:

```text
Stage 4f - Grafana Pyroscope    COMPLETE
Deep profile-content validation DEFERRED
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
│   └── pyroscope.md
├── infra/
│   └── kind/
├── observability/
│   ├── alloy/
│   ├── prometheus/
│   ├── mimir/
│   ├── loki/
│   ├── tempo/
│   └── pyroscope/
│       ├── pyroscope.yaml
│       └── alloy-profiles-values.yaml
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
```

The lab now has centralized **metrics, logs, traces, and profiling infrastructure** across two Kubernetes clusters.

The next stage is **Stage 4g - Grafana**, which will connect the observability backends into a single exploration and visualization interface.
