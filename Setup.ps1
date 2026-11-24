<#
.SYNOPSIS
    Sets up Windows 11. Start it with Setup.cmd.

.DESCRIPTION
    You pick apps and answer a few questions, then it runs on its own:
      0. Restore point
      1. Remove apps       data\remove.psd1, sponsored apps, Xbox if you say so
      2. Install apps      the ones you picked, then optionally update the rest
      3. Tweaks            data\tweaks.psd1
      4. Personal          data\personal.psd1, and my Start pins if you want them
      5. Privacy           data\privacy-general.psd1, and privacy-personal.psd1 on your own PCs
      6. Extras            new PC name, black background
      7. Clean-up          DISM /StartComponentCleanup
    Every step checks first, so running it again only changes what has drifted.

.PARAMETER Apps
    Skips the app menu. Same input: all, none, group names, numbers, ranges.

.PARAMETER Restore
    Puts back every setting earlier runs changed. Apps stay as they are.

.EXAMPLE
    .\Setup.cmd -WhatIf
    Shows what it would do and changes nothing. Works with -Restore too.
#>
#Requires -Version 5.1
#Requires -PSEdition Desktop
[CmdletBinding(SupportsShouldProcess)]
param([string[]]$Apps, [switch]$Restore)

. (Join-Path $PSScriptRoot 'tools\Helpers.ps1')

# The classic PowerShell window is bright blue; black is calmer.
if (-not $env:WT_SESSION -and $Host.Name -eq 'ConsoleHost') {
    try { $Host.UI.RawUI.BackgroundColor = 'Black'; $Host.UI.RawUI.ForegroundColor = 'Gray'; Clear-Host } catch { }
}

if (-not (Test-IsAdmin) -and -not $WhatIfPreference) {
    Write-Host 'Setup needs admin rights. Start it with Setup.cmd, which asks for them.' -ForegroundColor Red
    exit 1
}

$data       = Join-Path $PSScriptRoot 'data'
$appList    = (Import-PowerShellDataFile "$data\apps.psd1" -ErrorAction Stop).Apps
$removeData = Import-PowerShellDataFile "$data\remove.psd1" -ErrorAction Stop
$tweaks     = (Import-PowerShellDataFile "$data\tweaks.psd1" -ErrorAction Stop).Tweaks
$personal   = (Import-PowerShellDataFile "$data\personal.psd1" -ErrorAction Stop).Personal
$privacyAll = (Import-PowerShellDataFile "$data\privacy-general.psd1" -ErrorAction Stop).Privacy
$privacyOwn = (Import-PowerShellDataFile "$data\privacy-personal.psd1" -ErrorAction Stop).Privacy

$logName = if ($Restore) { 'restore' } else { 'setup' }
Start-Log "$logName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Write-Host ''
Write-Host "  Windows setup$(if ($Restore) { ': restore' })" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host '  DRY RUN, nothing will be changed' -ForegroundColor Yellow }
if ([Environment]::OSVersion.Version.Build -lt 22000) { Write-Log 'This is Windows 10. Setup is made for Windows 11.' -Level Warn }


