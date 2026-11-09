<#
.SYNOPSIS
    Sets up Windows 11 the way I want it. Start it with Setup.cmd.

.DESCRIPTION
    Four steps, top to bottom:
      1. Install apps       you pick them from the list in data\apps.psd1
      2. Remove apps        everything in data\remove.psd1
      3. Registry settings  everything in data\tweaks.psd1
      4. Summary            what changed and what failed; then read MANUAL.md

    Run it as often as you like. Every step checks first and only changes what
    is different, so a second run just removes whatever has come back.

.PARAMETER Apps
    Skip the menu. Same input as the menu: all, none, group names, numbers or
    ranges -- e.g.  -Apps core,social   or   -Apps none

.EXAMPLE
    .\Setup.cmd -WhatIf
    Shows everything it would do and changes nothing.
#>
#Requires -Version 5.1
#Requires -PSEdition Desktop
[CmdletBinding(SupportsShouldProcess)]
param([string[]]$Apps)

. (Join-Path $PSScriptRoot 'tools\Helpers.ps1')

# A dry run may go without admin; a real one needs it for the whole-PC parts.
if (-not (Test-IsAdmin) -and -not $WhatIfPreference) {
    Write-Host 'Setup needs admin rights. Start it with Setup.cmd, which asks for them.' -ForegroundColor Red
    exit 1
}

$data     = Join-Path $PSScriptRoot 'data'
$appList  = (Import-PowerShellDataFile "$data\apps.psd1" -ErrorAction Stop).Apps
$removals = (Import-PowerShellDataFile "$data\remove.psd1" -ErrorAction Stop).Remove
$tweaks   = (Import-PowerShellDataFile "$data\tweaks.psd1" -ErrorAction Stop).Tweaks

Start-Log (Join-Path $PSScriptRoot "logs\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log")
Write-Host ''
Write-Host '  Windows setup' -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host '  DRY RUN -- nothing will be changed' -ForegroundColor Yellow }
if ([Environment]::OSVersion.Version.Build -lt 22000) {
    Write-Log 'This is Windows 10. Setup is written for Windows 11 -- it will run, but untested.' -Level Warn
}


# === 1. Install apps =========================================================
Write-Log 'Install apps' -Level Step

$chosen = @(Select-Apps -Apps $appList -Choice $Apps)
$haveWinget = $false
if ($chosen | Where-Object { $_.Id }) { $haveWinget = Initialize-Winget }

foreach ($app in $chosen) {
    if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }

    if ($app.Url) {
        Install-FromUrl -Name $app.Name -Url $app.Url -Signer $app.Signer -Detect $app.Detect -Ask:([bool]$app.Ask) `
            -Arguments ("$($app.Args)".Replace('{data}', $data))
    }
    elseif ($haveWinget) {
        $source = if ($app.Source) { $app.Source } else { 'winget' }
        Install-WingetApp -Id $app.Id -Name $app.Name -Source $source -Ask:([bool]$app.Ask)
    }
}
if (-not $chosen) { Write-Log 'Nothing picked.' }


# === 2. Remove apps ==========================================================
Write-Log 'Remove apps' -Level Step

foreach ($r in $removals) {
    if ($r.Guard -eq 'OneDriveFolders') {
        $held = @(Get-FoldersInOneDrive) -join ', '
        if ($held) {
            Write-Log "$($r.Name) -- refused, these folders are backed up into OneDrive: $held. In OneDrive settings > Sync and backup > Manage back up, stop backing them up, then run Setup again." -Level Fail
            Add-Result -Step 'remove' -Name $r.Name -Status Failed -Detail "folders still in OneDrive: $held"
            continue
        }
    }

    if ($r.Feature)       { Disable-OptionalFeature -Feature $r.Feature -Name $r.Name }
    elseif ($r.Uninstall) { Remove-DesktopApp -DisplayName $r.Uninstall -Name $r.Name -StopProcess $r.StopProcess }
    else                  { Remove-StoreApp -Package $r.Package -Name $r.Name }
}


# === 3. Registry settings ====================================================
Write-Log 'Registry settings' -Level Step
Write-Log "Windows build $([Environment]::OSVersion.Version.Build). Keys move between releases; if one stops working, re-capture it."

$restartExplorer = $false
foreach ($t in $tweaks) {
    $type = if ($t.Type) { $t.Type } else { 'DWord' }
    $changed = Set-RegValue -Key $t.Key -Value "$($t.Value)" -Data $t.Data -Type $type -Label $t.Name
    if ($changed -and $t.Explorer) { $restartExplorer = $true }
}


# === 4. Summary ==============================================================
Show-Summary

if ($restartExplorer) {
    Write-Host ''
    if ((Read-Host '  Restart Explorer now so the taskbar and Explorer changes show? [Y/n]') -notmatch '^[nN]') {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log 'Explorer restarted.' -Level Ok
    }
}

Write-Host ''
Write-Host ' Next: read MANUAL.md for what is left to do by hand.' -ForegroundColor Yellow
Write-Host " $(Join-Path $PSScriptRoot 'MANUAL.md')" -ForegroundColor Yellow

# Non-zero exit when anything failed.
exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
