<#
    .SYNOPSIS
    Prueft den EasyGov-Feldkatalog und optional die SharePoint-Zielsite.

    .DESCRIPTION
    Ohne -SiteUrl: rein statische Pruefung von felder.json, wertelisten/,
    luecken.json und der aus dem Katalog abgeleiteten CH_-Skriptspalten
    (IDs eindeutig, Pflicht/Typ gesetzt, Wertelisten existieren, interne
    Namen, Required/FieldRole, Abdeckung der nicht_abgefragt-Luecken).
    Lauffaehig lokal/CI, aendert nichts.

    Mit -SiteUrl/-ClientId: zusaetzlich lesender Soll/Ist-Abgleich analog
    DE/AO/sharepoint-forms/Test-SteuerlicheErfassungListen.ps1.

    Die Soll-Felder kommen aus felder.json, derselben Quelle wie
    New-EasyGovGruendungListen.ps1 — keine zweite Feldliste.

    .PARAMETER ListPrefix
    Dasselbe Praefix wie das New-Skript (Standard CH_). Live-Abgleich
    erwartet die so aufgeloesten Listentitel.

    .EXAMPLE
    .\Test-EasyGovGruendungListen.ps1

    .EXAMPLE
    .\Test-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl,
    [string]$ClientId,
    [string]$ListPrefix = "CH_"
)

$ErrorActionPreference = "Stop"

$katalogRoot = Split-Path -Parent $PSScriptRoot
$felderPath = Join-Path $katalogRoot "felder.json"
$wertelistenDir = Join-Path $katalogRoot "wertelisten"
$lueckenPath = Join-Path $katalogRoot "luecken.json"
$pythonTest = Join-Path $katalogRoot "tests/test_konsistenz.py"
$newScript = Join-Path $PSScriptRoot "New-EasyGovGruendungListen.ps1"

$abweichungen = [System.Collections.Generic.List[string]]::new()

function Add-Abweichung([string]$Msg) { $abweichungen.Add($Msg) | Out-Null }

function Get-ChListName {
    param([Parameter(Mandatory = $true)][string]$LogicalName)
    if ($LogicalName.StartsWith($ListPrefix)) { return $LogicalName }
    return "$ListPrefix$LogicalName"
}

function ConvertTo-SpType {
    param([string]$Datentyp, [bool]$Required, [string]$InternalName = "")
    switch ($Datentyp) {
        "text" { return "Text" }
        "note" { return "Note" }
        "number" { return "Number" }
        "date" { return "DateOnly" }
        "choice" { return "Choice" }
        "multichoice" { return "MultiChoice" }
        "checkbox_group" { return "MultiChoice" }
        "boolean" { if ($Required) { return "Choice" } else { return "Boolean" } }
        "lookup" { return "Text" }  # Portal-Autocomplete. SharePoint-Lookup nur case_id / person_label.
        "datei" { return "Note" }
        "url" { return "URL" }
        "anzeige" {
            if ($InternalName -in @("rev3m_total", "rev3m_relevant")) { return "Number" }
            return "Text"
        }
        default { return "Text" }
    }
}

function Get-SollType {
    param($Feld)
    $req = [bool]$Feld.sharepoint_required
    $name = [string]$Feld.sharepoint_internal_name
    $liste = [string]$Feld.sharepoint_liste
    if ($name -eq "file_link") { return "URL" }
    if ($name -eq "person_label") { return "Lookup" }
    if ($name -eq "case_id" -and $liste -ne "0_Fallsteuerung") { return "Lookup" }
    return ConvertTo-SpType -Datentyp $Feld.datentyp -Required $req -InternalName $name
}

if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "Starte python3 $pythonTest"
    & python3 $pythonTest
    if ($LASTEXITCODE -ne 0) {
        Add-Abweichung "Python-Konsistenztest nicht gruen (Exit $LASTEXITCODE)"
    }
    else {
        Write-Host "Python-Konsistenztest: OK"
    }
}
else {
    Write-Host "python3 nicht gefunden — pruefe JSON nativ."
}

