// Infrastruktur fuer den Erfassungs-Chat-Prototyp, NUR VORBEREITET - NICHT
// DEPLOYT in dieser Session (siehe ../README.md "Rahmen"). Jede Ressource
// einzeln kommentiert, damit Nils Obenhaus jede Position einzeln
// freigeben kann.
//
// Deployment-Beispiel (NICHT ausgefuehrt):
//   az deployment group create \
//     --resource-group rg-erfassungschat-prototyp \
//     --template-file main.bicep \
//     --parameters @main.parameters.example.json
//
// Die Rollenzuweisung auf accompli-azureai (siehe `openAiRoleAssignment`
// unten) setzt voraus, dass dieses Template im GLEICHEN Tenant wie
// accompli-azureai bereitgestellt wird; liegt die Ressource in einer
// anderen Subscription, muss dieser Teil als eigenes, auf die
// Ziel-Subscription gescoptes Deployment laufen (siehe README "Deploy-
// Schritte" Punkt 7).

@description('Kurzer, eindeutiger Projektname, Basis fuer alle Ressourcennamen.')
param projectName string = 'erfassungschat'

@description('Umgebung, z. B. dev/test/prod - fliesst in Ressourcennamen ein.')
param environmentName string = 'dev'

@description('Region fuer Function App/Storage/App Insights. EU-Datenzone bevorzugt, z. B. westeurope oder germanywestcentral.')
param location string = resourceGroup().location

@description('Resource Group der bestehenden Azure-OpenAI-Ressource accompli-azureai (fuer die Rollenzuweisung).')
param accompliAzureAiResourceGroup string

@description('Name der bestehenden Azure-OpenAI-Ressource (Cognitive Services Account), z. B. accompli-azureai.')
param accompliAzureAiAccountName string = 'accompli-azureai'

@description('Microsoft-Graph-Hostname der SharePoint-Zielsite.')
param graphSiteHostname string = 'transferpricingdocs.sharepoint.com'

@description('Pfad der SharePoint-Zielsite unterhalb des Hosts.')
param graphSitePath string = '/sites/steuerdaten'

var namePrefix = '${projectName}-${environmentName}'
// Storage-Account-Namen duerfen keine Bindestriche enthalten und sind global
// eindeutig - 'stoitaxaibackend' ist ein Beispiel aus dem Auftrag, real waere
// ein per uniqueString() generierter Suffix noetig.
var functionStorageAccountName = toLower(replace('st${projectName}${environmentName}func', '-', ''))
var staticWebStorageAccountName = toLower(replace('st${projectName}${environmentName}web', '-', ''))

// ---------------------------------------------------------------------------
// 1. User-assigned Managed Identity
//    Einzige Azure-Identitaet der Function App - weder Azure OpenAI noch
//    Microsoft Graph werden mit einem API-Key/Client-Secret aufgerufen.
// ---------------------------------------------------------------------------
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${namePrefix}-mi'
  location: location
}

// ---------------------------------------------------------------------------
// 2. Storage Account fuer die Function App (Flex Consumption braucht einen
//    eigenen Storage Account fuer Deployment-Paket + Runtime-State).
// ---------------------------------------------------------------------------
resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// ---------------------------------------------------------------------------
// 3. Storage Account fuer das statische Frontend ($web). Bewusst GETRENNT
//    vom Function-Storage-Account (unterschiedliche Zugriffsanforderungen:
//    $web ist oeffentlich lesbar, der Function-Storage nicht).
// ---------------------------------------------------------------------------
resource staticWebStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: staticWebStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
}
// Hinweis: die Aktivierung des statischen Website-Hostings selbst
// (`az storage blob service-properties update --static-website`) ist in
// Bicep fuer Storage-Konten nicht als deklaratives Property verfuegbar und
// muss nach dem Deployment einmalig per CLI erfolgen (siehe README
// "Deploy-Schritte" Punkt 4).

// ---------------------------------------------------------------------------
// 4. Application Insights - OHNE Inhalte, nur Metadaten (siehe
//    Zielarchitektur: keine Chat-Inhalte in Logs). SamplingPercentage
//    reduziert zusaetzlich das Volumen; Request-Bodies werden von der
//    Anwendung selbst nie geloggt (siehe backend/app/llm_client.py).
// ---------------------------------------------------------------------------
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${namePrefix}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${namePrefix}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    DisableIpMasking: false
    SamplingPercentage: 50
  }
}

// ---------------------------------------------------------------------------
// 5. Function App Plan (Flex Consumption)
// ---------------------------------------------------------------------------
resource flexConsumptionPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${namePrefix}-plan'
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

// ---------------------------------------------------------------------------
// 6. Function App selbst - HTTP anonym (eigene Zugangspruefung im Code,
//    siehe backend/app/access_control.py), Managed Identity statt Keys.
// ---------------------------------------------------------------------------
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: '${namePrefix}-func'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: flexConsumptionPlan.id
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${functionStorageAccount.properties.primaryEndpoints.blob}deploymentpackage'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: managedIdentity.id
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.12'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
    }
    siteConfig: {
      appSettings: [
        { name: 'AzureWebJobsStorage__accountName', value: functionStorageAccount.name }
        { name: 'AzureWebJobsStorage__credential', value: 'managedidentity' }
        { name: 'AzureWebJobsStorage__clientId', value: managedIdentity.properties.clientId }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
        { name: 'AZURE_CLIENT_ID', value: managedIdentity.properties.clientId }
        { name: 'ERFASSUNGSCHAT_MOCK_MODE', value: 'false' }
        { name: 'AOAI_ENDPOINT', value: 'https://${accompliAzureAiAccountName}.openai.azure.com/' }
        { name: 'AOAI_DEPLOYMENT', value: 'gpt-5.6-sol-dz' }
        { name: 'AOAI_API_VERSION', value: '2024-08-01-preview' }
        { name: 'GRAPH_SITE_HOSTNAME', value: graphSiteHostname }
        { name: 'GRAPH_SITE_PATH', value: graphSitePath }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// 7. Rollenzuweisung "Cognitive Services OpenAI User" auf accompli-azureai,
//    gescopet auf GENAU diese Ressource (kein Subscription-weiter Scope).
//    Funktioniert nur, wenn main.bicep in derselben Subscription wie
//    accompli-azureai deployt wird - siehe Kommentar am Dateianfang.
// ---------------------------------------------------------------------------
resource accompliAzureAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: accompliAzureAiAccountName
  scope: resourceGroup(accompliAzureAiResourceGroup)
}

var cognitiveServicesOpenAiUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(accompliAzureAiAccount.id, managedIdentity.id, cognitiveServicesOpenAiUserRoleId)
  scope: accompliAzureAiAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAiUserRoleId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.name
output functionAppDefaultHostname string = functionApp.properties.defaultHostName
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output staticWebStorageAccountName string = staticWebStorageAccount.name
output functionStorageAccountName string = functionStorageAccount.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
