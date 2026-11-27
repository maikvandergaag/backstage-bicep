<#
.SYNOPSIS
  Demo 6 setup: fetch Azure.Bicep.Testing.Framework from a CI build of Azure/bicep.

.DESCRIPTION
  The package was merged in PR #20574 (21 Nov 2026) and is not on nuget.org until the next
  Bicep release. Every build of main publishes it as a workflow artifact, so we take it from there
  and put it in ./packages, which nuget.config uses as a local feed.

.PARAMETER RunId
  A specific "Build" workflow run. Default: the newest run on main that has the artifact.
  The run does not have to be green: the packages are built before the live tests run.
#>
[CmdletBinding()]
param(
  [string]$RunId,
  [string]$Repo = "Azure/bicep",
  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
# Write-Information is silent by default. Show progress unless the caller passes -InformationAction.
if (!$PSBoundParameters.ContainsKey("InformationAction")) { $InformationPreference = "Continue" }
$artifact = "bicep-nupkg-any"
$wanted = "Azure.Bicep.Testing.Framework", "Azure.Bicep.RpcClient"

if ($null -eq (Get-Command "gh" -ErrorAction SilentlyContinue)) {
  throw "Please install the GitHub CLI: https://cli.github.com/"
}

if (!$RunId) {
  $candidates = & gh run list -R $Repo --branch $Branch --workflow build --status completed -L 15 --json databaseId -q ".[].databaseId"
  if (!$?) { throw "Could not list workflow runs. Is 'gh auth status' OK?" }

  foreach ($candidate in $candidates) {
    $query = ".artifacts[] | select(.name == `"$artifact`" and .expired == false) | .id"
    $found = & gh api "repos/$Repo/actions/runs/$candidate/artifacts?per_page=100" -q $query
    if ($found) { $RunId = $candidate; break }
  }

  if (!$RunId) { throw "No recent build on '$Branch' has a '$artifact' artifact." }
}

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
Write-Information "Downloading '$artifact' from https://github.com/$Repo/actions/runs/$RunId (about 180 MB) ..."
& gh run download -R $Repo $RunId -n $artifact --dir $tmpDir
if (!$?) { throw "Download failed." }

$packages = Join-Path $PSScriptRoot "packages"
New-Item -ItemType Directory -Force -Path $packages | Out-Null
Get-ChildItem $packages -Filter "*.nupkg" | Remove-Item

foreach ($id in $wanted) {
  $file = Get-ChildItem $tmpDir -Filter "$id.*.nupkg" | Select-Object -First 1
  if (!$file) { throw "'$id' is not in run $RunId. Pick a build of main from after 21 Nov 2026." }
  Copy-Item $file.FullName $packages
  Write-Information "  $($file.Name)"
}

Remove-Item $tmpDir -Recurse

Write-Information ""
Write-Information "Done. Next (also downloads the pinned Bicep CLI on the first run):"
Write-Information "  dotnet test"
