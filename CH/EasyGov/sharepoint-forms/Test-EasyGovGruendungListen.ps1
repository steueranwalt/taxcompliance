<#
    .SYNOPSIS
    Prueft den EasyGov-Feldkatalog und optional die SharePoint-Zielsite.

    .DESCRIPTION
    Ohne -SiteUrl: rein statische Pruefung von felder.json und wertelisten/
    (IDs eindeutig, Pflicht/Typ gesetzt, Wertelisten existieren, interne
    Namen, Required/FieldRole). Lauffaehig lokal/CI, aendert nichts.

    Mit -SiteUrl/-ClientId: zusaetzlich lesender Soll/Ist-Abgleich analog
    DE/AO/sharepoint-forms/Test-SteuerlicheErfassungListen.ps1.

    Die Soll-Felder kommen aus felder.json, derselben Quelle wie
    New-EasyGovGruendungListen.ps1 — keine zweite Feldliste.

    .EXAMPLE
    .\Test-EasyGovGruendungListen.ps1

    .EXAMPLE
    .\Test-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl,
    [string]$ClientId
)

$ErrorActionPreference = "Stop"

$katalogRoot = Split-Path -Parent $PSScriptRoot
$felderPath = Join-Path $katalogRoot "felder.json"
$wertelistenDir = Join-Path $katalogRoot "wertelisten"
$pythonTest = Join-Path $katalogRoot "tests/test_konsistenz.py"

$abweichungen = [System.Collections.Generic.List[string]]::new()

function Add-Abweichung([string]$Msg) { $abweichungen.Add($Msg) | Out-Null }

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

$katalog = Get-Content -LiteralPath $felderPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ids = @{}
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
}

Write-Host "Statische Katalogpruefung: $($katalog.felder.Count) Felder, $($ids.Count) IDs."

if ($SiteUrl) {
    if (-not $ClientId) { throw "-ClientId ist Pflicht, sobald -SiteUrl gesetzt ist." }
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        throw "PnP.PowerShell ist fuer den Live-Abgleich noetig. Ohne -SiteUrl laeuft die statische Pruefung ohne dieses Modul."
    }
    Import-Module PnP.PowerShell -ErrorAction Stop
    $main = Join-Path $PSScriptRoot "New-EasyGovGruendungListen.ps1"
    if (-not (Test-Path -LiteralPath $main)) { throw "Hauptskript fehlt: $main" }

    function ConvertTo-SpType {
        param([string]$Datentyp, [bool]$Required)
        switch ($Datentyp) {
            "text" { return "Text" }
            "note" { return "Note" }
            "number" { return "Number" }
            "date" { return "DateOnly" }
            "choice" { return "Choice" }
            "multichoice" { return "MultiChoice" }
            "checkbox_group" { return "MultiChoice" }
            "boolean" { if ($Required) { return "Choice" } else { return "Boolean" } }
            "lookup" { return "Text" }
            default { return "Text" }
        }
    }

    function Test-SollTypeMatchesIst {
        param($SollType, $IstField)
        switch ($SollType) {
            "DateOnly" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateOnly") }
            "MultiChoice" { return ($IstField.TypeAsString -eq "MultiChoice") }
            "Note" { return ($IstField.TypeAsString -eq "Note") }
            default { return ($IstField.TypeAsString -eq $SollType) }
        }
    }

    Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
    $soll = @{}
    foreach ($f in $katalog.felder) {
        if (-not $f.sharepoint_liste -or -not $f.sharepoint_internal_name) { continue }
        if ($f.datentyp -in @("aktion", "anzeige")) { continue }
        $key = "$($f.sharepoint_liste)|$($f.sharepoint_internal_name)"
        if ($soll.ContainsKey($key)) { continue }
        $req = [bool]$f.sharepoint_required
        $soll[$key] = [PSCustomObject]@{
            List = $f.sharepoint_liste
            InternalName = $f.sharepoint_internal_name
            Type = ConvertTo-SpType -Datentyp $f.datentyp -Required $req
        }
    }

    $listen = $soll.Values | Select-Object -ExpandProperty List -Unique
    foreach ($listenName in $listen) {
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
