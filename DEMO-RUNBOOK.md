# Demo runbook: Backstage Bicep

Written 21 Nov 2026 against `Azure/bicep` main and v0.49.2. **Re-run every demo end to end in the week before the talk**: nightly builds change daily, and v0.50 may ship before 8 Dec.

Time budget: about 25 minutes of demos in total. Times per demo are targets, not guarantees.

| # | Demo                           | Who  | Time | Fallback                          |
|---|--------------------------------|------|------|-----------------------------------|
| 0 | Opening: `bicep --version`     | Gijs | 0:30 | Screenshot                        |
| 1 | Fresh on main                  | TBD  | 4:00 | Recording                         |
| 2 | Feature flags in action        | TBD  | 7:00 | Recording, pre-deployed stack     |
| 3 | Bicep without Azure            | TBD  | 4:00 | Recording                         |
| 4 | Commands without a flag        | TBD  | 4:00 | Pre-generated README and snapshot |
| 5 | Run a PR, close the loop       | TBD  | 5:00 | PR build pre-installed            |
| 6 | Test Bicep with C# (PR #20574) | TBD  | 3:30 | Recording                         |

Demo 6 was added on 27 Nov and is **not** in the 25 minutes yet. Swap it in for something, or trim elsewhere.

---

## Setup (day before, and again 1 hour before)

### 1. Install the nightly next to stable

Windows (PowerShell):

```powershell
iex "& { $(irm https://aka.ms/bicep/nightly-cli.ps1) }"
iex "& { $(irm https://aka.ms/bicep/nightly-vsix.ps1) }"
```

macOS and Linux:

```bash
bash <(curl -Ls https://aka.ms/bicep/nightly-cli.sh)
bash <(curl -Ls https://aka.ms/bicep/nightly-vsix.sh)
```

- Requires `gh` and `gh auth login`.
- The CLI lands in `~/.azure/bin`. Reload the VS Code window after installing the VSIX.
- Check `-BinaryPath` in the installer if you want stable and nightly in separate folders.
- Roll back with `az bicep install` and by reinstalling the extension from the Marketplace.

> **Checked 27 Nov: the default nightly is stale.** The install scripts take the last *green* build of main, and main has been red since 18 Nov (the live tests fail on `Az CLI login`). Without arguments you get the 17 Nov build, which has no `file:` support, so Demo 1 fails with BCP189. The red builds still publish their artifacts, so pass a run ID from the Actions tab instead: `-RunId 45710333592` (25 Nov, `0.49.60`) builds `01-fresh-on-main` fine. Check again in the week before the talk whether main is green.

### 2. Checklist

- [ ] `bicep --version` shows a nightly build (note the version for the opening).
- [ ] `gh auth status` is OK.
- [ ] `az account show` points at the **sandbox** subscription.
- [ ] Sandbox resource group exists and is empty.
- [ ] Env vars set in the demo terminal (Demo 2):

```powershell
$env:AZURE_SUBSCRIPTION_ID = "<sandbox-subscription-id>"
$env:AZURE_RESOURCE_GROUP  = "rg-backstage-bicep-demo"
```

- [ ] Extensions for Demo 3 restored once on venue Wi-Fi (or hotspot): `bicep restore 03-local-deploy/main.bicep`.
- [ ] Demo 4: `main.snapshot.json` generated (step 4.2) so `--mode validate` has a baseline.
- [ ] Demo 5: PR build installed in a separate folder, PR open in the browser.
- [ ] Demo 6: `./setup.ps1` run in `06-dotnet-tests`, then `dotnet test` run once (downloads the pinned CLI, restores NuGet packages).
- [ ] Terminal font 20pt+, VS Code zoom 2-3, notifications off, light-on-dark theme matching the deck.
- [ ] Recordings of every demo on the laptop **and** on a USB stick.

---

## Demo 0: Opening (slide "Who has seen Bicep before it ships?")

After the show of hands:

```bash
bicep --version
```

**Expect:** a version string from a nightly build, not `0.49.2`.

**Say (Gijs):** "This is the Bicep I'm running right now. You can't download it from the docs. It was built from main yesterday. By the end of this session, you'll have it too."

**If it fails:** show the screenshot of the version, and move on. Do not debug on stage.

---

## Demo 1: Fresh on main (`01-fresh-on-main`)

