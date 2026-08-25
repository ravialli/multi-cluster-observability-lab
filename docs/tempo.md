# Stage 4e: Grafana Tempo

## Overview

This stage introduces **Grafana Tempo** as the centralized trace backend running in the monitoring cluster.

Application traces originate from the OpenTelemetry Astronomy Shop workload in the workload cluster. Grafana Alloy receives those traces over OTLP, enriches them with workload identity, and exports them to Tempo over OTLP/HTTP.

The temporary OpenTelemetry Collector remains connected as a validation sink while Tempo becomes the centralized trace store.

## Architecture

```text
workload-cluster

Astronomy Shop
      |
      | OTLP traces
      v
Grafana Alloy
      |
      +------> Temporary OTel Collector
      |
      | OTLP/HTTP
      v
================ cluster boundary ================
      |
      v
Grafana Tempo
monitoring-cluster
```

## Deployment Model

Tempo runs as a single monolithic instance in the monitoring cluster.

```text
Tempo version: 3.0.2
HTTP API:      3200
OTLP/gRPC:     4317
OTLP/HTTP:     4318
API NodePort:  32080
OTLP/gRPC NP:  30417
OTLP/HTTP NP:  30418
Storage:       local filesystem
```

Local filesystem storage and `emptyDir` are intentional for this Kind lab.

## Directory

```text
observability/tempo/
```

Primary manifest:

```text
observability/tempo/tempo.yaml
```

## Tempo Configuration

```yaml
stream_over_http_enabled: true

server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"

        http:
          endpoint: "0.0.0.0:4318"

storage:
  trace:
    backend: local

    wal:
      path: /tmp/tempo/wal

    local:
      path: /tmp/tempo/blocks

usage_report:
  reporting_enabled: false
```

Tempo is started with:

```text
-target=all
```

which keeps all required Tempo components inside one process for the local lab.

## Deploy Tempo

```bash
KM=~/.kube/kind-config-monitoring

kubectl --kubeconfig $KM   apply -f observability/tempo/tempo.yaml

kubectl --kubeconfig $KM   -n observability   rollout status deployment/tempo
```

## Validate Tempo

Check centralized observability pods and services:

```bash
kubectl --kubeconfig $KM   -n observability   get pods,svc
```

Validated state:

```text
loki   1/1 Running
mimir  1/1 Running
tempo  1/1 Running
```

Tempo service:

```text
3200:32080/TCP
4318:30418/TCP
4317:30417/TCP
```

## Readiness and Build Information

Port-forward the Tempo API:

```bash
kubectl --kubeconfig $KM   -n observability   port-forward svc/tempo 3200:3200
```

Readiness:

```bash
curl -s http://localhost:3200/ready
```

Validated result:

```text
ready
```

Build information:

```bash
curl -s http://localhost:3200/api/status/buildinfo
```

Validated version:

```text
v3.0.2
```

## Cross-Cluster Connectivity

The workload cluster reaches Tempo over the shared Docker `kind` network.

Validated API endpoint:

```text
http://monitoring-cluster-worker:32080
```

Connectivity test:

```bash
KW=~/.kube/kind-config-workload

kubectl --kubeconfig $KW   -n observability   run tempo-network-test   --rm -i   --restart=Never   --image=curlimages/curl:8.12.1   --   curl -fsS http://monitoring-cluster-worker:32080/ready
```

Validated result:

```text
ready
```

The trace-ingestion endpoint is exposed through:

```text
monitoring-cluster-worker:30418
```

for OTLP/HTTP traffic.

## Alloy -> Tempo

Alloy exports application traces using OTLP/HTTP.

Relevant Alloy exporter:

```river
otelcol.exporter.otlphttp "tempo_traces" {
  client {
    endpoint = "http://monitoring-cluster-worker:30418"
  }
}
```

The effective trace endpoint is:

```text
http://monitoring-cluster-worker:30418/v1/traces
```

The Alloy batch processor sends traces to both:

```text
Temporary OpenTelemetry Collector
Grafana Tempo
```

Metrics continue to flow to Mimir and logs continue to flow to Loki.

## Validate Trace Export

Alloy self-metrics confirm the Tempo exporter is part of the active component graph:

