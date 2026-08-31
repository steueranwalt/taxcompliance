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
    # Kein -Force: der Parameter ist in PnP.PowerShell >= 3.x veraltet und loest
    # dort einen Entfernen-und-neu-Hinzufuegen-Zyklus aus. Beobachtet auf einem
    # Live-Tenant: das Feature war aktiv, "Enable-PnPFeature ... -Force" schlug
    # mit "not installed in this farm, and cannot be added to this scope" fehl
    # UND deaktivierte das Feature dabei. Ohne -Force ist Aktivieren eines
    # bereits aktiven Features ein No-Op statt eines Entfernungsversuchs.
    Enable-PnPFeature -Scope Site -Identity $script:DocumentSetsFeatureId
    Write-Ok "Feature aktiviert."
}

# --- 2. Basis-Inhaltstyp pruefen -----------------------------------------
# Reiner Lesezugriff, deshalb unabhaengig von -WhatIf mit vollen Versuchen:
# nach Aktivierung braucht SharePoint einen Moment, bis 0x0120D520 im
# Websitesammlungs-Katalog auftaucht. Ein Feature, das laut Get-PnPFeature
# schon aktiv war (nicht erst hier aktiviert wurde), kann trotzdem ohne
# Inhaltstyp dastehen, wenn die Provisionierung frueher nicht durchlief -
# das ist kein Timing-Fall, den Wiederholen behebt, sondern ein blockierender
# Befund, der IMMER gemeldet wird, auch unter -WhatIf.
$docSetBase = $null
foreach ($attempt in 1..6) {
    $docSetBase = Get-PnPContentType -Identity $script:CtIdDocumentSet -ErrorAction SilentlyContinue
    if ($docSetBase) { break }
    Start-Sleep -Seconds 5
}

if ($docSetBase) {
    Write-Ok "Basis-Inhaltstyp vorhanden: $($docSetBase.Name) ($script:CtIdDocumentSet)"
}
else {
    throw "Basis-Inhaltstyp $script:CtIdDocumentSet nicht gefunden, obwohl das Feature aktiv ist. NICHT -Force verwenden (siehe README, Abschnitt 'Bekannte Falle: -Force bei Enable/Disable-PnPFeature'). Neu aktivieren ueber die native SharePoint-Oberflaeche: <Site-URL>/_layouts/15/ManageFeatures.aspx?Scope=Site -> 'Document Sets' aktivieren."
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
