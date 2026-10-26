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
      Punkt 2 der fachlichen Pruefung: case_id (und neu: access_code) in
      0_Fallsteuerung sind weder indiziert noch eindeutig. SharePoint verlangt,
      dass ein Feld zuerst indiziert wird, bevor EnforceUniqueValues gesetzt
      werden kann. Schlaegt EnforceUniqueValues fehl (z. B. weil aus einem
      frueheren, nicht-idempotenten Lauf bereits doppelte Werte existieren),
      wird dies nur als Warnung ausgegeben, damit der Rest des Skripts
      weiterlaeuft.
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
      Punkt 10 der fachlichen Pruefung: Loeschverhalten von Lookups definieren.
      - "Restrict" fuer den tragenden case_id-Bezug jeder Folgeliste: ein
        Fallsteuerungs-Datensatz darf nicht geloescht werden, solange noch
        Folgedatensaetze darauf verweisen (Datenintegritaet/Revisionssicherheit).
      - "None" (Standard, unveraendert) fuer die optionalen Sekundaerbezuege in
        8_Unterlagen (related_person/related_participation/related_site), damit
        das Loeschen einer Person/Beteiligung/Betriebsstaette nicht an einer
        angehaengten Unterlage scheitert.
      Hinweis: SharePoint erlaubt das nachtraegliche Aendern des
      Loeschverhaltens eines Lookup-Felds nur eingeschraenkt; schlaegt das Setzen
      fehl, wird nur gewarnt.
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
      Zentrale Feld-Anlage- und -Angleichungsfunktion.

      Neu gegenueber der Vorversion:
      - -Type DateOnly: reines Datumsfeld ohne Uhrzeit (Punkt 3).
      - -Type URL: Hyperlink-Feld (fuer file_link in 8_Unterlagen).
      - -DefaultValue: Default fuer Boolean/Text/Note/Number (Punkt 7).
      - -Min/-Max: Wertebereich fuer Number-Felder (Punkt 10: share_percentage 0-100).
      - -ValidationFormula/-ValidationMessage: Spaltenvalidierung (Punkt 10:
        notification_year).
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
        [switch]$EnforceUniqueValues,
        [string]$ValidationFormula,
        [string]$ValidationMessage
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
# Liste 0: Fallsteuerung (zuerst, da alle Folgelisten hierauf verweisen)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "0_Fallsteuerung"
Add-Field -List "0_Fallsteuerung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "0_Fallsteuerung" -InternalName "access_code" -DisplayName "Zugangscode (Mandantenpruefung)" -Type Text `
    -Indexed -EnforceUniqueValues
# access_code: neuer Zufallswert je Fall, da Fall-IDs im Format JJJJ-NNNN leicht
# erratbar sind (fortlaufende Nummer). Der auslösende Power-Automate-Flow soll
# den Wert bei Fallanlage setzen, z. B. per Ausdruck toUpper(substring(guid(),0,10)).
# Spaetere Flows pruefen case_id UND access_code gemeinsam, bevor eine
# Formularantwort einem Fall zugeordnet wird. Nicht als -Required angelegt,
# da bestehende Faelle ohne Nachtrag sonst nicht mehr bearbeitbar waeren; siehe
# README.md fuer die empfohlene Nachtrags-/Migrationsvorgehensweise.
Add-Field -List "0_Fallsteuerung" -InternalName "direction" -DisplayName "Richtung" -Type Choice -Required `
    -Choices @("Inbound", "Outbound")
Add-Field -List "0_Fallsteuerung" -InternalName "form_type" -DisplayName "Rechtsform / Formulartyp" -Type Choice -Required `
    -Choices @("Einzelunternehmen", "Kapitalgesellschaft oder Genossenschaft", "Personengesellschaft oder -gemeinschaft", "Körperschaft nach ausländischem Recht", "BZSt2-Mitteilung")
Add-Field -List "0_Fallsteuerung" -InternalName "already_registered" -DisplayName "Bereits steuerlich erfasst" -Type Boolean -Required
Add-Field -List "0_Fallsteuerung" -InternalName "existing_tax_number" -DisplayName "Bestehende Steuernummer" -Type Text
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office_country" -DisplayName "Land des Finanzamts" -Type Text -Required
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office" -DisplayName "Zustaendiges Finanzamt" -Type Text -Required
Add-Field -List "0_Fallsteuerung" -InternalName "target_notification" -DisplayName "Zielmeldung (BZSt2-Sachverhalt)" -Type Choice `
    -Choices @("Betriebe/Betriebsstätten", "PersG-Beteiligung", "KapG-Beteiligung", "Drittstaat-Beherrschung", "Negativmeldung")
Add-Field -List "0_Fallsteuerung" -InternalName "processing_note" -DisplayName "Persoenliche Bearbeitungsnotiz" -Type Note
Add-Field -List "0_Fallsteuerung" -InternalName "case_status" -DisplayName "Status" -Type Choice -Required `
    -Choices @("offen", "in Bearbeitung", "vollständig", "übermittelt")
