<#
.SYNOPSIS
  Erstellt ein GitHub Issue in einem Repo (standard: lkwdriver98/SAP-AI)

.USAGE
  # 1) per Env-Var:
  $env:GITHUB_TOKEN = "ghp_..."
  .\Create-GitHubIssue.ps1

  # 2) per Parameter:
  .\Create-GitHubIssue.ps1 -Owner "lkwdriver98" -Repo "SAP-AI" -Token "ghp_..."

.NOTES
  Token wird nicht gespeichert. Stelle sicher, dass das Token "repo" Rechte hat.
#>

param(
  [string]$Owner = "lkwdriver98",
  [string]$Repo  = "SAP-AI",
  [string]$Token = $env:GITHUB_TOKEN,
  [string]$Title = "MVP: SmartOps AI — Automatic issue detection & ticketing for SAP with Human-in-the-Loop",
  [string]$Assignee = "lkwdriver98"
)

# Prompt for token if not provided
if (-not $Token -or $Token.Trim() -eq "") {
  Write-Host "GITHUB_TOKEN nicht gefunden. Bitte Personal Access Token eingeben (repo scope)." -ForegroundColor Yellow
  $Token = Read-Host -Prompt "GITHUB_TOKEN (PAT)"
  if (-not $Token -or $Token.Trim() -eq "") {
    Write-Error "Kein Token eingegeben. Abbruch."
    exit 1
  }
}

# Issue Body (Markdown)
$issueBody = @"
**Kurzbeschreibung**  
Aufbau eines MVP für SmartOps AI: Automatische Erkennung von SAP-Fehlern/Anomalien, Ursachenanalyse, Vorschlag von Lösungsschritten und strukturierte Ticket-Erstellung in einem Ticketsystem (z. B. Jira/ServiceNow). Jede vorgeschlagene Aktion erfordert menschliche Freigabe (Human-in-the-Loop).

**Hintergrund / Motivation**  
Ziel ist ein hybrides System, das automatische Erkennung und Analyse mit menschlicher Kontrolle kombiniert, um Ausfallzeiten zu reduzieren und gleichzeitig keine unkontrollierten Systemänderungen vorzunehmen.

**Ziele / Acceptance Criteria**
1. Datenintegration: Logs/Jobs/IDocs/RFCs werden erfasst und für die Analyse verfügbar gemacht.  
2. Anomalie-Erkennung: Erstes Regel-/ML-Modul identifiziert relevante Fehlerfälle.  
3. Ursachenanalyse: Automatisch generierte Root-Cause-Hypothesen + vorgeschlagene Maßnahmen.  
4. Human-in-the-Loop: UI/Workflow für Freigabe / Ablehnung vorgeschlagener Maßnahmen.  
5. Ticket-Anbindung: Automatisches Erzeugen eines strukturierten Ticket (Jira/ServiceNow) nach Freigabe.  
6. Protokollierung & Governance: Alle Aktionen protokolliert; keine automatische Änderung ohne GO.  
7. Dokumentation & Eval: README + Eval-Skript mit Beispiel-Datensatz und Erfolgsmetriken.

**Scope (MVP)**  
- Input: SAP Systemlogs, Job-Fehler, IDoc Fehler, RFC Errors (erstmalige Anbindung per API / SFTP).  
- Analyse: Heuristische + ML-basierte Erkennung (Anomalie / Klassifikation).  
- UI/Workflow: Einfaches Dashboard für Prüfungen + Freigabe.  
- Integration: Ticket-Erstellung in Jira/ServiceNow (Webhook/API).  
- Nicht im Scope: Vollautomatische Self-Healing-Aktionen ohne menschliche Freigabe; großflächiges Fine-Tuning eines LLM.

**Aufgaben (Tasks / Checklist)**  
- [ ] Anforderungen & Datenquellen finalisieren (Woche 1)  
- [ ] Log-Collector implementieren (ingest-adapter für Jobs/IDocs/RFCs) (Woche 2)  
- [ ] Baseline Anomalie-Detektor (Regel + ML-Proof-of-Concept) (Woche 3)  
- [ ] Ursachenanalyse-Modul + Vorschlagsengine (Woche 4)  
- [ ] Human-in-the-Loop UI (Freigabe / Feedback) (Woche 5)  
- [ ] Ticket-Integration (Jira/ServiceNow) + Testcases (Woche 6)  
- [ ] Eval & Dokumentation, DSGVO/Governance Check (Woche 7)

**Abhängigkeiten**  
- Zugang zu SAP-Logs / Test-System oder Log-Export.  
- Ticketing-Account (Jira/ServiceNow) mit API-Zugang.  
- GPU/Cloud Ressourcen für ML-Proof-of-Concept (falls nötig).

**Schätzung**  
~4–8 Wochen (MVP, 1–2 Personen, abhängig von Datenqualität & Zugängen).

**Labels / Meta**  
feature,sap,ml,human-in-the-loop,backend,priority:high,MVP

**Assignee**  
@$Assignee
"@

# Build payload
$payloadObject = @{
  title     = $Title
  body      = $issueBody
  labels    = @("feature","sap","ml","human-in-the-loop","backend","priority:high","MVP")
  assignees = @($Assignee)
}

$payload = $payloadObject | ConvertTo-Json -Depth 6

$uri = "https://api.github.com/repos/$Owner/$Repo/issues"
$headers = @{
  Authorization = "token $Token"
  "User-Agent"  = "$Owner-CreateIssueScript"
  Accept        = "application/vnd.github+json"
}

try {
  Write-Host "Erstelle Issue in $Owner/$Repo..." -ForegroundColor Cyan
  $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $payload -ContentType "application/json"
  Write-Host "Issue erstellt: $($response.html_url)" -ForegroundColor Green

  # Option: im Browser öffnen
  if ($PSVersionTable.PSVersion.Major -ge 3) {
    $open = Read-Host "Öffnen im Browser? (j/n)"
    if ($open -match '^[jJ]') { Start-Process $response.html_url }
  }
}
catch {
  Write-Error "Fehler beim Erstellen des Issues: $($_.Exception.Message)"
  if ($_.ErrorDetails) {
    Write-Host "Details:"; Write-Host $_.ErrorDetails
  }
  exit 1
}
