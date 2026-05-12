Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Incident 03: restore prior-day telemetry sources with local stubs."

$repo = Resolve-Path "."
$python = Join-Path $repo ".venv\Scripts\python.exe"

Start-Process -WindowStyle Hidden -FilePath $python -ArgumentList "05-integration\monitor-prior-days-stub.py" -WorkingDirectory $repo
Start-Process -WindowStyle Hidden -FilePath $python -ArgumentList "05-integration\monitor-day19-vector-store.py" -WorkingDirectory $repo
Start-Process -WindowStyle Hidden -FilePath $python -ArgumentList "05-integration\monitor-day20-llama-cpp.py" -WorkingDirectory $repo

Invoke-WebRequest -Method Post "http://localhost:9090/-/reload" | Out-Null
Start-Sleep -Seconds 20

Write-Host "Cross-day source checks:"
Invoke-RestMethod "http://localhost:9090/api/v1/query?query=count(up%7Bjob%3D~%22node.*%22%7D)" | ConvertTo-Json -Depth 5
Invoke-RestMethod "http://localhost:9090/api/v1/query?query=day19_qdrant_collections" | ConvertTo-Json -Depth 5
Invoke-RestMethod "http://localhost:9090/api/v1/query?query=day20_llamacpp_tokens_per_second" | ConvertTo-Json -Depth 5
Invoke-RestMethod "http://localhost:9090/api/v1/query?query=day22_dpo_eval_pass_rate" | ConvertTo-Json -Depth 5

Write-Host "Now refresh the Cross-Day Stack dashboard in Grafana."

