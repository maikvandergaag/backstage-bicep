// Demo 1b: a wrong-typed value in bicepconfig.json.
// Before PR #20561 this crashed 'bicep build'. On main it is a diagnostic
// (BCP273/BCP453) that names the property, and the built-in config is used.
// Fix: change "yes" to true in ./bicepconfig.json.

param name string = 'backstage'

output greeting string = 'Hello from ${name}'
