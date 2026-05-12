# Incident 03 - Cross-Day Dashboard Had No Connected Sources

## Summary

The cross-day dashboard loaded successfully but all panels showed "No Data". The
dashboard file existed, but no prior-day metrics were being scraped.

## Timeline

| Time | Event |
|---|---|
| T+00m | Cross-day dashboard opened |
| T+01m | Day19 and Day20 panels showed no data |
| T+04m | Stub exporters started on host ports 9101 and 9102 |
| T+06m | Prometheus returned Day19/Day20 metrics |
| T+10m | Added prior-days stub exporter for Day16/17/18/22 |
| T+12m | Prometheus returned all six dashboard queries |

## Detection

Primary signal: all six dashboard panels had no values.

Secondary signal: Prometheus query API returned empty vectors for prior-day
metric names.

## Mitigation

Run local stub exporters:

```powershell
Start-Process -WindowStyle Hidden .venv\Scripts\python.exe -ArgumentList "05-integration\monitor-prior-days-stub.py"
Start-Process -WindowStyle Hidden .venv\Scripts\python.exe -ArgumentList "05-integration\monitor-day19-vector-store.py"
Start-Process -WindowStyle Hidden .venv\Scripts\python.exe -ArgumentList "05-integration\monitor-day20-llama-cpp.py"
```

## Root Cause

The integration dashboard was provisioned, but prior-day systems were not
running. A dashboard can be syntactically valid and still operationally useless
if no source is connected.

## Action Items

- Added `05-integration/monitor-prior-days-stub.py`.
- Added Prometheus scrape jobs for Day16/17/18/19/20/22 stubs.
- Captured `submission/screenshots/cross-day-dashboard.png` after all six panels had data.

