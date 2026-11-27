# Demo 6: test Bicep with C#

Unit tests for Bicep, written in C#, that run in about 2 seconds and deploy nothing.

The tests use `Azure.Bicep.Testing.Framework`, an experimental NuGet package added to the Bicep repo in [PR #20574](https://github.com/Azure/bicep/pull/20574) (merged 21 Nov 2026). The package asks the Bicep CLI for a snapshot, the same evaluation that `bicep snapshot` does in Demo 4, and gives you the resulting resources to assert on with MSTest, xUnit or NUnit.

No feature flag, no Azure login and no subscription are needed.

> The package is experimental. Its API can change in any release, and it is not on nuget.org until the next Bicep release.
> That is why this folder has a `setup.ps1`.

## Run it

You need the .NET 10 SDK, PowerShell 7 and the GitHub CLI (`gh auth login` done).

```powershell
cd 06-dotnet-tests
./setup.ps1
dotnet test --logger "console;verbosity=normal"
```

Expected result:

```text
Passed Every_storage_account_is_locked_down ("dev") [1 s]
Passed Every_storage_account_is_locked_down ("prod") [20 ms]
Passed Prod_is_zone_redundant [28 ms]
Passed Names_are_valid_and_land_in_the_right_resource_group ("dev") [17 ms]
Passed Names_are_valid_and_land_in_the_right_resource_group ("prod") [18 ms]

Total tests: 5
     Passed: 5
```

The first `dotnet test` takes longer: it restores the NuGet packages and downloads Bicep CLI 0.49.2 to `~/.bicep/bin`.

## What setup.ps1 does

Every build of `Azure/bicep` main publishes its NuGet packages as a workflow artifact called `bicep-nupkg-any`. The script:

1. Finds the newest build of main that still has that artifact. The build does not have to be green.
2. Downloads the artifact (about 180 MB) with `gh run download`.
3. Copies `Azure.Bicep.Testing.Framework` and `Azure.Bicep.RpcClient` into `./packages`.

`nuget.config` adds `./packages` as a package source next to nuget.org, and the project file asks for version `*-*`, the newest version it can find, prerelease included. Once the package is released on nuget.org, the project picks it up from there and you can skip the script.

To use a specific build, pass its run ID from the [Actions tab](https://github.com/Azure/bicep/actions/workflows/build.yml):

```powershell
./setup.ps1 -RunId 45710333592
```

## What is in this folder

| File                     | What it is                                                               |
|--------------------------|--------------------------------------------------------------------------|
| `infra/main.bicep`       | The Bicep under test: two storage accounts, built with the Demo 4 module |
| `infra/dev.bicepparam`   | Parameters for dev: default SKU (`Standard_LRS`)                         |
| `infra/prod.bicepparam`  | Parameters for prod: `Standard_ZRS`                                      |
| `StorageTests.cs`        | The tests                                                                |
| `Backstage.Tests.csproj` | MSTest project that references the package                               |
| `nuget.config`           | Adds `./packages` as a local NuGet feed                                  |
| `setup.ps1`              | Fills `./packages` from a CI build                                       |

`packages`, `bin` and `obj` are git-ignored.

## What the tests check

| Test                                                   | Runs for  | Checks                                                                                                            |
|--------------------------------------------------------|-----------|-------------------------------------------------------------------------------------------------------------------|
| `Every_storage_account_is_locked_down`                 | dev, prod | There are 2 storage accounts, each with no public blob access, HTTPS only and TLS 1.2                             |
| `Prod_is_zone_redundant`                               | prod      | Every storage account uses `Standard_ZRS`                                                                         |
| `Names_are_valid_and_land_in_the_right_resource_group` | dev, prod | The name matches the naming pattern, is at most 24 characters, and the resource ID is in the right resource group |

## How a test works

Each test follows the same three steps.

**1. Get a snapshot.** `BicepTestHelper.GetSnapshot` takes a `.bicepparam` file and a made-up deployment context, and returns what Bicep would deploy:

```csharp
var snapshot = await bicep.GetSnapshot(Cli, new SnapshotOptions
{
    FilePath = Path.Combine(InfraFolder(), $"{env}.bicepparam"),
    SubscriptionId = Subscription,
    ResourceGroup = ResourceGroup,
    Location = "westeurope",
});
```

The subscription ID and resource group are fake. They are only there so that `resourceGroup().id`, `uniqueString()` and resource IDs evaluate to real values.

**2. Check the diagnostics.** If evaluation had problems, the snapshot can be incomplete, so the helper method fails the test before any other assertion runs:

```csharp
Assert.IsEmpty(snapshot.Diagnostics, string.Join(Environment.NewLine, snapshot.Diagnostics));
```

**3. Select resources and assert.** Resources from nested modules are flattened into one list. You select by resource type and read properties with a JSON Pointer:

```csharp
foreach (var account in snapshot.GetArmResourceOfType("Microsoft.Storage/storageAccounts"))
{
    Assert.AreEqual("Standard_ZRS", account.GetRequiredStringProperty("/sku/name"), account.Name);
}
```

Two details in `StorageTests.cs` are worth knowing:

- **One CLI process for all tests.** `PooledBicepClientFactory` is created once in `[ClassInitialize]` and disposed in `[ClassCleanup]`. The first test starts the Bicep CLI, the others reuse it over JSON-RPC. That is why they take about 20 ms each.
- **The Bicep files are read from the source folder**, not from `bin`. `InfraFolder()` uses `[CallerFilePath]` for that, so an edit to a `.bicep` or `.bicepparam` file shows up on the next `dotnet test` without a copy step.

## Try it: break a rule

In `infra/prod.bicepparam`, change `skuName` to `'Standard_LRS'` and run `dotnet test`:

```text
Failed Prod_is_zone_redundant
Expected: "Standard_ZRS"
But was:  "Standard_LRS"
```

The other 4 tests still pass. Change the value back afterwards.

The same kind of change in Demo 4 produced a snapshot diff. A diff tells you that something changed. A test tells you what is not allowed to change.

## Run against another Bicep version

By default the tests pin Bicep CLI `0.49.2`, so the result does not depend on what is installed on the machine. Set `BICEP_CLI_PATH` to run the same tests against another build, for example the nightly:

```powershell
$env:BICEP_CLI_PATH = "$HOME\.azure\bin\bicep.exe"
dotnet test
Remove-Item Env:BICEP_CLI_PATH
```

This is a cheap way to find out whether a new Bicep version changes what you deploy. Snapshots need CLI 0.36.1 or later.

## Limits

- A snapshot is a prediction, not the answer of the resource provider. Values that are only known at deployment time stay unresolved expressions such as `[reference(...)]`.
- Registry modules have to be restored, which can need network access.
- Snapshots can contain parameter and output values. Treat them as sensitive if your parameters are.

## More

- [Package guide in the Bicep repo](https://github.com/Azure/bicep/blob/main/src/Bicep.Testing.Framework/PACKAGE.md): the full API, including outputs, external inputs and management group scope.
- [DEMO-RUNBOOK.md](../DEMO-RUNBOOK.md), "Demo 6": the on-stage script.
