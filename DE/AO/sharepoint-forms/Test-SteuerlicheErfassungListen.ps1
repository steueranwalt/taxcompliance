#Requires -Modules PnP.PowerShell
<#
    .SYNOPSIS
    Vergleicht die SharePoint-Listenfamilie "Steuerliche Erfassung DE / Auslandsbezug"
    auf einer Zielsite gegen die Soll-Felder aus
    New-SteuerlicheErfassungListen.ps1 und meldet Abweichungen.

    .DESCRIPTION
    Rein lesendes Pruefskript, keine Aenderung auf der Zielsite. Es fuehrt
    KEINE Add-PnP*/Set-PnP*/New-PnP*-Aufrufe aus.

    Die Soll-Felder werden NICHT ein zweites Mal von Hand eingetragen (keine
    Dubliziert-Liste, die aus dem Takt geraten koennte). Stattdessen parst
    dieses Skript New-SteuerlicheErfassungListen.ps1 als Abstract Syntax Tree
    (AST) und liest die tatsaechlichen "Add-Field"-Aufrufe dort per
    `.SafeGetValue()` aus - das ist dieselbe Definitionsquelle, nur statisch
    ausgewertet statt ausgefuehrt. Ein echtes Dot-Sourcing des Hauptskripts
    kommt nicht in Frage, weil dessen oberste Ebene sofort Connect-PnPOnline
    und alle Add-Field-Aufrufe LIVE gegen die Zielsite ausfuehren wuerde -
    genau das soll dieses Pruefskript nicht tun.

    Vor jeder Verbindung wird ausserdem geprueft, dass im Hauptskript selbst
    kein interner Feldname laenger als 32 Zeichen ist oder Zeichen ausserhalb
    [A-Za-z0-9_] enthaelt (sonst kuerzt SharePoint ihn und ein spaeterer Lauf
    legt ein Duplikat an, siehe Testlauf 27./28.10.2026) - bei Verstoss bricht
    auch dieses Skript sofort ab, ohne sich zu verbinden.

    Geprueft wird pro Soll-Feld:
      - Existiert die Spalte ueberhaupt?
      - Entspricht der SharePoint-Feldtyp (inkl. DateOnly vs. DateTime) dem Soll?
      - Bei Choice-Feldern: sind alle Soll-Auswahlwerte vorhanden (zusaetzliche,
        nicht im Soll stehende Werte sind laut Design des Hauptskripts erlaubt
        und werden nicht als Abweichung gewertet)?
      - Bei Lookup-Feldern mit Loeschverhalten Restrict/Cascade: ist das Feld
        indiziert und steht RelationshipDeleteBehavior auf dem Sollwert?
      - EnforceUniqueValues, wo im Hauptskript mit -EnforceUniqueValues definiert
        (aktuell case_id und access_code in 0_Fallsteuerung).
      - DateOnly-Felder: DisplayFormat tatsaechlich "DateOnly", nicht "DateTime".

    SharePoint-Systemfelder (z. B. Title, TaxKeyword, Author, Editor, Created,
    Modified, ContentType, Attachments, ID) werden nie geprueft, da sie nicht
    aus Add-Field-Aufrufen stammen und folglich nie Teil der Soll-Liste sind.

    .PARAMETER SiteUrl
    Zielsite, siehe New-SteuerlicheErfassungListen.ps1 / README.md Abschnitt B.

    .PARAMETER ClientId
    Siehe New-SteuerlicheErfassungListen.ps1 / README.md Abschnitt C1.

    .EXAMPLE
    .\Test-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"

    .NOTES
    Exit-Code 0: keine Abweichungen. Exit-Code 1: mindestens eine Abweichung
    (siehe Tabelle in der Konsolenausgabe) oder ein Laufzeitfehler.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true, HelpMessage = "ClientId einer tenant-eigenen Entra-App-Registrierung mit delegierter Berechtigung 'AllSites.FullControl' (siehe README.md Abschnitt C1).")]
    [string]$ClientId
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Soll-Felder aus New-SteuerlicheErfassungListen.ps1 per AST einlesen
# (keine Dubliziert-Definition, keine Ausfuehrung des Hauptskripts)
# ---------------------------------------------------------------------------

