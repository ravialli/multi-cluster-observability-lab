# Stage 4i: Alerting

## Overview

This stage adds Grafana-managed alert rules for the main application and Kubernetes signals in the lab.

The rules are stored in Git and provisioned into Grafana from a ConfigMap.

## Alert Rules

The lab currently has these alerts:

```text
High HTTP 5xx Error Rate
High HTTP p95 Latency
Pod Restart Detected
Deployment Has Unavailable Replicas
```

The rules cover a simple SRE mix of errors, latency, availability, and workload reliability.

## Thresholds

```text
HTTP 5xx rate
> 5% for 2 minutes

HTTP p95 latency
> 500 ms for 5 minutes

Pod restart
> 0 restarts in 10 minutes

Unavailable deployment replicas
> 0 for 2 minutes
```

The application alerts use `noDataState: OK` so an idle lab does not create a false incident.

## Provisioning

Alert rules are stored in:

```text
observability/grafana/alerting/alert-rules.yaml
```

They are loaded through:

```text
grafana-alert-rules
```

and mounted into Grafana under its alerting provisioning directory.

## Validation

Grafana successfully provisioned all rules and evaluated them with healthy rule status.

A pod restart alert was also observed firing and later returning to normal after the restart window cleared.

That gave us a simple end-to-end test of:

```text
Kubernetes metric
    ↓
Prometheus
    ↓
Mimir
    ↓
Grafana alert rule
    ↓
Firing
    ↓
Normal
```

CPU throttling was considered for alerting, but the metric did not return usable series during validation, so that alert was intentionally deferred instead of adding a rule we could not verify.

## Stage Status

```text
Stage 4i - Alerting: COMPLETE
```