if (-not (Test-Path -LiteralPath $felderPath)) {
    throw "Feldkatalog nicht gefunden: $felderPath"
}
if (-not (Test-Path -LiteralPath $newScript)) {
    throw "Hauptskript fehlt: $newScript"
}

# Beide Skripte muessen fehlerfrei parsen (ohne Ausfuehrung, ohne Tenant).
foreach ($scriptPath in @($newScript, $PSCommandPath)) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        Add-Abweichung "Parse-Fehler in $(Split-Path -Leaf $scriptPath): $($parseErrors -join '; ')"
    }
}

$katalog = Get-Content -LiteralPath $felderPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ids = @{}
$soll = @{}
foreach ($f in $katalog.felder) {
    if ($ids.ContainsKey($f.id)) { Add-Abweichung "Doppelte ID $($f.id)" }
    $ids[$f.id] = $true
    if (-not $f.datentyp) { Add-Abweichung "$($f.id): Datentyp fehlt" }
    if (-not $f.pflichtstatus) { Add-Abweichung "$($f.id): Pflichtstatus fehlt" }
    if ($f.werteliste) {
        $wl = Join-Path $wertelistenDir "$($f.werteliste).json"
        if (-not (Test-Path -LiteralPath $wl)) {
            Add-Abweichung "$($f.id): Werteliste $($f.werteliste) fehlt"
        }
    }
    if ($f.sharepoint_internal_name) {
        $n = [string]$f.sharepoint_internal_name
        if ($n.Length -gt 32 -or $n -notmatch '^[A-Za-z0-9_]+$') {
            Add-Abweichung "$($f.id): interner Name ungueltig ($n)"
        }
        if ($f.sharepoint_required -and $f.field_role -ne "Tatsache" -and $f.datentyp -ne "lookup") {
            Add-Abweichung "$($f.id): Required-Ergebnisfeld"
        }
    }
    if (-not $f.sharepoint_liste -or -not $f.sharepoint_internal_name) { continue }
    if ($f.datentyp -eq "aktion") { continue }
    $key = "$($f.sharepoint_liste)|$($f.sharepoint_internal_name)"
    if ($soll.ContainsKey($key)) { continue }
    $soll[$key] = [PSCustomObject]@{
        LogicalList  = [string]$f.sharepoint_liste
        List         = Get-ChListName ([string]$f.sharepoint_liste)
        InternalName = [string]$f.sharepoint_internal_name
        Type         = Get-SollType -Feld $f
    }
}

# case_id-Lookup auf jeder Folgeliste analog New-Skript
$logicalLists = @(
    "0_Fallsteuerung", "1_Unternehmen", "2_Personen", "3_Kapital", "3_Anteile",
    "4_HR_Diverses", "5_MWST", "6_AHV", "7_UVG", "8_Unterlagen",
    "Technische_Mindestfelder", "Eingang_Fehler"
)
foreach ($logical in $logicalLists) {
    $resolved = Get-ChListName $logical
    if ($resolved -cnotlike "CH_*") {
        Add-Abweichung "Aufgeloeste Liste '$resolved' (logisch $logical) hat kein CH_-Praefix"
    }
    if ($logical -in @("0_Fallsteuerung", "Eingang_Fehler")) { continue }
    $key = "$logical|case_id"
    $soll[$key] = [PSCustomObject]@{
        LogicalList  = $logical
        List         = $resolved
        InternalName = "case_id"
        Type         = "Lookup"
    }
}

# Lookup-Typen muessen mit dem New-Skript uebereinstimmen (nicht Text).
$personLabel = $soll["3_Anteile|person_label"]
if (-not $personLabel) {
    Add-Abweichung "person_label fehlt im Soll"
}
elseif ($personLabel.Type -ne "Lookup") {
    Add-Abweichung "person_label Solltyp=$($personLabel.Type), erwartet Lookup"
}
$techCase = $soll["Technische_Mindestfelder|case_id"]
if (-not $techCase -or $techCase.Type -ne "Lookup") {
    Add-Abweichung "Technische_Mindestfelder/case_id Solltyp muss Lookup sein"
}
$fileLink = $soll["8_Unterlagen|file_link"]
if (-not $fileLink) {
    Add-Abweichung "8_Unterlagen/file_link fehlt"
}
elseif ($fileLink.Type -ne "URL") {
    Add-Abweichung "file_link Solltyp=$($fileLink.Type), erwartet URL"
}