# created_by / created_at: SharePoint-Systemfelder Author/Created werden verwendet, keine Zusatzspalte noetig.

# ---------------------------------------------------------------------------
# Liste 1: Allgemeiner Stammblock
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "1_Allgemeiner_Stammblock"
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "party_type" -DisplayName "Art des Meldepflichtigen" -Type Choice -Required `
    -Choices @("Person", "Firma")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "first_name" -DisplayName "Vorname" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "name_addition" -DisplayName "Namensvorsatz / -zusatz" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "religion" -DisplayName "Religion" -Type Choice `
    -Choices @("keine", "römisch-katholisch", "evangelisch", "sonstige")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "id_number" -DisplayName "Identifikationsnummer / Wirtschafts-IdNr." -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "legal_form" -DisplayName "Rechtsform" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "address_type" -DisplayName "Adressart" -Type Choice -Required `
    -Choices @("Inland", "Ausland")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "street" -DisplayName "Strasse, Hausnummer, Zusatz" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "address_supplement" -DisplayName "Adressergänzung" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "postal_code_city" -DisplayName "Postleitzahl, Ort" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "country" -DisplayName "Staat" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "po_box" -DisplayName "Postfach" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "phone" -DisplayName "Telefon" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "website" -DisplayName "Internetadresse" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "business_activity" -DisplayName "Genaue Taetigkeit" -Type Note -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "asset_management_only" -DisplayName "Ausschliesslich vermoegensverwaltend taetig" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "deviating_management_place" -DisplayName "Abweichender Ort der Geschäftsleitung" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "management_address" -DisplayName "Ort der Geschäftsleitung - Adresse" -Type Note
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_id_type" -DisplayName "Art der Steuernummer-Angabe" -Type Choice -Required `
    -Choices @("bestehend", "neu beantragen")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_number" -DisplayName "Steuernummer" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_office" -DisplayName "Zustaendiges Finanzamt" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_name" -DisplayName "Steuerliche Beratung - Name/Firma" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_address" -DisplayName "Steuerliche Beratung - Adresse" -Type Note
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "advisor_is_authorized_recipient" -DisplayName "Steuerliche Beratung ist empfangsbevollmächtigt" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_iban" -DisplayName "Bank - IBAN" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_bic" -DisplayName "Bank - BIC" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_account_holder" -DisplayName "Bank - Kontoinhaber" -Type Text
# --- Abschnitt 9 (Mandanten-Erhebungsmatrix) ergaenzt (Datenmodell 9.2 "Bank/Kontakt") ---
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "callback_email" -DisplayName "Rueckfrage-E-Mail (freiwillig)" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "sepa_desired" -DisplayName "SEPA-Lastschrift gewuenscht" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "par27_ao_agreement" -DisplayName "Zustimmung zur Zustaendigkeitsvereinbarung nach Paragraf 27 AO" -Type Boolean
# par27_ao_agreement ist nur bei form_type = Koerperschaft nach auslaendischem
# Recht fachlich unbedingt (Datenmodell 2.4, Kz 18). Da SharePoint keine
# formularuebergreifend bedingten Pflichtfelder kennt (siehe README.md
# Abschnitt C), bleibt die Spalte hier optional; die Pflicht wird ueber
# Forms-Branching in Formular 1 durchgesetzt.

# ---------------------------------------------------------------------------
# Liste 2: Unternehmens-/Gruendungsmodul (Inbound; auch Einzelunternehmen, s. E.9)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "2_Unternehmens_Gruendungsmodul"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "company_name" -DisplayName "Bezeichnung des Unternehmens" -Type Text -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "legal_form" -DisplayName "Rechtsform" -Type Choice -Required `
    -Choices @(
        "Einzelunternehmen", "Freiberufliche Tätigkeit", "Eingetragener Kaufmann (e.K.)",
        "GmbH", "UG (haftungsbeschränkt)", "AG", "SE", "KGaA", "eingetragene Genossenschaft (eG)",
        "GbR/eGbR", "OHG", "KG", "GmbH & Co. KG", "PartG/PartG mbB",
        "sonstige deutsche Rechtsform", "ausländische Rechtsform")
