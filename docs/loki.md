# Stage 4d: Grafana Loki

## Overview

This stage introduces **Grafana Loki** as the centralized log backend in the monitoring cluster.

Application logs originate from the OpenTelemetry Astronomy Shop workload in the workload cluster. Grafana Alloy receives those logs over OTLP, enriches them with cluster and environment identity, and exports them to Loki over OTLP/HTTP.

The temporary OpenTelemetry Collector remains connected as a validation sink while Loki becomes the centralized log store.

## Architecture

```text
workload-cluster

Astronomy Shop
      |
      | OTLP logs
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
Grafana Loki
monitoring-cluster
```

## Deployment Model

Loki runs as a single monolithic instance in the monitoring cluster.

```text
Loki version: 3.7.6
HTTP port:    3100
NodePort:     31080
Storage:      filesystem
Schema:       TSDB v13
Retention:    24h
```

Filesystem storage and `emptyDir` are intentional for this local Kind lab.

## Directory

```text
observability/loki/
```

Primary manifest:

```text
observability/loki/loki.yaml
```

## Loki Configuration

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: info

distributor:
  otlp_config:
    default_resource_attributes_as_index_labels:
      - service.name
      - service.namespace
      - deployment.environment.name
      - k8s.cluster.name

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki

  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules

  replication_factor: 1

  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 50

limits_config:
  allow_structured_metadata: true
  volume_enabled: true
  retention_period: 24h

schema_config:
  configs:
    - from: "2024-04-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

compactor:
  working_directory: /tmp/loki/retention
  delete_request_store: filesystem
  retention_enabled: true
```

## Indexed Label Strategy

Only stable identity attributes are indexed:

```text
service.name
service.namespace
deployment.environment.name
k8s.cluster.name
```

They appear in Loki as:

```text
service_name
service_namespace
deployment_environment_name
k8s_cluster_name
```

Higher-cardinality attributes such as `service.instance.id`, `container.id`, `process.pid`, `host.name`, `service.version`, and `service.criticality` remain available as structured metadata.

## Deploy Loki

```bash
KM=~/.kube/kind-config-monitoring

kubectl --kubeconfig $KM   apply -f observability/loki/loki.yaml

kubectl --kubeconfig $KM   -n observability   rollout status deployment/loki
```

## Validate Loki

```bash
kubectl --kubeconfig $KM   -n observability   get pods,svc
```

Validated state:

```text
loki   1/1 Running
mimir  1/1 Running
```

Loki service:

```text
3100:31080/TCP
```

## Readiness

```bash
kubectl --kubeconfig $KM   -n observability   port-forward svc/loki 3100:3100
```

```bash
curl -s http://localhost:3100/ready
```

Validated result:

```text
ready
```

## Cross-Cluster Connectivity

The workload cluster reaches Loki over the shared Docker `kind` network:

```text
http://monitoring-cluster-worker:31080
```

Validation:

```bash
KW=~/.kube/kind-config-workload

kubectl --kubeconfig $KW   -n observability   run loki-network-test   --rm -i   --restart=Never   --image=curlimages/curl:8.12.1   --   curl -fsS http://monitoring-cluster-worker:31080/ready
```

Result:

```text
ready
```

## Alloy -> Loki

Alloy exports application logs with OTLP/HTTP:

```river
otelcol.exporter.otlphttp "loki_logs" {
  client {
    endpoint = "http://monitoring-cluster-worker:31080/otlp"
  }
}
```

The effective log endpoint is:

```text
http://monitoring-cluster-worker:31080/otlp/v1/logs
```

Logs continue to be duplicated to the temporary OpenTelemetry Collector for validation.

## Validate Log Export

```bash
curl -s localhost:12345/metrics |
grep 'otelcol_exporter_sent_log_records_total' |
grep 'loki_logs'
```

Observed progression:

```text
48 -> 424+
```

Failed export check:

```bash
curl -s localhost:12345/metrics |
grep 'otelcol_exporter_send_failed_log_records_total' |
grep 'loki_logs'
```

Final validation returned no output.

## Validate Loki Labels

```bash
curl -s http://localhost:3100/loki/api/v1/labels
```

Validated labels:

```text
deployment_environment_name
k8s_cluster_name
service_name
service_namespace
```

Validated values:

```text
service_namespace="opentelemetry-demo"
k8s_cluster_name="workload-cluster"
deployment_environment_name="lab"
```

## Validate Application Logs

```bash
curl -sG   http://localhost:3100/loki/api/v1/query_range   --data-urlencode   'query={service_namespace="opentelemetry-demo"}'   --data-urlencode 'limit=10'
```

Validated result:

```text
status=success
resultType=streams
```

Real Astronomy Shop logs were returned, including Kafka and checkout records.

## LogQL Validation

```bash
curl -sG   http://localhost:3100/loki/api/v1/query   --data-urlencode   'query=sum by (service_name) (count_over_time({service_namespace="opentelemetry-demo"}[1m]))'
```

Example observed result:

```text
service_name="kafka" -> 46 logs
```

Values vary with current workload activity.

## Structured Metadata

Additional OpenTelemetry attributes remain available without becoming index labels, including:

```text
service_criticality
service_version
severity_text
severity_number
telemetry_sdk_language
telemetry_sdk_name
telemetry_sdk_version
process_pid
process_runtime_name
process_runtime_version
host_name
container_id
```

## Startup Ring Message

After restarting Loki to apply the lower-cardinality label configuration, one transient message appeared:

```text
error getting ingester clients
err="empty ring"
```

Follow-up checks showed:

```text
Loki readiness        ready
LogQL queries         successful
Alloy log exports     increasing
Recent Loki errors    none
```

The message was classified as a startup transient.

## Stage 4d Validation Results

```text
Loki deployment                         PASS
Loki readiness                          PASS
Monitoring-cluster placement            PASS
NodePort 31080                          PASS
Cross-cluster connectivity              PASS

Alloy OTLP/HTTP log export              PASS
Continuous log export                   PASS
Failed log exports                      NONE

Application logs stored                 PASS
service_name                            PASS
service_namespace                       PASS
k8s_cluster_name                        PASS
deployment_environment_name             PASS
High-cardinality label cleanup          PASS
Structured metadata preserved           PASS
LogQL queries                           PASS
Persistent Loki errors                  NONE
```

## Current Logging Architecture

```text
workload-cluster

Astronomy Shop
      |
      | OTLP logs
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
Grafana Loki
monitoring-cluster
```

## What Is Intentionally Deferred

```text
Tempo
Pyroscope
Grafana dashboards
Alerting
SLOs
Persistent production-grade object storage
High-availability Loki deployment
```

**Stage 4d status: Complete.**