foreach ($anzeigeName in @("resMunicipality", "domMunicipality", "hr_office", "rev3m_total", "rev3m_relevant", "suggested_insurer")) {
    $hit = $soll.Values | Where-Object { $_.InternalName -eq $anzeigeName }
    if (-not $hit) {
        Add-Abweichung "anzeige-Feld mit Mapping fehlt als Skriptspalte: $anzeigeName"
    }
}

if (Test-Path -LiteralPath $lueckenPath) {
    $luecken = Get-Content -LiteralPath $lueckenPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($gap in $luecken.nicht_abgefragt) {
        if (-not $gap.spalten -or @($gap.spalten).Count -eq 0) {
            Add-Abweichung "Luecke $($gap.id) ohne spalten"
            continue
        }
        foreach ($col in $gap.spalten) {
            $key = "$($col.liste)|$($col.internal_name)"
            if (-not $soll.ContainsKey($key)) {
                Add-Abweichung "Luecke $($gap.id): Spalte $key nicht in Skriptspalten / felder.json"
            }
        }
    }
}
else {
    Add-Abweichung "luecken.json fehlt"
}

Write-Host "Statische Katalogpruefung: $($katalog.felder.Count) Felder, $($ids.Count) IDs, $($soll.Count) Skriptspalten (Praefix $ListPrefix)."

if ($SiteUrl) {
    if (-not $ClientId) { throw "-ClientId ist Pflicht, sobald -SiteUrl gesetzt ist." }
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        throw "PnP.PowerShell ist fuer den Live-Abgleich noetig. Ohne -SiteUrl laeuft die statische Pruefung ohne dieses Modul."
    }
    Import-Module PnP.PowerShell -ErrorAction Stop

    function Test-SollTypeMatchesIst {
        param($SollType, $IstField)
        switch ($SollType) {
            "DateOnly" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateOnly") }
            "MultiChoice" { return ($IstField.TypeAsString -eq "MultiChoice") }
            "Note" { return ($IstField.TypeAsString -eq "Note") }
            "URL" { return ($IstField.TypeAsString -eq "URL") }
            "Lookup" { return ($IstField.TypeAsString -eq "Lookup") }
            default { return ($IstField.TypeAsString -eq $SollType) }
        }
    }

    Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
    $listen = $soll.Values | Select-Object -ExpandProperty List -Unique
    foreach ($listenName in $listen) {
        if ($listenName -cnotlike "CH_*") {
            Add-Abweichung "Live-Abgleich wuerde Liste ohne CH_-Praefix lesen: $listenName"
            continue
        }
        $listObj = Get-PnPList -Identity $listenName -ErrorAction SilentlyContinue
        $felderDieser = $soll.Values | Where-Object { $_.List -eq $listenName }
        if (-not $listObj) {
            foreach ($def in $felderDieser) {
                Add-Abweichung "Liste fehlt: $listenName (Feld $($def.InternalName))"
            }
            continue
        }
        $ist = @{}
        foreach ($fld in (Get-PnPField -List $listenName)) { $ist[$fld.InternalName] = $fld }
        foreach ($def in $felderDieser) {
            if (-not $ist.ContainsKey($def.InternalName)) {
                Add-Abweichung "Spalte fehlt: $listenName / $($def.InternalName)"
                continue
            }
            if (-not (Test-SollTypeMatchesIst -SollType $def.Type -IstField $ist[$def.InternalName])) {
                Add-Abweichung "Feldtyp: $listenName / $($def.InternalName) Soll=$($def.Type) Ist=$($ist[$def.InternalName].TypeAsString)"
            }
        }
    }
}

Write-Host ""
if ($abweichungen.Count -eq 0) {
    Write-Host "ERGEBNIS: OK"
    exit 0
}
Write-Host "ERGEBNIS: $($abweichungen.Count) Abweichungen"
$abweichungen | ForEach-Object { Write-Host "  - $_" }
exit 1
