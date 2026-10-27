#Requires -Modules PnP.PowerShell
<#
    .SYNOPSIS
    Legt die SharePoint-Listenfamilie "Substanzpruefung Holding-KG" (Listen
    SH0-SH11) an bzw. gleicht eine bereits vorhandene Installation an den
    aktuellen Feldkatalog an. Nutzt zusaetzlich zwei Listen der bestehenden
    steuerlichen Erfassung mit (siehe Abschnitt 6 der README), legt diese aber
    NICHT neu an und veraendert ihren Feldkatalog nicht.

    Feldkatalog und Architektur: siehe
      DE/Substanz-Holding-KG/Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md
      DE/Substanz-Holding-KG/sharepoint-forms/README.md (Abschnitt E: Forms-Spezifikation)

    .DESCRIPTION
    Uebernimmt Parameter-, Verbindungs- und Idempotenzlogik unveraendert vom
    Vorbild DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 (PR #16):
      - Fehlende Listen/Spalten werden angelegt.
      - Bereits vorhandene Spalten werden ANGEGLICHEN (Anzeigename, Pflichtstatus,
        fehlende Auswahlwerte werden ERGAENZT, nie entfernt; Index/Eindeutigkeit/
        Loeschverhalten werden nachgezogen, soweit SharePoint das im Nachhinein
        zulaesst).
      - Es werden NIE Spalten oder Listen geloescht oder Auswahlwerte entfernt.
        Jede Angleichung, die bei bereits vorhandenen Daten fehlschlagen kann,
        wird abgefangen und nur als Warnung ausgegeben, damit ein einzelner
        Problemfall nicht den gesamten Lauf abbricht.
      - Auswahlwerte werden konsequent mit Umlauten (ae/oe/ue -> ä/ö/ü) und in
        Schweizer Schreibweise ohne ss-statt-scharfes-s-Problem geschrieben (kein
        "ß" im gesamten Skript), identisch zwischen Skript, README und
        Klickanleitung (gleiche Loesung wie PR #16).

    .PARAMETER SiteUrl
    Zielsite im Tenant steueranwaltskanzlei.com, z. B.
    https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei (siehe README.md
    Abschnitt B fuer die Auswahl der Zielsite).

    .PARAMETER ClientId
    ClientId einer tenant-eigenen Entra-App-Registrierung mit delegierter
    Berechtigung "AllSites.FullControl" -- identisch zur Vorgabe in
    DE/AO/sharepoint-forms/README.md Abschnitt C1 (die generische
    PnP-Management-Shell-App ist seit 09/2024 in den meisten Tenants gesperrt).

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
    [string]$ClientId
)

$ErrorActionPreference = "Stop"

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

# ---------------------------------------------------------------------------
# Hilfsfunktionen (identisch zu DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1,
# damit beide Skriptfamilien gleich gewartet werden koennen)
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
      "Title" ist in jeder SharePoint-Standardliste per Vorlage Pflicht. Die
      Forms-Flows befuellen "Title" nicht zwangslaeufig (die fachliche Kennung
      je Liste ist eine eigene Spalte, z. B. case_id/display_label). Deshalb
      wird "Title" ueberall optional geschaltet; Flows SOLLTEN "Title" trotzdem
      befuellen (Lesbarkeit in Standardansichten), siehe README.md.
    #>
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
    <#
      case_id und access_code in SH0_Substanzfall muessen indiziert sein, bevor
      EnforceUniqueValues gesetzt werden kann. Schlaegt EnforceUniqueValues fehl
      (z. B. weil aus einem frueheren, nicht-idempotenten Lauf bereits doppelte
      Werte existieren), wird dies nur als Warnung ausgegeben, damit der Rest
      des Skripts weiterlaeuft.
    #>
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
    <#
      "Restrict" fuer den tragenden case_id-Bezug jeder Folgeliste auf
      SH0_Substanzfall: ein Substanzfall darf nicht geloescht werden, solange
      noch Folgedatensaetze darauf verweisen. "None" (Standard) fuer alle
      optionalen Sekundaer-Lookups (Personen-, Orts-, Asset-, Tätigkeits- und
      Beteiligungsbezuege), damit das Loeschen eines Kernobjekts nicht an einer
      angehaengten Referenz scheitert.
    #>
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
    <#
      Zentrale Feld-Anlage- und -Angleichungsfunktion, 1:1 uebernommen aus
      DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1:
      - -Type DateOnly: reines Datumsfeld ohne Uhrzeit.
      - -Type URL: Hyperlink-Feld (fuer Grundriss-/Fotolinks, file_link).
      - -DefaultValue: Default fuer Boolean/Text/Note/Number.
      - -Min/-Max: Wertebereich fuer Number-Felder.
      - -Indexed/-EnforceUniqueValues: siehe Set-FieldIndexAndUniqueness.
      - -DeleteBehavior: siehe Set-LookupDeleteBehavior (nur Type Lookup).
      - Angleichung bestehender Felder: Anzeigename, Pflichtstatus und fehlende
        Auswahlwerte (nie Entfernen) werden bei bereits vorhandenen Feldern
        nachgezogen.
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
            "Lookup" {
                $targetList = Get-PnPList -Identity $LookupList
                $deleteBehaviorAttr = if ($DeleteBehavior -ne "None") { " RelationshipDeleteBehavior='$DeleteBehavior'" } else { "" }
                $fieldXml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' List='{$($targetList.Id)}' ShowField='$LookupField'$deleteBehaviorAttr />"
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
                # Text, Note
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

        if ($Type -ne "Lookup" -and [bool]$existing.Required -ne [bool]$Required) {
            try {
                Set-PnPField -List $List -Identity $InternalName -Values @{ Required = [bool]$Required } | Out-Null
                Write-Host "    Pflichtstatus angeglichen -> Required=$Required"
            }
            catch {
                Write-Warning "    Konnte Pflichtstatus fuer $List/$InternalName nicht angleichen: $_"
            }
        }

        if ($Type -eq "Choice" -and $Choices) {
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
    if ($Type -eq "Lookup" -and $DeleteBehavior -ne "None") {
        Set-LookupDeleteBehavior -List $List -InternalName $InternalName -DeleteBehavior $DeleteBehavior
    }
}

# ---------------------------------------------------------------------------
# Gemeinsame Auswahlwert-Kataloge ("einheitliche Unterstruktur")
# ---------------------------------------------------------------------------

# Haeufigkeits-Skala, woertlich aus Vorgabe Abschnitt 1 Frage "Wie haeufig
# arbeitet sie fuer die Holding-KG?" uebernommen und modulweit einheitlich
# fuer jede "Wie haeufig?"-Frage verwendet (Abschnitte 1, 2, 4, 5, 6, 7).
$HaeufigkeitChoices = @("täglich", "mehrmals pro Woche", "wöchentlich", "monatlich", "nur bei Bedarf")

# 22 Managementtätigkeiten, woertlich aus Vorgabe Abschnitt 2 uebernommen.
$ManagementtaetigkeitChoices = @(
    "Geschäftsplanung / Unternehmenssteuerung",
    "Strategie und Unternehmensplanung",
    "Budgetplanung",
    "Controlling",
    "Liquiditätsplanung",
    "Finanzierung",
    "Investitionen",
    "Geschäftsführung / Unterstützung der Geschäftsleitung",
    "Vertriebssteuerung",
    "Marketing",
    "Preisgestaltung",
    "Einkauf",
    "Personalplanung",
    "Einstellungen und Vergütungen",
    "Organisation",
    "Rechnungswesen",
    "Steuern",
    "Recht",
    "Compliance",
    "IT",
    "Produktentwicklung / F&E",
    "sonstige Managementaufgaben"
)

# 12 Entscheidungsarten, woertlich aus Vorgabe Abschnitt 3 uebernommen.
$EntscheidungsartChoices = @(
    "Budget",
    "Investitionen",
    "Finanzierung",
    "Personal",
    "Geschäftsführung",
    "wichtige Verträge",
    "Preisgestaltung",
    "Vertrieb",
    "Produkte",
    "strategische Projekte",
    "Ausschüttungen",
    "Erwerb oder Verkauf von Beteiligungen"
)

# 12 Asset-Kategorien, woertlich aus Vorgabe Abschnitt 5 uebernommen.
$AssetKategorieChoices = @(
    "Schreibtische und Arbeitsplätze",
    "Büromöbel",
    "Computer",
    "Bildschirme",
    "Mobiltelefone",
    "Drucker",
    "Server / Netzwerk",
    "Software",
    "Fahrzeuge",
    "Fahrräder",
    "Besprechungsräume",
    "sonstige technische Ausstattung"
)

# Raumart: in der Vorgabe kein geschlossener Katalog genannt ("Art des
# Raums" als Freitextfrage) -- Kanzleientscheid: geschlossene Choice-Liste mit
# "Sonstige" fuer Auswertbarkeit, siehe Datenmodell Abschnitt 4.
$RaumartChoices = @("Büro", "Besprechungsraum", "Empfang", "Lager", "Home-Office / mitbenutzter Raum", "Sonstige")

# Kostenkategorie, aus Vorgabe Abschnitt 9 abgeleitet (Personen/Raeume/
# Arbeitsmittel/externe Dienstleister).
$KostenkategorieChoices = @("Personen", "Räume", "Arbeitsmittel", "externe Dienstleister")

# Dokumenttyp fuer SH11_Belege, aus den "Welche Unterlagen entstehen"- und
# Belegfragen (Punkt 5 des Auftrags) abgeleitet.
$DokumenttypChoices = @(
    "Nachweis Managementtätigkeit",
    "Protokoll / Beschlussdokumentation",
    "Vertrag / Vollmacht",
    "Grundriss",
    "Foto Geschäftsraum",
    "Foto Arbeitsmittel",
    "Rechnung / Kostenbeleg",
    "Sonstiges"
)

# ---------------------------------------------------------------------------
# Liste SH0: Substanzfall (zuerst, da alle Folgelisten hierauf verweisen)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH0_Substanzfall"
Add-Field -List "SH0_Substanzfall" -InternalName "case_id" -DisplayName "Fall-ID (Substanzprüfung)" -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "SH0_Substanzfall" -InternalName "access_code" -DisplayName "Zugangscode (Mandantenprüfung)" -Type Text `
    -Indexed -EnforceUniqueValues
# access_code: identisches Muster wie 0_Fallsteuerung.access_code (DE/AO) --
# Zufallswert je Fall, da Fall-IDs leicht erratbar sind. Nicht -Required, da
# bestehende Faelle ohne Nachtrag sonst nicht mehr bearbeitbar waeren.
Add-Field -List "SH0_Substanzfall" -InternalName "holding_name" -DisplayName "Name der Holding-KG" -Type Text -Required
Add-Field -List "SH0_Substanzfall" -InternalName "holding_tax_number" -DisplayName "Steuernummer / Identifikationsnummer der Holding-KG (falls bekannt)" -Type Text
Add-Field -List "SH0_Substanzfall" -InternalName "related_erfassung_case" -DisplayName "Bezug: Fall der steuerlichen Erfassung (DE/AO, falls vorhanden)" -Type Lookup `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
# related_erfassung_case (kein Forms-Feld, siehe README Abschnitt F): optionaler
# Bezug auf einen bereits bestehenden 0_Fallsteuerung-Datensatz (DE/AO), damit
# Beteiligungsgesellschaften aus 4_Beteiligte_und_Quoten desselben Falls als
# Lookup-Ziel fuer "Beteiligungsgesellschaft" in den Folgelisten wiederverwendet
# werden koennen (siehe Datenmodell Abschnitt "Wiederverwendung"). DeleteBehavior
# bleibt "None": das Loeschen eines Erfassungsfalls soll nicht an einem
# verknuepften Substanzfall scheitern.
Add-Field -List "SH0_Substanzfall" -InternalName "review_period_from" -DisplayName "Prüfungszeitraum - von" -Type DateOnly
Add-Field -List "SH0_Substanzfall" -InternalName "review_period_to" -DisplayName "Prüfungszeitraum - bis" -Type DateOnly
Add-Field -List "SH0_Substanzfall" -InternalName "engagement_contact" -DisplayName "Mandatsverantwortliche Person (Kanzlei)" -Type Text
Add-Field -List "SH0_Substanzfall" -InternalName "processing_note" -DisplayName "Persönliche Bearbeitungsnotiz" -Type Note
Add-Field -List "SH0_Substanzfall" -InternalName "case_status" -DisplayName "Status" -Type Choice -Required `
    -Choices @("offen", "in Bearbeitung", "vollständig", "ausgewertet")
# created_by/created_at: SharePoint-Systemfelder Author/Created werden verwendet, keine Zusatzspalte noetig (Muster wie 0_Fallsteuerung).

# ---------------------------------------------------------------------------
# Liste SH1: Personen, die fuer die Holding-KG taetig sind (Vorgabe Abschnitt 1)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH1_Personen"
Add-Field -List "SH1_Personen" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH1_Personen" -InternalName "person_name" -DisplayName "Name" -Type Text -Required
Add-Field -List "SH1_Personen" -InternalName "function_title" -DisplayName "Funktion / Stellenbezeichnung" -Type Text -Required
Add-Field -List "SH1_Personen" -InternalName "employer_company_text" -DisplayName "Bei welcher Gesellschaft angestellt oder vertraglich gebunden?" -Type Text -Required
Add-Field -List "SH1_Personen" -InternalName "employer_participation_ref" -DisplayName "Bezug: Beteiligungsgesellschaft (DE/AO 4_Beteiligte_und_Quoten, falls bereits erfasst)" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
# employer_participation_ref (kein Forms-Feld): Aufloesung von
# employer_company_text auf eine bereits in der steuerlichen Erfassung
# gefuehrte Beteiligungsgesellschaft, analog related_participation in
# 8_Unterlagen (DE/AO). Keine Angabe zur Konzern-/Beteiligungsquote -- es
# geht hier nur um den Arbeitgeber-/Vertragsbezug der Person, nicht um die
# Konzernstruktur als solche.
Add-Field -List "SH1_Personen" -InternalName "vertretung_ref" -DisplayName "Bezug: ggf. bereits erfasste Person/Vertretung (DE/AO 3_Personen_und_Vertretung)" -Type Lookup `
    -LookupList "3_Personen_und_Vertretung" -LookupField "display_label"
Add-Field -List "SH1_Personen" -InternalName "actual_tasks" -DisplayName "Welche Aufgaben übernimmt die Person tatsächlich für die Holding-KG?" -Type Note -Required
Add-Field -List "SH1_Personen" -InternalName "tasks_since" -DisplayName "Seit wann?" -Type DateOnly
Add-Field -List "SH1_Personen" -InternalName "work_frequency" -DisplayName "Wie häufig arbeitet sie für die Holding-KG?" -Type Choice -Required `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH1_Personen" -InternalName "work_time_share" -DisplayName "Wie viel Arbeitszeit entfällt ungefähr auf Aufgaben der Holding-KG?" -Type Text
# work_time_share bewusst Text statt Number/Prozent: die Vorgabe laesst sowohl
# Prozent- als auch Stundenangaben zu ("ungefaehr"); eine erzwungene
# Zahlenangabe wuerde die freie Schaetzung einschraenken.
Add-Field -List "SH1_Personen" -InternalName "work_locations" -DisplayName "An welchen Orten führt die Person diese Aufgaben aus?" -Type Note
Add-Field -List "SH1_Personen" -InternalName "office_presence_frequency" -DisplayName "Wie häufig arbeitet die Person in den Geschäftsräumen der Holding-KG?" -Type Choice `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH1_Personen" -InternalName "decisions_own" -DisplayName "Welche Entscheidungen trifft die Person selbst?" -Type Note
Add-Field -List "SH1_Personen" -InternalName "decisions_prepared_only" -DisplayName "Welche Entscheidungen bereitet sie nur vor?" -Type Note
Add-Field -List "SH1_Personen" -InternalName "signing_authority" -DisplayName "Welche Verträge oder sonstigen Unterlagen darf sie unterschreiben?" -Type Note
Add-Field -List "SH1_Personen" -InternalName "staff_or_vendors_managed" -DisplayName "Welche Mitarbeiter oder Dienstleister steuert sie?" -Type Note
Add-Field -List "SH1_Personen" -InternalName "tools_used" -DisplayName "Welche Arbeitsmittel nutzt sie?" -Type Note
# tools_used ist eine Freitext-Zusammenfassung; die strukturierte Zuordnung
# "welches Asset genau, wo, wie haeufig" steht in SH6_Asset_Nutzung (user_ref).
Add-Field -List "SH1_Personen" -InternalName "typical_week_description" -DisplayName "Offene Frage: typische Arbeitswoche/typischer Monat der Person für die Holding-KG" -Type Note -Required
Add-Field -List "SH1_Personen" -InternalName "evidence_note" -DisplayName "Belege/Nachweise (z. B. Anstellungsvertrag, Vollmacht) - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH1_Personen" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text
# display_label: identisches Muster wie in 3_Personen_und_Vertretung (DE/AO),
# vom auslösenden Flow nach Elementanlage zu befuellen, z. B.
# "<Name> (<Funktion>, Fall <case_id>, ID <ID>)".

# ---------------------------------------------------------------------------
# Liste SH2: Entscheidungsprozesse (Vorgabe Abschnitt 3, 12 Entscheidungsarten)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH2_Entscheidungsprozesse"
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "decision_type" -DisplayName "Art der Entscheidung" -Type Choice -Required `
    -Choices $EntscheidungsartChoices
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_first_involved_text" -DisplayName "Wer beschäftigt sich zuerst damit?" -Type Text
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_first_involved_ref" -DisplayName "Bezug: Person (wer beschäftigt sich zuerst damit)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_prepares_text" -DisplayName "Wer bereitet vor?" -Type Text
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_prepares_ref" -DisplayName "Bezug: Person (wer bereitet vor)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_recommends_text" -DisplayName "Wer gibt Empfehlung ab?" -Type Text
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_recommends_ref" -DisplayName "Bezug: Person (wer gibt Empfehlung ab)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_decides_final_text" -DisplayName "Wer trifft die endgültige Entscheidung?" -Type Text -Required
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "who_decides_final_ref" -DisplayName "Bezug: Person (wer trifft die endgültige Entscheidung)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "decision_maker_location" -DisplayName "Wo befindet sich diese Person bei der Entscheidung?" -Type Text
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "decision_channel" -DisplayName "Meeting / E-Mail / telefonisch / anders?" -Type Choice `
    -Choices @("Meeting", "E-Mail", "Telefonisch", "Anders")
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "documented_in_writing" -DisplayName "Schriftlich festgehalten?" -Type Boolean
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "documentation_location" -DisplayName "Wenn ja, wo? (inkl. Hinweis Datei-Upload/Dokumentbibliothek)" -Type Note
Add-Field -List "SH2_Entscheidungsprozesse" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH4: Geschäftsräume/Bereiche (Vorgabe Abschnitt 4)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH4_Orte"
Add-Field -List "SH4_Orte" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH4_Orte" -InternalName "address" -DisplayName "Anschrift" -Type Note -Required
Add-Field -List "SH4_Orte" -InternalName "room_number" -DisplayName "Raum / Raumnummer" -Type Text
Add-Field -List "SH4_Orte" -InternalName "size_sqm" -DisplayName "Grösse (m²)" -Type Number -Min 0
Add-Field -List "SH4_Orte" -InternalName "room_type" -DisplayName "Art des Raums" -Type Choice `
    -Choices $RaumartChoices
Add-Field -List "SH4_Orte" -InternalName "betriebsstaette_text" -DisplayName "Bezug: ggf. bereits gemeldete Betriebsstätte (Bezeichnung)" -Type Text
Add-Field -List "SH4_Orte" -InternalName "betriebsstaette_ref" -DisplayName "Bezug: Betriebsstätte (DE/AO 5_Betriebsstaetten, falls bereits erfasst)" -Type Lookup `
    -LookupList "5_Betriebsstaetten" -LookupField "display_label"
# betriebsstaette_ref (kein Forms-Feld): optionaler Querverweis, falls der
# Geschaeftsraum bereits als 5_Betriebsstaetten-Datensatz in der steuerlichen
# Erfassung (DE/AO) gefuehrt wird. Betriebsstaetten sind dort eine
# steuerliche/rechtliche Einheit je Standort ohne Raum-/Zugangs-/
# Ausstattungsdetails -- diese Liste bleibt deshalb eigenstaendig
# (Begruendung siehe Datenmodell Abschnitt "Wiederverwendung").
Add-Field -List "SH4_Orte" -InternalName "used_by" -DisplayName "Wer nutzt ihn?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "usage_frequency" -DisplayName "Wie häufig?" -Type Choice `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH4_Orte" -InternalName "used_for_activities" -DisplayName "Für welche Tätigkeiten?" -Type Note
# used_by/usage_frequency/used_for_activities sind Freitext-Zusammenfassungen;
# die strukturierte Zuordnung je Person/Taetigkeit steht in SH3 (location_ref)
# und SH6_Asset_Nutzung (location_ref).
Add-Field -List "SH4_Orte" -InternalName "exclusively_for_holding" -DisplayName "Ausschliesslich für Holding-KG?" -Type Boolean -Required
Add-Field -List "SH4_Orte" -InternalName "other_users_if_not_exclusive" -DisplayName "Wenn nein, wer sonst?" -Type Text
Add-Field -List "SH4_Orte" -InternalName "availability_for_holding" -DisplayName "Wann steht er der Holding-KG zur Verfügung?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "workstations" -DisplayName "Welche Arbeitsplätze?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "equipment" -DisplayName "Welche Ausstattung?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "access_persons" -DisplayName "Wer hat Zugang?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "access_credentials" -DisplayName "Schlüssel/Zugangskarten/Berechtigungen?" -Type Note
Add-Field -List "SH4_Orte" -InternalName "floor_plan_available" -DisplayName "Grundriss vorhanden?" -Type Boolean
Add-Field -List "SH4_Orte" -InternalName "floor_plan_link" -DisplayName "Verweis auf Grundriss (Datei-Upload/Dokumentbibliothek)" -Type URL
Add-Field -List "SH4_Orte" -InternalName "photos_available" -DisplayName "Fotos vorhanden?" -Type Boolean
Add-Field -List "SH4_Orte" -InternalName "photos_link" -DisplayName "Verweis auf Fotos (Datei-Upload/Dokumentbibliothek)" -Type URL
Add-Field -List "SH4_Orte" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH3: Managementtätigkeiten (Vorgabe Abschnitt 2, 22 Tätigkeiten,
# einheitliche Unterstruktur) -- zentrale Verknüpfungsliste Person x Tätigkeit
# x Beteiligung x Ort (n:m)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH3_Managementtaetigkeiten"
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "activity_type" -DisplayName "Tätigkeit" -Type Choice -Required `
    -Choices $ManagementtaetigkeitChoices
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "other_activity_description" -DisplayName "Bezeichnung, falls 'sonstige Managementaufgaben'" -Type Text
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "actually_performed" -DisplayName "Wird die Aufgabe von der Holding-KG tatsächlich wahrgenommen?" -Type Boolean -Required
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "handled_by_text" -DisplayName "Wer bearbeitet sie?" -Type Text -Required
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "handled_by_ref" -DisplayName "Bezug: Person (wer bearbeitet sie)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "description_concrete" -DisplayName "Was wird konkret gemacht?" -Type Note -Required
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "frequency" -DisplayName "Wie häufig?" -Type Choice -Required `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "participation_text" -DisplayName "Für welche Beteiligungsgesellschaft?" -Type Text
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "participation_ref" -DisplayName "Bezug: Beteiligungsgesellschaft (DE/AO 4_Beteiligte_und_Quoten)" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "location_text" -DisplayName "Wo wird sie ausgeübt?" -Type Text
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "location_ref" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "documents_created" -DisplayName "Welche Unterlagen entstehen?" -Type Note
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "evidence_note" -DisplayName "Belege/Nachweise - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "final_decision_text" -DisplayName "Wer trifft die abschliessende Entscheidung?" -Type Text
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "final_decision_ref" -DisplayName "Bezug: Person (wer trifft die abschliessende Entscheidung)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH3_Managementtaetigkeiten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text
# SH3 ist das Rueckgrat des Kern-Datenmodells: eine Zeile verknuepft eine
# Managementtaetigkeit mit genau einer Person (handled_by_ref), optional einer
# Beteiligungsgesellschaft (participation_ref) und einem Ort (location_ref).
# Werden mehrere Personen/Beteiligungen/Orte an derselben Taetigkeit beteiligt,
# werden mehrere Zeilen mit demselben activity_type angelegt (n:m ueber
# mehrere Zeilen, kein Mehrfach-Lookup) -- siehe Datenmodell, Abschnitt
# "Leitfragen-Nachweis".

# ---------------------------------------------------------------------------
# Liste SH5: Arbeitsplätze und Sachmittel / Assets (Vorgabe Abschnitt 5,
# Stammdaten "was ist vorhanden" -- Nutzung in SH6)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH5_Assets"
Add-Field -List "SH5_Assets" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH5_Assets" -InternalName "asset_category" -DisplayName "Kategorie" -Type Choice -Required `
    -Choices $AssetKategorieChoices
Add-Field -List "SH5_Assets" -InternalName "asset_description" -DisplayName "Was ist vorhanden? (Bezeichnung/Beschreibung)" -Type Text -Required
Add-Field -List "SH5_Assets" -InternalName "owner_text" -DisplayName "Wem gehört es?" -Type Text
Add-Field -List "SH5_Assets" -InternalName "cost_bearing_company_text" -DisplayName "Welche Gesellschaft trägt die Kosten?" -Type Text -Required
Add-Field -List "SH5_Assets" -InternalName "cost_bearing_company_ref" -DisplayName "Bezug: Beteiligungsgesellschaft (DE/AO 4_Beteiligte_und_Quoten, falls zutreffend)" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "SH5_Assets" -InternalName "evidence_note" -DisplayName "Belege/Nachweise (z. B. Fotos, Rechnungen) - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH5_Assets" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text
# Standort/Nutzer/Taetigkeit/Nutzungsumfang je Asset stehen bewusst NICHT hier,
# sondern in SH6_Asset_Nutzung (Vorgabe Abschnitt 5: "Datenmodell: Asset ->
# Standort -> Nutzer -> Tätigkeit -> Nutzungsumfang"), da ein Asset mehrere
# Nutzungsinstanzen haben kann (z. B. an verschiedenen Standorten oder durch
# verschiedene Personen).

# ---------------------------------------------------------------------------
# Liste SH6: Asset-Nutzung (Vorgabe Abschnitt 5) -- Verknüpfungsliste n:m
# Asset x Standort x Nutzer x Tätigkeit x Nutzungsumfang
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH6_Asset_Nutzung"
Add-Field -List "SH6_Asset_Nutzung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH6_Asset_Nutzung" -InternalName "asset_text" -DisplayName "Welches Arbeitsmittel/Asset?" -Type Text -Required
Add-Field -List "SH6_Asset_Nutzung" -InternalName "asset_ref" -DisplayName "Bezug: Asset (SH5_Assets)" -Type Lookup `
    -LookupList "SH5_Assets" -LookupField "display_label"
Add-Field -List "SH6_Asset_Nutzung" -InternalName "location_text" -DisplayName "Wo befindet es sich?" -Type Text
Add-Field -List "SH6_Asset_Nutzung" -InternalName "location_ref" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH6_Asset_Nutzung" -InternalName "user_text" -DisplayName "Wer nutzt es?" -Type Text -Required
Add-Field -List "SH6_Asset_Nutzung" -InternalName "user_ref" -DisplayName "Bezug: Person (Nutzer)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH6_Asset_Nutzung" -InternalName "usage_frequency" -DisplayName "Wie häufig?" -Type Choice -Required `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH6_Asset_Nutzung" -InternalName "used_for_activity" -DisplayName "Für welche Tätigkeit?" -Type Choice `
    -Choices $ManagementtaetigkeitChoices
Add-Field -List "SH6_Asset_Nutzung" -InternalName "exclusively_for_holding" -DisplayName "Ausschliesslich für Holding-KG?" -Type Boolean -Required
Add-Field -List "SH6_Asset_Nutzung" -InternalName "other_users_if_not_exclusive" -DisplayName "Wenn nein, wer noch?" -Type Text
Add-Field -List "SH6_Asset_Nutzung" -InternalName "usage_extent_note" -DisplayName "Nutzungsumfang (Details, z. B. Anteil/Stunden)" -Type Note
Add-Field -List "SH6_Asset_Nutzung" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH7: Nutzung der Substanz im Tagesgeschäft/Präsenz (Vorgabe Abschnitt 6)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH7_Tagesgeschaeft_Praesenz"
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "location_text" -DisplayName "Bezug: Geschäftsraum (Bezeichnung, optional)" -Type Text
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "location_ref" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "typical_days_per_month" -DisplayName "An wie vielen Tagen pro Monat sind Personen der Holding-KG typischerweise vor Ort?" -Type Number -Min 0 -Max 31
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "persons_onsite_text" -DisplayName "Welche Personen?" -Type Note -Required
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "activities_onsite" -DisplayName "Was tun sie dort konkret?" -Type Note -Required
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "management_meetings_held" -DisplayName "Finden dort Managementbesprechungen statt?" -Type Boolean
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "meeting_frequency" -DisplayName "Wie häufig? (Managementbesprechungen)" -Type Choice `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "meeting_participants" -DisplayName "Wer nimmt teil?" -Type Note
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "documents_created_or_signed" -DisplayName "Werden dort Unterlagen erstellt oder unterschrieben?" -Type Boolean
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "documents_created_or_signed_note" -DisplayName "Details - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "emails_or_transactions_handled" -DisplayName "Werden von dort E-Mails versandt oder Geschäftsvorgänge bearbeitet?" -Type Boolean
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "stakeholder_calls_held" -DisplayName "Werden von dort Gespräche mit Geschäftsführern, Vorständen, Banken, Kunden oder Beratern geführt?" -Type Boolean
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "tasks_done_elsewhere" -DisplayName "Welche Aufgaben werden regelmässig von anderen Orten aus erledigt?" -Type Note
Add-Field -List "SH7_Tagesgeschaeft_Praesenz" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH8: Zusammenarbeit mit Beteiligungsgesellschaften (Vorgabe Abschnitt 7)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH8_Zusammenarbeit_Beteiligungen"
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "participation_text" -DisplayName "Beteiligungsgesellschaft" -Type Text -Required
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "participation_ref" -DisplayName "Bezug: Beteiligungsgesellschaft (DE/AO 4_Beteiligte_und_Quoten)" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "typical_service_type" -DisplayName "Zuordnung zu einer Managementtätigkeit (optional)" -Type Choice `
    -Choices $ManagementtaetigkeitChoices
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "typical_service_description" -DisplayName "Bezeichnung der typischen Managementleistung" -Type Text -Required
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "contact_initiator_text" -DisplayName "Wer bei der Holding-KG nimmt Kontakt auf?" -Type Text -Required
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "contact_initiator_ref" -DisplayName "Bezug: Person (Kontaktaufnahme)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "counterpart_text" -DisplayName "Mit wem wird dort gesprochen?" -Type Text
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "frequency" -DisplayName "Wie häufig?" -Type Choice `
    -Choices $HaeufigkeitChoices
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "topic" -DisplayName "Was wird besprochen?" -Type Note -Required
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "guidance_given" -DisplayName "Welche Vorgaben oder Empfehlungen gibt die Holding-KG?" -Type Note
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "information_received" -DisplayName "Welche Informationen erhält sie zurück?" -Type Note
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "documents_exchanged" -DisplayName "Welche Unterlagen werden ausgetauscht? - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "outcome_next_steps" -DisplayName "Was passiert anschliessend?" -Type Note
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "control_person_text" -DisplayName "Wer kontrolliert die Umsetzung?" -Type Text
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "control_person_ref" -DisplayName "Bezug: Person (Kontrolle der Umsetzung)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH8_Zusammenarbeit_Beteiligungen" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH9: Typische konkrete Geschäftsvorgänge (Vorgabe Abschnitt 8,
# 3-5 Beispiele)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH9_Geschaeftsvorgaenge"
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "sequence_number" -DisplayName "Laufende Nummer (1-5)" -Type Number -Required -Min 1 -Max 5
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "subject" -DisplayName "Worum ging es?" -Type Note -Required
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "participation_text" -DisplayName "Welche Beteiligungsgesellschaft?" -Type Text -Required
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "participation_ref" -DisplayName "Bezug: Beteiligungsgesellschaft (DE/AO 4_Beteiligte_und_Quoten)" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "involved_person_text" -DisplayName "Wer auf Seiten der Holding-KG beteiligt?" -Type Text -Required
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "involved_person_ref" -DisplayName "Bezug: Person (beteiligt)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "action_taken" -DisplayName "Was hat diese Person konkret gemacht?" -Type Note -Required
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "event_date" -DisplayName "Wann?" -Type DateOnly -Required
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "location_text" -DisplayName "Wo?" -Type Text
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "location_ref" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "decision_made" -DisplayName "Welche Entscheidung wurde getroffen?" -Type Note
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "documents_created" -DisplayName "Welche Unterlagen entstanden? - Hinweis Datei-Upload/Dokumentbibliothek" -Type Note
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "implemented_by_text" -DisplayName "Wer setzte die Entscheidung um?" -Type Text
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "implemented_by_ref" -DisplayName "Bezug: Person (Umsetzung)" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH9_Geschaeftsvorgaenge" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH10: Kosten nur bezogen auf die tatsächliche Tätigkeit (Vorgabe
# Abschnitt 9)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH10_Kosten"
Add-Field -List "SH10_Kosten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH10_Kosten" -InternalName "cost_category" -DisplayName "Kostenkategorie" -Type Choice -Required `
    -Choices $KostenkategorieChoices
Add-Field -List "SH10_Kosten" -InternalName "related_person_text" -DisplayName "Welche Personen verursachen Kosten? (bei Kategorie Personen)" -Type Text
Add-Field -List "SH10_Kosten" -InternalName "related_person_ref" -DisplayName "Bezug: Person" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH10_Kosten" -InternalName "related_location_text" -DisplayName "Welche Räume werden genutzt? (bei Kategorie Räume)" -Type Text
Add-Field -List "SH10_Kosten" -InternalName "related_location_ref" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH10_Kosten" -InternalName "related_asset_text" -DisplayName "Welche Arbeitsmittel? (bei Kategorie Arbeitsmittel)" -Type Text
Add-Field -List "SH10_Kosten" -InternalName "related_asset_ref" -DisplayName "Bezug: Asset" -Type Lookup `
    -LookupList "SH5_Assets" -LookupField "display_label"
Add-Field -List "SH10_Kosten" -InternalName "external_provider_name" -DisplayName "Welche externen Dienstleister? (bei Kategorie externe Dienstleister)" -Type Text
Add-Field -List "SH10_Kosten" -InternalName "cost_description" -DisplayName "Welche Kosten entstehen daraus?" -Type Note -Required
Add-Field -List "SH10_Kosten" -InternalName "cost_amount" -DisplayName "Betrag (geschätzt)" -Type Number -Min 0
Add-Field -List "SH10_Kosten" -InternalName "cost_currency" -DisplayName "Währung" -Type Text -DefaultValue "EUR"
Add-Field -List "SH10_Kosten" -InternalName "paying_company_initially" -DisplayName "Welche Gesellschaft bezahlt zunächst?" -Type Text -Required
Add-Field -List "SH10_Kosten" -InternalName "allocation_method" -DisplayName "Wie werden sie der Holding-KG zugeordnet?" -Type Note -Required
Add-Field -List "SH10_Kosten" -InternalName "recharged" -DisplayName "Werden sie weiterberechnet?" -Type Boolean
Add-Field -List "SH10_Kosten" -InternalName "recharge_note" -DisplayName "Weiterberechnung - Details" -Type Note
Add-Field -List "SH10_Kosten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, für Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste SH11: Belege (Querschnitt, Belegfragen Punkt 5 des Auftrags) --
# strukturell identisch zu 8_Unterlagen (DE/AO), aber eigenstaendige Liste, da
# 8_Unterlagen.case_id zwingend (Required-Lookup) auf 0_Fallsteuerung zeigt
# und nicht auf SH0_Substanzfall umgewidmet werden kann (siehe Datenmodell
# Abschnitt "Wiederverwendung").
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "SH11_Belege"
Add-Field -List "SH11_Belege" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "SH0_Substanzfall" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "SH11_Belege" -InternalName "document_type" -DisplayName "Dokumenttyp" -Type Choice -Required `
    -Choices $DokumenttypChoices
Add-Field -List "SH11_Belege" -InternalName "related_object_text" -DisplayName "Bezug zu Objekt (Freitext: Person/Tätigkeit/Ort/Asset/Geschäftsvorgang-Kennung)" -Type Text
Add-Field -List "SH11_Belege" -InternalName "related_person" -DisplayName "Bezug: Person" -Type Lookup `
    -LookupList "SH1_Personen" -LookupField "display_label"
Add-Field -List "SH11_Belege" -InternalName "related_activity" -DisplayName "Bezug: Managementtätigkeit" -Type Lookup `
    -LookupList "SH3_Managementtaetigkeiten" -LookupField "display_label"
Add-Field -List "SH11_Belege" -InternalName "related_location" -DisplayName "Bezug: Geschäftsraum/Bereich" -Type Lookup `
    -LookupList "SH4_Orte" -LookupField "display_label"
Add-Field -List "SH11_Belege" -InternalName "related_asset" -DisplayName "Bezug: Asset" -Type Lookup `
    -LookupList "SH5_Assets" -LookupField "display_label"
# related_person/related_activity/related_location/related_asset bleiben ohne
# -DeleteBehavior (Standard "None"), identisches Muster wie 8_Unterlagen: das
# Loeschen eines Kernobjekts soll nicht an einem angehaengten Beleg scheitern.
Add-Field -List "SH11_Belege" -InternalName "note" -DisplayName "Hinweis" -Type Note
Add-Field -List "SH11_Belege" -InternalName "required" -DisplayName "Erforderlich" -Type Boolean -DefaultValue "0"
Add-Field -List "SH11_Belege" -InternalName "uploaded" -DisplayName "Vorhanden / hochgeladen" -Type Boolean -DefaultValue "0"
Add-Field -List "SH11_Belege" -InternalName "file_link" -DisplayName "Link zur Datei (falls extern abgelegt)" -Type URL

Write-Host ""
Write-Host "Fertig. Alle 12 Substanzpruefungs-Listen (SH0-SH11) sind angelegt bzw. angeglichen."
Write-Host "Wiederverwendet (nicht neu angelegt, siehe Datenmodell Abschnitt 'Wiederverwendung'):"
Write-Host "  - 'Eingang_Fehler' (DE/AO) fuer fehlgeschlagene Formular-Uebernahmen dieses Moduls (Formular-Nr. 101-111)."
Write-Host "  - '4_Beteiligte_und_Quoten' (DE/AO) als Lookup-Ziel fuer Beteiligungsgesellschaft-Bezuege."
Write-Host "  - '3_Personen_und_Vertretung' und '5_Betriebsstaetten' (DE/AO) nur als optionale Cross-Reference-Lookups."
Write-Host "Falls diese Listen auf der Zielsite noch nicht existieren, zuerst DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 ausfuehren."
Write-Host "Naechster Schritt: siehe DE/Substanz-Holding-KG/sharepoint-forms/README.md, Abschnitt E (Forms-Einrichtung) und F (Freigabe/Rollout)."
