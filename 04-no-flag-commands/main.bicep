// Demo 4: experimental commands without a feature flag.

param prefix string
param skuName string = 'Standard_LRS'

module storage './modules/storage/main.bicep' = {
  params: {
    name: '${prefix}${uniqueString(resourceGroup().id)}'
    skuName: skuName
  }
}