Requires the **nightly**: `file:` landed on main on 18 Nov 2026 (PR #20580) behind the flag `artifactAliasesAndRedirects`.

### 1.1 `file:` references

1. Open `01-fresh-on-main/main.bicep` in VS Code (nightly VSIX).
2. Show `bicepconfig.json`: one flag, `artifactAliasesAndRedirects`.
3. Show the two modules: `'file:./modules/network.bicep'` and the classic `'./modules/network.bicep'`. Both resolve to the same file.
4. Build:

```bash
cd 01-fresh-on-main
bicep build main.bicep
```

**Expect:** builds with an experimental-feature warning, `main.json` written.

5. Optional: set the flag to `false` and build again.

**Expect:** an error on the `file:` reference: the scheme is not supported without the flag.

**Point to make:** "oci: and file: are the first step of REP 0022. Aliases are next: PR #20585 is open right now."

### 1.2 Config errors as diagnostics

```bash
cd broken-config
bicep build main.bicep
```

**Expect:** a BCP273 or BCP453 diagnostic that names `experimentalFeaturesWarning`, and the build carries on with the built-in config. On v0.49.2 this was an unhandled exception.

Fix it live: change `"yes"` to `true` and build again.

### 1.3 Visual designer (optional, 30 s)

Open the visualizer on `01-fresh-on-main/main.bicep`. Show the Select (V) and Hand (H) tools and a marquee multi-selection.

**Fallback:** recording.

---

## Demo 2: Feature flags in action (`02-feature-flags`)

Flags: `deployCommands`, `userDefinedConstraints`, `testFramework`, `assertions`. Works on stable v0.49.2 and on the nightly.

### 2.1 Deploy commands

```bash
cd 02-feature-flags
bicep what-if deployment.bicepparam
```

**Expect:** a what-if diff with one storage account to create.

Show the `with` block in `stack.bicepparam`: mode, scope, `actionOnUnmanage`, `denySettings`. Everything about the deployment lives in one file.

```bash
bicep deploy stack.bicepparam
```

**Expect:** a Deployment Stack with one storage account. Takes about 30-60 s: talk over it.

### 2.2 `@validate()`

Show the decorator on `name` in `main.bicep`, then:

```bash
bicep what-if invalid.bicepparam
```

**Expect:** a failure with the message `Name must start with app-`.

> Check during rehearsal **where** the error appears (editor, build or deployment). The docs say an invalid value fails the deployment. Adjust the wording on stage to what you see.

### 2.3 Offline unit tests

Show `naming.bicep` (the `assert` statements) and `tests/main.test.bicep` (the `test` blocks).

```bash
bicep test tests/main.test.bicep
```

**Expect:** `prodNaming` and `devNaming` pass, `failingNaming` fails on `nameIsLowercase`. No Azure login needed.

**Point to make:** "Beyond bicep test: the official .NET package (PR #20574) and Anthony Martin's community bicep-testing." Demo 6 shows that package live.

### 2.4 Teardown

```bash
bicep teardown stack.bicepparam
```

**Expect:** the stack and its storage account are removed.

**If deploy is slow or fails:** deploy the stack the day before and only show `what-if` and `teardown` live.

---

## Demo 3: Bicep without Azure (`03-local-deploy`)

Flags: `localDeploy`, `ociEnabled`. Extensions from GHCR: `http` 0.1.4 and `utilities` 0.0.1.

```bash
cd 03-local-deploy
az logout   # optional, makes the point: no Azure session
bicep local-deploy main.bicepparam
```

**Expect:** three outputs:
- `latestStableRelease`: the latest Bicep tag from the GitHub API (for example `v0.49.2`).
- `publishedAt`: its publish date.
- `runningLocally`: the output of `bicep --version` on this machine (the nightly).

**Point to make:** "Bicep just called the GitHub API and ran a command on my laptop. No Azure, no ARM. Over gRPC to an extension."

**Watch out:**
- macOS may block the unsigned extension binary. Fix during setup with `codesign -s - '<path from the error>'`.
- The GitHub API allows 60 anonymous requests per hour per IP. Shared conference Wi-Fi can hit that. Use a hotspot.
- If `bicep` is not on the PATH of the extension process, `runningLocally` is empty. Swap the command for `gh --version` or `hostname`.
- Check during setup that `utilities:0.0.1` still exists on GHCR. If not, use the version from the repo's latest release.

---

## Demo 4: Commands without a flag (`04-no-flag-commands`)

No feature flag needed. Use the standalone `bicep` CLI: `snapshot` does not work through `az bicep`.

### 4.1 Docs from a module

```bash
cd 04-no-flag-commands
bicep docs generate ./modules/storage/main.bicep --stdout
```

**Expect:** Markdown with the module name, description, parameters (with descriptions and allowed values) and outputs. Without `--stdout` it writes `README.md` next to the module.

### 4.2 Snapshot baseline (do this in setup, not on stage)

```bash
bicep snapshot main.bicepparam --mode overwrite
```

**Expect:** `main.snapshot.json` with the normalized resources.

### 4.3 Snapshot diff (on stage)

1. In `main.bicepparam` change `skuName` to `'Standard_ZRS'`.
2. Run:

```bash
bicep snapshot main.bicepparam --mode validate
```

**Expect:** a what-if style diff showing the SKU change, without any call to Azure.

3. Change it back afterwards.

### 4.4 Mention only

- `bicep publish-extension`: push your own extension to a registry or the file system.
- Bicep MCP server: resource schemas, diagnostics, formatting and snapshots for AI agents.

---

## Demo 5: Run a PR, close the loop (`05-run-a-pr`)

Suggested PR: **#18790, extract to module** (still open on 21 Nov 2026). Check the status the week before. If it merged, pick another open PR from slide 18.

1. Open the PR on `github.com/Azure/bicep/pulls`. Show the branch name and the Checks tab.
2. Install the PR build (do it **before** the talk, show the command on stage):

```powershell
iex "& { $(irm https://aka.ms/bicep/nightly-cli.ps1) } -Branch <pr-branch-name>"
iex "& { $(irm https://aka.ms/bicep/nightly-vsix.ps1) } -Branch <pr-branch-name>"
```

For a PR from a fork: copy the run ID from the Checks tab and use `-RunId <id>` instead of `-Branch`.

3. Open `05-run-a-pr/main.bicep`, select `plan` and `site`, and use the extract-to-module refactoring.

**Expect:** a new module file with the parameters lifted automatically, and a module reference in `main.bicep`.

4. Close the loop: open the PR's comment box and say what you'd write: what worked, what didn't. Do not post live unless you mean it.

**If the PR build does not install:** the CI artifact may have expired or the build failed. Show the recording, and use it as a point: "this is exactly why you try it before it ships."

---

## Demo 6: Test Bicep with C# (`06-dotnet-tests`)

PR **#20574** adds `Azure.Bicep.Testing.Framework`: a NuGet package that asks the Bicep CLI for a snapshot and lets you assert on the evaluated resources from MSTest, xUnit or NUnit. Merged 21 Nov 2026, experimental, **not on nuget.org** until the next release. No feature flag, no Azure login, needs the .NET 10 SDK.

Verified 27 Nov with package `0.49.60-g024037d6a7` from run 45710333592, against CLI 0.49.2 (pinned), 0.47.16 and the 25 Nov build of main.

### 6.1 Setup (before the talk, not on stage)

```powershell
cd 06-dotnet-tests
./setup.ps1      # about 180 MB from GitHub Actions, needs gh
dotnet test      # first run downloads CLI 0.49.2 to ~/.bicep/bin
```

`setup.ps1` takes the newest build of main that has the `bicep-nupkg-any` artifact and copies two packages into `./packages`. `nuget.config` uses that folder as a feed. To pin a build: `./setup.ps1 -RunId <id>`.

### 6.2 Where the package comes from (30 s)

1. Show the PR in the browser: 1,386 lines added, from a branch called `agents/bicep-testing-library-creation`, with review rounds that read `@copilot address feedback`. Agent-assisted work on the Bicep repo itself, which is a nice aside if there is time.
2. Show `nuget.config` and the `packages` folder.

**Say:** "This package is not on NuGet. Search for it and you get nothing. It is in every build of main though, as a workflow artifact. Same trick as the nightly CLI, one folder further."

### 6.3 Green run (1:30)

1. Show `infra/main.bicep`: two storage accounts from the Demo 4 module, a `dev` and a `prod` parameter file.
2. Show `StorageTests.cs`. Walk through `Every_storage_account_is_locked_down` only: get a snapshot, select by resource type, read properties with a JSON Pointer.
3. Run:

```bash
dotnet test --logger "console;verbosity=normal"
```

**Expect:** 5 tests pass in about 2 seconds. The first one takes about 1 s (it starts the CLI), the rest about 20 ms each.

**Point to make:** "Twenty milliseconds per test, because it is one Bicep process answering over JSON-RPC. `uniqueString()` and `take()` are already evaluated: I am asserting on the real storage account name, and nothing has been deployed."

### 6.4 Break it (1:00)

1. In `infra/prod.bicepparam` change `skuName` to `'Standard_LRS'`.
2. Run `dotnet test`.

**Expect:** `Prod_is_zone_redundant` fails with `Expected: "Standard_ZRS"`, `But was: "Standard_LRS"` and the name of the storage account. The other 4 pass.

3. Change it back.

**Point to make:** "In Demo 4 the same change gave us a snapshot diff. A diff tells you that something changed. A test tells you what is not allowed to change. And unlike `bicep test`, this needs no feature flag and runs in the test runner your pipeline already has."

### 6.5 Mention only

- The tests pin CLI `0.49.2`, so the result does not depend on what is installed. Set `BICEP_CLI_PATH` to run the same tests against the nightly: a cheap way to find out whether the next release changes what you deploy.
- Limits to be honest about: these are predictions, not what the resource provider returns. Values only known at deployment time stay unresolved expressions. The package is experimental and its API may break in any release.

**Watch out:**
- `dotnet test` needs nuget.org for MSTest and `Azure.Deployments.Core`. Run it once in setup so everything is in the local cache.
- Workflow artifacts expire. If `setup.ps1` finds nothing, pass a newer `-RunId`. Keep a copy of the two `.nupkg` files with the recordings.
- If v0.50 ships before 8 Dec the package will be on nuget.org and `Version="*-*"` picks it up from there. Then change the story in 6.2 to "two weeks ago you had to take this from CI".
- Read the Bicep files from the source folder, not from `bin`: the tests do this with `[CallerFilePath]`, so the edit in 6.4 needs no rebuild step.

**Fallback:** recording.

---

## After the talk

- Remove the nightly: `az bicep install` and reinstall the Marketplace extension.
- `bicep teardown 02-feature-flags/stack.bicepparam` if Demo 2 was cut short.
- Delete the sandbox resource group.
