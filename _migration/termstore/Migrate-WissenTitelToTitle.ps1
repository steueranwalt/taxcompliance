<#
.SYNOPSIS
  Übernimmt Werte aus WissenTitel in die Standardspalte Title und entfernt WissenTitel.

.DESCRIPTION
  Behebt die doppelte Anzeige "Titel" (SharePoint-Standard Title vs. WissenTitel).
  1) Kopiert WissenTitel → Title (wenn WissenTitel gesetzt)
  2) Entfernt die Zusatzspalte WissenTitel aus der Bibliothek

.EXAMPLE
  .\Migrate-WissenTitelToTitle.ps1 -LibraryName "Shared Documents"
#>
[CmdletBinding()]
param(
    [string]$LibraryName = "Shared Documents",
    [int]$PageSize = 200,
    [switch]$WhatIf,
    [switch]$KeepField
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

Import-Module PnP.PowerShell -ErrorAction Stop
try { $null = Get-PnPContext } catch { throw "Zuerst Connect-PnPOnline ausführen." }

$list = Get-DocLib $LibraryName
Write-Host "Bibliothek: $($list.Title)" -ForegroundColor Green

$wissenTitel = Get-PnPField -List $list -Identity "WissenTitel" -ErrorAction SilentlyContinue
if (-not $wissenTitel) {
    Write-Host "Spalte WissenTitel existiert nicht – nichts zu migrieren." -ForegroundColor Yellow
    return
}

$copied = 0; $skipped = 0; $errors = 0; $scanned = 0

# Alle Dateien mit WissenTitel laden (paged)
$items = @(Get-PnPListItem -List $list -PageSize $PageSize -Fields "ID", "FileLeafRef", "FileRef", "Title", "WissenTitel", "FSObjType" -ErrorAction Stop)

foreach ($item in $items) {
    try {
        $fs = $item["FSObjType"]
        if ($null -ne $fs -and [int]$fs -ne 0) { continue }
    } catch {}

    $scanned++
    $src = $null
    try { $src = $item["WissenTitel"] } catch {}
    if ($null -eq $src) {
        try { $src = $item.FieldValues["WissenTitel"] } catch {}
    }
    $srcText = ("{0}" -f $src).Trim()
    if (-not $srcText) {
        $skipped++
        continue
    }

    # SharePoint Title max ~255
    if ($srcText.Length -gt 255) { $srcText = $srcText.Substring(0, 255) }

    $itemId = [int]$item.Id
    $leaf = ""
    try { $leaf = [string]$item["FileLeafRef"] } catch {}

    if ($WhatIf) {
        Write-Host ("[WhatIf] Id={0} {1} Title <= {2}" -f $itemId, $leaf, $srcText) -ForegroundColor Yellow
        $copied++
        continue
    }

    try {
        Set-PnPListItem -List $list -Identity $itemId -Values @{ Title = $srcText } -ErrorAction Stop | Out-Null
        $copied++
        if ($copied -le 15 -or ($copied % 50) -eq 0) {
            Write-Host ("OK Id={0} Title <= {1}" -f $itemId, $srcText) -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning ("Id={0}: {1}" -f $itemId, $_.Exception.Message)
        $errors++
    }
}

Write-Host ""
Write-Host "Migration: scannedFiles~$scanned copied=$copied skippedEmpty=$skipped errors=$errors" -ForegroundColor Green

if ($KeepField) {
    Write-Host "WissenTitel bleibt erhalten (-KeepField)." -ForegroundColor Yellow
    return
}

if ($WhatIf) {
    Write-Host "[WhatIf] Remove-PnPField WissenTitel" -ForegroundColor Yellow
    return
}

if ($errors -gt 0) {
    Write-Warning "Wegen Fehlern wird WissenTitel NICHT gelöscht. Bitte erneut ausführen oder -KeepField nutzen."
    return
}

try {
    Remove-PnPField -List $list -Identity "WissenTitel" -Force -ErrorAction Stop
    Write-Host "Spalte WissenTitel entfernt. Standard-Title (Anzeigename 'Titel') bleibt die einzige Titelsäule." -ForegroundColor Green
}
catch {
    Write-Warning "Konnte WissenTitel nicht löschen: $($_.Exception.Message)"
    Write-Host "Manuell: Bibliothekseinstellungen → Spalte WissenTitel/Titel (Zusatz) löschen." -ForegroundColor Yellow
}
