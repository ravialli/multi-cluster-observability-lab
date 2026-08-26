# Stage 4j: SLOs

## Overview

This stage adds simple service-level objectives for the Astronomy Shop HTTP metrics.

The current SLO coverage applies to the `cart` and `shipping` services because those are the services exposing the validated HTTP server metric family used by this lab.

## SLO Targets

### Availability

```text
Target: 99%
Good event: request does not return HTTP 5xx
```

### Latency

```text
Target: 95%
Good event: request completes within 500 ms
```

The lab uses a short 5-minute evaluation window. This keeps the project practical on a local Kind environment and is not meant to represent a production 30-day SLO window.

## SLO Dashboard

Grafana includes the dashboard:

```text
Service SLO - Astronomy Shop
```

Dashboard UID:

```text
service-slo
```

It contains:

```text
Availability SLI
Latency SLI
Availability Burn Rate
Latency Burn Rate
Availability Budget Remaining
Latency Budget Remaining
Request Rate by Service
Availability Burn Rate Over Time
```

Dashboard file:

```text
observability/grafana/dashboards/service-slo.json
```

## Burn-Rate Alerts

Two SLO alerts were added:

```text
Availability Error Budget Burning Fast
Latency Error Budget Burning Fast
```

Both alert when the short-window burn rate is above `2x` for 2 minutes.

The rules are part of:

```text
observability/grafana/alerting/alert-rules.yaml
```

## Validation

With the load generator running, the validated values were:

```text
Availability SLI        100%
Latency SLI             100%
Availability burn rate  0
Latency burn rate       0
```

Grafana also showed both burn-rate alert rules as:

```text
state: inactive
health: ok
```

This is the expected healthy state.

## Stage Status

```text
Stage 4j - SLOs: COMPLETE
```
