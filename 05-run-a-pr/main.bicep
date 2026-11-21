// Demo 5: try PR #18790 (extract to module) on this file.
// Select the two resources below in VS Code and use the extract-to-module refactoring.

param location string = resourceGroup().location
param name string = 'bsbweb'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: '${name}-plan'
  location: location
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2024-04-01' = {
  name: '${name}-app'
  location: location
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      minTlsVersion: '1.2'
    }
  }
}

output url string = 'https://${site.properties.defaultHostName}'
