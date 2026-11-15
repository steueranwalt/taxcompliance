<#
    .SYNOPSIS
    Legt die SharePoint-Listenfamilie "EasyGov Unternehmensgruendung CH" an
    bzw. gleicht eine vorhandene Installation an felder.json an.

    Feldkatalog: CH/EasyGov/felder.json
    Wertelisten: CH/EasyGov/wertelisten/
    Architektur: CH/EasyGov/Einheitliches-Datenmodell-easygov-unternehmensgruendung.md
                 CH/EasyGov/sharepoint-forms/README.md

    .DESCRIPTION
    Leitet die Spalten aus dem maschinenlesbaren Datenmodell ab (keine zweite,
    von Hand gepflegte Feldliste). Idempotent wie
    DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1:
      - Fehlende Listen/Spalten werden angelegt.
      - Vorhandene Spalten werden angeglichen (Anzeigename, Pflicht,
        fehlende Auswahlwerte ergaenzt, nie entfernt).
      - Es werden nie Listen, Spalten oder Auswahlwerte geloescht.

    Alle Listen erhalten das Praefix CH_ (Parameter -ListPrefix, Standard CH_),
    damit die produktiven DE/AO-Listen auf derselben Site
    (https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei) unangetastet
    bleiben. Vor jeder Aenderung: hartes ABBRUCH, falls eine Liste ohne
    CH_-Praefix geaendert wuerde. -WhatIf verbindet nicht und listet nur.

    Dieses Skript wird in der Agent-Session NICHT gegen einen Tenant ausgefuehrt.

    .PARAMETER SiteUrl
    Zielsite. Standard der Kanzlei: https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei
    Bei -WhatIf nicht noetig.

    .PARAMETER ClientId
    Tenant-eigene Entra-App mit delegierter Berechtigung AllSites.FullControl.
    Siehe DE/AO/sharepoint-forms/README.md Abschnitt C1. Bei -WhatIf nicht noetig.

    .PARAMETER ListPrefix
    Praefix aller CH-Listen. Standard CH_. Lookups zielen auf die so
    aufgeloesten Listen. Ein Lauf, der eine Liste ohne CH_-Praefix aendern
    wuerde, bricht vorher ab.

    .EXAMPLE
    .\New-EasyGovGruendungListen.ps1 -WhatIf

    .EXAMPLE
    .\New-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [string]$SiteUrl,

    [string]$ClientId,

    [string]$ListPrefix = "CH_"
)

$ErrorActionPreference = "Stop"

$script:ListPrefix = $ListPrefix
# pwsh 7 setzt WhatIfPreference unter -WhatIf auf True, nicht auf Continue.
$script:WhatIfMode = $false
if ($PSBoundParameters.ContainsKey("WhatIf") -and $PSBoundParameters["WhatIf"]) {
    $script:WhatIfMode = $true
}
elseif ($WhatIfPreference -and "$WhatIfPreference" -ne "SilentlyContinue") {
    $script:WhatIfMode = $true
}

if (-not $script:WhatIfMode) {
    if ([string]::IsNullOrWhiteSpace($SiteUrl) -or [string]::IsNullOrWhiteSpace($ClientId)) {
        throw "SiteUrl und ClientId sind Pflicht, sobald nicht -WhatIf. Zielsite laut Entscheid: https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei"
    }
}

$katalogRoot = Split-Path -Parent $PSScriptRoot
$felderPath = Join-Path $katalogRoot "felder.json"
$wertelistenDir = Join-Path $katalogRoot "wertelisten"

if (-not (Test-Path -LiteralPath $felderPath)) {
    throw "Feldkatalog nicht gefunden: $felderPath"
}

function Get-ChListName {
    param([Parameter(Mandatory = $true)][string]$LogicalName)
    if ([string]::IsNullOrWhiteSpace($LogicalName)) {
        throw "Leerer logischer Listenname."
    }
    if ($LogicalName.StartsWith($script:ListPrefix)) {
        return $LogicalName
    }
    return "$($script:ListPrefix)$LogicalName"
}

function Test-ChListPrefix {
    <#
      Harte Kollisionsbremse: dieses Skript darf keine Liste aendern, deren
      Titel nicht mit CH_ beginnt. Die DE/AO-Listen 0_Fallsteuerung … 9_Grundbesitz
      auf derselben Site bleiben damit unangetastet.
    #>
    param([Parameter(Mandatory = $true)][string]$ListName)
    if ($ListName -cnotlike "CH_*") {
        throw "ABBRUCH vor jeder Aenderung: Liste '$ListName' hat kein CH_-Praefix. Dieses Skript aendert keine DE/AO-Listen."
    }
}

function Get-WertelisteChoices {
    param([string]$Name)
    if (-not $Name) { return @() }
    $path = Join-Path $wertelistenDir "$Name.json"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Werteliste '$Name' nicht gefunden: $path"
    }
    $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    return @($json.werte | ForEach-Object { [string]$_.wert })
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
        "boolean" {
            # Required-Boolean laesst sich in SharePoint nur mit Ja speichern
            # (DE/AO README C2). Pflicht-Ja/Nein deshalb als Choice.
            if ($Required) { return "Choice" }
            return "Boolean"
        }
        "lookup" { return "Text" }  # Portal-Autocomplete. SharePoint-Lookup nur case_id / person_label.
        "datei" { return "Note" }
        "url" { return "URL" }
        "anzeige" {
            # Portal zeigt den Wert; Datenmodell speichert ihn, wenn ein Mapping
            # gesetzt ist (Adresse.Gemeinde, HR-Amt, MWST-Summen, UVG-Schaetzung).
            if ($InternalName -in @("rev3m_total", "rev3m_relevant")) { return "Number" }
            return "Text"
        }
        default { return "Text" }
    }
}

