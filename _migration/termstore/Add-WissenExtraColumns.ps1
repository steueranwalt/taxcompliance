<#
.SYNOPSIS
  Legt Zusatzspalten in Bibliothek Dokumente an (Jahr, Autor, Fundstelle).

.DESCRIPTION
  Alle Dokumente:
    - Jahr (Zahl)
    - Autor (Text)   # Intern: WissenAutor (nicht SharePoint "Autor"/Created By)

  Fundstelle (für Dokumenttyp Verwaltungsanweisung, Kommentar, Fachaufsatz,
  Urteil / Rechtsprechung, Gesetzesmaterialien):
    - Werk (Zeitschrift / Kommentarwerk)
    - Seite
    - Fundstelle (Freitext, optional vollständige Zitation)

  Jahr der Fundstelle = Spalte Jahr (gemeinsam).

.EXAMPLE
  Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "c77bfeb7-7624-497f-85d7-e509c5ec9dbc" -Tenant "transferpricingdocs.onmicrosoft.com"
  .\Add-WissenExtraColumns.ps1 -LibraryName "Shared Documents"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://transferpricingdocs.sharepoint.com/sites/wissen",
    [string]$LibraryName = "Shared Documents",
    [string]$FieldGroup = "Wissen Metadaten",
    [switch]$Connect,
    [switch]$Interactive,
    [string]$ClientId,
    [string]$Tenant,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Type: Number | Text | Note
$Columns = @(
    @{
        DisplayName  = "Jahr"
        InternalName = "WissenJahr"
        Type         = "Number"
        Description  = "Erscheinungs- / Entscheidungsjahr (auch Teil der Fundstelle)."
    },
    @{
        DisplayName  = "Autor"
        InternalName = "WissenAutor"
        Type         = "Text"
        Description  = "Autor bzw. Verfasser (nicht SharePoint-Ersteller)."
    },
    @{
        DisplayName  = "Werk"
        InternalName = "WissenWerk"
        Type         = "Text"
        Description  = "Zeitschrift, Kommentarwerk oder amtliche Sammlung (Teil der Fundstelle)."
    },
    @{
        DisplayName  = "Seite"
        InternalName = "WissenSeite"
        Type         = "Text"
        Description  = "Seite oder Randnummer, z. B. 123 oder 123-145."
    },
    @{
        DisplayName  = "Fundstelle"
        InternalName = "WissenFundstelle"
        Type         = "Note"
        Description  = "Optionale vollständige Zitation; strukturiert über Werk + Jahr + Seite."
    },
    @{
        DisplayName  = "Titel"
        InternalName = "WissenTitel"
        Type         = "Text"
        Description  = "Dokumenttitel (Internes Memo, Fachaufsatz)."
    },
    @{
        DisplayName  = "Aktenzeichen"
        InternalName = "WissenAktenzeichen"
        Type         = "Text"
        Description  = "Gerichts- oder Behördenaktenzeichen (Urteil, Verwaltungsanweisung)."
    }
)

function Connect-Wissen {
    if (-not $Connect) { return }
    $params = @{ Url = $SiteUrl }
    if ($ClientId) { $params.ClientId = $ClientId }
    if ($Tenant) { $params.Tenant = $Tenant }
    if ($Interactive) { $params.Interactive = $true } else { $params.DeviceLogin = $true }
    Connect-PnPOnline @params
}

function Get-ListOrThrow {
    param([string]$Name)

    foreach ($candidate in @(
            $Name,
            "Shared Documents",
            "/sites/wissen/Shared Documents",
            "Dokumente",
            "Documents",
            "Freigegebene Dokumente"
        )) {
        $list = Get-PnPList -Identity $candidate -ErrorAction SilentlyContinue
        if ($list) {
            $aliases = @("dokumente", "documents", "freigegebene dokumente", "shared documents", "wissen")
            if ($candidate -eq $Name -or $Name.Trim().ToLowerInvariant() -in $aliases) {
                return $list
            }
        }
    }

    $libs = @(Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 })
    $needle = $Name.Trim().ToLowerInvariant()
    $match = $libs | Where-Object { $_.Title.ToLowerInvariant() -eq $needle } | Select-Object -First 1
    if (-not $match -and $needle -in @("dokumente", "documents", "freigegebene dokumente", "shared documents", "wissen")) {
        $match = $libs | Where-Object { $_.Title -eq "Dokumente" -or $_.Title -eq "Documents" } | Select-Object -First 1
    }
    if ($match) {
        $resolved = Get-PnPList -Identity $match.Id -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved }
        return $match
    }

    $available = ($libs | ForEach-Object { $_.Title }) -join ", "
    throw "Bibliothek '$Name' nicht gefunden. Verfügbare Dokumentbibliotheken: $available"
}

function Ensure-Field {
    param($List, [hashtable]$Column)

    $existing = Get-PnPField -List $List -Identity $Column.InternalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Vorhanden: $($Column.DisplayName) ($($Column.InternalName))" -ForegroundColor DarkGray
        return "exists"
    }

    Write-Host "Lege an: $($Column.DisplayName) [$($Column.Type)]" -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "[WhatIf] Add-PnPField $($Column.InternalName)" -ForegroundColor Yellow
        return "whatif"
    }

    $params = @{
        List            = $List
        DisplayName     = $Column.DisplayName
        InternalName    = $Column.InternalName
        Type            = $Column.Type
        Group           = $FieldGroup
        AddToDefaultView = $false
    }

    Add-PnPField @params | Out-Null

    if ($Column.Description) {
        Set-PnPField -List $List -Identity $Column.InternalName -Values @{ Description = $Column.Description } -ErrorAction SilentlyContinue
    }
    return "created"
}

Import-Module PnP.PowerShell -ErrorAction Stop
Connect-Wissen

try { $null = Get-PnPContext }
catch { throw "Keine PnP-Verbindung. Zuerst Connect-PnPOnline ausführen oder -Connect nutzen." }

$list = Get-ListOrThrow -Name $LibraryName
Write-Host "Bibliothek: $($list.Title) (Id=$($list.Id))" -ForegroundColor Green

$stats = @{ created = 0; exists = 0; whatif = 0 }
foreach ($col in $Columns) {
    $result = Ensure-Field -List $list -Column $col
    $stats[$result]++
}

Write-Host ""
Write-Host "Fertig. created=$($stats.created) exists=$($stats.exists) whatif=$($stats.whatif)" -ForegroundColor Green
Write-Host @"

Verwendung nach Dokumenttyp:
  alle Dokumente:
    - Jahr, Autor
  Internes Memo / Fachaufsatz:
    - Titel
  Urteil / Rechtsprechung / Verwaltungsanweisung:
    - Aktenzeichen
  Verwaltungsanweisung / Kommentar / Fachaufsatz / Urteil / Gesetzesmaterialien:
    - Fundstelle = Werk + Jahr + Seite
    - optional Freitext-Spalte Fundstelle
"@
