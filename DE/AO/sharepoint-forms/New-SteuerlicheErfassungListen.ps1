#Requires -Modules PnP.PowerShell
<#
    .SYNOPSIS
    Legt die SharePoint-Listenfamilie "Steuerliche Erfassung DE / Auslandsbezug" an
    (Liste 0-8, die internen Referenzlisten "Technische_Mindestfelder" und
    "Eingang_Fehler") bzw. gleicht eine bereits vorhandene Installation an den
    aktuellen Feldkatalog an.

    Feldkatalog und Architektur: siehe
      DE/AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md
        (Abschnitt 9: Mandanten-Erhebungsmatrix Rechtsformen/Auslandssachverhalte)
      DE/AO/formulardaten-roherfassung.md
      DE/AO/sharepoint-forms/README.md (Abschnitt E: Forms-Spezifikation)

    .DESCRIPTION
    Das Skript ist idempotent:
      - Fehlende Listen/Spalten werden angelegt.
      - Bereits vorhandene Spalten werden ANGEGLICHEN (Anzeigename, Pflichtstatus,
        fehlende Auswahlwerte werden ERGAENZT, nie entfernt; Index/Eindeutigkeit/
        Loeschverhalten werden nachgezogen, soweit SharePoint das im Nachhinein
        zulaesst).
      - Es werden NIE Spalten oder Listen geloescht oder Auswahlwerte entfernt.
        Jede Angleichung, die bei bereits vorhandenen Daten fehlschlagen kann
        (z. B. EnforceUniqueValues bei vorhandenen Duplikaten), wird abgefangen
        und nur als Warnung ausgegeben, damit ein einzelner Problemfall nicht den
        gesamten Lauf abbricht.

    .PARAMETER SiteUrl
    Vor Ausfuehrung pruefen, welche der beiden Zielsites externes Teilen
    technisch zulaesst (Website-Einstellungen -> Freigabe -> Erweiterte
    Einstellungen):
      1. https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei
      2. https://obenhaus.sharepoint.com/sites/service

    .PARAMETER ClientId
    Seit September 2024 ist die generische PnP-Management-Shell-App
    (31359c7f-bd7e-475c-86db-fdb8c937548e) fuer neue Tenants standardmaessig
    gesperrt bzw. abgeschaltet. -ClientId ist daher FAKTISCH PFLICHT: eine
    tenant-eigene Azure-AD/Entra-App-Registrierung verwenden mit
      - Kontotyp: "Konten nur in diesem Organisationsverzeichnis" (single tenant)
      - Plattform: "Mobile and desktop applications", Redirect-URI
        "http://localhost" (Public-Client-Flow, kein Client-Secret noetig)
      - API-Berechtigung: SharePoint -> Delegiert -> AllSites.FullControl
        (Admin-Zustimmung erforderlich)
    Danach den Admin-Consent im Tenant erteilen und die ClientId hier
    uebergeben. Siehe README.md Abschnitt C1 fuer die vollstaendige Anleitung.

    .EXAMPLE
    .\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"

    .NOTES
    Dieses Skript wird in dieser Session NICHT gegen einen Tenant ausgefuehrt.
    Es ist ausschliesslich fuer die spaetere Ausfuehrung durch eine berechtigte
    Person vorgesehen.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true, HelpMessage = "ClientId einer tenant-eigenen Entra-App-Registrierung mit delegierter Berechtigung 'AllSites.FullControl' (siehe README.md Abschnitt C1). Die generische PnP-Management-Shell-App ist seit 09/2024 in den meisten Tenants gesperrt.")]
    [string]$ClientId
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Harte Namensregel-Pruefung VOR jeder Verbindung/Aenderung
#
# Testlauf 27./28.10.2026 (PnP.PowerShell 3.4.1 / PowerShell 7.6.9) ergab:
# SharePoint kuerzt interne Feldnamen (InternalName) intern auf 32 Zeichen.
# Ueberlange Namen fuehrten dazu, dass das Skript das Feld beim naechsten
# Angleichungslauf unter dem vollen (ungekuerzten) Namen nicht mehr fand und
# es ERNEUT anlegte - SharePoint haengte dem (ebenfalls gekuerzten) Namen des
# neuen Duplikats automatisch einen Zahlen-Suffix (_0, _1, ...) an. Betroffen
# waren 6 Felder (seitdem umbenannt, siehe README.md Abschnitt "Changelog").
#
# Deshalb: vor jeder Ausfuehrung ALLE im Skript selbst verwendeten
# -InternalName-Werte statisch pruefen (per AST-Parse des eigenen Skripts,
# ohne es auszufuehren) und bei Verstoss SOFORT abbrechen - bevor ueberhaupt
# eine Verbindung aufgebaut wird.
# ---------------------------------------------------------------------------
function Test-InternalFieldNamingRules {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Konnte '$ScriptPath' nicht auf gueltige interne Feldnamen pruefen (Parse-Fehler im Skript selbst): $($parseErrors -join '; ')"
    }

    $commandAsts = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Add-Field' },
        $true)

    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($cmd in $commandAsts) {
        $elements = $cmd.CommandElements
        $listValue = $null
        $internalNameValue = $null
        for ($i = 1; $i -lt $elements.Count; $i++) {
            $el = $elements[$i]
            if ($el -is [System.Management.Automation.Language.CommandParameterAst] -and ($i + 1) -lt $elements.Count) {
                if ($el.ParameterName -eq 'List') { $listValue = $elements[$i + 1].SafeGetValue() }
                elseif ($el.ParameterName -eq 'InternalName') { $internalNameValue = $elements[$i + 1].SafeGetValue() }
            }
        }
        if ($internalNameValue) {
            if ($internalNameValue.Length -gt 32) {
                $violations.Add("$listValue / $internalNameValue : $($internalNameValue.Length) Zeichen (Grenze: 32 - SharePoint kuerzt sonst stillschweigend)")
            }
            if ($internalNameValue -notmatch '^[A-Za-z0-9_]+$') {
                $violations.Add("$listValue / $internalNameValue : enthaelt Zeichen ausserhalb [A-Za-z0-9_]")
            }
        }
    }

    if ($violations.Count -gt 0) {
        throw "Ungueltige interne Feldnamen gefunden - Abbruch VOR jeder Verbindung/Aenderung:`n  $($violations -join "`n  ")"
    }
    Write-Host "Namensregel-Pruefung bestanden: alle internen Feldnamen <= 32 Zeichen und nur [A-Za-z0-9_]."
}

function Get-NormalizedChoiceKey {
    <#
      Review Nils 28.10.2026 (2_Unternehmens_Gruendungsmodul, Rechtsform-Choices):
      auf der frisch angelegten Site fanden sich Dubletten/Schreibvarianten bei
      Auswahlwerten (z. B. "ausl. Rechtsform" einmal mit Umlaut, einmal als "ae";
      "UG" und "UG (haftungsbeschränkt)" nebeneinander). Normalisiert einen
      Auswahlwert fuer den Vergleich: Kleinschreibung, ae/oe/ue/ss statt
      ä/ö/ü/ß, mehrfache Leerzeichen zusammengefasst. Dient NUR dem Erkennen
      von Schreibvarianten derselben Bedeutung, nicht der Anzeige - die
      tatsaechlichen Choice-Werte in SharePoint bleiben immer mit echten
      Umlauten (Empfehlung README.md Abschnitt C).
    #>
    param([Parameter(Mandatory = $true)][string]$Value)
    $normalized = $Value.Trim().ToLowerInvariant()
    $normalized = $normalized.Replace("ä", "ae").Replace("ö", "oe").Replace("ü", "ue").Replace("ß", "ss")
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

function Test-ChoiceValueDuplicates {
    <#
      Statischer Selbsttest (Review Nils 28.10.2026): prueft JEDE einzelne
      -Choices-Liste eines Add-Field-Aufrufs in diesem Skript auf
      Schreibvarianten-Dubletten (z. B. gleicher Wert einmal mit Umlaut, einmal
      ohne). Die auf der Zielsite tatsaechlich gefundenen Dubletten stammen
      nach Befund aus mehreren, nacheinander gegen dieselbe Site gelaufenen
      HISTORISCHEN Skriptversionen (die nicht-destruktive Angleichung ergaenzt
      Auswahlwerte nur, entfernt nie) - nicht aus der aktuellen Fassung dieses
      Skripts selbst. Dieser Selbsttest kann solche historisch akkumulierten
      Dubletten auf einer bereits produktiven Site deshalb NICHT erkennen (er
      liest nie von SharePoint); das uebernimmt Test-SteuerlicheErfassungListen.ps1
      (liest die tatsaechlichen Ist-Choices). Dieser Selbsttest ist ein
      zusaetzliches Sicherheitsnetz gegen kuenftige Kopier-/Tippfehler
      INNERHALB eines einzelnen Add-Field-Aufrufs, bevor ueberhaupt eine
      Verbindung aufgebaut wird.
    #>
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Konnte '$ScriptPath' nicht auf Auswahlwert-Dubletten pruefen (Parse-Fehler im Skript selbst): $($parseErrors -join '; ')"
    }

    $commandAsts = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Add-Field' },
        $true)

    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($cmd in $commandAsts) {
        $elements = $cmd.CommandElements
        $listValue = $null
        $internalNameValue = $null
        $choicesValue = $null
        for ($i = 1; $i -lt $elements.Count; $i++) {
            $el = $elements[$i]
            if ($el -is [System.Management.Automation.Language.CommandParameterAst] -and ($i + 1) -lt $elements.Count) {
                if ($el.ParameterName -eq 'List') { $listValue = $elements[$i + 1].SafeGetValue() }
                elseif ($el.ParameterName -eq 'InternalName') { $internalNameValue = $elements[$i + 1].SafeGetValue() }
                elseif ($el.ParameterName -eq 'Choices') { $choicesValue = @($elements[$i + 1].SafeGetValue()) }
            }
        }
        if ($choicesValue) {
            $seen = @{}
            foreach ($choice in $choicesValue) {
                $key = Get-NormalizedChoiceKey -Value $choice
                # -cne (fallunterscheidend!) statt -ne: PowerShell vergleicht
                # Strings mit -ne standardmaessig GROSS-/KLEINSCHREIBUNGS-
                # UNABHAENGIG, wodurch z. B. "Unbekannt" vs. "unbekannt" sonst
                # faelschlich als identisch durchgehen wuerde (im End-to-End-
                # Selbsttest 28.10.2026 mit absichtlich eingefuegter Dublette
                # reproduziert und mit -cne behoben).
                if ($seen.ContainsKey($key) -and $seen[$key] -cne $choice) {
                    $violations.Add("$listValue / $internalNameValue : '$($seen[$key])' vs. '$choice' (normalisiert identisch: '$key')")
                }
                $seen[$key] = $choice
            }
        }
    }

    if ($violations.Count -gt 0) {
        throw "Schreibvarianten-Dubletten in Auswahlwerten gefunden - Abbruch VOR jeder Verbindung/Aenderung:`n  $($violations -join "`n  ")"
    }
    Write-Host "Auswahlwert-Dubletten-Pruefung bestanden: keine Schreibvarianten innerhalb einer Choices-Liste."
}

