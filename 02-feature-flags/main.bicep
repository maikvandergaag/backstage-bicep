// Demo 2: deployCommands + userDefinedConstraints.

@description('Application name. Must start with app- (checked by @validate).')
@validate(x => startsWith(x, 'app-'), 'Name must start with app-')
param name string

param location string = resourceGroup().location

var storageName = take(toLower(replace('${name}${uniqueString(resourceGroup().id)}', '-', '')), 24)

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
  tags: {
    demo: 'backstage-bicep'
  }
}

output storageAccountName string = storage.name
