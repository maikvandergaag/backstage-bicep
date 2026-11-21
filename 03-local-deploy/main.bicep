// Demo 3: Bicep without Azure. Run with: bicep local-deploy main.bicepparam

targetScope = 'local'

extension http
extension utilities

param repo string

// Ask GitHub for the latest Bicep release. No Azure connection involved.
resource latestRelease 'HttpRequest' = {
  uri: 'https://api.github.com/repos/${repo}/releases/latest'
  format: 'raw'
}

var release = json(latestRelease.body)

// Run a command on this machine: which Bicep are we running?
resource localVersion 'Command' = {
  command: 'bicep --version'
}

output latestStableRelease string = release.tag_name
output publishedAt string = release.published_at
output runningLocally string? = localVersion.stdOut
