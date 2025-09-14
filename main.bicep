// 01-without-lz/main.bicep (Linux)
// Minimal 2-tier app WITHOUT landing zone guardrails.
// Linux App Service Plan + Linux Web App (Node), Azure SQL Server (public) + DB (Basic).
// Deploy at resource-group scope.

targetScope = 'resourceGroup'

@description('Prefix for resource names, e.g. contoso')
param namePrefix string

@description('Environment name, e.g. dev')
param env string

@description('Azure region')
param location string = resourceGroup().location

@secure()
@description('SQL administrator login password')
param sqlAdminPassword string

@description('SQL administrator login')
param sqlAdminLogin string = 'sqladminuser'

@description('App Service Plan SKU (Linux), e.g., B1, P0v3')
param appServiceSku string = 'B1'

@description('Optional client IP to allow on SQL firewall (x.x.x.x). If empty, no firewall rule is created.')
param clientIp string = ''

@description('Tags to apply to all resources')
param tags object = {
  env: env
  owner: 'demo'
  costCenter: '0000'
}

var rgName = resourceGroup().name
var baseName = '${namePrefix}-${env}'
var aspName = '${baseName}-asp'
var webName = '${baseName}-web'
var sqlServerName = toLower(replace('${baseName}-sqlsrv-${uniqueString(rgName)}', '_', ''))
var sqlDbName = '${baseName}-db'


// Map SKU name -> correct tier to satisfy API validation
//var skuTier = contains(['S1','S2','S3'], appServiceSku) ? 'Standard' : null

// ---------------- App Service Plan (Linux) ----------------
resource asp 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: aspName
  location: location
  kind: 'linux'
  sku: {
    name: appServiceSku
  //  tier: skuTier
    capacity: 1
  }
  properties: {
    reserved: true
  }
  tags: tags
}

// ---------------- Web App (Linux, Node 18) ----------------
resource web 'Microsoft.Web/sites@2023-12-01' = {
  name: webName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: asp.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
  tags: tags
}

// ---------------- SQL logical server (PUBLIC) ----------------
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
  tags: tags
}

// Optional firewall rule
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (clientIp != '') {
  name: 'allowClient'
  parent: sqlServer
  properties: {
    startIpAddress: clientIp
    endIpAddress: clientIp
  }
}

// ---------------- SQL Database (Basic) ----------------
resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDbName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  tags: tags
}

// ---------------- Web App connection string ----------------
// Use environment suffix for SQL (portable across clouds)
var sqlHost = '${sqlServer.name}${environment().suffixes.sqlServerHostname}'

resource webConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: web
  name: 'connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Server=tcp:${sqlHost},1433;Database=${sqlDbName};User ID=${sqlAdminLogin};Password=${sqlAdminPassword};Encrypt=true;Connection Timeout=30;'
      type: 'SQLAzure'
    }
  }
}

// ---------------- Outputs ----------------
// Use platform default host to avoid hardcoding azurewebsites.net
var webHost = web.properties.defaultHostName
output webUrl string = 'https://${webHost}'
output sqlServerFqdn string = sqlHost

output aspName string = aspName
output webName string = webName
output sqlServerName string = sqlServerName
output sqlDbName string = sqlDbName
output sqlAdminLogin string = sqlAdminLogin
