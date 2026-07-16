<#
.SYNOPSIS
  Legt Managed-Metadata-Spalten in der Bibliothek Wissen an (4 Termsets).

.DESCRIPTION
  Bindet Spalten an Termstore-Gruppe "Wissen":
  - Rechtsgebiet (Mehrfach)
  - Rechtsordnung (Mehrfach)
  - Dokumenttyp (Einzel)
  - Schlagworte (Mehrfach)

  Idempotent: vorhandene Spalten werden übersprungen.

.EXAMPLE
  $clientId = "c77bfeb7-7624-497f-85d7-e509c5ec9dbc"
  $tenant   = "transferpricingdocs.onmicrosoft.com"
  Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId $clientId -Tenant $tenant
  .\Add-WissenLibraryColumns.ps1

.EXAMPLE
  .\Add-WissenLibraryColumns.ps1 -Connect -Interactive -ClientId "..." -Tenant "transferpricingdocs.onmicrosoft.com" -LibraryName "Freigegebene Dokumente"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://transferpricingdocs.sharepoint.com/sites/wissen",
    [string]$LibraryName = "Wissen",
    [string]$TermGroupName = "Wissen",
    [string]$FieldGroup = "Wissen Metadaten",
    [switch]$Connect,
    [switch]$Interactive,
    [string]$ClientId,
    [string]$Tenant,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Columns = @(
    @{
        DisplayName  = "Rechtsgebiet"
        InternalName = "WissenRechtsgebiet"
        TermSet      = "Rechtsgebiet"
        Multi        = $true
        Required     = $false
    },
    @{
        DisplayName  = "Rechtsordnung"
        InternalName = "WissenRechtsordnung"
        TermSet      = "Rechtsordnung"
        Multi        = $true
        Required     = $false
    },
    @{
        DisplayName  = "Dokumenttyp"
        InternalName = "WissenDokumenttyp"
        TermSet      = "Dokumenttyp"
        Multi        = $false
        Required     = $false
    },
    @{
        DisplayName  = "Schlagworte"
        InternalName = "WissenSchlagworte"
        TermSet      = "Schlagworte"
        Multi        = $true
        Required     = $false
    }
)

function Connect-Wissen {
    if (-not $Connect) { return }
    $params = @{ Url = $SiteUrl }
    if ($ClientId) { $params.ClientId = $ClientId }
    if ($Tenant) { $params.Tenant = $Tenant }
    if ($Interactive) { $params.Interactive = $true } else { $params.DeviceLogin = $true }
    Connect-PnPOnline @params
}

function Get-ListOrThrow {
    param([string]$Name)
    $list = Get-PnPList -Identity $Name -ErrorAction SilentlyContinue
    if ($list) { return $list }
    throw "Bibliothek '$Name' nicht gefunden. Prüfe Listentitel (z. B. 'Wissen' oder 'Freigegebene Dokumente') und -LibraryName."
}

function Ensure-TaxonomyColumn {
    param(
        $List,
        [hashtable]$Column,
        [string]$GroupName
    )

    $existing = Get-PnPField -List $List -Identity $Column.InternalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Vorhanden: $($Column.DisplayName) ($($Column.InternalName))" -ForegroundColor DarkGray
        return "exists"
    }

    $termSetPath = "$GroupName|$($Column.TermSet)"
    Write-Host "Lege an: $($Column.DisplayName) -> $termSetPath ($(if($Column.Multi){'multi'}else{'single'}))" -ForegroundColor Cyan

    if ($WhatIf) {
        Write-Host "[WhatIf] Add-PnPTaxonomyField $($Column.InternalName)" -ForegroundColor Yellow
        return "whatif"
    }

    $params = @{
        List         = $List
        DisplayName  = $Column.DisplayName
        InternalName = $Column.InternalName
        TermSetPath  = $termSetPath
        Group        = $FieldGroup
    }
    if ($Column.Multi) { $params.Multi = $true }
    if ($Column.Required) { $params.Required = $true }

    Add-PnPTaxonomyField @params | Out-Null
    return "created"
}

# --- main ---
Import-Module PnP.PowerShell -ErrorAction Stop
Connect-Wissen

try { $null = Get-PnPContext }
catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausführen oder -Connect nutzen." }

$list = Get-ListOrThrow -Name $LibraryName
Write-Host "Bibliothek: $($list.Title) (Id=$($list.Id))" -ForegroundColor Green

$group = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction Stop
Write-Host "Term Group: $($group.Name)" -ForegroundColor Green

$stats = @{ created = 0; exists = 0; whatif = 0 }
foreach ($col in $Columns) {
    $set = Get-PnPTermSet -TermGroup $group -Identity $col.TermSet -ErrorAction Stop
    Write-Host "Termset OK: $($set.Name)" -ForegroundColor DarkGray
    $result = Ensure-TaxonomyColumn -List $list -Column $col -GroupName $TermGroupName
    $stats[$result]++
}

Write-Host ""
Write-Host "Fertig. created=$($stats.created) exists=$($stats.exists) whatif=$($stats.whatif)" -ForegroundColor Green
Write-Host "Nächster Schritt: Bibliothek '$($list.Title)' -> Spalten in Standardansicht + ggf. Content Type 'Dokument' prüfen."
