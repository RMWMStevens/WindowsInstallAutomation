# Runs Setup straight from GitHub -- no cloning or downloading first.
# Paste this into any PowerShell window:
#
#   irm https://roelie.cc/wia | iex
#
# With Setup arguments (a dry run, or skipping the app menu):
#
#   & ([scriptblock]::Create((irm https://roelie.cc/wia))) -WhatIf
#
# It downloads the repo as a zip into a temp folder, then starts Setup.ps1 as
# admin in a new window that stays open (Windows Terminal when available).

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads crawl

# PowerShell turns "-Apps core,social" into a list; Setup wants it as one value.
$setupArgs = @($args | ForEach-Object { if ($_ -is [array]) { $_ -join ',' } else { "$_" } })

# Clear out copies from earlier runs, so they do not pile up in temp. Only ones
# older than a day: a Setup still running from a newer copy reads files from it
# partway through (Start pins, Office settings), so those are left alone.
Get-ChildItem $env:TEMP -Directory -Filter 'WindowsInstallAutomation*' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$dir = Join-Path $env:TEMP 'WindowsInstallAutomation'
if (Test-Path $dir) { $dir = "$dir-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }

Write-Host 'Downloading WindowsInstallAutomation from GitHub...'
Invoke-WebRequest 'https://github.com/RMWMStevens/WindowsInstallAutomation/archive/refs/heads/main.zip' -OutFile "$dir.zip" -UseBasicParsing
Expand-Archive "$dir.zip" -DestinationPath $dir
Remove-Item "$dir.zip"

# The same launcher Setup.cmd uses: a new admin window, in Windows Terminal
# when the PC has it.
$start = Join-Path $dir 'WindowsInstallAutomation-main\tools\Start-Setup.ps1'
Write-Host 'Starting Setup in a new window -- say yes to the admin prompt.'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $start @setupArgs
