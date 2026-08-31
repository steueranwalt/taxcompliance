<#
.SYNOPSIS
  Schritt 3: Wandelt Ordner der Bibliothek in Dokumentenmappen um.

.DESCRIPTION
  Die Umwandlung erfolgt an Ort und Stelle: der Ordner behaelt Id, Pfad,
  Versionen, Freigaben und alle enthaltenen Dateien; nur sein Inhaltstyp wird
  von "Ordner" (0x0120) auf die Wissensmappe (abgeleitet von 0x0120D520)
  gewechselt und HTML_x0020_File_x0020_Type auf SharePoint.DocumentSet gesetzt.
  Es wird nichts kopiert, verschoben oder geloescht - deshalb bleiben auch
  bestehende Links auf Dateien in diesen Ordnern gueltig.

  Umgewandelt wird immer genau eine Ebene (-Depth), weil Dokumentenmappen
  nicht verschachtelt werden koennen. Ordner unterhalb einer Mappe bleiben
  normale Unterordner.

  Der Bestand wird Ebene fuer Ebene ueber Get-PnPFolderItem eingelesen, nicht
  ueber eine rekursive CAML-Abfrage: eine gefilterte Rekursion ueber die ganze
  Bibliothek laeuft bei dieser Groesse in die Listenansichtsschwelle
  (5.000 Elemente).

  Automatisch ausgenommen:
    - OneNote-Notizbuecher (Ordner mit .onetoc2 und alles darunter) - eine
      Umwandlung wuerde das Notizbuch beschaedigen
    - OneNote_RecycleBin und Forms
    - Ordner, die schon eine Dokumentenmappe sind
    - Ordner unterhalb einer bestehenden Dokumentenmappe
    - alles unter -ExcludePath

  Grenze der Verschachtelungspruefung: erkannt werden Dokumentenmappen auf den
  Ebenen 1 bis -Depth. Wer zuvor mit einer groesseren -Depth umgewandelt hat,
  sollte diesen Lauf zuerst per -Rollback zuruecknehmen.

.PARAMETER Depth
  Ordnerebene relativ zur Bibliothekswurzel. 1 = die acht Hauptordner,
  2 = die Themenordner darunter (empfohlen, siehe README.md).

.PARAMETER ReportOnly
  Nur analysieren und CSV schreiben, nichts aendern. Immer zuerst ausfuehren.

.PARAMETER Rollback
  Setzt die in einem frueheren Protokoll (-ReportPath) erfolgreich
  umgewandelten Ordner zurueck auf den Inhaltstyp Ordner.

.EXAMPLE
  Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive

  # 1. Analyse - aendert nichts
  .\Convert-FoldersToDocumentSets.ps1 -ReportOnly

  # 2. Probelauf mit fuenf Ordnern
  .\Convert-FoldersToDocumentSets.ps1 -Limit 5

  # 3. Vollauf
  .\Convert-FoldersToDocumentSets.ps1

.EXAMPLE
  # Zurueck auf Ordner
  .\Convert-FoldersToDocumentSets.ps1 -Rollback -ReportPath .\dokumentenmappen-log.csv
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://obenhaus.sharepoint.com/sites/Wissen",
    [string]$LibraryName = "Freigegebene Dokumente",
    [string]$ContentTypeName = "Wissensmappe",

    [ValidateRange(1, 10)]
    [int]$Depth = 2,

    # Standardausnahmen: Teams-Kanalordner und die beiden OneNote-Notizbuecher
    # auf oberster Ebene (siehe README.md, Bestandsaufnahme).
    [string[]]$ExcludePath = @("General", "Steuerrecht", "Wissen"),

    [string]$ReportPath = "$PSScriptRoot\dokumentenmappen-log.csv",
    [switch]$ReportOnly,
    [switch]$Rollback,

    [int]$Limit = 0,
    [switch]$SystemUpdate,
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

Connect-Wissen -Connect:$Connect -SiteUrl $SiteUrl -Interactive:$Interactive -ClientId $ClientId -Tenant $Tenant

