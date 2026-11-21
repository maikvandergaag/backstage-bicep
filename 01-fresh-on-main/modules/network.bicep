@description('Name of the virtual network.')
param name string

@description('Azure region for the virtual network.')
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.42.0.0/16'
      ]
    }
  }
}

output id string = vnet.id
