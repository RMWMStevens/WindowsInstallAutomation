<#
.SYNOPSIS
    Sets up Windows 11. Start it with Setup.cmd, or with the one-liner in README.md.

.DESCRIPTION
    You pick apps and answer a few questions, then it runs on its own:
      0. Restore point
      1. Remove apps       data\apps-remove.psd1 and sponsored apps, except the ones you keep; Xbox if you say so
      2. Install apps      the ones you picked; then, if you say so, update the menu's apps on this PC
      3. Tweaks            data\tweaks-general.psd1
      4. Personal          data\tweaks-personal.psd1, and my Start pins if you want them
      5. Privacy           data\privacy-general.psd1, and data\privacy-strict.psd1 if you want it
      6. Extras            new PC name, black background
      7. Clean-up          DISM /StartComponentCleanup
    Every step checks first, so running it again only changes what has drifted.

.PARAMETER Apps
    Skips the app menu. Same input: all, none, group names, numbers, ranges.

.PARAMETER Restore
    Puts back the settings earlier runs changed. Apps stay as they are.

.EXAMPLE
    .\Setup.cmd -WhatIf
    Shows what it would do. It changes nothing; it only writes its log (and the folder's README.txt). Works with -Restore too.
#>
#Requires -Version 5.1
#Requires -PSEdition Desktop
[CmdletBinding(SupportsShouldProcess)]
param([string[]]$Apps, [switch]$Restore)

# Company policies (and maybe Smart App Control) can restrict PowerShell so far
# that Setup cannot work.
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host 'PowerShell runs in a restricted mode on this PC, so Setup cannot run.' -ForegroundColor Red
    exit 1
}

. (Join-Path $PSScriptRoot 'tools\Helpers.ps1')

# The classic PowerShell window is bright blue; black is calmer.
if (-not $env:WT_SESSION -and $Host.Name -eq 'ConsoleHost') {
    try { $Host.UI.RawUI.BackgroundColor = 'Black'; $Host.UI.RawUI.ForegroundColor = 'Gray'; Clear-Host } catch { }
}

if (-not (Test-IsAdmin) -and -not $WhatIfPreference) {
    Write-Host 'Setup needs admin rights. Start it with Setup.cmd, which asks for them.' -ForegroundColor Red
    exit 1
}
if ([Environment]::OSVersion.Version.Build -lt 22000 -and -not $Restore) {
    Write-Host 'This is Windows 10. Setup only supports Windows 11.' -ForegroundColor Red
    exit 1
}

# Someone typed another account's password at the admin prompt: settings and
# logs would then go to that account.
$me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$atScreen = (Get-CimInstance Win32_ComputerSystem).UserName
if ($atScreen -and $atScreen -ne $me -and -not (Read-YesNo "$atScreen is signed in, but Setup runs as $me, so its settings and logs go to $me. Continue?")) {
    exit 1
}

$data          = Join-Path $PSScriptRoot 'data'
$appList       = (Import-PowerShellDataFile "$data\apps-install.psd1" -ErrorAction Stop).Apps
$removeData    = Import-PowerShellDataFile "$data\apps-remove.psd1" -ErrorAction Stop
$tweaks        = (Import-PowerShellDataFile "$data\tweaks-general.psd1" -ErrorAction Stop).Tweaks
$personal      = (Import-PowerShellDataFile "$data\tweaks-personal.psd1" -ErrorAction Stop).Personal
$privacyAll    = (Import-PowerShellDataFile "$data\privacy-general.psd1" -ErrorAction Stop).Privacy
$privacyStrict = (Import-PowerShellDataFile "$data\privacy-strict.psd1" -ErrorAction Stop).Privacy

$logName = if ($Restore) { 'restore' } else { 'setup' }
Start-Log "$logName-$script:PcId-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Write-Host ''
Write-Host "  Windows setup$(if ($Restore) { ': restore' })" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host '  DRY RUN, nothing will be changed' -ForegroundColor Yellow }


