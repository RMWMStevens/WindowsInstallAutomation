<#
.SYNOPSIS
    Sets up Windows 11 the way I want it. Start it with Setup.cmd.

.DESCRIPTION
    First you pick apps and answer a few yes/no questions; after that it runs
    on its own, top to bottom:
      0. Restore point      always, before anything changes
      1. Remove apps        everything in data\remove.psd1 (+ Xbox if you said so;
                            on a work PC the work apps stay)
      2. Install apps       the ones you picked, then optionally update what is
                            left -- after the removals, so nothing is updated
                            only to be removed
      3. Tweaks             data\tweaks.psd1   -- sensible on any PC
      4. Personal           data\personal.psd1 + Start pins -- my own preferences
      5. Privacy            data\privacy-general.psd1, plus privacy-personal.psd1
                            unless this is a work PC
      6. Extras             new PC name, black background
      7. Summary            what changed and what failed; then read MANUAL.md
    Steps 3 to 6 only run the parts you said yes to.

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

# Without Windows Terminal, Setup opens in the classic PowerShell window, which
# is bright blue. Plain black is calmer. (Inside Terminal this is skipped.)
if (-not $env:WT_SESSION -and $Host.Name -eq 'ConsoleHost') {
    try { $Host.UI.RawUI.BackgroundColor = 'Black'; $Host.UI.RawUI.ForegroundColor = 'Gray'; Clear-Host } catch { }
}

# A dry run may go without admin; a real one needs it for the whole-PC parts.
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

Start-Log (Join-Path $script:WorkDir "logs\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log")
Write-Host ''
Write-Host '  Windows setup' -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host '  DRY RUN -- nothing will be changed' -ForegroundColor Yellow }
if ([Environment]::OSVersion.Version.Build -lt 22000) {
    Write-Log 'This is Windows 10. Setup is written for Windows 11 -- it will run, but untested.' -Level Warn
}


# === Questions first, so the rest runs unattended ============================
$chosen = @(Select-Apps -Apps $appList -Choice $Apps)

# Big or licensed apps (Ask = $true, i.e. Microsoft 365) get one more question,
# right here with the app choice -- but only when they are not installed yet.
# They install last, after the quick ones.
$chosen = @($chosen | Where-Object {
        -not $_.Ask -or (Test-AppInstalled $_) -or
        (Read-YesNo "$($_.Name) is a big download and needs a licence to use. Install it?")
    })
$chosen = @($chosen | Where-Object { -not $_.Ask }) + @($chosen | Where-Object { $_.Ask })

Write-Host ''
Write-Host '  A few questions. Each one defaults to the capital letter:' -ForegroundColor Cyan
$newName     = if (Test-DefaultComputerName) { Read-NewComputerName }
# A work PC keeps its work apps (Teams, OneDrive, Outlook...), skips the privacy
# settings an employer may rely on, and leaves app updates to IT by default.
$workPC      = Read-YesNo 'Is this a work PC, managed by your employer?'
$doTweaks    = Read-YesNo 'Apply the general tweaks (data\tweaks.psd1)?' -Default $true
$doPrivacy   = Read-YesNo 'Apply the privacy settings (data\privacy-*.psd1)?' -Default $true
$updateAll   = Read-YesNo 'Update all installed apps afterwards (winget upgrade --all)?' -Default (-not $workPC)
$removeXbox  = Read-YesNo 'Remove the Xbox apps too (keep them on a gaming PC)?'
$doPersonal  = Read-YesNo 'Apply my personal preferences and Start pins (data\personal.psd1, data\start-pins.json)?'
$blackScreen = Read-YesNo 'Plain black background on the desktop and the lock / sign-in screen?'
Write-Log ("Answers: new name=$(if ($newName) { $newName } else { 'keep' }), work PC=$workPC, tweaks=$doTweaks, privacy=$doPrivacy, " +
    "update all=$updateAll, remove Xbox=$removeXbox, personal + pins=$doPersonal, black background=$blackScreen")


# === 0. Restore point ========================================================
Write-Log 'Restore point' -Level Step
if (-not (New-RestorePoint)) {
    if (-not (Read-YesNo 'No restore point could be made. Continue without one?')) {
        Write-Log 'Stopped before changing anything.' -Level Warn
        Show-Summary
        exit 1
    }
    Write-Log 'Continuing without a restore point, as you asked.' -Level Warn
}


# === 1. Remove apps ==========================================================
Write-Log 'Remove apps' -Level Step

