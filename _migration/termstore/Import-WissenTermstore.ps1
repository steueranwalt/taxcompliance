<#
.SYNOPSIS
  Importiert die Termstore-Gruppe "Wissen" (4 Termsets) in den Tenant transferpricingdocs.

.DESCRIPTION
  - Legt Term Group "Wissen" an (falls fehlend)
  - Importiert Hierarchien via Import-PnPTaxonomy (CSV mit | Trenner)
  - Setzt EN/FR Labels aus labels-de-en-fr.csv (best effort)

.NOTES
  Voraussetzung: PnP.PowerShell 2.x+
  Rolle: Term Store Administrator ODER SharePoint Administrator

.EXAMPLE
  Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive
  .\Import-WissenTermstore.ps1

.EXAMPLE
  .\Import-WissenTermstore.ps1 -SiteUrl "https://transferpricingdocs.sharepoint.com/sites/wissen" -Connect
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://transferpricingdocs.sharepoint.com/sites/wissen",
    [string]$TermGroupName = "Wissen",
    [string]$DataDir = $PSScriptRoot,
    [switch]$Connect,
    [switch]$SkipLabels,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-PnPModule {
    $mod = Get-Module -ListAvailable -Name PnP.PowerShell | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $mod) {
        throw "PnP.PowerShell fehlt. Installieren: Install-Module PnP.PowerShell -Scope CurrentUser"
    }
    Import-Module PnP.PowerShell -ErrorAction Stop
    Write-Host "PnP.PowerShell $($mod.Version)" -ForegroundColor DarkGray
}

function Connect-WissenSite {
    param([string]$Url)
    Write-Host "Verbinde: $Url" -ForegroundColor Cyan
    try {
        Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
    }
    catch {
        Write-Warning "Interactive fehlgeschlagen ($($_.Exception.Message)). Versuche DeviceLogin…"
        Connect-PnPOnline -Url $Url -DeviceLogin -ErrorAction Stop
    }
    $ctx = Get-PnPContext
    Write-Host "Verbunden als Kontext-Web: $($ctx.Url)" -ForegroundColor Green
}

function Ensure-TermGroup {
    param([string]$Name)
    $g = Get-PnPTermGroup -Identity $Name -ErrorAction SilentlyContinue
    if (-not $g) {
        if ($WhatIf) {
            Write-Host "[WhatIf] New-PnPTermGroup $Name"
            return
        }
        Write-Host "Lege Term Group an: $Name"
        New-PnPTermGroup -Name $Name | Out-Null
    }
    else {
        Write-Host "Term Group vorhanden: $Name"
    }
}

function Import-TaxonomyFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Datei fehlt: $Path"
    }
    Write-Host "Import: $(Split-Path $Path -Leaf)" -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "[WhatIf] Import-PnPTaxonomy -Path $Path"
        return
    }
    Import-PnPTaxonomy -Path $Path -ErrorAction Stop
}

function Set-MultilingualLabels {
    param([string]$LabelsPath, [string]$GroupName)

    if (-not (Test-Path -LiteralPath $LabelsPath)) {
        Write-Warning "Labels-Datei fehlt, überspringe: $LabelsPath"
        return
    }

    $rows = Import-Csv -LiteralPath $LabelsPath -Delimiter ";"
    $applied = 0
    $skipped = 0

    foreach ($row in $rows) {
        $termSetName = $row.TermSet
        $termPathInSet = $row.TermPath
        $termName = $row.DE
        if ([string]::IsNullOrWhiteSpace($termSetName) -or [string]::IsNullOrWhiteSpace($termName)) {
            $skipped++
            continue
        }

        try {
            $term = Get-PnPTerm -TermGroup $GroupName -TermSet $termSetName -Identity $termName -Recursive -ErrorAction Stop
            if ($term -is [array]) {
                $needle = ($termPathInSet -replace "\|", ";")
                $term = $term | Where-Object {
                    ($_.Path -replace "/", ";") -like "*$needle*" -or $_.Name -eq $termName
                } | Select-Object -First 1
            }
            if (-not $term) {
                $skipped++
                continue
            }

            if ($WhatIf) {
                Write-Host "[WhatIf] Labels $($term.Name): EN=$($row.EN) FR=$($row.FR)"
                $applied++
                continue
            }

            if ($row.EN) {
                Set-PnPTerm -Identity $term -Lcid 1033 -Name $row.EN -ErrorAction SilentlyContinue | Out-Null
            }
            if ($row.FR) {
                Set-PnPTerm -Identity $term -Lcid 1036 -Name $row.FR -ErrorAction SilentlyContinue | Out-Null
            }
            $applied++
        }
        catch {
            Write-Verbose "Label skip ${termSetName}/${termPathInSet}: $($_.Exception.Message)"
            $skipped++
        }
    }

    Write-Host "Labels: angewendet≈$applied übersprungen≈$skipped" -ForegroundColor DarkGray
}

# --- main ---
Assert-PnPModule

if ($Connect) {
    Connect-WissenSite -Url $SiteUrl
}

try {
    $null = Get-PnPContext
}
catch {
    throw "Keine PnP-Verbindung. Zuerst: Connect-PnPOnline -Url '$SiteUrl' -Interactive   ODER   -Connect"
}

Ensure-TermGroup -Name $TermGroupName

$files = @(
    "rechtsgebiet.csv",
    "rechtsordnung.csv",
    "schlagworte.csv",
    "dokumenttyp.csv"
)

foreach ($f in $files) {
    Import-TaxonomyFile -Path (Join-Path $DataDir $f)
}

if (-not $SkipLabels) {
    Set-MultilingualLabels -LabelsPath (Join-Path $DataDir "labels-de-en-fr.csv") -GroupName $TermGroupName
}

Write-Host ""
Write-Host "Fertig. Nächste Schritte:" -ForegroundColor Green
Write-Host "  1. SharePoint Admin Center → Content services → Term store → Gruppe 'Wissen' prüfen"
Write-Host "  2. Bibliothek Wissen: Spalten anlegen (Managed Metadata) und an die 4 Termsets binden"
Write-Host "     Empfohlen: Rechtsgebiet (multi), Rechtsordnung (multi), Dokumenttyp (single), Schlagworte (multi)"
