param(
    [string]$Config = "ldc-debug"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "Building with LDC (LLVM), config=$Config..."
dub build --compiler=ldc2 --config=$Config

