// Demo 6: the Bicep under test. Reuses the storage module from Demo 4.

param prefix string

@allowed(['dev', 'prod'])
param env string

param skuName string = 'Standard_LRS'

var purposes = ['data', 'logs']

module storage '../../04-no-flag-commands/modules/storage/main.bicep' = [
  for purpose in purposes: {
    params: {
      name: take('${prefix}${purpose}${env}${uniqueString(resourceGroup().id)}', 24)
      skuName: skuName
    }
  }
]

output storageIds string[] = [for (purpose, i) in purposes: storage[i].outputs.id]