$list    = Get-WissenList -Name $LibraryName
$rootUrl = Get-ListRootUrl -List $list

# Get-PnPFolderItem erwartet site-relative Pfade, die Bibliothekswurzel ist
# server-relativ ("/sites/Wissen/Freigegebene Dokumente").
$webUrl      = (Get-PnPWeb).ServerRelativeUrl.TrimEnd('/')
$rootSiteRel = $rootUrl.Substring($webUrl.Length).Trim('/')
Write-Ok "Bibliothek: $($list.Title)   Wurzel: $rootUrl"

function Invoke-WithRetry {
    <# Vier Versuche mit 2/4/8 s Backoff - SharePoint drosselt bei Massenupdates. #>
    param([Parameter(Mandatory)][scriptblock]$Action)

    $delays = @(2, 4, 8)
    for ($i = 0; $i -lt 4; $i++) {
        try { return & $Action }
        catch {
            if ($i -ge 3) { throw }
            Start-Sleep -Seconds $delays[$i]
        }
    }
}

# =========================================================================
# Rollback
# =========================================================================
if ($Rollback) {
    if (-not (Test-Path $ReportPath)) {
        throw "Protokoll nicht gefunden: $ReportPath. Rollback braucht das CSV des Umwandlungslaufs."
    }

    $rows = @(Import-Csv -Path $ReportPath -Delimiter ';' |
              Where-Object { $_.Action -eq 'convert' -and $_.Result -eq 'ok' })
    Write-Step "Rollback: $($rows.Count) Ordner aus $ReportPath"

    $reverted = 0
    foreach ($row in $rows) {
        if ($WhatIf) {
            Write-Warn2 "[WhatIf] Rollback -> Ordner: $($row.Path)"
            continue
        }
        try {
            Invoke-WithRetry {
                Set-PnPListItem -List $list.Id -Identity ([int]$row.ItemId) -Values @{
                    ContentTypeId              = $script:CtIdFolder
                    HTML_x0020_File_x0020_Type = ""
                } | Out-Null
            }
            $reverted++
            Write-Skip "zurueckgesetzt: $($row.Path)"
        }
        catch {
            Write-Warn2 "FEHLER Rollback $($row.Path): $($_.Exception.Message)"
        }
    }
    Write-Ok "Rollback fertig. Zurueckgesetzt: $reverted von $($rows.Count)"
    return
}

# =========================================================================
# Zielinhaltstyp
# =========================================================================
$targetCt = Get-PnPContentType -List $list.Id -Identity $ContentTypeName -ErrorAction SilentlyContinue
if (-not $targetCt -and -not $ReportOnly) {
    throw "Inhaltstyp '$ContentTypeName' ist in '$($list.Title)' nicht registriert. Zuerst .\New-WissenMappeContentType.ps1 ausfuehren."
}
$targetCtId = if ($targetCt) { $targetCt.Id.StringValue } else { "" }
$targetCtLabel = if ($targetCtId) { $targetCtId } else { "noch nicht angelegt" }
Write-Ok ("Zielinhaltstyp: {0} ({1})" -f $ContentTypeName, $targetCtLabel)

# =========================================================================
# Bestand einlesen - Ebene fuer Ebene
# =========================================================================
$SystemFolders = @("Forms", "OneNote_RecycleBin", "_private", "_cts")

function Get-ChildFolderNames {
    param([Parameter(Mandatory)][string]$SiteRelativeUrl)
    return @(Get-PnPFolderItem -FolderSiteRelativeUrl $SiteRelativeUrl -ItemType Folder -ErrorAction Stop |
             ForEach-Object { $_.Name })
}

function Test-HasOneNoteNotebook {
    <# Ein OneNote-Notizbuch erkennt man an der .onetoc2-Datei im Ordner. #>
    param([Parameter(Mandatory)][string]$SiteRelativeUrl)
    $files = @(Get-PnPFolderItem -FolderSiteRelativeUrl $SiteRelativeUrl -ItemType File -ErrorAction SilentlyContinue |
               ForEach-Object { $_.Name })
    return [bool](@($files | Where-Object { $_ -like "*.onetoc2" }).Count)
}

