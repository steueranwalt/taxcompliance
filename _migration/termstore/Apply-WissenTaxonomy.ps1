<#
.SYNOPSIS
  Befüllt Taxonomie-Spalten (Dokumenttyp, Rechtsordnung, Rechtsgebiet) aus CSV.

.DESCRIPTION
  Nutzt Term-GUIDs aus Termstore-Gruppe "Wissen" und Set-PnPTaxonomyFieldValue.
  Wichtig: -ListItem muss ein ListItem-Objekt sein (nicht die Id).

.EXAMPLE
  .\Apply-WissenTaxonomy.ps1 -CsvPath .\wissen-metadata-extract.csv -IncludeDokumenttyp -OnlyEmpty -Limit 20
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
    # TaxonomyFieldValue / TaxonomyFieldValueCollection
    try {
        if ($null -ne $Value.Count -and $Value.Count -eq 0) { return $true }
    } catch {}
    try {
        if (("" + $Value.Label).Trim() -ne "") { return $false }
        if (("" + $Value.TermGuid).Trim() -ne "") { return $false }
    } catch {}
    $s = ("{0}" -f $Value).Trim()
    return ($s -eq "" -or $s -eq "0")
}

function Get-PathDepth([string]$Path) {
    if (-not $Path) { return 0 }
    return ($Path -split '\|').Count
}

function Import-TermPathAliases {
    <#
      Liest Taxonomy-CSV (Wissen|TermSet|...|Leaf) und mappt Leaf-Label -> voller TermPath.
      Bei Duplikaten gewinnt der längere (spezifischere) Pfad.
    #>
    param([string]$TaxonomyCsvPath, [string]$TermSetName)

    $aliases = @{}
    if (-not (Test-Path -LiteralPath $TaxonomyCsvPath)) {
        Write-Host ("Alias-CSV fehlt (optional): {0}" -f $TaxonomyCsvPath) -ForegroundColor DarkGray
        return $aliases
    }

    foreach ($line in Get-Content -LiteralPath $TaxonomyCsvPath -Encoding UTF8) {
        $line = $line.Trim()
        if (-not $line -or $line.StartsWith("#")) { continue }
        $parts = $line -split '\|'
        if ($parts.Count -lt 3) { continue }
        if ($parts[1] -ne $TermSetName) { continue }
        $leaf = $parts[-1].Trim()
        if (-not $leaf) { continue }
        $path = $line
        $key = $leaf.ToLowerInvariant()
        if (-not $aliases.ContainsKey($key) -or (Get-PathDepth $path) -gt (Get-PathDepth $aliases[$key])) {
            $aliases[$key] = $path
            $aliases[$leaf] = $path
        }
    }
    Write-Host ("Alias-Map {0}: {1} Leaf-Labels aus {2}" -f $TermSetName, @($aliases.Keys | Where-Object { $_ -cmatch '[A-ZÄÖÜ]' }).Count, (Split-Path $TaxonomyCsvPath -Leaf)) -ForegroundColor DarkGray
    return $aliases
}

function Build-TermLabelMap {
    param([string]$GroupName, [string]$TermSetName, [hashtable]$PathAliases)

    # label -> @{ Id = [guid]; Path = "Group|Set|...|Term"; Label = "..." }
    $map = @{}
    $terms = @(Get-PnPTerm -TermGroup $GroupName -TermSet $TermSetName -Recursive -ErrorAction Stop)
    foreach ($t in $terms) {
        $name = ("{0}" -f $t.Name).Trim()
        if (-not $name) { continue }

        $path = $null
        try {
            if ($t.Path) { $path = ("{0}" -f $t.Path).Trim() }
        } catch {}
        # PnP Path oft ohne Group-Prefix → mit Alias / Group auffüllen
        if ($PathAliases -and $PathAliases.ContainsKey($name)) {
            $path = $PathAliases[$name]
        }
        elseif (-not $path) {
            $path = "{0}|{1}|{2}" -f $GroupName, $TermSetName, $name
        }
        elseif ($path -notlike "$GroupName|*") {
            $path = "{0}|{1}" -f $GroupName, $path
        }

        $entry = @{
            Id    = [guid]$t.Id
            Path  = $path
            Label = $name
        }

        $key = $name.ToLowerInvariant()
        $replace = $false
        if (-not $map.ContainsKey($name)) {
            $replace = $true
        }
        elseif ((Get-PathDepth $path) -gt (Get-PathDepth $map[$name].Path)) {
            $replace = $true
        }
        if ($replace) {
            $map[$name] = $entry
            $map[$key] = $entry
        }
    }

    # Auch Alias-Leaves ohne Treffer in Get-PnPTerm vorhalten (Set via TermPath)
    if ($PathAliases) {
        foreach ($k in @($PathAliases.Keys)) {
            if ($map.ContainsKey($k)) { continue }
            $path = $PathAliases[$k]
            $leaf = ($path -split '\|')[-1]
            $entry = @{
                Id    = [guid]::Empty
                Path  = $path
                Label = $leaf
            }
            $map[$k] = $entry
            $map[$leaf] = $entry
            $map[$leaf.ToLowerInvariant()] = $entry
        }
    }

    Write-Host ("Termset {0}: {1} Terms aus Termstore geladen" -f $TermSetName, $terms.Count) -ForegroundColor DarkGray
    if ($TermSetName -in @("Dokumenttyp", "Rechtsgebiet", "Rechtsordnung")) {
        $labels = ($terms | ForEach-Object { $_.Name } | Sort-Object -Unique) -join "; "
        Write-Host ("  Labels: {0}" -f $labels) -ForegroundColor DarkGray
    }
    return $map
}

