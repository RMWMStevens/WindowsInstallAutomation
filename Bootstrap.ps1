# Runs Setup straight from GitHub -- no cloning or downloading first.
# Paste this into any PowerShell window:
#
#   irm https://roelie.cc/wia | iex
#
# With Setup arguments (a dry run, or skipping the app menu):
#
#   & ([scriptblock]::Create((irm https://roelie.cc/wia))) -WhatIf
#
# It downloads the repo as a zip into a fresh temp folder, then starts Setup.ps1
# in Windows PowerShell, as admin, in a new window that stays open.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads crawl

# PowerShell turns "-Apps core,social" into a list; Setup wants it as one value.
$setupArgs = @($args | ForEach-Object { if ($_ -is [array]) { $_ -join ',' } else { "$_" } })

$dir = Join-Path $env:TEMP "WindowsInstallAutomation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host 'Downloading WindowsInstallAutomation from GitHub...'
Invoke-WebRequest 'https://github.com/RMWMStevens/WindowsInstallAutomation/archive/refs/heads/main.zip' -OutFile "$dir.zip" -UseBasicParsing
Expand-Archive "$dir.zip" -DestinationPath $dir
Remove-Item "$dir.zip"

$setup = Join-Path $dir 'WindowsInstallAutomation-main\Setup.ps1'
Write-Host "Starting Setup from $setup -- say yes to the admin prompt."
Start-Process powershell.exe -Verb RunAs -ArgumentList (@(
        '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$setup`"") + $setupArgs)