$katalog = Get-Content -LiteralPath $felderPath -Raw -Encoding UTF8 | ConvertFrom-Json
$spFields = @{}
foreach ($f in $katalog.felder) {
    if (-not $f.sharepoint_liste -or -not $f.sharepoint_internal_name) { continue }
    if ($f.datentyp -eq "aktion") { continue }
    $key = "$($f.sharepoint_liste)|$($f.sharepoint_internal_name)"
    if (-not $spFields.ContainsKey($key)) {
        $required = [bool]$f.sharepoint_required
        $internal = [string]$f.sharepoint_internal_name
        $type = ConvertTo-SpType -Datentyp $f.datentyp -Required $required -InternalName $internal
        if ($internal -eq "person_label") { $type = "Lookup" }
        if ($internal -eq "case_id" -and [string]$f.sharepoint_liste -ne "0_Fallsteuerung") { $type = "Lookup" }
        $choices = @()
        if ($f.werteliste -and $type -in @("Choice", "MultiChoice")) {
            $choices = Get-WertelisteChoices -Name $f.werteliste
        }
        elseif ($type -eq "Choice" -and $f.datentyp -eq "boolean") {
            $choices = @("Ja", "Nein")
        }
        $role = if ($f.field_role) { [string]$f.field_role } else { "Tatsache" }
        $spFields[$key] = [PSCustomObject]@{
            List         = [string]$f.sharepoint_liste
            InternalName = [string]$f.sharepoint_internal_name
            DisplayName  = [string]$f.label
            Type         = $type
            Required     = $required
            Choices      = $choices
            FieldRole    = $role
            HideFromForms = ($f.sharepoint_internal_name -eq "access_code")
        }
    }
    else {
        $existing = $spFields[$key]
        if ($f.sharepoint_required) { $existing.Required = $true }
        if ($f.label -and $f.label.Length -gt $existing.DisplayName.Length) {
            $existing.DisplayName = [string]$f.label
        }
    }
}

foreach ($def in $spFields.Values) {
    if ($def.InternalName.Length -gt 32 -or $def.InternalName -notmatch '^[A-Za-z0-9_]+$') {
        throw "Ungueltiger interner Feldname $($def.List)/$($def.InternalName)"
    }
    if ($def.Required -and $def.FieldRole -ne "Tatsache" -and $def.Type -ne "Lookup") {
        throw "Required-Ergebnisfeld: $($def.List)/$($def.InternalName) FieldRole=$($def.FieldRole)"
    }
}

