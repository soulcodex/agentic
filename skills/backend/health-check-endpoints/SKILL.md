---
name: health-check-endpoints
description: >
  Implements liveness and readiness health check endpoints following Kubernetes
  probe conventions. Covers response schema, dependency checks, Kubernetes probe
  config, and circuit breaker integration. Invoked when the user asks to add
  health checks, implement a /health endpoint, or set up Kubernetes probes.
version: 1.0.0
tags:
  - backend
  - health
  - kubernetes
  - observability
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Health Check Endpoints Skill

### Step 1 — Liveness Endpoint

`GET /health/live`

**Purpose**: tells Kubernetes whether the process is alive. If this fails, the pod
is restarted. Do **not** check external dependencies here — a database outage should
not restart all pods.

```go
// Go example
func livenessHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
```

Rules:
- Always returns `200 OK` unless the process is deadlocked or terminally broken.
- No database, cache, or broker calls.
- Response time < 5 ms.

### Step 2 — Readiness Endpoint

`GET /health/ready`

**Purpose**: tells Kubernetes whether the pod can accept traffic. If this fails,
the pod is removed from the load balancer (but not restarted). Check all
dependencies the service needs to serve requests.

```go
// Go example
func readinessHandler(w http.ResponseWriter, r *http.Request) {
    checks := map[string]CheckResult{}
    overall := "ok"

    // Database check
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()
    if err := db.PingContext(ctx); err != nil {
        checks["db"] = CheckResult{Status: "fail", Error: err.Error()}
        overall = "fail"
    } else {
        start := time.Now()
        db.PingContext(ctx)
        checks["db"] = CheckResult{Status: "ok", LatencyMs: time.Since(start).Milliseconds()}
    }

    // Redis check
    if err := cache.Ping(r.Context()).Err(); err != nil {
        checks["cache"] = CheckResult{Status: "fail", Error: err.Error()}
        overall = "fail"
    } else {
        checks["cache"] = CheckResult{Status: "ok"}
    }

    status := http.StatusOK
    if overall == "fail" {
        status = http.StatusServiceUnavailable
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(HealthResponse{Status: overall, Checks: checks})
}
```

### Step 3 — JSON Response Schema

Both endpoints use the same response shape:

```json
{
  "status": "ok",
  "checks": {
    "db": {
      "status": "ok",
      "latency_ms": 2
    },
    "cache": {
      "status": "ok",
      "latency_ms": 1
    },
    "broker": {
      "status": "fail",
      "error": "connection refused"
    }
  }
}
```

Top-level `status`: `"ok"` | `"degraded"` | `"fail"`.
Per-check `status`: `"ok"` | `"fail"`.
HTTP status: `200` for `ok`/`degraded`, `503` for `fail`.

### Step 4 — Kubernetes Probe Configuration

```yaml
# deployment.yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 10     # give the app time to start
  periodSeconds: 10
  failureThreshold: 3         # restart after 3 consecutive failures

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3         # remove from LB after 3 failures
  successThreshold: 1         # re-add after 1 success
```

Tune `initialDelaySeconds` to match the application's actual startup time.
Set `timeoutSeconds` to slightly above the dependency check timeout (e.g., 3 s).

### Step 5 — Circuit Breaker Integration

When a dependency's circuit breaker is **open**, the readiness check for that
dependency should return `"fail"`:

```go
if circuitBreaker.IsOpen("db") {
    checks["db"] = CheckResult{Status: "fail", Error: "circuit open"}
    overall = "fail"
}
```

This prevents traffic from reaching the pod when the circuit breaker would reject
all requests anyway, reducing cascading error propagation.

### Verify

- [ ] `GET /health/live` returns `200 OK` in < 5 ms with no external calls.
- [ ] `GET /health/ready` returns `503` when a dependency is down.
- [ ] `GET /health/ready` returns `200` once dependencies recover.
- [ ] Kubernetes `livenessProbe` and `readinessProbe` are configured.
- [ ] Dependency check timeouts are shorter than Kubernetes probe `timeoutSeconds`.
- [ ] Health endpoints are excluded from access logs (to avoid noise).
