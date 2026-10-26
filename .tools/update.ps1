$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $scriptDir 'update.sh'
$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashCommand) {
    $gitBash = @(
        'C:\Program Files\Git\bin\bash.exe',
        'C:\Program Files\Git\usr\bin\bash.exe',
        'C:\msys64\usr\bin\bash.exe'
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $gitBash) {
        throw 'Git Bash is required to run the tool-shed updater.'
    }
    $bashCommand = [pscustomobject]@{ Source = $gitBash }
}

$previousOverride = $env:TOOL_SHED_OS_OVERRIDE
try {
    $env:TOOL_SHED_OS_OVERRIDE = 'Windows_NT'
    & $bashCommand.Source $scriptPath @args
    $updateExitCode = $LASTEXITCODE
} finally {
    $env:TOOL_SHED_OS_OVERRIDE = $previousOverride
}
exit $updateExitCode