```text
otelcol.processor.batch.default
        |
        v
otelcol.exporter.otlphttp.tempo_traces
```

HTTP client metrics showed successful POST requests to:

```text
server_address="monitoring-cluster-worker"
server_port="30418"
http_response_status_code="200"
```

The Tempo exporter sent-span metric reached:

```text
otelcol_exporter_sent_spans_total = 43
```

with:

```text
url_path="/v1/traces"
```

The exporter queue size was:

```text
0
```

indicating no queued trace backlog at validation time.

## TraceQL Search

Tempo successfully returned traces using resource attributes added earlier in the telemetry pipeline.

Example TraceQL:

```bash
curl -sG   http://localhost:3200/api/search   --data-urlencode   'q={ resource.service.namespace = "opentelemetry-demo" && resource.k8s.cluster.name = "workload-cluster" && resource.deployment.environment.name = "lab" }'
```

This returned a real distributed trace with:

```text
rootServiceName = cart
rootTraceName   = flagd.evaluation.v2.Service/ResolveBoolean
```

The trace included spans from both:

```text
cart
flagd
```

## Resource Attribute Validation

The retrieved trace preserved Alloy-enriched and application-provided resource metadata.

Validated examples:

```text
deployment.environment.name = lab
service.namespace            = opentelemetry-demo
service.name                 = flagd
k8s.cluster.name             = workload-cluster
service.version              = 3.0.0
service.criticality          = low
```

The cart resource also included:

```text
deployment.environment.name = lab
service.namespace            = opentelemetry-demo
service.name                 = cart
k8s.cluster.name             = workload-cluster
service.version              = 3.0.0
service.criticality          = high
```

This proves the enrichment added in Alloy survives into centralized trace storage.

## Full Trace Retrieval

A trace found with TraceQL was retrieved using:

```bash
curl -s   "http://localhost:3200/api/v2/traces/a306810fa064ebf34a68b2660ebc0fdb"
```

The response contained non-empty:

```text
resourceSpans
scopeSpans
spans
```

The trace preserved distributed parent-child relationships across the cart and flagd services.

Observed span information included:

```text
SPAN_KIND_CLIENT
SPAN_KIND_SERVER
rpc.system=grpc
rpc.service=flagd.evaluation.v2.Service
rpc.method=ResolveBoolean
rpc.grpc.status_code=0
http.response.status_code=200
```

This confirms Tempo stores and returns the actual distributed trace rather than only trace metadata.

## Tempo Scheduler Log Noise

Tempo 3.0.2 emitted recurring messages similar to:

```text
error calling scheduler
rpc error: code = NotFound desc = no jobs found
```

during low-volume operation.

The trace pipeline remained healthy at the same time:

```text
Tempo readiness          ready
TraceQL search           successful
Full trace retrieval     successful
OTLP HTTP responses      200
Exporter queue           0
```

The message was therefore treated as idle scheduler log noise in this local monolithic deployment rather than an ingestion failure.

## Stage 4e Validation Results

```text
Tempo deployment                         PASS
Tempo v3.0.2                             PASS
Tempo readiness                          PASS
Monitoring-cluster placement             PASS
Cross-cluster connectivity               PASS

Alloy OTLP/HTTP trace export             PASS
Successful HTTP POST responses           PASS
Successful spans                         PASS
Exporter queue                            0

Application traces stored                PASS
TraceQL search                           PASS
Full trace retrieval                     PASS
Multi-service distributed trace          PASS
service.name                             PASS
service.namespace                        PASS
k8s.cluster.name                         PASS
deployment.environment.name              PASS
service.version                          PASS
service.criticality                      PASS

Persistent ingestion failures            NONE
```

## Current Trace Architecture

```text
workload-cluster

Astronomy Shop
      |
      | OTLP traces
      v
Grafana Alloy
      |
      +------> Temporary OTel Collector
      |
      | OTLP/HTTP
      v
================ cluster boundary ================
      |
      v
Grafana Tempo
monitoring-cluster
```

## What Is Intentionally Deferred

```text
Pyroscope
Grafana dashboards
Alerting
SLOs
Persistent production-grade object storage
High-availability Tempo deployment
```

**Stage 4e status: Complete.**
