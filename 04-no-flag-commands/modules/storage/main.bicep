metadata name = 'Backstage storage account'
metadata description = 'A storage account with secure defaults, used to demo bicep docs generate.'

@description('Name of the storage account. 3-24 lowercase letters and numbers.')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region.')
param location string = resourceGroup().location

@description('Storage SKU.')
@allowed(['Standard_LRS', 'Standard_ZRS', 'Standard_GRS'])
param skuName string = 'Standard_LRS'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

@description('Resource ID of the storage account.')
output id string = storage.id
