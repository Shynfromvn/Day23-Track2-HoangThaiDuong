# Day 23 Lab Reflection

**Student:** Hoàng Thái Dương 
**Submission date:** 2026-05-11  
**Lab repo URL:** https://github.com/Shynfromvn/Day23-Track2-HoangThaiDuong.git

---

## 1. Hardware + setup output

Paste output of `python 00-setup/verify-docker.py` after Docker Desktop is running:

```text
Docker:        OK  (29.4.0)
Compose v2:    OK  (5.1.1)
RAM available: 7.57 GB (OK)
Ports free:    OK
Report written: E:\Vin\phase2-ass-day23\Day23-Track2-HoangThaiDuong\00-setup\setup-report.json
```

---

## 2. Track 02 - Dashboards & Alerts

### 6 essential panels

Screenshot to commit: `submission/screenshots/dashboard-overview.png`.

### Burn-rate panel

Screenshot to commit: `submission/screenshots/slo-burn-rate.png`.

### Cost and tokens

Screenshot to commit: `submission/screenshots/cost-and-tokens.png`.

### Alert fire + resolve

| When | What | Evidence |
|---|---|---|
| T0 | stopped `day23-app` with `make alert` | `submission/screenshots/alertmanager-firing.png` |
| T0+~90s | `ServiceDown` fired | `submission/screenshots/slack-firing.png` |
| T1 | app restarted by the alert script | terminal output from `make alert` |
| T1+~60s | alert resolved | `submission/screenshots/slack-resolved.png` |

### One thing surprised me about Prometheus / Grafana

The useful part was not just collecting many metrics; it was choosing labels that kept the queries stable. The inference dashboard became readable once the core RED signals were grouped by `model` and `status`, while high-cardinality data such as prompt text stayed out of Prometheus and lived in traces/logs instead.

---

## 3. Track 03 - Tracing & Logs

### One trace screenshot from Jaeger

Screenshot to commit: `submission/screenshots/jaeger-trace.png`, showing the `predict` span with child spans `embed-text`, `vector-search`, and `generate-tokens`.

### GenAI semantic attributes

Screenshot to commit: `submission/screenshots/jaeger-genai-attrs.png`, showing attributes such as `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, and `gen_ai.response.finish_reason`.

### Log line correlated to trace

Paste one JSON log line from `docker compose logs app` after calling `/predict`:

```json
{"model": "llama3-mock", "input_tokens": 10, "output_tokens": 14, "quality": 0.746, "duration_seconds": 0.2469, "trace_id": "d007f927c6b9b1d363320025f026345a", "event": "prediction served", "level": "info", "timestamp": "2026-05-12T03:27:16.896552Z"}
```

The `trace_id` in the log should match the trace ID returned by `make trace` and visible in Jaeger.

### Tail-sampling math

The collector policy keeps 100% of traces with `ERROR` status, 100% of slow traces over 2000 ms, and 1% of the remaining healthy traces. If the service produced `N` traces/sec, with `E` error traces/sec and `S` slow non-error traces/sec, the expected retained rate is:

```text
kept/sec = E + S + 0.01 * (N - E - S)
```

For a mostly healthy run at 20 traces/sec with no errors and no slow traces, that is about `0.2 traces/sec`, or 1% retained. During a forced error, the error trace is retained even when the healthy traces are sampled away.

---

## 4. Track 04 - Drift Detection

### PSI scores

`04-drift-detection/reports/drift-summary.json`:

```json
{
  "prompt_length": {
    "psi": 3.461,
    "kl": 1.7982,
    "ks_stat": 0.702,
    "ks_pvalue": 0.0,
    "drift": "yes"
  },
  "embedding_norm": {
    "psi": 0.0187,
    "kl": 0.0324,
    "ks_stat": 0.052,
    "ks_pvalue": 0.133853,
    "drift": "no"
  },
  "response_length": {
    "psi": 0.0162,
    "kl": 0.0178,
    "ks_stat": 0.056,
    "ks_pvalue": 0.086899,
    "drift": "no"
  },
  "response_quality": {
    "psi": 8.8486,
    "kl": 13.5011,
    "ks_stat": 0.941,
    "ks_pvalue": 0.0,
    "drift": "yes"
  }
}
```

Screenshot to commit: `submission/screenshots/drift-report.png`, showing `04-drift-detection/reports/drift-report.html` rendered in a browser.

### Which test fits which feature?

For `prompt_length`, I would use PSI for operational monitoring because it is easy to threshold and explain to product/SRE stakeholders; I would use KS as a secondary statistical check because the feature is continuous. For `embedding_norm`, KS is a good first production test because the expected distribution is continuous and should remain stable around the model's embedding scale; MMD would be better for full embedding vectors, but norm alone is one-dimensional. For `response_length`, PSI works well for dashboarding bucket shifts, while KS catches distribution changes without requiring fixed bins. For `response_quality`, PSI is useful as the alerting signal because a shift from high beta-distributed scores to low scores is operationally meaningful, and KL helps quantify how different the full score distribution became.

---

## 5. Track 05 - Cross-Day Integration

### Which prior-day metric was hardest to expose? Why?

The Day 20 llama.cpp metric is the hardest because llama.cpp does not expose the exact AI-serving metrics this dashboard wants unless a sidecar or patch is present. Day 19 Qdrant is easier because it can expose Prometheus-style `/metrics`, while Day 20 often needs a wrapper to translate serving events into stable counters and gauges.

Screenshot to commit: `submission/screenshots/cross-day-dashboard.png`, showing the `Cross-Day Stack (Day 23 integrative)` dashboard with all six panels.

---

## 6. The single change that mattered most

The single change that mattered most was treating the `/predict` request as one trace tree instead of three unrelated timing blocks. The top-level `predict` span now carries GenAI attributes for model, prompt length, token usage, and quality score, while the child spans separate embedding, vector search, and token generation. That turns a slow request from "something was slow" into an operator-friendly answer: retrieval, generation, or the API wrapper.

This connects directly to the deck's RED/USE and tracing sections. Metrics tell me that latency or error budget burn happened; traces tell me where it happened; logs give me the exact correlated event through `trace_id`. The stack becomes useful when those three views agree on the same request instead of existing as separate dashboards.
