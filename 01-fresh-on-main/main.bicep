// Demo 1: new reference schemes (REP 0022, PR #20580).
// Requires a nightly build from main after 18 Nov 2026 and the
// artifactAliasesAndRedirects flag in ./bicepconfig.json.

param location string = resourceGroup().location
param prefix string = 'bsb'

// 'file:' names a local module, relative to this file.
module network 'file:./modules/network.bicep' = {
  params: {
    name: '${prefix}-vnet'
    location: location
  }
}

// The same module with a plain relative path, for comparison.
module networkClassic './modules/network.bicep' = {
  params: {
    name: '${prefix}-vnet-classic'
    location: location
  }
}

// 'oci:' is another spelling of 'br:'. Uncomment if you have a registry to show.
// module storage 'oci:<yourregistry>.azurecr.io/bicep/modules/storage:1.0.0' = {
//   params: { name: '${prefix}st' }
// }

output vnetId string = network.outputs.id
