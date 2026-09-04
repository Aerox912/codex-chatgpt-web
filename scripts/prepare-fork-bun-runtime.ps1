param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubEnv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Official 1.4.0 includes PR #32120 (8dd1b617) and avoids the old canary's
# retained-compaction deadline stall. Keep the fork's exact hash/revision gate.
$Repository = "oven-sh/bun"
$ToolchainTag = "bun-v1.4.0"
$AssetName = "bun-windows-x64.zip"
$ArchiveSha256 = "e6f093d39da486b20262ca8cdd5ed6a9e8bc9c2f275b78e6d3a0c5b28cc95901"
$BunSha256 = "627d2e4775c24bdedee2cd7ccc18dcadae061e5345274ab6e3c4c797927bfb8f"
$ExpectedVersion = "1.4.0"
$ExpectedRevision = "1.4.0+34cbb9a40"
$Url = "https://github.com/$Repository/releases/download/$ToolchainTag/$AssetName"

if (-not [IO.Path]::IsPathFullyQualified($GitHubEnv)) {
  throw "GitHubEnv must be an absolute path"
}

$RunnerTemp = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$Stage = Join-Path $RunnerTemp "codex-web-gpt-bun-$([guid]::NewGuid().ToString('N'))"
$Archive = Join-Path $Stage $AssetName
New-Item -ItemType Directory -Path $Stage | Out-Null

Invoke-WebRequest -Uri $Url -OutFile $Archive -TimeoutSec 120
$ActualArchiveSha256 = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualArchiveSha256 -ne $ArchiveSha256) {
  throw "Fork Bun archive SHA-256 mismatch: expected $ArchiveSha256, received $ActualArchiveSha256"
}

Expand-Archive -LiteralPath $Archive -DestinationPath $Stage
$Bun = Join-Path $Stage "bun-windows-x64/bun.exe"
if (-not (Test-Path -LiteralPath $Bun -PathType Leaf)) {
  throw "Fork Bun archive does not contain bun.exe"
}

$ActualBunSha256 = (Get-FileHash -LiteralPath $Bun -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualBunSha256 -ne $BunSha256) {
  throw "Fork Bun executable SHA-256 mismatch: expected $BunSha256, received $ActualBunSha256"
}

$ReportedVersion = (& $Bun --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $ReportedVersion -ne $ExpectedVersion) {
  throw "Fork Bun version mismatch: expected $ExpectedVersion, received $ReportedVersion"
}

$ReportedRevision = (& $Bun --revision | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $ReportedRevision -ne $ExpectedRevision) {
  throw "Fork Bun revision mismatch: expected $ExpectedRevision, received $ReportedRevision"
}

Add-Content -LiteralPath $GitHubEnv -Value "CODEX_CHATGPT_WEB_EMBEDDED_BUN=$Bun" -Encoding utf8
Add-Content -LiteralPath $GitHubEnv -Value "CODEX_CHATGPT_WEB_EMBEDDED_BUN_REVISION=$ExpectedRevision" -Encoding utf8
