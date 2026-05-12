# Bonus Reflection

The surprising part was that the hardest failures were not dramatic container
crashes. The obvious incident, stopping the app, was caught by Prometheus and
Slack quickly. The more useful lessons came from quiet failures: a Grafana panel
that showed no data because a healthy system had no `status="error"` time series,
and a cross-day dashboard that had valid JSON but pointed at a datasource UID
Grafana had generated differently. Those failures are exactly why observability
as code has to be tested end to end, not just linted.

With another eight hours, I would move this into a real Kubernetes cluster using
the manifests in `k8s/`, then add a GitOps loop with ArgoCD. The next useful
upgrade would be a small queue-backed agent workload with OpenTelemetry spans
for each tool call, because agent failures are slower and messier than normal
HTTP failures. I would also add a tiny owner-facing alert summary, written in
Vietnamese, so non-engineers receive impact language while engineers keep the
full Prometheus context.

