<#
.SYNOPSIS
  Gemeinsame Hilfsfunktionen fuer die Dokumentenmappen-Migration.

.DESCRIPTION
  Wird von den Skripten in diesem Ordner via Dot-Sourcing geladen:
      . "$PSScriptRoot\_Common.ps1"

  Enthaelt Verbindungsaufbau, Bibliotheks-Aufloesung und die
  Content-Type-IDs, die fuer Dokumentenmappen relevant sind.
#>

Set-StrictMode -Version Latest

# Feature "Dokumentenmappen" (Document Sets), Scope = Site (Websitesammlung)
$script:DocumentSetsFeatureId = "3bae86a2-776d-499d-9db8-fa4cd926e061"

# Basis-Content-Types
$script:CtIdFolder      = "0x0120"      # Ordner
$script:CtIdDocumentSet = "0x0120D520"  # Dokumentenmappe

# Feldwert, der einen Ordner in der UI als Dokumentenmappe rendert
$script:DocSetHtmlFileType = "SharePoint.DocumentSet"

function Connect-Wissen {
    <#
      Verbindet zur Site, wenn -Connect gesetzt ist. Ohne -Connect wird eine
      bereits bestehende PnP-Verbindung erwartet (gleiches Muster wie in
      _migration/termstore).
    #>
    param(
        [switch]$Connect,
        [string]$SiteUrl,
        [switch]$Interactive,
        [string]$ClientId,
        [string]$Tenant
    )

    if ($Connect) {
        $params = @{ Url = $SiteUrl }
        if ($ClientId) { $params.ClientId = $ClientId }
        if ($Tenant) { $params.Tenant = $Tenant }
        if ($Interactive) { $params.Interactive = $true } else { $params.DeviceLogin = $true }
        Connect-PnPOnline @params
    }

    try { $null = Get-PnPContext }
    catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausfuehren oder -Connect nutzen." }
}

function Get-WissenList {
    <#
      Loest die Zielbibliothek auf. Akzeptiert Titel, Id oder ServerRelativeUrl
      und faellt auf die ueblichen Aliase der Standardbibliothek zurueck
      (Freigegebene Dokumente / Shared Documents / Dokumente / Documents).
    #>
    param([Parameter(Mandatory)][string]$Name)

    $aliases = @("dokumente", "documents", "freigegebene dokumente", "shared documents", "wissen")
    $needle  = $Name.Trim().ToLowerInvariant()

    foreach ($candidate in @($Name, "Freigegebene Dokumente", "Shared Documents", "Dokumente", "Documents")) {
        $list = Get-PnPList -Identity $candidate -ErrorAction SilentlyContinue
        if ($list -and ($candidate -eq $Name -or $needle -in $aliases)) { return $list }
    }

    $libs  = @(Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 })
    $match = $libs | Where-Object { $_.Title.ToLowerInvariant() -eq $needle } | Select-Object -First 1
    if (-not $match -and $needle -in $aliases) {
        $match = $libs | Where-Object { $_.Title -in @("Freigegebene Dokumente", "Shared Documents", "Dokumente", "Documents") } | Select-Object -First 1
    }
    if ($match) { return (Get-PnPList -Identity $match.Id) }

    $available = ($libs | ForEach-Object { $_.Title }) -join ", "
    throw "Bibliothek '$Name' nicht gefunden. Verfuegbare Dokumentbibliotheken: $available"
}

function Get-ListRootUrl {
    <# Server-relative URL des Bibliotheks-Wurzelordners, ohne Trailing Slash. #>
    param([Parameter(Mandatory)]$List)

    $root = Get-PnPProperty -ClientObject $List -Property RootFolder
    return $root.ServerRelativeUrl.TrimEnd('/')
}

function Write-Step   { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Ok     { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Skip   { param([string]$Message) Write-Host $Message -ForegroundColor DarkGray }
function Write-Warn2  { param([string]$Message) Write-Host $Message -ForegroundColor Yellow }
