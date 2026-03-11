# Fetch NanoSVG headers from GitHub into vendor/nanosvg
$ErrorActionPreference = 'Stop'
$vendor = Join-Path (Join-Path $PSScriptRoot '..') 'vendor\nanosvg'
$base = 'https://raw.githubusercontent.com/memononen/nanosvg/master/src'
New-Item -ItemType Directory -Force -Path $vendor | Out-Null
Invoke-WebRequest -Uri "$base/nanosvg.h" -OutFile (Join-Path $vendor 'nanosvg.h') -UseBasicParsing
Invoke-WebRequest -Uri "$base/nanosvgrast.h" -OutFile (Join-Path $vendor 'nanosvgrast.h') -UseBasicParsing
Write-Host "NanoSVG headers saved to $vendor"
