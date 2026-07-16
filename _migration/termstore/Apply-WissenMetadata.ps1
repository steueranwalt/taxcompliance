<#
.SYNOPSIS
  Befüllt Wissen-Spalten in Bibliothek Dokumente aus wissen-metadata-extract.csv.

.EXAMPLE
  Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "c77bfeb7-7624-497f-85d7-e509c5ec9dbc" -Tenant "transferpricingdocs.onmicrosoft.com"
  .\Apply-WissenMetadata.ps1 -CsvPath ".\wissen-metadata-extract.csv" -LibraryName "Shared Documents" -Limit 20
#>
[CmdletBinding()]
param(
    [string]$LibraryName = "Shared Documents",
    [string]$CsvPath = (Join-Path $PSScriptRoot "wissen-metadata-extract.csv"),
    [string]$FolderPrefix = "Wissen",
    [int]$Limit = 0,
    [switch]$WhatIf,
    [switch]$ApplyTaxonomy,
    [switch]$OnlyEmpty
)

$ErrorActionPreference = "Stop"

function Get-ListOrThrow([string]$Name) {
    foreach ($candidate in @($Name, "Shared Documents", "Dokumente", "Documents")) {
        $list = Get-PnPList -Identity $candidate -ErrorAction SilentlyContinue
        if ($list) { return $list }
    }
    throw "Bibliothek nicht gefunden: $Name"
}

function Get-FieldString($fieldValues, [string]$name) {
    try {
        if ($null -eq $fieldValues) { return "" }
        if (-not $fieldValues.ContainsKey($name)) { return "" }
        $v = $fieldValues[$name]
        if ($null -eq $v) { return "" }
        return [string]$v
    }
    catch { return "" }
}

function Test-HasValue($fieldValues, [string]$name) {
    $s = Get-FieldString $fieldValues $name
    if (-not [string]::IsNullOrWhiteSpace($s)) { return $true }
    try {
        if ($fieldValues.ContainsKey($name) -and $null -ne $fieldValues[$name] -and "$($fieldValues[$name])" -ne "") {
            return $true
        }
    }
    catch { }
    return $false
}

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext }
catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV fehlt: $CsvPath"
}

$list = Get-ListOrThrow $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

$rows = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";")
if ($Limit -gt 0) {
    $rows = @($rows | Select-Object -First $Limit)
}
Write-Host "CSV-Zeilen: $($rows.Count)" -ForegroundColor Cyan

Write-Host "Lade Listeneinträge unter '$FolderPrefix' …" -ForegroundColor Cyan
# Nur Dateien (FSObjType=0), keine Ordner
$items = @(Get-PnPListItem -List $list -PageSize 2000 -Fields "Id","FSObjType","FileLeafRef","FileRef","FileDirRef","WissenJahr","WissenAutor","WissenWerk","WissenSeite","WissenFundstelle" |
    Where-Object {
        $fr = Get-FieldString $_.FieldValues "FileRef"
        $fs = 0
        try { $fs = [int]$_.FieldValues["FSObjType"] } catch { $fs = 0 }
        ($fs -eq 0) -and ($fr -like "*/$FolderPrefix/*")
    })

Write-Host "SP-Dateien unter $FolderPrefix : $($items.Count)" -ForegroundColor DarkGray

$byName = @{}
foreach ($it in $items) {
    $name = Get-FieldString $it.FieldValues "FileLeafRef"
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    if (-not $byName.ContainsKey($name)) {
        $byName[$name] = [System.Collections.Generic.List[object]]::new()
    }
    [void]$byName[$name].Add($it)
}

$updated = 0
$skipped = 0
$missing = 0
$errors = 0

