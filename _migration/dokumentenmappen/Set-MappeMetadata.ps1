<#
.SYNOPSIS
  Schritt 4: Befuellt die geteilten Spalten der Dokumentenmappen aus CSV.

.DESCRIPTION
  Schreibt Rechtsgebiet (Feld "Rechtsgebiet", Termset "Themengebiet") und
  Rechtsordnung (Feld/Termset "Rechtsordnung") je Mappe - beides bereits
  vorhandene kanzleiweite Spalten, keine neuen "Wissen*"-Spalten. Weil das
  geteilte Spalten der Dokumentenmappe sind, schreibt SharePoint die Werte
  anschliessend selbst auf alle Dokumente in der Mappe durch - ein Wert pro
  Thema statt ein Wert pro Dokument.

  Kein Schlagworte-Feld: die einzige vorhandene Kandidatenspalte
  ("Schlagwoerter" / Termset Dokument-Verschlagwortung) klassifiziert
  Aktendokumente (Auftrag, Berechnung, Entwurf, Memo, Stammakte, ...), keine
  Sachthemen - siehe README.md, Abschnitt "Metadatenmodell".

  CSV-Format (Semikolon, UTF-8 mit BOM), mehrere Werte je Zelle mit " || ":

      Pfad;Rechtsgebiet;Rechtsordnung
      02 Steuern DE/Umsatzsteuer;Steuerrecht;Deutschland

  Pfad ist relativ zur Bibliothekswurzel. Rechtsgebiet ist am Feld
  einwertig (TaxonomyFieldType) - pro Zeile genau ein Wert aus dem Termset
  "Themengebiet". Rechtsordnung ist mehrwertig (TaxonomyFieldTypeMulti) und
  erlaubt " || " fuer mehrere Laender/Raeume aus dem Termset "Rechtsordnung".
  Beide Termsets sind flach (keine Hierarchie), ein Blatt-Label reicht.

  Leere Zellen bedeuten "nichts schreiben", nicht "Wert loeschen".

.PARAMETER OnlyEmpty
  Nur Felder schreiben, die an der Mappe noch leer sind. Empfohlen fuer
  Nachlaeufe, damit von Hand gesetzte Werte nicht ueberschrieben werden.

.PARAMETER AllowFolders
  Auch normale Ordner befuellen, die noch keine Dokumentenmappe sind. Ohne
  diesen Schalter werden sie uebersprungen - dort gibt es keine geteilten
  Spalten, der Wert wuerde nicht durchgeschrieben.

.EXAMPLE
  Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive

  # Trockenlauf: zeigt jeden Schreibvorgang, aendert nichts
  .\Set-MappeMetadata.ps1 -WhatIf

  # Probelauf ueber fuenf Mappen
  .\Set-MappeMetadata.ps1 -Limit 5

  # Vollauf, vorhandene Werte nicht anfassen
  .\Set-MappeMetadata.ps1 -OnlyEmpty
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://obenhaus.sharepoint.com/sites/Wissen",
    [string]$LibraryName = "Freigegebene Dokumente",
    [string]$CsvPath = "$PSScriptRoot\mappen-metadaten.csv",
    [string]$TermGroupName = "Wissen",
    [string]$ReportPath = "$PSScriptRoot\mappen-metadaten-log.csv",

    [switch]$OnlyEmpty,
    [switch]$AllowFolders,
    [int]$Limit = 0,
    [switch]$Connect,
    [switch]$Interactive,
    [string]$ClientId,
    [string]$Tenant,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module PnP.PowerShell -ErrorAction Stop
. "$PSScriptRoot\_Common.ps1"

# Spalte -> internes Feld + Termset
# Spaltenname in der CSV -> internes Feld auf der Bibliothek -> Termset-Name.
# Feld und Termset heissen bei Rechtsgebiet bewusst unterschiedlich: die
# Spalte heisst intern "Rechtsgebiet", ist aber an das Termset "Themengebiet"
# gebunden (vgl. New-WissenMappeContentType.ps1).
$FieldMap = @(
    @{ Column = "Rechtsgebiet";  Field = "Rechtsgebiet";  TermSet = "Themengebiet";  Multi = $false }
    @{ Column = "Rechtsordnung"; Field = "Rechtsordnung"; TermSet = "Rechtsordnung"; Multi = $true  }
)

$MultiSeparator = " || "

Connect-Wissen -Connect:$Connect -SiteUrl $SiteUrl -Interactive:$Interactive -ClientId $ClientId -Tenant $Tenant

if (-not (Test-Path -LiteralPath $CsvPath)) { throw "CSV fehlt: $CsvPath" }

$list    = Get-WissenList -Name $LibraryName
$rootUrl = Get-ListRootUrl -List $list
$webUrl  = (Get-PnPWeb).ServerRelativeUrl.TrimEnd('/')
$rootSiteRel = $rootUrl.Substring($webUrl.Length).Trim('/')
Write-Ok "Bibliothek: $($list.Title)   Wurzel: $rootUrl"