Write-Step "Lese Ordnerbaum bis Ebene $Depth ..."

$nodes   = @()
$current = @([pscustomobject]@{ Segments = @(); SiteRel = $rootSiteRel })

for ($level = 1; $level -le $Depth; $level++) {
    $next = @()
    foreach ($parent in $current) {
        $childNames = @()
        try { $childNames = Get-ChildFolderNames -SiteRelativeUrl $parent.SiteRel }
        catch {
            Write-Warn2 "  Ordner nicht lesbar, uebersprungen: $($parent.SiteRel) - $($_.Exception.Message)"
            continue
        }

        foreach ($childName in $childNames) {
            if ($childName -in $SystemFolders) { continue }

            $node = [pscustomobject]@{
                Depth         = $level
                Segments      = @($parent.Segments + $childName)
                Name          = $childName
                SiteRel       = "$($parent.SiteRel)/$childName"
                IsOneNote     = $false
                ItemId        = 0
                Title         = ""
                ContentTypeId = ""
            }
            $node.IsOneNote = Test-HasOneNoteNotebook -SiteRelativeUrl $node.SiteRel
            $nodes += $node
            # Unter einem Notizbuch wird nicht weitergesucht.
            if ($level -lt $Depth -and -not $node.IsOneNote) { $next += $node }
        }
    }
    Write-Ok "  Ebene $level : $(@($nodes | Where-Object { $_.Depth -eq $level }).Count) Ordner"
    $current = $next
}

Write-Step "Lese Inhaltstypen der Ordner ..."
foreach ($node in $nodes) {
    try {
        $folder = Get-PnPFolder -Url $node.SiteRel -Includes ListItemAllFields -ErrorAction Stop
        $node.ItemId        = $folder.ListItemAllFields.Id
        $node.Title         = [string]$folder.ListItemAllFields["Title"]
        $node.ContentTypeId = [string]$folder.ListItemAllFields["ContentTypeId"]
    }
    catch {
        Write-Warn2 "  Listenelement nicht lesbar: $($node.SiteRel) - $($_.Exception.Message)"
    }
}

# Relative Pfade
foreach ($node in $nodes) {
    Add-Member -InputObject $node -NotePropertyName Path -NotePropertyValue ($node.Segments -join '/') -Force
}

$oneNoteRoots    = @($nodes | Where-Object { $_.IsOneNote } | ForEach-Object { $_.Path })
$existingDocSets = @($nodes | Where-Object { $_.ContentTypeId -like "$script:CtIdDocumentSet*" } | ForEach-Object { $_.Path })

Write-Ok "OneNote-Notizbuecher: $($oneNoteRoots.Count)"
Write-Ok "Bereits Dokumentenmappen: $($existingDocSets.Count)"

