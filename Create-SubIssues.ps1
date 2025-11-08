<#
Create-SubIssues.ps1
Legt mehrere Issues in einem Repo an und verlinkt sie mit dem Parent-Issue.
#>

param(
  [string]$Owner = "lkwdriver98",
  [string]$Repo  = "SAP-AI",
  [int]$ParentIssueNumber = 1,
  [string]$Token = $env:GITHUB_TOKEN,
  [string]$Assignee = "lkwdriver98"
)

if (-not $Token -or $Token.Trim() -eq "") {
  Write-Host "GITHUB_TOKEN nicht gefunden. Bitte Personal Access Token eingeben (repo scope)." -ForegroundColor Yellow
  $secure = Read-Host -Prompt "GITHUB_TOKEN (PAT)" -AsSecureString
  $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
  if (-not $Token -or $Token.Trim() -eq "") { Write-Error "Kein Token. Abbruch."; exit 1 }
}

$headers = @{
  Authorization = "Bearer $Token"
  "User-Agent"  = "$Owner-CreateSubIssuesScript"
  Accept        = "application/vnd.github+json"
}

$parentUrl = "https://github.com/$Owner/$Repo/issues/$ParentIssueNumber"

$issues = @(
  @{
    title = 'Requirements & Data Sources'
    body  = "Finalize requirements, auth/access, and list SAP data sources to enable (logs, jobs, IDocs, RFCs).`n`nParent Issue: $parentUrl"
    labels = @('task','requirements')
    estimate = '2-3d'
  },
  @{
    title = 'Log Collector - SAP Ingest Adapter (Jobs / IDocs / RFCs)'
    body  = "Implement a modular ingest (API/SFTP), parser/normalizer and secure storage (S3/DB). Include sample ingestion tests.`n`nParent Issue: $parentUrl"
    labels = @('backend','ingest')
    estimate = '3-5d'
  },
  @{
    title = 'Baseline Anomaly Detector (Rule + ML PoC)'
    body  = "Create a rule-based detection module and a lightweight ML proof-of-concept for anomalies/classification. Define evaluation metrics.`n`nParent Issue: $parentUrl"
    labels = @('ml','poC')
    estimate = '4-7d'
  },
  @{
    title = 'Root-Cause Analysis and Suggestion Engine'
    body  = "Implement root-cause hypothesis generator and suggestion engine. Provide an interface to the UI for suggestions and explanations.`n`nParent Issue: $parentUrl"
    labels = @('ml','analysis')
    estimate = '4-6d'
  },
  @{
    title = 'Human-in-the-Loop UI (Review and Approval)'
    body  = "Build a web dashboard for review, approval, and feedback (thumbs/corrections). Log feedback events for later model improvement.`n`nParent Issue: $parentUrl"
    labels = @('frontend','ui','human-in-the-loop')
    estimate = '4-6d'
  },
  @{
    title = 'Ticket Integration (Jira / ServiceNow)'
    body  = "Adapter and mapping for Jira/ServiceNow API, tests, and ticket-field templates. Provide an endpoint to create structured tickets after approval.`n`nParent Issue: $parentUrl"
    labels = @('integration','ticketing')
    estimate = '2-4d'
  },
  @{
    title = 'Evaluation, Documentation and Governance'
    body  = "Evaluation scripts, README, GDPR/governance notes, audit logging, and runbook. Final tests.`n`nParent Issue: $parentUrl"
    labels = @('docs','governance')
    estimate = '2-4d'
  }
)

function Create-Issue($issue) {
  $payload = @{
    title = $issue.title
    body  = $issue.body + "`n`n**Estimate**: " + $issue.estimate
    labels = $issue.labels
    assignees = @($Assignee)
  } | ConvertTo-Json -Depth 6

  $uri = "https://api.github.com/repos/$Owner/$Repo/issues"
  try {
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $payload -ContentType "application/json" -ErrorAction Stop
    Write-Host ("Issue erstellt: {0}" -f $resp.html_url) -ForegroundColor Green
  } catch {
    Write-Error ("Fehler beim Erstellen von '{0}': {1}" -f $issue.title, $_.Exception.Message)
    if ($_.Exception.Response -ne $null) {
      $stream = $_.Exception.Response.GetResponseStream()
      $reader = New-Object System.IO.StreamReader($stream)
      $body = $reader.ReadToEnd()
      Write-Host "GitHub Response:`n$body"
    }
  }
}

foreach ($i in $issues) {
  Create-Issue $i
  Start-Sleep -Seconds 1
}

Write-Host "Fertig. Pruefe die gerade erstellten Issues im Repo." -ForegroundColor Cyan
