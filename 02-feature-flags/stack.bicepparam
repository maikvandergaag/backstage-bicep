// Deployment Stack: use for 'bicep deploy' and 'bicep teardown'.
var subscriptionId = readEnvVar('AZURE_SUBSCRIPTION_ID')
var resourceGroup = readEnvVar('AZURE_RESOURCE_GROUP')

using 'main.bicep' with {
  mode: 'stack'
  scope: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}'
  actionOnUnmanage: {
    resources: 'delete'
  }
  denySettings: {
    mode: 'denyDelete'
  }
}

param name = 'app-backstage'
