$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$installer = Join-Path $repoRoot '.tools/install.ps1'

if (-not (Test-Path $installer)) {
    throw "Missing installer script: $installer"
}

& $installer 'cpp' @args
exit $LASTEXITCODE
