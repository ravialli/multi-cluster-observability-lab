# Grafana Alloy Operations Guide

## Purpose

Grafana Alloy is the telemetry gateway for the workload cluster in this lab. It receives OpenTelemetry data from the OpenTelemetry Astronomy Shop, enriches telemetry with cluster and environment identity, batches the data, and forwards it to the temporary OpenTelemetry Collector while the permanent observability backends are introduced.

This document covers Alloy deployment, configuration, validation, operational checks, troubleshooting, and rollback for the `workload-cluster`.

---

## Current Architecture

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
debug exporter
```

Alloy currently runs in the workload cluster. The temporary OpenTelemetry Collector remains in place only as a validation sink until Mimir, Loki, Tempo, and the remaining observability components are introduced.

---

## Cluster and Namespace

| Item | Value |
|---|---|
| Kubernetes cluster | `workload-cluster` |
| Alloy namespace | `observability` |
| Alloy release | `alloy` |
| Alloy workload type | Deployment |
| Alloy replicas | 1 |
| OTLP/gRPC port | `4317` |
| OTLP/HTTP port | `4318` |
| Alloy HTTP/metrics port | `12345` |
| Temporary collector namespace | `otel-demo` |
| Temporary collector service | `otel-collector` |

Workload kubeconfig:

```bash
K=~/.kube/kind-config-workload
```

---

## Repository Files

```text
observability/
└── alloy/
    └── values.yaml

service/
└── otel-demo/
    ├── values.yaml
    └── collector-values.yaml
```

`observability/alloy/values.yaml` contains the Alloy deployment and pipeline configuration.

`service/otel-demo/values.yaml` points Astronomy Shop services to Alloy.

`service/otel-demo/collector-values.yaml` controls the temporary OpenTelemetry Collector used for validation.

---

## Alloy Pipeline

The active telemetry path is:

```text
otelcol.receiver.otlp "applications"
        |
        v
otelcol.processor.transform "enrich"
        |
        v
otelcol.processor.batch "default"
        |
        v
otelcol.exporter.otlphttp "temporary"
```

### OTLP receiver

Alloy accepts both OTLP transports:

```text
OTLP/gRPC      :4317
OTLP/HTTP      :4318
```

This is required because Astronomy Shop services use a mix of gRPC and HTTP/protobuf exporters.

### Resource enrichment

Alloy adds the following resource attributes:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

If `service.namespace` is missing, Alloy adds:

```text
service.namespace = opentelemetry-demo
```

Application-provided attributes such as the following remain intact:

```text
service.name
service.namespace
service.version
service.criticality
```

### Batching

All telemetry passes through the batch processor before export.

Signals handled:

```text
logs
metrics
traces
```

Profiles are intentionally not handled in this stage. Profiling will be introduced with Pyroscope.

### Temporary exporter

Until the permanent observability backends are introduced, Alloy forwards OTLP/HTTP telemetry to:

```text
http://otel-collector.otel-demo.svc.cluster.local:4318
```

---

## Install or Upgrade Alloy

Add the Grafana Helm repository if it is not already configured:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Create the namespace if required:

```bash
kubectl --kubeconfig $K create namespace observability
```

Install or upgrade Alloy:

```bash
helm upgrade --install alloy \
  grafana/alloy \
  --version 1.11.0 \
  --namespace observability \
  --kubeconfig $K \
  --values observability/alloy/values.yaml
```

---

## Application Routing

Astronomy Shop uses:

```text
OTEL_COLLECTOR_NAME=alloy.observability.svc.cluster.local
```

Existing service-specific OTLP ports and protocols remain unchanged.

Examples:

```text
cart
  -> alloy.observability.svc.cluster.local:4317

shipping
  -> alloy.observability.svc.cluster.local:4318
  -> http/protobuf

payment
  -> alloy.observability.svc.cluster.local:4317
  -> grpc
