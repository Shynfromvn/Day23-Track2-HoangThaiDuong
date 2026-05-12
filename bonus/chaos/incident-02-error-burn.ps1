Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Incident 02: inject application-level 503s to exercise SLO burn-rate math."

for ($i = 1; $i -le 30; $i++) {
    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri "http://localhost:8000/predict" `
            -ContentType "application/json" `
            -Body '{"prompt":"chaos burn-rate probe","fail":true}' | Out-Null
    } catch {
        # 503 is expected for this drill.
    }
}

Write-Host "Injected 30 forced failures. Wait 30-60s, then inspect:"
Write-Host "  http://localhost:3000/d/day23-slo"
Write-Host "Prometheus quick check:"
Invoke-RestMethod "http://localhost:9090/api/v1/query?query=inference%3Afail_ratio%3Arate5m" |
    ConvertTo-Json -Depth 6