for ($i = 0; $i -lt $rows.Count; $i++) {
    $row = $rows[$i]
    $leaf = ("{0}" -f $row.FileLeafRef).Trim()
    if ([string]::IsNullOrWhiteSpace($leaf)) {
        $skipped++
        continue
    }

    if (-not $byName.ContainsKey($leaf)) {
        $missing++
        continue
    }

    $candidateList = $byName[$leaf]
    $item = $null
    if ($candidateList.Count -eq 1) {
        $item = $candidateList[0]
    }
    else {
        $rel = ("{0}" -f $row.ServerRelativePath).Trim() -replace "^Wissen/", "" -replace "\\", "/"
        foreach ($cand in $candidateList) {
            $fr = (Get-FieldString $cand.FieldValues "FileRef") -replace "\\", "/"
            if ($rel -and ($fr.EndsWith("/$rel") -or $fr.Contains("/$rel"))) {
                $item = $cand
                break
            }
        }
        if ($null -eq $item) { $item = $candidateList[0] }
    }

    $itemId = 0
    try { $itemId = [int]$item.Id } catch {
        $errors++
        Write-Warning "Ungültige Item-Id für $leaf"
        continue
    }

    if ($OnlyEmpty) {
        if (
            (Test-HasValue $item.FieldValues "WissenJahr") -or
            (Test-HasValue $item.FieldValues "WissenAutor") -or
            (Test-HasValue $item.FieldValues "WissenWerk") -or
            (Test-HasValue $item.FieldValues "WissenFundstelle")
        ) {
            $skipped++
            continue
        }
    }

    $values = @{}
    $jahrText = ("{0}" -f $row.Jahr).Trim()
    if ($jahrText -match '^\d{4}$') {
        $values["WissenJahr"] = [double]::Parse($jahrText)
    }
    $autor = ("{0}" -f $row.Autor).Trim()
    $werk = ("{0}" -f $row.Werk).Trim()
    $seite = ("{0}" -f $row.Seite).Trim()
    $fund = ("{0}" -f $row.Fundstelle).Trim()
    if ($autor) { $values["WissenAutor"] = $autor }
    if ($werk) { $values["WissenWerk"] = $werk }
    if ($seite) { $values["WissenSeite"] = $seite }
    if ($fund) { $values["WissenFundstelle"] = $fund }

    if ($values.Count -eq 0 -and -not $ApplyTaxonomy) {
        $skipped++
        continue
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Id=$itemId $leaf => $($values.Keys -join ',')"
        $updated++
        continue
    }

    try {
        if ($values.Count -gt 0) {
            # Ein Feld nach dem anderen – vermeidet Typkonflikte in Batch-Hashtables
            foreach ($key in @($values.Keys)) {
                $one = @{}
                $one[$key] = $values[$key]
                Set-PnPListItem -List $list -Identity $itemId -Values $one -ErrorAction Stop | Out-Null
            }
        }

        if ($ApplyTaxonomy) {
            $docType = ("{0}" -f $row.Dokumenttyp).Trim()
            $ordnung = ("{0}" -f $row.Rechtsordnung).Trim()
            $gebiet = ("{0}" -f $row.Rechtsgebiet).Trim()
            if ($docType -and (Get-Command Set-PnPTaxonomyFieldValue -ErrorAction SilentlyContinue)) {
                try { Set-PnPTaxonomyFieldValue -List $list -Identity $itemId -InternalName "WissenDokumenttyp" -TermLabel $docType -ErrorAction Stop | Out-Null } catch { }
            }
            if ($ordnung -and (Get-Command Set-PnPTaxonomyFieldValue -ErrorAction SilentlyContinue)) {
                try { Set-PnPTaxonomyFieldValue -List $list -Identity $itemId -InternalName "WissenRechtsordnung" -TermLabel $ordnung -ErrorAction Stop | Out-Null } catch { }
            }
            if ($gebiet -and (Get-Command Set-PnPTaxonomyFieldValue -ErrorAction SilentlyContinue)) {
                try { Set-PnPTaxonomyFieldValue -List $list -Identity $itemId -InternalName "WissenRechtsgebiet" -TermLabel $gebiet -ErrorAction Stop | Out-Null } catch { }
            }
        }

        $updated++
        if ($updated -le 5 -or ($updated % 50) -eq 0) {
            Write-Host "OK Id=$itemId $leaf" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "Id=$itemId $leaf : $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing errors=$errors" -ForegroundColor Green
