#Requires -Modules PnP.PowerShell
<#
    .SYNOPSIS
    Legt die SharePoint-Listenfamilie "Substanzpruefung Holding-KG" (20 Listen
    Erfassungen bis InterneBewertungen plus Dokumentbibliothek
    Substanznachweise) nach Anhang B2 des Erfassungsbogen-Entwurfs
    (Nils Obenhaus, 27.10.2026, Projekt 22032-2) an bzw. gleicht eine
    bestehende Installation an den aktuellen Feldkatalog an.

    ERSETZT die fruehere SH0-SH11-Modellierung (Update 1 von PR #18) vollstaendig.
    Nutzt zwei Listen der steuerlichen Erfassung (DE/AO) mit
    (Eingang_Fehler, 4_Beteiligte_und_Quoten) und referenziert zwei weitere
    optional (3_Personen_und_Vertretung, 5_Betriebsstaetten) -- siehe
    DE/Substanz-Holding-KG/Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md,
    Abschnitt "Wiederverwendung".

    Feldkatalog (B3, maschinenlesbar, einzige Quelle fuer dieses Skript):
      DE/Substanz-Holding-KG/feldkatalog/feldkatalog.json

    .DESCRIPTION
    Uebernimmt Parameter-, Verbindungs- und Idempotenzlogik unveraendert vom
    Vorbild DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 (PR #16):
      - Fehlende Listen/Spalten werden angelegt.
      - Bereits vorhandene Spalten werden ANGEGLICHEN (Anzeigename,
        Pflichtstatus, fehlende Auswahlwerte werden ERGAENZT, nie entfernt).
      - Es werden NIE Spalten, Listen oder Auswahlwerte geloescht.
      - Choice/MultiChoice-Spalten speichern STABILE CODES (z. B. FREQ_DAILY)
        als Wert, nicht die deutsche Beschriftung. Das Mapping Code -> Text
        steht im Feldkatalog (codebooks) und wird vom Power-Automate-Flow
        verwendet, um die in Forms gewaehlte deutsche Bezeichnung vor der
        Elementanlage in den stabilen Code zu uebersetzen (B3: "Mandant sieht
        deutsche Beschriftungen"; "unbekannt nie als 0" -- deshalb UNBEKANNT-
        Codes statt Boolean, wo die Vorgabe eine dritte Antwortmoeglichkeit
        neben Ja/Nein vorsieht).
      - InterneBewertungen erhaelt eigene, eingeschraenkte Berechtigungen
        (Rechtevererbung gebrochen); eine berechtigte Person muss danach
        manuell die zulaessige Pruefergruppe eintragen (siehe README.md).

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
    [string]$ClientId
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
      Bricht die Rechtevererbung einer Liste, damit sie NICHT mehr die
      Standard-Site-Berechtigungen erbt (Auftrag Punkt 2: InterneBewertungen
      braucht eingeschraenkte Berechtigungen). Das Skript kopiert zunaechst
      die bisherigen Zuweisungen (CopyRoleAssignments=$true), damit der Lauf
      niemanden sofort aussperrt; eine berechtigte Person MUSS danach manuell
      pruefen und nur die zulaessige Pruefergruppe stehen lassen (siehe
      sharepoint-forms/README.md, Abschnitt "InterneBewertungen").
      Idempotent: ueberspringt Listen, die bereits eigene Berechtigungen haben.
    #>
    param([Parameter(Mandatory = $true)][string]$List)
    try {
        $listObj = Get-PnPList -Identity $List -Includes HasUniqueRoleAssignments
        if ($listObj.HasUniqueRoleAssignments) {
            Write-Host "  Eigene Berechtigungen bereits gesetzt: $List"
            return
        }
        $ctx = Get-PnPContext
        $listObj.BreakRoleInheritance($true, $false)
        $ctx.ExecuteQuery()
        Write-Host "  Rechtevererbung gebrochen (Kopie der bisherigen Zuweisungen): $List"
        Write-Warning "  MANUELL NACHPRUEFEN: Nur die zulaessige interne Pruefergruppe darf auf '$List' Zugriff behalten (siehe README.md)."
    }
    catch {
        Write-Warning "  Konnte Rechtevererbung fuer '$List' nicht brechen: $_"
    }
}


# ---------------------------------------------------------------------------
# Liste: Erfassungen
# Fallsteuerung je Substanzpruefung (Vorbild: 0_Fallsteuerung, DE/AO; eigene Liste, Begruendung siehe Datenmodell)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Erfassungen"
Add-Field -List "Erfassungen" -InternalName "case_id" -DisplayName 'Fall-ID der Substanzprüfung (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
# case_id: Indiziert, eindeutig. Empfehlung: SH-JJJJ-NNNN.
Add-Field -List "Erfassungen" -InternalName "project_id" -DisplayName 'Projektkennung (z. B. 22032-2)' -Type Text
# project_id: Ergänzung über B2 hinaus: Mehrprojektfähigkeit derselben Site.
Add-Field -List "Erfassungen" -InternalName "period_from" -DisplayName 'Erfassungszeitraum - Beginn' -Type DateOnly -Required
Add-Field -List "Erfassungen" -InternalName "period_to" -DisplayName 'Erfassungszeitraum - Ende' -Type DateOnly
# period_to: Leer, falls Zeitraum noch läuft.
Add-Field -List "Erfassungen" -InternalName "reference_date" -DisplayName 'Stichtag (falls abweichend vom Zeitraum)' -Type DateOnly
Add-Field -List "Erfassungen" -InternalName "status" -DisplayName 'Status der Erfassung' -Type Choice -Required `
    -Choices @('ERFASSUNG_STATUS_OFFEN', 'ERFASSUNG_STATUS_IN_BEARBEITUNG', 'ERFASSUNG_STATUS_VOLLSTAENDIG', 'ERFASSUNG_STATUS_ABGESCHLOSSEN')
Add-Field -List "Erfassungen" -InternalName "completion_date" -DisplayName 'Abschlussdatum' -Type DateOnly
Add-Field -List "Erfassungen" -InternalName "version_number" -DisplayName 'Versionsnummer (Fortschreibung)' -Type Number
# version_number: Übernahmeschlüssel B4: ErfassungID+PersonID+Zeitraum+Version.
Add-Field -List "Erfassungen" -InternalName "compiler_name" -DisplayName 'Wer hat die Angaben zusammengestellt?' -Type Text -Required
Add-Field -List "Erfassungen" -InternalName "knowledgeable_contact" -DisplayName 'Fachlich auskunftsfähige Ansprechperson' -Type Text -Required
Add-Field -List "Erfassungen" -InternalName "processing_date" -DisplayName 'Datum der Bearbeitung' -Type DateOnly -Required
Add-Field -List "Erfassungen" -InternalName "confirmation_given" -DisplayName 'Bestätigung der Richtigkeit nach bestem Wissen' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
# confirmation_given: Fixtext: 'Die Angaben beschreiben die tatsächlichen Verhältnisse nach unserem derzeitigen Kenntnisstand. Schätzungen und geplante Tätigkeiten sind gekennzeichnet.' Als Ja/Nein-Haken umgesetzt (Boolean), da hier echte Bestätigung statt Status gefragt ist.
Add-Field -List "Erfassungen" -InternalName "reconciliation_status" -DisplayName 'Stimmen Angaben, Buchhaltung und Abrechnung überein?' -Type Choice -Required `
    -Choices @('C06_STATUS_JA', 'C06_STATUS_TEILWEISE', 'C06_STATUS_NEIN', 'C06_STATUS_NOCH_NICHT_ABGESTIMMT')
Add-Field -List "Erfassungen" -InternalName "reconciliation_notes" -DisplayName 'Differenzen, unentgeltliche Bereitstellungen, offene Erstattungen' -Type Note
Add-Field -List "Erfassungen" -InternalName "reconciliation_related_costs_text" -DisplayName 'Betroffene Kostenpositionen (Bezeichnung/ID)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Gesellschaften
# Bekannter Gesellschaftsbestand (Rolle), keine neue Strukturerhebung - Beteiligungsverhaeltnisse werden nicht abgefragt
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Gesellschaften"
Add-Field -List "Gesellschaften" -InternalName "company_id" -DisplayName 'Gesellschafts-ID (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "Gesellschaften" -InternalName "project_id_text" -DisplayName 'Projektkennung (Mehrprojektfähigkeit)' -Type Text
# project_id_text: Ergänzung über B2 hinaus.
Add-Field -List "Gesellschaften" -InternalName "company_name" -DisplayName 'Bekannter Name der Gesellschaft' -Type Text -Required
Add-Field -List "Gesellschaften" -InternalName "company_role" -DisplayName 'Rolle im vorhandenen Bestand' -Type Choice -Required `
    -Choices @('GESELLSCHAFT_ROLLE_HOLDING_KG', 'GESELLSCHAFT_ROLLE_BETEILIGUNG', 'GESELLSCHAFT_ROLLE_SCHWEIZER_MUTTER', 'GESELLSCHAFT_ROLLE_ANDERE', 'GESELLSCHAFT_ROLLE_UNBEKANNT')
# company_role: Keine neue Strukturerhebung - Beteiligungsverhältnisse werden nicht abgefragt.
Add-Field -List "Gesellschaften" -InternalName "ao_participation_ref" -DisplayName 'Bezug: bereits in der steuerlichen Erfassung geführte Beteiligung (DE/AO, optional)' -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"

# ---------------------------------------------------------------------------
# Liste: Substanznachweise
# Dokumentbibliothek fuer Belege/Nachweise (B5: Datei-Upload nicht ueber Forms)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Substanznachweise" -Template "DocumentLibrary"
Add-Field -List "Substanznachweise" -InternalName "nachweis_id" -DisplayName 'Nachweis-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Substanznachweise" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Substanznachweise" -InternalName "dokumentdatum" -DisplayName 'Dokumentdatum' -Type DateOnly
Add-Field -List "Substanznachweise" -InternalName "gesellschaft_ref" -DisplayName 'Betroffene Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Substanznachweise" -InternalName "dokumentart" -DisplayName 'Dokumentart' -Type Choice -Required `
    -Choices @('N02_UNTERLAGENART_VERTRAG', 'N02_UNTERLAGENART_VOLLMACHT', 'N02_UNTERLAGENART_EMAIL_VERLAUF', 'N02_UNTERLAGENART_KALENDER_NOTIZ', 'N02_UNTERLAGENART_BERICHT_PLANUNG', 'N02_UNTERLAGENART_BESCHLUSS_FREIGABE', 'N02_UNTERLAGENART_ARBEITSPRODUKT', 'N02_UNTERLAGENART_ZEITERFASSUNG', 'N02_UNTERLAGENART_RECHNUNG_BUCHUNG', 'N02_UNTERLAGENART_ZAHLUNG', 'N02_UNTERLAGENART_RAUM_GERAETENACHWEIS', 'N02_UNTERLAGENART_SONSTIGE_UNTERLAGE', 'N02_UNTERLAGENART_KEIN_BELEG', 'N02_UNTERLAGENART_WIRD_NACHGEREICHT')
Add-Field -List "Substanznachweise" -InternalName "dateilink" -DisplayName 'Link zur Datei, falls extern abgelegt' -Type URL
# dateilink: B5: Datei-Upload nicht über Forms, sondern separater Kanzlei-Uploadweg + Anlagenreferenz/Dateiname im Formular.
Add-Field -List "Substanznachweise" -InternalName "nachreichstatus" -DisplayName 'Nachreichstatus' -Type Choice -Required `
    -Choices @('ALLG_STATUS_NICHT_BEKANNT', 'ALLG_STATUS_NICHT_VORHANDEN', 'ALLG_STATUS_WIRD_NACHGEREICHT', 'ALLG_STATUS_NICHT_ZUTREFFEND', 'ALLG_STATUS_VORHANDEN')

# ---------------------------------------------------------------------------
# Liste: Personen
# Personen, die fuer die Holding-KG taetig sind (P01-P02 Uebersicht)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personen"
Add-Field -List "Personen" -InternalName "person_name" -DisplayName 'Wie heisst die Person?' -Type Text -Required
# person_name: Bereits bekannte Personen können ausgewählt werden (vorbereiteter Bestand).
Add-Field -List "Personen" -InternalName "functions_overview" -DisplayName 'Welche Funktion oder Stellenbezeichnung hat die Person? (Übersicht)' -Type MultiChoice -Required `
    -Choices @('P02_FUNKTION_GESCHAEFTSFUEHRER', 'P02_FUNKTION_VORSTAND', 'P02_FUNKTION_VERWALTUNGSRAT', 'P02_FUNKTION_CFO', 'P02_FUNKTION_KAUFM_LEITUNG', 'P02_FUNKTION_PERSONALVERANTWORTLICHER', 'P02_FUNKTION_BEREICHS_PROJEKTLEITUNG', 'P02_FUNKTION_SACHBEARBEITUNG', 'P02_FUNKTION_EXTERNER_BERATER', 'P02_FUNKTION_ANDERE')
# functions_overview: Je Funktion die betreffende Gesellschaft gesondert in Personenbindungen.
Add-Field -List "Personen" -InternalName "functions_other_text" -DisplayName 'Andere Funktion - bitte benennen' -Type Text
Add-Field -List "Personen" -InternalName "person_id" -DisplayName 'Person-ID (intern vergeben)' -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "Personen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Personenbindungen
# Vertragliche Bindung je Person x Gesellschaft (P02 je Funktion, P03-P05)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personenbindungen"
Add-Field -List "Personenbindungen" -InternalName "bindung_id" -DisplayName 'Bindungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Personenbindungen" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personenbindungen" -InternalName "funktion_code" -DisplayName 'Funktion für diese Gesellschaft' -Type Choice `
    -Choices @('P02_FUNKTION_GESCHAEFTSFUEHRER', 'P02_FUNKTION_VORSTAND', 'P02_FUNKTION_VERWALTUNGSRAT', 'P02_FUNKTION_CFO', 'P02_FUNKTION_KAUFM_LEITUNG', 'P02_FUNKTION_PERSONALVERANTWORTLICHER', 'P02_FUNKTION_BEREICHS_PROJEKTLEITUNG', 'P02_FUNKTION_SACHBEARBEITUNG', 'P02_FUNKTION_EXTERNER_BERATER', 'P02_FUNKTION_ANDERE')
Add-Field -List "Personenbindungen" -InternalName "funktion_andere_text" -DisplayName 'Andere Funktion - bitte benennen' -Type Text
Add-Field -List "Personenbindungen" -InternalName "company_ref" -DisplayName 'Bei welcher Gesellschaft oder welchem Auftraggeber besteht eine Anstellung oder andere vertragliche Bindung?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
# company_ref: Auswahl je Vertragsverhältnis; bei mehreren Bindungen je ein Personenbindungen-Datensatz.
Add-Field -List "Personenbindungen" -InternalName "company_status" -DisplayName 'Status, falls keine konkrete Gesellschaft zutrifft' -Type Choice `
    -Choices @('GESELLSCHAFT_STATUS_ANDERE', 'GESELLSCHAFT_STATUS_KEINE', 'GESELLSCHAFT_STATUS_UNBEKANNT', 'GESELLSCHAFT_STATUS_NICHT_EINDEUTIG')
# company_status: Belegt 'keine vertragliche Bindung'/'nicht bekannt', wenn GesellschaftRef leer bleibt.
Add-Field -List "Personenbindungen" -InternalName "basis_code" -DisplayName 'Auf welcher Grundlage arbeitet die Person?' -Type Choice -Required `
    -Choices @('P04_GRUNDLAGE_ARBEITSVERTRAG', 'P04_GRUNDLAGE_GF_VORSTANDSVERTRAG', 'P04_GRUNDLAGE_MANDATS_DIENSTLEISTUNGSVERTRAG', 'P04_GRUNDLAGE_GESELLSCHAFTER_OHNE_DIENSTVERTRAG', 'P04_GRUNDLAGE_ANDERE_VEREINBARUNG', 'P04_GRUNDLAGE_NUR_MUENDLICH', 'P04_GRUNDLAGE_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "basis_other_text" -DisplayName 'Andere Vereinbarung - bitte benennen' -Type Text
Add-Field -List "Personenbindungen" -InternalName "contract_status" -DisplayName 'Liegt dazu ein schriftlicher Vertrag vor?' -Type Choice -Required `
    -Choices @('P05_VERTRAGSSTATUS_UNTERZEICHNET', 'P05_VERTRAGSSTATUS_NUR_ENTWURF', 'P05_VERTRAGSSTATUS_VORHANDEN_NICHT_VERFUEGBAR', 'P05_VERTRAGSSTATUS_KEIN_VERTRAG', 'P05_VERTRAGSSTATUS_UNBEKANNT')
Add-Field -List "Personenbindungen" -InternalName "evidence_ref" -DisplayName 'Vertrag, Nachträge, Stellenbeschreibung, Vereinbarung zum Einsatz bei anderen Gesellschaften' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
# evidence_ref: Anlagenreferenz; Datei-Upload separat (B5), nicht über Forms.
Add-Field -List "Personenbindungen" -InternalName "contract_start" -DisplayName 'Vertragsbeginn' -Type DateOnly
Add-Field -List "Personenbindungen" -InternalName "contract_end" -DisplayName 'Vertragsende, falls bekannt' -Type DateOnly
Add-Field -List "Personenbindungen" -InternalName "actual_start_date" -DisplayName 'Seit wann übernimmt die Person tatsächlich Aufgaben im Zusammenhang mit der KG?' -Type DateOnly -Required
Add-Field -List "Personenbindungen" -InternalName "actual_start_precision" -DisplayName 'Datum genau oder ungefähr bekannt?' -Type Choice -Required `
    -Choices @('GENAUIGKEIT_GENAU', 'GENAUIGKEIT_UNGEFAEHR')
Add-Field -List "Personenbindungen" -InternalName "task_change_text" -DisplayName 'Beginn und Ende je Aufgabenbereich bei Wechsel' -Type Note
Add-Field -List "Personenbindungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Personeneinsaetze
# Arbeitszeit, Weisungsgeber, Vertretung, Praesenz je Person (P06-P08, P19-P20, P23-P24)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Personeneinsaetze"
Add-Field -List "Personeneinsaetze" -InternalName "einsatz_id" -DisplayName 'Einsatz-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Personeneinsaetze" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Personeneinsaetze" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personeneinsaetze" -InternalName "weisungsgeber_ref" -DisplayName 'Wer legt im Arbeitsalltag die Aufgaben und Prioritäten dieser Person fest?' -Type LookupMulti `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personeneinsaetze" -InternalName "weisungsgeber_status" -DisplayName 'Status, falls keine konkrete Person zutrifft' -Type Choice `
    -Choices @('PERSON_STATUS_ANDERE', 'PERSON_STATUS_MEHRERE', 'PERSON_STATUS_KEINE', 'PERSON_STATUS_WECHSELND', 'PERSON_STATUS_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "weisungsgeber_text" -DisplayName 'Wer kann Anweisungen geben, Abwesenheiten genehmigen, Arbeit beurteilen?' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "vertretung_ref" -DisplayName 'Wer vertritt die Person bei Abwesenheit?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Personeneinsaetze" -InternalName "vertretung_status" -DisplayName 'Status, falls keine konkrete Vertretung zutrifft' -Type Choice `
    -Choices @('P08_VERTRETUNG_BENANNT', 'P08_VERTRETUNG_WECHSELND', 'P08_VERTRETUNG_KEINE', 'P08_VERTRETUNG_UNBEKANNT')
Add-Field -List "Personeneinsaetze" -InternalName "liegengebliebene_aufgaben_text" -DisplayName 'Welche Aufgaben bleiben gegebenenfalls liegen?' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "overall_frequency" -DisplayName 'Wie häufig arbeitet die Person insgesamt an Aufgaben im Zusammenhang mit der KG?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NONE')
# overall_frequency: Codes: FREQ_DAILY, FREQ_MULTI_WEEK, FREQ_WEEKLY, FREQ_MONTHLY, FREQ_ON_DEMAND, FREQ_NONE.
Add-Field -List "Personeneinsaetze" -InternalName "total_hours" -DisplayName 'Gesamte Wochenstunden oder gesamte Stunden im Bezugszeitraum' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_hours" -DisplayName 'Davon Stunden im Auftrag der KG' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "kg_share_pct" -DisplayName 'Daraus ungefährer Prozentanteil' -Type Number `
    -Min 0 `
    -Max 100
Add-Field -List "Personeneinsaetze" -InternalName "basis_code" -DisplayName 'Grundlage der Angabe' -Type Choice `
    -Choices @('NUTZUNGSGRUNDLAGE_AUFZEICHNUNG', 'NUTZUNGSGRUNDLAGE_SCHAETZUNG', 'NUTZUNGSGRUNDLAGE_ANDERE_GRUNDLAGE')
Add-Field -List "Personeneinsaetze" -InternalName "separate_activity_text" -DisplayName 'Eigene Tätigkeiten für Beteiligungen ausserhalb eines KG-Auftrags' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "office_frequency" -DisplayName 'Wie häufig und wie lange arbeitet die Person tatsächlich im KG-Büro?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NONE')
# office_frequency: Codes: FREQ_DAILY, FREQ_MULTI_WEEK, FREQ_WEEKLY, FREQ_MONTHLY, FREQ_RARELY, FREQ_NEVER.
Add-Field -List "Personeneinsaetze" -InternalName "office_days_per_month" -DisplayName 'Ungefähre Tage im Monat im KG-Büro' -Type Number `
    -Min 0 `
    -Max 31
Add-Field -List "Personeneinsaetze" -InternalName "office_hours_per_visit" -DisplayName 'Stunden je Anwesenheit im KG-Büro' -Type Number
Add-Field -List "Personeneinsaetze" -InternalName "office_typical_tasks_text" -DisplayName 'Typische Tätigkeiten im KG-Büro' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "variation_type" -DisplayName 'Gibt es erhebliche zeitliche Schwankungen oder Änderungen?' -Type Choice -Required `
    -Choices @('P24_AENDERUNG_NEIN', 'P24_AENDERUNG_SAISONAL', 'P24_AENDERUNG_PROJEKTBEDINGT', 'P24_AENDERUNG_FUNKTIONSWECHSEL', 'P24_AENDERUNG_ANDERE')
Add-Field -List "Personeneinsaetze" -InternalName "variation_text" -DisplayName 'Betroffene Zeiträume und abweichende Stunden oder Orte' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "travel_time_text" -DisplayName 'Reisezeiten (gesondert, nicht als Arbeitszeit am Zielort)' -Type Note
Add-Field -List "Personeneinsaetze" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Orte
# Standortkatalog (P16/P22 referenzieren; R-Block fuer Raeume separat)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Orte"
Add-Field -List "Orte" -InternalName "ort_id" -DisplayName 'Ort-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Orte" -InternalName "ort_kategorie" -DisplayName 'Ortskategorie' -Type Choice -Required `
    -Choices @('ORT_KATEGORIE_KG_BUERO', 'ORT_KATEGORIE_BETEILIGUNG_RAEUME', 'ORT_KATEGORIE_HOMEOFFICE', 'ORT_KATEGORIE_SCHWEIZER_RAEUME', 'ORT_KATEGORIE_UNTERWEGS_GESCHAEFTSPARTNER', 'ORT_KATEGORIE_ANDERER_ORT')
Add-Field -List "Orte" -InternalName "standortgesellschaft_ref" -DisplayName 'Standortgesellschaft, soweit zutreffend' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Orte" -InternalName "adresse" -DisplayName 'Adresse bzw. Ort und Land' -Type Note
Add-Field -List "Orte" -InternalName "land" -DisplayName 'Land' -Type Text
Add-Field -List "Orte" -InternalName "nutzungsbereich" -DisplayName 'Bezeichnung des Nutzungsbereichs (z. B. ''Büro 2'', ''Homeoffice MA X'')' -Type Text
Add-Field -List "Orte" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Taetigkeiten
# Zentrale Verknuepfungsliste Person x Taetigkeit x Beteiligung (P09-P18; G01-G05, K01-K03/K05 Unterstruktur)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Taetigkeiten"
Add-Field -List "Taetigkeiten" -InternalName "taetigkeit_id" -DisplayName 'Tätigkeits-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Taetigkeiten" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Taetigkeiten" -InternalName "person_ref" -DisplayName 'Bezug: Person' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "bereich_code" -DisplayName 'In welchem Bereich arbeitet die Person tatsächlich? (steuert Folgefragen)' -Type Choice -Required `
    -Choices @('P09_BEREICH_KUNDEN_VERTRIEB', 'P09_BEREICH_EINKAUF_LIEFERANTEN', 'P09_BEREICH_PERSONAL', 'P09_BEREICH_FINANZEN_LIQUID', 'P09_BEREICH_BUCHFUEHRUNG_STEUERN', 'P09_BEREICH_PROJEKTE_BETRIEB', 'P09_BEREICH_PLANUNG_INVESTITIONEN', 'P09_BEREICH_BERICHTE_KONTROLLE', 'P09_BEREICH_VORGABEN_SCHULUNG', 'P09_BEREICH_EIGENE_ORGANISATION', 'P09_BEREICH_BETEILIGUNGS_GESELLSCHAFTER', 'P09_BEREICH_SCHWEIZER_MUTTER', 'P09_BEREICH_ANDERE', 'P09_BEREICH_KEINE_NUR_GEPLANT')
# bereich_code: Je Bereich eigener Taetigkeiten-Datensatz; 'nur geplant'/'keine Aufgaben' statt erfundener Details.
Add-Field -List "Taetigkeiten" -InternalName "bereich_andere_text" -DisplayName 'Andere Aufgaben - bitte benennen' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "handlung_code" -DisplayName 'Welche konkrete Tätigkeit wird erfasst? (Handlung aus der Handlungstabelle des gewählten Bereichs)' -Type Choice `
    -Choices @('P09_HANDLUNG_KUNDEN_VERTRIEB_01_KUNDENKONTAKTE_ANBAHNEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_02_KUNDEN_BETREUEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_03_ANGEBOTE_AUSARBEITEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_04_PREISE_UND_RABATTE_BESTIMMEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_05_LEISTUNGSUMFANG_UND_TERMINE_VERHANDELN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_06_VERTRAGSBEDINGUNGEN_AUSHANDELN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_07_AUFTRAEGE_ANNEHMEN_ODER_ABLEHNEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_08_REKLAMATIONEN_LOESEN', 'P09_HANDLUNG_KUNDEN_VERTRIEB_09_VERTRIEBSMITARBEITERN_KONKRETE_AUFGABEN_GEBEN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_01_BEDARF_FESTSTELLEN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_02_ANGEBOTE_EINHOLEN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_03_LIEFERANTEN_AUSWAEHLEN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_04_PREISE_MENGEN_UND_LIEFERBEDINGUNGEN_VERHANDELN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_05_BESTELLUNGEN_FREIGEBEN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_06_VERTRAEGE_AUSHANDELN', 'P09_HANDLUNG_EINKAUF_LIEFERANTEN_07_LIEFERPROBLEME_ENTSCHEIDEN', 'P09_HANDLUNG_PERSONAL_01_PERSONALBEDARF_PLANEN', 'P09_HANDLUNG_PERSONAL_02_BEWERBER_SUCHEN_UND_AUSWAEHLEN', 'P09_HANDLUNG_PERSONAL_03_VORSTELLUNGSGESPRAECHE_FUEHREN', 'P09_HANDLUNG_PERSONAL_04_VERGUETUNG_UND_VERTRAGSBEDINGUNGEN_VERHANDELN', 'P09_HANDLUNG_PERSONAL_05_EINSTELLUNGEN_ODER_KUENDIGUNGEN_ENTSCHEIDEN', 'P09_HANDLUNG_PERSONAL_06_ARBEITSVERTRAEGE_VORBEREITEN', 'P09_HANDLUNG_PERSONAL_07_ARBEITSVERTRAEGE_UNTERZEICHNEN', 'P09_HANDLUNG_PERSONAL_08_ZIELE_UND_AUFGABEN_FESTLEGEN', 'P09_HANDLUNG_PERSONAL_09_ARBEITSEINSAETZE_UND_URLAUB_GENEHMIGEN', 'P09_HANDLUNG_PERSONAL_10_LEISTUNG_BEURTEILEN', 'P09_HANDLUNG_FINANZEN_LIQUID_01_LIQUIDITAET_PLANEN', 'P09_HANDLUNG_FINANZEN_LIQUID_02_ZAHLUNGEN_PRIORISIEREN_ODER_FREIGEBEN', 'P09_HANDLUNG_FINANZEN_LIQUID_03_FORDERUNGEN_VERFOLGEN', 'P09_HANDLUNG_FINANZEN_LIQUID_04_BANKGESPRAECHE_FUEHREN', 'P09_HANDLUNG_FINANZEN_LIQUID_05_KREDIT_UND_SICHERHEITENBEDINGUNGEN_VERHANDELN', 'P09_HANDLUNG_FINANZEN_LIQUID_06_FINANZIERUNGSVORSCHLAEGE_VERGLEICHEN', 'P09_HANDLUNG_FINANZEN_LIQUID_07_KREDITE_AUSWAEHLEN', 'P09_HANDLUNG_FINANZEN_LIQUID_08_FINANZIERUNG_UEBERWACHEN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_01_BELEGE_BEARBEITEN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_02_MONATS_ODER_JAHRESABSCHLUSS_VORBEREITEN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_03_BUCHHALTER_UND_STEUERBERATER_BEAUFTRAGEN_ODER_STEUERN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_04_SACHVERHALTE_ERLAEUTERN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_05_STEUERLICHE_WAHLMOEGLICHKEITEN_ZUR_ENTSCHEIDUNG_VORLEGE', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_06_ENTSCHEIDUNGEN_NACH_BERATUNG_TREFFEN', 'P09_HANDLUNG_BUCHFUEHRUNG_STEUERN_07_FRISTEN_UEBERWACHEN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_01_KAPAZITAETEN_UND_TERMINE_PLANEN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_02_PROJEKTE_LEITEN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_03_MITARBEITEREINSATZ_BESTIMMEN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_04_QUALITAET_UND_LEISTUNGSERBRINGUNG_STEUERN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_05_KONKRETE_PROBLEME_LOESEN', 'P09_HANDLUNG_PROJEKTE_BETRIEB_06_LEISTUNGEN_ODER_ERGEBNISSE_ABNEHMEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_01_UNTERNEHMENSPLANUNG_ERSTELLEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_02_BUDGETS_ERARBEITEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_03_BUDGETS_FREIGEBEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_04_INVESTITIONEN_PRUEFEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_05_INVESTITIONEN_AUSWAEHLEN_ODER_FREIGEBEN', 'P09_HANDLUNG_PLANUNG_INVESTITIONEN_06_UMSETZUNG_UEBERWACHEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_01_KENNZAHLEN_SAMMELN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_02_BERICHTE_ERSTELLEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_03_BERICHTE_PRUEFEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_04_ABWEICHUNGEN_ERKLAEREN_LASSEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_05_GESCHAEFTSLEITUNG_BEFRAGEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_06_EINHALTUNG_VON_VORGABEN_PRUEFEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_07_MASSNAHMEN_EMPFEHLEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_08_KONKRETE_KORREKTURMASSNAHMEN_ANORDNEN', 'P09_HANDLUNG_BERICHTE_KONTROLLE_09_UMSETZUNG_VERFOLGEN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_01_ALLGEMEINE_RICHTLINIEN_ENTWERFEN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_02_RICHTLINIEN_BESCHLIESSEN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_03_KONKRETE_EINZELANWEISUNGEN_GEBEN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_04_MITARBEITENDE_FACHLICH_BERATEN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_05_SCHULUNGEN_KONZIPIEREN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_06_SCHULUNGEN_DURCHFUEHREN', 'P09_HANDLUNG_VORGABEN_SCHULUNG_07_UMSETZUNG_IN_EINZELNEN_VORGAENGEN_BEGLEITEN', 'P09_HANDLUNG_EIGENE_ORGANISATION_01_EIGENE_BUCHFUEHRUNG', 'P09_HANDLUNG_EIGENE_ORGANISATION_02_EIGENE_STEUERANGELEGENHEITEN', 'P09_HANDLUNG_EIGENE_ORGANISATION_03_EIGENE_BANKKONTEN_UND_ZAHLUNGEN', 'P09_HANDLUNG_EIGENE_ORGANISATION_04_EIGENES_PERSONAL', 'P09_HANDLUNG_EIGENE_ORGANISATION_05_EIGENE_RAEUME_UND_AUSSTATTUNG', 'P09_HANDLUNG_EIGENE_ORGANISATION_06_EIGENE_IT', 'P09_HANDLUNG_EIGENE_ORGANISATION_07_EIGENE_MANAGEMENTVERTRAEGE_UND_ABRECHNUNGEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_01_BETEILIGUNGEN_UEBERWACHEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_02_ERWERB_ODER_VERKAUF_VON_BETEILIGUNGEN_VORBEREITEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_03_STIMMRECHTSAUSUEBUNG_VORBEREITEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_04_GESELLSCHAFTERBESCHLUESSE_VORBEREITEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_05_ALS_VERTRETER_EINES_GESELLSCHAFTERS_ABSTIMMEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_06_AUSSCHUETTUNGSENTSCHEIDUNGEN_VORBEREITEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_07_KAPITALMASSNAHMEN_VORBEREITEN', 'P09_HANDLUNG_BETEILIGUNGS_GESELLSCHAFTER_08_ORGANBESTELLUNGEN_VORBEREITEN', 'P09_HANDLUNG_SCHWEIZER_MUTTER_01_UNTERLAGEN_FUER_DEREN_EIGENEN_ABSCHLUSS_ODER_STEUERERKL', 'P09_HANDLUNG_SCHWEIZER_MUTTER_02_UNTERLAGEN_FUER_KONZERNABSCHLUSS_AUFBEREITEN', 'P09_HANDLUNG_SCHWEIZER_MUTTER_03_DEREN_GESELLSCHAFTER_ODER_VERWALTUNGSRATSSITZUNGEN_VORB', 'P09_HANDLUNG_SCHWEIZER_MUTTER_04_DEREN_INVESTOREN_ODER_FINANZIERER_INFORMIEREN', 'P09_HANDLUNG_SCHWEIZER_MUTTER_05_DEREN_BETEILIGUNGSERWERB_FINANZIEREN', 'P09_HANDLUNG_SCHWEIZER_MUTTER_06_SONSTIGE_KONKRETE_ARBEITEN_BENENNEN')
# handlung_code: Forms zeigt je gewähltem Bereich nur die passenden Handlungen (siehe sharepoint-forms/README.md).
Add-Field -List "Taetigkeiten" -InternalName "activity_text" -DisplayName 'Beschreibung der konkreten Tätigkeit (nicht nur ''Management'' oder ''Controlling'')' -Type Note -Required
Add-Field -List "Taetigkeiten" -InternalName "empfaenger_ref" -DisplayName 'Für welche Gesellschaft wird die Tätigkeit ausgeführt / wer nutzt das Ergebnis unmittelbar?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Taetigkeiten" -InternalName "empfaenger_status" -DisplayName 'Status, falls kein eindeutiger Empfänger zutrifft' -Type Choice `
    -Choices @('GESELLSCHAFT_STATUS_ANDERE', 'GESELLSCHAFT_STATUS_KEINE', 'GESELLSCHAFT_STATUS_UNBEKANNT', 'GESELLSCHAFT_STATUS_NICHT_EINDEUTIG')
# empfaenger_status: Belegt u. a. 'andere Gesellschaft'/'nicht eindeutig'.
Add-Field -List "Taetigkeiten" -InternalName "mehrere_empfaenger_text" -DisplayName 'Bei mehreren unmittelbaren Empfängern: Aufteilung oder gemeinsame Nutzung erläutern' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "auftrag_funktion" -DisplayName 'In wessen Auftrag und in welcher Funktion handelt die Person dabei?' -Type Choice -Required `
    -Choices @('P12_FUNKTION_AUFTRAG_KG', 'P12_FUNKTION_AUFTRAG_BETEILIGUNG', 'P12_FUNKTION_AUFTRAG_SCHWEIZER_MUTTER', 'P12_FUNKTION_EIGENE_ORGANFUNKTION', 'P12_FUNKTION_VERTRETER_GESELLSCHAFTER', 'P12_FUNKTION_ANDERE', 'P12_FUNKTION_UNBEKANNT')
Add-Field -List "Taetigkeiten" -InternalName "auftraggeber_person_ref" -DisplayName 'Auftraggebende Person' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "auftraggeber_gesellschaft_ref" -DisplayName 'Auftraggebende Gesellschaft' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Taetigkeiten" -InternalName "handlungstyp" -DisplayName 'Was macht die Person bei dieser Tätigkeit?' -Type MultiChoice -Required `
    -Choices @('P13_HANDLUNGSTYP_INFO_SAMMELN', 'P13_HANDLUNGSTYP_VORSCHLAG_ERARBEITEN', 'P13_HANDLUNGSTYP_VERHANDLUNGEN_FUEHREN', 'P13_HANDLUNGSTYP_VERBINDLICHE_VORGABEN', 'P13_HANDLUNGSTYP_SELBST_ENTSCHEIDEN', 'P13_HANDLUNGSTYP_FREMDE_ENTSCHEIDUNG_UMSETZEN', 'P13_HANDLUNGSTYP_KONTROLLE_ARBEIT_ANDERER', 'P13_HANDLUNGSTYP_BERATEN_SCHULEN', 'P13_HANDLUNGSTYP_NUR_BERICHTEN')
Add-Field -List "Taetigkeiten" -InternalName "ablauf_text" -DisplayName 'Ablauf bei mehreren Schritten' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "verwendungszweck" -DisplayName 'Wofür wird das Ergebnis konkret verwendet?' -Type MultiChoice -Required `
    -Choices @('P14_VERWENDUNGSZWECK_KUNDENAUFTRAG', 'P14_VERWENDUNGSZWECK_EINKAUF_LIEFERANTENVERTRAG', 'P14_VERWENDUNGSZWECK_PERSONALENTSCHEIDUNG', 'P14_VERWENDUNGSZWECK_FINANZIERUNG_ZAHLUNG', 'P14_VERWENDUNGSZWECK_BETRIEBLICHE_PLANUNG_UMSETZUNG', 'P14_VERWENDUNGSZWECK_KONTROLLE_GESCHAEFTSLEITUNG', 'P14_VERWENDUNGSZWECK_VERWALTUNG_KG_SELBST', 'P14_VERWENDUNGSZWECK_STIMMRECHTE_GESELLSCHAFTERBESCHLUESSE', 'P14_VERWENDUNGSZWECK_ABSCHLUSS_BERICHT_SCHWEIZER_MUTTER', 'P14_VERWENDUNGSZWECK_ANDERER_ZWECK')
Add-Field -List "Taetigkeiten" -InternalName "verwendung_beispiel_text" -DisplayName 'Kurzes Beispiel zur Verwendung' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "activity_start" -DisplayName 'Seit wann erfolgt diese Tätigkeit?' -Type DateOnly -Required
Add-Field -List "Taetigkeiten" -InternalName "activity_end" -DisplayName 'Bis wann, falls beendet' -Type DateOnly
Add-Field -List "Taetigkeiten" -InternalName "frequency" -DisplayName 'Wie häufig erfolgt diese Tätigkeit?' -Type Choice -Required `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NONE')
# frequency: Volle Skala FREQ_DAILY..FREQ_ONCE.
Add-Field -List "Taetigkeiten" -InternalName "hours" -DisplayName 'Stunden im Bezugszeitraum' -Type Number
Add-Field -List "Taetigkeiten" -InternalName "is_estimate" -DisplayName 'Schätzung (statt exakter Wert)?' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Taetigkeiten" -InternalName "ergebnis_text" -DisplayName 'Welches konkrete Ergebnis ist im Bezugszeitraum entstanden?' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "ergebnis_datum" -DisplayName 'Datum des Ergebnisses' -Type DateOnly
Add-Field -List "Taetigkeiten" -InternalName "ergebnis_empfaenger_text" -DisplayName 'Empfänger des Ergebnisses' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "kein_fall_im_zeitraum" -DisplayName 'Kein tatsächlicher Fall im Zeitraum' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Taetigkeiten" -InternalName "ergebnis_nachweis_ref" -DisplayName 'Vorhandene Unterlagen' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "zusatz_erbringer" -DisplayName 'Wer erbringt dieselbe oder eine ähnliche Arbeit zusätzlich?' -Type Choice -Required `
    -Choices @('P18_ERBRINGER_NIEMAND', 'P18_ERBRINGER_INTERNE_PERSON', 'P18_ERBRINGER_EXTERNER_DIENSTLEISTER', 'P18_ERBRINGER_UNBEKANNT')
Add-Field -List "Taetigkeiten" -InternalName "zusatz_person_ref" -DisplayName 'Zusätzliche interne Person' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "zusatz_gesellschaft_text" -DisplayName 'Externer Dienstleister / Gesellschaft' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "zusatz_ergaenzung_text" -DisplayName 'Was ergänzt die Person konkret, welches zusätzliche Ergebnis entsteht?' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "zusatz_nur_berichtspflicht_mutter" -DisplayName 'Ergebnis ausschliesslich für Berichtspflichten der Mutter angefordert' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Taetigkeiten" -InternalName "g04_ergebnistyp" -DisplayName 'Was entsteht aus den Arbeiten für die Schweizer Mutter?' -Type MultiChoice `
    -Choices @('G04_ERGEBNISTYP_EINZELABSCHLUSS', 'G04_ERGEBNISTYP_KONZERNABSCHLUSS', 'G04_ERGEBNISTYP_INFORMATIONSBERICHT', 'G04_ERGEBNISTYP_BESCHLUSSVORLAGE', 'G04_ERGEBNISTYP_FINANZIERUNG', 'G04_ERGEBNISTYP_OPERATIVE_ENTSCHEIDUNG', 'G04_ERGEBNISTYP_ANDERES_ERGEBNIS')
# g04_ergebnistyp: Nur bei bereich_code=SCHWEIZER_MUTTER relevant.
Add-Field -List "Taetigkeiten" -InternalName "g04_mehrfachnutzung_text" -DisplayName 'Unterschiedliche Verwendungen bei Mehrfachnutzung von Unterlagen' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "g05_alternative" -DisplayName 'Wer würde die Arbeit erledigen, wenn die KG sie nicht übernähme?' -Type Choice `
    -Choices @('G05_ALTERNATIVE_BETEILIGUNG_SELBST', 'G05_ALTERNATIVE_SCHWEIZER_MUTTER', 'G05_ALTERNATIVE_ANDERER_INTERNER_BEREICH', 'G05_ALTERNATIVE_EXTERNER_DIENSTLEISTER', 'G05_ALTERNATIVE_ENTFAELLT', 'G05_ALTERNATIVE_UNBEKANNT')
# g05_alternative: Nur bei bereich_code=BETEILIGUNGS_GESELLSCHAFTER oder SCHWEIZER_MUTTER relevant; keine rechtliche Beurteilung.
Add-Field -List "Taetigkeiten" -InternalName "g05_text" -DisplayName 'Tatsächliche Vertretung oder bisherige Handhabung' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "k01_gegenstand" -DisplayName 'Was wird geprüft oder überwacht?' -Type MultiChoice `
    -Choices @('K01_GEGENSTAND_GESCHAEFTSERGEBNIS', 'K01_GEGENSTAND_BUDGET', 'K01_GEGENSTAND_LIQUIDITAET', 'K01_GEGENSTAND_PROJEKTE', 'K01_GEGENSTAND_PERSONAL', 'K01_GEGENSTAND_EINHALTUNG_VORGABEN', 'K01_GEGENSTAND_TAETIGKEIT_GESCHAEFTSLEITUNG', 'K01_GEGENSTAND_WERTENTWICKLUNG_BETEILIGUNG', 'K01_GEGENSTAND_ANDERES')
# k01_gegenstand: Nur bei bereich_code=BERICHTE_KONTROLLE relevant; betroffene Gesellschaft = empfaenger_ref.
Add-Field -List "Taetigkeiten" -InternalName "k02_reaktion" -DisplayName 'Was geschieht bei einer Abweichung tatsächlich?' -Type MultiChoice `
    -Choices @('K02_REAKTION_BERICHT_ZUR_KENNTNIS', 'K02_REAKTION_ERLAEUTERUNG_ANGEFORDERT', 'K02_REAKTION_EMPFEHLUNG_ABGEGEBEN', 'K02_REAKTION_ALLGEMEINE_VORGABE_GEAENDERT', 'K02_REAKTION_MASSNAHME_VERBINDLICH_ANGEORDNET', 'K02_REAKTION_EINZELFALL_SELBST_ENTSCHIEDEN', 'K02_REAKTION_ANDERE_REAKTION')
Add-Field -List "Taetigkeiten" -InternalName "k02_beispiel_empfaenger_text" -DisplayName 'Beispiel und Empfänger der Reaktion' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "k03_inhalt" -DisplayName 'Welchen Inhalt haben Anweisungen und Schulungen?' -Type MultiChoice `
    -Choices @('K03_INHALT_ALLGEMEINE_GRUNDSAETZE', 'K03_INHALT_FACHWISSEN_METHODEN', 'K03_INHALT_SOFTWARE_ANWENDUNG', 'K03_INHALT_REGELN_ABLAEUFE', 'K03_INHALT_KONKRETE_BEARBEITUNG', 'K03_INHALT_ANDERE_INHALTE')
# k03_inhalt: Nur bei bereich_code=VORGABEN_SCHULUNG relevant.
Add-Field -List "Taetigkeiten" -InternalName "k03_inhalt_andere_text" -DisplayName 'Andere Inhalte - bitte benennen' -Type Text
Add-Field -List "Taetigkeiten" -InternalName "k03_wer_bestimmt_ref" -DisplayName 'Wer bestimmt die Inhalte?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "k03_wer_nimmt_teil_text" -DisplayName 'Wer nimmt teil?' -Type Note
Add-Field -List "Taetigkeiten" -InternalName "k03_wer_setzt_um_ref" -DisplayName 'Wer setzt die Inhalte um?' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Taetigkeiten" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Zeitverteilungen
# n:m-Verknuepfung Zeitanteile auf Ort/Empfaenger (P16, P21, P22), Summe je Bezug = 100 Prozent
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Zeitverteilungen"
Add-Field -List "Zeitverteilungen" -InternalName "verteilung_id" -DisplayName 'Verteilungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Zeitverteilungen" -InternalName "bezug_typ" -DisplayName 'Bezugstyp der Verteilung' -Type Choice -Required `
    -Choices @('ZEITVERTEILUNG_BEZUGSTYP_EINSATZ', 'ZEITVERTEILUNG_BEZUGSTYP_TAETIGKEIT')
Add-Field -List "Zeitverteilungen" -InternalName "einsatz_ref" -DisplayName 'Bezug: Personeneinsatz (bei P21/P22)' -Type Lookup `
    -LookupList "Personeneinsaetze" -LookupField "display_label"
Add-Field -List "Zeitverteilungen" -InternalName "taetigkeit_ref" -DisplayName 'Bezug: Tätigkeit (bei P16)' -Type Lookup `
    -LookupList "Taetigkeiten" -LookupField "display_label"
Add-Field -List "Zeitverteilungen" -InternalName "dimension" -DisplayName 'Dimension der Verteilung' -Type Choice -Required `
    -Choices @('ZEITVERTEILUNG_DIMENSION_ORT', 'ZEITVERTEILUNG_DIMENSION_EMPFAENGER')
Add-Field -List "Zeitverteilungen" -InternalName "ort_ref" -DisplayName 'Bezug: Ort (bei Dimension=Ort)' -Type Lookup `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Zeitverteilungen" -InternalName "empfaenger_ref" -DisplayName 'Bezug: Empfänger-Gesellschaft (bei Dimension=Empfänger)' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Zeitverteilungen" -InternalName "prozent" -DisplayName 'Prozentanteil (Summe je Bezug = 100 %)' -Type Number -Required `
    -Min 0 `
    -Max 100
# prozent: 100-%-Prüfung mit Toleranz 99-101 % im Flow, siehe README.
Add-Field -List "Zeitverteilungen" -InternalName "stunden" -DisplayName 'Stunden (alternativ oder ergänzend zu Prozent)' -Type Number
Add-Field -List "Zeitverteilungen" -InternalName "basis_code" -DisplayName 'Grundlage der Verteilung' -Type Choice `
    -Choices @('NUTZUNGSGRUNDLAGE_AUFZEICHNUNG', 'NUTZUNGSGRUNDLAGE_SCHAETZUNG', 'NUTZUNGSGRUNDLAGE_ANDERE_GRUNDLAGE')
Add-Field -List "Zeitverteilungen" -InternalName "zeitraum_von" -DisplayName 'Zeitraum - Beginn' -Type DateOnly
Add-Field -List "Zeitverteilungen" -InternalName "zeitraum_bis" -DisplayName 'Zeitraum - Ende' -Type DateOnly
Add-Field -List "Zeitverteilungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Entscheidungsfaelle
# Entscheidungsfaelle (E01-E08) sowie Kontroll-/Anweisungs-/Schulungsfaelle (K05)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Entscheidungsfaelle"
Add-Field -List "Entscheidungsfaelle" -InternalName "fall_id" -DisplayName 'Fall-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Entscheidungsfaelle" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Entscheidungsfaelle" -InternalName "art_code" -DisplayName 'Um welche Entscheidung geht es?' -Type Choice -Required `
    -Choices @('E01_ART_KUNDENPREISE_AUFTRAEGE', 'E01_ART_LIEFERANTEN_BESTELLUNGEN', 'E01_ART_PERSONAL', 'E01_ART_ARBEITSORGANISATION', 'E01_ART_FINANZIERUNG_SICHERHEITEN', 'E01_ART_ZAHLUNGEN', 'E01_ART_BUDGET_INVESTITION', 'E01_ART_BETRIEBLICHE_STRATEGISCHE_PLANUNG', 'E01_ART_BETEILIGUNGSERWERB_VERKAUF', 'E01_ART_AUSSCHUETTUNG', 'E01_ART_KAPITALMASSNAHME', 'E01_ART_ORGANBESTELLUNG_ABBERUFUNG', 'E01_ART_ANDERE', 'E01_ART_KONTROLLE_ANWEISUNG_SCHULUNG')
# art_code: Codeliste um K05-Faelle (E01_ART_KONTROLLE_ANWEISUNG_SCHULUNG) erweitert.
Add-Field -List "Entscheidungsfaelle" -InternalName "art_andere_text" -DisplayName 'Andere Entscheidung - bitte benennen' -Type Text
Add-Field -List "Entscheidungsfaelle" -InternalName "gesellschaft_ref" -DisplayName 'Welche Gesellschaft betrifft die Entscheidung?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Entscheidungsfaelle" -InternalName "gesellschaft_status" -DisplayName 'Status, falls keine konkrete Gesellschaft zutrifft' -Type Choice `
    -Choices @('GESELLSCHAFT_STATUS_ANDERE', 'GESELLSCHAFT_STATUS_KEINE', 'GESELLSCHAFT_STATUS_UNBEKANNT', 'GESELLSCHAFT_STATUS_NICHT_EINDEUTIG')
Add-Field -List "Entscheidungsfaelle" -InternalName "inhalt" -DisplayName 'Gegenstand der Entscheidung' -Type Note
Add-Field -List "Entscheidungsfaelle" -InternalName "e05_grenzen" -DisplayName 'Welche Grenzen oder Freigaben bestehen?' -Type MultiChoice -Required `
    -Choices @('E05_GRENZEN_KEINE_FREIGABE', 'E05_GRENZEN_INNERHALB_BUDGET', 'E05_GRENZEN_BIS_BETRAG', 'E05_GRENZEN_ZUSTIMMUNG_GESCHAEFTSLEITUNG', 'E05_GRENZEN_ZUSTIMMUNG_GESELLSCHAFTER_GREMIUM', 'E05_GRENZEN_ANDERE_VORGABE')
Add-Field -List "Entscheidungsfaelle" -InternalName "e05_betrag" -DisplayName 'Betragsgrenze' -Type Number
Add-Field -List "Entscheidungsfaelle" -InternalName "e05_waehrung" -DisplayName 'Währung der Betragsgrenze' -Type Text
Add-Field -List "Entscheidungsfaelle" -InternalName "e05_regelung_ref" -DisplayName 'Schriftliche Regelung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Entscheidungsfaelle" -InternalName "e06_ablauf" -DisplayName 'Wie läuft eine Zustimmung in der Praxis ab?' -Type Choice -Required `
    -Choices @('E06_ZUSTIMMUNGSABLAUF_PRUEFT_AENDERT_REGELMAESSIG', 'E06_ZUSTIMMUNGSABLAUF_PRUEFT_AENDERT_SELTEN', 'E06_ZUSTIMMUNGSABLAUF_BESTAETIGT_UEBLICH', 'E06_ZUSTIMMUNGSABLAUF_ZEICHNET_FORMAL', 'E06_ZUSTIMMUNGSABLAUF_KEINE_ZUSTIMMUNG', 'E06_ZUSTIMMUNGSABLAUF_UNBEKANNT')
Add-Field -List "Entscheidungsfaelle" -InternalName "e06_beispiel_text" -DisplayName 'Beispiel: Kann die zustimmende Person ablehnen, wann zuletzt geschehen?' -Type Note
Add-Field -List "Entscheidungsfaelle" -InternalName "status" -DisplayName 'Status des Falls' -Type Choice -Required `
    -Choices @('FALL_STATUS_OFFEN', 'FALL_STATUS_GEPLANT', 'FALL_STATUS_ABGESCHLOSSEN')
# status: 'geplant' statt erfundener Detailantwort, falls Fall nur beabsichtigt.
Add-Field -List "Entscheidungsfaelle" -InternalName "ergebnis" -DisplayName 'Ergebnis der Entscheidung' -Type Note
Add-Field -List "Entscheidungsfaelle" -InternalName "e08_datum" -DisplayName 'Datum des Falls' -Type DateOnly
Add-Field -List "Entscheidungsfaelle" -InternalName "e08_nachweis_ref" -DisplayName 'Nachweis des Falls' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Entscheidungsfaelle" -InternalName "k05_text" -DisplayName 'Kontroll-, Anweisungs- oder Schulungsfall: Anlass, Beteiligte, Inhalt, Reaktion, Ergebnis' -Type Note
# k05_text: Nur bei art_code=E01_ART_KONTROLLE_ANWEISUNG_SCHULUNG.
Add-Field -List "Entscheidungsfaelle" -InternalName "k05_nachweis_ref" -DisplayName 'Nachweis zum Kontroll-/Anweisungs-/Schulungsfall' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Entscheidungsfaelle" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text
Add-Field -List "Entscheidungsfaelle" -InternalName "n01_bereich" -DisplayName 'Welche tatsächlich ausgeübten Managementtätigkeiten lassen sich konkret zeigen?' -Type MultiChoice `
    -Choices @('N01_BEREICH_KUNDENGESCHAEFT', 'N01_BEREICH_LIEFERANTENGESCHAEFT', 'N01_BEREICH_PERSONALENTSCHEIDUNG', 'N01_BEREICH_FINANZIERUNG', 'N01_BEREICH_BETRIEBLICHE_STEUERUNG', 'N01_BEREICH_BUDGET_INVESTITION', 'N01_BEREICH_ANDERE_TAETIGKEIT')
# n01_bereich: Je tatsächlich ausgeübtem wesentlichem Bereich ein Fall (keine fixe Obergrenze mehr, frühere offene Frage damit erledigt); bereits bei P17/E08/V09/K05 genannte Fälle referenzieren statt neu erfassen - siehe Belegverknuepfungen.

# ---------------------------------------------------------------------------
# Liste: Vertragsvorgaenge
# Vertragsverhandlungen und Abschlussreife (V01-V02, V05-V06, V08-V09)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Vertragsvorgaenge"
Add-Field -List "Vertragsvorgaenge" -InternalName "vorgang_id" -DisplayName 'Vorgangs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Vertragsvorgaenge" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Vertragsvorgaenge" -InternalName "vertragsart" -DisplayName 'Bei welchen Geschäften wirkt die Person mit?' -Type Choice -Required `
    -Choices @('V01_VERTRAGSART_KUNDENVERTRAEGE', 'V01_VERTRAGSART_LIEFERANTENVERTRAEGE', 'V01_VERTRAGSART_PERSONALVERTRAEGE', 'V01_VERTRAGSART_KREDITE_SICHERHEITEN', 'V01_VERTRAGSART_MIET_LEASINGVERTRAEGE', 'V01_VERTRAGSART_BERATERVERTRAEGE', 'V01_VERTRAGSART_SONSTIGE_VERTRAEGE', 'V01_VERTRAGSART_KEINE_MITWIRKUNG')
# vertragsart: Je ausgewählter Art (ausser 'keine Mitwirkung') ein eigener Vorgangs-Datensatz.
Add-Field -List "Vertragsvorgaenge" -InternalName "vertragsgesellschaft_ref" -DisplayName 'Welche Gesellschaft soll Vertragspartei werden?' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Vertragsvorgaenge" -InternalName "gegenpartei_text" -DisplayName 'Gegenpartei' -Type Text
Add-Field -List "Vertragsvorgaenge" -InternalName "v05_offene_punkte" -DisplayName 'Was ist nach ihrer Verhandlung noch offen?' -Type Choice -Required `
    -Choices @('V05_OFFENE_PUNKTE_WESENTLICHE_WIRTSCHAFTLICHE_PUNKTE', 'V05_OFFENE_PUNKTE_EINZELNE_WIRTSCHAFTLICHE_PUNKTE', 'V05_OFFENE_PUNKTE_NUR_RECHTLICHE_DETAILPRUEFUNG', 'V05_OFFENE_PUNKTE_NUR_INTERNE_FREIGABE', 'V05_OFFENE_PUNKTE_NUR_UNTERSCHRIFT', 'V05_OFFENE_PUNKTE_NICHTS_BINDEND', 'V05_OFFENE_PUNKTE_UNBEKANNT')
Add-Field -List "Vertragsvorgaenge" -InternalName "v05_text" -DisplayName 'Welche Punkte genau?' -Type Text
Add-Field -List "Vertragsvorgaenge" -InternalName "v06_aenderungshaeufigkeit" -DisplayName 'Wer prüft, ändert oder genehmigt danach den Vertrag?' -Type Choice -Required `
    -Choices @('V06_AENDERUNGSHAEUFIGKEIT_REGELMAESSIGE_AENDERUNGEN', 'V06_AENDERUNGSHAEUFIGKEIT_GELEGENTLICHE_AENDERUNGEN', 'V06_AENDERUNGSHAEUFIGKEIT_GEWOEHNLICH_KEINE_AENDERUNGEN', 'V06_AENDERUNGSHAEUFIGKEIT_KEINE_WEITERE_PRUEFUNG', 'V06_AENDERUNGSHAEUFIGKEIT_UNBEKANNT')
Add-Field -List "Vertragsvorgaenge" -InternalName "v06_beispiel_text" -DisplayName 'Letzte Änderung oder Ablehnung als Beispiel' -Type Note
Add-Field -List "Vertragsvorgaenge" -InternalName "v08_anzahl_vorgaenge" -DisplayName 'Anzahl Vorgänge im Zeitraum' -Type Number
Add-Field -List "Vertragsvorgaenge" -InternalName "v09_text" -DisplayName 'Beschreibung eines bis zur Unterschrift vorbereiteten Vertrags' -Type Note -Required
Add-Field -List "Vertragsvorgaenge" -InternalName "v09_nachweis_ref" -DisplayName 'Anlagen: E-Mail-Verlauf, Entwurfsstände, Verhandlungsnotiz, Freigabe, unterschriebener Vertrag' -Type LookupMulti `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Vertragsvorgaenge" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Fallbeteiligungen
# Rollen/Schritte/Orte der beteiligten Personen je Entscheidungsfall oder Vertragsvorgang (E03/E04/E07; V03/V04/V07/V08)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Fallbeteiligungen"
Add-Field -List "Fallbeteiligungen" -InternalName "beteiligung_id" -DisplayName 'Beteiligungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Fallbeteiligungen" -InternalName "bezug_typ" -DisplayName 'Bezugstyp' -Type Choice -Required `
    -Choices @('FALLBETEILIGUNG_BEZUGSTYP_ENTSCHEIDUNG', 'FALLBETEILIGUNG_BEZUGSTYP_VERTRAG')
Add-Field -List "Fallbeteiligungen" -InternalName "entscheidung_ref" -DisplayName 'Bezug: Entscheidungsfall' -Type Lookup `
    -LookupList "Entscheidungsfaelle" -LookupField "display_label"
Add-Field -List "Fallbeteiligungen" -InternalName "vertrag_ref" -DisplayName 'Bezug: Vertragsvorgang' -Type Lookup `
    -LookupList "Vertragsvorgaenge" -LookupField "display_label"
Add-Field -List "Fallbeteiligungen" -InternalName "person_ref" -DisplayName 'Bezug: Person (Entscheider/Beteiligter)' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Fallbeteiligungen" -InternalName "e04_entscheider" -DisplayName 'Wer bestimmt tatsächlich das Ergebnis?' -Type Choice `
    -Choices @('E04_ENTSCHEIDER_PERSON_ALLEIN', 'E04_ENTSCHEIDER_GEMEINSAM_BENANNTE', 'E04_ENTSCHEIDER_ANDERE_PERSON', 'E04_ENTSCHEIDER_GREMIUM_SITZUNG', 'E04_ENTSCHEIDER_GESELLSCHAFTERBESCHLUSS', 'E04_ENTSCHEIDER_UNBEKANNT')
Add-Field -List "Fallbeteiligungen" -InternalName "e03_rolle" -DisplayName 'Welche Rolle hat die Person dabei tatsächlich?' -Type MultiChoice `
    -Choices @('E03_ROLLE_GRUNDLAGEN_ERMITTELN', 'E03_ROLLE_ALTERNATIVEN_ENTWICKELN', 'E03_ROLLE_LOESUNG_EMPFEHLEN', 'E03_ROLLE_VERHANDELN', 'E03_ROLLE_SELBST_ENTSCHEIDEN', 'E03_ROLLE_GEMEINSAM_ENTSCHEIDEN', 'E03_ROLLE_ZUSTIMMUNG_ERTEILEN', 'E03_ROLLE_UMSETZEN', 'E03_ROLLE_KONTROLLE_UMSETZUNG', 'E03_ROLLE_NUR_INFORMIERT')
Add-Field -List "Fallbeteiligungen" -InternalName "v03_schritte" -DisplayName 'Welche Schritte übernimmt die Person tatsächlich? (Vertrag)' -Type MultiChoice `
    -Choices @('V03_SCHRITTE_KONTAKT_HERSTELLEN', 'V03_SCHRITTE_BEDARF_RAHMEN_KLAEREN', 'V03_SCHRITTE_VERTRAGSPARTNER_AUSWAEHLEN', 'V03_SCHRITTE_ANGEBOT_ERSTELLEN_EINHOLEN', 'V03_SCHRITTE_PREISE_VERGUETUNG_VERHANDELN', 'V03_SCHRITTE_LEISTUNG_LAUFZEIT_VERHANDELN', 'V03_SCHRITTE_HAFTUNG_SICHERHEITEN_VERHANDELN', 'V03_SCHRITTE_ENTWURF_ABSTIMMEN', 'V03_SCHRITTE_BINDENDE_ZUSAGE', 'V03_SCHRITTE_UNTERZEICHNEN', 'V03_SCHRITTE_NUR_WEITERLEITEN')
Add-Field -List "Fallbeteiligungen" -InternalName "v04_gespraechspartner" -DisplayName 'Mit wem führt sie diese Gespräche?' -Type MultiChoice `
    -Choices @('V04_GESPRAECHSPARTNER_KUNDEN', 'V04_GESPRAECHSPARTNER_LIEFERANTEN', 'V04_GESPRAECHSPARTNER_BEWERBER_MITARBEITENDE', 'V04_GESPRAECHSPARTNER_BANKEN_FINANZIERER', 'V04_GESPRAECHSPARTNER_STEUERBERATER_BUCHHALTER', 'V04_GESPRAECHSPARTNER_ANDERE_BERATER', 'V04_GESPRAECHSPARTNER_INTERNE_VERANTWORTLICHE', 'V04_GESPRAECHSPARTNER_ANDERE_GESPRAECHSPARTNER')
Add-Field -List "Fallbeteiligungen" -InternalName "v04_gespraechspartner_text" -DisplayName 'Andere Gesprächspartner - bitte benennen' -Type Text
Add-Field -List "Fallbeteiligungen" -InternalName "v07_unterlagenart" -DisplayName 'Welche Unterlagen darf die Person unterzeichnen oder verbindlich bestätigen?' -Type MultiChoice `
    -Choices @('V07_UNTERLAGENART_ANGEBOTE', 'V07_UNTERLAGENART_AUFTRAGSBESTAETIGUNGEN', 'V07_UNTERLAGENART_KUNDENVERTRAEGE', 'V07_UNTERLAGENART_BESTELLUNGEN_LIEFERANTENVERTRAEGE', 'V07_UNTERLAGENART_ARBEITSVERTRAEGE', 'V07_UNTERLAGENART_FINANZIERUNGSVERTRAEGE', 'V07_UNTERLAGENART_ZAHLUNGSFREIGABEN', 'V07_UNTERLAGENART_BERATERAUFTRAEGE', 'V07_UNTERLAGENART_SONSTIGE_DOKUMENTE', 'V07_UNTERLAGENART_KEINE')
Add-Field -List "Fallbeteiligungen" -InternalName "v07_grenzen_text" -DisplayName 'Allein oder gemeinsam; Betragsgrenzen; Vollmacht oder Kompetenzordnung' -Type Note
Add-Field -List "Fallbeteiligungen" -InternalName "v07_nachweis_ref" -DisplayName 'Vollmacht oder Kompetenzordnung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Fallbeteiligungen" -InternalName "v07_email_zusage" -DisplayName 'Auch bindende E-Mail-Zusagen erfasst' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Fallbeteiligungen" -InternalName "schritt" -DisplayName 'Schritt (Vorbereitung/Festlegung/Freigabe bzw. Verhandlung/Einigung/Freigabe/Unterschrift)' -Type Choice `
    -Choices @('FALLBETEILIGUNG_SCHRITT_VORBEREITUNG', 'FALLBETEILIGUNG_SCHRITT_INHALTLICHE_FESTLEGUNG', 'FALLBETEILIGUNG_SCHRITT_ABSCHLIESSENDE_FREIGABE', 'FALLBETEILIGUNG_SCHRITT_VERHANDLUNG', 'FALLBETEILIGUNG_SCHRITT_INHALTLICHE_EINIGUNG', 'FALLBETEILIGUNG_SCHRITT_FREIGABE_VERTRAG', 'FALLBETEILIGUNG_SCHRITT_UNTERZEICHNUNG')
Add-Field -List "Fallbeteiligungen" -InternalName "ort_ref" -DisplayName 'Aufenthaltsort bei diesem Schritt' -Type Lookup `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Fallbeteiligungen" -InternalName "land_text" -DisplayName 'Land, falls kein erfasster Ort' -Type Text
Add-Field -List "Fallbeteiligungen" -InternalName "zeitpunkt" -DisplayName 'Zeitpunkt dieses Schritts' -Type DateOnly
Add-Field -List "Fallbeteiligungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Steuerungsbeziehungen
# Steuerung von Mitarbeitenden/Dienstleistern (K04)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Steuerungsbeziehungen"
Add-Field -List "Steuerungsbeziehungen" -InternalName "beziehung_id" -DisplayName 'Beziehungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Steuerungsbeziehungen" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Steuerungsbeziehungen" -InternalName "taetigkeit_ref" -DisplayName 'Bezug: zugehörige Tätigkeit (optional)' -Type Lookup `
    -LookupList "Taetigkeiten" -LookupField "display_label"
Add-Field -List "Steuerungsbeziehungen" -InternalName "steuernde_person_ref" -DisplayName 'Steuert die Person bestimmte Mitarbeitende oder Dienstleister?' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Steuerungsbeziehungen" -InternalName "gesteuerte_person_ref" -DisplayName 'Gesteuerte Person (intern erfasst)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Steuerungsbeziehungen" -InternalName "gesteuerter_dienstleister_text" -DisplayName 'Gesteuerter Dienstleister (Name/Funktion)' -Type Text
Add-Field -List "Steuerungsbeziehungen" -InternalName "arbeitgeber_gesellschaft_ref" -DisplayName 'Arbeitgeber bzw. Vertragspartner' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Steuerungsbeziehungen" -InternalName "fuer_gesellschaft_ref" -DisplayName 'Gesellschaft, für die gearbeitet wird' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Steuerungsbeziehungen" -InternalName "art_text" -DisplayName 'Art der Steuerung' -Type Text
Add-Field -List "Steuerungsbeziehungen" -InternalName "haeufigkeit" -DisplayName 'Häufigkeit der Steuerung' -Type Choice -Required `
    -Choices @('K04_HAEUFIGKEIT_REGELMAESSIG', 'K04_HAEUFIGKEIT_FALLWEISE', 'K04_HAEUFIGKEIT_NEIN')
Add-Field -List "Steuerungsbeziehungen" -InternalName "befugnisse" -DisplayName 'Befugnis, Aufgaben, Termine und Ergebnisse verbindlich festzulegen' -Type Note
Add-Field -List "Steuerungsbeziehungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Raeume
# Geschaeftsraeume und tatsaechliche Nutzung (R01-R06)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Raeume"
Add-Field -List "Raeume" -InternalName "raum_id" -DisplayName 'Raum-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Raeume" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Raeume" -InternalName "ort_ref" -DisplayName 'Welche Räume oder Arbeitsbereiche nutzt die KG? (Ort/Adresse)' -Type Lookup -Required `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "raumart" -DisplayName 'Raumart' -Type Choice -Required `
    -Choices @('RAUM_ART_EIGENES_BUERO', 'RAUM_ART_EIGENER_RAUM_BETEILIGUNG', 'RAUM_ART_GEMEINSAMER_RAUM_BETEILIGUNG', 'RAUM_ART_FLEXIBLER_ARBEITSPLATZ', 'RAUM_ART_BESPRECHUNGSRAUM', 'RAUM_ART_HOMEOFFICE', 'RAUM_ART_SCHWEIZER_RAEUME', 'RAUM_ART_LAGER_ARCHIV', 'RAUM_ART_ANDERE_FLAECHE')
# raumart: Löst frühere offene Frage zum Raumart-Katalog: R01 gibt den Katalog vor.
Add-Field -List "Raeume" -InternalName "eigentuemer_gesellschaft_ref" -DisplayName 'Eigentümer der Fläche (Gesellschaft)' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Raeume" -InternalName "eigentuemer_person_ref" -DisplayName 'Eigentümer der Fläche (Person)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "mieter_ref" -DisplayName 'Mieter der Fläche' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Raeume" -InternalName "untervermieter_text" -DisplayName 'Untervermieter, falls zutreffend' -Type Text
Add-Field -List "Raeume" -InternalName "r02_nachweis_ref" -DisplayName 'Miet-, Untermiet- oder Nutzungsvereinbarung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "nutzung_beginn" -DisplayName 'Beginn der Nutzung' -Type DateOnly
Add-Field -List "Raeume" -InternalName "nutzung_ende" -DisplayName 'Ende der Nutzung' -Type DateOnly
Add-Field -List "Raeume" -InternalName "verfuegung" -DisplayName 'Worüber kann die KG tatsächlich verfügen?' -Type MultiChoice -Required `
    -Choices @('R03_VERFUEGUNG_EIGENER_SCHLUESSEL_ZUGANG', 'R03_VERFUEGUNG_JEDERZEITIGER_ZUGANG', 'R03_VERFUEGUNG_ZUGANG_NACH_ANMELDUNG', 'R03_VERFUEGUNG_FEST_ZUGEWIESENE_ARBEITSPLAETZE', 'R03_VERFUEGUNG_GELEGENTLICHE_BUCHUNG', 'R03_VERFUEGUNG_EIGENE_ABLAGE', 'R03_VERFUEGUNG_ABSCHLIESSBARE_AUFBEWAHRUNG', 'R03_VERFUEGUNG_EIGENE_BESCHILDERUNG', 'R03_VERFUEGUNG_KEINE_AUSSCHLIESSLICHE_FLAECHE')
Add-Field -List "Raeume" -InternalName "flaeche_qm" -DisplayName 'Fläche in m²' -Type Number `
    -Min 0
Add-Field -List "Raeume" -InternalName "anzahl_arbeitsplaetze" -DisplayName 'Anzahl Arbeitsplätze' -Type Number `
    -Min 0
Add-Field -List "Raeume" -InternalName "aufteilung_text" -DisplayName 'Aufteilung bei gemeinsamer Nutzung' -Type Note
Add-Field -List "Raeume" -InternalName "belegart" -DisplayName 'Wie wird die Nutzung belegt?' -Type MultiChoice `
    -Choices @('R05_BELEGART_GRUNDRISS', 'R05_BELEGART_MIET_NUTZUNGSVERTRAG', 'R05_BELEGART_FOTOS', 'R05_BELEGART_BUCHUNGS_ZUTRITTSDATEN', 'R05_BELEGART_KALENDER', 'R05_BELEGART_BESPRECHUNGSUNTERLAGEN', 'R05_BELEGART_ANDERE_UNTERLAGE', 'R05_BELEGART_KEINE_UNTERLAGEN')
Add-Field -List "Raeume" -InternalName "r05_nachweis_ref" -DisplayName 'Vorhandene Belege (Grundriss, Fotos, Verträge usw.)' -Type LookupMulti `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Raeume" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Arbeitsmittel
# Arbeitsmittel, Fahrzeuge, IT und Software (A01-A02, A05-A07)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Arbeitsmittel"
Add-Field -List "Arbeitsmittel" -InternalName "mittel_id" -DisplayName 'Mittel-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Arbeitsmittel" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Arbeitsmittel" -InternalName "art_code" -DisplayName 'Welches Arbeitsmittel wird genutzt?' -Type Choice -Required `
    -Choices @('A01_ART_FAHRZEUG', 'A01_ART_BUEROAUSSTATTUNG', 'A01_ART_COMPUTER_NOTEBOOK', 'A01_ART_MONITOR_ZUBEHOER', 'A01_ART_SMARTPHONE_TABLET', 'A01_ART_TELEFON_INTERNET', 'A01_ART_DRUCKER_SCANNER', 'A01_ART_SERVER_CLOUD', 'A01_ART_SOFTWARE_DATENBANK', 'A01_ART_ANDERES')
Add-Field -List "Arbeitsmittel" -InternalName "bezeichnung" -DisplayName 'Bezeichnung des Arbeitsmittels' -Type Text -Required
Add-Field -List "Arbeitsmittel" -InternalName "eigentuemer_gesellschaft_ref" -DisplayName 'Eigentümer (Gesellschaft)' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "eigentuemer_person_ref" -DisplayName 'Eigentümer (Person)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Arbeitsmittel" -InternalName "bereitsteller_ref" -DisplayName 'Bereitsteller' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "bereitstellungsart" -DisplayName 'Gekauft / gemietet / geleast / privat bereitgestellt' -Type Choice -Required `
    -Choices @('A02_BEREITSTELLUNG_GEKAUFT', 'A02_BEREITSTELLUNG_GEMIETET', 'A02_BEREITSTELLUNG_GELEAST', 'A02_BEREITSTELLUNG_PRIVAT_BEREITGESTELLT', 'A02_BEREITSTELLUNG_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "ort_ref" -DisplayName 'Standort des Arbeitsmittels' -Type Lookup `
    -LookupList "Orte" -LookupField "display_label"
Add-Field -List "Arbeitsmittel" -InternalName "beginn" -DisplayName 'Anschaffungs- bzw. Nutzungsbeginn' -Type DateOnly
Add-Field -List "Arbeitsmittel" -InternalName "fahrzeughalter_ref" -DisplayName 'Fahrzeughalter (nur bei Art=Fahrzeug)' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "leasingnehmer_ref" -DisplayName 'Leasingnehmer (nur bei Art=Fahrzeug)' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "fahrtenbuch_status" -DisplayName 'Fahrtenbuch oder andere Aufzeichnung vorhanden?' -Type Choice `
    -Choices @('ALLG_STATUS_NICHT_BEKANNT', 'ALLG_STATUS_NICHT_VORHANDEN', 'ALLG_STATUS_WIRD_NACHGEREICHT', 'ALLG_STATUS_NICHT_ZUTREFFEND', 'ALLG_STATUS_VORHANDEN')
# fahrtenbuch_status: Unterscheidet 'nicht vorhanden' von 'nicht bekannt' statt Boolean.
Add-Field -List "Arbeitsmittel" -InternalName "fahrtenbuch_text" -DisplayName 'Art der Aufzeichnung, falls vorhanden' -Type Text
Add-Field -List "Arbeitsmittel" -InternalName "mobilfunkvertrag_ref" -DisplayName 'Mobilfunkvertrag auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "email_domain_ref" -DisplayName 'E-Mail-Domain auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "konto_ref" -DisplayName 'Benutzerkonto auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "geraeteverwaltung_ref" -DisplayName 'Geräteverwaltung auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "support_ref" -DisplayName 'Technischer Support auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "speicherzugriff_ref" -DisplayName 'Speicherzugriff auf wen?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "lizenznehmer_ref" -DisplayName 'Lizenz- bzw. Abonnementnehmer' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Arbeitsmittel" -InternalName "anzahl_lizenzen_verfuegbar" -DisplayName 'Anzahl verfügbare Lizenzen' -Type Number `
    -Min 0
Add-Field -List "Arbeitsmittel" -InternalName "anzahl_lizenzen_genutzt" -DisplayName 'Anzahl tatsächlich genutzte Lizenzen' -Type Number `
    -Min 0
Add-Field -List "Arbeitsmittel" -InternalName "a07_nachweis_ref" -DisplayName 'Lizenz- oder Abonnementnachweis' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
# a07_nachweis_ref: Rechtliche Zulässigkeit wird intern geprüft (kein Formular-Feld).
Add-Field -List "Arbeitsmittel" -InternalName "beschraenkungen_text" -DisplayName 'Bekannte Nutzungsbeschränkungen' -Type Note
Add-Field -List "Arbeitsmittel" -InternalName "vertragsstatus" -DisplayName 'Vertragsstatus (sofern schriftlich fixiert)' -Type Choice `
    -Choices @('P05_VERTRAGSSTATUS_UNTERZEICHNET', 'P05_VERTRAGSSTATUS_NUR_ENTWURF', 'P05_VERTRAGSSTATUS_VORHANDEN_NICHT_VERFUEGBAR', 'P05_VERTRAGSSTATUS_KEIN_VERTRAG', 'P05_VERTRAGSSTATUS_UNBEKANNT')
Add-Field -List "Arbeitsmittel" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Ressourcennutzungen
# n:m-Verknuepfung Raum/Mittel x Person x Taetigkeit x Nutzungsanteil (R04; A03-A04)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Ressourcennutzungen"
Add-Field -List "Ressourcennutzungen" -InternalName "nutzung_id" -DisplayName 'Nutzungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Ressourcennutzungen" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Ressourcennutzungen" -InternalName "bezug_typ" -DisplayName 'Bezugstyp' -Type Choice -Required `
    -Choices @('RESSOURCE_BEZUGSTYP_RAUM', 'RESSOURCE_BEZUGSTYP_MITTEL')
Add-Field -List "Ressourcennutzungen" -InternalName "raum_ref" -DisplayName 'Bezug: Raum (bei Bezugstyp=Raum)' -Type Lookup `
    -LookupList "Raeume" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "mittel_ref" -DisplayName 'Bezug: Arbeitsmittel (bei Bezugstyp=Mittel)' -Type Lookup `
    -LookupList "Arbeitsmittel" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "person_ref" -DisplayName 'Wer arbeitet dort bzw. nutzt es tatsächlich?' -Type Lookup -Required `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "gesellschaft_ref" -DisplayName 'Für welche Gesellschaft?' -Type Lookup `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Ressourcennutzungen" -InternalName "taetigkeit_ref" -DisplayName 'Für welche Tätigkeit, soweit zuordenbar' -Type Lookup `
    -LookupList "Taetigkeiten" -LookupField "display_label"
Add-Field -List "Ressourcennutzungen" -InternalName "anteil_prozent" -DisplayName 'Nutzungsanteil in Prozent (Summe je Ressource = 100 %)' -Type Number `
    -Min 0 `
    -Max 100
# anteil_prozent: 100-%-Pruefung mit Toleranz im Flow.
Add-Field -List "Ressourcennutzungen" -InternalName "basis_code" -DisplayName 'Grundlage der Angabe' -Type Choice `
    -Choices @('NUTZUNGSGRUNDLAGE_AUFZEICHNUNG', 'NUTZUNGSGRUNDLAGE_SCHAETZUNG', 'NUTZUNGSGRUNDLAGE_ANDERE_GRUNDLAGE')
Add-Field -List "Ressourcennutzungen" -InternalName "tage_oder_stunden_pro_monat" -DisplayName 'Typische Tage bzw. Stunden im Monat' -Type Number
Add-Field -List "Ressourcennutzungen" -InternalName "haeufigkeit" -DisplayName 'Wie häufig wird es eingesetzt?' -Type Choice `
    -Choices @('FREQ_DAILY', 'FREQ_MULTI_WEEK', 'FREQ_WEEKLY', 'FREQ_MONTHLY', 'FREQ_QUARTERLY', 'FREQ_YEARLY', 'FREQ_ON_DEMAND', 'FREQ_ONCE', 'FREQ_RARELY', 'FREQ_NEVER', 'FREQ_NONE')
# haeufigkeit: Codes FREQ_DAILY..FREQ_ON_DEMAND, FREQ_NONE.
Add-Field -List "Ressourcennutzungen" -InternalName "ort_kategorie" -DisplayName 'Wo wird es eingesetzt?' -Type Choice `
    -Choices @('ORT_KATEGORIE_KG_BUERO', 'ORT_KATEGORIE_BETEILIGUNG_RAEUME', 'ORT_KATEGORIE_HOMEOFFICE', 'ORT_KATEGORIE_SCHWEIZER_RAEUME', 'ORT_KATEGORIE_UNTERWEGS_GESCHAEFTSPARTNER', 'ORT_KATEGORIE_ANDERER_ORT')
Add-Field -List "Ressourcennutzungen" -InternalName "nutzungszeitraum_von" -DisplayName 'Nutzungszeitraum - Beginn' -Type DateOnly
Add-Field -List "Ressourcennutzungen" -InternalName "nutzungszeitraum_bis" -DisplayName 'Nutzungszeitraum - Ende' -Type DateOnly
Add-Field -List "Ressourcennutzungen" -InternalName "privat" -DisplayName 'Privatnutzung' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Ressourcennutzungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Kosten
# Personal-, Sach- und Gemeinkosten (C01-C04; A08; R06)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Kosten"
Add-Field -List "Kosten" -InternalName "kosten_id" -DisplayName 'Kosten-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Kosten" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Kosten" -InternalName "kostenart" -DisplayName 'Kostenart' -Type Choice -Required `
    -Choices @('KOSTENART_PERSONAL_FESTVERGUETUNG', 'KOSTENART_PERSONAL_VARIABLE_VERGUETUNG', 'KOSTENART_PERSONAL_ARBEITGEBERBEITRAEGE', 'KOSTENART_PERSONAL_SPESEN', 'KOSTENART_PERSONAL_SONSTIGE_VERGUETUNG', 'KOSTENART_RAUMKOSTEN', 'KOSTENART_FAHRZEUGE', 'KOSTENART_IT_TELEFON', 'KOSTENART_SOFTWARE', 'KOSTENART_REISEN', 'KOSTENART_EXTERNE_BERATUNG', 'KOSTENART_BUCHFUEHRUNG', 'KOSTENART_VERSICHERUNGEN', 'KOSTENART_ALLGEMEINE_VERWALTUNG', 'KOSTENART_SONSTIGE_KOSTEN')
# kostenart: Vereinigung aus C01 (Vergütungsarten) und C03 (sonstige Kostenarten).
Add-Field -List "Kosten" -InternalName "kostenart_andere_text" -DisplayName 'Sonstige Kosten - bitte benennen' -Type Text
Add-Field -List "Kosten" -InternalName "betrag" -DisplayName 'Betrag' -Type Number -Required
# betrag: Betrag/Währung sind vorgegeben - frühere offene Frage damit erledigt.
Add-Field -List "Kosten" -InternalName "waehrung" -DisplayName 'Währung' -Type Text -Required
Add-Field -List "Kosten" -InternalName "zeitraum_von" -DisplayName 'Zeitraum - Beginn' -Type DateOnly
Add-Field -List "Kosten" -InternalName "zeitraum_bis" -DisplayName 'Zeitraum - Ende' -Type DateOnly
Add-Field -List "Kosten" -InternalName "zahlende_gesellschaft_ref" -DisplayName 'Zahlende Gesellschaft (zuerst zahlende Gesellschaft)' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kosten" -InternalName "kostenbasis_text" -DisplayName 'Grundlage bei Pauschalen' -Type Text
Add-Field -List "Kosten" -InternalName "quelle_text" -DisplayName 'Quelle (Vertrag, Rechnung, Umlagebeleg usw.)' -Type Text
Add-Field -List "Kosten" -InternalName "nachweis_ref" -DisplayName 'Nachweis (Rechnung, Vertrag, Umlagebeleg)' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "raum_ref" -DisplayName 'Bezug: Raum (bei Raumkosten)' -Type Lookup `
    -LookupList "Raeume" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "mittel_ref" -DisplayName 'Bezug: Arbeitsmittel (bei Arbeitsmittelkosten)' -Type Lookup `
    -LookupList "Arbeitsmittel" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "person_ref" -DisplayName 'Bezug: Person (bei Personalkosten)' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "taetigkeit_ref" -DisplayName 'Bezug: Tätigkeit, soweit direkt zuordenbar' -Type Lookup `
    -LookupList "Taetigkeiten" -LookupField "display_label"
Add-Field -List "Kosten" -InternalName "zuordnung" -DisplayName 'Lassen sich die Kosten direkt einer Tätigkeit oder Gesellschaft zuordnen?' -Type Choice -Required `
    -Choices @('C04_ZUORDNUNG_VOLLSTAENDIG', 'C04_ZUORDNUNG_TEILWEISE', 'C04_ZUORDNUNG_NEIN', 'C04_ZUORDNUNG_UNBEKANNT')
Add-Field -List "Kosten" -InternalName "schluessel" -DisplayName 'Verwendeter Schlüssel für gemeinsame Kosten' -Type Choice `
    -Choices @('C04_SCHLUESSEL_ZEIT', 'C04_SCHLUESSEL_NUTZUNG', 'C04_SCHLUESSEL_FLAECHE', 'C04_SCHLUESSEL_ANZAHL_NUTZER', 'C04_SCHLUESSEL_ANDERER_SCHLUESSEL', 'C04_SCHLUESSEL_KEIN_SCHLUESSEL')
Add-Field -List "Kosten" -InternalName "schluessel_begruendung" -DisplayName 'Begründung des Schlüssels' -Type Note
Add-Field -List "Kosten" -InternalName "berechneter_anteil" -DisplayName 'Berechneter Anteil' -Type Number `
    -Min 0 `
    -Max 100
Add-Field -List "Kosten" -InternalName "vertraulich_hinweis" -DisplayName 'Vertrauliche Vergütungsunterlagen direkt an Kanzlei übermittelt' -Type Choice `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
Add-Field -List "Kosten" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Kostenverteilungen
# Weiterberechnung von Kosten auf Empfaengergesellschaften (C02)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Kostenverteilungen"
Add-Field -List "Kostenverteilungen" -InternalName "kostenanteil_id" -DisplayName 'Kostenanteils-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Kostenverteilungen" -InternalName "kosten_ref" -DisplayName 'Bezug: Kostenposition' -Type Lookup -Required `
    -LookupList "Kosten" -LookupField "display_label"
Add-Field -List "Kostenverteilungen" -InternalName "empfaenger_gesellschaft_ref" -DisplayName 'Empfangende Gesellschaft' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Kostenverteilungen" -InternalName "anteil_prozent" -DisplayName 'Anteil in Prozent' -Type Number `
    -Min 0 `
    -Max 100
Add-Field -List "Kostenverteilungen" -InternalName "betrag" -DisplayName 'Betrag' -Type Number
Add-Field -List "Kostenverteilungen" -InternalName "schluessel" -DisplayName 'Berechnungsschlüssel der Weiterberechnung' -Type Choice -Required `
    -Choices @('C02_WEITERBERECHNUNG_KEINE', 'C02_WEITERBERECHNUNG_FESTE_PAUSCHALE', 'C02_WEITERBERECHNUNG_NACH_STUNDEN', 'C02_WEITERBERECHNUNG_NACH_ZEITANTEILEN', 'C02_WEITERBERECHNUNG_NACH_ANDEREM_SCHLUESSEL', 'C02_WEITERBERECHNUNG_UNBEKANNT')
Add-Field -List "Kostenverteilungen" -InternalName "begruendung" -DisplayName 'Begründung des Schlüssels' -Type Note
Add-Field -List "Kostenverteilungen" -InternalName "weiterberechnet" -DisplayName 'Weiterberechnet?' -Type Choice -Required `
    -Choices @('JA_NEIN_UNBEKANNT_JA', 'JA_NEIN_UNBEKANNT_NEIN', 'JA_NEIN_UNBEKANNT_UNBEKANNT')
# weiterberechnet: Bewusst Choice statt Boolean (B2: 'weiterberechnet ja/nein/unbekannt') - unbekannt nie als 0/false.
Add-Field -List "Kostenverteilungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Abrechnungen
# Tatsaechlich gestellte Abrechnungen/Leistungsvereinbarungen (G06, C05)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Abrechnungen"
Add-Field -List "Abrechnungen" -InternalName "abrechnung_id" -DisplayName 'Abrechnungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Abrechnungen" -InternalName "erfassung_ref" -DisplayName 'Bezug: Erfassung' -Type Lookup -Required `
    -LookupList "Erfassungen" -LookupField "case_id" `
    -DeleteBehavior Restrict
Add-Field -List "Abrechnungen" -InternalName "leistender_ref" -DisplayName 'Leistender (Gesellschaft)' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Abrechnungen" -InternalName "empfaenger_ref" -DisplayName 'Rechnungsempfänger' -Type Lookup -Required `
    -LookupList "Gesellschaften" -LookupField "company_id"
Add-Field -List "Abrechnungen" -InternalName "leistungsart" -DisplayName 'Welche Leistungen rechnet die KG tatsächlich ab?' -Type Choice -Required `
    -Choices @('C05_LEISTUNGSART_MANAGEMENTLEISTUNGEN', 'C05_LEISTUNGSART_PERSONALBEREITSTELLUNG', 'C05_LEISTUNGSART_SACHMITTELBEREITSTELLUNG', 'C05_LEISTUNGSART_KOSTENERSTATTUNG', 'C05_LEISTUNGSART_ANDERE_LEISTUNG', 'C05_LEISTUNGSART_KEINE_ABRECHNUNG')
Add-Field -List "Abrechnungen" -InternalName "betrag" -DisplayName 'Betrag' -Type Number
Add-Field -List "Abrechnungen" -InternalName "waehrung" -DisplayName 'Währung' -Type Text
Add-Field -List "Abrechnungen" -InternalName "zeitraum_von" -DisplayName 'Leistungszeitraum - Beginn' -Type DateOnly
Add-Field -List "Abrechnungen" -InternalName "zeitraum_bis" -DisplayName 'Leistungszeitraum - Ende' -Type DateOnly
Add-Field -List "Abrechnungen" -InternalName "zuschlag_text" -DisplayName 'Gegebenenfalls gesonderter Zuschlag' -Type Text
Add-Field -List "Abrechnungen" -InternalName "rechnungsdatum" -DisplayName 'Rechnungsdatum' -Type DateOnly
Add-Field -List "Abrechnungen" -InternalName "zahlungsstatus" -DisplayName 'Zahlungsstatus' -Type Choice `
    -Choices @('ZAHLUNGSSTATUS_BEZAHLT', 'ZAHLUNGSSTATUS_OFFEN', 'ZAHLUNGSSTATUS_TEILWEISE', 'ZAHLUNGSSTATUS_UNBEKANNT')
Add-Field -List "Abrechnungen" -InternalName "g06_vereinbarung_status" -DisplayName 'Schriftliche Leistungsvereinbarung vorhanden?' -Type Choice -Required `
    -Choices @('ALLG_STATUS_NICHT_BEKANNT', 'ALLG_STATUS_NICHT_VORHANDEN', 'ALLG_STATUS_WIRD_NACHGEREICHT', 'ALLG_STATUS_NICHT_ZUTREFFEND', 'ALLG_STATUS_VORHANDEN')
Add-Field -List "Abrechnungen" -InternalName "g06_vereinbarung_nachweis_ref" -DisplayName 'Leistungsvereinbarung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Abrechnungen" -InternalName "g06_rechnung_status" -DisplayName 'Tatsächlich gestellte Rechnung vorhanden?' -Type Choice -Required `
    -Choices @('ALLG_STATUS_NICHT_BEKANNT', 'ALLG_STATUS_NICHT_VORHANDEN', 'ALLG_STATUS_WIRD_NACHGEREICHT', 'ALLG_STATUS_NICHT_ZUTREFFEND', 'ALLG_STATUS_VORHANDEN')
Add-Field -List "Abrechnungen" -InternalName "g06_rechnung_nachweis_ref" -DisplayName 'Tatsächlich gestellte Rechnung' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
Add-Field -List "Abrechnungen" -InternalName "g06_abweichung_text" -DisplayName 'Abweichungen zwischen Vereinbarung und tatsächlicher Arbeit' -Type Note
Add-Field -List "Abrechnungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: Belegverknuepfungen
# Generische Verknuepfung Nachweis -> beliebige Zielliste (N02-N04)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Belegverknuepfungen"
Add-Field -List "Belegverknuepfungen" -InternalName "link_id" -DisplayName 'Link-ID (intern vergeben)' -Type Text -Required
Add-Field -List "Belegverknuepfungen" -InternalName "nachweis_ref" -DisplayName 'Welche Unterlagen belegen die Angabe?' -Type Lookup `
    -LookupList "Substanznachweise" -LookupField "display_label"
# nachweis_ref: Je referenzierter Unterlage ein Belegverknuepfungen-Datensatz; die N02_UNTERLAGENART-Kategorie steht auf dem referenzierten Substanznachweise-Eintrag (dokumentart), nicht hier.
Add-Field -List "Belegverknuepfungen" -InternalName "ziel_typ" -DisplayName 'Zieltyp der belegten Angabe (Liste)' -Type Choice -Required `
    -Choices @('ZIEL_TYP_ERFASSUNGEN', 'ZIEL_TYP_GESELLSCHAFTEN', 'ZIEL_TYP_PERSONEN', 'ZIEL_TYP_PERSONENBINDUNGEN', 'ZIEL_TYP_PERSONENEINSAETZE', 'ZIEL_TYP_TAETIGKEITEN', 'ZIEL_TYP_ORTE', 'ZIEL_TYP_ZEITVERTEILUNGEN', 'ZIEL_TYP_ENTSCHEIDUNGSFAELLE', 'ZIEL_TYP_FALLBETEILIGUNGEN', 'ZIEL_TYP_VERTRAGSVORGAENGE', 'ZIEL_TYP_STEUERUNGSBEZIEHUNGEN', 'ZIEL_TYP_RAEUME', 'ZIEL_TYP_ARBEITSMITTEL', 'ZIEL_TYP_RESSOURCENNUTZUNGEN', 'ZIEL_TYP_KOSTEN', 'ZIEL_TYP_KOSTENVERTEILUNGEN', 'ZIEL_TYP_ABRECHNUNGEN', 'ZIEL_TYP_INTERNEBEWERTUNGEN')
Add-Field -List "Belegverknuepfungen" -InternalName "ziel_id" -DisplayName 'Ziel-ID (stabile ID der referenzierten Zeile)' -Type Text -Required
# ziel_id: Generischer Verweis als Text statt 19 Einzel-Lookups (B2-Design uebernommen); Aufloesung durch Flow/Kanzlei.
Add-Field -List "Belegverknuepfungen" -InternalName "frage_id" -DisplayName 'Frage-ID, die belegt wird (z. B. P17, E08, V09, K05)' -Type Text
Add-Field -List "Belegverknuepfungen" -InternalName "belegter_sachverhalt" -DisplayName 'Belegter Sachverhalt' -Type Note
Add-Field -List "Belegverknuepfungen" -InternalName "seite_abschnitt" -DisplayName 'Seite oder Abschnitt in der Unterlage' -Type Text
Add-Field -List "Belegverknuepfungen" -InternalName "belegstatus" -DisplayName 'Belegstatus' -Type Choice -Required `
    -Choices @('N03_BELEGSTATUS_LIEGT_BEI', 'N03_BELEGSTATUS_BEREITS_UEBERMITTELT', 'N03_BELEGSTATUS_NUR_BENANNT', 'N03_BELEGSTATUS_WIRD_NACHGEREICHT', 'N03_BELEGSTATUS_NICHT_VORHANDEN')
Add-Field -List "Belegverknuepfungen" -InternalName "schaetzungsgrundlage_text" -DisplayName 'Geschätzte/unvollständige Angabe: Schätzungsgrundlage' -Type Note
Add-Field -List "Belegverknuepfungen" -InternalName "fehlende_information_text" -DisplayName 'Fehlende Information' -Type Note
Add-Field -List "Belegverknuepfungen" -InternalName "ansprechperson_ref" -DisplayName 'Zuständige Ansprechperson' -Type Lookup `
    -LookupList "Personen" -LookupField "display_label"
Add-Field -List "Belegverknuepfungen" -InternalName "erwarteter_nachreichtermin" -DisplayName 'Erwarteter Nachreichtermin' -Type DateOnly
Add-Field -List "Belegverknuepfungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

# ---------------------------------------------------------------------------
# Liste: InterneBewertungen
# NUR INTERN, eingeschraenkte Berechtigungen - Auswertungshilfen zu Anhang A (A1-A7)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "InterneBewertungen"
Add-Field -List "InterneBewertungen" -InternalName "bewertung_id" -DisplayName 'Bewertungs-ID (intern vergeben)' -Type Text -Required
Add-Field -List "InterneBewertungen" -InternalName "bezug_typ" -DisplayName 'Bezugstyp der Bewertung' -Type Choice -Required `
    -Choices @('BEWERTUNG_BEZUGSTYP_TAETIGKEIT', 'BEWERTUNG_BEZUGSTYP_FALL')
Add-Field -List "InterneBewertungen" -InternalName "taetigkeit_ref" -DisplayName 'Bezug: Tätigkeit' -Type Lookup `
    -LookupList "Taetigkeiten" -LookupField "display_label"
Add-Field -List "InterneBewertungen" -InternalName "fall_ref" -DisplayName 'Bezug: Entscheidungsfall' -Type Lookup `
    -LookupList "Entscheidungsfaelle" -LookupField "display_label"
Add-Field -List "InterneBewertungen" -InternalName "pruefungszusammenhang" -DisplayName 'Prüfungszusammenhang (z. B. tatsächliche Verwaltung, Konzernleistungen, Organrecht, VP-Stewardship, OECD-MK Art. 5)' -Type Text -Required
Add-Field -List "InterneBewertungen" -InternalName "einordnung" -DisplayName 'Vorläufige Einordnung' -Type Note -Required
Add-Field -List "InterneBewertungen" -InternalName "begruendung" -DisplayName 'Begründung' -Type Note
Add-Field -List "InterneBewertungen" -InternalName "quellen" -DisplayName 'Quellenverweis (interner Anhang A, Abschnitte A1-A7)' -Type Note
Add-Field -List "InterneBewertungen" -InternalName "pruefer_name" -DisplayName 'Prüfende Person' -Type Text
Add-Field -List "InterneBewertungen" -InternalName "pruefdatum" -DisplayName 'Prüfdatum' -Type DateOnly
Add-Field -List "InterneBewertungen" -InternalName "display_label" -DisplayName 'Anzeigelabel (eindeutig, für Lookups)' -Type Text

Set-RestrictedPermission -List "InterneBewertungen"

Write-Host ""
Write-Host "Fertig. Alle 20 Substanzpruefungs-Listen sowie die Dokumentbibliothek Substanznachweise sind angelegt bzw. angeglichen."
Write-Host "Ersetzt die fruehere SH0-SH11-Modellierung vollstaendig (Update 1, siehe PR-Beschreibung)."
Write-Host "Wiederverwendet (nicht neu angelegt, siehe Datenmodell Abschnitt \"Wiederverwendung\"):"
Write-Host "  - 'Eingang_Fehler' (DE/AO) fuer fehlgeschlagene Formular-Uebernahmen dieses Moduls."
Write-Host "  - '4_Beteiligte_und_Quoten' (DE/AO) als Lookup-Ziel fuer Gesellschaften.ao_participation_ref und weitere Beteiligungsbezuege."
Write-Host "  - '3_Personen_und_Vertretung' und '5_Betriebsstaetten' (DE/AO) nur als optionale Cross-Reference-Lookups."
Write-Host "Falls diese Listen auf der Zielsite noch nicht existieren, zuerst DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 ausfuehren."
Write-Host ""
Write-Warning "InterneBewertungen hat eine gebrochene Rechtevererbung erhalten - bitte manuell die zulaessige Pruefergruppe eintragen (siehe sharepoint-forms/README.md)."
Write-Host "Naechster Schritt: siehe DE/Substanz-Holding-KG/sharepoint-forms/README.md, Abschnitt E (Forms-Einrichtung) und F (Freigabe/Rollout)."
