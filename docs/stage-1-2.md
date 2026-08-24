# Multi-Cluster Observability Lab

A local Kubernetes lab for building a centralized observability platform across multiple clusters.

## Current Status

- Stage 1: Infrastructure ✅
- Stage 2: Sample Service ✅
- Stage 3: Instrumentation audit ⏳
- Stage 4: Observability stack ⏳

## Architecture

```text
                     Local Docker Environment
                              |
                 +------------+------------+
                 |                         |
                 v                         v
       monitoring-cluster          workload-cluster
       ------------------          ----------------
       Control Plane               Control Plane
       Worker                      Worker
                                           |
                                           v
                                  OpenTelemetry Demo
                                  (Astronomy Shop)
                                           |
                                           | OTLP
                                      4317 / 4318
                                           |
                                           v
                                    otel-collector
                                    (temporary)
                                           |
                                           v
                                      debug exporter
```

The monitoring cluster is intentionally empty at this stage. Grafana Alloy, Mimir, Loki, Tempo, Pyroscope, Grafana, alerting, and SLO components will be added later.

---

# Stage 1 - Infrastructure

## Goal

Create two isolated local Kubernetes clusters using Terraform and Kind:

- `monitoring-cluster`
- `workload-cluster`

Each cluster contains:

- 1 control-plane node
- 1 worker node

Separate kubeconfig files are used so cluster boundaries remain explicit.

## Terraform Layout

Recommended layout:

```text
infra/
└── kind/
    ├── main.tf
    └── .terraform.lock.hcl
```

The Kind Terraform provider is used to provision both clusters.

Example kubeconfig locations:

```text
~/.kube/kind-config-monitoring
~/.kube/kind-config-workload
```

## Validation

Monitoring cluster:

```bash
kubectl --kubeconfig ~/.kube/kind-config-monitoring get nodes
```

Workload cluster:

```bash
kubectl --kubeconfig ~/.kube/kind-config-workload get nodes
```

Both clusters should report a Ready control-plane node and worker node.

---

# Stage 2 - Sample Service

## Goal

Deploy a realistic microservice application into the workload cluster without deploying the demo's bundled observability backends.

The sample workload is the OpenTelemetry Astronomy Shop.

## Namespace

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  create namespace otel-demo
```

## Application Helm Values

The Astronomy Shop is used only as the application workload.

The bundled observability components are disabled:

```yaml
grafana:
  enabled: false

prometheus:
  enabled: false

jaeger:
  enabled: false

opensearch:
  enabled: false

opentelemetry-collector:
  enabled: false
```

## Application Installation

```bash
helm upgrade --install otel-demo \
  open-telemetry/opentelemetry-demo \
  --version 0.41.0 \
  --namespace otel-demo \
  --kubeconfig ~/.kube/kind-config-workload \
  --values service/otel-demo/values.yaml
```

If a previous Helm configuration has collector overrides, reset the release values:

```bash
helm upgrade otel-demo \
  open-telemetry/opentelemetry-demo \
  --version 0.41.0 \
  --namespace otel-demo \
  --kubeconfig ~/.kube/kind-config-workload \
  --reset-values \
  --values service/otel-demo/values.yaml
```

## Temporary Standalone Collector

A standalone OpenTelemetry Collector is installed separately from the demo chart.

Its purpose at this stage is only to verify that instrumented services can successfully export telemetry.

The collector is deployed as a Kubernetes Deployment and listens for OTLP traffic on:

- `4317` - OTLP/gRPC
- `4318` - OTLP/HTTP

Example `collector-values.yaml`:

```yaml
mode: deployment

fullnameOverride: otel-collector

image:
  repository: otel/opentelemetry-collector-contrib

command:
  name: otelcol-contrib

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 256Mi

service:
  enabled: true

ports:
  otlp:
    enabled: true

  otlp-http:
    enabled: true

config:
  exporters:
    debug:
      verbosity: basic
```

Install:

```bash
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --version 0.165.0 \
  --namespace otel-demo \
  --kubeconfig ~/.kube/kind-config-workload \
  --values service/otel-demo/collector-values.yaml
```

## Why a Standalone Collector?

The Astronomy Shop chart normally includes its own collector configuration and bundled backends.

For this project those components are intentionally separated.

Current path:

```text
Astronomy Shop -> OTLP -> standalone OTel Collector -> debug exporter
```

Future path:

```text
Astronomy Shop -> Alloy -> Mimir
                         -> Loki
                         -> Tempo
                         -> Pyroscope
```

This keeps the demo application independent from the observability platform being built.

## Validation

Check the sample workload:

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  -n otel-demo \
  get pods
```

Check collector:

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  -n otel-demo \
  get pods,svc | grep otel-collector
```

Check collector endpoint:

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  -n otel-demo \
  get endpoints otel-collector
```

Check collector errors:

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  -n otel-demo \
  logs deployment/otel-collector \
  --since=1m | grep -Ei "Exporting failed|error"
```

Check an instrumented service:

```bash
kubectl \
  --kubeconfig ~/.kube/kind-config-workload \
  -n otel-demo \
  logs deployment/shipping \
  --since=1m | grep -Ei "ExportError|network error"
```

A healthy environment should have no current telemetry export errors.

---

# Repository Structure

At the end of Stage 2, the repository looks like:

```text
multi-cluster-observability-lab/
├── README.md
├── .gitignore
├── docs/
│   └── stages-1-2.md
├── infra/
│   └── kind/
│       ├── main.tf
│       └── .terraform.lock.hcl
└── service/
    └── otel-demo/
        ├── values.yaml
        └── collector-values.yaml
```

