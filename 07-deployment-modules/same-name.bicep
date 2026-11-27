// Compiles today. With deploymentModules it does not: see the README.
// Two modules with the same name are fine as long as they go to different resource groups,
// because today each module is a deployment in its own resource group.

module west './modules/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup('rg-backstage-west')
  params: {
    name: 'bsbwest${uniqueString(subscription().id)}'
  }
}

module east './modules/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup('rg-backstage-east')
  params: {
    name: 'bsbeast${uniqueString(subscription().id)}'
  }
}