# =========================================================================
# Termstore einlesen: Label und Pfad -> Term
# =========================================================================
function Get-PathDepth { param([string]$Path) if (-not $Path) { return 0 } return ($Path -split '\|').Count }

function Build-TermMap {
    <#
      Baut je Termset eine Map. Schluessel sind sowohl das Blatt-Label als auch
      der vollstaendige Pfad. Bei doppelt vergebenen Labels gewinnt der tiefere
      Pfad - der vollstaendige Pfad bleibt in jedem Fall eindeutig ansprechbar.
    #>
    param([string]$GroupName, [string]$TermSetName)

    $map   = @{}
    $terms = @(Get-PnPTerm -TermGroup $GroupName -TermSet $TermSetName -Recursive -ErrorAction Stop)

    foreach ($t in $terms) {
        $label = ("{0}" -f $t.Name).Trim()
        if (-not $label) { continue }

        $path = ""
        try { if ($t.Path) { $path = ("{0}" -f $t.Path).Trim() } } catch { }
        # PnP liefert den Pfad ohne Gruppen-Praefix.
        if (-not $path) { $path = "$GroupName|$TermSetName|$label" }
        elseif ($path -notlike "$GroupName|*") { $path = "$GroupName|$path" }

        $entry = @{ Id = [guid]$t.Id; Path = $path; Label = $label }

        # Vollstaendiger Pfad: immer eindeutig
        $map[$path] = $entry

        # Label: tieferer Pfad gewinnt
        foreach ($key in @($label, $label.ToLowerInvariant())) {
            if (-not $map.ContainsKey($key) -or (Get-PathDepth $path) -gt (Get-PathDepth $map[$key].Path)) {
                $map[$key] = $entry
            }
        }
    }

    Write-Skip "  Termset $TermSetName : $($terms.Count) Terme"
    return $map
}

Write-Step "Lese Termstore-Gruppe '$TermGroupName' ..."
$termMaps = @{}
foreach ($m in $FieldMap) {
    $termMaps[$m.TermSet] = Build-TermMap -GroupName $TermGroupName -TermSetName $m.TermSet
}

function Resolve-Term {
    param([hashtable]$Map, [string]$Value)
    $v = $Value.Trim()
    if (-not $v) { return $null }
    if ($Map.ContainsKey($v)) { return $Map[$v] }
    $k = $v.ToLowerInvariant()
    if ($Map.ContainsKey($k)) { return $Map[$k] }
    return $null
}

# =========================================================================
# Feldwerte schreiben
# =========================================================================
function Test-TaxonomyEmpty {
    param($Value)
    if ($null -eq $Value) { return $true }
    try { if ($null -ne $Value.Count) { return ($Value.Count -eq 0) } } catch { }
    try { if (("" + $Value.Label).Trim() -ne "") { return $false } } catch { }
    return ((("{0}" -f $Value).Trim()) -eq "")
}

function Set-TaxonomyValues {
    <#
      Schreibt einen oder mehrere Terme in ein Managed-Metadata-Feld.

      Der Schreibweg richtet sich nach der FELDEIGENSCHAFT (-Multi), nicht
      nach der Anzahl Werte in der jeweiligen CSV-Zelle. Live-Befund: bei
      einem einwertigen Feld mit genau einem Wert schlug -TermPath allein
      mit "Taxonomy Term not found" fehl, obwohl derselbe Term im Trockenlauf
      korrekt aufgeloest wurde - deshalb hier ebenfalls ein Fallback.
    #>
    param($List, $ListItem, [string]$FieldName, $Entries, [bool]$Multi)

    if (-not $Multi) {
        $entry = $Entries[0]
        try {
            Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName `
                                      -TermPath $entry.Path -ErrorAction Stop | Out-Null
        }
        catch {
            Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName `
                                      -TermId $entry.Id -Label $entry.Label -ErrorAction Stop | Out-Null
        }
        return
    }

    # Mehrwertiges Feld: Hashtable Label -> TermId.
    $terms = @{}
    foreach ($e in $Entries) { $terms[$e.Label] = $e.Id.ToString() }
    try {
        Set-PnPTaxonomyFieldValue -ListItem $ListItem -InternalFieldName $FieldName `
                                  -Terms $terms -ErrorAction Stop | Out-Null
    }
    catch {
        # Fallback: Rohformat des Mehrfach-Taxonomiefelds
        $raw = ($Entries | ForEach-Object { "-1;#$($_.Label)|$($_.Id)" }) -join ";#"
        Set-PnPListItem -List $List.Id -Identity $ListItem.Id `
                        -Values @{ $FieldName = $raw } -ErrorAction Stop | Out-Null
    }
}

# =========================================================================
# CSV abarbeiten
# =========================================================================
$rows = @(Import-Csv -Path $CsvPath -Delimiter ';')
Write-Ok "CSV: $($rows.Count) Mappen aus $(Split-Path $CsvPath -Leaf)"