# === -Restore ================================================================
if ($Restore) {
    Write-Log 'Put back settings' -Level Step
    $changed = Restore-Settings
    Show-Summary
    if ($changed) {
        Request-ExplorerRestart
        Write-Host ''
        Write-Host ' Restart the PC to finish: policies and services only change back after a restart.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host " Removed apps are not put back: reinstall them from the Microsoft Store, or use the" -ForegroundColor Yellow
    Write-Host " restore point 'Before WindowsInstallAutomation' to undo everything at once." -ForegroundColor Yellow
    exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
}


# === Questions first, so the rest runs unattended ============================
$chosen = @(Select-Apps -Apps $appList -Choice $Apps)
# Big or licensed apps (Ask) get one more question unless already installed, and install last.
$chosen = @($chosen | Where-Object {
        -not $_.Ask -or (Test-AppInstalled $_) -or (Read-YesNo "$($_.Name) is a big download and needs a licence to use. Install it?")
    })
$chosen = @($chosen | Where-Object { -not $_.Ask }) + @($chosen | Where-Object { $_.Ask })

$last = Get-LastAnswers
$same = $false
if ($last) {
    Write-Host ''
    Write-Host "  Last time ($($last.Date.ToString('d MMM yyyy'))): $(Format-Answers $last)" -ForegroundColor Cyan
    $same = Read-YesNo 'Same answers as last time? (n asks each question again)' -Default $true
}

# Sponsored apps that came with the PC go, except the ones you keep or picked
# to install.
$found = @(Get-SponsoredApp -List $removeData.Sponsored)
$sponsored = @($found | Where-Object { $_.Pushed -and $_.Name -notin $chosen.Name })
$keepSponsored = @(
    if ($same) { $sponsored | Where-Object { $_.Name -in @($last.KeepSponsored) } }
    elseif ($sponsored) { Read-SponsoredToKeep -Found $sponsored })

# With the same answers these are taken from last time; only a new question is asked.
# Never repeated: the PC name and the black background.
$reuse = if ($same) { $last }
if (-not $same) {
    Write-Host ''
    Write-Host '  A few questions. Each one defaults to the capital letter:' -ForegroundColor Cyan
}
$newName     = if (-not $same -and (Test-DefaultComputerName)) { Read-NewComputerName }
$workPC      = Read-Answer $reuse WorkPC 'Is this a work PC, managed by your employer?'
$doTweaks    = Read-Answer $reuse Tweaks 'Apply the general tweaks (data\tweaks.psd1)?' -Default $true
$doPrivacy   = Read-Answer $reuse Privacy 'Apply the privacy settings (data\privacy-*.psd1)?' -Default $true
$updateAll   = Read-Answer $reuse UpdateAll 'Update all installed apps afterwards (winget upgrade --all)?' -Default (-not $workPC)
$removeXbox  = Read-Answer $reuse RemoveXbox 'Remove the Xbox apps too (keep them on a gaming PC)?'
$doPersonal  = Read-Answer $reuse Personal 'Apply my personal preferences (data\personal.psd1)?'
$doPins      = $doPersonal -and (Read-Answer $reuse StartPins 'Pin my apps to Start too (data\start-pins.json)?')
$blackScreen = if ($same) { $false } else { Read-YesNo 'Plain black background on the desktop and the lock / sign-in screen?' }
$doCleanup   = Read-Answer $reuse Cleanup 'At the end, clear out old Windows update files (DISM component clean-up, 10+ minutes)?'
Write-LogData 'Answers' @{ WorkPC = $workPC; Tweaks = $doTweaks; Privacy = $doPrivacy; UpdateAll = $updateAll
    RemoveXbox = $removeXbox; Personal = $doPersonal; StartPins = $doPins; Cleanup = $doCleanup; KeepSponsored = [string[]]@($keepSponsored | ForEach-Object { $_.Name })
    NewName = "$newName"; BlackBackground = $blackScreen; Same = $same; DryRun = [bool]$WhatIfPreference }


# === 0. Restore point ========================================================
Write-Log 'Restore point' -Level Step
if (-not (New-RestorePoint)) {
    if (-not (Read-YesNo 'No restore point could be made. Continue without one?')) {
        Write-Log 'Stopped before changing anything.' -Level Warn
        Show-Summary
        exit 1
    }
    Write-Log 'Continuing without a restore point.' -Level Warn
}


# === 1. Remove apps ==========================================================
Write-Log 'Remove apps' -Level Step
foreach ($r in $removeData.Remove) {
    if ($workPC -and $r.KeepOnWork) { Add-Result remove $r.Name Skipped 'kept, this is a work PC' 'work PC'; continue }
    if ($r.Guard -eq 'OneDriveFolders' -and ($held = @(Get-FoldersInOneDrive) -join ', ')) {
        Add-Result remove $r.Name Failed ("refused, these folders are backed up into OneDrive: $held. Stop that in OneDrive settings > " +
            'Sync and backup > Manage back up, then run Setup again.') "folders still in OneDrive: $held"
        continue
    }
    if ($r.Feature)       { Disable-OptionalFeature -Feature $r.Feature -Name $r.Name }
    elseif ($r.Uninstall) { Remove-DesktopApp -DisplayName $r.Uninstall -Name $r.Name -StopProcess $r.StopProcess }
    else                  { Remove-StoreApp -Package $r.Package -Name $r.Name }
}

foreach ($s in $found) {
    if (-not $s.Pushed) { Add-Result remove $s.Name Skipped 'kept, someone on this PC installed it' }
    elseif ($s.Name -in $chosen.Name) { Add-Result remove $s.Name Skipped 'kept, you picked it to install' }
    elseif ($keepSponsored -contains $s) { Add-Result remove $s.Name Skipped 'kept, as you asked' }
    else { Remove-StoreApp -Package $s.Package -Name $s.Name }
}
if (-not $found) { Add-Result remove 'Sponsored apps' AlreadySet 'none on this PC' }

if ($removeXbox) { foreach ($x in $removeData.Xbox) { Remove-StoreApp -Package $x.Package -Name $x.Name -Xbox } }
else { Write-Log 'Xbox apps: kept' -Level Skip }


# === 2. Install apps, then update the rest ===================================
Write-Log 'Install apps' -Level Step
$haveWinget = (($chosen | Where-Object { $_.Id }) -or $updateAll) -and (Initialize-Winget)
foreach ($app in $chosen) {
    if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }
    if ($app.Url) {
        Install-FromUrl -Name $app.Name -Url $app.Url -Signer $app.Signer -Detect $app.Detect -Arguments ("$($app.Args)".Replace('{data}', $data))
    }
    elseif ($haveWinget) { Install-WingetApp -Id $app.Id -Name $app.Name -Source $(if ($app.Source) { $app.Source } else { 'winget' }) }
}
if (-not $chosen) { Write-Log 'Nothing picked.' }
if ($updateAll -and $haveWinget) { Update-AllApps }

