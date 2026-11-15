# Microsoft Graph `Sites.Selected`: Zugriff der Function App auf GENAU eine SharePoint-Site

**Nicht in dieser Session ausgefuehrt.** Dokumentiertes Vorgehen fuer eine
Person mit Entra-Admin-Rechten im Accompli-Tenant
(`e12b46da-af8f-4791-90c6-5543937ef66f`), bevor die Function App produktiv
gegen `https://transferpricingdocs.sharepoint.com/sites/steuerdaten`
schreiben darf.

`Sites.Selected` ist bewusst gewaehlt statt `Sites.ReadWrite.All`: die
Managed Identity der Function App bekommt NUR Zugriff auf diese eine Site,
nicht auf jede SharePoint-Site im Tenant.

## 1. App-Registrierung fuer die Managed Identity sichtbar machen

Die user-assigned Managed Identity (siehe `main.bicep`, Ressource
`managedIdentity`) hat automatisch ein zugehöriges Service-Principal-Objekt
in Entra ID. Dessen Objekt-ID (`principalId`, Output von `main.bicep`) wird
unten gebraucht.

## 2. Anwendungsberechtigung `Sites.Selected` zuweisen (einmalig, Admin)

```powershell
# Voraussetzung: Microsoft.Graph PowerShell SDK installiert, als
# Entra-Global-Admin oder Privileged-Role-Admin verbunden.
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All","Application.Read.All"

# Service Principal der Graph-API selbst (konstante App-ID 00000003-0000-0000-c000-000000000000)
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$sitesSelectedRole = $graphSp.AppRoles | Where-Object { $_.Value -eq "Sites.Selected" }

# Service Principal der Managed Identity (principalId aus main.bicep-Output)
$miPrincipalId = "<managedIdentityPrincipalId aus Bicep-Output>"

New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $miPrincipalId `
    -PrincipalId $miPrincipalId `
    -ResourceId $graphSp.Id `
    -AppRoleId $sitesSelectedRole.Id
```

Nach diesem Schritt hat die Managed Identity die GLOBALE Berechtigung
`Sites.Selected` - das bedeutet nur, dass sie ÜBERHAUPT berechtigt werden
KANN, auf einzelne Sites zuzugreifen, noch nicht auf welche.

## 3. Site-spezifischen Zugriff auf `steuerdaten` gewaehren (einmalig, Admin)

```http
POST https://graph.microsoft.com/v1.0/sites/transferpricingdocs.sharepoint.com:/sites/steuerdaten:/permissions
Content-Type: application/json
Authorization: Bearer <Admin-Token mit Sites.FullControl.All oder Site-Collection-Admin-Rechten>

{
  "roles": ["write"],
  "grantedToIdentities": [
    {
      "application": {
        "id": "<AppId/ClientId der Managed Identity>",
        "displayName": "erfassungschat-dev-mi"
      }
    }
  ]
}
```

Die Antwort enthaelt eine `permission`-ID - diese zur Dokumentation
aufbewahren (fuer spaeteren Entzug/Audit via
`DELETE /sites/{site-id}/permissions/{permission-id}`).

## 4. Verifikation (rein lesend, unkritisch)

```http
GET https://graph.microsoft.com/v1.0/sites/transferpricingdocs.sharepoint.com:/sites/steuerdaten:/lists/0_Fallsteuerung
Authorization: Bearer <Token der Managed Identity, https://graph.microsoft.com/.default>
```

Erwartet: HTTP 200 mit den Metadaten der Liste `0_Fallsteuerung`. Ein
`403 Forbidden` bedeutet, dass Schritt 2 oder 3 nicht vollstaendig
durchgefuehrt wurde.

## Offene Punkte

- Die Site `transferpricingdocs.sharepoint.com/sites/steuerdaten` existiert
  gemaess Auftrag im Accompli-Tenant - ob die 11 Listen aus
  `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` dort bereits
  angelegt sind, ist in dieser Session nicht geprueft worden. Vor dem ersten
  produktiven Lauf: `New-SteuerlicheErfassungListen.ps1` gegen diese Site
  ausfuehren (mit einer fuer DIESEN Tenant passenden Entra-App-Registrierung,
  siehe `sharepoint-forms/README.md` Abschnitt C1 - die dort verwendete
  ClientId gilt nur fuer den Obenhaus-Tenant, nicht fuer Accompli).
- Der spaetere Power-Automate-Flow, der geprüfte Faelle von `steuerdaten`
  (Accompli) nach `steueranwaltskanzlei` (Obenhaus) uebertraegt, ist NICHT
  Teil dieses PR - siehe Haupt-README Abschnitt "Spaeter: Übertragung nach
  Obenhaus".
