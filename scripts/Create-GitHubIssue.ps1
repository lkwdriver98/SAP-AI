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
  [string]$Title = "MVP: SmartOps AI â€” Automatic issue detection & ticketing for SAP with Human-in-the-Loop",
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
Aufbau eines MVP fÃ¼r SmartOps AI: Automatische Erkennung...
(gekÃ¼rzt fÃ¼r Demo - fÃ¼lle ggf. aus)
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
