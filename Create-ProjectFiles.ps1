<#
Create-ProjectFiles.ps1

Legt Projektdateien lokal an oder erstellt sie direkt in einem GitHub-Repo.
Usage examples:
# 1) Lokal + Commit (kein push):
.\Create-ProjectFiles.ps1 -RepoPath "C:\code\SAP-AI" -Commit -CommitMessage "Add initial templates & scripts"

# 2) Direkt in GitHub (erstellt/updated Dateien im Repo branch 'main'):
.\Create-ProjectFiles.ps1 -Mode github -Owner "lkwdriver98" -RepoName "SAP-AI" -Token "<PAT>" -Branch "main"

Notes:
- Für Mode=github benötigt das Token 'repo' Rechte.
- Verwende 'Commit' nur bei lokalem Repo; das Skript versucht nicht automatisch remote push zu machen.
#>

param(
  [string]$RepoPath = ".",
  [ValidateSet("local","github")]
  [string]$Mode = "local",
  [string]$Owner = "",
  [string]$RepoName = "",
  [string]$Token = "",
  [switch]$Commit,
  [string]$CommitMessage = "Add initial project files",
  [string]$Branch = "main"
)

# ----------------------------
# Datei-Inhalte (anpassen falls nötig)
# ----------------------------
$files = @()

# .gitignore
$files += @{
  path = ".gitignore"
  content = @'
# Secrets
.env

# Node / Python / general
node_modules
dist
__pycache__
*.pyc

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
'@
}

# .env.example
$files += @{
  path = ".env.example"
  content = @'
# !!! Trage hier deinen Key ein und committe .env NICHT ins Git !!!
OPENAI_API_KEY=PASTE_YOUR_KEY_HERE
# Optional: Unternehmens-Proxy (falls nötig)
# HTTPS_PROXY=http://user:pass@proxyhost:8080
OPENAI_MODEL=gpt-4o-mini
OPENAI_TIMEOUT_MS=15000
'@
}

# README.md (kurz)
$files += @{
  path = "README.md"
  content = @'
# SAP-AI (SmartOps AI) – MVP

Dieses Repo enthält Vorlagen und Skripte für das SmartOps AI MVP:
- Datenerfassung (SAP-Logs/IDocs/RFCs)
- Baseline Anomaly Detection
- Root-Cause Analysis & Suggestion Engine
- Human-in-the-Loop UI
- Ticket-Integration (Jira/ServiceNow)

Siehe Issues für detaillierte Tasks. Dieses Projekt wurde vorbereitet basierend auf dem Starterkit / Exposé.
'@
}

