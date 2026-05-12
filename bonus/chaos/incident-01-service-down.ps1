Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Incident 01: stop the inference API and wait for ServiceDown."
docker stop day23-app | Out-Null

Write-Host "Waiting up to 120s for Alertmanager to show an active alert..."
for ($i = 1; $i -le 24; $i++) {
    Start-Sleep -Seconds 5
    $alerts = Invoke-RestMethod "http://localhost:9093/api/v2/alerts"
    if ($alerts.Count -gt 0) {
        Write-Host "Detected active alert after $($i * 5)s"
        $alerts | ConvertTo-Json -Depth 6
        break
    }
    Write-Host "No active alert yet after $($i * 5)s"
}

Write-Host "Restarting day23-app..."
docker start day23-app | Out-Null

Write-Host "Watch Slack for the firing and resolved Day23 Alerts messages."

