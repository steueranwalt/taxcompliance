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

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext }
catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV fehlt: $CsvPath – zuerst python extract_wissen_metadata.py ausführen oder Datei laden."
}

$list = Get-ListOrThrow -Name $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

$rows = Import-Csv -LiteralPath $CsvPath -Delimiter ";"
if ($Limit -gt 0) { $rows = $rows | Select-Object -First $Limit }
Write-Host "CSV-Zeilen: $($rows.Count)" -ForegroundColor Cyan

# Index SharePoint files under Wissen/
Write-Host "Lade Listeneinträge unter '$FolderPrefix' …" -ForegroundColor Cyan
$items = Get-PnPListItem -List $list -PageSize 2000 -Fields "Id","FileLeafRef","FileRef","FileDirRef","WissenJahr","WissenAutor","WissenWerk","WissenSeite","WissenFundstelle" |
    Where-Object { $_.FieldValues.FileRef -and ($_.FieldValues.FileRef -like "*/$FolderPrefix/*" -or $_.FieldValues.FileDirRef -like "*/$FolderPrefix*") }

Write-Host "SP-Dateien unter $FolderPrefix : $($items.Count)" -ForegroundColor DarkGray

# Map by FileLeafRef (and disambiguate by ending path)
$byName = @{}
foreach ($it in $items) {
    $name = $it.FieldValues.FileLeafRef
    if (-not $byName.ContainsKey($name)) { $byName[$name] = New-Object System.Collections.Generic.List[object] }
    $byName[$name].Add($it)
}

$updated = 0
$skipped = 0
$missing = 0
$errors = 0

foreach ($row in $rows) {
    $leaf = Normalize $row.FileLeafRef
    if (-not $leaf) { $skipped++; continue }

    $candidates = @()
    if ($byName.ContainsKey($leaf)) { $candidates = @($byName[$leaf]) }

    $item = $null
    if ($candidates.Count -eq 1) {
        $item = $candidates[0]
    }
    elseif ($candidates.Count -gt 1) {
        $needle = (Normalize $row.ServerRelativePath) -replace "^Wissen/", "" -replace "/", "\\"
        $item = $candidates | Where-Object {
            ($_.FieldValues.FileRef -replace "/", "\") -like "*$($needle -replace '\\','\')*" -or
            ($_.FieldValues.FileRef -replace "\\", "/") -like ("*/" + (($row.ServerRelativePath -replace "^Wissen/","")))
        } | Select-Object -First 1
        if (-not $item) { $item = $candidates[0] }
    }

    if (-not $item) {
        $missing++
        continue
    }

    if ($OnlyEmpty) {
        $fv = $item.FieldValues
        if ($fv.WissenJahr -or $fv.WissenAutor -or $fv.WissenWerk -or $fv.WissenFundstelle) {
            $skipped++
            continue
        }
    }

    $values = @{}
    if (Normalize $row.Jahr) {
        $y = 0
        if ([int]::TryParse((Normalize $row.Jahr), [ref]$y)) { $values["WissenJahr"] = $y }
    }
    if (Normalize $row.Autor) { $values["WissenAutor"] = (Normalize $row.Autor) }
    if (Normalize $row.Werk) { $values["WissenWerk"] = (Normalize $row.Werk) }
    if (Normalize $row.Seite) { $values["WissenSeite"] = (Normalize $row.Seite) }
    if (Normalize $row.Fundstelle) { $values["WissenFundstelle"] = (Normalize $row.Fundstelle) }

    if ($values.Count -eq 0 -and $SkipTaxonomy) {
        $skipped++
        continue
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Id=$($item.Id) $($item.FieldValues.FileLeafRef) => $($values.Keys -join ',')"
        $updated++
        continue
    }

    try {
        if ($values.Count -gt 0) {
            Set-PnPListItem -List $list -Identity $item.Id -Values $values -UpdateType SystemUpdate | Out-Null
        }

        if (-not $SkipTaxonomy) {
            # Taxonomy by label (best effort)
            if (Normalize $row.Dokumenttyp) {
                try {
                    Set-PnPListItem -List $list -Identity $item.Id -Values @{ "WissenDokumenttyp" = (Normalize $row.Dokumenttyp) } -UpdateType SystemUpdate | Out-Null
                } catch { }
            }
            if (Normalize $row.Rechtsordnung) {
                try {
                    Set-PnPListItem -List $list -Identity $item.Id -Values @{ "WissenRechtsordnung" = (Normalize $row.Rechtsordnung) } -UpdateType SystemUpdate | Out-Null
                } catch { }
            }
            if (Normalize $row.Rechtsgebiet) {
                try {
                    Set-PnPListItem -List $list -Identity $item.Id -Values @{ "WissenRechtsgebiet" = (Normalize $row.Rechtsgebiet) } -UpdateType SystemUpdate | Out-Null
                } catch { }
            }
        }
        $updated++
        if (($updated % 50) -eq 0) { Write-Host "… updated=$updated" -ForegroundColor DarkGray }
    }
    catch {
        Write-Warning "Id=$($item.Id) $($item.FieldValues.FileLeafRef): $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing errors=$errors" -ForegroundColor Green
Write-Host "Hinweis: missingOnSp = CSV-Datei nicht unter Shared Documents/$FolderPrefix gefunden."
