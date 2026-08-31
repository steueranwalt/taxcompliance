<#
.SYNOPSIS
  Schritt 2: Legt den Inhaltstyp "Wissensmappe" (Dokumentenmappe) an und
  registriert ihn in der Zielbibliothek.

.DESCRIPTION
  Erbt von 0x0120D520 (Dokumentenmappe) und traegt die Facetten, die fuer eine
  ganze Mappe gelten (vgl. _migration/termstore/ARCHITECTURE.md):

    Feld am Inhaltstyp   Rolle
    -------------------  --------------------------------------------------
    Title                Sprechender Mappentitel
    WissenRechtsgebiet   Fachgebiet der Mappe        -> geteiltes Feld
    WissenRechtsordnung  Rechtsraum der Mappe        -> geteiltes Feld
    WissenSchlagworte    Querschnittsthemen          -> geteiltes Feld

  "Geteiltes Feld" (Shared Field) heisst: der an der Mappe gesetzte Wert wird
  von SharePoint auf alle Dokumente in der Mappe durchgeschrieben. Genau das
  ersetzt das bisherige "Metadatum steckt nur im Ordnernamen".

  Bewusst NICHT geteilt, weil dokumentspezifisch:
    WissenDokumenttyp, WissenJahr, WissenAutor, WissenWerk, WissenSeite,
    WissenFundstelle, WissenAktenzeichen

  Idempotent: vorhandener Inhaltstyp und vorhandene Feldbindungen werden
  uebersprungen.

.EXAMPLE
  Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive
  .\New-WissenMappeContentType.ps1 -WhatIf
  .\New-WissenMappeContentType.ps1
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://obenhaus.sharepoint.com/sites/Wissen",
    [string]$LibraryName = "Freigegebene Dokumente",
    [string]$ContentTypeName = "Wissensmappe",
    [string]$ContentTypeGroup = "Wissen Metadaten",
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

# Felder am Inhaltstyp der Mappe
$MappeFields = @("WissenRechtsgebiet", "WissenRechtsordnung", "WissenSchlagworte")

# Felder, deren Wert auf die enthaltenen Dokumente durchgeschrieben wird
$SharedFields = @("WissenRechtsgebiet", "WissenRechtsordnung", "WissenSchlagworte")

# Felder auf der Willkommensseite der Mappe
$WelcomePageFields = @("Title", "WissenRechtsgebiet", "WissenRechtsordnung", "WissenSchlagworte")

Connect-Wissen -Connect:$Connect -SiteUrl $SiteUrl -Interactive:$Interactive -ClientId $ClientId -Tenant $Tenant

$list = Get-WissenList -Name $LibraryName
Write-Ok "Bibliothek: $($list.Title) (Id=$($list.Id))"

# --- 1. Voraussetzungen --------------------------------------------------
$docSetBase = Get-PnPContentType -Identity $script:CtIdDocumentSet -ErrorAction SilentlyContinue
if (-not $docSetBase) {
    throw "Basis-Inhaltstyp Dokumentenmappe ($script:CtIdDocumentSet) fehlt. Zuerst .\Enable-Dokumentenmappen.ps1 ausfuehren."
}

$missingFields = @()
foreach ($f in ($MappeFields | Select-Object -Unique)) {
    if (-not (Get-PnPField -Identity $f -ErrorAction SilentlyContinue)) { $missingFields += $f }
}
if ($missingFields.Count -gt 0) {
    throw "Websitespalten fehlen: $($missingFields -join ', '). Diese Spalten legt _migration/termstore/Add-WissenLibraryColumns.ps1 an (dort ggf. auf Websiteebene heben)."
}

# --- 2. Inhaltstyp anlegen ----------------------------------------------
$ct = Get-PnPContentType -Identity $ContentTypeName -ErrorAction SilentlyContinue

