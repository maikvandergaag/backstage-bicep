# Demo 7: modules that are not deployments

Try an open pull request on the Bicep repo: [PR #20563](https://github.com/Azure/bicep/pull/20563) adds the experimental feature `deploymentModules`. With the flag on, a Bicep module no longer compiles to a nested deployment, but to a new resource type: `Microsoft.Resources/deployments/modules`.

> [!INFO]
> The PR is a draft (checked 27 Nov 2026). It is not on main and not in any release or nightly. You need the build of the PR itself.
> Compile only: deploying the result needs a preview in Azure Resource Manager that is not generally available.

## Why this is helpful

Today every module is a deployment of its own. Bicep compiles a module to a `Microsoft.Resources/deployments` resource, and Azure records each one in the deployment history of the scope it targets. That has three consequences:

- **The history fills up fast.** A scope keeps at most 800 deployments. `main.bicep` in this folder has 9 module instances, so one run writes 10 entries: the deployment itself plus 9 modules. Azure Verified Modules nest much deeper than this example.
- **Hitting the limit fails the deployment.** Azure cleans up old entries automatically once a scope is over 700, but not when there is a `CanNotDelete` lock on the resource group, when the deploying identity may not delete deployments, or when many deployments run at once. Then you get `DeploymentQuotaExceeded`. See [the Azure docs](https://learn.microsoft.com/azure/azure-resource-manager/troubleshooting/deployment-quota-exceeded).
- **The history is hard to read.** Your own deployments sit between generated names such as `storage-3fk2jd9s`.

With `deploymentModules`, modules become children of the one root deployment. According to the PR they do not count toward the limit of 800. For `main.bicep` that would be 1 entry per run instead of 10.

## Run it

You need PowerShell 7 and the GitHub CLI (`gh auth login` done).

Install the build of the PR next to your normal Bicep. `-Branch` does not work here, because the branch has no green build, so use the run ID:

```powershell
iex "& { $(irm https://aka.ms/bicep/nightly-cli.ps1) } -RunId 45493178956 -BinaryPath $HOME\.bicep-pr"
Set-Alias bicep-pr "$HOME\.bicep-pr\bicep.exe"
bicep-pr --version
```

Expected: `Bicep CLI version 0.49.62 (affa4f3351)`. The alias only lives in the current terminal.

### 1. Today: modules are deployments

`bicepconfig.json` starts with the flag off.

```powershell
cd 07-deployment-modules
./show-modules.ps1
```

```text
Module          CompilesTo                      ApiVersion
------          ----------                      ----------
workload (loop) Microsoft.Resources/deployments 2025-04-01
  data          Microsoft.Resources/deployments 2025-04-01
  logs          Microsoft.Resources/deployments 2025-04-01
```

`show-modules.ps1` builds `main.bicep` and lists every module in the ARM template, nested modules indented.

### 2. Turn the flag on

In `bicepconfig.json`, set `deploymentModules` to `true` and run the script again:

```text
Module          CompilesTo                              ApiVersion
------          ----------                              ----------
workload (loop) Microsoft.Resources/deployments/modules 2026-10-05-preview
  data          Microsoft.Resources/deployments/modules 2026-10-05-preview
  logs          Microsoft.Resources/deployments/modules 2026-10-05-preview
```

The Bicep file did not change. To see the details, run `bicep-pr build main.bicep` and open `main.json`:

```json
"type": "Microsoft.Resources/deployments/modules",
"apiVersion": "2026-10-05-preview",
"name": "[format('{0}/{1}', split(deployment().name, '/')[0], format('workload-{0}', parameters('environments')[copyIndex()]))]",
"properties": {
  "resourceScope": {
    "id": "[resourceGroup().id]"
  },
```

- **`name`** is `<root deployment>/<module name>`. Nested modules get the same prefix, so all 9 modules sit directly under the root deployment.
- **`resourceScope.id`** says where the module deploys to. It replaces the `subscriptionId` and `resourceGroup` properties of a nested deployment.
- `mode` and `expressionEvaluationOptions` are gone.

### 3. What breaks: the same name twice

Turning the flag on is not free. `same-name.bicep` has two modules called `storage` that go to different resource groups. That compiles today, because each one is a deployment in its own resource group.

With the flag on:

```powershell
bicep-pr build same-name.bicep
```

```text
Error BCP122: Modules: "west", "east" are defined with this same name and this same scope in a file.
```

All modules now live under one root deployment, so a module name has to be unique in the whole deployment, not per resource group. If you reuse explicit module names across scopes, this flag breaks your build. Leaving out `name` avoids it: Bicep then generates a unique one.

## Feedback worth giving on the PR

Found while building this demo, on build `0.49.62 (affa4f3351)`:

1. **The BCP122 message is misleading.** It says "this same name and this same scope", but the two modules in `same-name.bicep` have different scopes. With the flag on, the scope no longer matters, and the message should say so.
2. **`bicep snapshot` no longer resolves module outputs.** The predicted resources are the same with the flag off and on (6 storage accounts), but the output `storageIds` changes from real resource IDs into an unresolved `[createArray(reference(...))]` expression. Tests that assert on outputs, like the ones in Demo 6 could, would fail.

## Files

| File                     | What it is                                                              |
|--------------------------|-------------------------------------------------------------------------|
| `bicepconfig.json`       | The `deploymentModules` flag. Starts as `false`                         |
| `main.bicep`             | Three workloads in a loop                                               |
| `modules/workload.bicep` | A module that uses two other modules, the way Azure Verified Modules do |
| `modules/storage.bicep`  | One storage account                                                     |
| `same-name.bicep`        | Two modules with the same name in different resource groups             |
| `show-modules.ps1`       | Builds a file and lists what each module compiles to                    |

## Watch out

- **Use the PR build.** Other Bicep versions ignore the flag without a warning: you get regular deployments and no error. `show-modules.ps1` uses `bicep-pr` when that command exists, otherwise `bicep`.
- **Do not deploy the output.** The docs in the PR say the feature "requires the deployment modules preview to be enabled in ARM". This demo was only compiled, never deployed, so the claim about the limit of 800 comes from the PR, not from a test.
- Set the flag back to `false` when you are done.

## More

- [DEMO-RUNBOOK.md](../DEMO-RUNBOOK.md), "Demo 7": the on-stage script.
- [Automatic deletions from deployment history](https://learn.microsoft.com/azure/azure-resource-manager/templates/deployment-history-deletions): how the limit of 800 works today.