foreach ($r in $removeData.Remove) {
    if ($workPC -and $r.KeepOnWork) {
        Write-Log "$($r.Name) -- kept, this is a work PC" -Level Skip
        Add-Result -Step 'remove' -Name $r.Name -Status Skipped -Detail 'work PC'
        continue
    }
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

if ($removeXbox) {
    foreach ($x in $removeData.Xbox) { Remove-StoreApp -Package $x.Package -Name $x.Name -Xbox }
}
else { Write-Log 'Xbox apps -- kept' -Level Skip }


# === 2. Install apps, then update what is left ================================
Write-Log 'Install apps' -Level Step

$haveWinget = $false
if (($chosen | Where-Object { $_.Id }) -or $updateAll) { $haveWinget = Initialize-Winget }

foreach ($app in $chosen) {
    if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }

    if ($app.Url) {
        Install-FromUrl -Name $app.Name -Url $app.Url -Signer $app.Signer -Detect $app.Detect `
            -Arguments ("$($app.Args)".Replace('{data}', $data))
    }
    elseif ($haveWinget) {
        $source = if ($app.Source) { $app.Source } else { 'winget' }
        Install-WingetApp -Id $app.Id -Name $app.Name -Source $source
    }
}
if (-not $chosen) { Write-Log 'Nothing picked.' }
if ($updateAll -and $haveWinget) { Update-AllApps }

# Installers can bring removed apps back -- Microsoft 365 adds its companion
# apps. When something was actually installed, look once more, and only act on
# Store apps from the removal list that really are back. (Guarded ones, like
# OneDrive's, were already handled in step 1 and stay with that decision.)
$installedSomething = $script:Results | Where-Object { $_.Step -eq 'apps' -and $_.Status -eq 'Changed' -and $_.Name -ne 'Update all apps' }
if ($installedSomething) {
    foreach ($r in $removeData.Remove | Where-Object { $_.Package -and -not $_.Guard -and -not ($workPC -and $_.KeepOnWork) }) {
        if (Get-InstalledStoreApp $r.Package) { Remove-StoreApp -Package $r.Package -Name "$($r.Name) (came back with an install)" }
    }
}


# === 3-5. Tweaks, personal preferences, privacy ==============================
$restartExplorer = $false
foreach ($set in @(
        @{ Title = 'Tweaks';   Step = 'tweaks';   Wanted = $doTweaks;   Items = $tweaks }
        @{ Title = 'Personal'; Step = 'personal'; Wanted = $doPersonal; Items = $personal }
        @{ Title = 'Privacy';  Step = 'privacy';  Wanted = $doPrivacy;  Items = $privacyAll })) {
    Write-Log $set.Title -Level Step
    if (-not $set.Wanted) { Write-Log 'Skipped -- you said no' -Level Skip; continue }
    if ($set.Step -eq 'tweaks') {
        Write-Log "Windows build $([Environment]::OSVersion.Version.Build). Registry keys move between releases; if one stops working, re-capture it."
    }
    if (Set-RegList -Items $set.Items -Step $set.Step) { $restartExplorer = $true }

    # Start pins go with the personal preferences, through Microsoft's "Configure
    # Start Pins" policy for this account. applyOnce in the file: pinned once at
    # the next sign-in, after that yours to change. Pins for apps that are not
    # installed stay hidden until they are.
    if ($set.Step -eq 'personal') {
        $pins = (Get-Content "$data\start-pins.json" -Raw) -replace '\r?\n\s*', ''
        $null = Set-RegValue -Key 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Value 'ConfigureStartPins' `
            -Data $pins -Type String -Label 'Start pins (show after signing out and in)' -Step 'personal'
    }

    # The privacy settings an employer may rely on: only on my own PCs.
    if ($set.Step -eq 'privacy') {
        if ($workPC) { Write-Log 'Personal privacy settings (data\privacy-personal.psd1) -- skipped, this is a work PC' -Level Skip }
        elseif (Set-RegList -Items $privacyOwn -Step 'privacy') { $restartExplorer = $true }
    }
}


# === 6. Extras ===============================================================
Write-Log 'Extras' -Level Step
if ($newName) { Rename-ThisPC -NewName $newName }
if ($blackScreen) { Set-BlackBackground }
if (-not ($newName -or $blackScreen)) { Write-Log 'None -- no new name, no black background' -Level Skip }


# === 7. Summary ==============================================================
Show-Summary

if ($restartExplorer) {
    Write-Host ''
    if (Read-YesNo 'Restart Explorer now so the taskbar and Explorer changes show?' -Default $true) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log 'Explorer restarted.' -Level Ok
    }
}
# Policies, Start pins, a new name and removed parts of Windows only fully take
# effect after a restart. Installs alone do not need one.
$needsRestart = $script:Results | Where-Object { $_.Status -eq 'Changed' -and $_.Step -in 'remove', 'tweaks', 'personal', 'privacy', 'extras' }
if ($needsRestart -and -not $WhatIfPreference) {
    Write-Host ''
    Write-Host ' Restart the PC when you are done: policies, Start pins and removed parts' -ForegroundColor Yellow
    Write-Host ' of Windows only fully take effect after a restart.' -ForegroundColor Yellow
    if ($newName) { Write-Host " The restart also finishes renaming this PC to $newName." -ForegroundColor Yellow }
}

Write-Host ''
Write-Host ' Next: read MANUAL.md for what is left to do by hand.' -ForegroundColor Yellow
Write-Host " $(Join-Path $PSScriptRoot 'MANUAL.md')" -ForegroundColor Yellow

# Non-zero exit when anything failed.
exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