Write-Host "Namensregel-Pruefung bestanden: $($spFields.Count) SharePoint-Felder aus felder.json."
function Get-NormalizedChoiceKey {
    <#
      Review Nils 28.10.2026 (2_Unternehmens_Gruendungsmodul, Rechtsform-Choices):
      auf der frisch angelegten Site fanden sich Dubletten/Schreibvarianten bei
      Auswahlwerten (z. B. "ausl. Rechtsform" einmal mit Umlaut, einmal als "ae";
      "UG" und "UG (haftungsbeschränkt)" nebeneinander). Normalisiert einen
      Auswahlwert fuer den Vergleich: Kleinschreibung, ae/oe/ue/ss statt
      ae/oe/ue/ss statt Umlaute und Eszett, mehrfache Leerzeichen zusammengefasst. Dient NUR dem Erkennen
      von Schreibvarianten derselben Bedeutung, nicht der Anzeige - die
      tatsaechlichen Choice-Werte in SharePoint bleiben immer mit echten
      Umlauten (Empfehlung README.md Abschnitt C).
    #>
    param([Parameter(Mandatory = $true)][string]$Value)
    $normalized = $Value.Trim().ToLowerInvariant()
    $normalized = $normalized.Replace("ä", "ae").Replace("ö", "oe").Replace("ü", "ue").Replace(([char]0x00DF).ToString(), "ss")
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

function New-ListIfMissing {
    param([string]$Title, [string]$Template = "GenericList")
    Test-ChListPrefix -ListName $Title
    if ($script:WhatIfMode) {
        Write-Host "[WhatIf] Liste sicherstellen (anlegen falls fehlend, nie loeschen): $Title"
        return
    }
    $existing = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue
    if (-not $existing) {
        Write-Host "Lege Liste an: $Title"
        New-PnPList -Title $Title -Template $Template -EnableVersioning | Out-Null
    }
    else {
        Write-Host "Liste existiert bereits: $Title"
    }
    Set-TitleOptional -List $Title
}

function Set-TitleOptional {
    <#
      Punkt 1 der fachlichen Pruefung: "Title" ist in allen SharePoint-Standardlisten
      per Vorlage Pflicht. Die Forms-Flows setzen "Title" nicht zwangslaeufig
      (die fachliche Kennung je Liste ist eine eigene Spalte, z. B. case_id).
      Deshalb wird "Title" ueberall optional geschaltet; die Flows SOLLTEN "Title"
      trotzdem befuellen (Lesbarkeit in der SharePoint-Ansicht), siehe README.md.
    #>
    param([string]$List)
    try {
        $titleField = Get-PnPField -List $List -Identity "Title" -ErrorAction Stop
        if ($titleField.Required) {
            Set-PnPField -List $List -Identity "Title" -Values @{ Required = $false } -WarningAction Stop | Out-Null
            $verify = Get-PnPField -List $List -Identity "Title" -ErrorAction Stop
            if ($verify.Required) {
                throw "Rueckgelesen ist 'Title' weiterhin Pflicht (Required=$($verify.Required))."
            }
            Write-Host "  'Title' auf optional gesetzt und verifiziert: $List"
        }
    }
    catch {
        Write-Warning "  Konnte 'Title' in '$List' nicht auf optional setzen/verifizieren: $_"
    }
}

function Get-XmlEscaped {
    param([string]$Text)
    return [System.Security.SecurityElement]::Escape($Text)
}

function Test-FieldTypeMatchesSchema {
    <#
      Punkt C der fachlichen Pruefung (Testlauf 27./28.10.2026): ordnet den im
      Skript verwendeten logischen -Type-Werten den tatsaechlichen SharePoint-
      Feldtyp (TypeAsString) sowie bei Datumsfeldern das DisplayFormat zu und
      vergleicht gegen ein bereits vorhandenes Feld. Spiegelt bewusst dieselbe
      Logik wie Test-SteuerlicheErfassungListen.ps1, damit Haupt- und
      Pruefskript bei einer Typabweichung denselben Befund melden.
    #>
    param([string]$SollType, $IstField)
    switch ($SollType) {
        "DateOnly" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateOnly") }
        "DateTime" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateTime") }
        "Note" { return ($IstField.TypeAsString -eq "Note") }
        "URL" { return ($IstField.TypeAsString -eq "URL") }
        "MultiChoice" { return ($IstField.TypeAsString -eq "MultiChoice") }
        default { return ($IstField.TypeAsString -eq $SollType) }
    }
}

function Format-FieldTypeForDisplay {
    param($IstField)
    if ($IstField.TypeAsString -eq "DateTime") {
        return "DateTime (DisplayFormat=$($IstField.DisplayFormat))"
    }
    return $IstField.TypeAsString
}

function Set-DateOnlyFormat {
    <#
      Punkt B der fachlichen Pruefung (Testlauf 27./28.10.2026): 13 bereits
      bestehende Datumsfelder standen trotz -Type DateOnly im Skript auf der
      Zielsite mit DisplayFormat=DateTime, weil die bisherige Angleichungslogik
      DisplayFormat bei bereits vorhandenen Feldern nie nachzog (nur die
      XML-Erstellung neuer Felder setzte Format='DateOnly' korrekt). Fix: wird
      jetzt nach jeder Feldanlage/-angleichung unbedingt aufgerufen (wie
      Set-FieldIndexAndUniqueness/Set-LookupDeleteBehavior), prueft den
      Ist-Zustand und setzt DisplayFormat bei Abweichung direkt per CSOM
      (FieldDateTime.DisplayFormat), da Set-PnPField denselben
      Enum-Konvertierungsfehler zeigen kann wie bei RelationshipDeleteBehavior
      (siehe Set-LookupDeleteBehavior). Liest danach zurueck und verifiziert,
      bevor Erfolg gemeldet wird.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName
    )
    try {
        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        if ($field.TypeAsString -ne "DateTime") {
            throw "Feld ist kein Datumsfeld (TypeAsString=$($field.TypeAsString)); DateOnly nicht anwendbar - vermutlich Typabweichung, siehe Warnung oben."
        }
        if ($field.DisplayFormat -ne "DateOnly") {
            $ctx = Get-PnPContext
            $dateField = $ctx.CastTo[Microsoft.SharePoint.Client.FieldDateTime]($field)
            $dateField.DisplayFormat = [Microsoft.SharePoint.Client.DateTimeFieldFormatType]::DateOnly
            $dateField.Update()
            Invoke-PnPQuery
        }
        $verify = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        if ($verify.DisplayFormat -ne "DateOnly") {
            throw "Rueckgelesenes DisplayFormat '$($verify.DisplayFormat)' entspricht nicht dem Sollwert 'DateOnly'."
        }
        Write-Host "  DateOnly-Format gesetzt und verifiziert: $List / $InternalName"
    }
    catch {
        Write-Warning "  Konnte DateOnly-Format fuer $List/$InternalName nicht setzen/verifizieren: $_"
    }
}

function Set-FieldFormVisibility {
    <#
      Review Nils 28.10.2026 (0_Fallsteuerung): access_code wird ausschliesslich
      von einem Flow gesetzt, nie von Hand. Damit niemand versehentlich ueber das
      native SharePoint-Listenformular (NewForm.aspx/EditForm.aspx - zu
      unterscheiden von den Microsoft-Forms-Umfragen F0-F9!) einen eigenen Wert
      eintraegt, wird das Feld dort ausgeblendet (ShowInNewForm/ShowInEditForm =
      FALSE). In der Anzeige (DisplayForm) bleibt es sichtbar, damit die Kanzlei
      den Code bei Bedarf nachschlagen kann. Gilt fuer neue und bestehende Felder
      gleichermassen (unbedingter Aufruf am Ende von Add-Field).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName
    )
    try {
        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        if ($field.ShowInNewForm -or $field.ShowInEditForm) {
            Set-PnPField -List $List -Identity $InternalName -Values @{ ShowInNewForm = $false; ShowInEditForm = $false } -WarningAction Stop | Out-Null
            $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
            if ($field.ShowInNewForm -or $field.ShowInEditForm) {
                throw "Rueckgelesen ist das Feld weiterhin im Neu- oder Bearbeiten-Formular sichtbar (ShowInNewForm=$($field.ShowInNewForm), ShowInEditForm=$($field.ShowInEditForm))."
            }
            Write-Host "  Feld im Neu-/Bearbeiten-Formular ausgeblendet und verifiziert: $List / $InternalName"
        }
    }
    catch {
        Write-Warning "  Konnte Feld $List/$InternalName nicht im Neu-/Bearbeiten-Formular ausblenden: $_"
    }
}

