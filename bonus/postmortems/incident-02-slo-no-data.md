# Incident 02 - SLO Dashboard Showed No Data On A Healthy System

## Summary

The SLO burn-rate dashboard showed "No data" even though the inference API had
served traffic. The underlying service was healthy; the observability query was
wrong for the no-error case.

## Timeline

| Time | Event |
|---|---|
| T+00m | Opened SLO Burn Rate dashboard |
| T+01m | Prometheus showed `inference_requests_total{status="ok"}` had samples |
| T+02m | Recording rule `inference:fail_ratio:rate5m` returned an empty vector |
| T+05m | Rules updated to use `or vector(0)` and `clamp_min(...)` |
| T+06m | Prometheus reloaded |
| T+07m | Dashboard showed error budget remaining at 100% and burn rate at 0 |

## Detection

Primary signal: a dashboard panel with "No data" while base request counters
were present.

## Mitigation

Update SLO rules so absence of errors means `0`, not empty:

```promql
(sum(rate(inference_requests_total{status="error"}[5m])) or vector(0))
/
clamp_min(sum(rate(inference_requests_total[5m])), 1e-9)
```

## Root Cause

Prometheus had no `status="error"` series during a healthy run. Dividing an
empty vector by a non-empty vector produced no time series, so Grafana displayed
"No data" instead of burn rate `0`.

## Action Items

- Implemented the rule fix in `02-prometheus-grafana/prometheus/rules/slo-burn-rate.yml`.
- Implemented the dashboard fix in `02-prometheus-grafana/grafana/dashboards/slo-burn-rate.json`.
- Add a dashboard-review checklist item: every healthy-state panel must show an explicit healthy value.

