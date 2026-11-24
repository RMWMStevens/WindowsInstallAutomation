# What "irm https://roelie.cc/wia | iex" runs: downloads the repo from GitHub
# (main) to a temp folder and starts Setup as admin in a new window. With
# arguments:
#   & ([scriptblock]::Create((irm https://roelie.cc/wia))) -WhatIf
# All inside & { }, so nothing stays set in the PowerShell window it ran in.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # the progress bar slows downloads down

    # "-Apps core,social" arrives as a list; Setup wants one value.
    $setupArgs = @($args | ForEach-Object { if ($_ -is [array]) { $_ -join ',' } else { "$_" } })

    # Copies older than a day go. Newer ones may still be in use by a running Setup.
    Get-ChildItem $env:TEMP -Directory -Filter 'WindowsInstallAutomation*' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $dir = Join-Path $env:TEMP 'WindowsInstallAutomation'
    if (Test-Path $dir) { $dir = "$dir-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }

    Write-Host 'Downloading WindowsInstallAutomation from GitHub...'
    Invoke-WebRequest 'https://github.com/RMWMStevens/WindowsInstallAutomation/archive/refs/heads/main.zip' -OutFile "$dir.zip" -UseBasicParsing
    Expand-Archive "$dir.zip" -DestinationPath $dir
    Remove-Item "$dir.zip"

    Write-Host 'Starting Setup in a new window. Say yes to the admin prompt.'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'WindowsInstallAutomation-main\tools\Start-Setup.ps1') @setupArgs
} @args