function Set-FieldIndexAndUniqueness {
    <#
      Punkt 2 der fachlichen Pruefung: case_id (und neu: access_code) in
      0_Fallsteuerung sind weder indiziert noch eindeutig. SharePoint verlangt,
      dass ein Feld zuerst indiziert wird, bevor EnforceUniqueValues gesetzt
      werden kann. Schlaegt EnforceUniqueValues fehl (z. B. weil aus einem
      frueheren, nicht-idempotenten Lauf bereits doppelte Werte existieren),
      wird dies nur als Warnung ausgegeben, damit der Rest des Skripts
      weiterlaeuft.

      Testlauf 27.10.2026 (PnP.PowerShell 3.4.1 / PowerShell 7.6.9) ergab: eine
      Set-PnPField-Eigenschaftsaenderung kann intern nur eine WARNUNG werfen
      ("Value will be ignored") statt eines Fehlers, und das Skript meldete
      danach faelschlich Erfolg. Deshalb jetzt -WarningAction Stop (macht jede
      PnP-Warnung zu einem fangbaren Fehler) UND ein Rueckgelesen-Vergleich vor
      jeder Erfolgsmeldung.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [switch]$EnforceUniqueValues
    )
    try {
        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        if (-not $field.Indexed) {
            Set-PnPField -List $List -Identity $InternalName -Values @{ Indexed = $true } -WarningAction Stop | Out-Null
            $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
            if (-not $field.Indexed) {
                throw "Rueckgelesen ist das Feld weiterhin nicht indiziert (Indexed=$($field.Indexed))."
            }
            Write-Host "  Feld indiziert und verifiziert: $List / $InternalName"
        }
        if ($EnforceUniqueValues) {
            $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
            if (-not $field.EnforceUniqueValues) {
                Set-PnPField -List $List -Identity $InternalName -Values @{ EnforceUniqueValues = $true } -WarningAction Stop | Out-Null
                $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
                if (-not $field.EnforceUniqueValues) {
                    throw "Rueckgelesen hat das Feld weiterhin keine eindeutigen Werte (EnforceUniqueValues=$($field.EnforceUniqueValues))."
                }
                Write-Host "  Feld auf eindeutige Werte gesetzt und verifiziert: $List / $InternalName"
            }
        }
    }
    catch {
        Write-Warning "  Konnte Index/Eindeutigkeit fuer $List/$InternalName nicht setzen/verifizieren (ggf. vorhandene Duplikate zuerst bereinigen): $_"
    }
}

function Set-LookupDeleteBehavior {
    <#
      Punkt 10 der fachlichen Pruefung: Loeschverhalten von Lookups definieren.
      - "Restrict" fuer den tragenden case_id-Bezug jeder Folgeliste: ein
        Fallsteuerungs-Datensatz darf nicht geloescht werden, solange noch
        Folgedatensaetze darauf verweisen (Datenintegritaet/Revisionssicherheit).
      - "None" (Standard, unveraendert) fuer die optionalen Sekundaerbezuege in
        8_Unterlagen (related_person/related_participation/related_site), damit
        das Loeschen einer Person/Beteiligung/Betriebsstaette nicht an einer
        angehaengten Unterlage scheitert.

      KORRIGIERT nach echtem Testlauf 27.10.2026 (PnP.PowerShell 3.4.1 /
      PowerShell 7.6.9), der zwei echte Fehler ergab, die das Skript faelschlich
      als Erfolg meldete:
      1. Set-PnPField kann den String "Restrict"/"Cascade" NICHT zuverlaessig in
         den Enum-Typ Microsoft.SharePoint.Client.RelationshipDeleteBehaviorType
         konvertieren - es kam nur die WARNUNG "Setting property
         'RelationshipDeleteBehavior' ... Value will be ignored.", waehrend das
         Skript danach "Loeschverhalten gesetzt" ausgab. Fix: den Enum-Wert
         direkt per CSOM setzen (FieldLookup-Objekt via ClientContext.CastTo),
         nicht ueber Set-PnPFields generische -Values-Eigenschaftszuweisung.
      2. "Restrict"/"Cascade" verlangen einen INDIZIERTEN Lookup; das Skript
         indizierte Lookup-Felder bislang nicht automatisch. Fix: vor dem
         Setzen des Loeschverhaltens IMMER zuerst Set-FieldIndexAndUniqueness
         aufrufen, unabhaengig davon, ob der Add-Field-Aufruf -Indexed gesetzt
         hat.
      Nach dem Setzen wird der Wert in jedem Fall zurueckgelesen und mit dem
      Sollwert verglichen, bevor Erfolg gemeldet wird. Gilt fuer neue und
      bestehende Felder gleichermassen, da diese Funktion nach jeder
      Feldanlage/-angleichung unbedingt aufgerufen wird.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [ValidateSet("None", "Restrict", "Cascade")][string]$DeleteBehavior = "None"
    )
    if ($DeleteBehavior -eq "None") { return }
    try {
        # Restrict/Cascade verlangen einen indizierten Lookup (siehe oben).
        Set-FieldIndexAndUniqueness -List $List -InternalName $InternalName

        $ctx = Get-PnPContext
        $targetEnum = [Microsoft.SharePoint.Client.RelationshipDeleteBehaviorType]$DeleteBehavior

        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        $lookupField = $ctx.CastTo[Microsoft.SharePoint.Client.FieldLookup]($field)
        $ctx.Load($lookupField)
        Invoke-PnPQuery

        if (-not ($lookupField.Indexed -and $lookupField.RelationshipDeleteBehavior -eq $targetEnum)) {
            $lookupField.RelationshipDeleteBehavior = $targetEnum
            # UpdateAndPushChanges($true) statt Update(): noetig, damit SharePoint
            # die Aenderung auch bei einem bereits bestehenden (ggf. befuellten)
            # Lookup-Feld auf die abhaengigen Listenbeziehungen anwendet.
            $lookupField.UpdateAndPushChanges($true)
            Invoke-PnPQuery
        }

        # Zurueck lesen und verifizieren, bevor Erfolg gemeldet wird - NIE blind
        # "gesetzt" melden, nur weil Set-PnPField/CSOM keinen Fehler geworfen hat.
        $verifyField = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        $verifyLookup = $ctx.CastTo[Microsoft.SharePoint.Client.FieldLookup]($verifyField)
        $ctx.Load($verifyLookup)
        Invoke-PnPQuery
        if (-not $verifyLookup.Indexed) {
            throw "Rueckgelesen ist der Lookup weiterhin nicht indiziert (Indexed=$($verifyLookup.Indexed)); Restrict/Cascade greift ohne Index nicht."
        }
        if ($verifyLookup.RelationshipDeleteBehavior -ne $targetEnum) {
            throw "Rueckgelesenes Loeschverhalten '$($verifyLookup.RelationshipDeleteBehavior)' entspricht nicht dem Sollwert '$DeleteBehavior'."
        }
        Write-Host "  Loeschverhalten gesetzt und verifiziert ($DeleteBehavior): $List / $InternalName"
    }
    catch {
        Write-Warning "  Konnte Loeschverhalten fuer $List/$InternalName nicht auf '$DeleteBehavior' setzen/verifizieren: $_"
    }
}