# Rechtsform-Choices Punkt 8 erweitert: Personengesellschaften (GbR/eGbR, OHG, KG,
# GmbH & Co. KG, PartG/PartG mbB), SE, KGaA sowie Einzelunternehmen-Varianten,
# da Formular 2 laut Routing-Tabelle README.md Abschnitt E.9 nicht nur fuer
# Kapitalgesellschaften, sondern auch fuer Einzelunternehmen und
# Personengesellschaften durchlaufen wird (Datenmodell Abschnitt 9.1).
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_type" -DisplayName "Gruendungsart" -Type Choice -Required `
    -Choices @("Neugründung", "Übernahme", "Umwandlung", "Bargründung", "Sachgründung")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_date" -DisplayName "Gruendungsdatum" -Type DateOnly -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "activity_start_date" -DisplayName "Beginn der Taetigkeit" -Type DateOnly -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "notarial_deed_date" -DisplayName "Notarielle Errichtung / Musterprotokoll vom" -Type DateOnly
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_amount" -DisplayName "Grund-/Stammkapital - Betrag" -Type Number
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_currency" -DisplayName "Grund-/Stammkapital - Waehrung" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "paid_in_capital" -DisplayName "Eingezahltes Kapital" -Type Number
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_status" -DisplayName "Handelsregister-Status" -Type Choice -Required `
    -Choices @("beabsichtigt", "beantragt", "erfolgt")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "registry_court" -DisplayName "Ort des Amtsgerichts" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_number" -DisplayName "Register / Registernummer" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor" -DisplayName "Vorheriger Inhaber / Vorunternehmen" -Type Note
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "deviating_fiscal_year" -DisplayName "Abweichendes Wirtschaftsjahr" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "fiscal_year_start" -DisplayName "Wirtschaftsjahr - Beginn" -Type DateOnly
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "profit_determination_method" -DisplayName "Gewinnermittlungsart" -Type Choice -Required `
    -Choices @("Betriebsvermögensvergleich", "Einnahmenüberschussrechnung")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_opening_year" -DisplayName "Voraussichtlicher Gewinn Eroeffnungsjahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_following_year" -DisplayName "Voraussichtlicher Gewinn Folgejahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "part_of_group" -DisplayName "Konzernzugehoerigkeit" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "controlling_company_name" -DisplayName "Herrschendes Unternehmen - Name" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_controlling_company_for_tax_group" -DisplayName "Organtraegerschaft" -Type Boolean
# --- Abschnitt 9 ergaenzt (Datenmodell 2.3/9.3, Personengesellschaft) ---
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "legal_capacity" -DisplayName "Rechtsfaehigkeit (Personengesellschaft)" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "profit_distribution_key" -DisplayName "Aufteilungsschluessel (Gewinn-/Verlustverteilung)" -Type Text
# legal_capacity ist bei form_type = Personengesellschaft/-gemeinschaft laut
# Datenmodell Kz 33 unbedingt, bei anderen Formulartypen nicht einschlaegig;
# deshalb ohne -Required, Pflicht ueber Forms-Branching (siehe README.md E.2).

# ---------------------------------------------------------------------------
# Liste 3: Personen und Vertretung
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "3_Personen_und_Vertretung"
Add-Field -List "3_Personen_und_Vertretung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "3_Personen_und_Vertretung" -InternalName "role" -DisplayName "Rolle" -Type Choice -Required `
    -Choices @("Gesetzlicher Vertreter", "Ständiger Vertreter", "Empfangsbevollmächtigter", "Steuerliche Beratung", "Ehegatte/Lebenspartner")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "person_type" -DisplayName "Art der Person" -Type Choice -Required `
    -Choices @("natürlich", "nicht natürlich")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "first_name" -DisplayName "Vorname" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly
Add-Field -List "3_Personen_und_Vertretung" -InternalName "id_number" -DisplayName "Identifikationsnummer" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "profession" -DisplayName "Beruf / Taetigkeit" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "phone" -DisplayName "Telefon" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "tax_reference" -DisplayName "Steuerliche Kennzeichen" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "dependency_status" -DisplayName "Abhaengige/unabhaengige Person" -Type Choice `
    -Choices @("abhängig", "unabhängig")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "power_to_conclude_contracts" -DisplayName "Abschlussvollmacht" -Type Boolean
