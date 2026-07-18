<#
.SYNOPSIS
  Befüllt Jahr/Autor/Werk/Seite/Fundstelle/Titel/Aktenzeichen aus CSV (einfacher, robuster Lauf).

.DESCRIPTION
  -OnlyEmpty prüft pro Feld (nicht pauschal die ganze Datei).
  Fehlende SharePoint-Dateien werden am Ende gelistet und in eine Report-Datei geschrieben.

.EXAMPLE
  .\Apply-WissenMetadata.ps1 -CsvPath .\wissen-metadata-extract.csv -Limit 20

.EXAMPLE
  .\Apply-WissenMetadata.ps1 -CsvPath .\wissen-metadata-extract.csv -OnlyEmpty -IncludeYear
#>
[CmdletBinding()]
param(
    [string]$LibraryName = "Shared Documents",
    [string]$CsvPath = (Join-Path $PSScriptRoot "wissen-metadata-extract.csv"),
    [string]$FolderPrefix = "Wissen",
    [string]$MissingReportPath = (Join-Path (Get-Location) "wissen-metadata-missing-on-sp.csv"),
    [int]$Limit = 0,
    [switch]$WhatIf,
    [switch]$OnlyEmpty,
    [switch]$IncludeYear
)

$ErrorActionPreference = "Continue"

function Get-DocLib {
    param([string]$Name)
    foreach ($c in @($Name, "Shared Documents", "Dokumente", "Documents")) {
        $l = Get-PnPList -Identity $c -ErrorAction SilentlyContinue
        if ($l) { return $l }
    }
    throw "Bibliothek nicht gefunden"
}

function Find-FileItem {
    param($List, [string]$Leaf, [string]$RelPath)
    $safe = $Leaf.Replace("'", "''")
    $query = @"
<View Scope='RecursiveAll'>
  <Query>
    <Where>
      <And>
        <Eq><FieldRef Name='FSObjType'/><Value Type='Integer'>0</Value></Eq>
        <Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>$safe</Value></Eq>
      </And>
    </Where>
  </Query>
  <ViewFields>
    <FieldRef Name='ID'/><FieldRef Name='FileRef'/><FieldRef Name='FileLeafRef'/>
    <FieldRef Name='WissenJahr'/><FieldRef Name='WissenAutor'/><FieldRef Name='WissenWerk'/>
    <FieldRef Name='WissenSeite'/><FieldRef Name='WissenFundstelle'/>
    <FieldRef Name='WissenTitel'/><FieldRef Name='WissenAktenzeichen'/>
  </ViewFields>
  <RowLimit>20</RowLimit>
</View>
"@
    $found = @(Get-PnPListItem -List $List -Query $query -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) { return $null }
    if ($found.Count -eq 1) { return $found[0] }

    $rel = $RelPath -replace "^Wissen/", "" -replace "\\", "/"
    foreach ($f in $found) {
        $fr = ""
        try { $fr = [string]$f["FileRef"] } catch { try { $fr = [string]$f.FieldValues["FileRef"] } catch { $fr = "" } }
        $fr = $fr -replace "\\", "/"
        if ($rel -and ($fr.EndsWith("/$rel") -or $fr.Contains("/$rel"))) { return $f }
    }
    return $found[0]
}

function Get-ItemVal($Item, [string]$Name) {
    try {
        if ($null -ne $Item[$Name]) { return $Item[$Name] }
    } catch {}
    try {
        if ($Item.FieldValues.ContainsKey($Name)) { return $Item.FieldValues[$Name] }
    } catch {}
    return $null
}

function Test-EmptyVal($Value) {
    if ($null -eq $Value) { return $true }
    $s = ("{0}" -f $Value).Trim()
    return ($s -eq "" -or $s -eq "0")
}

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext } catch { throw "Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) { throw "CSV fehlt: $CsvPath" }

$list = Get-DocLib $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

foreach ($fn in @("WissenAutor", "WissenWerk", "WissenSeite", "WissenFundstelle", "WissenTitel", "WissenAktenzeichen")) {
    $fld = Get-PnPField -List $list -Identity $fn -ErrorAction SilentlyContinue
    if (-not $fld) {
        throw "Spalte $fn fehlt. Zuerst: .\Add-WissenExtraColumns.ps1 -LibraryName 'Shared Documents'"
    }
}
$yearField = Get-PnPField -List $list -Identity "WissenJahr" -ErrorAction SilentlyContinue
if ($IncludeYear -and -not $yearField) {
    throw "Spalte WissenJahr fehlt."
}

$rows = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";")
if ($Limit -gt 0) { $rows = @($rows | Select-Object -First $Limit) }
Write-Host "CSV-Zeilen: $($rows.Count) (CAML-Suche je Datei, kein Bulk-Index)" -ForegroundColor Cyan

