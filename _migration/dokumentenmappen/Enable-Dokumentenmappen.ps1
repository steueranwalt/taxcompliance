<#
.SYNOPSIS
  Schritt 1: Aktiviert das Feature "Dokumentenmappen" (Document Sets) in der
  Websitesammlung und Inhaltstypen-Verwaltung in der Zielbibliothek.

.DESCRIPTION
  Idempotent. Prueft zuerst, ob Feature und Einstellung schon aktiv sind, und
  aendert nur, was fehlt.

  Ohne dieses Feature existiert der Basis-Inhaltstyp "Dokumentenmappe"
  (0x0120D520) in der Websitesammlung nicht und Schritt 2 schlaegt fehl.

.EXAMPLE
  Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive
  .\Enable-Dokumentenmappen.ps1

.EXAMPLE
  .\Enable-Dokumentenmappen.ps1 -Connect -Interactive `
      -SiteUrl "https://obenhaus.sharepoint.com/sites/Wissen" -WhatIf
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://obenhaus.sharepoint.com/sites/Wissen",
    [string]$LibraryName = "Freigegebene Dokumente",
    [switch]$Connect,
    [switch]$Interactive,
    [string]$ClientId,
    [string]$Tenant,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module PnP.PowerShell -ErrorAction Stop
. "$PSScriptRoot\_Common.ps1"

Connect-Wissen -Connect:$Connect -SiteUrl $SiteUrl -Interactive:$Interactive -ClientId $ClientId -Tenant $Tenant

# --- 1. Feature "Dokumentenmappen" ---------------------------------------
$feature = Get-PnPFeature -Scope Site -Identity $script:DocumentSetsFeatureId -ErrorAction SilentlyContinue

if ($feature) {
    Write-Skip "Feature Dokumentenmappen: bereits aktiv ($script:DocumentSetsFeatureId)"
}
elseif ($WhatIf) {
    Write-Warn2 "[WhatIf] Enable-PnPFeature -Scope Site -Identity $script:DocumentSetsFeatureId"
}
else {
    Write-Step "Aktiviere Feature Dokumentenmappen ($script:DocumentSetsFeatureId) ..."
    Enable-PnPFeature -Scope Site -Identity $script:DocumentSetsFeatureId -Force
    Write-Ok "Feature aktiviert."
}

# --- 2. Basis-Inhaltstyp pruefen -----------------------------------------
# Nach Aktivierung braucht SharePoint einen Moment, bis 0x0120D520 im
# Websitesammlungs-Katalog auftaucht.
$docSetBase = $null
foreach ($attempt in 1..6) {
    $docSetBase = Get-PnPContentType -Identity $script:CtIdDocumentSet -ErrorAction SilentlyContinue
    if ($docSetBase) { break }
    if ($WhatIf) { break }
    Start-Sleep -Seconds 5
}

if ($docSetBase) {
    Write-Ok "Basis-Inhaltstyp vorhanden: $($docSetBase.Name) ($script:CtIdDocumentSet)"
}
elseif (-not $WhatIf) {
    throw "Basis-Inhaltstyp $script:CtIdDocumentSet nicht gefunden. Feature-Aktivierung pruefen (Websiteeinstellungen -> Websitesammlungsfeatures -> Dokumentenmappen)."
}

# --- 3. Inhaltstypen-Verwaltung in der Bibliothek ------------------------
$list = Get-WissenList -Name $LibraryName
Write-Ok "Bibliothek: $($list.Title) (Id=$($list.Id))"

if ($list.ContentTypesEnabled) {
    Write-Skip "Inhaltstypen-Verwaltung: bereits aktiviert"
}
elseif ($WhatIf) {
    Write-Warn2 "[WhatIf] Set-PnPList -Identity '$($list.Title)' -EnableContentTypes `$true"
}
else {
    Write-Step "Aktiviere Inhaltstypen-Verwaltung in '$($list.Title)' ..."
    Set-PnPList -Identity $list.Id -EnableContentTypes $true
    Write-Ok "Inhaltstypen-Verwaltung aktiviert."
}

Write-Host ""
Write-Ok "Schritt 1 fertig. Naechster Schritt: .\New-WissenMappeContentType.ps1"
