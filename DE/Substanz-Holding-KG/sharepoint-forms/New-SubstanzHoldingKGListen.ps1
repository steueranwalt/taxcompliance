#Requires -Modules PnP.PowerShell
<#
    .SYNOPSIS
    Legt die SharePoint-Listenfamilie "Substanzpruefung Holding-KG" nach
    VERSION 3 des Erfassungsbogen-Entwurfs (Nils Obenhaus, 27.10.2026,
    Projekt 22032-2, Anhang B1-B4) an bzw. gleicht eine bestehende
    Installation an den aktuellen Feldkatalog an. Gegenstand ist das
    Tagesgeschaeft (wiederkehrende Aufgabe je Person/Gesellschaft/Zeitraum),
    NICHT der Einzelvorgang.

    ERSETZT Version 2 (Update 1 von PR #18) vollstaendig: die dortigen
    Vorgangslisten Taetigkeiten, Entscheidungsfaelle, Vertragsvorgaenge und
    Fallbeteiligungen sowie die FallID-Frage entfallen ersatzlos.
    Siehe DE/Substanz-Holding-KG/Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md,
    Abschnitt "Aenderungsprotokoll V2 -> V3".

    Nutzt eine Liste der steuerlichen Erfassung (DE/AO) mit (Eingang_Fehler)
    und referenziert eine weitere optional (4_Beteiligte_und_Quoten) --
    siehe Datenmodell, Abschnitt "Wiederverwendung".

    Feldkatalog (B3, maschinenlesbar, einzige Quelle fuer dieses Skript):
      DE/Substanz-Holding-KG/feldkatalog/feldkatalog.json (SchemaVersion 3)

    .DESCRIPTION
    Uebernimmt Parameter-, Verbindungs- und Idempotenzlogik unveraendert vom
    Vorbild DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 (PR #16):
      - Fehlende Listen/Spalten werden angelegt.
      - Bereits vorhandene Spalten werden ANGEGLICHEN (Anzeigename,
        Pflichtstatus, fehlende Auswahlwerte werden ERGAENZT, nie entfernt).
      - Es werden NIE Spalten, Listen oder Auswahlwerte geloescht.
      - Choice/MultiChoice-Spalten speichern STABILE CODES (z. B. FREQ_DAILY)
        als Wert, nicht die deutsche Beschriftung; Mapping im Feldkatalog.
      - "Nicht bekannt", "nicht zutreffend" und Null sind getrennte Zustaende
        (B4) -- deshalb Choice mit UNBEKANNT-Code statt Boolean, wo die
        Vorgabe neben Ja/Nein eine dritte Antwortmoeglichkeit vorsieht.
      - H-Handlungen (45 Einzelhandlungen) werden in Forms als Einzelfragen
        ausgefuehrt/nicht ausgefuehrt/nicht bekannt gestellt (B3), im Skript
        kompakt als drei MultiChoice-Spalten auf Personeneinsaetze abgelegt.
      - InterneBewertungen wird je Standort als eigene Liste
        (InterneBewertungen_ZH, InterneBewertungen_HH, gesteuert ueber
        -Standort) mit gebrochener Rechtevererbung angelegt. Lesezugriff
        erhalten nur die ueber -StandortGruppen/-GesamtGruppe benannten
        SharePoint-Gruppen (keine Item-Level-Berechtigung); ohne Gruppenname
        bleibt die jeweilige Liste gesperrt (Warnung statt Fehler, siehe
        README.md).

    .PARAMETER SiteUrl
    Zielsite im Tenant steueranwaltskanzlei.com (siehe
    DE/Substanz-Holding-KG/sharepoint-forms/README.md Abschnitt B).

    .PARAMETER ClientId
    ClientId einer tenant-eigenen Entra-App-Registrierung mit delegierter
    Berechtigung "AllSites.FullControl" (siehe DE/AO/sharepoint-forms/README.md
    Abschnitt C1).

    .EXAMPLE
    .\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"

    .NOTES
    Dieses Skript wird in dieser Session NICHT gegen einen Tenant ausgefuehrt.
    Es ist ausschliesslich fuer die spaetere Ausfuehrung durch eine berechtigte
    Person vorgesehen.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true, HelpMessage = "ClientId einer tenant-eigenen Entra-App-Registrierung mit delegierter Berechtigung 'AllSites.FullControl' (siehe DE/AO/sharepoint-forms/README.md Abschnitt C1). Die generische PnP-Management-Shell-App ist seit 09/2024 in den meisten Tenants gesperrt.")]
    [string]$ClientId,

    [Parameter(HelpMessage = "Standorte, fuer die eine eigene InterneBewertungen_<Standort>-Liste angelegt/angeglichen wird (idempotent - ein spaeterer Lauf mit zusaetzlichem Standort ergaenzt nur die fehlende Liste). Default nur ZH, da fast nur ZH-Faelle (Entscheidung Nils).")]
    [ValidateSet('ZH', 'HH')]
    [string[]]$Standort = @('ZH'),

    [Parameter(HelpMessage = "Zuordnung Standort -> SharePoint-Gruppenname mit Lesezugriff auf die jeweilige InterneBewertungen_<Standort>-Liste, z. B. @{ ZH = 'Substanzpruefung ZH'; HH = 'Substanzpruefung HH' }. Fehlt ein Standort in dieser Tabelle, wird nur gewarnt (keine Rechtevergabe ohne Gruppe) statt eines Fehlers.")]
    [hashtable]$StandortGruppen = @{},

    [Parameter(HelpMessage = "SharePoint-Gruppenname, der auf ALLEN InterneBewertungen_<Standort>-Listen Lesezugriff erhalten soll (z. B. 'steueranwaltskanzlei'). Leer lassen, um keine uebergreifende Gruppe zu berechtigen (dann nur Warnung).")]
    [string]$GesamtGruppe = ''
)

$ErrorActionPreference = "Stop"

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

# ---------------------------------------------------------------------------
# Hilfsfunktionen (identisch zu DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1)
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
    param([string]$List)
    try {
        $titleField = Get-PnPField -List $List -Identity "Title" -ErrorAction Stop
        if ($titleField.Required) {
            Set-PnPField -List $List -Identity "Title" -Values @{ Required = $false } | Out-Null
            Write-Host "  'Title' auf optional gesetzt: $List"
        }
    }
    catch {
        Write-Warning "  Konnte 'Title' in '$List' nicht auf optional pruefen/setzen: $_"
    }
}

function Get-XmlEscaped {
    param([string]$Text)
    return [System.Security.SecurityElement]::Escape($Text)
}

function Set-FieldIndexAndUniqueness {
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [switch]$EnforceUniqueValues
    )
    try {
        $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
        if (-not $field.Indexed) {
            Set-PnPField -List $List -Identity $InternalName -Values @{ Indexed = $true } | Out-Null
            Write-Host "  Feld indiziert: $List / $InternalName"
        }
        if ($EnforceUniqueValues) {
            $field = Get-PnPField -List $List -Identity $InternalName -ErrorAction Stop
            if (-not $field.EnforceUniqueValues) {
                Set-PnPField -List $List -Identity $InternalName -Values @{ EnforceUniqueValues = $true } | Out-Null
                Write-Host "  Feld auf eindeutige Werte gesetzt: $List / $InternalName"
            }
        }
    }
    catch {
        Write-Warning "  Konnte Index/Eindeutigkeit fuer $List/$InternalName nicht setzen (ggf. vorhandene Duplikate zuerst bereinigen): $_"
    }
}

function Set-LookupDeleteBehavior {
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [ValidateSet("None", "Restrict", "Cascade")][string]$DeleteBehavior = "None"
    )
    if ($DeleteBehavior -eq "None") { return }
    try {
        Set-PnPField -List $List -Identity $InternalName -Values @{ RelationshipDeleteBehavior = $DeleteBehavior } | Out-Null
        Write-Host "  Loeschverhalten gesetzt ($DeleteBehavior): $List / $InternalName"
    }
    catch {
        Write-Warning "  Konnte Loeschverhalten fuer $List/$InternalName nicht auf '$DeleteBehavior' setzen: $_"
    }
}

