# Stage 4f: Grafana Pyroscope

## Overview

This stage adds **Grafana Pyroscope** as the centralized continuous-profiling backend in the monitoring cluster.

A dedicated Grafana Alloy profiling collector runs in the workload cluster as a DaemonSet. It uses eBPF for process-level CPU profiling and is configured to forward profiles to Pyroscope across the Kind cluster boundary.

For the current project milestone, Stage 4f is marked **complete**. Backend deployment, cross-cluster connectivity, dedicated profiler deployment, kernel compatibility, eBPF loading, target discovery, and collector health were validated. Full stored-profile and flame-graph validation is intentionally deferred for a later revisit.

## Architecture

```text
workload-cluster

Application processes
      |
      | eBPF CPU sampling
      v
alloy-profiles
Dedicated Alloy DaemonSet
      |
      | Pyroscope write
      v
================ cluster boundary ================
      |
      v
Grafana Pyroscope
monitoring-cluster
```

The existing telemetry gateway remains separate:

```text
alloy            -> metrics / logs / traces
alloy-profiles   -> continuous profiling
```

## Deployment

```text
Pyroscope version: 2.2.0
HTTP port:        4040
NodePort:         30440
Storage:          filesystem
Architecture:     v2
Mode:             target=all
```

Files:

```text
observability/pyroscope/pyroscope.yaml
observability/pyroscope/alloy-profiles-values.yaml
```

## Backend Validation

Validated monitoring-cluster state:

```text
mimir       1/1 Running
loki        1/1 Running
tempo       1/1 Running
pyroscope   1/1 Running
```

Readiness:

```bash
curl -s http://localhost:4040/ready
```

Result:

```text
ready
```

Build metric:

```bash
curl -s http://localhost:4040/metrics |
grep '^pyroscope_build_info'
```

Validated version:

```text
version="2.2.0"
```

## Cross-Cluster Connectivity

The workload cluster successfully reached:

```text
http://monitoring-cluster-worker:30440/ready
```

Result:

```text
ready
```

## Dedicated Profiling Collector

A separate Alloy release is used for profiling:

```text
release: alloy-profiles
mode:    DaemonSet
```

The profiler uses:

```text
hostPID: true
privileged: true
```

This keeps the main telemetry gateway non-privileged.

## Kernel and eBPF Validation

Validated workload nodes:

```text
kernel: 7.0.12-linuxkit
arch:   arm64
```

The profiler reported:

```text
Supports generic eBPF map batch operations
Supports generic eBPF map batch lookup-and-delete
Supports LPM trie eBPF map batch operations
eBPF tracer loaded
```

No persistent permission, MEMLOCK, or BPF load failures were observed.

## Profiling Target Discovery

Initial Kubernetes discovery:

```text
pyroscope_ebpf_active_targets = 41
```

After adding process discovery and joining Kubernetes metadata with local processes:

```text
pyroscope_ebpf_active_targets = 69
```

Internal profiler activity included:

```text
agent_num_generic_pid_total                1782
bpf_num_proc_new_total                    2382
agent_num_exe_id_loaded_to_ebpf              2
agent_stack_delta_extraction_success_total   2
```

Profiling health:

```text
pyroscope_ebpf_profiling_sessions_total          1
pyroscope_ebpf_profiling_sessions_failing_total  0
pyroscope_ebpf_pprofs_dropped_total              0
```

The Alloy graph confirmed:

```text
pyroscope.ebpf.otel_demo
        |
        v
pyroscope.write.central
```

## Writer Configuration

Profiles are configured to be sent to:

```text
http://monitoring-cluster-worker:30440
```

with:

```text
k8s_cluster_name            = workload-cluster
deployment_environment_name = lab
```

## Validation Boundary

Validated:

```text
Pyroscope backend deployment                PASS
Pyroscope readiness                         PASS
Pyroscope version 2.2.0                     PASS
Cross-cluster connectivity                  PASS
Dedicated Alloy profiler                    PASS
DaemonSet deployment                        PASS
hostPID / privileged configuration          PASS
Kernel compatibility                        PASS
eBPF tracer load                            PASS
Process target discovery                    PASS
Active profiling targets                    PASS
Failed profiling sessions                   0
Dropped pprof profiles                      0
Profiler -> writer graph connection         PASS
```

At the time of validation, the Astronomy Shop load generator had been scaled to zero. Because the workload was intentionally quiet, stored CPU profiles and flame-graph data were not fully validated.

That deeper profile-content validation is intentionally deferred for a later revisit.

## Deferred Follow-Up

When revisiting this stage:

```text
Re-enable application load
Confirm pyroscope_ebpf_pprofs_total > 0
Confirm Pyroscope ProfileTypes
Confirm service_name values
Confirm cluster/environment labels
Query stored CPU profile series
Render flame graph data
```

## Stage 4f Status

```text
Stage 4f - Grafana Pyroscope      COMPLETE
Profile-content deep validation   DEFERRED FOR REVISIT
```

**Stage 4f status: Complete.**
