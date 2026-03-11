param(
    [string]$Config = "dmd-debug"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "Building with dmd, config=$Config..."
dub build --compiler=dmd --config=$Config