# Installers can bring removed apps back (Microsoft 365 does), so look again.
if ($script:Results | Where-Object { $_.Step -eq 'apps' -and $_.Status -eq 'Changed' -and $_.Name -ne 'Update all apps' }) {
    foreach ($r in $removeData.Remove | Where-Object { $_.Package -and -not $_.Guard -and -not ($workPC -and $_.KeepOnWork) }) {
        if (Get-InstalledStoreApp $r.Package) { Remove-StoreApp -Package $r.Package -Name "$($r.Name) (came back with an install)" }
    }
}


# === 3-5. Tweaks, personal, privacy ==========================================
$restartExplorer = $false
foreach ($set in @(
        @{ Title = 'Tweaks';   Step = 'tweaks';   Wanted = $doTweaks;   Items = $tweaks }
        @{ Title = 'Personal'; Step = 'personal'; Wanted = $doPersonal; Items = $personal }
        @{ Title = 'Privacy';  Step = 'privacy';  Wanted = $doPrivacy;  Items = $privacyAll })) {
    Write-Log $set.Title -Level Step
    if (-not $set.Wanted) { Write-Log 'Skipped, you said no' -Level Skip; continue }
    if (Set-RegList -Items $set.Items -Step $set.Step) { $restartExplorer = $true }

    # Start pins, through the "Configure Start Pins" policy. applyOnce in the
    # file: pinned at the next sign-in, after that yours to change.
    if ($set.Step -eq 'personal' -and $doPins) {
        $pins = (Get-Content "$data\start-pins.json" -Raw) -replace '\r?\n\s*', ''
        $null = Set-RegValue -Key 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Value 'ConfigureStartPins' `
            -Data $pins -Type String -Label 'Start pins (show after signing out and in)' -Step 'personal'
    }
    if ($set.Step -eq 'privacy') {
        if ($workPC) { Write-Log 'Personal privacy settings: skipped, this is a work PC' -Level Skip }
        elseif (Set-RegList -Items $privacyOwn -Step 'privacy') { $restartExplorer = $true }
    }
}


# === 6. Extras ===============================================================
Write-Log 'Extras' -Level Step
if ($newName) { Rename-ThisPC -NewName $newName }
if ($blackScreen) { Set-BlackBackground }
if (-not ($newName -or $blackScreen)) { Write-Log 'None' -Level Skip }


# === 7. Clean-up =============================================================
Write-Log 'Clean-up' -Level Step
if ($doCleanup) { Invoke-ComponentCleanup } else { Write-Log 'Skipped, you said no' -Level Skip }


# === Summary =================================================================
Show-Summary
if ($restartExplorer) { Request-ExplorerRestart }
$needsRestart = $script:Results | Where-Object { $_.Status -eq 'Changed' -and $_.Step -in 'remove', 'tweaks', 'personal', 'privacy', 'extras' }
if ($needsRestart -and -not $WhatIfPreference) {
    Write-Host ''
    Write-Host ' Restart the PC to finish: policies, Start pins and removed parts of Windows need it.' -ForegroundColor Yellow
}
exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