if ($Limit -gt 0 -and $rows.Count -gt $Limit) {
    Write-Warn2 "Limit $Limit aktiv - es werden nur die ersten $Limit von $($rows.Count) Zeilen bearbeitet."
    $rows = @($rows[0..($Limit - 1)])
}

$results = @()
$stats   = @{ written = 0; skipped = 0; failed = 0; nomappe = 0; notfound = 0 }

foreach ($row in $rows) {
    $relPath = ([string]$row.Pfad).Trim()
    if (-not $relPath) { continue }

    $siteRel = "$rootSiteRel/$relPath"
    $record  = [pscustomobject]@{
        Pfad = $relPath; ItemId = 0; Rechtsgebiet = ""; Rechtsordnung = ""
        Ergebnis = ""; Hinweis = ""
    }

    # --- Mappe aufloesen ---
    $item = $null
    try {
        $folder = Get-PnPFolder -Url $siteRel -Includes ListItemAllFields -ErrorAction Stop
        $item   = $folder.ListItemAllFields
        $record.ItemId = $item.Id
    }
    catch {
        $record.Ergebnis = "nicht gefunden"
        $record.Hinweis  = $_.Exception.Message
        $stats.notfound++
        $results += $record
        Write-Warn2 "  nicht gefunden: $relPath"
        continue
    }

    $isDocSet = ([string]$item["ContentTypeId"]) -like "$script:CtIdDocumentSet*"
    if (-not $isDocSet -and -not $AllowFolders) {
        $record.Ergebnis = "keine Dokumentenmappe"
        $record.Hinweis  = "Zuerst Convert-FoldersToDocumentSets.ps1, oder -AllowFolders"
        $stats.nomappe++
        $results += $record
        Write-Skip "  keine Mappe: $relPath"
        continue
    }

    # --- Felder schreiben ---
    $anyWritten = $false
    $anyFailed  = $false
    $notes      = @()

    foreach ($m in $FieldMap) {
        $cell = ([string]$row.($m.Column)).Trim()
        if (-not $cell) { continue }

        # Terme aufloesen; unbekannte Terme werden gemeldet, nicht erfunden.
        $entries = @()
        foreach ($v in ($cell -split [regex]::Escape($MultiSeparator))) {
            $entry = Resolve-Term -Map $termMaps[$m.TermSet] -Value $v
            if ($entry) { $entries += $entry }
            else { $notes += "Term unbekannt in $($m.TermSet): '$($v.Trim())'" }
        }
        if ($entries.Count -eq 0) { $anyFailed = $true; continue }

        if ($OnlyEmpty) {
            $currentValue = $null
            try { $currentValue = $item[$m.Field] } catch { }
            if (-not (Test-TaxonomyEmpty $currentValue)) {
                $record.($m.Column) = "vorhanden, nicht angetastet"
                continue
            }
        }

        $labels = ($entries | ForEach-Object { $_.Label }) -join ", "
        $record.($m.Column) = $labels

        if ($WhatIf) {
            Write-Warn2 "  [WhatIf] $relPath  $($m.Field) = $labels"
            continue
        }

        try {
            Set-TaxonomyValues -List $list -ListItem $item -FieldName $m.Field -Entries $entries -Multi:$m.Multi
            $anyWritten = $true
        }
        catch {
            $anyFailed = $true
            $notes += "$($m.Field): $($_.Exception.Message)"
        }
    }

    $record.Hinweis = ($notes -join " | ")
    if ($WhatIf)          { $record.Ergebnis = "whatif" }
    elseif ($anyFailed)   { $record.Ergebnis = "Fehler"; $stats.failed++;  Write-Warn2 "  FEHLER  $relPath : $($record.Hinweis)" }
    elseif ($anyWritten)  { $record.Ergebnis = "geschrieben"; $stats.written++; Write-Host "  ok      $relPath" }
    else                  { $record.Ergebnis = "nichts zu tun"; $stats.skipped++; Write-Skip "  nichts zu tun: $relPath" }

    $results += $record
}

# =========================================================================
# Protokoll
# =========================================================================
$results | Export-Csv -Path $ReportPath -Delimiter ';' -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Ok "geschrieben: $($stats.written)   nichts zu tun: $($stats.skipped)"
if ($stats.nomappe)  { Write-Warn2 "noch keine Dokumentenmappe: $($stats.nomappe)" }
if ($stats.notfound) { Write-Warn2 "Pfad nicht gefunden: $($stats.notfound)" }
if ($stats.failed)   { Write-Warn2 "Fehler: $($stats.failed) - Details im Protokoll" }
Write-Ok "Protokoll: $ReportPath"

Write-Host ""
Write-Host "Das Durchschreiben auf die Dokumente in der Mappe erledigt SharePoint"
Write-Host "asynchron. Bei grossen Mappen kann das einige Minuten dauern."
