<#
.SYNOPSIS
  Befüllt Wissen-Spalten in Bibliothek Dokumente aus wissen-metadata-extract.csv.

.DESCRIPTION
  Matcht Dateien unter Shared Documents/Wissen/... per FileLeafRef (+ optional Ordner).
  Setzt: WissenJahr, WissenAutor, WissenWerk, WissenSeite, WissenFundstelle
  und nach Möglichkeit Taxonomie-Labels für Dokumenttyp / Rechtsordnung / Rechtsgebiet.

.EXAMPLE
  Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "c77bfeb7-7624-497f-85d7-e509c5ec9dbc" -Tenant "transferpricingdocs.onmicrosoft.com"
  .\Apply-WissenMetadata.ps1 -CsvPath ".\wissen-metadata-extract.csv" -LibraryName "Shared Documents"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://transferpricingdocs.sharepoint.com/sites/wissen",
    [string]$LibraryName = "Shared Documents",
    [string]$CsvPath = (Join-Path $PSScriptRoot "wissen-metadata-extract.csv"),
    [string]$FolderPrefix = "Wissen",
    [int]$Limit = 0,
    [switch]$WhatIf,
    [switch]$SkipTaxonomy,
    [switch]$OnlyEmpty
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ListOrThrow {
    param([string]$Name)
    foreach ($candidate in @($Name, "Shared Documents", "Dokumente", "Documents")) {
        $list = Get-PnPList -Identity $candidate -ErrorAction SilentlyContinue
        if ($list) { return $list }
    }
    $match = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.Title -eq "Dokumente" } | Select-Object -First 1
    if ($match) { return (Get-PnPList -Identity $match.Id) }
    throw "Bibliothek nicht gefunden: $Name"
}

function Normalize([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return "" }
    return $s.Trim()
}

function Test-HasValue($v) {
    if ($null -eq $v) { return $false }
    if ($v -is [string]) { return -not [string]::IsNullOrWhiteSpace($v) }
    return $true
}

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext }
catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV fehlt: $CsvPath – zuerst python extract_wissen_metadata.py ausführen oder Datei laden."
}

$list = Get-ListOrThrow -Name $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

$rows = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";")
if ($Limit -gt 0) { $rows = @($rows | Select-Object -First $Limit) }
Write-Host "CSV-Zeilen: $($rows.Count)" -ForegroundColor Cyan

Write-Host "Lade Listeneinträge unter '$FolderPrefix' …" -ForegroundColor Cyan
$allItems = @(Get-PnPListItem -List $list -PageSize 2000 -Fields "Id","FileLeafRef","FileRef","FileDirRef","WissenJahr","WissenAutor","WissenWerk","WissenSeite","WissenFundstelle")
$items = @($allItems | Where-Object {
        $_.FieldValues["FileRef"] -and (
            $_.FieldValues["FileRef"] -like "*/$FolderPrefix/*" -or
            $_.FieldValues["FileDirRef"] -like "*/$FolderPrefix*"
        )
    })

Write-Host "SP-Dateien unter $FolderPrefix : $($items.Count)" -ForegroundColor DarkGray

# Map FileLeafRef -> array of list items (plain PowerShell arrays)
$byName = @{}
foreach ($it in $items) {
    $name = [string]$it.FieldValues["FileLeafRef"]
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    if (-not $byName.ContainsKey($name)) {
        $byName[$name] = @()
    }
    $byName[$name] += $it
}

$updated = 0
$skipped = 0
$missing = 0
$errors = 0

foreach ($row in $rows) {
    $leaf = Normalize $row.FileLeafRef
    if (-not $leaf) { $skipped++; continue }

    if (-not $byName.ContainsKey($leaf)) {
        $missing++
        continue
    }

    $candidates = @($byName[$leaf])
    $item = $null
    if ($candidates.Count -eq 1) {
        $item = $candidates[0]
    }
    else {
        $rel = (Normalize $row.ServerRelativePath) -replace "^Wissen/", ""
        $relFwd = $rel -replace "\\", "/"
        $item = @(
            $candidates | Where-Object {
                $fr = ([string]$_.FieldValues["FileRef"]) -replace "\\", "/"
                $fr.EndsWith("/" + $relFwd) -or $fr.Contains("/" + $relFwd)
            }
        ) | Select-Object -First 1
        if (-not $item) { $item = $candidates[0] }
    }

    if (-not $item -or -not $item.Id) {
        $missing++
        continue
    }

    if ($OnlyEmpty) {
        $fv = $item.FieldValues
        if (
            (Test-HasValue $fv["WissenJahr"]) -or
            (Test-HasValue $fv["WissenAutor"]) -or
            (Test-HasValue $fv["WissenWerk"]) -or
            (Test-HasValue $fv["WissenFundstelle"])
        ) {
            $skipped++
            continue
        }
    }

    $values = @{}
    if (Normalize $row.Jahr) {
        $y = 0
        if ([int]::TryParse((Normalize $row.Jahr), [ref]$y)) {
            # Number fields expect Double in CSOM
            $values["WissenJahr"] = [double]$y
        }
    }
    if (Normalize $row.Autor) { $values["WissenAutor"] = [string](Normalize $row.Autor) }
    if (Normalize $row.Werk) { $values["WissenWerk"] = [string](Normalize $row.Werk) }
    if (Normalize $row.Seite) { $values["WissenSeite"] = [string](Normalize $row.Seite) }
    if (Normalize $row.Fundstelle) { $values["WissenFundstelle"] = [string](Normalize $row.Fundstelle) }

    if ($values.Count -eq 0 -and $SkipTaxonomy) {
        $skipped++
        continue
    }

    $itemId = [int]$item.Id

    if ($WhatIf) {
        Write-Host "[WhatIf] Id=$itemId $($item.FieldValues['FileLeafRef']) => $($values.Keys -join ',')"
        $updated++
        continue
    }

    try {
        if ($values.Count -gt 0) {
            Set-PnPListItem -List $list -Identity $itemId -Values $values | Out-Null
        }

        if (-not $SkipTaxonomy) {
            if (Normalize $row.Dokumenttyp) {
                try {
                    Set-PnPListItem -List $list -Identity $itemId -Values @{ "WissenDokumenttyp" = [string](Normalize $row.Dokumenttyp) } | Out-Null
                }
                catch { }
            }
            if (Normalize $row.Rechtsordnung) {
                try {
                    Set-PnPListItem -List $list -Identity $itemId -Values @{ "WissenRechtsordnung" = [string](Normalize $row.Rechtsordnung) } | Out-Null
                }
                catch { }
            }
            if (Normalize $row.Rechtsgebiet) {
                try {
                    Set-PnPListItem -List $list -Identity $itemId -Values @{ "WissenRechtsgebiet" = [string](Normalize $row.Rechtsgebiet) } | Out-Null
                }
                catch { }
            }
        }
        $updated++
        if (($updated % 50) -eq 0) { Write-Host "… updated=$updated" -ForegroundColor DarkGray }
    }
    catch {
        Write-Warning "Id=$itemId $($item.FieldValues['FileLeafRef']): $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing errors=$errors" -ForegroundColor Green
Write-Host "Hinweis: missingOnSp = CSV-Datei nicht unter Shared Documents/$FolderPrefix gefunden."