```

Do not modify application source code to route telemetry.

---

## Validate Alloy

### 1. Pod health

```bash
kubectl --kubeconfig $K \
  -n observability \
  get pods
```

Expected:

```text
alloy-xxxxxxxxxx-xxxxx   1/1   Running
```

### 2. Service ports

```bash
kubectl --kubeconfig $K \
  -n observability \
  get svc alloy
```

Confirm Alloy exposes:

```text
4317/TCP
4318/TCP
12345/TCP
```

### 3. Check Alloy logs

```bash
kubectl --kubeconfig $K \
  -n observability \
  logs deployment/alloy \
  --since=10m |
grep -Ei 'error|failed|transform|ottl'
```

No output is expected during normal operation.

---

## Validate Incoming Telemetry

Port-forward Alloy:

```bash
kubectl --kubeconfig $K \
  -n observability \
  port-forward svc/alloy 12345:12345
```

Check receiver counters:

```bash
curl -s localhost:12345/metrics |
grep -E 'otelcol_receiver_accepted_(spans|metric_points|log_records)_total'
```

Validated Stage 4a results showed successful ingestion for all three signals over both transports:

```text
Logs     -> gRPC and HTTP
Metrics  -> gRPC and HTTP
Traces   -> gRPC and HTTP
```

Example validated span counts:

```text
gRPC spans: 8969
HTTP spans: 2827
```

These values are counters and should continue increasing while traffic is flowing.

---

## Validate Outbound Telemetry

Check exporter counters:

```bash
curl -s localhost:12345/metrics |
grep -E 'otelcol_exporter_(sent|send_failed)_(spans|metric_points|log_records)_total'
```

Validated Stage 4a results included:

```text
sent_log_records_total     5453
sent_metric_points_total   64771
sent_spans_total           14856
```

No `send_failed_*` counters were observed during validation.

The exact totals will change over time. The important operational checks are:

```text
sent_* counters increase
send_failed_* remains zero or absent
```

---

## Validate Downstream Delivery

Check the temporary OpenTelemetry Collector:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  logs deployment/otel-collector \
  --since=1m |
grep -E 'Traces|Metrics|Logs'
```

Expected:

```text
Traces
Metrics
Logs
```

This confirms:

```text
Application -> Alloy -> temporary collector
```

---

## Validate Resource Enrichment

For deep inspection, temporarily set the temporary collector debug exporter to:

```yaml
config:
  exporters:
    debug:
      verbosity: detailed
```

Upgrade the collector:

```bash
helm upgrade otel-collector \
  open-telemetry/opentelemetry-collector \
  --version 0.165.0 \
  --namespace otel-demo \
  --kubeconfig $K \
  --values service/otel-demo/collector-values.yaml
```

Wait for rollout:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  rollout status deployment/otel-collector
```

Search for enriched attributes:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  logs deployment/otel-collector \
  --since=2m |
grep -m 10 -E 'k8s.cluster.name|deployment.environment.name'
```

Validated output:

```text
k8s.cluster.name: Str(workload-cluster)
deployment.environment.name: Str(lab)
```

After validation, restore:

```yaml
verbosity: basic
```

Detailed debug logging should not remain enabled during normal operation because it produces very large log volumes.

---

## Application Export Error Check

Check a service that exports using OTLP/HTTP:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  logs deployment/shipping \
  --since=1m |
grep -Ei 'ExportError|network error'
```

Expected:

```text
no output
```

If export errors appear, validate Alloy DNS, ports, pod health, and receiver counters.

---

## Common Troubleshooting

### Alloy pod is not running

```bash
kubectl --kubeconfig $K \
  -n observability \
  describe pod -l app.kubernetes.io/name=alloy
```

Then inspect logs:

```bash
kubectl --kubeconfig $K \
  -n observability \
  logs deployment/alloy