$updated = 0; $skipped = 0; $missing = 0; $errors = 0
$missingRows = New-Object System.Collections.Generic.List[object]

foreach ($row in $rows) {
    $leaf = ("{0}" -f $row.FileLeafRef).Trim()
    if (-not $leaf) { $skipped++; continue }

    $rel = ("{0}" -f $row.ServerRelativePath).Trim()

    try {
        $item = Find-FileItem -List $list -Leaf $leaf -RelPath $rel
    }
    catch {
        Write-Warning "Suche fehlgeschlagen für ${leaf}: $($_.Exception.Message)"
        $errors++
        continue
    }

    if ($null -eq $item) {
        $missing++
        $missingRows.Add([pscustomobject]@{
                FileLeafRef        = $leaf
                ServerRelativePath = $rel
                LocalPath          = ("{0}" -f $row.LocalPath).Trim()
            }) | Out-Null
        continue
    }

    $itemId = [int]$item.Id

    $autor = ("{0}" -f $row.Autor).Trim()
    $werk = ("{0}" -f $row.Werk).Trim()
    $seite = ("{0}" -f $row.Seite).Trim()
    $fund = ("{0}" -f $row.Fundstelle).Trim()
    $jahr = ("{0}" -f $row.Jahr).Trim()
    $titel = ("{0}" -f $row.Titel).Trim()
    $az = ("{0}" -f $row.Aktenzeichen).Trim()

    $pairs = [ordered]@{}
    if ($autor -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenAutor")))) {
        $pairs["WissenAutor"] = $autor
    }
    if ($werk -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenWerk")))) {
        $pairs["WissenWerk"] = $werk
    }
    if ($seite -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenSeite")))) {
        $pairs["WissenSeite"] = $seite
    }
    if ($fund -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenFundstelle")))) {
        $pairs["WissenFundstelle"] = $fund
    }
    if ($titel -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenTitel")))) {
        $pairs["WissenTitel"] = $titel
    }
    if ($az -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenAktenzeichen")))) {
        $pairs["WissenAktenzeichen"] = $az
    }
    if ($IncludeYear -and $jahr -match '^\d{4}$' -and (-not $OnlyEmpty -or (Test-EmptyVal (Get-ItemVal $item "WissenJahr")))) {
        $pairs["WissenJahr"] = [int]$jahr
    }

    if ($pairs.Count -eq 0) {
        $skipped++
        continue
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Id=$itemId $leaf => $($pairs.Keys -join ',')"
        $updated++
        continue
    }

    $okItem = $true
    foreach ($key in $pairs.Keys) {
        try {
            $val = $pairs[$key]
            if (Get-Command Set-PnPFieldValue -ErrorAction SilentlyContinue) {
                Set-PnPFieldValue -List $list -Identity $itemId -FieldName $key -Value $val -ErrorAction Stop | Out-Null
            }
            else {
                $ht = @{}
                $ht[$key] = $val
                Set-PnPListItem -List $list -Identity $itemId -Values $ht -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Warning "Id=$itemId $leaf field $key : $($_.Exception.Message)"
            $okItem = $false
            $errors++
        }
    }

    if ($okItem) {
        $updated++
        if ($updated -le 10 -or ($updated % 25) -eq 0) {
            Write-Host "OK Id=$itemId $leaf" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing errors=$errors" -ForegroundColor Green

if ($missingRows.Count -gt 0) {
    $missingRows | Export-Csv -LiteralPath $MissingReportPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
    Write-Host "Missing-Report: $MissingReportPath" -ForegroundColor Yellow
    Write-Host "Fehlende Dateien (max. 30):" -ForegroundColor Yellow
    $missingRows | Select-Object -First 30 | ForEach-Object {
        Write-Host ("  - {0}" -f $_.FileLeafRef) -ForegroundColor DarkYellow
    }
    if ($missingRows.Count -gt 30) {
        Write-Host ("  ... und {0} weitere (siehe Report)" -f ($missingRows.Count - 30)) -ForegroundColor DarkYellow
    }
}
