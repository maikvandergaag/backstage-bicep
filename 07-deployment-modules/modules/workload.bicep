// A module that uses another module, like most Azure Verified Modules do.

param env string
param prefix string

module data './storage.bicep' = {
  name: 'data-${env}'
  params: {
    name: take('${prefix}data${env}${uniqueString(resourceGroup().id)}', 24)
  }
}

module logs './storage.bicep' = {
  name: 'logs-${env}'
  params: {
    name: take('${prefix}logs${env}${uniqueString(resourceGroup().id)}', 24)
  }
}

output storageIds string[] = [data.outputs.id, logs.outputs.id]