# =========================================================================
# Entscheiden
# =========================================================================
function Test-UnderAny {
    param([string]$Path, [string[]]$Prefixes)
    foreach ($p in $Prefixes) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if ($Path -eq $p -or $Path.StartsWith("$p/", [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

$decisions = @()
foreach ($node in $nodes) {
    $action = "convert"
    $reason = ""

    if ($node.Depth -ne $Depth) {
        $action = "skip"; $reason = "andere Ebene ($($node.Depth))"
    }
    elseif ($node.ItemId -le 0) {
        $action = "skip"; $reason = "Listenelement nicht lesbar"
    }
    elseif ($node.ContentTypeId -like "$script:CtIdDocumentSet*") {
        $action = "skip"; $reason = "ist schon eine Dokumentenmappe"
    }
    elseif ($node.IsOneNote -or (Test-UnderAny -Path $node.Path -Prefixes $oneNoteRoots)) {
        $action = "skip"; $reason = "OneNote-Notizbuch"
    }
    elseif (Test-UnderAny -Path $node.Path -Prefixes $ExcludePath) {
        $action = "skip"; $reason = "ExcludePath"
    }
    elseif (Test-UnderAny -Path $node.Path -Prefixes $existingDocSets) {
        $action = "skip"; $reason = "liegt in einer Dokumentenmappe"
    }
    elseif (@($existingDocSets | Where-Object { $_.StartsWith("$($node.Path)/", [StringComparison]::OrdinalIgnoreCase) }).Count) {
        $action = "skip"; $reason = "enthaelt schon eine Dokumentenmappe"
    }

    $decisions += [pscustomobject]@{
        Depth  = $node.Depth
        Path   = $node.Path
        Name   = $node.Name
        ItemId = $node.ItemId
        Title  = $node.Title
        FromCT = $node.ContentTypeId
        Action = $action
        Reason = $reason
        Result = ""
    }
}

$candidates = @($decisions | Where-Object { $_.Action -eq 'convert' } | Sort-Object Path)
if ($Limit -gt 0 -and $candidates.Count -gt $Limit) {
    Write-Warn2 "Limit $Limit aktiv - es werden nur die ersten $Limit von $($candidates.Count) Ordnern umgewandelt."
    foreach ($c in $candidates[$Limit..($candidates.Count - 1)]) {
        $c.Action = "skip"; $c.Reason = "Limit"
    }
    $candidates = @($candidates[0..($Limit - 1)])
}

Write-Host ""
Write-Ok "Ebene $Depth : $($candidates.Count) Ordner werden zu Dokumentenmappen."
$decisions | Where-Object { $_.Action -eq 'skip' } |
    Group-Object Reason | Sort-Object Count -Descending |
    ForEach-Object { Write-Skip ("  uebersprungen {0,5}  {1}" -f $_.Count, $_.Name) }

# =========================================================================
# Anwenden
# =========================================================================
if ($ReportOnly) {
    Write-Warn2 "`n-ReportOnly: es wurde nichts geaendert."
}
else {
    Write-Host ""
    $done = 0; $failed = 0
    foreach ($c in $candidates) {
        if ($WhatIf) {
            Write-Warn2 "[WhatIf] $($c.Path) -> $ContentTypeName"
            $c.Result = "whatif"
            continue
        }

        # Die Willkommensseite der Mappe zeigt Title - leere Titel mit dem
        # Ordnernamen vorbelegen.
        $values = @{ HTML_x0020_File_x0020_Type = $script:DocSetHtmlFileType }
        if ([string]::IsNullOrWhiteSpace($c.Title)) { $values["Title"] = $c.Name }

        try {
            Invoke-WithRetry {
                $splat = @{ List = $list.Id; Identity = $c.ItemId; Values = $values }
                if ($SystemUpdate) { $splat.UpdateType = "SystemUpdate" }

                try {
                    Set-PnPListItem @splat -ContentType $targetCtId | Out-Null
                }
                catch {
                    # Aeltere PnP-Versionen setzen den Inhaltstyp nur ueber das Feld.
                    $fallback = $values.Clone()
                    $fallback["ContentTypeId"] = $targetCtId
                    $splat.Values = $fallback
                    Set-PnPListItem @splat | Out-Null
                }
            }
            $c.Result = "ok"
            $done++
            Write-Host ("  ok      {0}" -f $c.Path)
        }
        catch {
            $c.Result = "error: $($_.Exception.Message)"
            $failed++
            Write-Warn2 ("  FEHLER  {0}: {1}" -f $c.Path, $_.Exception.Message)
        }
    }

    Write-Host ""
    if ($failed -gt 0) { Write-Warn2 "Umgewandelt: $done   Fehler: $failed" }
    else { Write-Ok "Umgewandelt: $done   Fehler: 0" }
}

# =========================================================================
# Protokoll
# =========================================================================
$decisions | Sort-Object Depth, Path |
    Export-Csv -Path $ReportPath -Delimiter ';' -NoTypeInformation -Encoding UTF8
Write-Ok "Protokoll: $ReportPath"

if (-not $ReportOnly -and -not $WhatIf) {
    Write-Host ""
    Write-Host "Rueckgaengig machen:"
    Write-Host "  .\Convert-FoldersToDocumentSets.ps1 -Rollback -ReportPath `"$ReportPath`""
}
