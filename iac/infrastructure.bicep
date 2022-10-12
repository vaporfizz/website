@allowed([
  'Microsoft'
  'Verizon'
])
param cdnProvider string = 'Microsoft'
param location string = resourceGroup().location

var environment = uniqueString(resourceGroup().id)

resource deploymentIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-vaporfizz-deployment-${environment}'
  location: location
}

resource deploymentIdentityRoleAssigmentContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, environment, deploymentIdentity.id, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    principalId: deploymentIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'stvfizzweb${environment}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    isSftpEnabled: false
    supportsHttpsTrafficOnly: true
  }

  resource blobService 'blobServices@2022-05-01' = {
    name: 'default'

    resource webContainer 'containers@2022-05-01' = {
      name: '$web'
    }
  }
}

resource cdnProfile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
  name: 'cdn-vaporfizzweb-${environment}'
  location: location
  sku: {
    name: 'Standard_${cdnProvider}'
  }

  resource endpoint 'endpoints@2022-05-01-preview' = {
    name: 'cdn-endpoint-vaporfizzweb-${environment}'
    location: location
    properties: {
      contentTypesToCompress: [
        'text/plain'
        'text/html'
        'text/css'
        'text/javascript'
        'application/x-javascript'
        'application/javascript'
        'application/json'
        'application/xml'
      ]
      isCompressionEnabled: true
      isHttpAllowed: true
      isHttpsAllowed: true
      optimizationType: 'GeneralWebDelivery'
      originHostHeader:  replace(replace(reference('Microsoft.Storage/storageAccounts/${storageAccount.name}', storageAccount.apiVersion, 'Full').properties.primaryEndpoints.web, 'https://', ''), '/', '')
      origins: [
        {
          name: 'origin'
          properties: {
            enabled: true
            hostName: replace(replace(reference('Microsoft.Storage/storageAccounts/${storageAccount.name}', storageAccount.apiVersion, 'Full').properties.primaryEndpoints.web, 'https://', ''), '/', '')
            httpsPort: 443
          }
        }
      ]
      queryStringCachingBehavior: 'IgnoreQueryString'
    }
  }
}

resource dataPlaneScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'dataPlaneScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deploymentIdentity.id}': {}
    }
  }

  properties: {
    arguments: '-Environment ${environment} -ResourceGroupName ${resourceGroup().name}'
    azPowerShellVersion: '7.2'
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    scriptContent: 'param (\r\n    [Parameter(Mandatory=$true)]\r\n    [String]\r\n    $Environment,\r\n    [Parameter(Mandatory=$true)]\r\n    [String]\r\n    $ResourceGroupName\r\n)\r\n\r\nConnect-AzAccount -Identity\r\n$storageAccount = Get-AzStorageAccount -Name stvfizzweb$Environment -ResourceGroupName $ResourceGroupName\r\nEnable-AzStorageStaticWebsite -Context $storageAccount.Context -IndexDocument "index.html"'
    timeout: 'PT1H'
  }
}

output environment string = environment
