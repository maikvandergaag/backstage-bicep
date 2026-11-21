# Backstage Bicep: demo repo

Demos for **Backstage Bicep: Exploring what's next before it ships** (Gijs Reijn & Maik van der Gaag, APE XXL, 8 Dec 2026).

> Sandbox only. Experimental flags and nightly builds are unsupported and can break between days.
> Never copy a `bicepconfig.json` from this repo into a production repo.

| Folder | Demo | Slide | Needs Azure | Needs nightly |
|---|---|---|---|---|
| `01-fresh-on-main` | Fresh on main: `file:` references, config errors as diagnostics | Fresh on main (Demo 1) | No | Yes (main after 18 Nov 2026) |
| `02-feature-flags` | `deployCommands`, `@validate()`, `bicep test` | Feature flags in action (Demo 2) | Yes (deploy/teardown) | No, flags work on v0.49.2 |
| `03-local-deploy` | `bicep local-deploy` with the http and utilities extensions | Bicep without Azure (Demo 3) | No | No |
| `04-no-flag-commands` | `bicep snapshot`, `bicep docs generate` | Experimental commands without a flag (Demo 4) | No | No |
| `05-run-a-pr` | Install a PR build, try it, comment | Run a PR (Demo 5) | No | PR build |

Each demo folder has its own `bicepconfig.json` with only the flags that demo needs, so flags never leak between demos.

The step-by-step script, expected output and fallbacks are in [DEMO-RUNBOOK.md](./DEMO-RUNBOOK.md).

## Prerequisites

- Bicep CLI: stable (v0.49.2 or later) **and** a nightly from main, side by side (see the runbook, "Setup").
- VS Code with the Bicep extension (nightly VSIX for Demo 1 and Demo 5).
- GitHub CLI (`gh`), logged in. The nightly install scripts use it.
- Azure CLI, logged in to a **sandbox** subscription, for Demo 2 only.
- An empty sandbox resource group for Demo 2.