function Add-Field {
    <#
      Zentrale Feld-Anlage- und -Angleichungsfunktion.

      Neu gegenueber der Vorversion:
      - -Type DateOnly: reines Datumsfeld ohne Uhrzeit (Punkt 3).
      - -Type URL: Hyperlink-Feld (fuer file_link in 8_Unterlagen).
      - -DefaultValue: Default fuer Boolean/Text/Note/Number (Punkt 7).
      - -Min/-Max: Wertebereich fuer Number-Felder (Punkt 10: share_percentage 0-100).
      - -Decimals: Nachkommastellen fuer Number-Felder (Punkt C: notification_year
        ohne Nachkommastellen).
      - -ValidationFormula/-ValidationMessage: Spaltenvalidierung.
      - -Indexed/-EnforceUniqueValues: siehe Set-FieldIndexAndUniqueness.
      - -DeleteBehavior: siehe Set-LookupDeleteBehavior (nur Type Lookup).
      - Angleichung bestehender Felder: Anzeigename, Pflichtstatus und fehlende
        Auswahlwerte (nie Entfernen) werden bei bereits vorhandenen Feldern
        nachgezogen. Eine Typabweichung (z. B. Soll Note, Ist Text) wird klar
        gewarnt, aber nie automatisch geaendert oder geloescht (Punkt C).
      - -Type DateOnly: DisplayFormat wird unbedingt verifiziert/nachgezogen,
        siehe Set-DateOnlyFormat (Punkt B).
      - -HideFromForms: blendet das Feld im nativen SharePoint-Neu-/Bearbeiten-
        Formular aus (ShowInNewForm/ShowInEditForm = FALSE), siehe
        Set-FieldFormVisibility. Fuer Flow-generierte Felder wie access_code.
      - -FieldRole/-AppliesTo: reine Metadaten (wirken NIE auf die SharePoint-
        Spalte selbst) fuer externe Generatoren (z. B. den Mandanten-Chat in
        DE/AO/erfassungs-chat/), die aus diesem Skript ableiten, welche Felder
        sie dem Mandanten stellen duerfen. Format und Wertebereich siehe
        README.md Abschnitt C3 ("Feld-Metadaten fuer externe Generatoren").
        Harte Regel, die hier zusaetzlich zur Dokumentation erzwungen wird:
        ein Feld mit -FieldRole "Ergebnis" oder "System" darf NIE -Required
        sein - genau dieses Muster (Required-Ergebnisfeld) meldete der
        Erfassungs-Chat-Generator am 28.10.2026 fuer vier Felder
        (tax_office, formation_type, profit_determination_method, site_type;
        die ersten beiden waren zu diesem Zeitpunkt bereits durch die
        Grundregel-Arbeit in diesem Skript behoben).

      Defensive Namensregel-Pruefung zusaetzlich zur Pruefung der aus
      felder.json abgeleiteten internen Namen am Skriptanfang.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Text", "Note", "Number", "Boolean", "Choice", "MultiChoice", "Lookup", "DateOnly", "DateTime", "URL")]
        [string]$Type,
        [switch]$Required,
        [string[]]$Choices,
        [string]$LookupList,
        [string]$LookupField = "Title",
        [ValidateSet("None", "Restrict", "Cascade")][string]$DeleteBehavior = "None",
        [Nullable[double]]$Min,
        [Nullable[double]]$Max,
        [Nullable[int]]$Decimals,
        [string]$DefaultValue,
        [switch]$Indexed,
        [switch]$EnforceUniqueValues,
        [string]$ValidationFormula,
        [string]$ValidationMessage,
        [switch]$HideFromForms,
        [ValidateSet("Tatsache", "Ergebnis", "System")][string]$FieldRole = "Tatsache",
        [ValidateSet("Alle", "Gesellschaft", "NatuerlichePerson")][string[]]$AppliesTo = @("Alle")
    )

    Test-ChListPrefix -ListName $List
    if ($Type -eq "Lookup") {
        if (-not $LookupList) { throw "Lookup '$InternalName' ($List) ohne -LookupList." }
        Test-ChListPrefix -ListName $LookupList
    }
    if ($InternalName.Length -gt 32 -or $InternalName -notmatch '^[A-Za-z0-9_]+$') {
        throw "Ungueltiger interner Feldname '$InternalName' ($List): > 32 Zeichen oder Zeichen ausserhalb [A-Za-z0-9_]."
    }
    if ($Required -and $FieldRole -ne "Tatsache" -and $Type -ne "Lookup") {
        # Lookup ausgenommen: case_id ist in jeder Folgeliste -Required UND
        # -FieldRole System (technischer Fremdschluessel, wird vom Flow/der
        # Session gesetzt, nie von einem Menschen "beantwortet" - die
        # Required-Boolean-Falle betrifft nur Felder, die ein Mensch ueber
        # ein Pflicht-UI-Element ausfuellen muesste).
        throw "Feld '$InternalName' ($List) ist -Required, aber -FieldRole '$FieldRole' - widerspricht der Grundregel: Ergebnis-/Systemfelder duerfen nie vom Mandanten zwingend erfragt werden. Siehe README.md Abschnitt C3."
    }

    if ($script:WhatIfMode) {
        $reqLabel = if ($Required) { " Required" } else { "" }
        $lookupLabel = if ($Type -eq "Lookup") { " -> $LookupList.$LookupField" } else { "" }
        Write-Host "[WhatIf] Spalte sicherstellen (anlegen oder angleichen, nie loeschen): $List / $InternalName ($Type$reqLabel$lookupLabel)"
        return
    }

    $existing = Get-PnPField -List $List -Identity $InternalName -ErrorAction SilentlyContinue

    if (-not $existing) {
        $requiredAttr = if ($Required) { "TRUE" } else { "FALSE" }
        $escapedDisplayName = Get-XmlEscaped $DisplayName

        switch ($Type) {
            "Choice" {
                $choiceXml = ($Choices | ForEach-Object { "<CHOICE>$(Get-XmlEscaped $_)</CHOICE>" }) -join ""
                $fieldXml = "<Field Type='Choice' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' Format='Dropdown'><CHOICES>$choiceXml</CHOICES></Field>"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "MultiChoice" {
                $choiceXml = ($Choices | ForEach-Object { "<CHOICE>$(Get-XmlEscaped $_)</CHOICE>" }) -join ""
                $fieldXml = "<Field Type='MultiChoice' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'><CHOICES>$choiceXml</CHOICES></Field>"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "Lookup" {
                $targetList = Get-PnPList -Identity $LookupList
                $deleteBehaviorAttr = ""
                $indexedAttr = ""
                if ($DeleteBehavior -ne "None") {
                    $deleteBehaviorAttr = " RelationshipDeleteBehavior='$DeleteBehavior'"
                    # Bug gefunden 27./28.10.2026 auf einer FRISCHEN, leeren Site
                    # (transferpricingdocs/steuerdaten): Restrict/Cascade verlangen
                    # einen indizierten Lookup bereits bei der ERSTANLAGE, nicht erst
                    # bei einer spaeteren Angleichung. Add-PnPFieldFromXml brach sonst
                    # ab mit "Dieses Nachschlagefeld kann kein Verhalten fuer
                    # Beziehungen erzwingen, weil es nicht indiziert ist." Auf einer
                    # bereits bestehenden Site (z. B. obenhaus) fiel das nicht auf,
                    # weil die Lookups dort schon vorhanden und indiziert waren - das
                    # Skript lief nur noch durch die Angleichung (Set-LookupDeleteBehavior
                    # ruft dort bereits Set-FieldIndexAndUniqueness zuerst auf). Fix:
                    # Indexed='TRUE' gleich im Erstellungs-XML mitgeben, damit beide
                    # Faelle (frische und bestehende Site) idempotent funktionieren.
                    $indexedAttr = " Indexed='TRUE'"
                }
                $fieldXml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' List='{$($targetList.Id)}' ShowField='$LookupField'$deleteBehaviorAttr$indexedAttr />"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "DateOnly" {
                $fieldXml = "<Field Type='DateTime' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' Format='DateOnly' />"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "DateTime" {
                $fieldXml = "<Field Type='DateTime' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' Format='DateTime' />"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "Number" {
                $minMaxAttr = ""
                if ($null -ne $Min) { $minMaxAttr += " Min='$Min'" }
                if ($null -ne $Max) { $minMaxAttr += " Max='$Max'" }
                if ($null -ne $Decimals) { $minMaxAttr += " Decimals='$Decimals'" }
                $validationXml = ""
                if ($ValidationFormula) {
                    $validationXml = "<Validation Message='$(Get-XmlEscaped $ValidationMessage)'>$(Get-XmlEscaped $ValidationFormula)</Validation>"
                }
                if ($minMaxAttr -or $validationXml -or $DefaultValue) {
                    $defaultXml = if ($DefaultValue) { "<Default>$(Get-XmlEscaped $DefaultValue)</Default>" } else { "" }
                    $fieldXml = "<Field Type='Number' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'$minMaxAttr>$defaultXml$validationXml</Field>"
                    Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
                }
                else {
                    Add-PnPField -List $List -InternalName $InternalName -DisplayName $DisplayName -Type Number -Required:$Required | Out-Null
                }
            }
            "Boolean" {
                if ($DefaultValue) {
                    $fieldXml = "<Field Type='Boolean' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'><Default>$(Get-XmlEscaped $DefaultValue)</Default></Field>"
                    Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
                }
                else {
                    Add-PnPField -List $List -InternalName $InternalName -DisplayName $DisplayName -Type Boolean -Required:$Required | Out-Null
                }
            }
            "URL" {
                Add-PnPField -List $List -InternalName $InternalName -DisplayName $DisplayName -Type URL -Required:$Required | Out-Null
            }
            default {
                # Text, Note
                if ($DefaultValue -or $ValidationFormula) {
                    $spType = if ($Type -eq "Note") { "Note" } else { "Text" }
                    $defaultXml = if ($DefaultValue) { "<Default>$(Get-XmlEscaped $DefaultValue)</Default>" } else { "" }
                    $validationXml = ""
                    if ($ValidationFormula) {
                        $validationXml = "<Validation Message='$(Get-XmlEscaped $ValidationMessage)'>$(Get-XmlEscaped $ValidationFormula)</Validation>"
                    }
                    $fieldXml = "<Field Type='$spType' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'>$defaultXml$validationXml</Field>"
                    Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
                }
                else {
                    Add-PnPField -List $List -InternalName $InternalName -DisplayName $DisplayName `
                        -Type $Type -Required:$Required | Out-Null
                }
            }
        }
        Write-Host "  Feld angelegt: $List / $InternalName ($Type)"
    }
    else {
        Write-Host "  Feld existiert bereits, pruefe Angleichung: $List / $InternalName"

        # Punkt C der fachlichen Pruefung (Testlauf 27./28.10.2026): wenn der
        # Ist-Typ nicht dem Soll-Typ entspricht (z. B. notification_year Ist
        # Number statt Text, participant_name_share Ist Text statt Note),
        # klar warnen - NICHT still weiterlaufen, aber auch NICHT automatisch
        # aendern oder loeschen (SharePoint unterstuetzt Typaenderungen an
        # bestehenden Feldern ohnehin nicht zuverlaessig). Typspezifische
        # Angleichung (Choices-Ergaenzung) wird bei einer Typabweichung
        # uebersprungen, da sie auf dem falschen Feldtyp keinen Sinn ergibt.
        $typeMatches = Test-FieldTypeMatchesSchema -SollType $Type -IstField $existing
        if (-not $typeMatches) {
            Write-Warning "    TYP-ABWEICHUNG: Liste=$List Feld=$InternalName Soll=$Type Ist=$(Format-FieldTypeForDisplay $existing) - wird NICHT automatisch geaendert oder geloescht, bitte manuell pruefen."
        }

        if ($existing.Title -ne $DisplayName) {
            try {
                Set-PnPField -List $List -Identity $InternalName -Values @{ Title = $DisplayName } -WarningAction Stop | Out-Null
                $verify = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
                if ($verify.Title -ne $DisplayName) {
                    throw "Rueckgelesener Anzeigename '$($verify.Title)' entspricht nicht dem Sollwert '$DisplayName'."
                }
                Write-Host "    Anzeigename angeglichen und verifiziert -> '$DisplayName'"
            }
            catch {
                Write-Warning "    Konnte Anzeigename fuer $List/$InternalName nicht angleichen: $_"
            }
        }

        if ($Type -ne "Lookup" -and [bool]$existing.Required -ne [bool]$Required) {
            try {
                Set-PnPField -List $List -Identity $InternalName -Values @{ Required = [bool]$Required } -WarningAction Stop | Out-Null
                $verify = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
                if ([bool]$verify.Required -ne [bool]$Required) {
                    throw "Rueckgelesener Pflichtstatus '$($verify.Required)' entspricht nicht dem Sollwert '$Required'."
                }
                Write-Host "    Pflichtstatus angeglichen und verifiziert -> Required=$Required"
            }
            catch {
                Write-Warning "    Konnte Pflichtstatus fuer $List/$InternalName nicht angleichen: $_"
            }
        }

        if ($typeMatches -and $Type -in @("Choice", "MultiChoice") -and $Choices) {
            $existingChoices = @($existing.Choices)
            $missingChoices = $Choices | Where-Object { $existingChoices -notcontains $_ }
            if ($missingChoices) {
                # Testlauf 27.10.2026 ergab: Set-PnPField konnte "Choices" bei
                # bestehenden Feldern nicht setzen ("Object of type
                # 'System.Object[]' cannot be converted to type
                # 'System.String[]'. Value will be ignored."), waehrend das
                # Skript trotzdem "ergaenzt" meldete. Fix: das Array explizit
                # als [string[]] typisieren (nicht als generisches Object[]),
                # -WarningAction Stop, und bei erneutem Fehlschlag per CSOM
                # (FieldChoice.Choices) direkt setzen. Immer zurueck lesen und
                # verifizieren, bevor Erfolg gemeldet wird.
                [string[]]$unionChoices = @($existingChoices) + @($missingChoices)
                try {
                    try {
                        Set-PnPField -List $List -Identity $InternalName -Values @{ Choices = $unionChoices } -WarningAction Stop | Out-Null
                    }
                    catch {
                        Write-Host "    Set-PnPField konnte Auswahlwerte nicht setzen, versuche CSOM-Fallback: $_"
                        $ctx = Get-PnPContext
                        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
                        $choiceField = $ctx.CastTo[Microsoft.SharePoint.Client.FieldChoice]($field)
                        $choiceField.Choices = $unionChoices
                        $choiceField.Update()
                        Invoke-PnPQuery
                    }
                    $verify = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
                    $verifyChoices = @($verify.Choices)
                    $stillMissing = $Choices | Where-Object { $verifyChoices -notcontains $_ }
                    if ($stillMissing) {
                        throw "Nach dem Schreiben fehlen weiterhin Auswahlwerte: $($stillMissing -join ', ')."
                    }
                    Write-Host "    Auswahlwerte ergaenzt und verifiziert (nichts entfernt): $($missingChoices -join ', ')"
                }
                catch {
                    Write-Warning "    Konnte Auswahlwerte fuer $List/$InternalName nicht ergaenzen: $_"
                }
            }
        }
    }

    if ($Indexed -or $EnforceUniqueValues) {
        Set-FieldIndexAndUniqueness -List $List -InternalName $InternalName -EnforceUniqueValues:$EnforceUniqueValues
    }
    if ($Type -eq "Lookup" -and $DeleteBehavior -ne "None") {
        Set-LookupDeleteBehavior -List $List -InternalName $InternalName -DeleteBehavior $DeleteBehavior
    }
    if ($Type -eq "DateOnly") {
        Set-DateOnlyFormat -List $List -InternalName $InternalName
    }
    if ($HideFromForms) {
        Set-FieldFormVisibility -List $List -InternalName $InternalName
    }
}


foreach ($def in $spFields.Values) {
    if ($def.Choices -and $def.Choices.Count -gt 0) {
        $seenChoices = @{}
        foreach ($choice in $def.Choices) {
            $ckey = Get-NormalizedChoiceKey -Value $choice
            if ($seenChoices.ContainsKey($ckey) -and $seenChoices[$ckey] -cne $choice) {
                throw "Schreibvarianten in $($def.List)/$($def.InternalName): '$($seenChoices[$ckey])' vs. '$choice'"
            }
            $seenChoices[$ckey] = $choice
        }
    }
}
Write-Host "Auswahlwert-Dubletten-Pruefung bestanden (Wertelisten aus JSON)."

$logicalLists = @(
    "0_Fallsteuerung",
    "1_Unternehmen",
    "2_Personen",
    "3_Kapital",
    "3_Anteile",
    "4_HR_Diverses",
    "5_MWST",
    "6_AHV",
    "7_UVG",
    "8_Unterlagen",
    "Technische_Mindestfelder",
    "Eingang_Fehler"
)
$listOrder = @($logicalLists | ForEach-Object { Get-ChListName $_ })
foreach ($listName in $listOrder) {
    Test-ChListPrefix -ListName $listName
}

$fallsteuerung = Get-ChListName "0_Fallsteuerung"
$eingangFehler = Get-ChListName "Eingang_Fehler"
$personen = Get-ChListName "2_Personen"
$anteile = Get-ChListName "3_Anteile"

if ($script:WhatIfMode) {
    Write-Host "Trockenlauf (-WhatIf): keine Verbindung, keine Aenderung. Zielsite waere: $(if ($SiteUrl) { $SiteUrl } else { 'https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei' })"
}
else {
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        throw "PnP.PowerShell ist fuer den Live-Lauf noetig. Trockenlauf ohne Tenant: -WhatIf"
    }
    Import-Module PnP.PowerShell -ErrorAction Stop
    if ($PSCmdlet.ShouldProcess($SiteUrl, "Listenfamilie EasyGov CH anlegen oder angleichen")) {
        Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
    }
    else {
        return
    }
}

foreach ($listName in $listOrder) {
    New-ListIfMissing -Title $listName
}

# case_id in Folgelisten als Lookup auf CH_0_Fallsteuerung (nicht im Portal, analog DE/AO)
$followLists = $listOrder | Where-Object { $_ -ne $fallsteuerung -and $_ -ne $eingangFehler }
foreach ($listName in $followLists) {
    Add-Field -List $listName -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
        -LookupList $fallsteuerung -LookupField "case_id" -DeleteBehavior Restrict
}

foreach ($def in ($spFields.Values | Sort-Object List, InternalName)) {
    if ($def.InternalName -eq "case_id" -and $def.List -ne "0_Fallsteuerung") { continue }
    if ($def.List -eq "3_Anteile" -and $def.InternalName -eq "person_label") { continue }

    $addParams = @{
        List         = Get-ChListName $def.List
        InternalName = $def.InternalName
        DisplayName  = $def.DisplayName
        Type         = $def.Type
        FieldRole    = $def.FieldRole
    }
    if ($def.Required) { $addParams["Required"] = $true }
    if ($def.Choices -and $def.Choices.Count -gt 0) { $addParams["Choices"] = [string[]]$def.Choices }
    if ($def.HideFromForms) { $addParams["HideFromForms"] = $true }
    if ($def.List -eq "0_Fallsteuerung" -and $def.InternalName -in @("case_id", "access_code")) {
        $addParams["Indexed"] = $true
        $addParams["EnforceUniqueValues"] = $true
    }
    Add-Field @addParams
}

if ($spFields.ContainsKey("3_Anteile|person_label")) {
    Add-Field -List $anteile -InternalName "person_label" -DisplayName "Gesellschafter Anzeigelabel" -Type Lookup -Required -FieldRole "System" `
        -LookupList $personen -LookupField "display_label" -DeleteBehavior None
}

if ($script:WhatIfMode) {
    Write-Host "Trockenlauf fertig. Es wurde nichts angelegt oder geaendert."
}
else {
    Write-Host "Fertig. Listenfamilie EasyGov Unternehmensgruendung (Praefix $script:ListPrefix) angelegt bzw. angeglichen."
}