# === -Restore ================================================================
if ($Restore) {
    Write-Log 'Put back settings' -Level Step
    $allowed = @($tweaks + $personal + $privacyAll + $privacyStrict | ForEach-Object { "$($_.Key)|$($_.Value)" }) + $script:OwnValues
    $changed = Restore-Settings -Allowed $allowed
    Show-Summary
    if ($changed) {
        Request-ExplorerRestart
        Write-Host ''
        Write-Host ' Restart the PC to finish: policies and services only change back after a restart.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host ' Removed apps are not put back: reinstall them from the Microsoft Store, OneDrive from' -ForegroundColor Yellow
    Write-Host ' onedrive.com. Start keeps its pins, and the lock screen its picture.' -ForegroundColor Yellow
    exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
}


# === Questions first, so the rest runs unattended ============================
$managed = Get-ManagedReason
$chosen = @(Select-Apps -Apps $appList -Choice $Apps)

$last = Get-LastAnswers
$same = $false
if ($last) {
    Write-Host ''
    Write-Host "  Last time ($($last.Date.ToString('d MMM yyyy'))): $(Format-Answers $last)" -ForegroundColor Cyan
    $same = Read-YesNo 'Same answers as last time? (n asks each question again)' -Default $true
}

# With the same answers these are taken from last time; only a new question is asked.
$reuse = if ($same) { $last }
if (-not $same) {
    Write-Host ''
    Write-Host '  A few questions. Each one defaults to the capital letter:' -ForegroundColor Cyan
}
# The default follows whether an organisation manages this PC. It is asked
# again when one does, but last time's answer was no.
$askWork = $managed -and -not $last.WorkPC
$workPC = Read-Answer $(if (-not $askWork) { $reuse }) WorkPC "Is this a work PC, managed by your employer$(if ($managed) { " (it is $managed)" })?" -Default ([bool]$managed)
# Never repeated: the PC name and the black background.
$newName = if (-not $same -and -not $workPC -and (Test-DefaultComputerName)) { Read-NewComputerName }

# Office is IT's on a work PC.
if ($workPC) {
    foreach ($app in $chosen | Where-Object { $_.NotOnWork }) { Write-Log "$($app.Name): left to IT, this is a work PC" -Level Skip }
    $chosen = @($chosen | Where-Object { -not $_.NotOnWork })
}
# Apps that need a licence (Ask) get one more question unless already installed, and install last.
$chosen = @($chosen | Where-Object {
        -not $_.Ask -or (Test-AppInstalled $_) -or (Read-YesNo "$($_.Name) is a big download and needs a licence to use. Install it?")
    })
$chosen = @($chosen | Where-Object { -not $_.Ask }) + @($chosen | Where-Object { $_.Ask })

# data\apps-office.xml is for a Microsoft 365 Family or Personal licence. A work or
# school account (enterprise and school plans) needs O365ProPlusRetail, in a copy of the file.
$office = $chosen | Where-Object { "$($_.Args)" -like '*apps-office.xml*' -and -not (Test-AppInstalled $_) }
if ($office -and (Read-YesNo 'Will you sign in to Microsoft 365 with a work or school account? (n: Family or Personal)' -Default ([bool]$managed))) {
    $xml = Join-Path $env:TEMP 'office-work.xml'
    if (-not $WhatIfPreference) { (Get-Content "$data\apps-office.xml" -Raw).Replace('O365HomePremRetail', 'O365ProPlusRetail') | Set-Content $xml -Encoding UTF8 }
    $office.Args = "/configure `"$xml`""
}

# The keep list: apps from apps-remove.psd1 that are on this PC. Sponsored apps only
# when Windows or the PC maker put them there and you did not pick them, work
# apps not on a work PC, and parts (PartOf) go with their app.
$present = @(Get-PresentApp -Remove $removeData.Remove -Sponsored $removeData.Sponsored)
$listed = @($present | Where-Object {
        -not $_.PartOf -and -not ($workPC -and $_.KeepOnWork) -and ($_.Pushed -or -not $_.Sponsored) -and $_.Name -notin $chosen.Name })
$keep = @(if ($same -and $null -ne $last.Keep) { $last.Keep } elseif ($listed) { Read-AppsToKeep -Apps $listed })

$doTweaks    = Read-Answer $reuse Tweaks 'Apply the general tweaks (data\tweaks-general.psd1)?' -Default $true
$doPrivacy   = Read-Answer $reuse Privacy 'Apply the privacy settings (data\privacy-general.psd1)?' -Default $true
$doStrict    = $doPrivacy -and -not $workPC -and (Read-Answer $reuse PrivacyStrict 'Apply the strict privacy settings too (data\privacy-strict.psd1)?')
$updateApps  = Read-Answer $reuse UpdateApps 'Update the apps from the menu that are already on this PC (winget)?'
$removeXbox  = Read-Answer $reuse RemoveXbox 'Remove the Xbox apps too (keep them on a gaming PC)?'
$doPersonal  = Read-Answer $reuse Personal 'Apply my personal preferences (data\tweaks-personal.psd1)?'
$doPins      = $doPersonal -and (Read-Answer $reuse StartPins 'Replace the Start pins with mine (data\start-pins.json)?')
$blackScreen = if ($same) { $false } else { Read-YesNo 'Plain black background on the desktop and the lock / sign-in screen?' }
$doCleanup   = Read-Answer $reuse Cleanup 'At the end, clear out old Windows update files (DISM component clean-up, 10+ minutes)?'
Write-LogData 'Answers' @{ WorkPC = $workPC; Tweaks = $doTweaks; Privacy = $doPrivacy; PrivacyStrict = $doStrict; UpdateApps = $updateApps
    RemoveXbox = $removeXbox; Personal = $doPersonal; StartPins = $doPins; Cleanup = $doCleanup; Keep = [string[]]@($keep | Where-Object { $_ })
    NewName = "$newName"; BlackBackground = $blackScreen; Same = $same; DryRun = [bool]$WhatIfPreference }

# From here on Setup runs on its own, so the PC must not go to sleep. The
# finally block lets it sleep again, also after Ctrl+C or an error.
Set-KeepAwake $true
try {
    # === 0. Restore point ====================================================
    Write-Log 'Restore point' -Level Step
    if (-not (New-RestorePoint)) {
        if (-not (Read-YesNo 'No restore point could be made. Continue without one?')) {
            Write-Log 'Stopped before changing anything.' -Level Warn
            Show-Summary
            exit 1
        }
        Write-Log 'Continuing without a restore point.' -Level Warn
    }


    # === 1. Remove apps ======================================================
    Write-Log 'Remove apps' -Level Step
    foreach ($r in $removeData.Remove) {
        if ($workPC -and $r.KeepOnWork) { Add-Result remove $r.Name Skipped 'kept, this is a work PC' 'work PC'; continue }
        if ($r.Name -in $keep -or ($r.PartOf -and $r.PartOf -in $keep)) { Add-Result remove $r.Name Skipped 'kept, as you asked'; continue }
        if ($r.Feature)       { Disable-OptionalFeature -Feature $r.Feature -Name $r.Name }
        elseif ($r.Uninstall) { Remove-DesktopApp -DisplayName $r.Uninstall -Name $r.Name -StopProcess $r.StopProcess -Guard $r.Guard }
        else                  { Remove-StoreApp -Package $r.Package -Name $r.Name -Guard $r.Guard }
    }

    $sponsored = @($present | Where-Object Sponsored)
    foreach ($s in $sponsored) {
        if (-not $s.Pushed) { Add-Result remove $s.Name Skipped 'kept, someone on this PC installed it' }
        elseif ($s.Name -in $chosen.Name) { Add-Result remove $s.Name Skipped 'kept, you picked it to install' }
        elseif ($s.Name -in $keep) { Add-Result remove $s.Name Skipped 'kept, as you asked' }
        else { Remove-StoreApp -Package $s.Package -Name $s.Name }
    }
    if (-not $sponsored) { Add-Result remove 'Sponsored apps' AlreadySet 'none on this PC' }

    if ($removeXbox) { foreach ($x in $removeData.Xbox) { Remove-StoreApp -Package $x.Package -Name $x.Name -Xbox } }
    else { Write-Log 'Xbox apps: kept' -Level Skip }


    # === 2. Install apps, then update them ===================================
    Write-Log 'Install apps' -Level Step
    $haveWinget = (($chosen | Where-Object { $_.Id }) -or $updateApps) -and (Initialize-Winget)
    foreach ($app in $chosen) {
        if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }
        if ($app.Url) {
            Install-FromUrl -Name $app.Name -Url $app.Url -Signer $app.Signer -Detect $app.Detect -Arguments ("$($app.Args)".Replace('{data}', $data))
        }
        elseif ($haveWinget) { Install-WingetApp -Id $app.Id -Name $app.Name -Source $(if ($app.Source) { $app.Source } else { 'winget' }) }
    }
    if (-not $chosen) { Write-Log 'Nothing picked.' }

    # Installers can bring removed apps back (Microsoft 365 does), so look again.
    if ($script:Results | Where-Object { $_.Step -eq 'apps' -and $_.Status -eq 'Changed' }) {
        $again = $removeData.Remove | Where-Object {
            $_.Package -and -not $_.Guard -and -not ($workPC -and $_.KeepOnWork) -and $_.Name -notin $keep -and $_.PartOf -notin $keep }
        foreach ($r in $again) {
            if (Get-InstalledStoreApp $r.Package) { Remove-StoreApp -Package $r.Package -Name "$($r.Name) (came back with an install)" }
        }
    }

    if ($updateApps) {
        Write-Log 'Update apps' -Level Step
        if ($haveWinget) { Update-Apps -Apps $appList }
    }


    # === 3-5. Tweaks, personal, privacy ======================================
    $restartExplorer = $false
    foreach ($set in @(
            @{ Title = 'Tweaks';   Step = 'tweaks';   Wanted = $doTweaks;   Items = $tweaks }
            @{ Title = 'Personal'; Step = 'personal'; Wanted = $doPersonal; Items = $personal }
            @{ Title = 'Privacy';  Step = 'privacy';  Wanted = $doPrivacy;  Items = $privacyAll })) {
        Write-Log $set.Title -Level Step
        if (-not $set.Wanted) { Write-Log 'Skipped, you said no' -Level Skip; continue }
        if (Set-RegList -Items $set.Items -Step $set.Step -WorkPC:$workPC) { $restartExplorer = $true }

        # Start pins, through the "Configure Start Pins" policy. applyOnce in the
        # file: they replace the pins at the next sign-in, after that Start is yours.
        if ($set.Step -eq 'personal' -and $doPins) {
            $pins = (Get-Content "$data\start-pins.json" -Raw) -replace '\r?\n\s*', ''
            $null = Set-RegValue -Key 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Value 'ConfigureStartPins' `
                -Data $pins -Type String -Label 'Start pins (show after signing out and in)' -Step 'personal'
        }
        if ($set.Step -eq 'privacy') {
            if ($workPC) { Write-Log 'Strict privacy settings: skipped, this is a work PC' -Level Skip }
            elseif (-not $doStrict) { Write-Log 'Strict privacy settings: skipped, you said no' -Level Skip }
            elseif (Set-RegList -Items $privacyStrict -Step 'privacy') { $restartExplorer = $true }
        }
    }


    # === 6. Extras ===========================================================
    Write-Log 'Extras' -Level Step
    if ($newName) { Rename-ThisPC -NewName $newName }
    if ($blackScreen) { Set-BlackBackground }
    if (-not ($newName -or $blackScreen)) { Write-Log 'None' -Level Skip }


    # === 7. Clean-up =========================================================
    Write-Log 'Clean-up' -Level Step
    if ($doCleanup) { Invoke-ComponentCleanup } else { Write-Log 'Skipped, you said no' -Level Skip }
}
finally { Set-KeepAwake $false }


# === Summary =================================================================
Show-Summary
if ($restartExplorer) { Request-ExplorerRestart }
$needsRestart = $script:Results | Where-Object { $_.Status -eq 'Changed' -and $_.Step -in 'remove', 'apps', 'tweaks', 'personal', 'privacy', 'extras' }
if ($needsRestart -and -not $WhatIfPreference) {
    Write-Host ''
    Write-Host ' Restart the PC to finish: policies, Start pins, removed parts of Windows and some installs need it.' -ForegroundColor Yellow
}
exit ([int](@($script:Results | Where-Object Status -eq 'Failed').Count -gt 0))
