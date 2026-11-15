#Requires -Modules PnP.PowerShell
# Minimale, synthetische Testfixture im Stil von
# DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1 - deckt die
# vom Parser unterstuetzten Konstrukte ab: einfache Text-/Boolean-Felder,
# Choice mit mehrzeiliger Choices-Liste, Lookup mit DeleteBehavior, Number
# mit Min/Max/Decimals, DefaultValue sowie eine Kommentarzeile MITTEN in
# einem mehrzeiligen Add-Field-Aufruf (Regressionsfall fuer den Parser).

New-ListIfMissing -Title "0_Testliste"
Add-Field -List "0_Testliste" -InternalName "test_id" -DisplayName "Test-ID" -Type Text -Required `
    -Indexed -EnforceUniqueValues
Add-Field -List "0_Testliste" -InternalName "status" -DisplayName "Status" -Type Choice -Required `
    -Choices @(
        "offen",
        # Kommentar mitten in der Choices-Liste - darf den Parser nicht stoeren.
        "erledigt"
    )
Add-Field -List "0_Testliste" -InternalName "aktiv" -DisplayName "Aktiv" -Type Boolean -DefaultValue "0"

New-ListIfMissing -Title "1_Folgeliste"
Add-Field -List "1_Folgeliste" -InternalName "test_id" -DisplayName "Test-ID" -Type Lookup -Required `
    -LookupList "0_Testliste" -LookupField "test_id" -DeleteBehavior Restrict
Add-Field -List "1_Folgeliste" -InternalName "betrag" -DisplayName "Betrag" -Type Number -Required `
    -Min 0 -Max 100 -Decimals 2
Add-Field -List "1_Folgeliste" -InternalName "anmerkung" -DisplayName "Anmerkung" -Type Note
