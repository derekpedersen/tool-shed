$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$uninstaller = Join-Path $repoRoot '.tools/uninstall.ps1'

if (-not (Test-Path $uninstaller)) {
    throw "Missing uninstaller script: $uninstaller"
}

& $uninstaller 'cpp' @args
exit $LASTEXITCODE
