# Build + smoke MAIN with raw expression
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Bin = Join-Path $Root 'bin'
$BuildScript = Join-Path $PSScriptRoot 'build-local.ps1'

& $BuildScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$env:COB_LIBRARY_PATH = $Bin

Write-Host ''
Write-Host '=== Smoke MAIN ==='
$Exe = Join-Path $Bin 'MAIN.exe'
$out = '(1+2)*sqrt(9)^2' | & $Exe
$line = ($out | Select-Object -Last 1)
Write-Host $line

if ($line -notmatch 'MOCK') {
    Write-Error "Expected mock output containing MOCK, got: $line"
}

Write-Host 'OK'
exit 0
