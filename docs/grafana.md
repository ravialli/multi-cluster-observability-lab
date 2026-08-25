# Stage 4g: Grafana

## Overview

This stage adds **Grafana** as the unified visualization and exploration layer for the centralized observability stack.

Grafana runs in the monitoring cluster and connects to:

```text
Mimir       -> metrics
Loki        -> logs
Tempo       -> traces
Pyroscope   -> profiles
```

All four data sources are provisioned as code through the Grafana Helm values file.

## Architecture

```text
monitoring-cluster

                 Grafana
               /   |   |   \
              v    v   v    v
            Mimir Loki Tempo Pyroscope
```

## Deployment

Grafana is installed from:

```text
grafana-community/grafana
chart version: 12.10.0
```

Validated Grafana application version:

```text
13.2.0
```

The chart version and application version are separate.

Primary configuration:

```text
observability/grafana/values.yaml
```

## Provisioned Data Sources

### Mimir

```yaml
name: Mimir
uid: mimir
type: prometheus
url: http://mimir.observability.svc.cluster.local:9009/prometheus
isDefault: true
```

### Loki

```yaml
name: Loki
uid: loki
type: loki
url: http://loki.observability.svc.cluster.local:3100
```

### Tempo

```yaml
name: Tempo
uid: tempo
type: tempo
url: http://tempo.observability.svc.cluster.local:3200
```

### Pyroscope

```yaml
name: Pyroscope
uid: pyroscope
type: grafana-pyroscope-datasource
url: http://pyroscope.observability.svc.cluster.local:4040
```

Because Grafana and the backends run in the same monitoring cluster, Kubernetes service DNS is used.

## Runtime Validation

Grafana pod:

```text
1/1 Running
```

Grafana service:

```text
ClusterIP
port 80
```

Port-forward:

```bash
kubectl --kubeconfig $KM   -n observability   port-forward svc/grafana 3000:80
```

## API Health

```bash
curl -s http://localhost:3000/api/health | jq
```

Validated:

```json
{
  "database": "ok",
  "version": "13.2.0"
}
```

## Data Source Health

All four sources passed Grafana's health API:

```text
Mimir       OK
Loki        OK
Tempo       OK
Pyroscope   OK
```

Validated messages:

```text
Mimir       Successfully queried the Prometheus API.
Loki        Data source successfully connected.
Tempo       Data source is working.
Pyroscope   Data source is working.
```

## Grafana -> Mimir

Grafana successfully queried:

```promql
up{job="alloy"}
```

Validated:

```text
value=1
cluster="workload-cluster"
environment="lab"
component="telemetry-gateway"
```

## Grafana -> Loki

Grafana successfully queried:

```logql
{service_namespace="opentelemetry-demo"}
```

Returned real logs with:

```text
service_name="kafka"
service_namespace="opentelemetry-demo"
k8s_cluster_name="workload-cluster"
deployment_environment_name="lab"
```

## Grafana -> Tempo

Grafana successfully proxied TraceQL searches using:

```text
service.namespace = opentelemetry-demo
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
```

Tempo returned real distributed traces including:

```text
cart -> flagd
```

## Grafana -> Pyroscope

The Pyroscope datasource health check returned:

```text
status=OK
message="Data source is working"
```

Deep profile-content validation remains deferred from Stage 4f, but Grafana-to-Pyroscope connectivity is confirmed.

## Stage 4g Validation Results

```text
Grafana deployment                    PASS
Grafana API health                    PASS
Grafana 13.2.0                        PASS
Provisioning as code                  PASS

Mimir datasource                      PASS
Loki datasource                       PASS
Tempo datasource                      PASS
Pyroscope datasource                  PASS

Grafana -> Mimir                      PASS
Grafana -> Loki                       PASS
Grafana -> Tempo                      PASS
Grafana -> Pyroscope                  PASS
```

## Next Stage

```text
Stage 4h - Dashboards
```

The next stage will build RED and USE views on top of the centralized telemetry.

**Stage 4g status: Complete.**
