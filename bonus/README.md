# Bonus Portfolio Piece: Postmortem Rehearsal

## Scenario

I operate the Day 23 inference observability stack as the on-call engineer for a
small AI service. Instead of adding more dashboards for their own sake, this
bonus intentionally breaks the system in three different ways and records what
signal caught the incident, how fast it was detected, and what system change
made the next incident easier to handle.

## Incidents

| Incident | Failure mode | Signal | Evidence |
|---|---|---|---|
| 01 | App stopped | `ServiceDown` Alertmanager + Slack | `submission/screenshots/slack-firing.png`, `submission/screenshots/slack-resolved.png` |
| 02 | Healthy traffic but SLO panel blank | SLO dashboard returned no data while app had traffic | `submission/screenshots/slo-burn-rate.png` |
| 03 | Prior-day dashboard had no integrations | Cross-day dashboard showed no source connected | `submission/screenshots/cross-day-dashboard.png` |

## Run The Chaos Scripts

From the repo root with the Compose stack running:

```powershell
powershell -ExecutionPolicy Bypass -File bonus/chaos/incident-01-service-down.ps1
powershell -ExecutionPolicy Bypass -File bonus/chaos/incident-02-error-burn.ps1
powershell -ExecutionPolicy Bypass -File bonus/chaos/incident-03-prior-day-stubs.ps1
```

Each script prints the detection query and the expected dashboard or alert to
inspect. The scripts are intentionally small so an on-call engineer can read
them before running them.

## Real System Changes From The Drill

- Alertmanager startup was fixed so the Slack webhook is read from a file inside
  the container.
- Grafana datasource UIDs are pinned (`prometheus`, `loki`, `jaeger`) so
  dashboard-as-code works reproducibly.
- SLO recording rules now return `0` instead of empty series when there are no
  errors, making a healthy system visibly healthy.
- Cross-day stubs now provide data for all six prior-day panels.

## Portfolio Summary

This bonus turns the lab into a blameless operations artifact: the stack has
metrics, traces, logs, alerts, screenshots, and postmortems that explain what
changed because of the incidents.

