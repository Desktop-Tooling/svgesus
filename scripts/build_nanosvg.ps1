# Build NanoSVG C impl to bin/nanosvg_impl.obj (for dmd/ldc link).
# Requires: run fetch_nanosvg.ps1 first. Needs cl (Visual C++ compiler) in PATH.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$bin = Join-Path $root 'bin'
$vendor = Join-Path $root 'vendor\nanosvg'
New-Item -ItemType Directory -Force -Path $bin | Out-Null

$cFile = Join-Path $vendor 'nanosvg_impl.c'
$obj = Join-Path $bin 'nanosvg_impl.obj'
if (-not (Test-Path $cFile)) {
    Write-Error "Run scripts/fetch_nanosvg.ps1 first. Missing: $cFile"
}

if (Get-Command cl -ErrorAction SilentlyContinue) {
    & cl /nologo /c "/I$vendor" "$cFile" "/Fo$obj"
    exit $LASTEXITCODE
}
Write-Error "Need cl (Visual Studio Build Tools) in PATH to build NanoSVG C part."
