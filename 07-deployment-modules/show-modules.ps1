<#
.SYNOPSIS
  Demo 7: show what each module in a Bicep file compiles to.

.DESCRIPTION
  Builds the file and lists every module in the resulting ARM template, nested modules indented.
  Run it with deploymentModules off and on in bicepconfig.json to see the difference.

.PARAMETER File
  The Bicep file to build. Default: main.bicep.

.PARAMETER Bicep
  The Bicep CLI to use. Default: bicep-pr if that command exists, otherwise bicep.
#>
[CmdletBinding()]
param(
  [string]$File = "main.bicep",
  [string]$Bicep
)

$ErrorActionPreference = "Stop"
$moduleTypes = "Microsoft.Resources/deployments", "Microsoft.Resources/deployments/modules"

if (!$Bicep) {
  $Bicep = if (Get-Command "bicep-pr" -ErrorAction SilentlyContinue) { "bicep-pr" } else { "bicep" }
}

function Get-Module($Template, [int]$Depth) {
  # Resources are an object keyed by symbolic name, or an array in older language versions.
  $resources = $Template.resources
  $entries = if ($resources -is [System.Collections.IDictionary]) {
    $resources.GetEnumerator() | ForEach-Object { @{ Symbol = $_.Key; Resource = $_.Value } }
  }
  else {
    $resources | ForEach-Object { @{ Symbol = $_.name; Resource = $_ } }
  }

  foreach ($entry in $entries) {
    $resource = $entry.Resource
    if ($resource.type -notin $moduleTypes) { continue }

    [pscustomobject]@{
      Module     = ("  " * $Depth) + $entry.Symbol + $(if ($resource.copy) { " (loop)" })
      CompilesTo = $resource.type
      ApiVersion = $resource.apiVersion
    }

    if ($resource.properties.template) { Get-Module $resource.properties.template ($Depth + 1) }
  }
}

$output = & $Bicep build $File --stdout 2>&1
$json = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
if ($LASTEXITCODE -ne 0) {
  $problems = $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | Out-String
  throw "Build of '$File' failed:`n$problems"
}

Get-Module ($json | Out-String | ConvertFrom-Json -AsHashtable) 0
