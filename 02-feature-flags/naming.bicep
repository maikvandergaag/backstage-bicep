// Pure naming logic with assertions, tested offline by tests/main.test.bicep.

@allowed(['dev', 'test', 'prod'])
param env string
param app string

var name = 'app-${app}-${env}'
var location = env == 'prod' ? 'westeurope' : 'northeurope'

assert nameStartsWithApp = startsWith(name, 'app-')
assert nameIsLowercase = name == toLower(name)
assert prodRunsInWestEurope = env != 'prod' || location == 'westeurope'

output name string = name
output location string = location
