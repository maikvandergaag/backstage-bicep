// Demo 7: try PR #20563 (deploymentModules) on this file.
// Three workloads, each with two storage accounts. Nine modules in total.

param prefix string = 'bsb'
param environments string[] = ['dev', 'test', 'prod']

module workload './modules/workload.bicep' = [
  for env in environments: {
    name: 'workload-${env}'
    params: {
      env: env
      prefix: prefix
    }
  }
]

output storageIds string[][] = [for (env, i) in environments: workload[i].outputs.storageIds]
