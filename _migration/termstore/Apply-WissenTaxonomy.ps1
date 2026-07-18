<#
.SYNOPSIS
  Befüllt Taxonomie-Spalten (Dokumenttyp, Rechtsordnung, Rechtsgebiet) aus CSV.

.DESCRIPTION
  Nutzt Term-GUIDs aus Termstore-Gruppe "Wissen" und Set-PnPTaxonomyFieldValue.
  Schlagworte werden nicht gesetzt (keine Extraktion).

.EXAMPLE
  .\Apply-WissenTaxonomy.ps1 -CsvPath .\wissen-metadata-extract.csv -Limit 20

.EXAMPLE
  .\Apply-WissenTaxonomy.ps1 -CsvPath .\wissen-metadata-extract.csv -OnlyEmpty
#>
[CmdletBinding()]
param(
    [string]$LibraryName = "Shared Documents",
    [string]$CsvPath = (Join-Path $PSScriptRoot "wissen-metadata-extract.csv"),
    [string]$TermGroupName = "Wissen",
    [string]$MissingReportPath = (Join-Path (Get-Location) "wissen-taxonomy-missing-on-sp.csv"),
    [int]$Limit = 0,
    [switch]$WhatIf,
    [switch]$OnlyEmpty,
    [switch]$IncludeDokumenttyp,
    [switch]$IncludeRechtsordnung,
    [switch]$IncludeRechtsgebiet
)

$ErrorActionPreference = "Continue"

# Default: alle drei Heuristik-Felder
if (-not $IncludeDokumenttyp -and -not $IncludeRechtsordnung -and -not $IncludeRechtsgebiet) {
    $IncludeDokumenttyp = $true
    $IncludeRechtsordnung = $true
    $IncludeRechtsgebiet = $true
}

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
    <FieldRef Name='WissenDokumenttyp'/><FieldRef Name='WissenRechtsordnung'/><FieldRef Name='WissenRechtsgebiet'/>
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

function Test-TaxonomyEmpty($Value) {
    if ($null -eq $Value) { return $true }
    if ($Value -is [System.Array] -and $Value.Count -eq 0) { return $true }
    $s = ("{0}" -f $Value).Trim()
    return ($s -eq "" -or $s -eq "0")
}

function Build-TermLabelMap {
    param([string]$GroupName, [string]$TermSetName)

    $map = @{}
    $terms = @(Get-PnPTerm -TermGroup $GroupName -TermSet $TermSetName -Recursive -ErrorAction Stop)
    foreach ($t in $terms) {
        $name = ("{0}" -f $t.Name).Trim()
        if (-not $name) { continue }
        # Prefer deepest unique label; keep first if duplicates
        if (-not $map.ContainsKey($name)) {
            $map[$name] = [guid]$t.Id
        }
        # also index lowercase for tolerant lookup
        $key = $name.ToLowerInvariant()
        if (-not $map.ContainsKey($key)) {
            $map[$key] = [guid]$t.Id
        }
    }
    Write-Host ("Termset {0}: {1} Terms geladen" -f $TermSetName, $terms.Count) -ForegroundColor DarkGray
    return $map
}

function Resolve-TermId {
    param([hashtable]$Map, [string]$Label)
    $label = $Label.Trim()
    if (-not $label) { return $null }
    if ($Map.ContainsKey($label)) { return $Map[$label] }
    $key = $label.ToLowerInvariant()
    if ($Map.ContainsKey($key)) { return $Map[$key] }
    return $null
}

function Set-TaxonomySingle {
    param($List, [int]$ItemId, [string]$FieldName, [guid]$TermId, [string]$Label)

    if (Get-Command Set-PnPTaxonomyFieldValue -ErrorAction SilentlyContinue) {
        Set-PnPTaxonomyFieldValue -List $List -Identity $ItemId -InternalFieldName $FieldName -TermId $TermId -ErrorAction Stop | Out-Null
        return
    }

    # Fallback: Label|Guid format for taxonomy fields
    $ht = @{}
    $ht[$FieldName] = ("{0}|{1}" -f $Label, $TermId.ToString())
    Set-PnPListItem -List $List -Identity $ItemId -Values $ht -ErrorAction Stop | Out-Null
}

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext } catch { throw "Zuerst Connect-PnPOnline ausführen." }

if (-not (Test-Path -LiteralPath $CsvPath)) { throw "CSV fehlt: $CsvPath" }

$list = Get-DocLib $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

$needed = @()
if ($IncludeDokumenttyp) { $needed += "WissenDokumenttyp" }
if ($IncludeRechtsordnung) { $needed += "WissenRechtsordnung" }
if ($IncludeRechtsgebiet) { $needed += "WissenRechtsgebiet" }

foreach ($fn in $needed) {
    $fld = Get-PnPField -List $list -Identity $fn -ErrorAction SilentlyContinue
    if (-not $fld) {
        throw "Spalte $fn fehlt. Zuerst: .\Add-WissenLibraryColumns.ps1"
    }
}