function Add-Field {
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Text", "Note", "Number", "Boolean", "Choice", "MultiChoice", "Lookup", "LookupMulti", "DateOnly", "DateTime", "URL")]
        [string]$Type,
        [switch]$Required,
        [string[]]$Choices,
        [string]$LookupList,
        [string]$LookupField = "Title",
        [ValidateSet("None", "Restrict", "Cascade")][string]$DeleteBehavior = "None",
        [Nullable[double]]$Min,
        [Nullable[double]]$Max,
        [string]$DefaultValue,
        [switch]$Indexed,
        [switch]$EnforceUniqueValues
    )

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
                $deleteBehaviorAttr = if ($DeleteBehavior -ne "None") { " RelationshipDeleteBehavior='$DeleteBehavior'" } else { "" }
                $fieldXml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' List='{$($targetList.Id)}' ShowField='$LookupField'$deleteBehaviorAttr />"
                Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
            }
            "LookupMulti" {
                $targetList = Get-PnPList -Identity $LookupList
                $fieldXml = "<Field Type='LookupMulti' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' List='{$($targetList.Id)}' ShowField='$LookupField' Mult='TRUE' />"
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
                if ($minMaxAttr -or $DefaultValue) {
                    $defaultXml = if ($DefaultValue) { "<Default>$(Get-XmlEscaped $DefaultValue)</Default>" } else { "" }
                    $fieldXml = "<Field Type='Number' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'$minMaxAttr>$defaultXml</Field>"
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
                if ($DefaultValue) {
                    $spType = if ($Type -eq "Note") { "Note" } else { "Text" }
                    $defaultXml = "<Default>$(Get-XmlEscaped $DefaultValue)</Default>"
                    $fieldXml = "<Field Type='$spType' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr'>$defaultXml</Field>"
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

        if ($existing.Title -ne $DisplayName) {
            try {
                Set-PnPField -List $List -Identity $InternalName -Values @{ Title = $DisplayName } | Out-Null
                Write-Host "    Anzeigename angeglichen -> '$DisplayName'"
            }
            catch {
                Write-Warning "    Konnte Anzeigename fuer $List/$InternalName nicht angleichen: $_"
            }
        }

        if ($Type -ne "Lookup" -and $Type -ne "LookupMulti" -and [bool]$existing.Required -ne [bool]$Required) {
            try {
                Set-PnPField -List $List -Identity $InternalName -Values @{ Required = [bool]$Required } | Out-Null
                Write-Host "    Pflichtstatus angeglichen -> Required=$Required"
            }
            catch {
                Write-Warning "    Konnte Pflichtstatus fuer $List/$InternalName nicht angleichen: $_"
            }
        }

        if (($Type -eq "Choice" -or $Type -eq "MultiChoice") -and $Choices) {
            $existingChoices = @($existing.Choices)
            $missingChoices = $Choices | Where-Object { $existingChoices -notcontains $_ }
            if ($missingChoices) {
                try {
                    $unionChoices = @($existingChoices) + @($missingChoices)
                    Set-PnPField -List $List -Identity $InternalName -Values @{ Choices = $unionChoices } | Out-Null
                    Write-Host "    Auswahlwerte ergaenzt (nichts entfernt): $($missingChoices -join ', ')"
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
    if (($Type -eq "Lookup" -or $Type -eq "LookupMulti") -and $DeleteBehavior -ne "None") {
        Set-LookupDeleteBehavior -List $List -InternalName $InternalName -DeleteBehavior $DeleteBehavior
    }
}

function Set-RestrictedPermission {
    <#
      Bricht die Rechtevererbung OHNE die bisherigen (breiten) Site-
      Berechtigungen zu kopieren (CopyRoleAssignments = $false) -- die Liste
      ist danach fuer alle ausser Site Collection Administrators unsichtbar,
      bis explizit eine Gruppe berechtigt wird. Das ist die bewusste
      "fail closed"-Entscheidung (Nils: "keine Rechtevergabe ohne Gruppe,
      Warnung statt Fehler"): fehlt eine Gruppe, bleibt die Liste gesperrt
      statt versehentlich fuer alle sichtbar zu sein.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$List,
        [string[]]$Groups
    )
    try {
        $listObj = Get-PnPList -Identity $List -Includes HasUniqueRoleAssignments
        if (-not $listObj.HasUniqueRoleAssignments) {
            $ctx = Get-PnPContext
            $listObj.BreakRoleInheritance($false, $false)
            $ctx.ExecuteQuery()
            Write-Host "  Rechtevererbung gebrochen (keine Berechtigungen kopiert): $List"
        }
        else {
            Write-Host "  Eigene Berechtigungen bereits gesetzt: $List"
        }
    }
    catch {
        Write-Warning "  Konnte Rechtevererbung fuer '$List' nicht brechen: $_"
    }

    $validGroups = @($Groups | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($validGroups.Count -eq 0) {
        Write-Warning "  Keine Gruppe fuer '$List' angegeben - die Liste bleibt gesperrt, bis manuell eine Gruppe mit Leserecht eingetragen wird (siehe sharepoint-forms/README.md)."
        return
    }
    foreach ($g in $validGroups) {
        try {
            Set-PnPListPermission -Identity $List -Group $g -AddRole "Read" | Out-Null
            Write-Host "  Leserecht erteilt an Gruppe '$g': $List"
        }
        catch {
            Write-Warning "  Konnte Gruppe '$g' nicht auf '$List' berechtigen (existiert die Gruppe auf dieser Site?): $_"
        }
    }
}


# ---------------------------------------------------------------------------
# Liste: Personen
# Personen, die fuer die Holding-KG taetig sind (S03)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personen"
Add-Field -List "Personen" -InternalName "person_name" -DisplayName 'Welche Person wird beschrieben?' -Type Text -Required
# person_name: Bekannte Person auswählen / weitere Person ergänzen.
Add-Field -List "Personen" -InternalName "person_id" -DisplayName 'Person-ID (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "Personen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Erfassungen
# Fallsteuerung je Substanzpruefung; Auskunftsperson aus N24 statt S02 (gestrichen)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Erfassungen"
Add-Field -List "Erfassungen" -InternalName "case_id" -DisplayName 'Fall-ID der Substanzprüfung (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "Erfassungen" -InternalName "project_id" -DisplayName 'Projektkennung (z. B. 22032-2)' -Type Text
Add-Field -List "Erfassungen" -InternalName "referenzcode" -DisplayName 'Erfassungsreferenz (Pflichtfeld auf jedem Formular, Plausibilitaetspruefung)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
# referenzcode: Kurzer, nicht fortlaufender Code je Erfassung (z. B. zufaellig vergeben). PFLICHTFELD auf allen fuenf Formularen anstelle der rohen Fall-ID. Ist KEIN Berechtigungsnachweis, sondern eine Plausibilitaetspruefung (Entscheidung Nils, offene Frage 1) - siehe sharepoint-forms/README.md Abschnitt D.
Add-Field -List "Erfassungen" -InternalName "formular_enddatum" -DisplayName 'Formular-Enddatum (Forms-Annahmeschluss)' -Type DateOnly
# formular_enddatum: In Microsoft Forms je Formular unter Einstellungen -> Start- und Enddatum einzutragen (Annahmeschluss nach Ende des Erhebungszeitraums); dieses Feld haelt den geplanten Termin zur Nachverfolgung fest.
Add-Field -List "Erfassungen" -InternalName "period_from" -DisplayName 'Für welchen Zeitraum gelten die Angaben? - Beginn' -Type DateOnly -Required
Add-Field -List "Erfassungen" -InternalName "period_to" -DisplayName 'Für welchen Zeitraum gelten die Angaben? - Ende' -Type DateOnly -Required
Add-Field -List "Erfassungen" -InternalName "period_confirmed" -DisplayName 'Vorgegebener Zeitraum bestätigt oder korrigiert' -Type Boolean -Required
# period_confirmed: Nur bestaetigen/korrigieren (2 Zustaende) - kein 'nicht bekannt' im Quelltext.
Add-Field -List "Erfassungen" -InternalName "schema_version" -DisplayName 'Schema-Version des Erfassungsbogens' -Type Number -Required `
    -DefaultValue '3'
Add-Field -List "Erfassungen" -InternalName "status" -DisplayName 'Status der Erfassung' -Type Choice -Required `
    -Choices @('ERFASSUNG_STATUS_OFFEN', 'ERFASSUNG_STATUS_IN_BEARBEITUNG', 'ERFASSUNG_STATUS_VOLLSTAENDIG', 'ERFASSUNG_STATUS_ABGESCHLOSSEN')
# status: Flow prueft Status vor jeder Elementanlage; bei 'abgeschlossen' Ablage in Eingang_Fehler statt in den Fachlisten (siehe README Abschnitt D).
Add-Field -List "Erfassungen" -InternalName "auskunftsperson_ref" -DisplayName 'Rückfragekontakt (aus N24, zuletzt übermittelte Angabe)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
# auskunftsperson_ref: Ersetzt S02 (gestrichen); N24 kann je Modul abweichen, hier wird der zuletzt gemeldete Kontakt gefuehrt.
Add-Field -List "Erfassungen" -InternalName "auskunftsperson_text" -DisplayName 'Rückfragekontakt, falls nicht aus Personen-Bestand' -Type Text
Add-Field -List "Erfassungen" -InternalName "confirmation_status" -DisplayName 'Entsprechen die Angaben dem derzeitigen Kenntnisstand?' -Type Choice -Required `
    -Choices @('N25_STATUS_VOLLSTAENDIG', 'N25_STATUS_UNVOLLSTAENDIG')
Add-Field -List "Erfassungen" -InternalName "missing_evidence_status" -DisplayName 'Gibt es für eine wesentliche Angabe noch keinen passenden Nachweis?' -Type Choice -Required `
    -Choices @('N26_STATUS_NEIN', 'N26_STATUS_JA', 'N26_STATUS_UNBEKANNT')

# ---------------------------------------------------------------------------
# Liste: Gesellschaften
# Bekannter Gesellschaftsbestand (Rolle), keine neue Strukturerhebung
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Gesellschaften"
Add-Field -List "Gesellschaften" -InternalName "company_id" -DisplayName 'Gesellschafts-ID (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "Gesellschaften" -InternalName "company_name" -DisplayName 'Bekannter Name der Gesellschaft' -Type Text -Required
Add-Field -List "Gesellschaften" -InternalName "company_role" -DisplayName 'Rolle im vorhandenen Bestand' -Type Choice -Required `
    -Choices @('GESELLSCHAFT_ROLLE_HOLDING_KG', 'GESELLSCHAFT_ROLLE_BETEILIGUNG', 'GESELLSCHAFT_ROLLE_SCHWEIZER_MUTTER', 'GESELLSCHAFT_ROLLE_ANDERE', 'GESELLSCHAFT_ROLLE_UNBEKANNT')
# company_role: Bestehende Struktur nicht erneut erheben (B1).
Add-Field -List "Gesellschaften" -InternalName "ao_participation_ref" -DisplayName 'Bezug: bereits in der steuerlichen Erfassung geführte Beteiligung (DE/AO, optional)' -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "Gesellschaften" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Orte
# Standortkatalog (O01 referenziert)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Orte"
Add-Field -List "Orte" -InternalName "ort_id" -DisplayName 'Ort-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Orte" -InternalName "ort_kategorie" -DisplayName 'Ortskategorie' -Type Choice -Required `
    -Choices @('ORT_KATEGORIE_KG_BUERO', 'ORT_KATEGORIE_BETEILIGUNG_RAEUME', 'ORT_KATEGORIE_HOMEOFFICE', 'ORT_KATEGORIE_SCHWEIZER_RAEUME', 'ORT_KATEGORIE_GESCHAEFTSPARTNER', 'ORT_KATEGORIE_UNTERWEGS', 'ORT_KATEGORIE_ANDERER_ORT')
Add-Field -List "Orte" -InternalName "standortgesellschaft_ref" -DisplayName 'Standortgesellschaft, soweit zutreffend' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Orte" -InternalName "adresse" -DisplayName 'Adresse bzw. Ort und Land' -Type Note
Add-Field -List "Orte" -InternalName "land" -DisplayName 'Land' -Type Text
Add-Field -List "Orte" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Substanznachweise
# Dokumentbibliothek fuer Belege (B3/B4: kein nativer Forms-Upload)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Substanznachweise" -Template "DocumentLibrary"
Add-Field -List "Substanznachweise" -InternalName "nachweis_id" -DisplayName 'Nachweis-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Substanznachweise" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Substanznachweise" -InternalName "dokumentart" -DisplayName 'Welche Unterlage können Sie einer Angabe zuordnen?' -Type Choice -Required `
    -Choices @('N20_DOKUMENTART_VERTRAG_NACHTRAG', 'N20_DOKUMENTART_STELLENBESCHREIBUNG', 'N20_DOKUMENTART_VOLLMACHT_KOMPETENZORDNUNG', 'N20_DOKUMENTART_EMAIL_GESPRAECHSNOTIZ', 'N20_DOKUMENTART_KALENDER_ZEITERFASSUNG', 'N20_DOKUMENTART_PLAN_BERICHT', 'N20_DOKUMENTART_BESCHLUSS_FREIGABE', 'N20_DOKUMENTART_SCHULUNGSUNTERLAGE', 'N20_DOKUMENTART_RECHNUNG_BUCHUNG', 'N20_DOKUMENTART_ZAHLUNGSNACHWEIS', 'N20_DOKUMENTART_RAUM_GERAETENACHWEIS', 'N20_DOKUMENTART_ANDERE')
Add-Field -List "Substanznachweise" -InternalName "dokumenttitel_text" -DisplayName 'Dokumenttitel' -Type Text -Required
Add-Field -List "Substanznachweise" -InternalName "dokumentdatum" -DisplayName 'Dokumentdatum' -Type DateOnly
Add-Field -List "Substanznachweise" -InternalName "gesellschaft_ref" -DisplayName 'Betroffene Gesellschaft, soweit zuordenbar' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Substanznachweise" -InternalName "dateilink" -DisplayName 'Link zur Datei, falls extern abgelegt' -Type URL
# dateilink: B3/B4: kein nativer Forms-Upload; separater Kanzlei-Uebermittlungsweg + Anlagenreferenz.
Add-Field -List "Substanznachweise" -InternalName "verfuegbarkeit" -DisplayName 'Wie ist die Unterlage verfügbar?' -Type Choice -Required `
    -Choices @('N22_VERFUEGBARKEIT_WIRD_UEBERMITTELT', 'N22_VERFUEGBARKEIT_BEREITS_UEBERMITTELT', 'N22_VERFUEGBARKEIT_KANN_NACHGEREICHT_WERDEN', 'N22_VERFUEGBARKEIT_DERZEIT_NICHT_AUFFINDBAR', 'N22_VERFUEGBARKEIT_NICHT_VORHANDEN', 'N22_VERFUEGBARKEIT_UNBEKANNT')

# ---------------------------------------------------------------------------
# Liste: Funktionen
# Navigationsebene Person x Gesellschaft x Stellenbezeichnung (S04) - eigenstaendig von Personenbindungen (siehe Datenmodell)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Funktionen"
Add-Field -List "Funktionen" -InternalName "funktion_id" -DisplayName 'Funktions-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Funktionen" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Funktionen" -InternalName "gesellschaft_ref" -DisplayName 'Welche Funktion hat diese Person? - Gesellschaft' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Funktionen" -InternalName "stellenbezeichnung_text" -DisplayName 'Stellenbezeichnung' -Type Text -Required
# stellenbezeichnung_text: Mehrere Funktionen moeglich - je Funktion ein Funktionen-Datensatz.
Add-Field -List "Funktionen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Personenbindungen
# Vertragliche Bindung und allgemeine Arbeitsorganisation (P30-P38)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personenbindungen"
Add-Field -List "Personenbindungen" -InternalName "bindung_id" -DisplayName 'Bindungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Personenbindungen" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "gesellschaft_ref" -DisplayName 'Mit welcher Gesellschaft besteht ein Vertrag für die Tätigkeit der Person?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Personenbindungen" -InternalName "gesellschaft_status" -DisplayName 'Status, falls kein/mehrere Vertragsverhältnisse' -Type Choice `
    -Choices @('GESELLSCHAFT_STATUS_KG_SELBST', 'GESELLSCHAFT_STATUS_BETEILIGUNG', 'GESELLSCHAFT_STATUS_SCHWEIZER_MUTTER', 'GESELLSCHAFT_STATUS_ANDERE', 'GESELLSCHAFT_STATUS_KEIN_VERTRAG', 'GESELLSCHAFT_STATUS_MEHRERE', 'GESELLSCHAFT_STATUS_UNBEKANNT')
# gesellschaft_status: Bei mehreren Vertragsverhaeltnissen je ein Personenbindungen-Datensatz.
Add-Field -List "Personenbindungen" -InternalName "vertragsart" -DisplayName 'Welche Art von Vertrag besteht?' -Type Choice `
    -Choices @('P31_VERTRAGSART_ARBEITSVERTRAG', 'P31_VERTRAGSART_GF_VORSTANDSVERTRAG', 'P31_VERTRAGSART_MANDATS_DIENSTLEISTUNGSVERTRAG', 'P31_VERTRAGSART_ANDERE', 'P31_VERTRAGSART_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "schriftform" -DisplayName 'Welcher schriftliche Stand liegt vor?' -Type Choice -Required `
    -Choices @('P32_SCHRIFTFORM_UNTERZEICHNET', 'P32_SCHRIFTFORM_NUR_ENTWURF', 'P32_SCHRIFTFORM_NICHT_VERFUEGBAR', 'P32_SCHRIFTFORM_NUR_MUENDLICH', 'P32_SCHRIFTFORM_KEINE', 'P32_SCHRIFTFORM_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "nachweis_ref" -DisplayName 'Anlage (Vertrag)' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "beginn" -DisplayName 'Seit wann besteht das Vertragsverhältnis?' -Type DateOnly -Required
Add-Field -List "Personenbindungen" -InternalName "beginn_genauigkeit" -DisplayName 'Datumsgenauigkeit' -Type Choice -Required `
    -Choices @('GENAUIGKEIT_GENAU', 'GENAUIGKEIT_UNGEFAEHR', 'GENAUIGKEIT_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "ende" -DisplayName 'Enddatum, falls beendet' -Type DateOnly
Add-Field -List "Personenbindungen" -InternalName "weisungsgeber_ref" -DisplayName 'Wer legt im Arbeitsalltag die Aufgaben und Prioritäten fest?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "weisungsgeber_status" -DisplayName 'Status, falls keine konkrete Person' -Type Choice `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "anweisungsbefugter_ref" -DisplayName 'Wer kann der Person konkrete Arbeitsanweisungen geben?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "anweisungsbefugter_status" -DisplayName 'Status, falls abweichend von P34' -Type Choice `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "abwesenheit_genehmiger_ref" -DisplayName 'Wer genehmigt Abwesenheiten?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "abwesenheit_genehmiger_status" -DisplayName 'Status' -Type Choice `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "beurteiler_ref" -DisplayName 'Wer beurteilt die Arbeit der Person?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "beurteiler_status" -DisplayName 'Status' -Type Choice `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "vertretung_ref" -DisplayName 'Wer vertritt die Person bei Abwesenheit?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "vertretung_status" -DisplayName 'Status' -Type Choice `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Aufgaben
# Zentrale Liste: wiederkehrende Aufgabe je Person x Bereich (T01-T09, T16; G10/G12/D01 Gateway)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Aufgaben"
Add-Field -List "Aufgaben" -InternalName "aufgabe_id" -DisplayName 'Aufgabe-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Aufgaben" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Aufgaben" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Aufgaben" -InternalName "bereich_code" -DisplayName 'Bestätigten Aufgabenbereich auswählen' -Type Choice -Required `
    -Choices @('S07_BEREICH_KUNDEN_LIEFERANTEN', 'S07_BEREICH_PERSONAL', 'S07_BEREICH_FINANZEN_BERATER', 'S07_BEREICH_PROJEKTE_PLANUNG', 'S07_BEREICH_BERICHTE_KONTROLLE', 'S07_BEREICH_VORGABEN_SCHULUNG', 'S07_BEREICH_EIGENE_VERWALTUNG', 'S07_BEREICH_BETEILIGUNG_MUTTER', 'S07_BEREICH_ANDERER_BEREICH', 'S07_BEREICH_NICHT_BEKANNT')
Add-Field -List "Aufgaben" -InternalName "handlungen_bezug" -DisplayName 'Zugrundeliegende bestätigte Handlungen' -Type MultiChoice `
    -Choices @('H_KUNDEN_LIEFERANTEN_01_KUNDEN_BETREUT', 'H_KUNDEN_LIEFERANTEN_02_ANGEBOTE_AUSGEARBEITET', 'H_KUNDEN_LIEFERANTEN_03_PREISE_FESTGELEGT', 'H_KUNDEN_LIEFERANTEN_04_KUNDENVERTRAEGE_VERHANDELT', 'H_KUNDEN_LIEFERANTEN_05_LIEFERANTEN_AUSGEWAEHLT', 'H_KUNDEN_LIEFERANTEN_06_LIEFERANTENVERTRAEGE_VERHANDELT', 'H_PERSONAL_01_BEWERBER_AUSGEWAEHLT', 'H_PERSONAL_02_VERGUETUNG_ODER_VERTRAGSBEDINGUNGEN_VERHANDELT', 'H_PERSONAL_03_EINSTELLUNGEN_ODER_KUENDIGUNGEN_ENTSCHIEDEN', 'H_PERSONAL_04_KONKRETE_ARBEITSAUFGABEN_VERTEILT', 'H_PERSONAL_05_ABWESENHEITEN_GENEHMIGT', 'H_PERSONAL_06_LEISTUNGEN_VON_MITARBEITENDEN_BEURTEILT', 'H_FINANZEN_BERATER_01_LIQUIDITAET_GEPLANT', 'H_FINANZEN_BERATER_02_ZAHLUNGEN_FREIGEGEBEN', 'H_FINANZEN_BERATER_03_BANKGESPRAECHE_GEFUEHRT', 'H_FINANZEN_BERATER_04_FINANZIERUNGSBEDINGUNGEN_VERHANDELT', 'H_FINANZEN_BERATER_05_BUCHHALTER_ODER_STEUERBERATER_GESTEUERT', 'H_FINANZEN_BERATER_06_ENTSCHEIDUNGEN_NACH_DEREN_BERATUNG_GETROFFEN', 'H_PROJEKTE_PLANUNG_01_PROJEKTE_GELEITET', 'H_PROJEKTE_PLANUNG_02_KAPAZITAETEN_ODER_TERMINE_GEPLANT', 'H_PROJEKTE_PLANUNG_03_BETRIEBLICHE_PROBLEME_ENTSCHIEDEN', 'H_PROJEKTE_PLANUNG_04_BUDGETS_VORBEREITET', 'H_PROJEKTE_PLANUNG_05_BUDGETS_FREIGEGEBEN', 'H_PROJEKTE_PLANUNG_06_INVESTITIONEN_AUSGEWAEHLT_ODER_FREIGEGEBEN', 'H_BERICHTE_KONTROLLE_01_BERICHTE_ERSTELLT', 'H_BERICHTE_KONTROLLE_02_BERICHTE_GEPRUEFT', 'H_BERICHTE_KONTROLLE_03_ERLAEUTERUNGEN_ANGEFORDERT', 'H_BERICHTE_KONTROLLE_04_MASSNAHMEN_EMPFOHLEN', 'H_BERICHTE_KONTROLLE_05_KONKRETE_KORREKTURMASSNAHMEN_ANGEORDNET', 'H_VORGABEN_SCHULUNG_01_ALLGEMEINE_RICHTLINIEN_ENTWICKELT', 'H_VORGABEN_SCHULUNG_02_ALLGEMEINE_VORGABEN_BESCHLOSSEN', 'H_VORGABEN_SCHULUNG_03_KONKRETE_EINZELANWEISUNGEN_GEGEBEN', 'H_VORGABEN_SCHULUNG_04_MITARBEITENDE_GESCHULT', 'H_EIGENE_VERWALTUNG_01_EIGENE_BUCHFUEHRUNG_ODER_STEUERN_BEARBEITET', 'H_EIGENE_VERWALTUNG_02_EIGENES_PERSONAL_VERWALTET', 'H_EIGENE_VERWALTUNG_03_EIGENE_RAEUME_ODER_ARBEITSMITTEL_VERWALTET', 'H_EIGENE_VERWALTUNG_04_EIGENE_IT_BETREUT', 'H_EIGENE_VERWALTUNG_05_EIGENE_FINANZIERUNG_BEARBEITET', 'H_EIGENE_VERWALTUNG_06_EIGENE_LEISTUNGEN_ABGERECHNET', 'H_BETEILIGUNG_MUTTER_01_BETEILIGUNGSENTWICKLUNG_UEBERWACHT', 'H_BETEILIGUNG_MUTTER_02_BETEILIGUNGSERWERB_ODER_VERKAUF_VORBEREITET', 'H_BETEILIGUNG_MUTTER_03_STIMMABGABEN_ODER_GESELLSCHAFTERBESCHLUESSE_VORBER', 'H_BETEILIGUNG_MUTTER_04_AUSSCHUETTUNG_ODER_KAPITALMASSNAHME_VORBEREITET', 'H_BETEILIGUNG_MUTTER_05_UNTERLAGEN_FUER_ABSCHLUSS_ODER_KONZERNABSCHLUSS_DE', 'H_BETEILIGUNG_MUTTER_06_SITZUNGEN_ODER_BERICHTE_FUER_DIE_MUTTER_VORBEREITE')
# handlungen_bezug: Aggregation bestaetigter Handlungen zu dieser Aufgabe (Abschnitt 1.2, letzter Absatz).
Add-Field -List "Aufgaben" -InternalName "t01_text" -DisplayName 'Welche Aufgabe übernimmt die Person im Tagesgeschäft? (konkretisiert)' -Type Note -Required
# t01_text: Beispiel: 'Finanzleitung der Gesellschaft A'.
Add-Field -List "Aufgaben" -InternalName "t02_art" -DisplayName 'Wie ist die Person in diesem Aufgabenbereich tätig?' -Type Choice -Required `
    -Choices @('T02_ART_DAUERHAFT', 'T02_ART_REGELMAESSIG', 'T02_ART_VERTRETUNG', 'T02_ART_FALLWEISE', 'T02_ART_PROJEKT', 'T02_ART_GEPLANT', 'T02_ART_UNBEKANNT')
# t02_art: Geaenderte Bedeutung gegenueber V2 (dort T02 = Auftrag/Funktion-Frage).
Add-Field -List "Aufgaben" -InternalName "t02_anlass_text" -DisplayName 'Üblicher Anlass (bei fallweiser Tätigkeit)' -Type Text
Add-Field -List "Aufgaben" -InternalName "t03_beginn" -DisplayName 'Seit wann übt die Person diese Aufgabe aus?' -Type DateOnly
Add-Field -List "Aufgaben" -InternalName "t03_beginn_genauigkeit" -DisplayName 'Datumsgenauigkeit' -Type Choice `
    -Choices @('GENAUIGKEIT_GENAU', 'GENAUIGKEIT_UNGEFAEHR', 'GENAUIGKEIT_UNBEKANNT')
Add-Field -List "Aufgaben" -InternalName "t03_ende" -DisplayName 'Ende (bei beendeter Tätigkeit)' -Type DateOnly
Add-Field -List "Aufgaben" -InternalName "t05_taetigkeiten" -DisplayName 'Welche Tätigkeiten führt die Person dabei selbst aus?' -Type MultiChoice -Required `
    -Choices @('T05_TAETIGKEIT_INFORMATIONEN_AUSWERTEN', 'T05_TAETIGKEIT_ENTSCHEIDUNGEN_VORBEREITEN', 'T05_TAETIGKEIT_VERTRAEGE_VERHANDELN', 'T05_TAETIGKEIT_ENTSCHEIDUNGEN_TREFFEN', 'T05_TAETIGKEIT_VERBINDLICHE_EINZELANWEISUNGEN', 'T05_TAETIGKEIT_UMSETZUNG_STEUERN', 'T05_TAETIGKEIT_ARBEITSERGEBNISSE_KONTROLLIEREN', 'T05_TAETIGKEIT_BERATEN', 'T05_TAETIGKEIT_SCHULEN', 'T05_TAETIGKEIT_ADMINISTRATIVE_ARBEITEN', 'T05_TAETIGKEIT_ANDERE')
# t05_taetigkeiten: Auswahl wird anhand der bestaetigten Handlungen eingegrenzt (Forms-Filter).
Add-Field -List "Aufgaben" -InternalName "t07_auftrag" -DisplayName 'In wessen Auftrag übernimmt die Person diese Aufgaben?' -Type Choice -Required `
    -Choices @('T07_AUFTRAG_KG', 'T07_AUFTRAG_BETEILIGUNG', 'T07_AUFTRAG_SCHWEIZER_MUTTER', 'T07_AUFTRAG_ANDERER', 'T07_AUFTRAG_KEINE', 'T07_AUFTRAG_UNBEKANNT')
Add-Field -List "Aufgaben" -InternalName "t08_funktion_ref" -DisplayName 'In welcher Funktion ist die Person tätig?' -Type Lookup `
    -LookupList "Funktionen" -LookupField "display_label"
Add-Field -List "Aufgaben" -InternalName "t08_funktion_status" -DisplayName 'Status der Funktionsangabe' -Type Choice -Required `
    -Choices @('T08_FUNKTION_STATUS_BEKANNT', 'T08_FUNKTION_STATUS_ANDERE', 'T08_FUNKTION_STATUS_MEHRERE', 'T08_FUNKTION_STATUS_UNBEKANNT')
Add-Field -List "Aufgaben" -InternalName "t08_andere_text" -DisplayName 'Andere Funktion - bitte benennen' -Type Text
Add-Field -List "Aufgaben" -InternalName "t09_zusammenarbeit" -DisplayName 'Mit welchen Personen oder Stellen arbeitet sie regelmässig zusammen?' -Type MultiChoice -Required `
    -Choices @('T09_ZUSAMMENARBEIT_GESCHAEFTSLEITUNG', 'T09_ZUSAMMENARBEIT_FACHABTEILUNGEN', 'T09_ZUSAMMENARBEIT_MITARBEITENDE', 'T09_ZUSAMMENARBEIT_KUNDEN', 'T09_ZUSAMMENARBEIT_LIEFERANTEN', 'T09_ZUSAMMENARBEIT_BANKEN', 'T09_ZUSAMMENARBEIT_BUCHHALTUNG_STEUERBERATUNG', 'T09_ZUSAMMENARBEIT_ANDERE_BERATER', 'T09_ZUSAMMENARBEIT_GESELLSCHAFTER', 'T09_ZUSAMMENARBEIT_ANDERE_STELLEN')
Add-Field -List "Aufgaben" -InternalName "t09_zusammenarbeit_text" -DisplayName 'Zugehörige Gesellschaft/Organisation je Punkt' -Type Note
Add-Field -List "Aufgaben" -InternalName "t16_haeufigkeit" -DisplayName 'Wie häufig arbeitet die Person in diesem Aufgabenbereich?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NICHT_TAETIG', 'FREQ_UNBEKANNT')
Add-Field -List "Aufgaben" -InternalName "g10_aufgabenart" -DisplayName 'Welche Aufgaben betreffen die eigene Organisation oder Beteiligungsverwaltung der KG?' -Type MultiChoice `
    -Choices @('G10_AUFGABENART_BUCHFUEHRUNG_STEUERN', 'G10_AUFGABENART_EIGENES_PERSONAL', 'G10_AUFGABENART_EIGENE_RAEUME_AUSSTATTUNG', 'G10_AUFGABENART_EIGENE_IT', 'G10_AUFGABENART_EIGENE_FINANZIERUNG', 'G10_AUFGABENART_ABRECHNUNG_MANAGEMENTLEISTUNGEN', 'G10_AUFGABENART_UEBERWACHUNG_BETEILIGUNGEN', 'G10_AUFGABENART_VORBEREITUNG_STIMMABGABEN', 'G10_AUFGABENART_ANDERE', 'G10_AUFGABENART_KEINE')
# g10_aufgabenart: Nur bei bereich_code=EIGENE_VERWALTUNG.
Add-Field -List "Aufgaben" -InternalName "g12_mutterarbeiten" -DisplayName 'Welche laufenden Arbeiten werden für die Schweizer Mutter erledigt?' -Type MultiChoice `
    -Choices @('G12_MUTTERARBEITEN_EIGENER_ABSCHLUSS_MUTTER', 'G12_MUTTERARBEITEN_KONZERNABSCHLUSS', 'G12_MUTTERARBEITEN_STEUERERKLAERUNGEN_MUTTER', 'G12_MUTTERARBEITEN_SITZUNGSUNTERLAGEN', 'G12_MUTTERARBEITEN_BERICHTE_ANTEILSEIGNER', 'G12_MUTTERARBEITEN_FINANZIERUNG_BETEILIGUNGSERWERB', 'G12_MUTTERARBEITEN_ANDERE', 'G12_MUTTERARBEITEN_KEINE')
# g12_mutterarbeiten: Nur bei bereich_code=BETEILIGUNG_MUTTER.
Add-Field -List "Aufgaben" -InternalName "d01_rollen" -DisplayName 'Welche Entscheidungsaufgaben übernimmt die Person tatsächlich?' -Type MultiChoice `
    -Choices @('D01_ROLLE_ENTSCHEIDET_SELBST', 'D01_ROLLE_ENTSCHEIDET_GEMEINSAM', 'D01_ROLLE_BEREITET_VOR', 'D01_ROLLE_ZUSTIMMUNG', 'D01_ROLLE_UMSETZT', 'D01_ROLLE_KONTROLLIERT', 'D01_ROLLE_KEINE', 'D01_ROLLE_UNBEKANNT')
# d01_rollen: 'keine' exklusiv; steuert, ob Entscheidungsbefugnisse-Zeilen erfasst werden.
Add-Field -List "Aufgaben" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Personeneinsaetze
# Person x Erfassungszeitraum: S05-S07, H-Handlungsbestaetigungen (45 Handlungen als 3 MultiChoice), Z01-Z07, O03-O05
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personeneinsaetze"
Add-Field -List "Personeneinsaetze" -InternalName "einsatz_id" -DisplayName 'Einsatz-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Personeneinsaetze" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Personeneinsaetze" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personeneinsaetze" -InternalName "taetigkeit_status" -DisplayName 'War die Person im angegebenen Zeitraum im Zusammenhang mit der KG tätig?' -Type Choice -Required `
    -Choices @('S05_STATUS_JA', 'S05_STATUS_GEPLANT', 'S05_STATUS_BEENDET', 'S05_STATUS_KEINE', 'S05_STATUS_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "taetigkeit_beginn" -DisplayName 'Seit wann übernimmt die Person diese Aufgaben tatsächlich?' -Type DateOnly
Add-Field -List "Personeneinsaetze" -InternalName "taetigkeit_beginn_genauigkeit" -DisplayName 'Datumsgenauigkeit' -Type Choice `
    -Choices @('GENAUIGKEIT_GENAU', 'GENAUIGKEIT_UNGEFAEHR', 'GENAUIGKEIT_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "taetigkeit_ende" -DisplayName 'Enddatum (nur bei beendeter Tätigkeit)' -Type DateOnly
Add-Field -List "Personeneinsaetze" -InternalName "bereiche" -DisplayName 'In welchen Bereichen hat die Person gearbeitet?' -Type MultiChoice `
    -Choices @('S07_BEREICH_KUNDEN_LIEFERANTEN', 'S07_BEREICH_PERSONAL', 'S07_BEREICH_FINANZEN_BERATER', 'S07_BEREICH_PROJEKTE_PLANUNG', 'S07_BEREICH_BERICHTE_KONTROLLE', 'S07_BEREICH_VORGABEN_SCHULUNG', 'S07_BEREICH_EIGENE_VERWALTUNG', 'S07_BEREICH_BETEILIGUNG_MUTTER', 'S07_BEREICH_ANDERER_BEREICH', 'S07_BEREICH_NICHT_BEKANNT')
# bereiche: Nicht ausgewaehlte Bereiche gelten NICHT automatisch als ausdruecklich verneint (B4).
Add-Field -List "Personeneinsaetze" -InternalName "bereich_andere_text" -DisplayName 'Anderer Bereich - bitte benennen' -Type Text
Add-Field -List "Personeneinsaetze" -InternalName "handlungen_ausgefuehrt" -DisplayName 'Handlungen: ausgeführt' -Type MultiChoice `
    -Choices @('H_KUNDEN_LIEFERANTEN_01_KUNDEN_BETREUT', 'H_KUNDEN_LIEFERANTEN_02_ANGEBOTE_AUSGEARBEITET', 'H_KUNDEN_LIEFERANTEN_03_PREISE_FESTGELEGT', 'H_KUNDEN_LIEFERANTEN_04_KUNDENVERTRAEGE_VERHANDELT', 'H_KUNDEN_LIEFERANTEN_05_LIEFERANTEN_AUSGEWAEHLT', 'H_KUNDEN_LIEFERANTEN_06_LIEFERANTENVERTRAEGE_VERHANDELT', 'H_PERSONAL_01_BEWERBER_AUSGEWAEHLT', 'H_PERSONAL_02_VERGUETUNG_ODER_VERTRAGSBEDINGUNGEN_VERHANDELT', 'H_PERSONAL_03_EINSTELLUNGEN_ODER_KUENDIGUNGEN_ENTSCHIEDEN', 'H_PERSONAL_04_KONKRETE_ARBEITSAUFGABEN_VERTEILT', 'H_PERSONAL_05_ABWESENHEITEN_GENEHMIGT', 'H_PERSONAL_06_LEISTUNGEN_VON_MITARBEITENDEN_BEURTEILT', 'H_FINANZEN_BERATER_01_LIQUIDITAET_GEPLANT', 'H_FINANZEN_BERATER_02_ZAHLUNGEN_FREIGEGEBEN', 'H_FINANZEN_BERATER_03_BANKGESPRAECHE_GEFUEHRT', 'H_FINANZEN_BERATER_04_FINANZIERUNGSBEDINGUNGEN_VERHANDELT', 'H_FINANZEN_BERATER_05_BUCHHALTER_ODER_STEUERBERATER_GESTEUERT', 'H_FINANZEN_BERATER_06_ENTSCHEIDUNGEN_NACH_DEREN_BERATUNG_GETROFFEN', 'H_PROJEKTE_PLANUNG_01_PROJEKTE_GELEITET', 'H_PROJEKTE_PLANUNG_02_KAPAZITAETEN_ODER_TERMINE_GEPLANT', 'H_PROJEKTE_PLANUNG_03_BETRIEBLICHE_PROBLEME_ENTSCHIEDEN', 'H_PROJEKTE_PLANUNG_04_BUDGETS_VORBEREITET', 'H_PROJEKTE_PLANUNG_05_BUDGETS_FREIGEGEBEN', 'H_PROJEKTE_PLANUNG_06_INVESTITIONEN_AUSGEWAEHLT_ODER_FREIGEGEBEN', 'H_BERICHTE_KONTROLLE_01_BERICHTE_ERSTELLT', 'H_BERICHTE_KONTROLLE_02_BERICHTE_GEPRUEFT', 'H_BERICHTE_KONTROLLE_03_ERLAEUTERUNGEN_ANGEFORDERT', 'H_BERICHTE_KONTROLLE_04_MASSNAHMEN_EMPFOHLEN', 'H_BERICHTE_KONTROLLE_05_KONKRETE_KORREKTURMASSNAHMEN_ANGEORDNET', 'H_VORGABEN_SCHULUNG_01_ALLGEMEINE_RICHTLINIEN_ENTWICKELT', 'H_VORGABEN_SCHULUNG_02_ALLGEMEINE_VORGABEN_BESCHLOSSEN', 'H_VORGABEN_SCHULUNG_03_KONKRETE_EINZELANWEISUNGEN_GEGEBEN', 'H_VORGABEN_SCHULUNG_04_MITARBEITENDE_GESCHULT', 'H_EIGENE_VERWALTUNG_01_EIGENE_BUCHFUEHRUNG_ODER_STEUERN_BEARBEITET', 'H_EIGENE_VERWALTUNG_02_EIGENES_PERSONAL_VERWALTET', 'H_EIGENE_VERWALTUNG_03_EIGENE_RAEUME_ODER_ARBEITSMITTEL_VERWALTET', 'H_EIGENE_VERWALTUNG_04_EIGENE_IT_BETREUT', 'H_EIGENE_VERWALTUNG_05_EIGENE_FINANZIERUNG_BEARBEITET', 'H_EIGENE_VERWALTUNG_06_EIGENE_LEISTUNGEN_ABGERECHNET', 'H_BETEILIGUNG_MUTTER_01_BETEILIGUNGSENTWICKLUNG_UEBERWACHT', 'H_BETEILIGUNG_MUTTER_02_BETEILIGUNGSERWERB_ODER_VERKAUF_VORBEREITET', 'H_BETEILIGUNG_MUTTER_03_STIMMABGABEN_ODER_GESELLSCHAFTERBESCHLUESSE_VORBER', 'H_BETEILIGUNG_MUTTER_04_AUSSCHUETTUNG_ODER_KAPITALMASSNAHME_VORBEREITET', 'H_BETEILIGUNG_MUTTER_05_UNTERLAGEN_FUER_ABSCHLUSS_ODER_KONZERNABSCHLUSS_DE', 'H_BETEILIGUNG_MUTTER_06_SITZUNGEN_ODER_BERICHTE_FUER_DIE_MUTTER_VORBEREITE')
# handlungen_ausgefuehrt: Bestaetigt (Entscheidung Nils): je Handlung eine Forms-Einzelfrage ausgefuehrt/nicht ausgefuehrt/nicht bekannt (B3), hier als 3 MultiChoice-Spalten gebuendelt gespeichert. Ein Handlungscode, der in KEINER der drei Spalten steht, bedeutet 'nicht gefragt' (Bereich nicht ausgewaehlt, S07) - nicht 'nicht bekannt'. Flow-Pruefregel: derselbe Handlungscode darf nicht in mehr als einer der drei Spalten vorkommen, sonst Ablage in Eingang_Fehler bzw. OffenePunkte statt stiller Uebernahme. Auswertungen je einzelner Handlung muessen alle drei Spalten auflösen (siehe sharepoint-forms/README.md).
Add-Field -List "Personeneinsaetze" -InternalName "handlungen_nicht_ausgefuehrt" -DisplayName 'Handlungen: nicht ausgeführt' -Type MultiChoice `
    -Choices @('H_KUNDEN_LIEFERANTEN_01_KUNDEN_BETREUT', 'H_KUNDEN_LIEFERANTEN_02_ANGEBOTE_AUSGEARBEITET', 'H_KUNDEN_LIEFERANTEN_03_PREISE_FESTGELEGT', 'H_KUNDEN_LIEFERANTEN_04_KUNDENVERTRAEGE_VERHANDELT', 'H_KUNDEN_LIEFERANTEN_05_LIEFERANTEN_AUSGEWAEHLT', 'H_KUNDEN_LIEFERANTEN_06_LIEFERANTENVERTRAEGE_VERHANDELT', 'H_PERSONAL_01_BEWERBER_AUSGEWAEHLT', 'H_PERSONAL_02_VERGUETUNG_ODER_VERTRAGSBEDINGUNGEN_VERHANDELT', 'H_PERSONAL_03_EINSTELLUNGEN_ODER_KUENDIGUNGEN_ENTSCHIEDEN', 'H_PERSONAL_04_KONKRETE_ARBEITSAUFGABEN_VERTEILT', 'H_PERSONAL_05_ABWESENHEITEN_GENEHMIGT', 'H_PERSONAL_06_LEISTUNGEN_VON_MITARBEITENDEN_BEURTEILT', 'H_FINANZEN_BERATER_01_LIQUIDITAET_GEPLANT', 'H_FINANZEN_BERATER_02_ZAHLUNGEN_FREIGEGEBEN', 'H_FINANZEN_BERATER_03_BANKGESPRAECHE_GEFUEHRT', 'H_FINANZEN_BERATER_04_FINANZIERUNGSBEDINGUNGEN_VERHANDELT', 'H_FINANZEN_BERATER_05_BUCHHALTER_ODER_STEUERBERATER_GESTEUERT', 'H_FINANZEN_BERATER_06_ENTSCHEIDUNGEN_NACH_DEREN_BERATUNG_GETROFFEN', 'H_PROJEKTE_PLANUNG_01_PROJEKTE_GELEITET', 'H_PROJEKTE_PLANUNG_02_KAPAZITAETEN_ODER_TERMINE_GEPLANT', 'H_PROJEKTE_PLANUNG_03_BETRIEBLICHE_PROBLEME_ENTSCHIEDEN', 'H_PROJEKTE_PLANUNG_04_BUDGETS_VORBEREITET', 'H_PROJEKTE_PLANUNG_05_BUDGETS_FREIGEGEBEN', 'H_PROJEKTE_PLANUNG_06_INVESTITIONEN_AUSGEWAEHLT_ODER_FREIGEGEBEN', 'H_BERICHTE_KONTROLLE_01_BERICHTE_ERSTELLT', 'H_BERICHTE_KONTROLLE_02_BERICHTE_GEPRUEFT', 'H_BERICHTE_KONTROLLE_03_ERLAEUTERUNGEN_ANGEFORDERT', 'H_BERICHTE_KONTROLLE_04_MASSNAHMEN_EMPFOHLEN', 'H_BERICHTE_KONTROLLE_05_KONKRETE_KORREKTURMASSNAHMEN_ANGEORDNET', 'H_VORGABEN_SCHULUNG_01_ALLGEMEINE_RICHTLINIEN_ENTWICKELT', 'H_VORGABEN_SCHULUNG_02_ALLGEMEINE_VORGABEN_BESCHLOSSEN', 'H_VORGABEN_SCHULUNG_03_KONKRETE_EINZELANWEISUNGEN_GEGEBEN', 'H_VORGABEN_SCHULUNG_04_MITARBEITENDE_GESCHULT', 'H_EIGENE_VERWALTUNG_01_EIGENE_BUCHFUEHRUNG_ODER_STEUERN_BEARBEITET', 'H_EIGENE_VERWALTUNG_02_EIGENES_PERSONAL_VERWALTET', 'H_EIGENE_VERWALTUNG_03_EIGENE_RAEUME_ODER_ARBEITSMITTEL_VERWALTET', 'H_EIGENE_VERWALTUNG_04_EIGENE_IT_BETREUT', 'H_EIGENE_VERWALTUNG_05_EIGENE_FINANZIERUNG_BEARBEITET', 'H_EIGENE_VERWALTUNG_06_EIGENE_LEISTUNGEN_ABGERECHNET', 'H_BETEILIGUNG_MUTTER_01_BETEILIGUNGSENTWICKLUNG_UEBERWACHT', 'H_BETEILIGUNG_MUTTER_02_BETEILIGUNGSERWERB_ODER_VERKAUF_VORBEREITET', 'H_BETEILIGUNG_MUTTER_03_STIMMABGABEN_ODER_GESELLSCHAFTERBESCHLUESSE_VORBER', 'H_BETEILIGUNG_MUTTER_04_AUSSCHUETTUNG_ODER_KAPITALMASSNAHME_VORBEREITET', 'H_BETEILIGUNG_MUTTER_05_UNTERLAGEN_FUER_ABSCHLUSS_ODER_KONZERNABSCHLUSS_DE', 'H_BETEILIGUNG_MUTTER_06_SITZUNGEN_ODER_BERICHTE_FUER_DIE_MUTTER_VORBEREITE')
# handlungen_nicht_ausgefuehrt: Siehe Hinweis bei handlungen_ausgefuehrt (Flow-Pruefregel: keine Handlung in mehr als einer der drei Spalten).
Add-Field -List "Personeneinsaetze" -InternalName "handlungen_unbekannt" -DisplayName 'Handlungen: nicht bekannt' -Type MultiChoice `
    -Choices @('H_KUNDEN_LIEFERANTEN_01_KUNDEN_BETREUT', 'H_KUNDEN_LIEFERANTEN_02_ANGEBOTE_AUSGEARBEITET', 'H_KUNDEN_LIEFERANTEN_03_PREISE_FESTGELEGT', 'H_KUNDEN_LIEFERANTEN_04_KUNDENVERTRAEGE_VERHANDELT', 'H_KUNDEN_LIEFERANTEN_05_LIEFERANTEN_AUSGEWAEHLT', 'H_KUNDEN_LIEFERANTEN_06_LIEFERANTENVERTRAEGE_VERHANDELT', 'H_PERSONAL_01_BEWERBER_AUSGEWAEHLT', 'H_PERSONAL_02_VERGUETUNG_ODER_VERTRAGSBEDINGUNGEN_VERHANDELT', 'H_PERSONAL_03_EINSTELLUNGEN_ODER_KUENDIGUNGEN_ENTSCHIEDEN', 'H_PERSONAL_04_KONKRETE_ARBEITSAUFGABEN_VERTEILT', 'H_PERSONAL_05_ABWESENHEITEN_GENEHMIGT', 'H_PERSONAL_06_LEISTUNGEN_VON_MITARBEITENDEN_BEURTEILT', 'H_FINANZEN_BERATER_01_LIQUIDITAET_GEPLANT', 'H_FINANZEN_BERATER_02_ZAHLUNGEN_FREIGEGEBEN', 'H_FINANZEN_BERATER_03_BANKGESPRAECHE_GEFUEHRT', 'H_FINANZEN_BERATER_04_FINANZIERUNGSBEDINGUNGEN_VERHANDELT', 'H_FINANZEN_BERATER_05_BUCHHALTER_ODER_STEUERBERATER_GESTEUERT', 'H_FINANZEN_BERATER_06_ENTSCHEIDUNGEN_NACH_DEREN_BERATUNG_GETROFFEN', 'H_PROJEKTE_PLANUNG_01_PROJEKTE_GELEITET', 'H_PROJEKTE_PLANUNG_02_KAPAZITAETEN_ODER_TERMINE_GEPLANT', 'H_PROJEKTE_PLANUNG_03_BETRIEBLICHE_PROBLEME_ENTSCHIEDEN', 'H_PROJEKTE_PLANUNG_04_BUDGETS_VORBEREITET', 'H_PROJEKTE_PLANUNG_05_BUDGETS_FREIGEGEBEN', 'H_PROJEKTE_PLANUNG_06_INVESTITIONEN_AUSGEWAEHLT_ODER_FREIGEGEBEN', 'H_BERICHTE_KONTROLLE_01_BERICHTE_ERSTELLT', 'H_BERICHTE_KONTROLLE_02_BERICHTE_GEPRUEFT', 'H_BERICHTE_KONTROLLE_03_ERLAEUTERUNGEN_ANGEFORDERT', 'H_BERICHTE_KONTROLLE_04_MASSNAHMEN_EMPFOHLEN', 'H_BERICHTE_KONTROLLE_05_KONKRETE_KORREKTURMASSNAHMEN_ANGEORDNET', 'H_VORGABEN_SCHULUNG_01_ALLGEMEINE_RICHTLINIEN_ENTWICKELT', 'H_VORGABEN_SCHULUNG_02_ALLGEMEINE_VORGABEN_BESCHLOSSEN', 'H_VORGABEN_SCHULUNG_03_KONKRETE_EINZELANWEISUNGEN_GEGEBEN', 'H_VORGABEN_SCHULUNG_04_MITARBEITENDE_GESCHULT', 'H_EIGENE_VERWALTUNG_01_EIGENE_BUCHFUEHRUNG_ODER_STEUERN_BEARBEITET', 'H_EIGENE_VERWALTUNG_02_EIGENES_PERSONAL_VERWALTET', 'H_EIGENE_VERWALTUNG_03_EIGENE_RAEUME_ODER_ARBEITSMITTEL_VERWALTET', 'H_EIGENE_VERWALTUNG_04_EIGENE_IT_BETREUT', 'H_EIGENE_VERWALTUNG_05_EIGENE_FINANZIERUNG_BEARBEITET', 'H_EIGENE_VERWALTUNG_06_EIGENE_LEISTUNGEN_ABGERECHNET', 'H_BETEILIGUNG_MUTTER_01_BETEILIGUNGSENTWICKLUNG_UEBERWACHT', 'H_BETEILIGUNG_MUTTER_02_BETEILIGUNGSERWERB_ODER_VERKAUF_VORBEREITET', 'H_BETEILIGUNG_MUTTER_03_STIMMABGABEN_ODER_GESELLSCHAFTERBESCHLUESSE_VORBER', 'H_BETEILIGUNG_MUTTER_04_AUSSCHUETTUNG_ODER_KAPITALMASSNAHME_VORBEREITET', 'H_BETEILIGUNG_MUTTER_05_UNTERLAGEN_FUER_ABSCHLUSS_ODER_KONZERNABSCHLUSS_DE', 'H_BETEILIGUNG_MUTTER_06_SITZUNGEN_ODER_BERICHTE_FUER_DIE_MUTTER_VORBEREITE')
# handlungen_unbekannt: Siehe Hinweis bei handlungen_ausgefuehrt (Flow-Pruefregel: keine Handlung in mehr als einer der drei Spalten).
Add-Field -List "Personeneinsaetze" -InternalName "weitere_aufgabe_je_bereich_text" -DisplayName 'Welche weitere Aufgabe hat die Person in diesem Bereich ausgeübt? (je Bereich)' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "zeitnachweis_unterlagenart" -DisplayName 'Welche Unterlagen können die Zeitangaben stützen?' -Type MultiChoice -Required `
    -Choices @('Z01_UNTERLAGENART_ZEITERFASSUNG', 'Z01_UNTERLAGENART_KALENDER', 'Z01_UNTERLAGENART_PROJEKT_ARBEITSUNTERLAGEN', 'Z01_UNTERLAGENART_ANDERE', 'Z01_UNTERLAGENART_KEINE')
Add-Field -List "Personeneinsaetze" -InternalName "gesamthaeufigkeit" -DisplayName 'Wie häufig hat die Person im Zusammenhang mit der KG gearbeitet?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NICHT_TAETIG', 'FREQ_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "gesamtstunden_status" -DisplayName 'Wie viele Arbeitsstunden hat die Person insgesamt im Zeitraum geleistet?' -Type Choice -Required `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "gesamtstunden" -DisplayName 'Gesamtstunden im Zeitraum' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_stunden_status" -DisplayName 'Wie viele dieser Stunden entfielen auf Arbeiten im Auftrag der KG?' -Type Choice -Required `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "kg_stunden" -DisplayName 'KG-Stunden im Zeitraum' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_stunden_offene_zuordnung" -DisplayName 'Zuordnung zum KG-Auftrag nicht sicher möglich' -Type Boolean
# kg_stunden_offene_zuordnung: Reiner Kennzeichnungs-Flag, keine dritte Antwortmoeglichkeit im Quelltext.
Add-Field -List "Personeneinsaetze" -InternalName "schaetzgrundlage" -DisplayName 'Worauf beruht die Schätzung?' -Type Choice `
    -Choices @('Z06_GRUNDLAGE_KALENDER', 'Z06_GRUNDLAGE_TYPISCHE_WOCHE', 'Z06_GRUNDLAGE_WIEDERKEHRENDE_ARBEITEN', 'Z06_GRUNDLAGE_ANDERE', 'Z06_GRUNDLAGE_KEINE_NAEHERE')
# schaetzgrundlage: Nur wenn mindestens eine Zeitangabe geschaetzt wurde.
Add-Field -List "Personeneinsaetze" -InternalName "zeitabschnitt_abweichend" -DisplayName 'Gab es Zeitabschnitte mit deutlich anderem Arbeitsumfang?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "zeitabschnitt_von" -DisplayName 'Abweichender Zeitabschnitt - Beginn' -Type DateOnly
Add-Field -List "Personeneinsaetze" -InternalName "zeitabschnitt_bis" -DisplayName 'Abweichender Zeitabschnitt - Ende' -Type DateOnly
Add-Field -List "Personeneinsaetze" -InternalName "zeitabschnitt_stunden" -DisplayName 'Abweichende Stunden in diesem Zeitabschnitt' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_buero_haeufigkeit" -DisplayName 'Wie häufig war die Person im KG-Büro tätig?' -Type Choice -Required `
    -Choices @('O03_HAEUFIGKEIT_DAILY', 'O03_HAEUFIGKEIT_MULTI_WEEK', 'O03_HAEUFIGKEIT_WEEKLY', 'O03_HAEUFIGKEIT_MONTHLY', 'O03_HAEUFIGKEIT_SELTENER', 'O03_HAEUFIGKEIT_NIE', 'O03_HAEUFIGKEIT_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "kg_buero_tage_status" -DisplayName 'Wie viele Tage arbeitete die Person im Zeitraum im KG-Büro?' -Type Choice `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
# kg_buero_tage_status: Anzeige: O03 nicht 'nie'.
Add-Field -List "Personeneinsaetze" -InternalName "kg_buero_tage" -DisplayName 'Tage im KG-Büro' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_buero_aufgaben_ref" -DisplayName 'Welche der bereits genannten Aufgaben erledigte sie im KG-Büro?' -Type LookupMulti `
    -LookupList "Aufgaben" -LookupField "display_label"
# kg_buero_aufgaben_ref: Anzeige: O03 nicht 'nie'.
Add-Field -List "Personeneinsaetze" -InternalName "kg_buero_andere_text" -DisplayName 'Andere Aufgabe im KG-Büro - bitte benennen' -Type Text
Add-Field -List "Personeneinsaetze" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Aufgabenempfaenger
# n:m-Verknuepfung Aufgabe x Empfaengergesellschaft (T04, T10, G11, G13)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Aufgabenempfaenger"
Add-Field -List "Aufgabenempfaenger" -InternalName "empfaenger_id" -DisplayName 'Empfänger-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Aufgabenempfaenger" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Aufgabenempfaenger" -InternalName "gesellschaft_ref" -DisplayName 'Für welche Gesellschaften übernimmt die Person diese Aufgabe?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Aufgabenempfaenger" -InternalName "gesellschaft_status" -DisplayName 'Status, falls keine konkrete Gesellschaft' -Type Choice `
    -Choices @('GESELLSCHAFT_STATUS_KG_SELBST', 'GESELLSCHAFT_STATUS_BETEILIGUNG', 'GESELLSCHAFT_STATUS_SCHWEIZER_MUTTER', 'GESELLSCHAFT_STATUS_ANDERE', 'GESELLSCHAFT_STATUS_KEIN_VERTRAG', 'GESELLSCHAFT_STATUS_MEHRERE', 'GESELLSCHAFT_STATUS_UNBEKANNT')
Add-Field -List "Aufgabenempfaenger" -InternalName "nutzen_art" -DisplayName 'Wem kommen diese Arbeiten unmittelbar zugute?' -Type Choice -Required `
    -Choices @('T10_EMPFAENGER_BETEILIGUNG_LAUFENDES_GESCHAEFT', 'T10_EMPFAENGER_KG_EIGENE_VERWALTUNG', 'T10_EMPFAENGER_KG_BETEILIGUNGSRECHTE', 'T10_EMPFAENGER_SCHWEIZER_MUTTER', 'T10_EMPFAENGER_ANDERE', 'T10_EMPFAENGER_MEHRERE', 'T10_EMPFAENGER_UNBEKANNT')
# nutzen_art: Mittelbarer Vorteil aus Beteiligung allein genuegt nicht (T10).
Add-Field -List "Aufgabenempfaenger" -InternalName "verwendung_text" -DisplayName 'Verwendung der Arbeitsergebnisse (bei mehreren Empfängern)' -Type Note
Add-Field -List "Aufgabenempfaenger" -InternalName "g11_rolle" -DisplayName 'Für welche Gesellschaft werden Beteiligungsrechte oder Gesellschafteraufgaben wahrgenommen?' -Type Choice `
    -Choices @('G11_ROLLE_KG_ANTEILSEIGNERIN', 'G11_ROLLE_SCHWEIZER_MUTTER_ANTEILSEIGNERIN', 'G11_ROLLE_ANDERE_GESELLSCHAFT', 'G11_ROLLE_UNBEKANNT')
# g11_rolle: Nur bei bereich_code=EIGENE_VERWALTUNG oder BETEILIGUNG_MUTTER.
Add-Field -List "Aufgabenempfaenger" -InternalName "g11_beteiligung_ref" -DisplayName 'Betroffene Beteiligung' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Aufgabenempfaenger" -InternalName "g13_zusatz_empfaenger_ref" -DisplayName 'Wer nutzt diese Arbeitsergebnisse zusätzlich?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
# g13_zusatz_empfaenger_ref: Nur bei bereich_code=BETEILIGUNG_MUTTER.
Add-Field -List "Aufgabenempfaenger" -InternalName "g13_zusatz_empfaenger_text" -DisplayName 'Nutzung kurz angeben' -Type Note
Add-Field -List "Aufgabenempfaenger" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Aufgabenzustaendigkeiten
# Priorisierung, weitere Mitwirkende, Aufteilung, Vertretung und Aenderungen je Aufgabe (T06, T11-T15, G14-G15)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Aufgabenzustaendigkeiten"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "zustaendigkeit_id" -DisplayName 'Zuständigkeits-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t06_prioritaet_ref" -DisplayName 'Wer legt die Aufgaben und Prioritäten in diesem Bereich fest?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t06_prioritaet_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('PERSON_STATUS_SELBST', 'PERSON_STATUS_BENANNTE_PERSON', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_NIEMAND', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t06_gesellschaft_ref" -DisplayName 'Zugehörige Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t11_unterschiedlich" -DisplayName 'Bestehen innerhalb dieses Aufgabenbereichs unterschiedliche Zuständigkeiten?' -Type Choice -Required `
    -Choices @('T11_ZUSTAENDIGKEIT_NEIN', 'T11_ZUSTAENDIGKEIT_JA_GESELLSCHAFT', 'T11_ZUSTAENDIGKEIT_JA_GESCHAEFT_BETRAG', 'T11_ZUSTAENDIGKEIT_JA_STANDORT', 'T11_ZUSTAENDIGKEIT_ANDERE', 'T11_ZUSTAENDIGKEIT_UNBEKANNT')
# t11_unterschiedlich: Geaenderte Bedeutung gegenueber V2.
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t12_text" -DisplayName 'Wie sind diese Zuständigkeiten verteilt?' -Type Note
# t12_text: Anzeige: T11 benennt unterschiedliche Zustaendigkeiten.
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t13_status" -DisplayName 'Wer übernimmt weitere Teile dieser Aufgabe?' -Type Choice -Required `
    -Choices @('T13_STATUS_PERSONEN', 'T13_STATUS_DIENSTLEISTER', 'T13_STATUS_NIEMAND', 'T13_STATUS_UNBEKANNT')
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t13_personen_ref" -DisplayName 'Benannte interne Personen' -Type LookupMulti `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t13_dienstleister_text" -DisplayName 'Externe Dienstleister' -Type Text
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t13_gesellschaft_ref" -DisplayName 'Gesellschaft bzw. Arbeitgeber' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t14_aufteilung_text" -DisplayName 'Wie sind die Arbeiten zwischen diesen Beteiligten verteilt?' -Type Note
# t14_aufteilung_text: Anzeige: T13 benennt weitere Beteiligte.
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t15_geaendert" -DisplayName 'Hat sich diese Aufgabenverteilung im Zeitraum geändert?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t15_zeitpunkt" -DisplayName 'Änderungszeitpunkt' -Type DateOnly
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "t15_neue_zustaendigkeit_text" -DisplayName 'Geänderte Zuständigkeit' -Type Note
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "g14_regelung" -DisplayName 'Wie ist die Zuständigkeit für diese Aufgaben organisatorisch geregelt?' -Type Choice `
    -Choices @('G14_REGELUNG_STAENDIGE_VERTEILUNG', 'G14_REGELUNG_SCHRIFTLICHER_AUFTRAG', 'G14_REGELUNG_MUENDLICHE_ABSPRACHE', 'G14_REGELUNG_WIEDERKEHRENDE_ANFORDERUNG', 'G14_REGELUNG_WECHSELNDE_ZUSTAENDIGKEIT', 'G14_REGELUNG_ANDERE', 'G14_REGELUNG_UNBEKANNT')
# g14_regelung: Nur bei bereich_code=BETEILIGUNG_MUTTER.
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "g15_vertretung" -DisplayName 'Wie werden diese Aufgaben bei Abwesenheit weitergeführt?' -Type Choice `
    -Choices @('G15_VERTRETUNG_BENANNTE_VERTRETUNG', 'G15_VERTRETUNG_VERTEILUNG_MEHRERE', 'G15_VERTRETUNG_EXTERNER_DIENSTLEISTER', 'G15_VERTRETUNG_BLEIBT_LIEGEN', 'G15_VERTRETUNG_BISHER_KEIN_FALL', 'G15_VERTRETUNG_UNBEKANNT')
# g15_vertretung: Nur bei bereich_code=BETEILIGUNG_MUTTER.
Add-Field -List "Aufgabenzustaendigkeiten" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Entscheidungsbefugnisse
# Wiederkehrende Entscheidungszustaendigkeit je Aufgabe x Entscheidungsart (D02-D10)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Entscheidungsbefugnisse"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "befugnis_id" -DisplayName 'Befugnis-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Entscheidungsbefugnisse" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
# aufgabe_ref: Anzeige: Entscheidungsaufgabe vorhanden (D01 nicht 'keine').
Add-Field -List "Entscheidungsbefugnisse" -InternalName "entscheidungsart_code" -DisplayName 'Welche Entscheidungen betrifft dies?' -Type Choice -Required `
    -Choices @('D02_ART_PREISE_KUNDENAUFTRAEGE', 'D02_ART_LIEFERANTEN_EINKAUF', 'D02_ART_PERSONAL', 'D02_ART_PERSONALEINSATZ', 'D02_ART_FINANZIERUNG', 'D02_ART_ZAHLUNGEN', 'D02_ART_BUDGETS', 'D02_ART_INVESTITIONEN', 'D02_ART_UNTERNEHMENSPLANUNG', 'D02_ART_BETEILIGUNGEN', 'D02_ART_AUSSCHUETTUNGEN', 'D02_ART_KAPITALMASSNAHMEN', 'D02_ART_ORGANBESTELLUNGEN', 'D02_ART_ANDERE')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "entscheidungsart_andere_text" -DisplayName 'Andere Entscheidungen - bitte benennen' -Type Text
Add-Field -List "Entscheidungsbefugnisse" -InternalName "gesellschaft_ref" -DisplayName 'Tatsächlich betroffene Gesellschaft' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d03_entscheider_ref" -DisplayName 'Wer trifft in diesem Bereich die inhaltlichen Entscheidungen?' -Type LookupMulti `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d03_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('D03_ENTSCHEIDER_PERSON_ALLEIN', 'D03_ENTSCHEIDER_GEMEINSAM_BENANNTE', 'D03_ENTSCHEIDER_ANDERE_PERSON', 'D03_ENTSCHEIDER_GESCHAEFTSLEITUNG', 'D03_ENTSCHEIDER_ANDERES_GREMIUM', 'D03_ENTSCHEIDER_GESELLSCHAFTER', 'D03_ENTSCHEIDER_UNTERSCHIEDLICH', 'D03_ENTSCHEIDER_UNBEKANNT')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d03_gesellschaft_ref" -DisplayName 'Gesellschaft des Entscheiders' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d03_funktion_text" -DisplayName 'Funktion des Entscheiders' -Type Text
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d04_zustimmung" -DisplayName 'Für welche Entscheidungen ist eine zusätzliche Zustimmung erforderlich?' -Type Choice -Required `
    -Choices @('D04_ZUSTIMMUNG_KEINE', 'D04_ZUSTIMMUNG_NACH_BETRAG', 'D04_ZUSTIMMUNG_AUSSERHALB_BUDGET', 'D04_ZUSTIMMUNG_NACH_ART', 'D04_ZUSTIMMUNG_GRUNDSAETZLICH', 'D04_ZUSTIMMUNG_ANDERE', 'D04_ZUSTIMMUNG_UNBEKANNT')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d05_erteiler_ref" -DisplayName 'Wer erteilt diese Zustimmung?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
# d05_erteiler_ref: Anzeige: Zustimmung erforderlich.
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d05_gesellschaft_ref" -DisplayName 'Gesellschaft des Erteilers' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d05_funktion_text" -DisplayName 'Funktion des Erteilers' -Type Text
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d06_bearbeitung" -DisplayName 'Wie werden Entscheidungsvorschläge vor der Freigabe tatsächlich bearbeitet?' -Type MultiChoice `
    -Choices @('D06_BEARBEITUNG_INHALTLICH_GEPRUEFT', 'D06_BEARBEITUNG_MIT_VERANTWORTLICHEN_BESPROCHEN', 'D06_BEARBEITUNG_ZUR_ERGAENZUNG_ZURUECK', 'D06_BEARBEITUNG_INHALTLICH_GEAENDERT', 'D06_BEARBEITUNG_GELEGENTLICH_ABGELEHNT', 'D06_BEARBEITUNG_OHNE_BEARBEITUNG_BESTAETIGT', 'D06_BEARBEITUNG_UNTERSCHIEDLICH', 'D06_BEARBEITUNG_UNBEKANNT')
# d06_bearbeitung: Anzeige: Zustimmung erforderlich.
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d07_pruefpunkte" -DisplayName 'Welche Punkte werden dabei geprüft oder abgestimmt?' -Type MultiChoice `
    -Choices @('D07_PRUEFPUNKTE_WIRTSCHAFTLICHE_BEDINGUNGEN', 'D07_PRUEFPUNKTE_FINANZIERUNG_LIQUIDITAET', 'D07_PRUEFPUNKTE_PERSONAL', 'D07_PRUEFPUNKTE_BUDGET', 'D07_PRUEFPUNKTE_RECHTLICH_STEUERLICH', 'D07_PRUEFPUNKTE_UMSETZUNG', 'D07_PRUEFPUNKTE_ANDERE', 'D07_PRUEFPUNKTE_UNBEKANNT')
# d07_pruefpunkte: Anzeige: Pruefung oder Abstimmung vorhanden (D06 nicht 'ohne Bearbeitung').
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d08_grenzen" -DisplayName 'Welche Grenzen gelten für die eigenen Entscheidungsbefugnisse?' -Type Choice -Required `
    -Choices @('D08_GRENZEN_KEINE', 'D08_GRENZEN_BETRAG', 'D08_GRENZEN_BUDGET', 'D08_GRENZEN_THEMENBEREICH', 'D08_GRENZEN_ZUSTIMMUNGSVORBEHALT', 'D08_GRENZEN_ANDERE', 'D08_GRENZEN_UNBEKANNT')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d08_betrag" -DisplayName 'Betragsgrenze' -Type Number
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d08_waehrung" -DisplayName 'Währung der Betragsgrenze' -Type Text
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d08_regelung_ref" -DisplayName 'Schriftliche Regelung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d09_umsetzung" -DisplayName 'Wer verantwortet die Umsetzung der Entscheidungen?' -Type Choice -Required `
    -Choices @('D09_UMSETZUNG_PERSON_SELBST', 'D09_UMSETZUNG_BENANNTE_MITARBEITENDE', 'D09_UMSETZUNG_GESCHAEFTSLEITUNG', 'D09_UMSETZUNG_EXTERNER_DIENSTLEISTER', 'D09_UMSETZUNG_UNTERSCHIEDLICH', 'D09_UMSETZUNG_UNBEKANNT')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d10_gesellschafter_vorgelegt" -DisplayName 'Welche Entscheidungen werden tatsächlich den Gesellschaftern vorgelegt?' -Type MultiChoice -Required `
    -Choices @('D10_ART_BETEILIGUNGSERWERB_VERKAUF', 'D10_ART_AUSSCHUETTUNG', 'D10_ART_KAPITALMASSNAHME', 'D10_ART_ORGANBESTELLUNG', 'D10_ART_BUDGET_INVESTITION', 'D10_ART_ANDERE', 'D10_ART_KEINE', 'D10_ART_UNBEKANNT')
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d10_gesellschaft_ref" -DisplayName 'Gesellschaft, deren Gesellschafter entscheiden' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "d10_vertreter_ref" -DisplayName 'Handelnder Vertreter' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Entscheidungsbefugnisse" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Vertragszustaendigkeiten
# Wiederkehrende Vertragszustaendigkeit je Aufgabe x Vertragsart (V10-V18)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Vertragszustaendigkeiten"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "zustaendigkeit_id" -DisplayName 'Zuständigkeits-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Vertragszustaendigkeiten" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "vertragsart_code" -DisplayName 'Bei welchen Verträgen übernimmt die Person Aufgaben?' -Type Choice -Required `
    -Choices @('V10_ART_KUNDENVERTRAEGE', 'V10_ART_LIEFERANTENVERTRAEGE', 'V10_ART_PERSONALVERTRAEGE', 'V10_ART_KREDITE_SICHERHEITEN', 'V10_ART_MIETE_LEASING', 'V10_ART_BERATERVERTRAEGE', 'V10_ART_ANDERE', 'V10_ART_KEINE', 'V10_ART_UNBEKANNT')
# vertragsart_code: Je ausgewaehlter Art (ausser 'keine') ein eigener Datensatz.
Add-Field -List "Vertragszustaendigkeiten" -InternalName "vertragspartei_ref" -DisplayName 'Für welche Gesellschaft übernimmt sie diese Vertragsaufgaben?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "vertragspartei_text" -DisplayName 'Vertragspartei ausdrücklich benennen' -Type Text
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v12_gespraechspartner" -DisplayName 'Mit welchen Geschäftspartnern oder Ansprechpartnern führt sie die Gespräche?' -Type MultiChoice -Required `
    -Choices @('V12_GESPRAECHSPARTNER_KUNDEN', 'V12_GESPRAECHSPARTNER_LIEFERANTEN', 'V12_GESPRAECHSPARTNER_BEWERBER_MITARBEITENDE', 'V12_GESPRAECHSPARTNER_BANKEN_FINANZIERER', 'V12_GESPRAECHSPARTNER_VERMIETER_LEASINGGEBER', 'V12_GESPRAECHSPARTNER_STEUERBERATER_ANDERE', 'V12_GESPRAECHSPARTNER_ANDERE')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v13_teile" -DisplayName 'Welche Teile der Verhandlung übernimmt sie selbst?' -Type MultiChoice -Required `
    -Choices @('V13_TEILE_KONTAKT_BEDARFSKLAERUNG', 'V13_TEILE_AUSWAHL_VERTRAGSPARTNER', 'V13_TEILE_PREIS_VERGUETUNG', 'V13_TEILE_LEISTUNG_MENGE', 'V13_TEILE_TERMINE_LAUFZEIT', 'V13_TEILE_HAFTUNG_SICHERHEITEN', 'V13_TEILE_KUENDIGUNGSBEDINGUNGEN', 'V13_TEILE_ABSTIMMUNG_UNTERSCHRIFTSREIF', 'V13_TEILE_ANDERE')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v14_abschlussreife" -DisplayName 'Bis zu welchem Stand führt sie die Verhandlungen üblicherweise?' -Type Choice -Required `
    -Choices @('V14_ABSCHLUSSREIFE_NUR_GRUNDLAGEN', 'V14_ABSCHLUSSREIFE_ANGEBOT', 'V14_ABSCHLUSSREIFE_EINZELNE_BEDINGUNGEN', 'V14_ABSCHLUSSREIFE_WESENTLICHE_BEDINGUNGEN', 'V14_ABSCHLUSSREIFE_BIS_AUF_FREIGABE', 'V14_ABSCHLUSSREIFE_SCHLIESST_SELBST_AB', 'V14_ABSCHLUSSREIFE_UNTERSCHIEDLICH', 'V14_ABSCHLUSSREIFE_UNBEKANNT')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v15_bearbeitung" -DisplayName 'Welche Bearbeitung erfolgt danach durch andere Personen?' -Type MultiChoice -Required `
    -Choices @('V15_BEARBEITUNG_WEITERE_WIRTSCHAFTLICHE_VERHANDLUNG', 'V15_BEARBEITUNG_RECHTLICHE_DETAILPRUEFUNG', 'V15_BEARBEITUNG_INHALTLICHE_FREIGABE', 'V15_BEARBEITUNG_REGELMAESSIG_WESENTLICHE_AENDERUNGEN', 'V15_BEARBEITUNG_NUR_UNTERZEICHNUNG', 'V15_BEARBEITUNG_KEINE_WEITERE_BEARBEITUNG', 'V15_BEARBEITUNG_UNTERSCHIEDLICH', 'V15_BEARBEITUNG_UNBEKANNT')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v15_zustaendige_ref" -DisplayName 'Zuständige Personen' -Type LookupMulti `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v15_gesellschaft_ref" -DisplayName 'Zugehörige Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v16_zeichnung" -DisplayName 'Wer erklärt die verbindliche Zusage oder unterzeichnet üblicherweise?' -Type Choice -Required `
    -Choices @('V16_ZEICHNUNG_PERSON_SELBST', 'V16_ZEICHNUNG_ANDERE_PERSON', 'V16_ZEICHNUNG_GEMEINSAME_ZEICHNUNG', 'V16_ZEICHNUNG_JE_VERTRAGSART', 'V16_ZEICHNUNG_UNBEKANNT')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v16_person_ref" -DisplayName 'Zeichnungsberechtigte Person(en)' -Type LookupMulti `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v17_unterlagenart" -DisplayName 'Welche Verträge oder Unterlagen darf die Person verbindlich bestätigen oder unterzeichnen?' -Type MultiChoice -Required `
    -Choices @('V17_UNTERLAGENART_ANGEBOTE', 'V17_UNTERLAGENART_AUFTRAGSBESTAETIGUNGEN', 'V17_UNTERLAGENART_KUNDENVERTRAEGE', 'V17_UNTERLAGENART_BESTELLUNGEN_LIEFERANTENVERTRAEGE', 'V17_UNTERLAGENART_PERSONALVERTRAEGE', 'V17_UNTERLAGENART_FINANZIERUNGSVERTRAEGE', 'V17_UNTERLAGENART_ZAHLUNGSFREIGABEN', 'V17_UNTERLAGENART_BERATERAUFTRAEGE', 'V17_UNTERLAGENART_ANDERE', 'V17_UNTERLAGENART_KEINE', 'V17_UNTERLAGENART_UNBEKANNT')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v17_grenzen_text" -DisplayName 'Einzel- oder gemeinsame Zeichnung und Grenzen' -Type Note
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v17_nachweis_ref" -DisplayName 'Vollmacht/Kompetenzordnung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Vertragszustaendigkeiten" -InternalName "v18_haeufigkeit" -DisplayName 'Wie häufig führt sie solche Verhandlungen?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NICHT_TAETIG', 'FREQ_UNBEKANNT')
Add-Field -List "Vertragszustaendigkeiten" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Kontrollaufgaben
# Aufsichts-/Instruktions-/Schulungsaufgabe je Aufgabe (K10-K14)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Kontrollaufgaben"
Add-Field -List "Kontrollaufgaben" -InternalName "kontrollaufgabe_id" -DisplayName 'Kontrollaufgabe-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Kontrollaufgaben" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Kontrollaufgaben" -InternalName "k10_gegenstand" -DisplayName 'Welche Bereiche überwacht oder kontrolliert die Person?' -Type MultiChoice -Required `
    -Choices @('K10_GEGENSTAND_ERGEBNIS', 'K10_GEGENSTAND_BUDGET', 'K10_GEGENSTAND_LIQUIDITAET', 'K10_GEGENSTAND_PROJEKTE', 'K10_GEGENSTAND_PERSONAL', 'K10_GEGENSTAND_EINHALTUNG_VORGABEN', 'K10_GEGENSTAND_TAETIGKEIT_GESCHAEFTSLEITUNG', 'K10_GEGENSTAND_BETEILIGUNGSENTWICKLUNG', 'K10_GEGENSTAND_ANDERE', 'K10_GEGENSTAND_KEINE', 'K10_GEGENSTAND_UNBEKANNT')
Add-Field -List "Kontrollaufgaben" -InternalName "k11_befugnisse" -DisplayName 'Welche Befugnisse übt sie bei Abweichungen tatsächlich aus?' -Type MultiChoice -Required `
    -Choices @('K11_BEFUGNISSE_ERLAEUTERUNGEN_VERLANGEN', 'K11_BEFUGNISSE_EMPFEHLUNGEN_GEBEN', 'K11_BEFUGNISSE_ALLGEMEINE_VORGABEN_ANPASSEN', 'K11_BEFUGNISSE_MASSNAHMEN_ANORDNEN', 'K11_BEFUGNISSE_SELBST_EINGREIFEN', 'K11_BEFUGNISSE_UMSETZUNG_NACHHALTEN', 'K11_BEFUGNISSE_NUR_BERICHTEN', 'K11_BEFUGNISSE_ANDERE', 'K11_BEFUGNISSE_UNBEKANNT')
# k11_befugnisse: Anzeige: Kontrollaufgaben vorhanden.
Add-Field -List "Kontrollaufgaben" -InternalName "k12_art" -DisplayName 'Welche Art von Vorgaben, Beratung oder Schulung übernimmt sie?' -Type MultiChoice -Required `
    -Choices @('K12_ART_ALLGEMEINE_RICHTLINIEN', 'K12_ART_FACHWISSEN_METHODEN', 'K12_ART_SOFTWAREANWENDUNG', 'K12_ART_ALLGEMEINE_ARBEITSABLAEUFE', 'K12_ART_KONKRETE_ANWEISUNGEN', 'K12_ART_ANDERE', 'K12_ART_KEINE', 'K12_ART_UNBEKANNT')
Add-Field -List "Kontrollaufgaben" -InternalName "k13_adressaten" -DisplayName 'An welche Personen oder Bereiche richten sich diese Leistungen?' -Type MultiChoice `
    -Choices @('K13_ADRESSATEN_GESCHAEFTSLEITUNG', 'K13_ADRESSATEN_FACHABTEILUNGEN', 'K13_ADRESSATEN_EINZELNE_MITARBEITENDE', 'K13_ADRESSATEN_DIENSTLEISTER', 'K13_ADRESSATEN_ANDERE')
# k13_adressaten: Anzeige: Vorgaben, Beratung oder Schulung vorhanden.
Add-Field -List "Kontrollaufgaben" -InternalName "k13_gesellschaft_ref" -DisplayName 'Zugehörige Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kontrollaufgaben" -InternalName "k14_festleger_ref" -DisplayName 'Wer legt deren Inhalt fest?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
# k14_festleger_ref: Anzeige: Vorgaben, Beratung oder Schulung vorhanden.
Add-Field -List "Kontrollaufgaben" -InternalName "k14_status" -DisplayName 'Status' -Type Choice `
    -Choices @('K14_FESTLEGUNG_PERSON_SELBST', 'K14_FESTLEGUNG_GESCHAEFTSLEITUNG', 'K14_FESTLEGUNG_SCHWEIZER_MUTTER', 'K14_FESTLEGUNG_ANDERE', 'K14_FESTLEGUNG_GEMEINSAM', 'K14_FESTLEGUNG_UNBEKANNT')
Add-Field -List "Kontrollaufgaben" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Steuerungsbeziehungen
# Gesteuerte Mitarbeitende/Dienstleister je Aufgabe (K15-K17)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Steuerungsbeziehungen"
Add-Field -List "Steuerungsbeziehungen" -InternalName "beziehung_id" -DisplayName 'Beziehungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Steuerungsbeziehungen" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Steuerungsbeziehungen" -InternalName "gesteuerte_person_ref" -DisplayName 'Welche Mitarbeitenden oder Dienstleister steuert die Person im Tagesgeschäft?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Steuerungsbeziehungen" -InternalName "dienstleister_text" -DisplayName 'Dienstleister (falls kein Personen-Datensatz)' -Type Text
Add-Field -List "Steuerungsbeziehungen" -InternalName "status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('T13_STATUS_PERSONEN', 'T13_STATUS_DIENSTLEISTER', 'T13_STATUS_NIEMAND', 'T13_STATUS_UNBEKANNT')
Add-Field -List "Steuerungsbeziehungen" -InternalName "k16_gesellschaft_ref" -DisplayName 'Für welche Gesellschaft arbeiten diese Mitarbeitenden oder Dienstleister?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Steuerungsbeziehungen" -InternalName "k17_festlegung" -DisplayName 'Was legt die Person für diese Mitarbeitenden oder Dienstleister tatsächlich fest?' -Type MultiChoice `
    -Choices @('K17_FESTLEGUNG_AUFGABEN', 'K17_FESTLEGUNG_PRIORITAETEN', 'K17_FESTLEGUNG_TERMINE', 'K17_FESTLEGUNG_VORGEHENSWEISE', 'K17_FESTLEGUNG_ERWARTETE_ERGEBNISSE', 'K17_FESTLEGUNG_ABNAHME', 'K17_FESTLEGUNG_ANDERE', 'K17_FESTLEGUNG_KEINE', 'K17_FESTLEGUNG_UNBEKANNT')
# k17_festlegung: Anzeige: gesteuerte Personen/Dienstleister vorhanden.
Add-Field -List "Steuerungsbeziehungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Zeitverteilungen
# n:m-Verknuepfung Aufgabe x Empfaengergesellschaft, Stunden (Z08); keine Summenkorrektur auf 100% (B4)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Zeitverteilungen"
Add-Field -List "Zeitverteilungen" -InternalName "verteilung_id" -DisplayName 'Verteilungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Zeitverteilungen" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup -Required `
    -LookupList "Aufgaben" -LookupField "display_label"
# aufgabe_ref: Nur bei Aufgaben mit mehreren Empfaengern oder offenen Stunden (B3); sonst Uebernahme der eindeutigen Zuordnung ohne Rueckfrage.
Add-Field -List "Zeitverteilungen" -InternalName "empfaenger_ref" -DisplayName 'Empfänger-Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Zeitverteilungen" -InternalName "status" -DisplayName 'Status der Verteilung' -Type Choice -Required `
    -Choices @('Z08_STATUS_AUS_UNTERLAGEN', 'Z08_STATUS_GESCHAETZT', 'Z08_STATUS_NUR_ANTEILE', 'Z08_STATUS_UNBEKANNT', 'Z08_STATUS_REST_NICHT_ZUGEORDNET')
# status: REST_NICHT_ZUGEORDNET bildet die ausdruecklich offene Restzeit ab (B4) - keine Summenkorrektur auf 100%.
Add-Field -List "Zeitverteilungen" -InternalName "stunden" -DisplayName 'Stunden je Empfänger' -Type Number
Add-Field -List "Zeitverteilungen" -InternalName "anteil_geschaetzt_prozent" -DisplayName 'Geschätzter Anteil (falls keine Stunden verfügbar)' -Type Number `
    -Min 0 `
    -Max 100
Add-Field -List "Zeitverteilungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Aufgabenorte
# Arbeitsorte je Aufgabe (O01-O02, O05-O08) sowie Orte der Vorbereitung/Verhandlung/Entscheidung/Freigabe (O06, polymorph zu D/V/K)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Aufgabenorte"
Add-Field -List "Aufgabenorte" -InternalName "ort_eintrag_id" -DisplayName 'Orts-Eintrag-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Aufgabenorte" -InternalName "bezugsart" -DisplayName 'Bezugsart des Ortseintrags' -Type Choice -Required `
    -Choices @('AUFGABENORT_BEZUGSART_ARBEITSZEIT_ORT', 'AUFGABENORT_BEZUGSART_FUNKTIONSORT')
# bezugsart: PFLICHT-Spalte (Entscheidung Nils). ARBEITSZEIT_ORT = O01/O02 (traegt Stunden/Anteile); FUNKTIONSORT = O06 (traegt KEINE Stunden/Anteile, geaenderte Bedeutung ggue. V2, dort Fallbeteiligungen.schritt).
Add-Field -List "Aufgabenorte" -InternalName "funktion" -DisplayName 'Funktion (nur bei Funktionsort)' -Type Choice `
    -Choices @('AUFGABENORT_FUNKTION_VORBEREITUNG', 'AUFGABENORT_FUNKTION_VERHANDLUNG', 'AUFGABENORT_FUNKTION_ENTSCHEIDUNG', 'AUFGABENORT_FUNKTION_FREIGABE')
# funktion: Nur bei bezugsart=FUNKTIONSORT auszufuellen/anzuzeigen.
Add-Field -List "Aufgabenorte" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe (bei Bezugsart=Arbeitszeit-Ort)' -Type Lookup `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "entscheidung_ref" -DisplayName 'Bezug: Entscheidungsbefugnis (bei Bezugsart=Funktionsort, Funktion Vorbereitung/Entscheidung/Freigabe)' -Type Lookup `
    -LookupList "Entscheidungsbefugnisse" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "vertrag_ref" -DisplayName 'Bezug: Vertragszuständigkeit (bei Bezugsart=Funktionsort, Funktion Vorbereitung/Verhandlung/Freigabe)' -Type Lookup `
    -LookupList "Vertragszustaendigkeiten" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "kontrolle_ref" -DisplayName 'Bezug: Kontrollaufgabe (bei Bezugsart=Funktionsort)' -Type Lookup `
    -LookupList "Kontrollaufgaben" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "person_ref" -DisplayName 'Beteiligte Person an diesem Ort' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "ort_ref" -DisplayName 'An welchen Orten führte die Person die erfassten Aufgaben aus?' -Type Lookup -Required `
    -LookupList "Orte" -LookupField "display_label"
# ort_ref: Bei Telefon-/Videobesprechungen zaehlt der Aufenthaltsort der Person (O06).
Add-Field -List "Aufgabenorte" -InternalName "o02_status" -DisplayName 'Wie viel Arbeitszeit entfiel auf den jeweiligen Ort?' -Type Choice `
    -Choices @('O02_STATUS_STUNDEN_VERFUEGBAR', 'O02_STATUS_GESCHAETZTE_STUNDEN', 'O02_STATUS_NUR_PROZENTANTEIL', 'O02_STATUS_UNBEKANNT')
# o02_status: Nur bei bezugsart=ARBEITSZEIT_ORT; bei FUNKTIONSORT leer lassen (Doppelzaehlungs-Validierung).
Add-Field -List "Aufgabenorte" -InternalName "o02_stunden" -DisplayName 'Stunden am jeweiligen Ort' -Type Number
# o02_stunden: Nur bei bezugsart=ARBEITSZEIT_ORT; bei FUNKTIONSORT leer lassen.
Add-Field -List "Aufgabenorte" -InternalName "o02_prozent" -DisplayName 'Prozentanteil am jeweiligen Ort' -Type Number `
    -Min 0 `
    -Max 100
# o02_prozent: Alternative zu Stunden, keine zusaetzliche Schaetzpflicht (O02). Nur bei bezugsart=ARBEITSZEIT_ORT; bei FUNKTIONSORT leer lassen.
Add-Field -List "Aufgabenorte" -InternalName "o07_grund" -DisplayName 'Warum wurde für diese Arbeit das Homeoffice genutzt?' -Type MultiChoice `
    -Choices @('O07_GRUND_PERSOENLICHER_WUNSCH', 'O07_GRUND_VORGABE_UNTERNEHMEN', 'O07_GRUND_KEIN_ANDERER_ARBEITSPLATZ', 'O07_GRUND_NAEHE_KUNDEN', 'O07_GRUND_ANDERER_GRUND', 'O07_GRUND_UNBEKANNT')
# o07_grund: Anzeige: Homeoffice in O01 vorhanden.
Add-Field -List "Aufgabenorte" -InternalName "o08_alternativer_arbeitsplatz" -DisplayName 'Stand für diese Arbeit ein anderer Arbeitsplatz zur Verfügung?' -Type Choice `
    -Choices @('JA_NEIN_TEILWEISE_UNBEKANNT_JA', 'JA_NEIN_TEILWEISE_UNBEKANNT_NEIN', 'JA_NEIN_TEILWEISE_UNBEKANNT_TEILWEISE', 'JA_NEIN_TEILWEISE_UNBEKANNT_UNBEKANNT')
# o08_alternativer_arbeitsplatz: Anzeige: Homeoffice in O01 vorhanden.
Add-Field -List "Aufgabenorte" -InternalName "o08_alternativ_ort_ref" -DisplayName 'Alternativer Standort' -Type Lookup `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Aufgabenorte" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Raeume
# Geschaeftsraeume und tatsaechliche Verfuegungsmoeglichkeiten (R21-R28)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Raeume"
Add-Field -List "Raeume" -InternalName "raum_id" -DisplayName 'Raum-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Raeume" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Raeume" -InternalName "ort_ref" -DisplayName 'Welcher Raum oder Arbeitsbereich wird genutzt?' -Type Lookup -Required `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "raumart" -DisplayName 'Raumart' -Type Choice -Required `
    -Choices @('RAUM_ART_EIGENES_BUERO', 'RAUM_ART_EIGENER_RAUM_BETEILIGUNG', 'RAUM_ART_GEMEINSAMER_RAUM', 'RAUM_ART_WECHSELNDER_ARBEITSPLATZ', 'RAUM_ART_BESPRECHUNGSRAUM', 'RAUM_ART_HOMEOFFICE', 'RAUM_ART_ARCHIV', 'RAUM_ART_ANDERER_BEREICH')
Add-Field -List "Raeume" -InternalName "eigentuemer_ref" -DisplayName 'Wem gehört der Raum?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Raeume" -InternalName "eigentuemer_person_ref" -DisplayName 'Eigentümer (Person)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "r22_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('R22_24_STATUS_GESELLSCHAFT', 'R22_24_STATUS_PERSON', 'R22_24_STATUS_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "mieter_ref" -DisplayName 'Wer ist Mieter des Raums?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Raeume" -InternalName "r23_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('R23_STATUS_GESELLSCHAFT', 'R23_STATUS_PERSON', 'R23_STATUS_KEIN_MIETVERHAELTNIS', 'R23_STATUS_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r24_bereitsteller" -DisplayName 'Wer stellt den Raum der KG zur Verfügung?' -Type Choice -Required `
    -Choices @('R24_BEREITSTELLER_EIGENTUEMER', 'R24_BEREITSTELLER_MIETER', 'R24_BEREITSTELLER_ANDERER', 'R24_BEREITSTELLER_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r24_name_text" -DisplayName 'Name bzw. Gesellschaft des Bereitstellers' -Type Text
Add-Field -List "Raeume" -InternalName "r25_vereinbarung" -DisplayName 'Auf welcher Vereinbarung beruht die Nutzung?' -Type Choice -Required `
    -Choices @('R25_VEREINBARUNG_MIETVERTRAG', 'R25_VEREINBARUNG_UNTERMIETVERTRAG', 'R25_VEREINBARUNG_ANDERE_SCHRIFTLICHE', 'R25_VEREINBARUNG_MUENDLICH', 'R25_VEREINBARUNG_KEINE_BEKANNT', 'R25_VEREINBARUNG_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r25_beginn" -DisplayName 'Beginn der Nutzung' -Type DateOnly
Add-Field -List "Raeume" -InternalName "r25_ende" -DisplayName 'Ende der Nutzung' -Type DateOnly
Add-Field -List "Raeume" -InternalName "r26_eigener_zugang" -DisplayName 'Eigener Schlüssel oder Zugang?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
# r26_eigener_zugang: R26: je eine Einzelfrage, nicht als MultiChoice.
Add-Field -List "Raeume" -InternalName "r26_zugang_ohne_anmeldung" -DisplayName 'Zugang ohne Voranmeldung?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r26_fest_zugewiesen" -DisplayName 'Fest zugewiesene Arbeitsplätze?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r26_eigene_ablage" -DisplayName 'Eigene Ablage?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r26_abschliessbare_aufbewahrung" -DisplayName 'Abschliessbare Aufbewahrung?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r26_nur_nach_buchung" -DisplayName 'Raum nur nach Buchung verfügbar?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r27_flaeche_status" -DisplayName 'Welche Fläche wird genutzt?' -Type Choice -Required `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r27_flaeche_qm" -DisplayName 'Fläche in m²' -Type Number `
    -Min 0
Add-Field -List "Raeume" -InternalName "r27_gemeinsam_genutzt" -DisplayName 'Gemeinsam genutzte Fläche' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r28_status" -DisplayName 'Wie viele Arbeitsplätze stehen dort zur Verfügung?' -Type Choice -Required `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
Add-Field -List "Raeume" -InternalName "r28_anzahl_arbeitsplaetze" -DisplayName 'Anzahl Arbeitsplätze' -Type Number `
    -Min 0
Add-Field -List "Raeume" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Arbeitsmittel
# Arbeitsmittel, Fahrzeuge, IT und Software - Eigentum/Bereitstellung/Lizenzen (A20-A23, A26-A31)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Arbeitsmittel"
Add-Field -List "Arbeitsmittel" -InternalName "mittel_id" -DisplayName 'Mittel-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Arbeitsmittel" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Arbeitsmittel" -InternalName "art_code" -DisplayName 'Welches Arbeitsmittel wird genutzt?' -Type Choice -Required `
    -Choices @('A20_ART_FAHRZEUG', 'A20_ART_BUEROAUSSTATTUNG', 'A20_ART_COMPUTER', 'A20_ART_SMARTPHONE_TABLET', 'A20_ART_TELEFON_INTERNET', 'A20_ART_DRUCKER', 'A20_ART_SERVER_CLOUD', 'A20_ART_SOFTWARE_DATENBANK', 'A20_ART_ANDERES')
Add-Field -List "Arbeitsmittel" -InternalName "bezeichnung_text" -DisplayName 'Bezeichnung' -Type Text -Required
Add-Field -List "Arbeitsmittel" -InternalName "eigentuemer_ref" -DisplayName 'Wem gehört das Arbeitsmittel?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
# eigentuemer_ref: Bei Software stattdessen Lizenznehmer unter A26.
Add-Field -List "Arbeitsmittel" -InternalName "eigentuemer_person_ref" -DisplayName 'Eigentümer (Person)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Arbeitsmittel" -InternalName "a21_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('A21_22_STATUS_GESELLSCHAFT', 'A21_22_STATUS_PERSON', 'A21_22_STATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a22_bereitsteller_ref" -DisplayName 'Wer stellt es zur Verfügung?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "a22_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('A21_22_STATUS_GESELLSCHAFT', 'A21_22_STATUS_PERSON', 'A21_22_STATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a23_grundlage" -DisplayName 'Auf welcher Grundlage wird es genutzt?' -Type Choice -Required `
    -Choices @('A23_GRUNDLAGE_GEKAUFT', 'A23_GRUNDLAGE_GEMIETET', 'A23_GRUNDLAGE_GELEAST', 'A23_GRUNDLAGE_PRIVAT_BEREITGESTELLT', 'A23_GRUNDLAGE_ANDERE', 'A23_GRUNDLAGE_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a23_beginn" -DisplayName 'Nutzungsbeginn' -Type DateOnly
Add-Field -List "Arbeitsmittel" -InternalName "a23_ende" -DisplayName 'Nutzungsende' -Type DateOnly
Add-Field -List "Arbeitsmittel" -InternalName "a26_lizenznehmer_ref" -DisplayName 'Wer ist Lizenz- oder Abonnementnehmer?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
# a26_lizenznehmer_ref: Anzeige: Software oder Datenbank.
Add-Field -List "Arbeitsmittel" -InternalName "a26_status" -DisplayName 'Status' -Type Choice `
    -Choices @('A21_22_STATUS_GESELLSCHAFT', 'A21_22_STATUS_PERSON', 'A21_22_STATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a27_status" -DisplayName 'Wie viele Lizenzen stehen zur Verfügung?' -Type Choice `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
# a27_status: Anzeige: Software oder Datenbank.
Add-Field -List "Arbeitsmittel" -InternalName "a27_lizenzen_verfuegbar" -DisplayName 'Anzahl verfügbare Lizenzen' -Type Number `
    -Min 0
Add-Field -List "Arbeitsmittel" -InternalName "a28_status" -DisplayName 'Wie viele Lizenzen werden tatsächlich genutzt?' -Type Choice `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
# a28_status: Anzeige: Software oder Datenbank.
Add-Field -List "Arbeitsmittel" -InternalName "a28_lizenzen_genutzt" -DisplayName 'Anzahl tatsächlich genutzte Lizenzen' -Type Number `
    -Min 0
Add-Field -List "Arbeitsmittel" -InternalName "a28_beschraenkungen_text" -DisplayName 'Bekannte Nutzungsbeschränkungen' -Type Note
Add-Field -List "Arbeitsmittel" -InternalName "a29_vertrag_ref" -DisplayName 'Auf wen läuft der Mobilfunk- oder IT-Vertrag?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
# a29_vertrag_ref: Anzeige: Smartphone, Telefon oder IT-Vertrag.
Add-Field -List "Arbeitsmittel" -InternalName "a29_status" -DisplayName 'Status' -Type Choice `
    -Choices @('A21_22_STATUS_GESELLSCHAFT', 'A21_22_STATUS_PERSON', 'A21_22_STATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a30_verwalter_ref" -DisplayName 'Wer verwaltet das Gerät oder Benutzerkonto?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
# a30_verwalter_ref: Anzeige: IT oder Smartphone. Keine Passwoerter erfassen.
Add-Field -List "Arbeitsmittel" -InternalName "a30_status" -DisplayName 'Status' -Type Choice `
    -Choices @('A30_VERWALTUNG_INTERNE_PERSON', 'A30_VERWALTUNG_DIENSTLEISTER', 'A30_VERWALTUNG_NIEMAND_GESONDERT', 'A30_VERWALTUNG_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "a31_halter_ref" -DisplayName 'Wer ist Fahrzeughalter?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
# a31_halter_ref: Anzeige: Fahrzeug.
Add-Field -List "Arbeitsmittel" -InternalName "a31_status" -DisplayName 'Status' -Type Choice `
    -Choices @('A21_22_STATUS_GESELLSCHAFT', 'A21_22_STATUS_PERSON', 'A21_22_STATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Ressourcennutzungen
# n:m-Verknuepfung Raum/Mittel x Person x Aufgabe x Nutzungsumfang (R29, A24-A25, A32)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Ressourcennutzungen"
Add-Field -List "Ressourcennutzungen" -InternalName "nutzung_id" -DisplayName 'Nutzungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Ressourcennutzungen" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Ressourcennutzungen" -InternalName "bezug_typ" -DisplayName 'Bezugstyp' -Type Choice -Required `
    -Choices @('RESSOURCE_BEZUGSTYP_RAUM', 'RESSOURCE_BEZUGSTYP_MITTEL')
Add-Field -List "Ressourcennutzungen" -InternalName "raum_ref" -DisplayName 'Bezug: Raum' -Type Lookup `
    -LookupList "Raeume" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "mittel_ref" -DisplayName 'Bezug: Arbeitsmittel' -Type Lookup `
    -LookupList "Arbeitsmittel" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "person_ref" -DisplayName 'Wer nutzt den Raum/das Arbeitsmittel tatsächlich?' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "gesellschaft_ref" -DisplayName 'Für welche Gesellschaft?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Ressourcennutzungen" -InternalName "aufgabe_ref" -DisplayName 'Für welche Aufgabe, soweit zuordenbar' -Type Lookup `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "a25_einheit" -DisplayName 'Wie verteilt sich die tatsächliche Nutzung?' -Type Choice -Required `
    -Choices @('A25_EINHEIT_STUNDEN', 'A25_EINHEIT_KILOMETER', 'A25_EINHEIT_ANDERE_EINHEIT', 'A25_EINHEIT_GESCHAETZTE_ANTEILE', 'A25_EINHEIT_NICHT_AUFTEILBAR', 'A25_EINHEIT_DERZEIT_UNGENUTZT')
Add-Field -List "Ressourcennutzungen" -InternalName "a25_menge" -DisplayName 'Menge in der gewählten Einheit' -Type Number
Add-Field -List "Ressourcennutzungen" -InternalName "a25_privatanteil_prozent" -DisplayName 'Privatanteil in Prozent' -Type Number `
    -Min 0 `
    -Max 100
Add-Field -List "Ressourcennutzungen" -InternalName "bezugszeitraum_von" -DisplayName 'Bezugszeitraum - Beginn' -Type DateOnly
Add-Field -List "Ressourcennutzungen" -InternalName "bezugszeitraum_bis" -DisplayName 'Bezugszeitraum - Ende' -Type DateOnly
Add-Field -List "Ressourcennutzungen" -InternalName "a32_fahrtzweck" -DisplayName 'Für welche Fahrten wurde das Fahrzeug eingesetzt?' -Type MultiChoice `
    -Choices @('A32_FAHRTZWECK_KUNDEN_LIEFERANTEN', 'A32_FAHRTZWECK_BETEILIGUNGSBESUCHE', 'A32_FAHRTZWECK_BANK_BERATER', 'A32_FAHRTZWECK_KG_BUERO', 'A32_FAHRTZWECK_ANDERE_BERUFLICHE', 'A32_FAHRTZWECK_PRIVAT')
# a32_fahrtzweck: Anzeige: Fahrzeug (A20).
Add-Field -List "Ressourcennutzungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Kosten
# Kostenposition mit Bezug zu Person/Raum/Mittel/Aufgabe (C20-C24)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Kosten"
Add-Field -List "Kosten" -InternalName "kosten_id" -DisplayName 'Kosten-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Kosten" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Kosten" -InternalName "kostenart" -DisplayName 'Welche Kostenposition wird beschrieben?' -Type Choice -Required `
    -Choices @('C20_KOSTENART_VERGUETUNG', 'C20_KOSTENART_ARBEITGEBERBEITRAEGE', 'C20_KOSTENART_SPESEN', 'C20_KOSTENART_RAUMKOSTEN', 'C20_KOSTENART_FAHRZEUG', 'C20_KOSTENART_IT_TELEFON', 'C20_KOSTENART_SOFTWARE', 'C20_KOSTENART_REISE', 'C20_KOSTENART_BERATUNG', 'C20_KOSTENART_BUCHFUEHRUNG', 'C20_KOSTENART_VERSICHERUNG', 'C20_KOSTENART_SONSTIGE_VERWALTUNG')
Add-Field -List "Kosten" -InternalName "person_ref" -DisplayName 'Bezug: Person, soweit zuordenbar' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "raum_ref" -DisplayName 'Bezug: Raum, soweit zuordenbar' -Type Lookup `
    -LookupList "Raeume" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "mittel_ref" -DisplayName 'Bezug: Arbeitsmittel, soweit zuordenbar' -Type Lookup `
    -LookupList "Arbeitsmittel" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe, soweit zuordenbar' -Type Lookup `
    -LookupList "Aufgaben" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "zahlende_gesellschaft_ref" -DisplayName 'Welche Gesellschaft hat diese Kosten zunächst bezahlt?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kosten" -InternalName "c21_status" -DisplayName 'Status' -Type Choice -Required `
    -Choices @('C21_STATUS_GESELLSCHAFT', 'C21_STATUS_NOCH_NICHT_BEZAHLT', 'C21_STATUS_UNBEKANNT')
Add-Field -List "Kosten" -InternalName "c21_rechnungsempfaenger_text" -DisplayName 'Rechnungsempfänger (bei offener Rechnung)' -Type Text
Add-Field -List "Kosten" -InternalName "zeitraum_von" -DisplayName 'Auf welchen Zeitraum beziehen sich die Kosten? - Beginn' -Type DateOnly -Required
Add-Field -List "Kosten" -InternalName "zeitraum_bis" -DisplayName 'Zeitraum - Ende' -Type DateOnly -Required
Add-Field -List "Kosten" -InternalName "betrag_status" -DisplayName 'Wie hoch ist der Betrag?' -Type Choice -Required `
    -Choices @('ERMITTLUNGSART_ERMITTELT', 'ERMITTLUNGSART_GESCHAETZT', 'ERMITTLUNGSART_UNBEKANNT')
Add-Field -List "Kosten" -InternalName "betrag" -DisplayName 'Betrag' -Type Number
Add-Field -List "Kosten" -InternalName "waehrung" -DisplayName 'Währung' -Type Text
Add-Field -List "Kosten" -InternalName "weiterberechnung" -DisplayName 'Wurden diese Kosten einer anderen Gesellschaft berechnet oder von ihr erstattet?' -Type Choice -Required `
    -Choices @('C24_WEITERBERECHNUNG_JA_VOLLSTAENDIG', 'C24_WEITERBERECHNUNG_JA_TEILWEISE', 'C24_WEITERBERECHNUNG_NEIN', 'C24_WEITERBERECHNUNG_NOCH_OFFEN', 'C24_WEITERBERECHNUNG_UNBEKANNT')
Add-Field -List "Kosten" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Kostenverteilungen
# Weiterberechnung von Kosten auf Empfaengergesellschaften (C25-C27)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Kostenverteilungen"
Add-Field -List "Kostenverteilungen" -InternalName "kostenanteil_id" -DisplayName 'Kostenanteils-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Kostenverteilungen" -InternalName "kosten_ref" -DisplayName 'Bezug: Kostenposition' -Type Lookup -Required `
    -LookupList "Kosten" -LookupField "display_label"
# kosten_ref: Anzeige: C24 = ja oder noch offen.
Add-Field -List "Kostenverteilungen" -InternalName "empfaenger_gesellschaft_ref" -DisplayName 'Welche Gesellschaft erhielt die Rechnung oder erstattete die Kosten?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kostenverteilungen" -InternalName "rechnungsempfaenger_ref" -DisplayName 'Rechnungsempfänger, falls abweichend' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kostenverteilungen" -InternalName "schluessel" -DisplayName 'Wie wurde der berechnete Anteil bestimmt?' -Type Choice -Required `
    -Choices @('C26_SCHLUESSEL_DIREKT', 'C26_SCHLUESSEL_STUNDEN', 'C26_SCHLUESSEL_NUTZUNG', 'C26_SCHLUESSEL_FLAECHE', 'C26_SCHLUESSEL_ANZAHL_NUTZER', 'C26_SCHLUESSEL_FESTE_PAUSCHALE', 'C26_SCHLUESSEL_ANDERER', 'C26_SCHLUESSEL_UNBEKANNT')
Add-Field -List "Kostenverteilungen" -InternalName "betrag" -DisplayName 'Betrag (bei Teilbeträgen)' -Type Number
Add-Field -List "Kostenverteilungen" -InternalName "zuschlag" -DisplayName 'Wurde ein Zuschlag berechnet?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Kostenverteilungen" -InternalName "zuschlag_basis_text" -DisplayName 'Zuschlagsbasis' -Type Text
Add-Field -List "Kostenverteilungen" -InternalName "zuschlag_hoehe" -DisplayName 'Höhe des Zuschlags' -Type Number
Add-Field -List "Kostenverteilungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Abrechnungen
# Tatsaechlich gestellte Abrechnungen (C28-C31)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Abrechnungen"
Add-Field -List "Abrechnungen" -InternalName "abrechnung_id" -DisplayName 'Abrechnungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Abrechnungen" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Abrechnungen" -InternalName "leistungsart" -DisplayName 'Welche Leistung rechnete die KG ab?' -Type Choice -Required `
    -Choices @('C28_LEISTUNGSART_MANAGEMENT', 'C28_LEISTUNGSART_PERSONALBEREITSTELLUNG', 'C28_LEISTUNGSART_ARBEITSMITTELBEREITSTELLUNG', 'C28_LEISTUNGSART_KOSTENERSTATTUNG', 'C28_LEISTUNGSART_ANDERE', 'C28_LEISTUNGSART_KEINE', 'C28_LEISTUNGSART_UNBEKANNT')
Add-Field -List "Abrechnungen" -InternalName "leistender_ref" -DisplayName 'Leistender' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Abrechnungen" -InternalName "empfaenger_ref" -DisplayName 'Empfänger' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Abrechnungen" -InternalName "zeitraum_von" -DisplayName 'Zeitraum - Beginn' -Type DateOnly
Add-Field -List "Abrechnungen" -InternalName "zeitraum_bis" -DisplayName 'Zeitraum - Ende' -Type DateOnly
Add-Field -List "Abrechnungen" -InternalName "betrag" -DisplayName 'Betrag' -Type Number
Add-Field -List "Abrechnungen" -InternalName "waehrung" -DisplayName 'Währung' -Type Text
Add-Field -List "Abrechnungen" -InternalName "vereinbarung_status" -DisplayName 'Liegt eine Vereinbarung zu dieser Leistung vor?' -Type Choice -Required `
    -Choices @('C29_VEREINBARUNG_UNTERZEICHNET', 'C29_VEREINBARUNG_NUR_ENTWURF', 'C29_VEREINBARUNG_NICHT_VERFUEGBAR', 'C29_VEREINBARUNG_KEINE', 'C29_VEREINBARUNG_UNBEKANNT')
Add-Field -List "Abrechnungen" -InternalName "c29_nachweis_ref" -DisplayName 'Vereinbarung (Nachweis)' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Abrechnungen" -InternalName "c30_abweichung" -DisplayName 'Welche Unterschiede zwischen Vereinbarung und tatsächlicher Ausführung sind bekannt?' -Type Choice -Required `
    -Choices @('C30_ABWEICHUNG_KEINE_BEKANNT', 'C30_ABWEICHUNG_VORHANDEN', 'C30_ABWEICHUNG_NOCH_NICHT_VERGLICHEN')
Add-Field -List "Abrechnungen" -InternalName "c30_text" -DisplayName 'Abweichung - Beschreibung' -Type Note
Add-Field -List "Abrechnungen" -InternalName "c31_abgestimmt" -DisplayName 'Sind Angaben und Abrechnungen mit der Buchhaltung abgestimmt?' -Type Choice -Required `
    -Choices @('C31_ABGESTIMMT_JA', 'C31_ABGESTIMMT_TEILWEISE', 'C31_ABGESTIMMT_NEIN', 'C31_ABGESTIMMT_NOCH_NICHT_GEPRUEFT')
Add-Field -List "Abrechnungen" -InternalName "c31_differenzen_text" -DisplayName 'Bekannte Differenzen' -Type Note
Add-Field -List "Abrechnungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Belegverknuepfungen
# Generische Verknuepfung Nachweis -> beliebige Zielliste, keine Mehrfachablage (N21)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Belegverknuepfungen"
Add-Field -List "Belegverknuepfungen" -InternalName "link_id" -DisplayName 'Link-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Belegverknuepfungen" -InternalName "nachweis_ref" -DisplayName 'Bezug: Nachweis' -Type Lookup -Required `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Belegverknuepfungen" -InternalName "ziel_typ" -DisplayName 'Welche Aufgabe, Zuständigkeit oder sonstige Angabe belegt die Unterlage? - Zieltyp' -Type Choice -Required `
    -Choices @('ZIEL_TYP_ERFASSUNGEN', 'ZIEL_TYP_GESELLSCHAFTEN', 'ZIEL_TYP_PERSONEN', 'ZIEL_TYP_ORTE', 'ZIEL_TYP_FUNKTIONEN', 'ZIEL_TYP_PERSONENBINDUNGEN', 'ZIEL_TYP_AUFGABEN', 'ZIEL_TYP_AUFGABENEMPFAENGER', 'ZIEL_TYP_AUFGABENZUSTAENDIGKEITEN', 'ZIEL_TYP_ENTSCHEIDUNGSBEFUGNISSE', 'ZIEL_TYP_VERTRAGSZUSTAENDIGKEITEN', 'ZIEL_TYP_KONTROLLAUFGABEN', 'ZIEL_TYP_STEUERUNGSBEZIEHUNGEN', 'ZIEL_TYP_PERSONENEINSAETZE', 'ZIEL_TYP_ZEITVERTEILUNGEN', 'ZIEL_TYP_AUFGABENORTE', 'ZIEL_TYP_RAEUME', 'ZIEL_TYP_ARBEITSMITTEL', 'ZIEL_TYP_RESSOURCENNUTZUNGEN', 'ZIEL_TYP_KOSTEN', 'ZIEL_TYP_KOSTENVERTEILUNGEN', 'ZIEL_TYP_ABRECHNUNGEN', 'ZIEL_TYP_OFFENEPUNKTE', 'ZIEL_TYP_INTERNEBEWERTUNGEN_ZH', 'ZIEL_TYP_INTERNEBEWERTUNGEN_HH')
Add-Field -List "Belegverknuepfungen" -InternalName "ziel_id" -DisplayName 'Ziel-ID (stabile ID der referenzierten Zeile)' -Type Text -Required
# ziel_id: Generischer Verweis als Text statt Einzel-Lookups je Zielliste (B1: 'keine Mehrfachablage').
Add-Field -List "Belegverknuepfungen" -InternalName "frage_id_text" -DisplayName 'Frage-ID, die belegt wird' -Type Text
Add-Field -List "Belegverknuepfungen" -InternalName "abschnitt_text" -DisplayName 'Seite oder Abschnitt' -Type Text
Add-Field -List "Belegverknuepfungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: OffenePunkte
# Fehlende Angaben und fehlende Nachweise mit Ansprechperson (N23, N26)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "OffenePunkte"
Add-Field -List "OffenePunkte" -InternalName "offener_punkt_id" -DisplayName 'Offener-Punkt-ID (intern vergeben)' -Type Text -Required
Add-Field -List "OffenePunkte" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "OffenePunkte" -InternalName "art" -DisplayName 'Art des offenen Punktes' -Type Choice -Required `
    -Choices @('OFFENER_PUNKT_ART_OFFENE_ANGABE', 'OFFENER_PUNKT_ART_FEHLENDER_NACHWEIS')
Add-Field -List "OffenePunkte" -InternalName "beschreibung_text" -DisplayName 'Welche Angaben müssen noch geklärt werden?' -Type Note -Required
Add-Field -List "OffenePunkte" -InternalName "bezug_ziel_typ" -DisplayName 'Bezug: Zieltyp (optional, generisch)' -Type Choice `
    -Choices @('ZIEL_TYP_ERFASSUNGEN', 'ZIEL_TYP_GESELLSCHAFTEN', 'ZIEL_TYP_PERSONEN', 'ZIEL_TYP_ORTE', 'ZIEL_TYP_FUNKTIONEN', 'ZIEL_TYP_PERSONENBINDUNGEN', 'ZIEL_TYP_AUFGABEN', 'ZIEL_TYP_AUFGABENEMPFAENGER', 'ZIEL_TYP_AUFGABENZUSTAENDIGKEITEN', 'ZIEL_TYP_ENTSCHEIDUNGSBEFUGNISSE', 'ZIEL_TYP_VERTRAGSZUSTAENDIGKEITEN', 'ZIEL_TYP_KONTROLLAUFGABEN', 'ZIEL_TYP_STEUERUNGSBEZIEHUNGEN', 'ZIEL_TYP_PERSONENEINSAETZE', 'ZIEL_TYP_ZEITVERTEILUNGEN', 'ZIEL_TYP_AUFGABENORTE', 'ZIEL_TYP_RAEUME', 'ZIEL_TYP_ARBEITSMITTEL', 'ZIEL_TYP_RESSOURCENNUTZUNGEN', 'ZIEL_TYP_KOSTEN', 'ZIEL_TYP_KOSTENVERTEILUNGEN', 'ZIEL_TYP_ABRECHNUNGEN', 'ZIEL_TYP_OFFENEPUNKTE', 'ZIEL_TYP_INTERNEBEWERTUNGEN_ZH', 'ZIEL_TYP_INTERNEBEWERTUNGEN_HH')
Add-Field -List "OffenePunkte" -InternalName "bezug_ziel_id" -DisplayName 'Bezug: Ziel-ID' -Type Text
Add-Field -List "OffenePunkte" -InternalName "ansprechperson_ref" -DisplayName 'Zuständige Person' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "OffenePunkte" -InternalName "nachreichtermin" -DisplayName 'Nachreichtermin (nur falls tatsächlich vereinbart)' -Type DateOnly
Add-Field -List "OffenePunkte" -InternalName "status" -DisplayName 'Status des offenen Punktes' -Type Choice -Required `
    -Choices @('OFFENER_PUNKT_STATUS_OFFEN', 'OFFENER_PUNKT_STATUS_ANGEFORDERT', 'OFFENER_PUNKT_STATUS_GEKLAERT')
Add-Field -List "OffenePunkte" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# InterneBewertungen_<Standort>: je Standort eine eigene Liste mit
# gebrochener Rechtevererbung (Entscheidung Nils - keine Item-Level-
# Berechtigung). Idempotent: ein spaeterer Lauf mit zusaetzlichem
# -Standort-Wert ergaenzt nur die fehlende Liste, ohne bestehende
# Listen/Berechtigungen zu veraendern.
# ---------------------------------------------------------------------------
foreach ($standort in $Standort) {
    $listName = "InterneBewertungen_$standort"
    Write-Host ""
    Write-Host "--- Standort: $standort ($listName) ---"

    # ---------------------------------------------------------------------------
    # Liste: InterneBewertungen (je Standort, siehe -Standort)
    # NUR INTERN, je Standort eine eigene Liste InterneBewertungen_<Standort> mit eingeschraenkten Berechtigungen - Auswertungshilfen zu Anhang D (D1-D7)
    # ---------------------------------------------------------------------------
    New-ListIfMissing -Title $listName
    Add-Field -List $listName -InternalName "bewertung_id" -DisplayName 'Bewertungs-ID (intern vergeben)' -Type Text -Required
    Add-Field -List $listName -InternalName "bezug_typ" -DisplayName 'Bezugstyp der Bewertung' -Type Choice -Required `
        -Choices @('BEWERTUNG_BEZUGSTYP_AUFGABE', 'BEWERTUNG_BEZUGSTYP_ENTSCHEIDUNGSBEFUGNIS', 'BEWERTUNG_BEZUGSTYP_VERTRAGSZUSTAENDIGKEIT', 'BEWERTUNG_BEZUGSTYP_KONTROLLAUFGABE')
    Add-Field -List $listName -InternalName "aufgabe_ref" -DisplayName 'Bezug: Aufgabe' -Type Lookup `
        -LookupList "Aufgaben" -LookupField "display_label"
    Add-Field -List $listName -InternalName "entscheidung_ref" -DisplayName 'Bezug: Entscheidungsbefugnis' -Type Lookup `
        -LookupList "Entscheidungsbefugnisse" -LookupField "display_label"
    Add-Field -List $listName -InternalName "vertrag_ref" -DisplayName 'Bezug: Vertragszuständigkeit' -Type Lookup `
        -LookupList "Vertragszustaendigkeiten" -LookupField "display_label"
    Add-Field -List $listName -InternalName "kontrolle_ref" -DisplayName 'Bezug: Kontrollaufgabe' -Type Lookup `
        -LookupList "Kontrollaufgaben" -LookupField "display_label"
    Add-Field -List $listName -InternalName "pruefungszusammenhang" -DisplayName 'Prüfungszusammenhang (z. B. tatsächliche Verwaltung, Konzernleistungen, Organrecht, VP-Stewardship, OECD-MK Art. 5)' -Type Text -Required
    Add-Field -List $listName -InternalName "einordnung" -DisplayName 'Vorläufige Einordnung' -Type Note -Required
    Add-Field -List $listName -InternalName "begruendung" -DisplayName 'Begründung' -Type Note
    Add-Field -List $listName -InternalName "quellen" -DisplayName 'Quellenverweis (Interner Anhang D, D1-D7)' -Type Note
    Add-Field -List $listName -InternalName "pruefer_name" -DisplayName 'Prüfende Person' -Type Text
    Add-Field -List $listName -InternalName "pruefdatum" -DisplayName 'Prüfdatum' -Type DateOnly
    Add-Field -List $listName -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

    Set-RestrictedPermission -List $listName -Groups @($StandortGruppen[$standort], $GesamtGruppe)
}

Write-Host ""
Write-Host "Fertig. Die 24 gemeinsamen Substanzpruefungs-Listen (Version 3), die Dokumentbibliothek Substanznachweise sowie InterneBewertungen_<Standort> fuer $($Standort -join ', ') sind angelegt bzw. angeglichen."
Write-Host "Ersetzt Version 2 vollstaendig (Update 2) - keine Vorgangslisten mehr (siehe PR-Beschreibung)."
Write-Host "Wiederverwendet (nicht neu angelegt, siehe Datenmodell Abschnitt \"Wiederverwendung\"):"
Write-Host "  - 'Eingang_Fehler' (DE/AO) fuer fehlgeschlagene Formular-Uebernahmen dieses Moduls (ungueltige/abgelaufene Erfassungsreferenz, Handlungs-Spaltenkonflikt)."
Write-Host "  - '4_Beteiligte_und_Quoten' (DE/AO) als Lookup-Ziel fuer Gesellschaften.ao_participation_ref."
Write-Host "Falls diese Listen auf der Zielsite noch nicht existieren, zuerst DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 ausfuehren."
Write-Host ""
foreach ($standort in $Standort) {
    if (-not $StandortGruppen.ContainsKey($standort) -and [string]::IsNullOrWhiteSpace($GesamtGruppe)) {
        Write-Warning "InterneBewertungen_$standort hat eine gebrochene Rechtevererbung erhalten, aber weder in -StandortGruppen noch -GesamtGruppe wurde eine Gruppe angegeben - die Liste bleibt gesperrt, bis manuell eine Gruppe mit Leserecht eingetragen wird (siehe sharepoint-forms/README.md)."
    }
}
Write-Host "Naechster Schritt: siehe DE/Substanz-Holding-KG/sharepoint-forms/README.md, Abschnitt E (Forms-Einrichtung) und F (Freigabe/Rollout)."
