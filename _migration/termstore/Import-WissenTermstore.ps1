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
    [switch]$Additive = $true,
    [switch]$SkipSnapshot,
    [int]$ChunkSize = 25,
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

function Export-TermstoreSnapshot {
    param([string]$GroupName)

    $outDir = Join-Path ([System.IO.Path]::GetTempPath()) ("termstore-snapshot-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    $group = Get-PnPTermGroup -Identity $GroupName -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Host "Snapshot: Gruppe '$GroupName' noch nicht vorhanden." -ForegroundColor DarkGray
        return
    }

    $sets = Get-PnPTermSet -TermGroup $group -ErrorAction SilentlyContinue
    $sets | Select-Object Id, Name, Description | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $outDir "termsets.csv")

    $rows = @()
    foreach ($set in $sets) {
        $terms = Get-PnPTerm -TermGroup $GroupName -TermSet $set.Name -Recursive -ErrorAction SilentlyContinue
        foreach ($term in $terms) {
            $rows += [PSCustomObject]@{
                TermSet      = $set.Name
                TermId       = $term.Id
                Name         = $term.Name
                Path         = $term.Path
                IsDeprecated = $term.IsDeprecated
            }
        }
    }
    $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $outDir "terms-flat.csv")
    Write-Host "Snapshot geschrieben: $outDir" -ForegroundColor DarkGray
}

function Normalize-Path {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    return (($Path -replace "/", ";") -replace "\|", ";").Trim()
}

function Get-MissingLines {
    param(
        [string]$TaxonomyFile,
        [string]$GroupName
    )

    $lines = Get-Content -LiteralPath $TaxonomyFile | Where-Object { $_ -match '\S' }
    $missing = @()

    $bySet = @{}
    foreach ($line in $lines) {
        $cols = $line.Split("|")
        if ($cols.Count -lt 3) { continue }
        $setName = $cols[1].Trim()
        if (-not $bySet.ContainsKey($setName)) { $bySet[$setName] = @() }
        $bySet[$setName] += $line
    }

    foreach ($setName in $bySet.Keys) {
        $existing = Get-PnPTerm -TermGroup $GroupName -TermSet $setName -Recursive -ErrorAction SilentlyContinue
        $existingPaths = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($term in $existing) {
            [void]$existingPaths.Add((Normalize-Path $term.Path))
        }

        foreach ($line in $bySet[$setName]) {
            $cols = $line.Split("|")
            $segments = $cols[2..($cols.Count - 1)]
            $desiredPath = Normalize-Path ($segments -join ";")
            if (-not $existingPaths.Contains($desiredPath)) {
                $missing += $line
            }
        }
    }
    return $missing
}

function Import-InChunks {
    param(
        [string]$TaxonomyFile,
        [int]$ChunkSize = 25
    )
    $lines = Get-Content -LiteralPath $TaxonomyFile | Where-Object { $_ -match '\S' }
    if ($lines.Count -eq 0) {
        Write-Host "Nichts zu importieren: $(Split-Path $TaxonomyFile -Leaf)" -ForegroundColor DarkGray
        return
    }
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "wissen-termstore-import"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $part = 0
    for ($i = 0; $i -lt $lines.Count; $i += $ChunkSize) {
        $part++
        $end = [Math]::Min($i + $ChunkSize - 1, $lines.Count - 1)
        $chunk = $lines[$i..$end]
        $partFile = Join-Path $tmpDir ("{0}-part-{1}.csv" -f ([IO.Path]::GetFileNameWithoutExtension($TaxonomyFile)), $part)
        $chunk | Set-Content -LiteralPath $partFile -Encoding UTF8
        Import-TaxonomyFile -Path $partFile
    }
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

if (-not $SkipSnapshot) {
    Export-TermstoreSnapshot -GroupName $TermGroupName
}

$files = @(
    "rechtsgebiet.csv",
    "rechtsordnung.csv",
    "schlagworte.csv",
    "dokumenttyp.csv"
)

foreach ($f in $files) {
    $path = Join-Path $DataDir $f
    if ($Additive) {
        $missing = Get-MissingLines -TaxonomyFile $path -GroupName $TermGroupName
        if ($missing.Count -eq 0) {
            Write-Host "Keine fehlenden Terme in $f" -ForegroundColor DarkGray
            continue
        }
        $tmpMissing = Join-Path ([System.IO.Path]::GetTempPath()) ("missing-" + $f)
        $missing | Set-Content -LiteralPath $tmpMissing -Encoding UTF8
        Write-Host "Additiv importiere $($missing.Count) Zeilen aus $f" -ForegroundColor Cyan
        Import-InChunks -TaxonomyFile $tmpMissing -ChunkSize $ChunkSize
    }
    else {
        Import-InChunks -TaxonomyFile $path -ChunkSize $ChunkSize
    }
}

if (-not $SkipLabels) {
    Set-MultilingualLabels -LabelsPath (Join-Path $DataDir "labels-de-en-fr.csv") -GroupName $TermGroupName
}

Write-Host ""
Write-Host "Fertig. Nächste Schritte:" -ForegroundColor Green
Write-Host "  1. SharePoint Admin Center → Content services → Term store → Gruppe 'Wissen' prüfen"
Write-Host "  2. Bibliothek Wissen: Spalten anlegen (Managed Metadata) und an die 4 Termsets binden"
Write-Host "     Empfohlen: Rechtsgebiet (multi), Rechtsordnung (multi), Dokumenttyp (single), Schlagworte (multi)"