function Resolve-TermEntry {
    param([hashtable]$Map, [hashtable]$PathAliases, [string]$Label)
    $label = $Label.Trim()
    if (-not $label) { return $null }
    if ($Map.ContainsKey($label)) { return $Map[$label] }
    $key = $label.ToLowerInvariant()
    if ($Map.ContainsKey($key)) { return $Map[$key] }
    if ($PathAliases -and $PathAliases.ContainsKey($label)) {
        return @{
            Id    = [guid]::Empty
            Path  = $PathAliases[$label]
            Label = $label
        }
    }
    if ($PathAliases -and $PathAliases.ContainsKey($key)) {
        return @{
            Id    = [guid]::Empty
            Path  = $PathAliases[$key]
            Label = $label
        }
    }
    return $null
}

function Set-TaxonomySingle {
    param(
        $List,
        $ListItem,
        [string]$FieldName,
        [guid]$TermId,
        [string]$Label,
        [string]$TermPath
    )

    # PnP verlangt ListItem-Objekt, nicht Id.
    # TermPath zuerst: zuverlässig bei Hierarchie (Direkte Steuern unter Steuerrecht).
    if (Get-Command Set-PnPTaxonomyFieldValue -ErrorAction SilentlyContinue) {
        if ($TermPath) {
            try {
                Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName -TermPath $TermPath -ErrorAction Stop | Out-Null
                return
            }
            catch {
                # Fallback auf TermId
            }
        }
        if ($TermId -and $TermId -ne [guid]::Empty) {
            Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName -TermId $TermId -Label $Label -ErrorAction Stop | Out-Null
            return
        }
        if ($TermPath) {
            # zweiten Versuch-Fehler durchreichen
            Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName -TermPath $TermPath -ErrorAction Stop | Out-Null
            return
        }
        throw "Kein TermId/TermPath für $FieldName / $Label"
    }

    if ($TermId -eq [guid]::Empty) {
        throw "Set-PnPTaxonomyFieldValue fehlt und TermId leer für $Label"
    }
    $ht = @{}
    $ht[$FieldName] = ("-1;#{0}|{1}" -f $Label, $TermId.ToString())
    Set-PnPListItem -List $List -Identity $ListItem.Id -Values $ht -ErrorAction Stop | Out-Null
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
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$csvDir = Split-Path -Parent (Resolve-Path -LiteralPath $CsvPath).Path

function Find-LocalTaxonomyCsv([string]$FileName) {
    foreach ($dir in @($scriptDir, $csvDir, (Get-Location).Path)) {
        if (-not $dir) { continue }
        $p = Join-Path $dir $FileName
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return (Join-Path $scriptDir $FileName)
}

$mapDok = $null; $mapRo = $null; $mapRg = $null
$aliasDok = @{}; $aliasRo = @{}; $aliasRg = @{}

if ($IncludeDokumenttyp) {
    $aliasDok = Import-TermPathAliases -TaxonomyCsvPath (Find-LocalTaxonomyCsv "dokumenttyp.csv") -TermSetName "Dokumenttyp"
    $mapDok = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Dokumenttyp" -PathAliases $aliasDok
}
if ($IncludeRechtsordnung) {
    $aliasRo = Import-TermPathAliases -TaxonomyCsvPath (Find-LocalTaxonomyCsv "rechtsordnung.csv") -TermSetName "Rechtsordnung"
    $mapRo = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Rechtsordnung" -PathAliases $aliasRo
}
if ($IncludeRechtsgebiet) {
    $aliasRg = Import-TermPathAliases -TaxonomyCsvPath (Find-LocalTaxonomyCsv "rechtsgebiet.csv") -TermSetName "Rechtsgebiet"
    $mapRg = Build-TermLabelMap -GroupName $TermGroupName -TermSetName "Rechtsgebiet" -PathAliases $aliasRg
}

$rows = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";")
if ($Limit -gt 0) { $rows = @($rows | Select-Object -First $Limit) }
Write-Host "CSV-Zeilen: $($rows.Count)" -ForegroundColor Cyan

$updated = 0; $skipped = 0; $missing = 0; $errors = 0; $unresolved = 0
$missingRows = New-Object System.Collections.Generic.List[object]
$unresolvedLabels = New-Object System.Collections.Generic.HashSet[string]
$firstErrorShown = $false

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
            $entry = Resolve-TermEntry -Map $mapDok -PathAliases $aliasDok -Label $dok
            if ($entry) {
                $ops.Add([pscustomobject]@{
                        Field = "WissenDokumenttyp"
                        TermId = $entry.Id
                        Label = $entry.Label
                        Path = $entry.Path
                    }) | Out-Null
            }
            else {
                [void]$unresolvedLabels.Add("Dokumenttyp::$dok")
                $unresolved++
            }
        }
    }

    if ($wantRo) {
        if (-not $OnlyEmpty -or (Test-TaxonomyEmpty (Get-ItemVal $item "WissenRechtsordnung"))) {
            $entry = Resolve-TermEntry -Map $mapRo -PathAliases $aliasRo -Label $ro
            if ($entry) {
                $ops.Add([pscustomobject]@{
                        Field = "WissenRechtsordnung"
                        TermId = $entry.Id
                        Label = $entry.Label
                        Path = $entry.Path
                    }) | Out-Null
            }
            else {
                [void]$unresolvedLabels.Add("Rechtsordnung::$ro")
                $unresolved++
            }
        }
    }

    if ($wantRg) {
        if (-not $OnlyEmpty -or (Test-TaxonomyEmpty (Get-ItemVal $item "WissenRechtsgebiet"))) {
            $entry = Resolve-TermEntry -Map $mapRg -PathAliases $aliasRg -Label $rg
            if ($entry) {
                $ops.Add([pscustomobject]@{
                        Field = "WissenRechtsgebiet"
                        TermId = $entry.Id
                        Label = $entry.Label
                        Path = $entry.Path
                    }) | Out-Null
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
        Write-Host ("[WhatIf] Id={0} {1} => {2}" -f $itemId, $leaf, (($ops | ForEach-Object { $_.Label }) -join ","))
        $updated++
        continue
    }

    $okItem = $true
    foreach ($op in $ops) {
        try {
            Set-TaxonomySingle -List $list -ListItem $item -FieldName $op.Field -TermId $op.TermId -Label $op.Label -TermPath $op.Path
        }
        catch {
            $msg = $_.Exception.Message
            if (-not $firstErrorShown) {
                Write-Warning ("ERSTER FEHLER Id={0} {1} field {2}: {3}" -f $itemId, $leaf, $op.Field, $msg)
                $firstErrorShown = $true
            }
            elseif ($errors -lt 5) {
                Write-Warning ("Id={0} {1} field {2}: {3}" -f $itemId, $leaf, $op.Field, $msg)
            }
            $okItem = $false
            $errors++
        }
    }

    if ($okItem) {
        $updated++
        if ($updated -le 15 -or ($updated % 25) -eq 0) {
            Write-Host ("OK Id={0} {1} => {2}" -f $itemId, $leaf, (($ops | ForEach-Object { $_.Label }) -join ",")) -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "Fertig. updated=$updated skipped=$skipped missingOnSp=$missing unresolvedLabels=$unresolved errors=$errors" -ForegroundColor Green

if ($unresolvedLabels.Count -gt 0) {
    Write-Host "Nicht aufgelöste Labels (fehlen vermutlich im Termstore):" -ForegroundColor Yellow
    $unresolvedLabels | Sort-Object | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
    Write-Host "Hinweis: Termset prüfen. Nested Terms ggf. per Import-WissenTermstore / Apply-Termstore nachziehen." -ForegroundColor Yellow
    Write-Host "Diagnose: Get-PnPTerm -TermGroup 'Wissen' -TermSet 'Rechtsgebiet' -Recursive | Select-Object Name" -ForegroundColor Yellow
}

if ($missingRows.Count -gt 0) {
    $missingRows | Export-Csv -LiteralPath $MissingReportPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
    Write-Host "Missing-Report: $MissingReportPath" -ForegroundColor Yellow
    Write-Host "Fehlende Dateien (max. 30):" -ForegroundColor Yellow
    $missingRows | Select-Object -First 30 | ForEach-Object {
        Write-Host ("  - {0}" -f $_.FileLeafRef) -ForegroundColor DarkYellow
    }
}
