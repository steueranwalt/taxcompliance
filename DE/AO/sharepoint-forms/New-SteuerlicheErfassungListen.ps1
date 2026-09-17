#Requires -Modules PnP.PowerShell
<#
    Legt die SharePoint-Listenfamilie "Steuerliche Erfassung DE / Auslandsbezug" an
    (Liste 0-8 plus interne Referenzliste "Technische Mindestfelder").

    Feldkatalog und Architektur: siehe
    DE/AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md
    DE/AO/formulardaten-roherfassung.md
    DE/AO/sharepoint-forms/README.md

    Vorbedingung: Vor Ausfuehrung pruefen, welche der beiden Zielsites externes
    Teilen technisch zulaesst (Website-Einstellungen -> Freigabe -> Erweiterte
    Einstellungen):
      1. https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei
      2. https://obenhaus.sharepoint.com/sites/service
    -SiteUrl entsprechend setzen.

    Ausfuehrung (Beispiel):
      .\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"

    -ClientId ist erforderlich, wenn der Tenant die generische PnP-Management-Shell-App
    (31359c7f-bd7e-475c-86db-fdb8c937548e) blockiert; dann eine tenant-eigene
    App-Registrierung mit delegierter Berechtigung "AllSites.FullControl" verwenden.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $false)]
    [string]$ClientId
)

$ErrorActionPreference = "Stop"
if ($ClientId) {
    Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
}
else {
    Connect-PnPOnline -Url $SiteUrl -Interactive
}

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
}

function Get-XmlEscaped {
    param([string]$Text)
    return [System.Security.SecurityElement]::Escape($Text)
}