if ($ct) {
    Write-Skip "Inhaltstyp vorhanden: $($ct.Name) ($($ct.Id.StringValue))"
}
elseif ($WhatIf) {
    Write-Warn2 "[WhatIf] Add-PnPContentType -Name '$ContentTypeName' -ParentContentType Dokumentenmappe"
}
else {
    Write-Step "Lege Inhaltstyp '$ContentTypeName' an (Eltern: $($docSetBase.Name)) ..."
    Add-PnPContentType -Name $ContentTypeName `
                       -Group $ContentTypeGroup `
                       -Description "Dokumentenmappe fuer ein Wissensthema. Rechtsgebiet, Rechtsordnung und Schlagworte gelten fuer die ganze Mappe und werden auf die enthaltenen Dokumente durchgeschrieben." `
                       -ParentContentType $docSetBase | Out-Null
    $ct = Get-PnPContentType -Identity $ContentTypeName
    Write-Ok "Inhaltstyp angelegt: $($ct.Id.StringValue)"
}

# --- 3. Felder an den Inhaltstyp binden ---------------------------------
if ($ct) {
    $boundFields = @((Get-PnPProperty -ClientObject $ct -Property Fields) | ForEach-Object { $_.InternalName })

    foreach ($f in $MappeFields) {
        if ($f -in $boundFields) {
            Write-Skip "Feld am Inhaltstyp vorhanden: $f"
            continue
        }
        if ($WhatIf) {
            Write-Warn2 "[WhatIf] Add-PnPFieldToContentType -Field $f -ContentType '$ContentTypeName'"
            continue
        }
        Write-Step "Binde Feld an Inhaltstyp: $f"
        Add-PnPFieldToContentType -Field $f -ContentType $ct.Id.StringValue
    }
}
elseif (-not $WhatIf) {
    throw "Inhaltstyp '$ContentTypeName' konnte nicht aufgeloest werden."
}

# --- 4. Geteilte Felder und Willkommensseite ----------------------------
# Die Dokumentenmappen-Vorlage (SharedFields / WelcomePageFields /
# AllowedContentTypes) ist nur ueber CSOM erreichbar; PnP.PowerShell hat dafuer
# kein eigenes Cmdlet. Schlaegt das fehl, wird die UI-Alternative ausgegeben,
# statt die Migration zu blockieren.
function Set-MappeTemplate {
    param($ContentType)

    $csomOk = $true
    try { $null = [Microsoft.Office.DocumentManagement.DocumentSets.DocumentSetTemplate] }
    catch {
        $csomOk = $false
        $dll = Get-ChildItem -Path (Split-Path (Get-Module PnP.PowerShell).Path) `
                             -Filter "Microsoft.SharePoint.Client.DocumentManagement.dll" `
                             -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($dll) {
            try { Add-Type -Path $dll.FullName; $csomOk = $true } catch { $csomOk = $false }
        }
    }
    if (-not $csomOk) { return $false }

    $ctx      = Get-PnPContext
    $template = [Microsoft.Office.DocumentManagement.DocumentSets.DocumentSetTemplate]::GetDocumentSetTemplate($ContentType)
    $ctx.Load($template)
    $ctx.Load($template.SharedFields)
    $ctx.Load($template.WelcomePageFields)
    $ctx.Load($template.AllowedContentTypes)
    $ctx.ExecuteQuery()

    $existingShared  = @($template.SharedFields      | ForEach-Object { $_.InternalName })
    $existingWelcome = @($template.WelcomePageFields | ForEach-Object { $_.InternalName })
    $changed = $false

    foreach ($f in $SharedFields) {
        if ($f -in $existingShared) { Write-Skip "Geteiltes Feld vorhanden: $f"; continue }
        Write-Step "Setze geteiltes Feld: $f"
        $template.SharedFields.Add((Get-PnPField -Identity $f))
        $changed = $true
    }
    foreach ($f in $WelcomePageFields) {
        if ($f -in $existingWelcome) { Write-Skip "Willkommensseiten-Feld vorhanden: $f"; continue }
        Write-Step "Setze Willkommensseiten-Feld: $f"
        $template.WelcomePageFields.Add((Get-PnPField -Identity $f))
        $changed = $true
    }

    # Nur Dokumente in der Mappe zulassen (keine verschachtelten Mappen).
    $allowed = @($template.AllowedContentTypes | ForEach-Object { $_.StringValue })
    if ($allowed -notcontains "0x0101") {
        Write-Step "Erlaube Inhaltstyp Dokument (0x0101) in der Mappe"
        $template.AllowedContentTypes.Add([Microsoft.SharePoint.Client.ContentTypeId]::Parse("0x0101"))
        $changed = $true
    }

    if ($changed) {
        $template.Update($true)
        $ctx.ExecuteQuery()
        Write-Ok "Dokumentenmappen-Vorlage aktualisiert."
    }
    else {
        Write-Skip "Dokumentenmappen-Vorlage bereits vollstaendig."
    }
    return $true
}

if ($WhatIf) {
    Write-Warn2 "[WhatIf] Geteilte Felder: $($SharedFields -join ', ')"
    Write-Warn2 "[WhatIf] Willkommensseite: $($WelcomePageFields -join ', ')"
}
elseif ($ct) {
    $done = $false
    try { $done = Set-MappeTemplate -ContentType $ct }
    catch { Write-Warn2 "Dokumentenmappen-Vorlage per CSOM fehlgeschlagen: $($_.Exception.Message)" }

    if (-not $done) {
        Write-Warn2 @"

Geteilte Felder bitte einmalig in der UI setzen:
  Websiteeinstellungen -> Websiteinhaltstypen -> $ContentTypeName
    -> Einstellungen fuer Dokumentenmappen
    -> Geteilte Spalten:        $($SharedFields -join ', ')
    -> Spalten Willkommensseite: $($WelcomePageFields -join ', ')
    -> Zulaessige Inhaltstypen:  Dokument
Alles andere in dieser Migration funktioniert auch ohne diesen Schritt.
"@
    }
}

# --- 5. Inhaltstyp in der Bibliothek registrieren ------------------------
if (-not $list.ContentTypesEnabled) {
    throw "Inhaltstypen-Verwaltung in '$($list.Title)' ist aus. Zuerst .\Enable-Dokumentenmappen.ps1 ausfuehren."
}

$inList = Get-PnPContentType -List $list.Id -Identity $ContentTypeName -ErrorAction SilentlyContinue
if ($inList) {
    Write-Skip "Inhaltstyp in Bibliothek registriert: $ContentTypeName"
}
elseif ($WhatIf) {
    Write-Warn2 "[WhatIf] Add-PnPContentTypeToList -List '$($list.Title)' -ContentType '$ContentTypeName'"
}
else {
    Write-Step "Registriere Inhaltstyp in Bibliothek '$($list.Title)' ..."
    Add-PnPContentTypeToList -List $list.Id -ContentType $ContentTypeName
    Write-Ok "Registriert."
}

Write-Host ""
Write-Ok "Schritt 2 fertig. Naechster Schritt: .\Convert-FoldersToDocumentSets.ps1 -ReportOnly"
