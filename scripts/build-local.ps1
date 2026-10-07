# Dynamic GnuCOBOL build by folder:
# - src/main/*.cbl  -> executable (-x)  .exe
# - src/utils/*.cbl -> dynamic module (-m) .dll
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$SrcMain = Join-Path $Root 'src\main'
$SrcUtils = Join-Path $Root 'src\utils'
$Copy = Join-Path $Root 'copybook'
$Bin = Join-Path $Root 'bin'

if (-not (Get-Command cobc -ErrorAction SilentlyContinue)) {
    Write-Error @"
cobc (GnuCOBOL) not found in PATH.
Install options:
  - winget install GnuCOBOL.GnuCOBOL
  - chocolatey: choco install gnucobol
  - https://gnucobol.sourceforge.io/
"@
}

if (-not (Test-Path -LiteralPath $Bin)) {
    New-Item -ItemType Directory -Force -Path $Bin | Out-Null
}

Write-Host "Cleaning $Bin ..."
$cleanExt = @('.exe', '.dll', '.so', '.dylib', '.o', '.obj', '.c', '.h', '.i', '.out', '.txt')
Get-ChildItem -LiteralPath $Bin -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -ne '.gitkeep' -and (
            $cleanExt -contains $_.Extension.ToLowerInvariant() -or
            $_.Name -like '*.out.txt'
        )
    } |
    ForEach-Object {
        Write-Host "  remove $($_.Name)"
        Remove-Item -LiteralPath $_.FullName -Force
    }
Write-Host ''

if (-not (Test-Path -LiteralPath $SrcMain)) {
    Write-Error "Missing folder: $SrcMain"
}
if (-not (Test-Path -LiteralPath $SrcUtils)) {
    Write-Error "Missing folder: $SrcUtils"
}

$mains = @(Get-ChildItem -LiteralPath $SrcMain -Filter '*.cbl' -File | Sort-Object Name)
$modules = @(Get-ChildItem -LiteralPath $SrcUtils -Filter '*.cbl' -File | Sort-Object Name)

if ($mains.Count -eq 0) {
    Write-Error "No .cbl files in src/main (expected MAIN etc.)"
}
if ($modules.Count -eq 0) {
    Write-Error "No .cbl files in src/utils (expected CALCULATOR, LOGIC* etc.)"
}

Write-Host "src/main  -> $($mains.Count) exe"
Write-Host "src/utils -> $($modules.Count) dll"
Write-Host ''

Push-Location $Root
try {
    foreach ($mod in $modules) {
        $outDll = Join-Path $Bin ($mod.BaseName + '.dll')
        Write-Host "DLL   cobc -m  utils/$($mod.Name)"
        & cobc -m -std=ibm -I $Copy -o $outDll $mod.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed building module $($mod.Name)"
        }
    }

    Write-Host ''

    foreach ($main in $mains) {
        $outExe = Join-Path $Bin ($main.BaseName + '.exe')
        Write-Host "EXE   cobc -x  main/$($main.Name)"
        & cobc -x -std=ibm -I $Copy -o $outExe $main.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed building main $($main.Name)"
        }
    }
}
finally {
    Pop-Location
}

Write-Host ''
Write-Host "Build OK -> $Bin"
Get-ChildItem -LiteralPath $Bin -File | Where-Object {
    $_.Extension -in '.exe', '.dll', '.so', '.dylib'
} | ForEach-Object { Write-Host "  $($_.Name)" }