Test-InternalFieldNamingRules -ScriptPath $PSCommandPath
Test-ChoiceValueDuplicates -ScriptPath $PSCommandPath

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

function New-ListIfMissing {
    param([string]$Title, [string]$Template = "GenericList")
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
      unterscheiden von den Microsoft-Forms-Umfragen F0-F8!) einen eigenen Wert
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

      Defensive Namensregel-Pruefung (zusaetzlich zur Pruefung am Skriptanfang,
      siehe Test-InternalFieldNamingRules): da $InternalName hier immer ein
      literaler String aus dem Skript ist, sollte die Pruefung am Skriptanfang
      jeden Verstoss bereits vor der ersten Verbindung abfangen. Diese zweite,
      lokale Pruefung ist nur ein zusaetzliches Sicherheitsnetz.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Text", "Note", "Number", "Boolean", "Choice", "Lookup", "DateOnly", "DateTime", "URL")]
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

    if ($InternalName.Length -gt 32 -or $InternalName -notmatch '^[A-Za-z0-9_]+$') {
        throw "Ungueltiger interner Feldname '$InternalName' ($List): > 32 Zeichen oder Zeichen ausserhalb [A-Za-z0-9_]. Siehe Test-InternalFieldNamingRules."
    }
    if ($Required -and $FieldRole -ne "Tatsache" -and $Type -ne "Lookup") {
        # Lookup ausgenommen: case_id ist in jeder Folgeliste -Required UND
        # -FieldRole System (technischer Fremdschluessel, wird vom Flow/der
        # Session gesetzt, nie von einem Menschen "beantwortet" - die
        # Required-Boolean-Falle betrifft nur Felder, die ein Mensch ueber
        # ein Pflicht-UI-Element ausfuellen muesste).
        throw "Feld '$InternalName' ($List) ist -Required, aber -FieldRole '$FieldRole' - widerspricht der Grundregel: Ergebnis-/Systemfelder duerfen nie vom Mandanten zwingend erfragt werden. Siehe README.md Abschnitt C3."
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

        if ($typeMatches -and $Type -eq "Choice" -and $Choices) {
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

# ---------------------------------------------------------------------------
# Liste 0: Fallsteuerung (zuerst, da alle Folgelisten hierauf verweisen)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "0_Fallsteuerung"
Add-Field -List "0_Fallsteuerung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "0_Fallsteuerung" -InternalName "access_code" -DisplayName "Zugangscode (Mandantenpruefung, automatisch per Flow erzeugt)" -Type Text `
    -Indexed -EnforceUniqueValues -HideFromForms
# access_code (Review Nils 28.10.2026): Zufallswert je Fall, da Fall-IDs im
# Format JJJJ-NNNN leicht erratbar sind (fortlaufende Nummer). NIEMAND traegt
# den Wert von Hand ein - der fallanlegende Power-Automate-Flow erzeugt ihn IM
# SELBEN "Element erstellen"-Schritt wie case_id (z. B. per Ausdruck
# toUpper(substring(guid(),0,10))) und baut ihn in den vorausgefuellten Link zu
# den Formularen 1-8 ein. Spaetere Flows pruefen case_id UND access_code
# gemeinsam, bevor eine Formularantwort einem Fall zugeordnet wird. Deshalb
# -HideFromForms (im nativen SharePoint-Neu-/Bearbeiten-Formular ausgeblendet,
# siehe Set-FieldFormVisibility) und bewusst weiterhin nicht -Required (ein
# nachtraegliches Pflichtfeld ohne Default wuerde bei bereits vorhandenen
# Eintraegen die Spaltenanlage verhindern). Zum Zusammenspiel von
# EnforceUniqueValues mit leeren Werten: siehe README.md Abschnitt D1.
Add-Field -List "0_Fallsteuerung" -InternalName "direction" -DisplayName "Richtung" -Type Choice -Required `
    -Choices @("Ausländische Gesellschaft mit Bezug zu Deutschland (Inbound)", "Deutsche Gesellschaft/Person mit Auslandsbezug (Outbound)")
# direction (Review Nils 28.10.2026): "Inbound"/"Outbound" allein waren fuer die
# Kanzlei nicht selbsterklaerend. Die Fachbegriffe bleiben als Klammerzusatz
# erhalten, der Haupttext ist jetzt verstaendliches Deutsch. BREAKING CHANGE
# fuer bestehende Flows: jede Power-Automate-Bedingung, die bisher exakt auf
# "Inbound"/"Outbound" prueft, muss auf den neuen vollen Wortlaut umgestellt
# werden - siehe README.md Abschnitt H (Changelog) fuer die Alt/Neu-Zuordnung.
Add-Field -List "0_Fallsteuerung" -InternalName "form_type" -DisplayName "Rechtsform / Formulartyp" -Type Choice -Required `
    -Choices @("Einzelunternehmen", "Kapitalgesellschaft oder Genossenschaft", "Personengesellschaft oder -gemeinschaft", "Körperschaft nach ausländischem Recht", "BZSt2-Mitteilung")
Add-Field -List "0_Fallsteuerung" -InternalName "registration_status" -DisplayName "Bereits steuerlich erfasst" -Type Choice `
    -Choices @("Ja", "Nein", "Unbekannt")
# registration_status (Review Nils 28.10.2026) ERSETZT already_registered
# (Boolean, war -Required): ein als Pflicht markiertes Ja/Nein-Feld liess sich
# in SharePoint nur mit "Ja" sauber ausfuellen (Checkbox-Verhalten bei
# Required-Yes/No). Jetzt optionales Choice-Feld mit "Unbekannt" als dritter
# Option. already_registered wird von diesem Skript nicht mehr angelegt oder
# angeglichen (Typaenderung Boolean -> Choice ist laut Punkt C nicht automatisch
# moeglich) - auf Bestandssites manuell loeschen, siehe README.md Abschnitt H
# (beide bislang bekannten Sites hatten beim Wechsel 0 Eintraege in
# 0_Fallsteuerung, die alte Spalte kann also gefahrlos entfernt werden).
Add-Field -List "0_Fallsteuerung" -InternalName "existing_tax_number" -DisplayName "Bestehende Steuernummer" -Type Text
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office_country" -DisplayName "Land des Finanzamts (von der Kanzlei nach Pruefung ausgefuellt)" -Type Choice `
    -Choices @("Deutschland", "Österreich", "Schweiz", "Liechtenstein", "Frankreich", "Italien", "Spanien", "Niederlande", "Belgien", "Luxemburg", "Polen", "Vereinigtes Königreich", "Vereinigte Staaten", "Sonstiger EU/EWR-Staat", "Sonstiger Staat", "Unbekannt")
# tax_office_country (Review Nils 28.10.2026): nicht mehr Pflicht (vorher Text
# -Required) und jetzt Choice statt freiem Text - Deutschland als erster Wert
# (haeufigster Fall), dazu EU/EWR-Kernstaaten, Schweiz, UK, USA, je ein
# Sammelwert fuer weitere EU/EWR- bzw. Drittstaaten sowie "Unbekannt". Nach der
# Grundregel (Datenmodell Abschnitt 10, Trennung Tatsache/Rechtsfolge) ist
# dieses Feld wie das folgende (tax_office) ein Ergebnisfeld, keine
# Mandanten-Tatsache - die zugrunde liegenden Tatsachen (Ort der
# Geschaeftsleitung, Sitz, Betriebsstaette in DE usw.) stehen in Liste 1/2/5,
# siehe Datenmodell Ableitungstabelle.
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office" -DisplayName "Zustaendiges Finanzamt (von der Kanzlei nach Pruefung ausgefuellt)" -Type Text
# tax_office (Review Nils 28.10.2026): nicht mehr Pflicht - das bestimmt die
# Kanzlei anhand der erhobenen Tatsachen, nicht der Mandant (Grundregel, siehe
# oben). War bislang zusaetzlich dupliziert in Liste 1 (dort jetzt entfernt,
# siehe README.md Abschnitt H) - lebt jetzt nur noch hier.
Add-Field -List "0_Fallsteuerung" -InternalName "target_notification" -DisplayName "Zielmeldung (BZSt2-Sachverhalt) - wird von der Kanzlei nach Pruefung der Angaben festgelegt" -Type Choice `
    -Choices @("Betriebe/Betriebsstätten", "PersG-Beteiligung", "KapG-Beteiligung", "Drittstaat-Beherrschung", "Negativmeldung")
Add-Field -List "0_Fallsteuerung" -InternalName "processing_note" -DisplayName "Persoenliche Bearbeitungsnotiz" -Type Note
Add-Field -List "0_Fallsteuerung" -InternalName "case_status" -DisplayName "Status" -Type Choice -Required `
    -Choices @("offen", "in Bearbeitung", "vollständig", "übermittelt")
Add-Field -List "0_Fallsteuerung" -InternalName "par27_ao_agreement" -DisplayName "Zustimmung zur Zuständigkeitsvereinbarung nach Paragraf 27 AO (Kanzleifeld)" -Type Boolean
# par27_ao_agreement (Review Nils 28.10.2026, verschoben von 1_Allgemeiner_
# Stammblock hierher): fachlich unverstaendlich fuer den Mandanten und in der
# Praxis fuer ihn irrelevant - trotzdem nicht ersatzlos gestrichen, weil es im
# ELSTER-Fragebogen "Koerperschaft nach auslaendischem Recht" eine belegte
# Grundlage hat (Datenmodell Abschnitt 2.4 Kz 18, unbedingtes Pflichtfeld;
# zusaetzlich durch die ELSTER-Portalpruefung 26.10.2026 bestaetigt, siehe
# Abschnitt 9.6/E.10). Bleibt deshalb als Kanzleifeld hier in der internen
# Fallsteuerung erhalten, nicht mehr als Forms-Frage an den Mandanten.
Add-Field -List "0_Fallsteuerung" -InternalName "crm_reference" -DisplayName "Referenz auf Mandant im CRM (Kanzleifeld)" -Type Text
# crm_reference (Review Nils 28.10.2026): ersetzt die bisherigen
# Kontakt-Einzelfelder in 1_Allgemeiner_Stammblock (Rueckfrage-E-Mail, Telefon
# usw.) - diese Daten liegen im CRM der Kanzlei, nicht in dieser Fallliste.
# Hoechstens eine Referenz/ID auf den CRM-Datensatz wird hier gefuehrt.
# created_by / created_at: SharePoint-Systemfelder Author/Created werden verwendet, keine Zusatzspalte noetig.

# ---------------------------------------------------------------------------
# Liste 1: Allgemeiner Stammblock
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "1_Allgemeiner_Stammblock"
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "party_type" -DisplayName "Art des Meldepflichtigen" -Type Choice -Required `
    -Choices @("Person", "Firma")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "first_name" -DisplayName "Vorname" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "name_addition" -DisplayName "Namensvorsatz / -zusatz" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly -AppliesTo @("NatuerlichePerson")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "religion" -DisplayName "Religion" -Type Choice -AppliesTo @("NatuerlichePerson") `
    -Choices @("keine", "römisch-katholisch", "evangelisch", "sonstige")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "id_number" -DisplayName "Identifikationsnummer / Wirtschafts-IdNr." -Type Text -Required
# --- Rechtsform neu strukturiert (Review Nils 28.10.2026, Grundregel Tatsachen
# statt Wuerdigung + "jede Stammangabe genau an einer Stelle"): ersetzt das
# bisherige Freitextfeld "legal_form" hier UND die eigene Choice-Liste in
# 2_Unternehmens_Gruendungsmodul (dort entfernt, siehe README.md Abschnitt H).
# Zwei-Fragen-Struktur: zuerst Grundtyp, dann deutsches oder auslaendisches
# Recht; bei deutschem Recht Folgefrage mit der konkreten Rechtsform, bei
# auslaendischem Recht Wortlaut + Staat als Freitext. Vereine/Stiftungen/jPoeR
# bleiben ausgeschlossen (Datenmodell 9.1 Status X); auslaendische
# Partnerships/LLP/LLC bleiben im manuellen Pruefschritt vor Formular 0
# (Status M) - keine eigene Kategorie hier.
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form_category" -DisplayName "Rechtsform - Grundtyp" -Type Choice -AppliesTo @("Gesellschaft") `
    -Choices @("Einzelunternehmen (gewerblich)", "Freiberufliche Tätigkeit", "Personengesellschaft", "Kapitalgesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form_jurisdiction" -DisplayName "Rechtsform - nach deutschem oder ausländischem Recht" -Type Choice -AppliesTo @("Gesellschaft") `
    -Choices @("nach deutschem Recht", "nach ausländischem Recht")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form_german" -DisplayName "Konkrete Rechtsform (deutsches Recht)" -Type Choice -AppliesTo @("Gesellschaft") `
    -Choices @("GmbH", "UG (haftungsbeschränkt)", "AG", "e.K.", "OHG", "KG", "GmbH & Co. KG", "GbR", "PartG", "sonstige deutsche Rechtsform")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form_foreign_name" -DisplayName "Rechtsform nach ausländischem Recht (Wortlaut)" -Type Text -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form_foreign_country" -DisplayName "Staat der ausländischen Rechtsform" -Type Text -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "address_type" -DisplayName "Adressart" -Type Choice -Required `
    -Choices @("Inland", "Ausland")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "street" -DisplayName "Strasse, Hausnummer, Zusatz" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "address_supplement" -DisplayName "Adressergänzung" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "postal_code_city" -DisplayName "Postleitzahl, Ort" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "country" -DisplayName "Staat" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "po_box" -DisplayName "Postfach" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "website" -DisplayName "Internetadresse" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "business_activity" -DisplayName "Genaue Taetigkeit" -Type Note -Required
# --- Vermoegensverwaltung: Tatsachen statt Wuerdigung (Review Nils 28.10.2026) ---
# ersetzt "asset_management_only" (Boolean; die rechtliche Wuerdigung
# "ausschliesslich vermoegensverwaltend" ist Kanzleisache, siehe Datenmodell
# Abschnitt 10 Ableitungstabelle).
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "asset_management_present" -DisplayName "Verwaltet Vermögen (Beteiligungen, Immobilien, Kapitalvermögen usw.)" -Type Boolean -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "asset_management_type" -DisplayName "Art der Vermögensverwaltung" -Type Note -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "asset_mgmt_share_revenue" -DisplayName "Anteil Vermögensverwaltung am Umsatz in Prozent" -Type Number -AppliesTo @("Gesellschaft") `
    -Min 0 -Max 100
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "asset_mgmt_share_profit" -DisplayName "Anteil Vermögensverwaltung am Gewinn in Prozent" -Type Number -AppliesTo @("Gesellschaft") `
    -Min 0 -Max 100
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "other_business_activities" -DisplayName "Weitere Tätigkeiten" -Type Note -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_id_type" -DisplayName "Art der Steuernummer-Angabe" -Type Choice -Required `
    -Choices @("bestehend", "neu beantragen")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_number" -DisplayName "Steuernummer" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_name" -DisplayName "Steuerliche Beratung - Name/Firma" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_address" -DisplayName "Steuerliche Beratung - Adresse" -Type Note
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "advisor_is_authorized_recipient" -DisplayName "Steuerliche Beratung ist empfangsbevollmächtigt" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_iban" -DisplayName "Bank - IBAN" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_bic" -DisplayName "Bank - BIC" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_account_holder" -DisplayName "Bank - Kontoinhaber" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "foreign_tax_id" -DisplayName "Ausländische Steuer-ID / TIN" -Type Text -AppliesTo @("Gesellschaft")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "vat_id_existing" -DisplayName "Bestehende USt-IdNr." -Type Text -AppliesTo @("Gesellschaft")
# tax_office, tax_office_country, phone, callback_email, sepa_desired,
# par27_ao_agreement, deviating_management_place, management_address: ENTFERNT
# (Review Nils 28.10.2026). Begruendung je Feld und manuelle Loeschschritte auf
# Bestandssites siehe README.md Abschnitt H/G. Kurzfassung: tax_office/
# tax_office_country sind Ergebnisfelder und leben nur noch in 0_Fallsteuerung
# (dort waren sie ausserdem dupliziert); phone/callback_email sind
# CRM-Kontaktdaten der Kanzlei, keine Fallangaben; sepa_desired vorerst ganz
# entfernt; par27_ao_agreement als Kanzleifeld nach 0_Fallsteuerung verschoben
# (Mandant soll keine Zustimmung zu einer Zustaendigkeitsvereinbarung
# einschaetzen); deviating_management_place/management_address als
# Tatsachenfelder zu den einzelnen Personen nach 3_Personen_und_Vertretung
# verschoben (usual_workplace_*), der Ort der Geschaeftsleitung wird von der
# Kanzlei daraus abgeleitet (Kanzleifeld, siehe Datenmodell Abschnitt 10).

# ---------------------------------------------------------------------------
# Liste 2: Unternehmens-/Gruendungsmodul (Inbound; auch Einzelunternehmen, s. E.9)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "2_Unternehmens_Gruendungsmodul"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
# company_name und legal_form (bisherige Choice-Liste) ENTFERNT (Review Nils
# 28.10.2026, "jede Stammangabe genau an einer Stelle"): Name/Firma und
# Rechtsform sind Stammangaben und leben jetzt ausschliesslich in
# 1_Allgemeiner_Stammblock (last_name_or_company, legal_form_*) - diese Liste
# verweist ueber case_id statt eine eigene Kopie zu fuehren.
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_type" -DisplayName "Gruendungsart (von der Kanzlei eingeordnet)" -Type Choice -FieldRole Ergebnis `
    -Choices @("Neugründung", "Übernahme", "Umwandlung", "Bargründung", "Sachgründung")
# formation_type (Befund Erfassungs-Chat-Generator 28.10.2026, PR #22,
# generator/output/required_ergebnis_konflikte.json): "Gruendungsart" (insb.
# Bar-/Sachgruendung, Umwandlung) ist selbst eine rechtliche Einordnung, kein
# Tatsachenfeld - war bislang -Required, was dem Generator-Befund und der
# Grundregel (Datenmodell Abschnitt 10) widersprach. Jetzt nicht mehr
# -Required, als Kanzleifeld gekennzeichnet (-FieldRole Ergebnis, siehe
# README.md Abschnitt C3). Tatsachen stattdessen ueber predecessor_exists
# (siehe oben), capital_contribution_type und transformation_event (neu,
# siehe unten) sowie den Upload der Gruendungsurkunde/Satzung (Liste 8).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "capital_contribution_type" -DisplayName "Grund-/Stammkapital erbracht als" -Type Choice `
    -Choices @("Bareinlage", "Sacheinlage", "gemischt (Bar- und Sacheinlage)")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "transformation_event" -DisplayName "Entstehung durch gesellschaftsrechtliche Umwandlung (z. B. Verschmelzung, Spaltung, Formwechsel)" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "transformation_details" -DisplayName "Art der Umwandlung und beteiligte Rechtstraeger" -Type Note
# capital_contribution_type/transformation_event/transformation_details
# (neu, Grundregel-Ableitung fuer formation_type): Bar- vs. Sacheinlage ist
# eine vom Mandanten feststellbare Tatsache (wurde Geld oder ein
# Vermoegensgegenstand eingebracht), waehrend "Sachgruendung" als Rechtsbegriff
# selbst eine Einordnung ist. Ebenso ist "liegt eine Umwandlung vor" eine
# Tatsache, "welche Gruendungsart daraus rechtlich folgt" nicht.
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_date" -DisplayName "Gruendungsdatum" -Type DateOnly -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "activity_start_date" -DisplayName "Beginn der Taetigkeit" -Type DateOnly -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "notarial_deed_date" -DisplayName "Notarielle Errichtung / Musterprotokoll vom" -Type DateOnly
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_amount" -DisplayName "Grund-/Stammkapital - Betrag" -Type Number
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_currency" -DisplayName "Grund-/Stammkapital - Waehrung" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "paid_in_capital" -DisplayName "Eingezahltes Kapital" -Type Number
# Gruendungsurkunde/Satzung/Gesellschaftsvertrag: kein eigenes Upload-Feld hier
# noetig - Verweis auf 8_Unterlagen (document_type jetzt inkl. "Gruendungsurkunde"
# und "Satzung", siehe dort).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_status" -DisplayName "Handelsregister-Status" -Type Choice -Required `
    -Choices @("beabsichtigt", "beantragt", "erfolgt")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "registry_court" -DisplayName "Ort des Amtsgerichts bzw. der ausländischen Registerbehörde" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_number" -DisplayName "Register / Registernummer" -Type Text
# registry_court-Anzeigename verallgemeinert (Review Nils 28.10.2026): gilt
# jetzt auch fuer eine auslaendische registerfuehrende Stelle, nicht nur das
# deutsche Amtsgericht - deckt damit einen Teil des Befunds "Registerangaben
# fehlen bei Koerperschaft auslaendischen Rechts" ab (siehe README.md
# Abschnitt H zur ebenfalls ergaenzten E.9-Routing-Korrektur).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor_exists" -DisplayName "Wurde die Tätigkeit vorher ganz oder teilweise von einem anderen Unternehmen bzw. einer anderen Person ausgeübt?" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor_name" -DisplayName "Vorheriger Inhaber / Vorunternehmen - Name" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor_tax_or_address" -DisplayName "Vorheriger Inhaber / Vorunternehmen - Steuernummer bzw. Anschrift" -Type Note
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor_scope" -DisplayName "Übernahme ganz oder teilweise" -Type Choice `
    -Choices @("ganz", "teilweise")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor_since" -DisplayName "Übernommen ab" -Type DateOnly
# predecessor_* ersetzt das bisherige einzelne Freitextfeld "predecessor"
# (Review Nils 28.10.2026): erst Ja/Nein-Tatsache, dann bei Ja die
# strukturierten Folgefragen (wer, Steuernummer/Anschrift, ganz/teilweise,
# ab wann).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "fiscal_year_matches_calendar" -DisplayName "Entspricht das Wirtschaftsjahr dem Kalenderjahr?" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "fiscal_year_start" -DisplayName "Wirtschaftsjahr - Beginn" -Type DateOnly
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "fiscal_year_end" -DisplayName "Wirtschaftsjahr - Ende" -Type DateOnly
# fiscal_year_matches_calendar ersetzt "deviating_fiscal_year" (Review Nils
# 28.10.2026, gleiche Tatsache nur umgekehrtes Vorzeichen: Nein hier = Ja
# dort) und vermeidet ein doppeltes Pflichtfeld-Paar; fiscal_year_end war
# bislang gar nicht vorhanden, obwohl "Beginn" ohne "Ende" unvollstaendig ist.
# Beide Datumsfelder bleiben ohne -Required, da sie nur bei Antwort "Nein"
# ausgefuellt werden (Forms-Branching, siehe README.md E.2).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "profit_determination_method" -DisplayName "Gewinnermittlungsart (von der Kanzlei abgeleitet)" -Type Choice `
    -Choices @("Betriebsvermögensvergleich", "Einnahmenüberschussrechnung")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "foreign_bookkeeping_obligation" -DisplayName "Buchführungs-/Bilanzierungspflicht nach ausländischem Recht" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "voluntary_balance_sheet" -DisplayName "Bereits bilanziert (freiwillig oder nach anderer Vorschrift)" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "balance_sheet_basis" -DisplayName "Rechtsgrundlage der Bilanzierung (z. B. Handelsrecht, ausländisches Recht)" -Type Text
# profit_determination_method (Review Nils 28.10.2026): nicht mehr Pflicht und
# jetzt als Kanzleifeld gekennzeichnet - "Gewinnermittlungsart" ist eine
# rechtliche Wuerdigung (§ 4/§ 5 EStG), kein Mandanten-Fakt. Stattdessen werden
# die Tatsachen erhoben (Buchfuehrungspflicht nach auslaendischem Recht,
# freiwillige Bilanzierung, Rechtsgrundlage; Handelsregister-Eintragung bereits
# ueber register_status, freiberufliche Taetigkeit bereits ueber
# legal_form_category in Liste 1 abgedeckt - keine Dubletten dafuer angelegt).
# Die Kanzlei leitet die Gewinnermittlungsart daraus ab, siehe Datenmodell
# Abschnitt 10 Ableitungstabelle.
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_opening_year" -DisplayName "Voraussichtlicher Gewinn Eroeffnungsjahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_following_year" -DisplayName "Voraussichtlicher Gewinn Folgejahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "part_of_group" -DisplayName "Konzernzugehoerigkeit" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "controlling_company_name" -DisplayName "Herrschendes Unternehmen - Name" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_tax_group_parent" -DisplayName "Organtraegerschaft" -Type Boolean -FieldRole "Ergebnis"
# --- Abschnitt 9 ergaenzt (Datenmodell 2.3/9.3, Personengesellschaft) ---
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "legal_capacity" -DisplayName "Rechtsfaehigkeit (Personengesellschaft)" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "profit_distribution_key" -DisplayName "Aufteilungsschluessel (Gewinn-/Verlustverteilung)" -Type Text
# legal_capacity ist bei form_type = Personengesellschaft/-gemeinschaft laut
# Datenmodell Kz 33 unbedingt, bei anderen Formulartypen nicht einschlaegig;
# deshalb ohne -Required, Pflicht ueber Forms-Branching (siehe README.md E.2).
# --- Abschnitt 9.6 ergaenzt (Update 2, ELSTER-Portalpruefung 26.10.2026):
# bedingte Pflichtfelder aus fsekapgaus-202401 und fsekapg-202401, Status
# belegt_bedingt. Keines dieser Felder ist bedingungslos -Required, da die
# Pflicht jeweils an eine andere Auswahl geknuepft ist (siehe Datenmodell
# Abschnitt 9.6 und README.md Abschnitt E.2 fuer die genaue Bedingung je Feld). ---
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "notary_name" -DisplayName "Gruendungsnotar - Name" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "notary_address" -DisplayName "Gruendungsnotar - Adresse" -Type Note
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_general_partner_of_kg" -DisplayName "Komplementaerin einer KG" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "general_partner_kg_name" -DisplayName "Bezeichnung der KG (falls Komplementaerin)" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_date" -DisplayName "Handelsregister - Datum (beantragt am / Tag der Eintragung)" -Type DateOnly
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "split_ownership_structure" -DisplayName "Betriebsaufspaltung" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "split_ownership_company_name" -DisplayName "Bezeichnung des Besitzunternehmens" -Type Text -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "split_owner_asset_description" -DisplayName "Bezeichnung des ueberlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage, Betriebsaufspaltung)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "split_ownership_usage_start" -DisplayName "Beginn der tatsaechlichen Nutzung (Betriebsaufspaltung)" -Type DateOnly -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "split_owner_address_or_taxno" -DisplayName "Anschrift und/oder Steuernummer des Besitzunternehmens" -Type Note -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "kst_exemption" -DisplayName "Koerperschaftsteuerbefreiung nach Paragraf 5 KStG" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "kst_exemption_number" -DisplayName "Nummer nach Paragraf 5 Absatz 1 KStG" -Type Text -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "par60a_ao_determination" -DisplayName "Feststellung nach Paragraf 60a AO" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "par60a_ao_purpose" -DisplayName "Zweck der Koerperschaft (Paragraf 60a AO)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_tax_group_subsidiary" -DisplayName "Organgesellschaft (koerperschaftsteuerliche Organschaft)" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "tax_group_parent_name" -DisplayName "Name/Firma des Organtraegers" -Type Text -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_vat_group_member" -DisplayName "Umsatzsteuerliche Organschaft" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "vat_group_start_date" -DisplayName "Beginn der umsatzsteuerlichen Organschaft" -Type DateOnly -FieldRole "Ergebnis"
# split_owner_asset_description (Zeile 135 in fsekapg-202401): Kanzleientscheid
# Nils 27.10.2026 - Feld wird gefuehrt als "Bezeichnung des ueberlassenen
# Wirtschaftsguts (wesentliche Betriebsgrundlage)". Der genaue Wortlaut laut
# ELSTER-Fehlerliste war nur "Bezeichnung" ohne weiteren Kontext; die
# Bezeichnung oben ist Kanzleientscheid, nicht im Portal verifiziert.
# Interner Feldname unveraendert (idempotent).

# ---------------------------------------------------------------------------
# Liste 3: Personen und Vertretung
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "3_Personen_und_Vertretung"
Add-Field -List "3_Personen_und_Vertretung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "3_Personen_und_Vertretung" -InternalName "role" -DisplayName "Rolle" -Type Choice -Required `
    -Choices @("Gesetzlicher Vertreter", "Ständiger Vertreter", "Empfangsbevollmächtigter", "Steuerliche Beratung", "Ehegatte/Lebenspartner")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "person_type" -DisplayName "Art der Person" -Type Choice -Required `
    -Choices @("natürlich", "nicht natürlich")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "first_name" -DisplayName "Vorname" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly -AppliesTo @("NatuerlichePerson")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "id_number" -DisplayName "Identifikationsnummer" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "profession" -DisplayName "Beruf / Taetigkeit" -Type Text -AppliesTo @("NatuerlichePerson")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "phone" -DisplayName "Telefon" -Type Text -FieldRole "System"
Add-Field -List "3_Personen_und_Vertretung" -InternalName "tax_reference" -DisplayName "Steuerliche Kennzeichen" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "dependency_status" -DisplayName "Abhaengige/unabhaengige Person" -Type Choice -FieldRole "Ergebnis" `
    -Choices @("abhängig", "unabhängig")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "power_to_conclude_contracts" -DisplayName "Abschlussvollmacht" -Type Boolean
Add-Field -List "3_Personen_und_Vertretung" -InternalName "is_authorized_recipient" -DisplayName "Empfangsbevollmaechtigt" -Type Boolean
# --- Uebliche Taetigkeitsorte der Person (Review Nils 28.10.2026, verschoben
# von 1_Allgemeiner_Stammblock hierher): ersetzt "deviating_management_place"/
# "management_address" (gehoerten fachlich nicht zum Unternehmen, sondern zu
# den einzelnen gesetzlichen Vertretern/Geschaeftsfuehrern). Tatsachenfelder je
# Person; der Ort der tatsaechlichen Geschaeftsleitung des Unternehmens
# (Ergebnisfeld) wird von der Kanzlei daraus abgeleitet, nicht vom Mandanten
# selbst eingeschaetzt - siehe Datenmodell Abschnitt 10 Ableitungstabelle.
# Fachlich vor allem bei role = Gesetzlicher Vertreter/Staendiger Vertreter
# einschlaegig (Forms-Branching, siehe README.md E.3).
Add-Field -List "3_Personen_und_Vertretung" -InternalName "usual_workplace_country" -DisplayName "Übliches Land der Tätigkeit (dieser Person)" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "usual_workplace_address" -DisplayName "Übliche Adresse/Ort der Tätigkeit (dieser Person)" -Type Note
Add-Field -List "3_Personen_und_Vertretung" -InternalName "works_elsewhere" -DisplayName "Arbeitet auch regelmässig an einem anderen Ort" -Type Boolean
Add-Field -List "3_Personen_und_Vertretung" -InternalName "other_workplace_details" -DisplayName "Anderer Tätigkeitsort - wo und Anteil der Arbeitszeit" -Type Note
Add-Field -List "3_Personen_und_Vertretung" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text -FieldRole "System"
# display_label (Punkt 10, "Lookup-Anzeigefeld eindeutig machen"): last_name_or_company
# ist bei Namensgleichheit nicht eindeutig. display_label soll vom auslösenden
# Flow unmittelbar nach Elementanlage befuellt werden, z. B.
# "<Name> (<Rolle>, Fall <case_id>, ID <ID>)", und wird als ShowField der
# Lookup-Spalte 8_Unterlagen/related_person verwendet statt last_name_or_company.

# ---------------------------------------------------------------------------
# Liste 4: Beteiligte und Quoten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "4_Beteiligte_und_Quoten"
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "sequence_number" -DisplayName "Laufende Nummer / Zeichnernummer" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participant_type" -DisplayName "Art des Beteiligten" -Type Choice -Required `
    -Choices @("natürlich", "nicht natürlich")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly -AppliesTo @("NatuerlichePerson")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "tax_reference" -DisplayName "Steuerliche Kennzeichen" -Type Text
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participation_type" -DisplayName "Art der Beteiligung" -Type Choice -Required `
    -Choices @("direkt", "mittelbar")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "role" -DisplayName "Rolle" -Type Choice -Required `
    -Choices @("Anteilseigner", "Gesellschafter", "Treuhänder")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "nominal_share" -DisplayName "Beteiligung nominell" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "share_percentage" -DisplayName "Beteiligung in Prozent" -Type Number -Required `
    -Min 0 -Max 100
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "fraction_numerator_denominator" -DisplayName "Zaehler / Nenner" -Type Text
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "trust_relationship_status" -DisplayName "Treuhandverhältnis" -Type Choice -Required `
    -Choices @("Ja", "Nein")
# trust_relationship_status (Audit 28.10.2026, gleiches Muster wie
# registration_status/already_registered) ERSETZT "trust_relationship"
# (Boolean, war -Required): ein als Pflicht markiertes Ja/Nein-Feld laesst sich
# in SharePoint im nativen Formular nur mit "Ja" sauber ausfuellen (Checkbox-
# Verhalten bei Required-Yes/No). Anders als registration_status bleibt dieses
# Feld unbedingt Pflicht (ELSTER Kz 90, Datenmodell Abschnitt 2.2: "Treuhand-
# verhaeltnis: ja/nein" ist bei jedem Beteiligten-Datensatz unbedingt zu
# beantworten, "Unbekannt" ist hier fachlich nicht vorgesehen) - deshalb Choice
# mit genau "Ja"/"Nein" statt eines dritten Wertes. Required funktioniert bei
# Choice-Feldern korrekt (beide Optionen sind gleichwertige Auswahlwerte, kein
# Checkbox-Default). "trust_relationship" wird von diesem Skript nicht mehr
# angelegt oder angeglichen (Typaenderung Boolean -> Choice ist laut Punkt C
# nicht automatisch moeglich) - auf Bestandssites manuell loeschen, siehe
# README.md Abschnitt H (vor dem Loeschen pruefen, ob Liste 4 bereits befuellt
# ist - anders als bei already_registered ist hier kein 0-Eintraege-Nachweis
# bekannt).
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "profit_share_opening_year" -DisplayName "Voraussichtlicher Gewinnanteil Eroeffnungsjahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "profit_share_following_year" -DisplayName "Voraussichtlicher Gewinnanteil Folgejahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "limited_tax_liability" -DisplayName "Beschraenkte Steuerpflicht" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participation_since" -DisplayName "Beteiligt seit dem" -Type DateOnly
# --- Abschnitt 9 ergaenzt (Datenmodell 9.2 "Beteiligte": Stimmrechte) ---
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "voting_rights_percentage" -DisplayName "Stimmrechte in Prozent" -Type Number `
    -Min 0 -Max 100
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text -FieldRole "System"

# ---------------------------------------------------------------------------
# Liste 5: Betriebsstaetten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "5_Betriebsstaetten"
Add-Field -List "5_Betriebsstaetten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "5_Betriebsstaetten" -InternalName "site_name" -DisplayName "Bezeichnung der Betriebsstätte/Einrichtung" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "country" -DisplayName "Land" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "site_type" -DisplayName "Art der Einrichtung (von der Kanzlei eingeordnet - fest/nicht fest nach Paragraf 12 AO)" -Type Choice -FieldRole Ergebnis `
    -Choices @("fest", "nicht fest")
# site_type (Befund Erfassungs-Chat-Generator 28.10.2026, PR #22,
# generator/output/required_ergebnis_konflikte.json): "fest"/"nicht fest" ist
# der Betriebsstaetten-Begriff aus Paragraf 12 AO selbst, keine
# Mandanten-Tatsache - war bislang -Required, was dem Generator-Befund und
# der Grundregel (Datenmodell Abschnitt 10) widersprach. Jetzt nicht mehr
# -Required, als Kanzleifeld gekennzeichnet (-FieldRole Ergebnis). Tatsachen
# stattdessen ueber ownership_status/usage_type/activity_period_* (bestehend)
# sowie own_disposal_power (neu, siehe unten) - das zentrale Tatbestandsmerkmal
# der "Verfuegungsmacht" nach staendiger BFH-Rechtsprechung zu Paragraf 12 AO.
Add-Field -List "5_Betriebsstaetten" -InternalName "ownership_status" -DisplayName "Eigentumsverhältnis" -Type Choice `
    -Choices @("Eigentum", "Miete", "Nutzung")
Add-Field -List "5_Betriebsstaetten" -InternalName "own_disposal_power" -DisplayName "Eigene, nicht nur voruebergehende Verfuegungsmacht ueber die Einrichtung (z. B. eigener Schluessel/Zugang, eigener Arbeitsplatz)" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "usage_type" -DisplayName "Nutzungsart" -Type Choice `
    -Choices @("Lagerung", "Verarbeitung", "Einkauf", "Werbung", "Sonstige")
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_from" -DisplayName "Taetigkeitsdauer - von" -Type DateOnly
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_to" -DisplayName "Taetigkeitsdauer - bis" -Type DateOnly
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_to_unknown" -DisplayName "Taetigkeitsdauer bis unbekannt" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "vat_relevant_site" -DisplayName "Umsatzsteuerliche Betriebsstätte" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "5_Betriebsstaetten" -InternalName "contact" -DisplayName "Telefon / Internetadresse" -Type Text
Add-Field -List "5_Betriebsstaetten" -InternalName "payroll_tax_site" -DisplayName "Lohnsteuerliche Betriebsstätte" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "5_Betriebsstaetten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text -FieldRole "System"

# ---------------------------------------------------------------------------
# Liste 6: Steuer- und Umsatzsteuerprofil (nur Inbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "6_Steuer_und_Umsatzsteuerprofil"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_opening_year" -DisplayName "Geschaetzter Umsatz Eroeffnungsjahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_following_year" -DisplayName "Geschaetzter Umsatz Folgejahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule" -DisplayName "Kleinunternehmer-Regelung" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule_waiver" -DisplayName "Verzicht auf Kleinunternehmer-Regelung" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_vat_amount" -DisplayName "Voraussichtliche USt (Zahllast/Ueberschuss)" -Type Number -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_filing_period" -DisplayName "Voranmeldungszeitraum" -Type Choice -FieldRole "Ergebnis" `
    -Choices @("Monat", "Quartal")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_taxation_method" -DisplayName "Soll-/Ist-Besteuerung" -Type Choice -FieldRole "Ergebnis" `
    -Choices @("Soll-Besteuerung", "Ist-Besteuerung")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "request_vat_id" -DisplayName "USt-IdNr. beantragen" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "previous_vat_id" -DisplayName "Fruehere USt-IdNr." -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "oss_procedure" -DisplayName "OSS-Verfahren" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "own_webshop" -DisplayName "Eigener Webshop" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "electronic_interface" -DisplayName "Elektronische Schnittstelle" -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "construction_services_over_10pct" -DisplayName "Bauleistungen ueber 10% Weltumsatz" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "employees_total" -DisplayName "Anzahl Arbeitnehmer insgesamt" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "payroll_start_date" -DisplayName "Beginn Lohnzahlungen" -Type DateOnly
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_payroll_tax" -DisplayName "Voraussichtliche Lohnsteuer" -Type Number -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "exemption_cert_48b_construction" -DisplayName "Freistellungsbescheinigung Paragraf 48b EStG" -Type Boolean
# --- Abschnitt 9.6 ergaenzt (Update 2, ELSTER-Portalpruefung 26.10.2026):
# bedingte Pflichtfelder aus fsekapgaus-202401 und fsekapg-202401 (beide
# Formulare zeigen denselben USt-Block), Status belegt_bedingt, siehe
# Datenmodell Abschnitt 9.6 / README.md Abschnitt E.6 fuer die Bedingung je Feld. ---
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_tax_free_sales" -DisplayName "Steuerfreie Umsaetze nach Paragraf 4 UStG" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_tax_free_sales_type" -DisplayName "Art des Umsatzes (steuerfrei)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_reduced_rate_sales" -DisplayName "Ermaessigter Steuersatz" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_reduced_rate_sales_type" -DisplayName "Art des Umsatzes (ermaessigter Satz)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_zero_rate_sales" -DisplayName "Nullsteuersatz" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_zero_rate_sales_type" -DisplayName "Art des Umsatzes (Nullsteuersatz)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_zero_rate_legal_basis" -DisplayName "Rechtsvorschrift zum Nullsteuersatz" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_flat_rate_agriculture" -DisplayName "Durchschnittssatzbesteuerung Paragraf 24 UStG (Land-/Forstwirtschaft)" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_flat_rate_agriculture_type" -DisplayName "Art des Umsatzes (Paragraf 24 UStG)" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_flat_rate_agriculture_choice" -DisplayName "Durchschnittssatzbesteuerung oder Verzicht" -Type Choice -FieldRole "Ergebnis" `
    -Choices @("Durchschnittssatzbesteuerung beibehalten", "Verzicht auf Durchschnittssatzbesteuerung")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "input_tax_refund_requested" -DisplayName "Vorsteuerverguetung beantragt" -Type Boolean -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "input_tax_refund_date" -DisplayName "Datum der Vorsteuerverguetung" -Type DateOnly -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "input_tax_refund_reference" -DisplayName "Aktenzeichen Vorsteuerverguetung" -Type Text -FieldRole "Ergebnis"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "webshop_url" -DisplayName "Internetadresse (URL) des Webshops" -Type URL
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "electronic_interface_identifier" -DisplayName "Identifikationsmerkmal der elektronischen Schnittstelle" -Type Text
# own_webshop/electronic_interface existierten bereits; webshop_url und
# electronic_interface_identifier ergaenzen die laut ELSTER zusaetzlich
# bedingt erforderlichen Detailangaben (URL bzw. Identifikationsmerkmal,
# z. B. Accountname), ohne die bestehenden Felder zu veraendern oder zu loeschen.

# ---------------------------------------------------------------------------
# Liste 7: Auslandsmitteilung (BZSt2, nur Outbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "7_Auslandsmitteilung_BZSt2"
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "notification_year" -DisplayName "Mitteilungsjahr" -Type Number -Required `
    -Min 1000 -Max 9999 -Decimals 0
# notification_year (Entscheid 28.10.2026, revidiert Punkt 10 aus der
# ursprünglichen Pruefung): Der Testlauf 27./28.10.2026 ergab, dass das Feld
# auf der Zielsite bereits als Number angelegt war (nicht wie im Skript zuvor
# als Text) - Formular 6/E.7 Frage 2 ist in Forms bereits als Zahlenfrage
# 1000-9999 gebaut. Entscheid: Skript auf Number mit Min=1000/Max=9999 und
# Decimals=0 umstellen, statt die Site auf Text umzustellen. Damit sind nur
# vierstellige Ganzzahlen zulaessig; das fruehere Bedenken wegen eines
# Tausendertrennzeichens in der Anzeige wird in Kauf genommen (Forms selbst
# erzwingt ohnehin eine Zahlenfrage, keine Validierungsformel mehr noetig).
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "notification_subject" -DisplayName "Sachverhalt" -Type Choice -Required `
    -Choices @("Betriebe/Betriebsstätten", "PersG-Beteiligung", "KapG-Beteiligung", "Drittstaat-Beherrschung", "Negativmeldung")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "tax_or_id_number" -DisplayName "Steuer-/Identifikationsnummer" -Type Text -Required
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_type" -DisplayName "Typ der Auslandseinheit" -Type Choice `
    -Choices @("Betriebsstätte", "Betrieb", "Personengesellschaft", "Kapitalgesellschaft", "Vermögensmasse")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_name_legal_form" -DisplayName "Firmenname / Rechtsform" -Type Text
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_address" -DisplayName "Adresse / Staat" -Type Note
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_formation_date" -DisplayName "Gruendungsdatum" -Type DateOnly
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "activity_code" -DisplayName "Taetigkeitskennzahl (1-13)" -Type Choice `
    -Choices @("1 Land-/Forstwirtschaft", "2 Herstellung/Verarbeitung", "3 Kredit/Versicherung", "4 Handel", "5 Rechte/Muster", "6 VuV Grundstücke", "7 VuV bewegliche Sachen", "8 Verwaltung", "9 Kapitalanlage", "10 Finanzierung", "11 sonstige Dienstleistungen", "12 Holding", "13 Sonstiges")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "activity_code_explanation" -DisplayName "Erlaeuterung zu 'Sonstiges' (Frage 9a)" -Type Text
# activity_code_explanation (Punkt 6, Formular 7 Frage 9a): Pflichttext, wenn
# activity_code = "13 Sonstiges"; ohne -Required angelegt, da bedingt (siehe
# README.md E.7 Frage 9 Branching-Hinweis).
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "nominal_capital" -DisplayName "Nominalkapital / Kapital" -Type Number
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "registered_in_germany" -DisplayName "Im Inland steuerlich erfasst" -Type Boolean
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "participant_name_share" -DisplayName "Beteiligte - Name / Anteil in %" -Type Note
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "participation_since" -DisplayName "Beteiligt seit dem" -Type DateOnly
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "third_country_control" -DisplayName "Drittstaat-Beherrschung" -Type Boolean
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "advisor_involvement" -DisplayName "Mitwirkung Steuerberatung" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 8: Unterlagen
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "8_Unterlagen"
Add-Field -List "8_Unterlagen" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "8_Unterlagen" -InternalName "document_type" -DisplayName "Dokumenttyp" -Type Choice -Required `
    -Choices @("Gründungsurkunde", "Satzung", "Gesellschaftsvertrag", "Vollmacht Steuerberatung", "Empfangsvollmacht", "SEPA-Mandat", "Handelsregisterauszug", "Sachgründungsbericht", "Ansässigkeitsbescheinigung", "Sonstiges")
# Gründungsurkunde/Satzung (Review Nils 28.10.2026, 2_Unternehmens_Gruendungsmodul):
# ergaenzen (additiv, Choices werden nie entfernt) den bisherigen Katalog, damit
# die in Liste 2 referenzierte Gruendungsurkunde/Satzung/der Gesellschaftsvertrag
# ueber Liste 8 mit dem passenden Dokumenttyp hochgeladen werden kann.
# "Gesellschaftsvertrag" blieb zusaetzlich bestehen (z. B. GbR/OHG ohne notarielle
# Urkunde).
Add-Field -List "8_Unterlagen" -InternalName "related_object_text" -DisplayName "Bezug zu Objekt (Freitext aus Formular)" -Type Text -FieldRole "System"
# related_object_text (Punkt 6): bildet die Forms-Frage "Bezug zu Objekt" (Text,
# README.md E.8 Frage 3) ab. Ohne diese Spalte konnte ein einfacher
# Power-Automate-Flow die Forms-Antwort gar nicht speichern, da die
# Lookup-Spalten related_case/related_person/related_participation/related_site
# keinen Freitext annehmen. related_object_text ist die Rohantwort; die
# Lookups werden danach manuell oder durch einen erweiterten Flow aufgeloest.
Add-Field -List "8_Unterlagen" -InternalName "required" -DisplayName "Erforderlich" -Type Boolean -DefaultValue "0" -FieldRole "System"
Add-Field -List "8_Unterlagen" -InternalName "uploaded" -DisplayName "Vorhanden / hochgeladen" -Type Boolean -DefaultValue "0" -FieldRole "System"
# required/uploaded (Punkt 7): keine Forms-Frage, daher nicht mehr -Required;
# Default FALSE, damit neu erstellte Elemente ohne explizite Eingabe konsistent
# starten. Beide Felder werden von der Kanzlei intern gepflegt.
Add-Field -List "8_Unterlagen" -InternalName "note" -DisplayName "Hinweis" -Type Note
Add-Field -List "8_Unterlagen" -InternalName "file_link" -DisplayName "Link zur Datei (falls extern abgelegt)" -Type URL -FieldRole "System"
# file_link (Punkt 6): Hyperlink-Feld fuer den Fall, dass eine Datei nicht ueber
# den Forms-Datei-Upload (erfordert Microsoft-Konto, siehe README.md E.8),
# sondern ueber einen separaten Kanzlei-Upload-Weg eingesammelt und hier nur
# verlinkt wird. Wird nicht aus einer Forms-Frage befuellt, sondern durch Flow
# oder manuell.
# related_object (Nachschlagefeld Fall/Person/Beteiligung/Betriebsstaette) und file (Anhang)
# werden nach Anlage aller Listen manuell verknuepft, da PnP kein Multi-Listen-Lookup-Feld kennt;
# ersatzweise vier separate Lookup-Spalten (related_case, related_person, related_participation, related_site)
# plus Standard-Anlagenfunktion der Liste verwenden.
Add-Field -List "8_Unterlagen" -InternalName "related_case" -DisplayName "Bezug: Fall" -Type Lookup -FieldRole "System" `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "8_Unterlagen" -InternalName "related_person" -DisplayName "Bezug: Person" -Type Lookup -FieldRole "System" `
    -LookupList "3_Personen_und_Vertretung" -LookupField "display_label"
Add-Field -List "8_Unterlagen" -InternalName "related_participation" -DisplayName "Bezug: Beteiligung" -Type Lookup -FieldRole "System" `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "8_Unterlagen" -InternalName "related_site" -DisplayName "Bezug: Betriebsstätte" -Type Lookup -FieldRole "System" `
    -LookupList "5_Betriebsstaetten" -LookupField "display_label"
# related_person/related_participation/related_site bleiben ohne -DeleteBehavior
# (Standard "None", Punkt 10): das Loeschen einer Person/Beteiligung/
# Betriebsstaette soll nicht am Vorhandensein einer verknuepften Unterlage
# scheitern. related_case bleibt ebenfalls "None", da der primaere
# Fall-Bezug bereits ueber case_id (oben, Restrict) gesichert ist.

# ---------------------------------------------------------------------------
# Referenzliste (intern, kein Form): Technische Mindestfelder
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Technische_Mindestfelder"
Add-Field -List "Technische_Mindestfelder" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "Technische_Mindestfelder" -InternalName "entity_or_person_id" -DisplayName "entity_id / person_id" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "object_type" -DisplayName "object_type" -Type Text -Required
Add-Field -List "Technische_Mindestfelder" -InternalName "object_sequence" -DisplayName "object_sequence" -Type Number
Add-Field -List "Technische_Mindestfelder" -InternalName "source_form_type" -DisplayName "source_form_type" -Type Choice -Required `
    -Choices @("EU", "KapG", "PersG", "Auslandskörperschaft", "BZSt2")
Add-Field -List "Technische_Mindestfelder" -InternalName "kz_reference" -DisplayName "elster_kz / bzst_kz" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "value" -DisplayName "value" -Type Note
Add-Field -List "Technische_Mindestfelder" -InternalName "conditional_trigger" -DisplayName "conditional_trigger (condition)" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "validation_status" -DisplayName "validation_status" -Type Choice -Required `
    -Choices @("offen", "geprüft", "fehlerhaft")
# --- Abschnitt 9.5 ergaenzt: Feldkatalog object_id, field_key, field_label,
# data_type, required_status, condition, source, verification_date ---
# "condition" wird bewusst NICHT als eigenes Duplikat angelegt, sondern durch
# das bereits vorhandene Feld conditional_trigger abgebildet (DisplayName oben
# entsprechend ergaenzt). Alle anderen Katalogfelder sind neu:
Add-Field -List "Technische_Mindestfelder" -InternalName "object_id" -DisplayName "object_id" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "field_key" -DisplayName "field_key" -Type Text -Required
Add-Field -List "Technische_Mindestfelder" -InternalName "field_label" -DisplayName "field_label" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "data_type" -DisplayName "data_type" -Type Choice `
    -Choices @("Einzeiler Text", "Mehrzeiliger Text", "Auswahl", "Ja/Nein", "Datum", "Zahl", "Anhang", "Nachschlagefeld (Lookup)", "Hyperlink")
Add-Field -List "Technische_Mindestfelder" -InternalName "required_status" -DisplayName "required_status" -Type Choice `
    -Choices @("belegt_unbedingt", "belegt_bedingt", "intake_empfohlen", "amtlich_ungeprüft")
Add-Field -List "Technische_Mindestfelder" -InternalName "source" -DisplayName "source" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "verification_date" -DisplayName "verification_date" -Type DateOnly

# ---------------------------------------------------------------------------
# Neue interne Referenzliste: Eingang_Fehler
# Fehlgeschlagene Uebernahmen aus Power Automate (z. B. unbekannte/fehlende
# case_id, fehlerhafter access_code, Validierungsfehler) werden hier statt
# stillschweigend verworfen dokumentiert.
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Eingang_Fehler"
Add-Field -List "Eingang_Fehler" -InternalName "form_no" -DisplayName "Formular-Nr. (0-8)" -Type Number -Required
Add-Field -List "Eingang_Fehler" -InternalName "case_id_raw" -DisplayName "Fall-ID (Rohantwort)" -Type Text
Add-Field -List "Eingang_Fehler" -InternalName "reason" -DisplayName "Fehlerursache" -Type Text -Required
Add-Field -List "Eingang_Fehler" -InternalName "payload" -DisplayName "Rohdaten der Formularantwort" -Type Note
Add-Field -List "Eingang_Fehler" -InternalName "status" -DisplayName "Status" -Type Choice -Required `
    -Choices @("offen", "in Prüfung", "behoben", "verworfen")

Write-Host ""
Write-Host "Fertig. Alle 9 Fachlisten (0-8) sowie die internen Referenzlisten"
Write-Host "'Technische_Mindestfelder' und 'Eingang_Fehler' sind angelegt bzw. angeglichen."
Write-Host "Naechster Schritt: siehe DE/AO/sharepoint-forms/README.md, Abschnitt E (Forms-Einrichtung) und F (Freigabe/Rollout)."
