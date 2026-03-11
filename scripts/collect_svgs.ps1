# Collect SVGs for tests into tests/svg-samples.
# Strategy:
# 1. If tests/svg-samples already has .svg files, do nothing.
# 2. Try to copy up to 200 .svg files from Z:\code (if present).
# 3. If still low, download a small sample set from Simple Icons CDN.

$ErrorActionPreference = 'Stop'

$root    = Split-Path $PSScriptRoot -Parent
$outDir  = Join-Path $root 'tests\svg-samples'

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# If we already have SVGs, don't touch them.
$existing = Get-ChildItem -Path $outDir -Filter *.svg -Recurse -ErrorAction SilentlyContinue
if ($existing.Count -gt 0) {
    Write-Host "SVG samples already present in $outDir ($($existing.Count) files). Skipping."
    exit 0
}

Write-Host "Collecting SVG samples into $outDir..."

# 1) Try local collection under Z:\code (user's repo root)
if (Test-Path 'Z:\code') {
    $localSvgs = Get-ChildItem -Path 'Z:\code' -Filter *.svg -Recurse -ErrorAction SilentlyContinue | Select-Object -First 200
    foreach ($f in $localSvgs) {
        $dest = Join-Path $outDir $f.Name
        Copy-Item $f.FullName $dest -ErrorAction SilentlyContinue
    }
}

# 2) If still too few, pull a small curated set from Simple Icons CDN
$need = 100
$current = (Get-ChildItem -Path $outDir -Filter *.svg -ErrorAction SilentlyContinue).Count
if ($current -lt $need) {
    $names = @(
        'github','microsoft','visualstudiocode','windows','android','apple',
        'docker','kubernetes','git','python','rust','d',
        'twitter','facebook','linkedin','youtube','twitch',
        'amazon','google','spotify','netflix','discord','slack'
    )
    foreach ($name in $names) {
        $url = "https://cdn.jsdelivr.net/npm/simple-icons@latest/icons/$name.svg"
        $dest = Join-Path $outDir "$name.svg"
        if (Test-Path $dest) { continue }
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        } catch {
            Write-Warning "Failed to download $url : $($_.Exception.Message)"
        }
    }
}

$final = Get-ChildItem -Path $outDir -Filter *.svg -ErrorAction SilentlyContinue
Write-Host "Collected $($final.Count) SVG files in $outDir."

