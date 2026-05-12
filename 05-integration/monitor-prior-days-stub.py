"""Stub metrics for prior days 16, 17, 18, and 22.

This fills the cross-day Grafana dashboard when the original prior-day labs are
not running locally. Day 19 and Day 20 have dedicated stubs in this folder.
"""
from __future__ import annotations

import random
import time

from prometheus_client import Gauge, Histogram, start_http_server


def main() -> int:
    airflow_duration = Histogram(
        "airflow_dag_run_duration_seconds",
        "Stub: Airflow DAG run duration",
        buckets=(30, 60, 120, 300, 600, 900, 1200),
    )
    spark_active = Gauge("spark_application_active", "Stub: active Spark applications")
    dpo_pass_rate = Gauge("day22_dpo_eval_pass_rate", "Stub: DPO eval pass rate")

    start_http_server(9103)
    print("Stub Day 16/17/18/22 metrics on :9103 (Prometheus job: node-stub)")

    while True:
        airflow_duration.observe(max(15, random.gauss(180, 35)))
        spark_active.set(1)
        dpo_pass_rate.set(max(0.0, min(1.0, random.gauss(0.91, 0.02))))
        time.sleep(5)


if __name__ == "__main__":
    raise SystemExit(main())
