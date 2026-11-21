// Offline unit tests: bicep test tests/main.test.bicep

test prodNaming '../naming.bicep' = {
  params: {
    env: 'prod'
    app: 'backstage'
  }
}

test devNaming '../naming.bicep' = {
  params: {
    env: 'dev'
    app: 'backstage'
  }
}

// Fails on purpose: uppercase breaks nameIsLowercase. Comment out after the demo point.
test failingNaming '../naming.bicep' = {
  params: {
    env: 'test'
    app: 'Backstage'
  }
}