function Get-FieldDefinitionsFromScript {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Hauptskript nicht gefunden: $ScriptPath"
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Hauptskript '$ScriptPath' enthaelt Parse-Fehler, Abbruch: $($parseErrors -join '; ')"
    }

    $commandAsts = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Add-Field' },
        $true)

    foreach ($cmd in $commandAsts) {
        $params = @{}
        $elements = $cmd.CommandElements
        for ($i = 1; $i -lt $elements.Count; $i++) {
            $el = $elements[$i]
            if ($el -is [System.Management.Automation.Language.CommandParameterAst]) {
                $paramName = $el.ParameterName
                if ($el.Argument) {
                    # Form "-Param wert" als ein Token (selten in diesem Skript)
                    $params[$paramName] = $el.Argument.SafeGetValue()
                }
                elseif (($i + 1) -lt $elements.Count -and $elements[$i + 1] -isnot [System.Management.Automation.Language.CommandParameterAst]) {
                    # Form "-Param <naechstes Element>" (Normalfall in diesem Skript)
                    $params[$paramName] = $elements[$i + 1].SafeGetValue()
                    $i++
                }
                else {
                    # Bare Switch-Parameter ohne folgenden Wert, z. B. -Required, -Indexed
                    $params[$paramName] = $true
                }
            }
        }
        [PSCustomObject]@{
            List                = $params['List']
            InternalName        = $params['InternalName']
            DisplayName         = $params['DisplayName']
            Type                = $params['Type']
            Required            = [bool]$params['Required']
            Choices             = @($params['Choices'])
            LookupList          = $params['LookupList']
            LookupField         = $params['LookupField']
            DeleteBehavior      = if ($params.ContainsKey('DeleteBehavior') -and $params['DeleteBehavior']) { $params['DeleteBehavior'] } else { 'None' }
            Indexed             = [bool]$params['Indexed']
            EnforceUniqueValues = [bool]$params['EnforceUniqueValues']
            Min                 = $params['Min']
            Max                 = $params['Max']
            HideFromForms       = [bool]$params['HideFromForms']
        }
    }
}

