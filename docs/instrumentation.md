# Application Instrumentation

The workload cluster runs the OpenTelemetry Astronomy Shop as the sample
distributed application. The demo is already instrumented with OpenTelemetry
across multiple languages and services, so no application source-code changes
were required for this lab.

## Telemetry Signals

The application currently exports the following signals:

| Signal | Status |
|---|---|
| Traces | Enabled |
| Metrics | Enabled |
| Logs | Enabled |
| Profiles | Deferred to the Pyroscope stage |

Telemetry delivery was verified using the temporary OpenTelemetry Collector
debug exporter.

## OTLP Transport

Services use both supported OTLP transports.

Examples:

| Service | Endpoint | Protocol |
|---|---|---|
| cart | `otel-collector:4317` | OTLP/gRPC |
| payment | `otel-collector:4317` | OTLP/gRPC |
| checkout | `otel-collector:4318` | OTLP HTTP/protobuf |
| shipping | `otel-collector:4318` | OTLP HTTP/protobuf |
| load-generator | `otel-collector:4318` | OTLP HTTP/protobuf |

This provides a realistic mixed-protocol workload for validating the
observability pipeline.

## Resource Attributes

Application telemetry currently contains or derives the following identity
attributes:

- `service.name`
- `service.namespace`
- `service.version`
- `service.criticality`
- Kubernetes pod and namespace metadata

The following attributes will be added centrally in the telemetry pipeline
rather than duplicated across individual application configurations:

- `k8s.cluster.name`
- `deployment.environment.name`

For the workload cluster these will identify telemetry as:

```text
k8s.cluster.name = workload-cluster
deployment.environment.name = lab
