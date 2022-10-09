@allowed([
  'Microsoft'
  'Verizon'
])
param cdnProvider string = 'Microsoft'
param location string = resourceGroup().location

var environment = uniqueString(resourceGroup().id)

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

output environment string = environment
