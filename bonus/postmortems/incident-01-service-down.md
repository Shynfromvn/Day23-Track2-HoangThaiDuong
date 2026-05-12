# Incident 01 - Inference API Stopped

## Summary

The `day23-app` container was stopped to simulate a hard service outage.
Prometheus could no longer scrape `inference-api`, and Alertmanager routed a
`ServiceDown` alert to Slack.

## Timeline

| Time | Event |
|---|---|
| T+00s | `docker stop day23-app` issued |
| T+60s | Prometheus `up{job="inference-api"} == 0` condition persisted |
| T+85s | Alertmanager showed active `ServiceDown` |
| T+90s | Slack received firing alert |
| T+95s | App restarted |
| T+~60s after restart | Slack received resolved alert |

## Detection

Primary signal: `ServiceDown` alert.

Evidence: `submission/screenshots/slack-firing.png` and
`submission/screenshots/slack-resolved.png`.

## Mitigation

Restart the app container:

```powershell
docker start day23-app
```

## Root Cause

Intentional chaos injection stopped the container.

## Action Items

- Keep `ServiceDown` as a critical alert.
- Keep Slack `send_resolved: true`; the resolve message matters as much as the page.
- In Kubernetes, use liveness/readiness probes and `replicas: 2` to reduce manual restart work.

