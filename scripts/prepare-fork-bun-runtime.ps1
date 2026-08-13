param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubEnv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Repository = "Aerox912/codex-chatgpt-web"
$ToolchainTag = "toolchain-bun-1.4.0-pr32120-7a7885a04"
$AssetName = "bun-windows-x64-pr32120-7a7885a04.zip"
$ArchiveSha256 = "a97d1123441b03a3ba74de9f99ed0fa4ba22a48126651cb87025da082aaa048f"
$BunSha256 = "d9f1d90b24894040749cbb678c171fec9b512f496c4c0a4d67c7180d3e565a97"
$ExpectedVersion = "1.4.0"
$ExpectedRevision = "1.4.0-canary.1+7a7885a04"
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
$Bun = Join-Path $Stage "bun.exe"
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