# .github/PULL_REQUEST_TEMPLATE.md
$files += @{
  path = ".github/PULL_REQUEST_TEMPLATE.md"
  content = @'
## Kurzbeschreibung
(Was macht dieser PR? Welches Issue wird adressiert?)

## Art der Änderung
- [ ] Bugfix
- [ ] Feature
- [ ] Dokumentation
- [ ] Infrastruktur

## Vorgehensweise
(Kurze Erklärung der Implementierung, wichtige Entscheidungen)

## Tests
(Was wurde getestet? Unit/Integration/Manual Steps)

## Checkliste
- [ ] Code-Lint/Format
- [ ] Tests grün
- [ ] Dokumentation aktualisiert
- [ ] Issue referenziert (z. B. fixes #12)

## Sonstiges
(Relevante Hinweise, Deploy-Notizen)
'@
}

# scripts/Create-SubIssues.ps1 (aus vorheriger Nachricht)
$files += @{
  path = "scripts/Create-SubIssues.ps1"
  content = @'
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
    title = "Log Collector — SAP Ingest Adapter (Jobs / IDocs / RFCs)"
    body  = "Implementiere modularen Ingest (API/SFTP), Parser/Normalizer und sichere Speicherung (S3/DB). Inkl. sample ingestion tests.\n\nParent Issue: $parentUrl"
    labels = @("backend","ingest")
    estimate = "3-5d"
  },
  @{
    title = "Baseline Anomaly Detector (Regel + ML PoC)"
    body  = "Erstelle ein regelbasiertes Detektionsmodul und ein leichtes ML-Proof-of-Concept für Anomalien / Klassifikation. Eval-Metriken definieren.\n\nParent Issue: $parentUrl"
    labels = @("ml","poC")
    estimate = "4-7d"
  },
  @{
    title = "Root-Cause Analysis & Suggestion Engine"
    body  = "Implementiere Root-Cause-Hypothesen-Generator und Vorschlags-Engine. Schnittstelle zum UI für Vorschläge und Begründungen.\n\nParent Issue: $parentUrl"
    labels = @("ml","analysis")
    estimate = "4-6d"
  },
  @{
    title = "Human-in-the-Loop UI (Review & Approval)"
    body  = "Web Dashboard für Prüfungen, Freigabe/Ablehnung und Feedback (Thumbs/Korrektur). Feedback-Events für spätere Modell-Verbesserung loggen.\n\nParent Issue: $parentUrl"
    labels = @("frontend","ui","human-in-the-loop")
    estimate = "4-6d"
  },
  @{
    title = "Ticket Integration (Jira / ServiceNow)"
    body  = "Adapter/Mapping für Jira/ServiceNow API, Testcases, Mapping-Templates für Ticket-Felder. Ein Endpunkt zum Erstellen strukturierter Tickets nach Freigabe.\n\nParent Issue: $parentUrl"
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

Write-Host "Fertig. Prüfe die gerade erstellten Issues im Repo." -ForegroundColor Cyan
'@
}

# scripts/Create-GitHubIssue.ps1 (simpler version)
$files += @{
  path = "scripts/Create-GitHubIssue.ps1"
  content = @'
<#
Kurz: Erstellt ein GitHub Issue.
Usage:
$env:GITHUB_TOKEN = "ghp_..."
.\Create-GitHubIssue.ps1 -Owner "lkwdriver98" -Repo "SAP-AI"
#>
param(
  [string]$Owner = "lkwdriver98",
  [string]$Repo  = "SAP-AI",
  [string]$Token = $env:GITHUB_TOKEN,
  [string]$Title = "MVP: SmartOps AI — Automatic issue detection & ticketing for SAP with Human-in-the-Loop",
  [string]$Assignee = "lkwdriver98"
)

if (-not $Token -or $Token.Trim() -eq "") {
  Write-Host "Bitte GITHUB_TOKEN eingeben:" -ForegroundColor Yellow
  $Token = Read-Host -AsSecureString
  $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token))
  if (-not $Token) { Write-Error "Kein Token"; exit 1 }
}

$headers = @{
  Authorization = "token $Token"
  "User-Agent"  = "$Owner-CreateIssueScript"
  Accept        = "application/vnd.github+json"
}

$body = @"
**Kurzbeschreibung**
Aufbau eines MVP für SmartOps AI: Automatische Erkennung...
(gekürzt für Demo - fülle ggf. aus)
"@

$payload = @{
  title = $Title
  body = $body
  labels = @("feature","sap","ml","human-in-the-loop","backend","priority:high","MVP")
  assignees = @($Assignee)
} | ConvertTo-Json -Depth 6

$uri = "https://api.github.com/repos/$Owner/$Repo/issues"
try {
  $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $payload -ContentType "application/json"
  Write-Host "Issue erstellt: $($resp.html_url)"
} catch {
  Write-Error ("Fehler beim Erstellen des Issues: {0}" -f $_.Exception.Message)
}
'@
}

# scripts/Create-GitHubIssue-Debug.ps1 (aus vorheriger Nachricht)
$files += @{
  path = "scripts/Create-GitHubIssue-Debug.ps1"
  content = @'
<#
Robustes Debug-Skript, prüft Token und Repo, erstellt Issue mit Debug-Ausgabe.
(gekürzt hier - siehe vollständiges Skript in Nachrichtenverlauf)
#>
Write-Host "Dies ist ein Debug-Skript (gekürzt). Für die vollständige Fassung siehe Chatverlauf."
'@
}