Add-Field -List "3_Personen_und_Vertretung" -InternalName "is_authorized_recipient" -DisplayName "Empfangsbevollmaechtigt" -Type Boolean
Add-Field -List "3_Personen_und_Vertretung" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text
# display_label (Punkt 10, "Lookup-Anzeigefeld eindeutig machen"): last_name_or_company
# ist bei Namensgleichheit nicht eindeutig. display_label soll vom auslösenden
# Flow unmittelbar nach Elementanlage befuellt werden, z. B.
# "<Name> (<Rolle>, Fall <case_id>, ID <ID>)", und wird als ShowField der
# Lookup-Spalte 8_Unterlagen/related_person verwendet statt last_name_or_company.

# ---------------------------------------------------------------------------
# Liste 4: Beteiligte und Quoten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "4_Beteiligte_und_Quoten"
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "sequence_number" -DisplayName "Laufende Nummer / Zeichnernummer" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participant_type" -DisplayName "Art des Beteiligten" -Type Choice -Required `
    -Choices @("natürlich", "nicht natürlich")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateOnly
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
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "trust_relationship" -DisplayName "Treuhandverhaeltnis" -Type Boolean -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "expected_profit_share_opening_year" -DisplayName "Voraussichtlicher Gewinnanteil Eroeffnungsjahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "expected_profit_share_following_year" -DisplayName "Voraussichtlicher Gewinnanteil Folgejahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "limited_tax_liability" -DisplayName "Beschraenkte Steuerpflicht" -Type Boolean
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participation_since" -DisplayName "Beteiligt seit dem" -Type DateOnly
# --- Abschnitt 9 ergaenzt (Datenmodell 9.2 "Beteiligte": Stimmrechte) ---
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "voting_rights_percentage" -DisplayName "Stimmrechte in Prozent" -Type Number `
    -Min 0 -Max 100
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste 5: Betriebsstaetten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "5_Betriebsstaetten"
Add-Field -List "5_Betriebsstaetten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "5_Betriebsstaetten" -InternalName "site_name" -DisplayName "Bezeichnung der Betriebsstätte/Einrichtung" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "country" -DisplayName "Land" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "site_type" -DisplayName "Art der Einrichtung" -Type Choice -Required `
    -Choices @("fest", "nicht fest")
Add-Field -List "5_Betriebsstaetten" -InternalName "ownership_status" -DisplayName "Eigentumsverhältnis" -Type Choice `
    -Choices @("Eigentum", "Miete", "Nutzung")
Add-Field -List "5_Betriebsstaetten" -InternalName "usage_type" -DisplayName "Nutzungsart" -Type Choice `
    -Choices @("Lagerung", "Verarbeitung", "Einkauf", "Werbung", "Sonstige")
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_from" -DisplayName "Taetigkeitsdauer - von" -Type DateOnly
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_to" -DisplayName "Taetigkeitsdauer - bis" -Type DateOnly
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_to_unknown" -DisplayName "Taetigkeitsdauer bis unbekannt" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "vat_relevant_site" -DisplayName "Umsatzsteuerliche Betriebsstätte" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "contact" -DisplayName "Telefon / Internetadresse" -Type Text
Add-Field -List "5_Betriebsstaetten" -InternalName "payroll_tax_site" -DisplayName "Lohnsteuerliche Betriebsstätte" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "display_label" -DisplayName "Anzeigelabel (eindeutig, fuer Lookups)" -Type Text

# ---------------------------------------------------------------------------
# Liste 6: Steuer- und Umsatzsteuerprofil (nur Inbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "6_Steuer_und_Umsatzsteuerprofil"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_opening_year" -DisplayName "Geschaetzter Umsatz Eroeffnungsjahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_following_year" -DisplayName "Geschaetzter Umsatz Folgejahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule" -DisplayName "Kleinunternehmer-Regelung" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule_waiver" -DisplayName "Verzicht auf Kleinunternehmer-Regelung" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_vat_amount" -DisplayName "Voraussichtliche USt (Zahllast/Ueberschuss)" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_filing_period" -DisplayName "Voranmeldungszeitraum" -Type Choice `
    -Choices @("Monat", "Quartal")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_taxation_method" -DisplayName "Soll-/Ist-Besteuerung" -Type Choice `
    -Choices @("Soll-Besteuerung", "Ist-Besteuerung")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "request_vat_id" -DisplayName "USt-IdNr. beantragen" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "previous_vat_id" -DisplayName "Fruehere USt-IdNr." -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "oss_procedure" -DisplayName "OSS-Verfahren" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "own_webshop" -DisplayName "Eigener Webshop" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "electronic_interface" -DisplayName "Elektronische Schnittstelle" -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "construction_services_over_10pct" -DisplayName "Bauleistungen ueber 10% Weltumsatz" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "employees_total" -DisplayName "Anzahl Arbeitnehmer insgesamt" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "payroll_start_date" -DisplayName "Beginn Lohnzahlungen" -Type DateOnly
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_payroll_tax" -DisplayName "Voraussichtliche Lohnsteuer" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "exemption_certificate_construction" -DisplayName "Freistellungsbescheinigung Paragraf 48b EStG" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 7: Auslandsmitteilung (BZSt2, nur Outbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "7_Auslandsmitteilung_BZSt2"
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "notification_year" -DisplayName "Mitteilungsjahr" -Type Text -Required `
    -ValidationFormula "AND(ISNUMBER(VALUE([Mitteilungsjahr])),LEN([Mitteilungsjahr])=4)" `
    -ValidationMessage "Bitte eine vierstellige Jahreszahl eingeben (z. B. 2026)."
