<#
.Create-SubIssues.ps1
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
  $Token = Read-Host -Prompt "GITHUB_TOKEN (PAT)" -AsSecureString
  $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token))
  if (-not $Token -or $Token.Trim() -eq "") { Write-Error "Kein Token. Abbruch."; exit 1 }
}

$headers = @{
  Authorization = "Bearer $Token"
  "User-Agent"  = "$Owner-CreateSubIssuesScript"
  Accept        = "application/vnd.github+json"
}

# Parent-URL
$parentUrl = "https://github.com/$Owner/$Repo/issues/$ParentIssueNumber"

$issues = @(
  @{
    title = "Requirements & Data Sources"
    body  = "Finalisiere Anforderungen, Auth/Access, und liste freizugebende SAP-Datenquellen (Logs, Jobs, IDocs, RFCs).\n\nParent Issue: $parentUrl"
    labels = @("task","requirements")
    estimate = "2-3d"
  },
  @{
    title = "Log Collector â€” SAP Ingest Adapter (Jobs / IDocs / RFCs)"
    body  = "Implementiere modularen Ingest (API/SFTP), Parser/Normalizer und sichere Speicherung (S3/DB). Inkl. sample ingestion tests.\n\nParent Issue: $parentUrl"
    labels = @("backend","ingest")
    estimate = "3-5d"
  },
  @{
    title = "Baseline Anomaly Detector (Regel + ML PoC)"
    body  = "Erstelle ein regelbasiertes Detektionsmodul und ein leichtes ML-Proof-of-Concept fÃ¼r Anomalien / Klassifikation. Eval-Metriken definieren.\n\nParent Issue: $parentUrl"
    labels = @("ml","poC")
    estimate = "4-7d"
  },
  @{
    title = "Root-Cause Analysis & Suggestion Engine"
    body  = "Implementiere Root-Cause-Hypothesen-Generator und Vorschlags-Engine. Schnittstelle zum UI fÃ¼r VorschlÃ¤ge und BegrÃ¼ndungen.\n\nParent Issue: $parentUrl"
    labels = @("ml","analysis")
    estimate = "4-6d"
  },
  @{
    title = "Human-in-the-Loop UI (Review & Approval)"
    body  = "Web Dashboard fÃ¼r PrÃ¼fungen, Freigabe/Ablehnung und Feedback (Thumbs/Korrektur). Feedback-Events fÃ¼r spÃ¤tere Modell-Verbesserung loggen.\n\nParent Issue: $parentUrl"
    labels = @("frontend","ui","human-in-the-loop")
    estimate = "4-6d"
  },
  @{
    title = "Ticket Integration (Jira / ServiceNow)"
    body  = "Adapter/Mapping fÃ¼r Jira/ServiceNow API, Testcases, Mapping-Templates fÃ¼r Ticket-Felder. Ein Endpunkt zum Erstellen strukturierter Tickets nach Freigabe.\n\nParent Issue: $parentUrl"
    labels = @("integration","ticketing")
    estimate = "2-4d"
  },
  @{
    title = "Evaluation, Documentation & Governance"
    body  = "Eval-Skripte, README, DSGVO/Governance Hinweise, Audit-Logging und Betriebsanleitung. Abschlusstests.\n\nParent Issue: $parentUrl"
    labels = @("docs","governance")
    estimate = "2-4d"
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
    Write-Host "Issue erstellt: $($resp.html_url)" -ForegroundColor Green
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

# Create all issues
foreach ($i in $issues) {
  Create-Issue $i
  Start-Sleep -Seconds 1
}

Write-Host "Fertig. PrÃ¼fe die gerade erstellten Issues im Repo." -ForegroundColor Cyan