# .github/workflows/example-ci.yml (kleines Beispiel)
$files += @{
  path = ".github/workflows/example-ci.yml"
  content = @'
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.10"
      - name: Lint
        run: echo "Add real checks here"
'@
}

# ----------------------------
# Helpers
# ----------------------------
function Ensure-DirForFile($fullPath) {
  $dir = Split-Path $fullPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Write-LocalFile($repoPath, $relativePath, $content) {
  $fullPath = Join-Path $repoPath $relativePath
  Ensure-DirForFile $fullPath
  Set-Content -Path $fullPath -Value $content -Encoding UTF8
  Write-Host "Geschrieben: $relativePath"
}

# ----------------------------
# Mode: local
# ----------------------------
if ($Mode -eq "local") {
  Write-Host "Modus: local. Dateien werden nach '$RepoPath' geschrieben." -ForegroundColor Cyan
  foreach ($f in $files) {
    try {
      Write-LocalFile -repoPath $RepoPath -relativePath $f.path -content $f.content
    } catch {
      Write-Error ("Fehler beim Schreiben von {0}: {1}" -f $f.path, $_.Exception.Message)
    }
  }

  if ($Commit) {
    # check git
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
      Write-Warning "Git nicht gefunden. Installiere Git oder verzichte auf -Commit."
    } else {
      $cwd = Get-Location
      try {
        Set-Location -Path (Resolve-Path $RepoPath)
        if (-not (Test-Path ".git")) {
          Write-Host "Kein Git-Repo gefunden. Initialisiere neues Repo." -ForegroundColor Yellow
          git init
          Write-Host "Bitte füge remote origin manuell hinzu, falls du pushen möchtest."
        }
        git add .
        git commit -m "$CommitMessage" --allow-empty
        Write-Host "Lokaler Commit erstellt." -ForegroundColor Green
      } catch {
        Write-Error ("Fehler beim Commit: {0}" -f $_.Exception.Message)
      } finally {
        Set-Location $cwd
      }
    }
  } else {
    Write-Host "Wenn gewünscht, führe Git add/commit manuell aus oder rufe dieses Skript mit -Commit auf." -ForegroundColor Yellow
  }

  exit 0
}

# ----------------------------
# Mode: github
# ----------------------------
if ($Mode -eq "github") {
  if (-not $Owner -or -not $RepoName) {
    Write-Error "Owner und RepoName sind erforderlich im github-Modus."
    exit 1
  }
  if (-not $Token -or $Token.Trim() -eq "") {
    Write-Error "Token ist erforderlich für github mode."
    exit 1
  }

  $headers = @{
    Authorization = "Bearer $Token"
    "User-Agent"  = "CreateProjectFilesScript"
    Accept        = "application/vnd.github+json"
  }

  function Upload-FileToGitHub($owner, $repo, $branch, $filePath, $content, $message) {
    $urlPath = [uri]::EscapeDataString($filePath)
    $apiUrl = "https://api.github.com/repos/$owner/$repo/contents/$urlPath"

    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $payload = @{
      message = $message
      content = $base64
      branch  = $branch
    } | ConvertTo-Json -Depth 6

    try {
      # Try to create/update (PUT)
      $resp = Invoke-RestMethod -Uri $apiUrl -Method Put -Headers $headers -Body $payload -ContentType "application/json" -ErrorAction Stop
      Write-Host ("GitHub: Datei erstellt/aktualisiert: {0} -> {1}" -f $filePath, $resp.content.download_url) -ForegroundColor Green
    } catch {
      Write-Error ("Fehler beim Upload von {0}: {1}" -f $filePath, $_.Exception.Message)
      if ($_.Exception.Response -ne $null) {
        $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd()
        Write-Host "GitHub Response:`n$body"
      }
    }
  }

  foreach ($f in $files) {
    Upload-FileToGitHub -owner $Owner -repo $RepoName -branch $Branch -filePath $f.path -content $f.content -message $CommitMessage
    Start-Sleep -Milliseconds 500
  }

  Write-Host "Fertig." -ForegroundColor Cyan
  exit 0
}

Write-Error "Unbekannter Modus: $Mode"