# notification_year bewusst als Text statt Number (Punkt 10): ein SharePoint-
# Number-Feld zeigt Jahreszahlen ab 1000 je nach Gebietsschema mit
# Tausendertrennzeichen an (z. B. "2.026"), was fachlich falsch wirkt. Die
# Spaltenvalidierung erzwingt weiterhin eine vierstellige Zahl als Text.
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
Add-Field -List "8_Unterlagen" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id" -DeleteBehavior Restrict
Add-Field -List "8_Unterlagen" -InternalName "document_type" -DisplayName "Dokumenttyp" -Type Choice -Required `
    -Choices @("Gesellschaftsvertrag", "Vollmacht Steuerberatung", "Empfangsvollmacht", "SEPA-Mandat", "Handelsregisterauszug", "Sachgründungsbericht", "Ansässigkeitsbescheinigung", "Sonstiges")
Add-Field -List "8_Unterlagen" -InternalName "related_object_text" -DisplayName "Bezug zu Objekt (Freitext aus Formular)" -Type Text
# related_object_text (Punkt 6): bildet die Forms-Frage "Bezug zu Objekt" (Text,
# README.md E.8 Frage 3) ab. Ohne diese Spalte konnte ein einfacher
# Power-Automate-Flow die Forms-Antwort gar nicht speichern, da die
# Lookup-Spalten related_case/related_person/related_participation/related_site
# keinen Freitext annehmen. related_object_text ist die Rohantwort; die
# Lookups werden danach manuell oder durch einen erweiterten Flow aufgeloest.
Add-Field -List "8_Unterlagen" -InternalName "required" -DisplayName "Erforderlich" -Type Boolean -DefaultValue "0"
Add-Field -List "8_Unterlagen" -InternalName "uploaded" -DisplayName "Vorhanden / hochgeladen" -Type Boolean -DefaultValue "0"
# required/uploaded (Punkt 7): keine Forms-Frage, daher nicht mehr -Required;
# Default FALSE, damit neu erstellte Elemente ohne explizite Eingabe konsistent
# starten. Beide Felder werden von der Kanzlei intern gepflegt.
Add-Field -List "8_Unterlagen" -InternalName "note" -DisplayName "Hinweis" -Type Note
Add-Field -List "8_Unterlagen" -InternalName "file_link" -DisplayName "Link zur Datei (falls extern abgelegt)" -Type URL
# file_link (Punkt 6): Hyperlink-Feld fuer den Fall, dass eine Datei nicht ueber
# den Forms-Datei-Upload (erfordert Microsoft-Konto, siehe README.md E.8),
# sondern ueber einen separaten Kanzlei-Upload-Weg eingesammelt und hier nur
# verlinkt wird. Wird nicht aus einer Forms-Frage befuellt, sondern durch Flow
# oder manuell.
# related_object (Nachschlagefeld Fall/Person/Beteiligung/Betriebsstaette) und file (Anhang)
# werden nach Anlage aller Listen manuell verknuepft, da PnP kein Multi-Listen-Lookup-Feld kennt;
# ersatzweise vier separate Lookup-Spalten (related_case, related_person, related_participation, related_site)
# plus Standard-Anlagenfunktion der Liste verwenden.
Add-Field -List "8_Unterlagen" -InternalName "related_case" -DisplayName "Bezug: Fall" -Type Lookup `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "8_Unterlagen" -InternalName "related_person" -DisplayName "Bezug: Person" -Type Lookup `
    -LookupList "3_Personen_und_Vertretung" -LookupField "display_label"
Add-Field -List "8_Unterlagen" -InternalName "related_participation" -DisplayName "Bezug: Beteiligung" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "display_label"
Add-Field -List "8_Unterlagen" -InternalName "related_site" -DisplayName "Bezug: Betriebsstätte" -Type Lookup `
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