```

Look for configuration parsing, River syntax, port binding, OTTL, or connectivity errors.

### Receiver counters remain at zero

Check whether Astronomy Shop still points to Alloy:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  get deployment shipping \
  -o jsonpath='{range .spec.template.spec.containers[0].env[?(@.name=="OTEL_COLLECTOR_NAME")]}{.value}{"\n"}{end}'
```

Expected:

```text
alloy.observability.svc.cluster.local
```

Confirm the Alloy service:

```bash
kubectl --kubeconfig $K \
  -n observability \
  get svc alloy
```

### gRPC works but HTTP does not

Check that port `4318` is exposed and that the application is configured for:

```text
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

### HTTP works but gRPC does not

Check that port `4317` is exposed.

A known gRPC example is the payment service:

```text
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

### Alloy receives data but the temporary collector does not

Check exporter counters:

```bash
curl -s localhost:12345/metrics |
grep -E 'otelcol_exporter_(sent|send_failed)_'
```

Then confirm the temporary collector service exists:

```bash
kubectl --kubeconfig $K \
  -n otel-demo \
  get svc otel-collector
```

### Transform configuration is present but attributes are not visible

The temporary collector normally uses:

```text
debug verbosity = basic
```

Basic debug output shows telemetry counts but not detailed resource attributes.

Temporarily switch to:

```text
verbosity = detailed
```

to verify resource enrichment, then return to `basic`.

### Alloy reports OTTL errors

Run:

```bash
kubectl --kubeconfig $K \
  -n observability \
  logs deployment/alloy \
  --since=10m |
grep -Ei 'transform|ottl|error|failed'
```

Do not ignore repeated transformation errors even when the processor is configured with:

```text
error_mode = ignore
```

The setting prevents individual malformed telemetry records from stopping the pipeline, but persistent errors still indicate a configuration issue.

---

## Rollout Status

```bash
kubectl --kubeconfig $K \
  -n observability \
  rollout status deployment/alloy
```

---

## Restart Alloy

Use a Kubernetes rollout restart:

```bash
kubectl --kubeconfig $K \
  -n observability \
  rollout restart deployment/alloy
```

Then:

```bash
kubectl --kubeconfig $K \
  -n observability \
  rollout status deployment/alloy
```

Avoid deleting the Helm release merely to restart Alloy.

---

## Roll Back an Alloy Helm Change

Review release history:

```bash
helm history alloy \
  --namespace observability \
  --kubeconfig $K
```

Roll back to a known-good revision:

```bash
helm rollback alloy <REVISION> \
  --namespace observability \
  --kubeconfig $K
```

Validate the pod and telemetry counters again after rollback.

---

## Health Checklist

Use this compact checklist after any Alloy configuration change:

```text
[ ] Alloy pod is Running
[ ] Alloy service exposes 4317 and 4318
[ ] Alloy logs contain no repeated errors
[ ] accepted_spans_total increases
[ ] accepted_metric_points_total increases
[ ] accepted_log_records_total increases
[ ] sent_spans_total increases
[ ] sent_metric_points_total increases
[ ] sent_log_records_total increases
[ ] send_failed counters are zero or absent
[ ] temporary collector receives traces
[ ] temporary collector receives metrics
[ ] temporary collector receives logs
[ ] shipping shows no OTLP export errors
[ ] k8s.cluster.name = workload-cluster
[ ] deployment.environment.name = lab
```

---

## Stage 4a Validation Result

Stage 4a is validated successfully.

Confirmed:

```text
Alloy deployment                 PASS
OTLP/gRPC ingestion              PASS
OTLP/HTTP ingestion              PASS
Logs ingestion                   PASS
Metrics ingestion                PASS
Traces ingestion                 PASS
Resource transformation          PASS
Cluster enrichment               PASS
Environment enrichment           PASS
Downstream OTLP export           PASS
Observed exporter failures       NONE
Shipping export errors           NONE
```

Alloy should remain unchanged while the next observability components are introduced unless a real integration requirement requires a configuration update.