function Get-NormalizedChoiceKey {
    <#
      Dieselbe Normalisierung wie in New-SteuerlicheErfassungListen.ps1
      (Get-NormalizedChoiceKey dort, Review Nils 28.10.2026): erkennt
      Schreibvarianten-Dubletten in Auswahlwerten (ä/ö/ü/ß vs. ae/oe/ue/ss,
      Gross-/Kleinschreibung, mehrfache Leerzeichen).
    #>
    param([Parameter(Mandatory = $true)][string]$Value)
    $normalized = $Value.Trim().ToLowerInvariant()
    $normalized = $normalized.Replace("ä", "ae").Replace("ö", "oe").Replace("ü", "ue").Replace("ß", "ss")
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

function Test-InternalFieldNamingRules {
    <#
      Dieselbe Regel wie in New-SteuerlicheErfassungListen.ps1
      (Test-InternalFieldNamingRules dort): interne Feldnamen duerfen hoechstens
      32 Zeichen lang sein und nur aus [A-Za-z0-9_] bestehen, sonst kuerzt
      SharePoint sie stillschweigend und ein spaeterer Lauf legt Duplikate an
      (siehe Testlauf 27./28.10.2026). Wird hier auf dieselben, bereits per AST
      eingelesenen Soll-Definitionen angewendet, nicht ein zweites Mal geparst.
    #>
    param([Parameter(Mandatory = $true)][array]$Definitions)
    $violations = $Definitions | Where-Object { $_.InternalName.Length -gt 32 -or $_.InternalName -notmatch '^[A-Za-z0-9_]+$' }
    if ($violations) {
        $lines = $violations | ForEach-Object { "$($_.List) / $($_.InternalName) ($($_.InternalName.Length) Zeichen)" }
        throw "Hauptskript enthaelt ungueltige interne Feldnamen - Abbruch vor jeder Verbindung:`n  $($lines -join "`n  ")"
    }
}

function Test-SollTypeMatchesIst {
    <#
      Ordnet den im Hauptskript verwendeten logischen -Type-Werten den
      SharePoint-Feldtyp (TypeAsString) sowie bei Datumsfeldern das
      DisplayFormat zu und vergleicht gegen das tatsaechliche Feld.
    #>
    param($SollType, $IstField)
    switch ($SollType) {
        "DateOnly" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateOnly") }
        "DateTime" { return ($IstField.TypeAsString -eq "DateTime" -and $IstField.DisplayFormat -eq "DateTime") }
        "Note" { return ($IstField.TypeAsString -eq "Note") }
        "URL" { return ($IstField.TypeAsString -eq "URL") }
        default { return ($IstField.TypeAsString -eq $SollType) }
    }
}

function Format-IstTypeForDisplay {
    param($IstField)
    if ($IstField.TypeAsString -eq "DateTime") {
        return "DateTime (DisplayFormat=$($IstField.DisplayFormat))"
    }
    return $IstField.TypeAsString
}

# ---------------------------------------------------------------------------
# Verbindung (rein lesend - dieses Skript aendert nichts auf der Zielsite)
# ---------------------------------------------------------------------------

$mainScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-SteuerlicheErfassungListen.ps1"
Write-Host "Lese Soll-Felder aus: $mainScriptPath"
$sollFelder = @(Get-FieldDefinitionsFromScript -ScriptPath $mainScriptPath)
Write-Host "Soll-Felder gelesen: $($sollFelder.Count) ueber $(($sollFelder | Select-Object -ExpandProperty List -Unique).Count) Listen"
Test-InternalFieldNamingRules -Definitions $sollFelder
Write-Host "Namensregel-Pruefung bestanden: alle internen Soll-Feldnamen <= 32 Zeichen und nur [A-Za-z0-9_]."

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
$ctx = Get-PnPContext

$ergebnisse = [System.Collections.Generic.List[object]]::new()

function Add-Ergebnis {
    param([string]$List, [string]$InternalName, [string]$Check, $Soll, $Ist, [bool]$Ok)
    $ergebnisse.Add([PSCustomObject]@{
            Liste    = $List
            Feld     = $InternalName
            Pruefung = $Check
            Soll     = $Soll
            Ist      = $Ist
            Status   = if ($Ok) { "OK" } else { "ABWEICHUNG" }
        })
}

$listenNamen = $sollFelder | Select-Object -ExpandProperty List -Unique
foreach ($listenName in $listenNamen) {
    $listObj = Get-PnPList -Identity $listenName -ErrorAction SilentlyContinue
    $felderDieserListe = $sollFelder | Where-Object { $_.List -eq $listenName }

    if (-not $listObj) {
        foreach ($def in $felderDieserListe) {
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Liste vorhanden" -Soll "vorhanden" -Ist "Liste fehlt komplett" -Ok $false
        }
        continue
    }

    # Alle Ist-Felder dieser Liste EINMAL laden (Hashtable nach InternalName),
    # statt pro Soll-Feld einen eigenen Get-PnPField-Aufruf zu machen. Felder,
    # die hier auftauchen, aber nicht im Soll stehen (SharePoint-Systemfelder
    # wie Title, TaxKeyword, Author, Editor, Created, Modified, ContentType,
    # Attachments, ID, Guid usw.), werden nie geprueft - diese Funktion iteriert
    # ausschliesslich ueber die Soll-Liste, nie ueber alle Ist-Felder.
    $istFelderDieserListe = @{}
    foreach ($f in (Get-PnPField -List $listenName)) {
        $istFelderDieserListe[$f.InternalName] = $f
    }

    foreach ($def in $felderDieserListe) {
        if (-not $istFelderDieserListe.ContainsKey($def.InternalName)) {
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Spalte vorhanden" -Soll "vorhanden" -Ist "fehlt" -Ok $false
            continue
        }
        $istFeld = $istFelderDieserListe[$def.InternalName]

        $typOk = Test-SollTypeMatchesIst -SollType $def.Type -IstField $istFeld
        Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Feldtyp" `
            -Soll $def.Type -Ist (Format-IstTypeForDisplay -IstField $istFeld) -Ok $typOk

        if ($def.Type -eq "Choice" -and $def.Choices) {
            $istChoices = @($istFeld.Choices)
            $fehlendeChoices = $def.Choices | Where-Object { $istChoices -notcontains $_ }
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Auswahlwerte vollstaendig" `
                -Soll ($def.Choices -join ", ") -Ist ($istChoices -join ", ") -Ok (-not $fehlendeChoices)
        }

        if ($def.Type -eq "Choice" -and $istFeld.Choices) {
            # Review Nils 28.10.2026 (2_Unternehmens_Gruendungsmodul): auf der
            # LIVE-Site koennen sich ueber mehrere, nacheinander gelaufene
            # Skriptversionen Schreibvarianten-Dubletten angesammelt haben
            # (z. B. "UG" und "UG (haftungsbeschränkt)", "ausl. Rechtsform"
            # einmal mit Umlaut/einmal als "ae") - die nicht-destruktive
            # Angleichung des Hauptskripts ergaenzt Auswahlwerte nur, entfernt
            # nie. Dies ist die dynamische Ergaenzung zum statischen Selbsttest
            # Test-ChoiceValueDuplicates im Hauptskript (der nur EINEN
            # Add-Field-Aufruf isoliert prueft, nie akkumulierte Live-Werte
            # ueber mehrere Laeufe sehen kann).
            $istChoicesLive = @($istFeld.Choices)
            $gesehen = @{}
            $dubletten = [System.Collections.Generic.List[string]]::new()
            foreach ($choiceWert in $istChoicesLive) {
                $key = Get-NormalizedChoiceKey -Value $choiceWert
                if ($gesehen.ContainsKey($key) -and $gesehen[$key] -cne $choiceWert) {
                    $dubletten.Add("'$($gesehen[$key])' vs. '$choiceWert'")
                }
                else {
                    $gesehen[$key] = $choiceWert
                }
            }
            $dublettenText = if ($dubletten.Count -gt 0) { $dubletten -join "; " } else { "keine Dubletten" }
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Auswahlwerte ohne Schreibvariante-Dubletten" `
                -Soll "keine Dubletten" -Ist $dublettenText -Ok ($dubletten.Count -eq 0)
        }

        if ($def.HideFromForms) {
            # Review Nils 28.10.2026 (access_code): Feld muss im nativen
            # SharePoint-Neu-/Bearbeiten-Formular ausgeblendet sein (siehe
            # Set-FieldFormVisibility im Hauptskript), damit niemand von Hand
            # einen Wert eintraegt, der eigentlich nur vom Flow gesetzt wird.
            $formVisibilityOk = -not $istFeld.ShowInNewForm -and -not $istFeld.ShowInEditForm
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Im Neu-/Bearbeiten-Formular ausgeblendet" `
                -Soll "ShowInNewForm=False, ShowInEditForm=False" `
                -Ist "ShowInNewForm=$($istFeld.ShowInNewForm), ShowInEditForm=$($istFeld.ShowInEditForm)" -Ok $formVisibilityOk
        }

        # Restrict/Cascade verlangen einen indizierten Lookup (siehe Hauptskript
        # Set-LookupDeleteBehavior) - unabhaengig davon, ob -Indexed am
        # Add-Field-Aufruf selbst gesetzt wurde.
        $sollIndexed = $def.Indexed -or ($def.Type -eq "Lookup" -and $def.DeleteBehavior -in @("Restrict", "Cascade"))
        if ($sollIndexed) {
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Indexed" `
                -Soll $true -Ist $istFeld.Indexed -Ok ([bool]$istFeld.Indexed -eq $true)
        }

        if ($def.EnforceUniqueValues) {
            Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "EnforceUniqueValues" `
                -Soll $true -Ist $istFeld.EnforceUniqueValues -Ok ([bool]$istFeld.EnforceUniqueValues -eq $true)
        }

        if ($def.Type -eq "Lookup" -and $def.DeleteBehavior -in @("Restrict", "Cascade")) {
            try {
                $lookupField = $ctx.CastTo[Microsoft.SharePoint.Client.FieldLookup]($istFeld)
                $ctx.Load($lookupField)
                Invoke-PnPQuery
                $istBehavior = $lookupField.RelationshipDeleteBehavior.ToString()
                Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Lookup-Loeschverhalten" `
                    -Soll $def.DeleteBehavior -Ist $istBehavior -Ok ($istBehavior -eq $def.DeleteBehavior)
            }
            catch {
                Add-Ergebnis -List $listenName -InternalName $def.InternalName -Check "Lookup-Loeschverhalten" `
                    -Soll $def.DeleteBehavior -Ist "nicht lesbar: $_" -Ok $false
            }
        }
    }
}

Write-Host ""
Write-Host "=== Soll/Ist-Tabelle (alle Pruefungen) ==="
$ergebnisse | Sort-Object Liste, Feld, Pruefung | Format-Table -AutoSize -Wrap

$abweichungen = @($ergebnisse | Where-Object { $_.Status -eq "ABWEICHUNG" })
Write-Host ""
if ($abweichungen.Count -eq 0) {
    Write-Host "Ergebnis: keine Abweichungen. $($ergebnisse.Count) Pruefungen ueber $($listenNamen.Count) Listen, alle OK."
    Write-Host "ERGEBNIS: OK"
    exit 0
}
else {
    Write-Host "=== Abweichungen ($($abweichungen.Count) von $($ergebnisse.Count) Pruefungen) ==="
    $abweichungen | Sort-Object Liste, Feld, Pruefung | Format-Table -AutoSize -Wrap
    Write-Host "Ergebnis: $($abweichungen.Count) Abweichung(en) gefunden - siehe Tabelle oben."
    Write-Host "ERGEBNIS: $($abweichungen.Count) Abweichungen"
    exit 1
}
