<#
.SYNOPSIS
  Befüllt Jahr/Autor/Werk/Seite/Fundstelle/Titel/Aktenzeichen aus CSV (einfacher, robuster Lauf).

.EXAMPLE
  .\Apply-WissenMetadata.ps1 -CsvPath .\wissen-metadata-extract.csv -Limit 20
#>
[CmdletBinding()]
param(
    [string]$LibraryName = "Shared Documents",
    [string]$CsvPath = (Join-Path $PSScriptRoot "wissen-metadata-extract.csv"),
    [string]$FolderPrefix = "Wissen",
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
    # CAML: Dateiname
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

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext } catch { throw "Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) { throw "CSV fehlt: $CsvPath" }

$list = Get-DocLib $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

# Prüfen, ob Textspalten existieren
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

foreach ($row in $rows) {
    $leaf = ("{0}" -f $row.FileLeafRef).Trim()
    if (-not $leaf) { $skipped++; continue }

    $rel = ("{0}" -f $row.ServerRelativePath).Trim()
    # optional: nur Pfade unter Wissen
    if ($rel -and ($rel -notlike "Wissen/*") -and ($rel -notlike "*/$FolderPrefix/*")) {
        # CSV-Pfade beginnen mit Wissen/...
    }

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
        continue
    }

    $itemId = [int]$item.Id

    if ($OnlyEmpty) {
        $has =
            $null -ne (Get-ItemVal $item "WissenAutor") -or
            $null -ne (Get-ItemVal $item "WissenWerk") -or
            $null -ne (Get-ItemVal $item "WissenFundstelle") -or
            $null -ne (Get-ItemVal $item "WissenJahr")
        if ($has -and ("$(Get-ItemVal $item 'WissenAutor')$(Get-ItemVal $item 'WissenWerk')$(Get-ItemVal $item 'WissenFundstelle')$(Get-ItemVal $item 'WissenJahr')" -ne "")) {
            # if any non-empty string/number
            $a = "$(Get-ItemVal $item 'WissenAutor')"; $w = "$(Get-ItemVal $item 'WissenWerk')"; $f = "$(Get-ItemVal $item 'WissenFundstelle')"; $y = "$(Get-ItemVal $item 'WissenJahr')"
            if (($a -and $a -ne "") -or ($w -and $w -ne "") -or ($f -and $f -ne "") -or ($y -and $y -ne "")) {
                $skipped++
                continue
            }
        }
    }

    $autor = ("{0}" -f $row.Autor).Trim()
    $werk = ("{0}" -f $row.Werk).Trim()
    $seite = ("{0}" -f $row.Seite).Trim()
    $fund = ("{0}" -f $row.Fundstelle).Trim()
    $jahr = ("{0}" -f $row.Jahr).Trim()
    $titel = ("{0}" -f $row.Titel).Trim()
    $az = ("{0}" -f $row.Aktenzeichen).Trim()

    $pairs = [ordered]@{}
    if ($autor) { $pairs["WissenAutor"] = $autor }
    if ($werk) { $pairs["WissenWerk"] = $werk }
    if ($seite) { $pairs["WissenSeite"] = $seite }
    if ($fund) { $pairs["WissenFundstelle"] = $fund }
    if ($titel) { $pairs["WissenTitel"] = $titel }
    if ($az) { $pairs["WissenAktenzeichen"] = $az }
    if ($IncludeYear -and $jahr -match '^\d{4}$') {
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
            # Set-PnPFieldValue is more reliable for single fields in PnP 3.x
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
Write-Host "Jahr wird nur mit -IncludeYear gesetzt (Zahlenspalte separat testen)."