function Add-Field {
    param(
        [string]$List,
        [string]$InternalName,
        [string]$DisplayName,
        [string]$Type,
        [switch]$Required,
        [string[]]$Choices,
        [string]$LookupList,
        [string]$LookupField = "Title"
    )
    $existing = Get-PnPField -List $List -Identity $InternalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  Feld existiert bereits: $List / $InternalName"
        return
    }
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
            $fieldXml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$escapedDisplayName' Required='$requiredAttr' List='{$($targetList.Id)}' ShowField='$LookupField' />"
            Add-PnPFieldFromXml -List $List -FieldXml $fieldXml | Out-Null
        }
        default {
            Add-PnPField -List $List -InternalName $InternalName -DisplayName $DisplayName `
                -Type $Type -Required:$Required | Out-Null
        }
    }
    Write-Host "  Feld angelegt: $List / $InternalName ($Type)"
}

# ---------------------------------------------------------------------------
# Liste 0: Fallsteuerung (zuerst, da alle Folgelisten hierauf verweisen)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "0_Fallsteuerung"
Add-Field -List "0_Fallsteuerung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Text -Required
Add-Field -List "0_Fallsteuerung" -InternalName "direction" -DisplayName "Richtung" -Type Choice -Required `
    -Choices @("Inbound", "Outbound")
Add-Field -List "0_Fallsteuerung" -InternalName "form_type" -DisplayName "Rechtsform / Formulartyp" -Type Choice -Required `
    -Choices @("Einzelunternehmen", "Kapitalgesellschaft oder Genossenschaft", "Personengesellschaft oder -gemeinschaft", "Koerperschaft nach auslaendischem Recht", "BZSt2-Mitteilung")
Add-Field -List "0_Fallsteuerung" -InternalName "already_registered" -DisplayName "Bereits steuerlich erfasst" -Type Boolean -Required
Add-Field -List "0_Fallsteuerung" -InternalName "existing_tax_number" -DisplayName "Bestehende Steuernummer" -Type Text
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office_country" -DisplayName "Land des Finanzamts" -Type Text -Required
Add-Field -List "0_Fallsteuerung" -InternalName "tax_office" -DisplayName "Zustaendiges Finanzamt" -Type Text -Required
Add-Field -List "0_Fallsteuerung" -InternalName "target_notification" -DisplayName "Zielmeldung (BZSt2-Sachverhalt)" -Type Choice `
    -Choices @("Betriebe/Betriebsstaetten", "PersG-Beteiligung", "KapG-Beteiligung", "Drittstaat-Beherrschung", "Negativmeldung")
Add-Field -List "0_Fallsteuerung" -InternalName "processing_note" -DisplayName "Persoenliche Bearbeitungsnotiz" -Type Note
Add-Field -List "0_Fallsteuerung" -InternalName "case_status" -DisplayName "Status" -Type Choice -Required `
    -Choices @("offen", "in Bearbeitung", "vollstaendig", "uebermittelt")
# created_by / created_at: SharePoint-Systemfelder Author/Created werden verwendet, keine Zusatzspalte noetig.

# ---------------------------------------------------------------------------
# Liste 1: Allgemeiner Stammblock
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "1_Allgemeiner_Stammblock"
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "party_type" -DisplayName "Art des Meldepflichtigen" -Type Choice -Required `
    -Choices @("Person", "Firma")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "first_name" -DisplayName "Vorname" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "name_addition" -DisplayName "Namensvorsatz / -zusatz" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateTime
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "religion" -DisplayName "Religion" -Type Choice `
    -Choices @("keine", "roemisch-katholisch", "evangelisch", "sonstige")
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
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "deviating_management_place" -DisplayName "Abweichender Ort der Geschaeftsleitung" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "management_address" -DisplayName "Ort der Geschaeftsleitung - Adresse" -Type Note
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_id_type" -DisplayName "Art der Steuernummer-Angabe" -Type Choice -Required `
    -Choices @("bestehend", "neu beantragen")
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_number" -DisplayName "Steuernummer" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_office" -DisplayName "Zustaendiges Finanzamt" -Type Text -Required
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_name" -DisplayName "Steuerliche Beratung - Name/Firma" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "tax_advisor_address" -DisplayName "Steuerliche Beratung - Adresse" -Type Note
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "advisor_is_authorized_recipient" -DisplayName "Steuerliche Beratung ist empfangsbevollmaechtigt" -Type Boolean
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_iban" -DisplayName "Bank - IBAN" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_bic" -DisplayName "Bank - BIC" -Type Text
Add-Field -List "1_Allgemeiner_Stammblock" -InternalName "bank_account_holder" -DisplayName "Bank - Kontoinhaber" -Type Text

# ---------------------------------------------------------------------------
# Liste 2: Unternehmens-/Gruendungsmodul (nur Inbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "2_Unternehmens_Gruendungsmodul"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "company_name" -DisplayName "Bezeichnung des Unternehmens" -Type Text -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "legal_form" -DisplayName "Rechtsform" -Type Choice -Required `
    -Choices @("GmbH", "AG", "UG", "Genossenschaft", "sonstige deutsche Rechtsform", "auslaendische Rechtsform")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_type" -DisplayName "Gruendungsart" -Type Choice -Required `
    -Choices @("Neugruendung", "Uebernahme", "Umwandlung", "Bargruendung", "Sachgruendung")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "formation_date" -DisplayName "Gruendungsdatum" -Type DateTime -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "activity_start_date" -DisplayName "Beginn der Taetigkeit" -Type DateTime -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "notarial_deed_date" -DisplayName "Notarielle Errichtung / Musterprotokoll vom" -Type DateTime
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_amount" -DisplayName "Grund-/Stammkapital - Betrag" -Type Number
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "share_capital_currency" -DisplayName "Grund-/Stammkapital - Waehrung" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "paid_in_capital" -DisplayName "Eingezahltes Kapital" -Type Number
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_status" -DisplayName "Handelsregister-Status" -Type Choice -Required `
    -Choices @("beabsichtigt", "beantragt", "erfolgt")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "registry_court" -DisplayName "Ort des Amtsgerichts" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "register_number" -DisplayName "Register / Registernummer" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "predecessor" -DisplayName "Vorheriger Inhaber / Vorunternehmen" -Type Note
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "deviating_fiscal_year" -DisplayName "Abweichendes Wirtschaftsjahr" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "fiscal_year_start" -DisplayName "Wirtschaftsjahr - Beginn" -Type DateTime
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "profit_determination_method" -DisplayName "Gewinnermittlungsart" -Type Choice -Required `
    -Choices @("Betriebsvermoegensvergleich", "Einnahmenueberschussrechnung")
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_opening_year" -DisplayName "Voraussichtlicher Gewinn Eroeffnungsjahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "expected_profit_following_year" -DisplayName "Voraussichtlicher Gewinn Folgejahr" -Type Number -Required
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "part_of_group" -DisplayName "Konzernzugehoerigkeit" -Type Boolean
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "controlling_company_name" -DisplayName "Herrschendes Unternehmen - Name" -Type Text
Add-Field -List "2_Unternehmens_Gruendungsmodul" -InternalName "is_controlling_company_for_tax_group" -DisplayName "Organtraegerschaft" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 3: Personen und Vertretung
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "3_Personen_und_Vertretung"
Add-Field -List "3_Personen_und_Vertretung" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "3_Personen_und_Vertretung" -InternalName "role" -DisplayName "Rolle" -Type Choice -Required `
    -Choices @("Gesetzlicher Vertreter", "Staendiger Vertreter", "Empfangsbevollmaechtigter", "Steuerliche Beratung", "Ehegatte/Lebenspartner")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "person_type" -DisplayName "Art der Person" -Type Choice -Required `
    -Choices @("natuerlich", "nicht natuerlich")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "salutation_title" -DisplayName "Anrede / Titel" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "first_name" -DisplayName "Vorname" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateTime
Add-Field -List "3_Personen_und_Vertretung" -InternalName "id_number" -DisplayName "Identifikationsnummer" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "profession" -DisplayName "Beruf / Taetigkeit" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "3_Personen_und_Vertretung" -InternalName "phone" -DisplayName "Telefon" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "tax_reference" -DisplayName "Steuerliche Kennzeichen" -Type Text
Add-Field -List "3_Personen_und_Vertretung" -InternalName "dependency_status" -DisplayName "Abhaengige/unabhaengige Person" -Type Choice `
    -Choices @("abhaengig", "unabhaengig")
Add-Field -List "3_Personen_und_Vertretung" -InternalName "power_to_conclude_contracts" -DisplayName "Abschlussvollmacht" -Type Boolean
Add-Field -List "3_Personen_und_Vertretung" -InternalName "is_authorized_recipient" -DisplayName "Empfangsbevollmaechtigt" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 4: Beteiligte und Quoten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "4_Beteiligte_und_Quoten"
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "sequence_number" -DisplayName "Laufende Nummer / Zeichnernummer" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participant_type" -DisplayName "Art des Beteiligten" -Type Choice -Required `
    -Choices @("natuerlich", "nicht natuerlich")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "last_name_or_company" -DisplayName "Name / Firma" -Type Text -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "date_of_birth" -DisplayName "Geburtsdatum" -Type DateTime
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "tax_reference" -DisplayName "Steuerliche Kennzeichen" -Type Text
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participation_type" -DisplayName "Art der Beteiligung" -Type Choice -Required `
    -Choices @("direkt", "mittelbar")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "role" -DisplayName "Rolle" -Type Choice -Required `
    -Choices @("Anteilseigner", "Gesellschafter", "Treuhaender")
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "nominal_share" -DisplayName "Beteiligung nominell" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "share_percentage" -DisplayName "Beteiligung in Prozent" -Type Number -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "fraction_numerator_denominator" -DisplayName "Zaehler / Nenner" -Type Text
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "trust_relationship" -DisplayName "Treuhandverhaeltnis" -Type Boolean -Required
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "expected_profit_share_opening_year" -DisplayName "Voraussichtlicher Gewinnanteil Eroeffnungsjahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "expected_profit_share_following_year" -DisplayName "Voraussichtlicher Gewinnanteil Folgejahr" -Type Number
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "limited_tax_liability" -DisplayName "Beschraenkte Steuerpflicht" -Type Boolean
Add-Field -List "4_Beteiligte_und_Quoten" -InternalName "participation_since" -DisplayName "Beteiligt seit dem" -Type DateTime

# ---------------------------------------------------------------------------
# Liste 5: Betriebsstaetten
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "5_Betriebsstaetten"
Add-Field -List "5_Betriebsstaetten" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "5_Betriebsstaetten" -InternalName "site_name" -DisplayName "Bezeichnung der Betriebsstaette/Einrichtung" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "country" -DisplayName "Land" -Type Text -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "address" -DisplayName "Adresse" -Type Note -Required
Add-Field -List "5_Betriebsstaetten" -InternalName "site_type" -DisplayName "Art der Einrichtung" -Type Choice -Required `
    -Choices @("fest", "nicht fest")
Add-Field -List "5_Betriebsstaetten" -InternalName "ownership_status" -DisplayName "Eigentumsverhaeltnis" -Type Choice `
    -Choices @("Eigentum", "Miete", "Nutzung")
Add-Field -List "5_Betriebsstaetten" -InternalName "usage_type" -DisplayName "Nutzungsart" -Type Choice `
    -Choices @("Lagerung", "Verarbeitung", "Einkauf", "Werbung", "Sonstige")
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_from" -DisplayName "Taetigkeitsdauer - von" -Type DateTime
Add-Field -List "5_Betriebsstaetten" -InternalName "activity_period_to" -DisplayName "Taetigkeitsdauer - bis" -Type DateTime
Add-Field -List "5_Betriebsstaetten" -InternalName "vat_relevant_site" -DisplayName "Umsatzsteuerliche Betriebsstaette" -Type Boolean
Add-Field -List "5_Betriebsstaetten" -InternalName "contact" -DisplayName "Telefon / Internetadresse" -Type Text
Add-Field -List "5_Betriebsstaetten" -InternalName "payroll_tax_site" -DisplayName "Lohnsteuerliche Betriebsstaette" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 6: Steuer- und Umsatzsteuerprofil (nur Inbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "6_Steuer_und_Umsatzsteuerprofil"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_opening_year" -DisplayName "Geschaetzter Umsatz Eroeffnungsjahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "estimated_revenue_following_year" -DisplayName "Geschaetzter Umsatz Folgejahr" -Type Number -Required
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule" -DisplayName "Kleinunternehmer-Regelung" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "small_business_rule_waiver" -DisplayName "Verzicht auf Kleinunternehmer-Regelung" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_vat_amount" -DisplayName "Voraussichtliche USt (Zahllast/Ueberschuss)" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "vat_filing_period" -DisplayName "Voranmeldungszeitraum" -Type Choice `
    -Choices @("Monat", "Quartal")
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "request_vat_id" -DisplayName "USt-IdNr. beantragen" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "previous_vat_id" -DisplayName "Fruehere USt-IdNr." -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "oss_procedure" -DisplayName "OSS-Verfahren" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "own_webshop" -DisplayName "Eigener Webshop" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "electronic_interface" -DisplayName "Elektronische Schnittstelle" -Type Text
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "construction_services_over_10pct" -DisplayName "Bauleistungen ueber 10% Weltumsatz" -Type Boolean
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "employees_total" -DisplayName "Anzahl Arbeitnehmer insgesamt" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "payroll_start_date" -DisplayName "Beginn Lohnzahlungen" -Type DateTime
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "expected_payroll_tax" -DisplayName "Voraussichtliche Lohnsteuer" -Type Number
Add-Field -List "6_Steuer_und_Umsatzsteuerprofil" -InternalName "exemption_certificate_construction" -DisplayName "Freistellungsbescheinigung Paragraf 48b EStG" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 7: Auslandsmitteilung (BZSt2, nur Outbound)
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "7_Auslandsmitteilung_BZSt2"
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "notification_year" -DisplayName "Mitteilungsjahr" -Type Number -Required
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "notification_subject" -DisplayName "Sachverhalt" -Type Choice -Required `
    -Choices @("Betriebe/Betriebsstaetten", "PersG-Beteiligung", "KapG-Beteiligung", "Drittstaat-Beherrschung", "Negativmeldung")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "tax_or_id_number" -DisplayName "Steuer-/Identifikationsnummer" -Type Text -Required
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_type" -DisplayName "Typ der Auslandseinheit" -Type Choice `
    -Choices @("Betriebsstaette", "Betrieb", "Personengesellschaft", "Kapitalgesellschaft", "Vermoegensmasse")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_name_legal_form" -DisplayName "Firmenname / Rechtsform" -Type Text
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_address" -DisplayName "Adresse / Staat" -Type Note
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "foreign_entity_formation_date" -DisplayName "Gruendungsdatum" -Type DateTime
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "activity_code" -DisplayName "Taetigkeitskennzahl (1-13)" -Type Choice `
    -Choices @("1 Land-/Forstwirtschaft", "2 Herstellung/Verarbeitung", "3 Kredit/Versicherung", "4 Handel", "5 Rechte/Muster", "6 VuV Grundstuecke", "7 VuV bewegliche Sachen", "8 Verwaltung", "9 Kapitalanlage", "10 Finanzierung", "11 sonstige Dienstleistungen", "12 Holding", "13 Sonstiges")
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "nominal_capital" -DisplayName "Nominalkapital / Kapital" -Type Number
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "registered_in_germany" -DisplayName "Im Inland steuerlich erfasst" -Type Boolean
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "participant_name_share" -DisplayName "Beteiligte - Name / Anteil in %" -Type Text
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "participation_since" -DisplayName "Beteiligt seit dem" -Type DateTime
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "third_country_control" -DisplayName "Drittstaat-Beherrschung" -Type Boolean
Add-Field -List "7_Auslandsmitteilung_BZSt2" -InternalName "advisor_involvement" -DisplayName "Mitwirkung Steuerberatung" -Type Boolean

# ---------------------------------------------------------------------------
# Liste 8: Unterlagen
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "8_Unterlagen"
Add-Field -List "8_Unterlagen" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "8_Unterlagen" -InternalName "document_type" -DisplayName "Dokumenttyp" -Type Choice -Required `
    -Choices @("Gesellschaftsvertrag", "Vollmacht Steuerberatung", "Empfangsvollmacht", "SEPA-Mandat", "Handelsregisterauszug", "Sachgruendungsbericht", "Ansaessigkeitsbescheinigung", "Sonstiges")
Add-Field -List "8_Unterlagen" -InternalName "required" -DisplayName "Erforderlich" -Type Boolean -Required
Add-Field -List "8_Unterlagen" -InternalName "uploaded" -DisplayName "Vorhanden / hochgeladen" -Type Boolean -Required
Add-Field -List "8_Unterlagen" -InternalName "note" -DisplayName "Hinweis" -Type Note
# related_object (Nachschlagefeld Fall/Person/Beteiligung/Betriebsstaette) und file (Anhang)
# werden nach Anlage aller Listen manuell verknuepft, da PnP kein Multi-Listen-Lookup-Feld kennt;
# ersatzweise vier separate Lookup-Spalten (related_case, related_person, related_participation, related_site)
# plus Standard-Anlagenfunktion der Liste verwenden.
Add-Field -List "8_Unterlagen" -InternalName "related_case" -DisplayName "Bezug: Fall" -Type Lookup `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "8_Unterlagen" -InternalName "related_person" -DisplayName "Bezug: Person" -Type Lookup `
    -LookupList "3_Personen_und_Vertretung" -LookupField "last_name_or_company"
Add-Field -List "8_Unterlagen" -InternalName "related_participation" -DisplayName "Bezug: Beteiligung" -Type Lookup `
    -LookupList "4_Beteiligte_und_Quoten" -LookupField "last_name_or_company"
Add-Field -List "8_Unterlagen" -InternalName "related_site" -DisplayName "Bezug: Betriebsstaette" -Type Lookup `
    -LookupList "5_Betriebsstaetten" -LookupField "site_name"

# ---------------------------------------------------------------------------
# Referenzliste (intern, kein Form): Technische Mindestfelder
# ---------------------------------------------------------------------------
New-ListIfMissing -Title "Technische_Mindestfelder"
Add-Field -List "Technische_Mindestfelder" -InternalName "case_id" -DisplayName "Fall-ID" -Type Lookup -Required `
    -LookupList "0_Fallsteuerung" -LookupField "case_id"
Add-Field -List "Technische_Mindestfelder" -InternalName "entity_or_person_id" -DisplayName "entity_id / person_id" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "object_type" -DisplayName "object_type" -Type Text -Required
Add-Field -List "Technische_Mindestfelder" -InternalName "object_sequence" -DisplayName "object_sequence" -Type Number
Add-Field -List "Technische_Mindestfelder" -InternalName "source_form_type" -DisplayName "source_form_type" -Type Choice -Required `
    -Choices @("EU", "KapG", "PersG", "Auslandskoerperschaft", "BZSt2")
Add-Field -List "Technische_Mindestfelder" -InternalName "kz_reference" -DisplayName "elster_kz / bzst_kz" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "value" -DisplayName "value" -Type Note
Add-Field -List "Technische_Mindestfelder" -InternalName "conditional_trigger" -DisplayName "conditional_trigger" -Type Text
Add-Field -List "Technische_Mindestfelder" -InternalName "validation_status" -DisplayName "validation_status" -Type Choice -Required `
    -Choices @("offen", "geprueft", "fehlerhaft")

Write-Host ""
Write-Host "Fertig. Alle 9 Fachlisten sowie die interne Referenzliste 'Technische_Mindestfelder' sind angelegt."
Write-Host "Naechster Schritt: siehe DE/AO/sharepoint-forms/README.md, Abschnitt E (Forms-Einrichtung) und F (Freigabe/Rollout)."