Write-Host "Lade Termstore-Gruppe '$TermGroupName' ..." -ForegroundColor Cyan
$mapDok = $null; $mapRo = $null; $mapRg = $null
if ($IncludeDokumenttyp) { $mapDok = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Dokumenttyp" }
if ($IncludeRechtsordnung) { $mapRo = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Rechtsordnung" }
if ($IncludeRechtsgebiet) { $mapRg = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Rechtsgebiet" }

$rows = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";")
if ($Limit -gt 0) { $rows = @($rows | Select-Object -First $Limit) }
Write-Host "CSV-Zeilen: $($rows.Count)" -ForegroundColor Cyan

$updated = 0; $skipped = 0; $missing = 0; $errors = 0; $unresolved = 0
$missingRows = New-Object System.Collections.Generic.List[object]
$unresolvedLabels = New-Object System.Collections.Generic.HashSet[string]

foreach ($row in $rows) {
    $leaf = ("{0}" -f $row.FileLeafRef).Trim()
    if (-not $leaf) { $skipped++; continue }

    $dok = ("{0}" -f $row.Dokumenttyp).Trim()
    $ro = ("{0}" -f $row.Rechtsordnung).Trim()
    $rg = ("{0}" -f $row.Rechtsgebiet).Trim()

    $wantDok = $IncludeDokumenttyp -and $dok
    $wantRo = $IncludeRechtsordnung -and $ro
    $wantRg = $IncludeRechtsgebiet -and $rg
    if (-not ($wantDok -or $wantRo -or $wantRg)) {
        $skipped++
        continue
    }

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
    $ops = New-Object System.Collections.Generic.List[object]

    if ($wantDok) {
        if (-not $OnlyEmpty -or (Test-TaxonomyEmpty (Get-ItemVal $item "WissenDokumenttyp"))) {
            $tid = Resolve-TermId -Map $mapDok -Label $dok
            if ($tid) {
                $ops.Add([pscustomobject]@{ Field = "WissenDokumenttyp"; TermId = $tid; Label = $dok; Multi = $false }) | Out-Null
            }
            else {
                [void]$unresolvedLabels.Add("Dokumenttyp::$dok")
                $unresolved++
            }
        }
    }

    if ($wantRo) {
        if (-not $OnlyEmpty -or (Test-TaxonomyEmpty (Get-ItemVal $item "WissenRechtsordnung"))) {
            $tid = Resolve-TermId -Map $mapRo -Label $ro
            if ($tid) {
                $ops.Add([pscustomobject]@{ Field = "WissenRechtsordnung"; TermId = $tid; Label = $ro; Multi = $true }) | Out-Null
            }
            else {
                [void]$unresolvedLabels.Add("Rechtsordnung::$ro")
                $unresolved++
            }
        }
    }

    if ($wantRg) {
        if (-not $OnlyEmpty -or (Test-TaxonomyEmpty (Get-ItemVal $item "WissenRechtsgebiet"))) {
            $tid = Resolve-TermId -Map $mapRg -Label $rg
            if ($tid) {
                $ops.Add([pscustomobject]@{ Field = "WissenRechtsgebiet"; TermId = $tid; Label = $rg; Multi = $true }) | Out-Null
            }
            else {
                [void]$unresolvedLabels.Add("Rechtsgebiet::$rg")
                $unresolved++
            }
        }
    }

    if ($ops.Count -eq 0) {
        $skipped++
        continue
    }

    if ($WhatIf) {
        Write-Host ("[WhatIf] Id={0} {1} => {2}" -f $itemId, $leaf, (($ops | ForEach-Object { $_.Field }) -join ","))
        $updated++
        continue
    }

    $okItem = $true
    foreach ($op in $ops) {
        try {
            Set-TaxonomySingle -List $list -ItemId $itemId -FieldName $op.Field -TermId $op.TermId -Label $op.Label
        }
        catch {
            Write-Warning ("Id={0} {1} field {2}: {3}" -f $itemId, $leaf, $op.Field, $_.Exception.Message)
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
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing unresolvedLabels=$unresolved errors=$errors" -ForegroundColor Green

if ($unresolvedLabels.Count -gt 0) {
    Write-Host "Nicht aufgelöste Labels:" -ForegroundColor Yellow
    $unresolvedLabels | Sort-Object | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
}

if ($missingRows.Count -gt 0) {
    $missingRows | Export-Csv -LiteralPath $MissingReportPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
    Write-Host "Missing-Report: $MissingReportPath" -ForegroundColor Yellow
    Write-Host "Fehlende Dateien (max. 30):" -ForegroundColor Yellow
    $missingRows | Select-Object -First 30 | ForEach-Object {
        Write-Host ("  - {0}" -f $_.FileLeafRef) -ForegroundColor DarkYellow
    }
}
