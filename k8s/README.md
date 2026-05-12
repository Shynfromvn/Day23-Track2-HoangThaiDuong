# Day 23 Advanced Kubernetes Port

This folder is a production-shaped Kubernetes port of the Day 23 Compose stack.
It is intentionally written as raw manifests plus `kustomize` so the rendered
objects are easy to inspect before applying them.

## What This Deploys

- `monitoring` namespace
- Inference API Deployment + Service
- Prometheus StatefulSet + Service + PVC
- Alertmanager Deployment + Service
- Grafana Deployment + Service + PVC
- Loki Deployment + Service
- Jaeger all-in-one Deployment + Service
- OpenTelemetry Collector Deployment + Service

## Run On A Local Cluster

Create a local cluster with Docker Desktop Kubernetes, kind, or k3d. Then:

```powershell
kubectl apply -k k8s/raw
kubectl get pods -n monitoring
```

Port-forward the UIs:

```powershell
kubectl -n monitoring port-forward svc/inference-api 8000:8000
kubectl -n monitoring port-forward svc/grafana 3000:3000
kubectl -n monitoring port-forward svc/prometheus 9090:9090
kubectl -n monitoring port-forward svc/alertmanager 9093:9093
kubectl -n monitoring port-forward svc/jaeger 16686:16686
kubectl -n monitoring port-forward svc/loki 3100:3100
```

## Build The App Image

For kind:

```powershell
docker build -t day23-inference-api:local 01-instrument-fastapi/app
kind load docker-image day23-inference-api:local
kubectl apply -k k8s/raw
```

For Docker Desktop Kubernetes, the local Docker image is usually visible to the
cluster directly:

```powershell
docker build -t day23-inference-api:local 01-instrument-fastapi/app
kubectl apply -k k8s/raw
```

## Slack Webhook Secret

Create the Slack secret before applying if you want Slack alert delivery:

```powershell
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic slack-webhook `
  --from-literal=url="https://hooks.slack.com/services/..." `
  --dry-run=client -o yaml | kubectl apply -f -
```

If the secret is absent, Alertmanager still starts but Slack delivery will fail.

## Verification

```powershell
kubectl -n monitoring get pods
kubectl -n monitoring exec deploy/inference-api -- wget -qO- http://localhost:8000/healthz
kubectl -n monitoring port-forward svc/inference-api 8000:8000
curl http://localhost:8000/metrics
```

Prometheus should scrape `inference-api.monitoring.svc.cluster.local:8000`.
Grafana dashboards are generated from the same dashboard-as-code JSON files used
by the Compose lab.

## Architecture Notes

- Prometheus is a StatefulSet with a PVC because TSDB data must survive pod restarts.
- Grafana has a PVC for local state, but all datasources and dashboards are still provisioned as code.
- The app uses readiness/liveness/startup probes. A slow model-load version should increase `startupProbe.failureThreshold`.
- OTel Collector is a Deployment gateway here. For node-level telemetry, use an Operator or DaemonSet in a production cluster.
- Secrets are Kubernetes `Secret` objects, not ConfigMaps.

