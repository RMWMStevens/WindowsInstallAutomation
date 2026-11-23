# The functions Setup.ps1 uses. Setup.ps1 dot-sources this file, so everything
# here runs inside Setup.ps1 and sees its -WhatIf.
#
# Every function checks the current state first and does nothing when it is
# already right. Under -WhatIf they say what they would do and change nothing.

$script:Results = [System.Collections.Generic.List[object]]::new()
$script:LogPath = $null

# Setup's own folder on the PC, like AdwCleaner's C:\AdwCleaner: logs, and the
# black background picture. Fixed and easy to find, whether Setup ran from a
# clone or from the one-liner's temp folder. Safe to delete at any time; only
# Setup.cmd -Restore needs the logs, to know what to put back.
$script:WorkDir = Join-Path $env:SystemDrive 'WindowsInstallAutomation'

# Load the Store-app and Windows-feature modules now, with -WhatIf switched off
# just for this: loading them under -WhatIf prints a screen of "What if: Set
# Alias" lines from their own setup code. Modules read the global setting.
$whatIf = $global:WhatIfPreference
$global:WhatIfPreference = $false
Import-Module Appx, Dism -Global -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$global:WhatIfPreference = $whatIf

# winget writes UTF-8; without this Windows PowerShell reads it in the old
# console code page and "HWiNFO(R)" turns into "HWiNFO┬«" on screen and in the log.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }


# === Logging and the summary =================================================

function Start-Log {
    param([Parameter(Mandatory)][string]$Path)
    # Should the folder ever be out of reach, the log goes to the temp folder.
    try { New-Item -ItemType Directory -Path (Split-Path $Path) -Force -WhatIf:$false -ErrorAction Stop | Out-Null }
    catch { $Path = Join-Path $env:TEMP (Split-Path $Path -Leaf) }
    $script:LogPath = $Path

    # Anyone who finds the folder later can read what it is.
    if (Test-Path $script:WorkDir) {
        Set-Content (Join-Path $script:WorkDir 'README.txt') -Encoding UTF8 -WhatIf:$false -ErrorAction SilentlyContinue -Value @'
WindowsInstallAutomation
========================

This folder was made by WindowsInstallAutomation, a script that sets up a
Windows 11 PC: it installs the apps you pick, removes pre-installed apps and
applies a set of settings. What it does, and how to run it:

    https://github.com/RMWMStevens/WindowsInstallAutomation

Made by Roel Stevens -- https://roelstevens.dev

What is in this folder:

    logs\        one log file per run: what was changed, skipped or failed,
                 and how each changed setting was before
    black.png    the black background picture, if you chose that option

Nothing on this PC depends on this folder. You can delete it at any time,
but "Setup.cmd -Restore" needs the logs to put settings back the way they
were.
'@
    }

    $os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Windows $($os.DisplayVersion) build $($os.CurrentBuild) $($os.EditionID) ===" |
        Set-Content $Path -Encoding UTF8 -WhatIf:$false
}

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Ok', 'Warn', 'Fail', 'Step', 'Skip')][string]$Level = 'Info'
    )
    $prefix, $colour = switch ($Level) {
        'Step' { '', 'Cyan' }
        'Ok'   { '  [ ok ] ', 'Green' }
        'Skip' { '  [skip] ', 'DarkGray' }
        'Warn' { '  [warn] ', 'Yellow' }
        'Fail' { '  [FAIL] ', 'Red' }
        default { '  ', 'Gray' }
    }
    if ($Level -eq 'Step') { Write-Host ''; Write-Host "== $Message" -ForegroundColor $colour }
    else { Write-Host "$prefix$Message" -ForegroundColor $colour }
    if ($script:LogPath) { "$Level`t$Message" | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }
}

# Every check records one result; the summary at the end is built from these.
function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Changed', 'AlreadySet', 'Skipped', 'Failed')][string]$Status,
        [string]$Detail = ''
    )
    $script:Results.Add([pscustomobject]@{ Step = $Step; Name = $Name; Status = $Status; Detail = $Detail })
}

function Show-Summary {
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor Cyan
    Write-Host ' Summary' -ForegroundColor Cyan
    Write-Host ('=' * 62) -ForegroundColor Cyan
    $script:Results | Group-Object Step | ForEach-Object {
        $counts = $_.Group | Group-Object Status | ForEach-Object { "$($_.Name)=$($_.Count)" }
        Write-Host (' {0,-10} {1}' -f $_.Name, ($counts -join '  '))
    }
    $failed = @($script:Results | Where-Object Status -eq 'Failed')
    if ($failed) {
        Write-Host ''
        Write-Host " Failed ($($failed.Count)):" -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "   - $($_.Name): $($_.Detail)" -ForegroundColor Red }
    }
    $changed = @($script:Results | Where-Object Status -eq 'Changed').Count
    Write-Host ''
    Write-Host " $changed change(s) applied. Log: $script:LogPath"
}

# A yes/no question; Enter gives the default. With no console to ask on (a
# scripted run), the default is used as well.
function Read-YesNo {
    param([Parameter(Mandatory)][string]$Question, [bool]$Default = $false)
    $hint = if ($Default) { '[Y/n]' } else { '[y/N]' }
    try { $answer = Read-Host "  $Question $hint" } catch { return $Default }
    if ($answer -match '^[yY]') { return $true }
    if ($answer -match '^[nN]') { return $false }
    $Default
}

# Every real run writes its answers as an "Answers" line in its log, so the
# next run on this PC can offer them again. Dry runs do not count.
function Save-Answers {
    param([Parameter(Mandatory)][hashtable]$Answers)
    if ($WhatIfPreference -or -not $script:LogPath) { return }
    "Answers`t$(ConvertTo-Json ([pscustomobject]$Answers) -Compress)" | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false
}

# The answers of the newest real run on this PC, with the day it ran.
# Nothing when there is none.
function Get-LastAnswers {
    $logs = Get-ChildItem (Join-Path $script:WorkDir 'logs') -Filter 'setup-*.log' -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($log in $logs) {
        $line = @(Get-Content $log.FullName -Encoding UTF8) -like "Answers`t*" | Select-Object -Last 1
        if ($line) {
            return $line.Substring(8) | ConvertFrom-Json | Add-Member -NotePropertyName Date -NotePropertyValue $log.LastWriteTime -PassThru
        }
    }
}

# One line with the answers, for "Same answers as last time?". Questions that
# were not asked yet last time are left out.
function Format-Answers {
    param([Parameter(Mandatory)]$Answers)
    $labels = [ordered]@{ WorkPC = 'work PC'; Tweaks = 'tweaks'; Privacy = 'privacy'; UpdateAll = 'update all'
        RemoveXbox = 'remove Xbox'; Personal = 'personal + pins'; Cleanup = 'clean-up' }
    $parts = @(foreach ($key in $labels.Keys) {
            if ($null -ne $Answers.$key) { "$($labels[$key]) $(if ($Answers.$key) { 'yes' } else { 'no' })" }
        })
    $kept = @($Answers.KeepSponsored | Where-Object { $_ })
    if ($kept) { $parts += "sponsored apps kept: $($kept -join ', ')" }
    $parts -join ', '
}

# A yes/no question that "Same answers as last time?" can answer: with the
# same answers ($Reuse = last time's), it takes last time's answer without
# asking. A question that was not there last time -- one added to Setup later
# -- is asked anyway, on its own, and remembered from then on.
function Read-Answer {
    param($Reuse, [Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$Question, [bool]$Default = $false)
    if ($Reuse -and $null -ne $Reuse.$Key) { return [bool]$Reuse.$Key }
    Read-YesNo $Question -Default $Default
}

# Windows' own made-up names: DESKTOP-1A2B3C4, LAPTOP-1A2B3C4D, WIN-...
function Test-DefaultComputerName { $env:COMPUTERNAME -match '^(DESKTOP|LAPTOP|WIN)-[A-Z0-9]{5,11}$' }

# Asks for a new PC name. Returns nothing when you keep the current one.
function Read-NewComputerName {
    try { $new = "$(Read-Host "  This PC is called $env:COMPUTERNAME. New name (Enter keeps it)")".Trim() } catch { return }
    if (-not $new) { return }
    # Windows' rules: up to 15 letters, digits or hyphens, not only digits,
    # not starting or ending with a hyphen.
    if ($new -notmatch '^[A-Za-z0-9-]{1,15}$' -or $new -match '^\d+$' -or $new -match '^-|-$') {
        Write-Log "'$new' is not a valid PC name (up to 15 letters, digits or hyphens) -- keeping $env:COMPUTERNAME" -Level Warn
        return
    }
    $new
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


# === 0. Restore point ========================================================

# A restore point before anything changes. System Protection is switched on for
# the Windows drive first: without it there is nothing to restore to.
# Returns $true when there is one to fall back on.
function New-RestorePoint {
    $name = 'Restore point'
    if ($WhatIfPreference) {
        Write-Log "$name -- would create one before changing anything"
        Add-Result -Step 'safety' -Name $name -Status Skipped -Detail 'WhatIf'
        return $true
    }
    try {
        Write-Log "$name -- creating one, this takes a minute..."
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        $warning = $null
        Checkpoint-Computer -Description 'Before WindowsInstallAutomation' -RestorePointType MODIFY_SETTINGS `
            -ErrorAction Stop -WarningVariable warning -WarningAction SilentlyContinue
        if ($warning) {
            # Windows allows one a day; the one it already made covers this run.
            Write-Log "$name -- Windows made one in the last 24 hours, that one covers this run" -Level Skip
            Add-Result -Step 'safety' -Name $name -Status AlreadySet
            return $true
        }
        Write-Log "$name -- created ('Before WindowsInstallAutomation')" -Level Ok
        Add-Result -Step 'safety' -Name $name -Status Changed
        $true
    }
    catch {
        Write-Log "$name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'safety' -Name $name -Status Failed -Detail $_.Exception.Message
        $false
    }
}


# === 2. Installing ===========================================================

# Shows every app as a numbered list, grouped, and returns the ones picked.
# Answering n at "Go ahead?", or typing nothing usable, shows the menu again.
# $Choice skips the menu; it takes the same input: 'all', 'none', group names,
# numbers, ranges like 20-25.
function Select-Apps {
    param([Parameter(Mandatory)][object[]]$Apps, [string[]]$Choice)

    $interactive = -not $Choice
    while ($true) {
        if ($interactive) {
            $group = $null
            for ($i = 0; $i -lt $Apps.Count; $i++) {
                if ($Apps[$i].Group -ne $group) {
                    $group = $Apps[$i].Group
                    Write-Host ''
                    Write-Host "  $group" -ForegroundColor Cyan
                }
                $asks = if ($Apps[$i].Ask) { '  (asks first)' } else { '' }
                Write-Host ('    {0,2}  {1}{2}' -f ($i + 1), $Apps[$i].Name, $asks)
            }
            Write-Host ''
            Write-Host '  Type numbers, ranges or group names, e.g.  all   or   core social tools   or   1-5 9' -ForegroundColor Gray
            Write-Host '  Just Enter installs nothing (the removals and settings still run).' -ForegroundColor Gray
            $Choice = Read-Host '  Install'
        }

        $picked = [System.Collections.Generic.List[int]]::new()
        foreach ($token in ($Choice -split '[,\s]+' | Where-Object { $_ })) {
            $numbers = switch -Regex ($token) {
                '^all$'         { 1..$Apps.Count; break }
                '^none$'        { break }
                '^\d+$'         { [int]$token; break }
                '^(\d+)-(\d+)$' { [int]$Matches[1]..[int]$Matches[2]; break }
                default {
                    $inGroup = @(1..$Apps.Count | Where-Object { $Apps[$_ - 1].Group -eq $token })
                    if ($inGroup) { $inGroup } else { Write-Log "'$token' is not a number or a group -- ignored" -Level Warn }
                }
            }
            foreach ($n in $numbers) {
                if ($n -lt 1 -or $n -gt $Apps.Count) { Write-Log "There is no app $n -- ignored" -Level Warn }
                elseif (-not $picked.Contains($n)) { $picked.Add($n) }
            }
        }
        $result = @($picked | Sort-Object | ForEach-Object { $Apps[$_ - 1] })

        # Typed something, but none of it was an app or a group (a stray key, a
        # typo): ask again rather than quietly install nothing. Only just
        # Enter, or 'none', means no apps.
        if ($interactive -and -not $result -and "$Choice".Trim() -and $Choice -notmatch '\bnone\b') {
            Write-Host '  Nothing in that matched an app number or a group -- try again.' -ForegroundColor Yellow
            continue
        }
        if (-not $interactive -or -not $result) { return $result }
        Write-Host ''
        Write-Host "  $($result.Count) app(s): $($result.Name -join ', ')"
        if ((Read-Host '  Go ahead? [Y/n] (n picks again)') -notmatch '^[nN]') { return $result }
    }
}

# On a brand-new install winget only appears once the Store has updated App
# Installer, which can take a while after the first sign-in. Registering it
# like this is Microsoft's documented fix.
function Initialize-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return $true }
    Write-Log 'winget not found -- registering App Installer...'
    try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop } catch { }
    if (Get-Command winget -ErrorAction SilentlyContinue) { return $true }
    Write-Log 'winget is still missing. Update "App Installer" in the Microsoft Store, then run Setup again.' -Level Fail
    Add-Result -Step 'apps' -Name 'winget' -Status Failed -Detail 'not available'
    $false
}

# Is an app from apps.psd1 already on this PC? The same check the installers
# make. A winget app counts as not installed while winget is not there yet.
function Test-AppInstalled {
    param([Parameter(Mandatory)][hashtable]$App)
    if ($App.Url) { return [bool](Get-InstalledProgram $App.Detect) }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    $source = if ($App.Source) { $App.Source } else { 'winget' }
    $listed = & winget list --id $App.Id --exact --source $source --accept-source-agreements 2>$null
    $LASTEXITCODE -eq 0 -and ($listed -join "`n") -match [regex]::Escape($App.Id)
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string]$Source = 'winget'
    )

    if (Test-AppInstalled @{ Id = $Id; Source = $Source }) {
        Write-Log "$Name -- already installed" -Level Skip
        Add-Result -Step 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would install"
        Add-Result -Step 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    Write-Log "$Name -- installing..."
    $out = & winget install --id $Id --exact --silent --source $Source `
        --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    if ($script:LogPath) { $out | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }

    if ($LASTEXITCODE -eq 0) {
        Write-Log $Name -Level Ok
        Add-Result -Step 'apps' -Name $Name -Status Changed
    }
    elseif ($LASTEXITCODE -in -1978335189, -1978335135) {
        # winget's own "already installed / nothing newer": nothing changed.
        Write-Log "$Name -- already installed" -Level Skip
        Add-Result -Step 'apps' -Name $Name -Status AlreadySet
    }
    else {
        Write-Log "$Name -- winget exit $LASTEXITCODE (see log)" -Level Fail
        Add-Result -Step 'apps' -Name $Name -Status Failed -Detail "winget exit $LASTEXITCODE"
    }
}

# What winget would update right now: Name, Id and installed Version. Read
# from winget's table by column position, so it works in any Windows language.
# Apps winget is told to leave alone (pins, below) are not in the table.
function Get-WingetUpdates {
    $lines = @(& winget upgrade --accept-source-agreements --disable-interactivity 2>$null |
        ForEach-Object { ("$_" -split "`r")[-1] })
    $dashes = [array]::FindIndex([string[]]$lines, [Predicate[string]] { param($l) $l -match '^-{20,}$' })
    if ($dashes -lt 1) { return }   # no table: nothing to update
    $columns = [regex]::Matches($lines[$dashes - 1], '\S+')   # Name, Id, Version, Available, Source
    if ($columns.Count -lt 5) { return }
    $idAt, $versionAt, $sourceAt = $columns[1].Index, $columns[2].Index, $columns[4].Index
    foreach ($row in $lines[($dashes + 1)..($lines.Count - 1)]) {
        # A real row ends in one word (the source) at the Source column; the
        # sentences winget prints under the table do not.
        if ($row.Length -le $sourceAt -or $row.Substring($sourceAt).Trim() -match '\s') { break }
        [pscustomobject]@{
            Name    = $row.Substring(0, $idAt).Trim()
            Id      = $row.Substring($idAt).Trim().Split(' ')[0]
            Version = $row.Substring($versionAt).Trim().Split(' ')[0]
        }
    }
}

# Brings every app winget knows about up to date, except what it is told to
# leave alone ("pinned"; see them with: winget pin list). All of these still
# get updated, just not by Setup:
#   Microsoft 365     updates itself. winget's own Office package would rerun
#                     Microsoft's default setup, OneDrive and Teams included.
#   Windows Terminal  Setup's own window runs inside it; updating it would close
#                     that window halfway through. The Microsoft Store updates it.
#   App Installer     this is winget itself. Updating it mid-run left winget
#                     unable to answer straight after (seen on the laptop), and
#                     Setup still needs it then. The Microsoft Store updates it.
#   Node.js           only within its current major version (26.x stays 26.x):
#                     a jump to a new major can break projects, so that one is
#                     yours to make: winget pin remove OpenJS.NodeJS.LTS, then
#                     winget upgrade OpenJS.NodeJS.LTS
$script:LeaveAlone = @('Microsoft.Office', 'Microsoft.WindowsTerminal', '9N0DX20HK701', 'Microsoft.AppInstaller', '9NBLGGH4NNS1')

function Update-AllApps {
    $name = 'Update all apps'
    $before = @(Get-WingetUpdates | Where-Object { $_.Id -notin $script:LeaveAlone })
    if (-not $before) {
        Write-Log "$name -- everything is up to date already" -Level Skip
        Add-Result -Step 'apps' -Name $name -Status AlreadySet
        return
    }
    if ($WhatIfPreference) {
        Write-Log "$name -- would update $($before.Count) app(s): $($before.Name -join ', ')"
        Add-Result -Step 'apps' -Name $name -Status Skipped -Detail 'WhatIf'
        return
    }

    foreach ($id in $script:LeaveAlone) {
        $null = & winget pin add --id $id --exact --accept-source-agreements --disable-interactivity 2>&1
    }
    $node = $before | Where-Object { $_.Id -eq 'OpenJS.NodeJS.LTS' }
    if ($node -and $node.Version -match '^v?(\d+)\.') {
        $null = & winget pin add --id OpenJS.NodeJS.LTS --exact --version "$($Matches[1]).*" --force `
            --accept-source-agreements --disable-interactivity 2>&1
    }

    # One line per app on screen while it runs, everything winget says in the log.
    Write-Log "$name -- updating, this can take a while..."
    & winget upgrade --all --silent --accept-package-agreements --accept-source-agreements `
        --disable-interactivity 2>&1 | ForEach-Object {
        $line = ("$_" -split "`r")[-1]
        if ($script:LogPath) { Add-Content $script:LogPath $line -Encoding UTF8 -WhatIf:$false }
        if ($line -match '^\((\d+)/(\d+)\)\s+\S+\s+(.+?)\s+\[') { Write-Host "    ($($Matches[1])/$($Matches[2])) $($Matches[3])" -ForegroundColor Gray }
    }
    $exit = $LASTEXITCODE

    # Whatever winget still offers afterwards did not get updated -- an app that
    # was open, or one whose new version needs a fresh install.
    $left = @(Get-WingetUpdates)
    if ($left) {
        $names = $left.Name -join ', '
        Write-Log ("$name -- not updated: $names. winget's reason is in the log. Often the app was open: " +
            "close it and run Setup again. Otherwise the new version needs a fresh install: uninstall the app, then install it again.") -Level Fail
        Add-Result -Step 'apps' -Name $name -Status Failed -Detail "not updated: $names -- app open, or needs a fresh install (see the log)"
    }
    elseif ($exit -notin 0, -1978335189, -1978335212) {
        Write-Log "$name -- winget exit $exit (see the log)" -Level Fail
        Add-Result -Step 'apps' -Name $name -Status Failed -Detail "winget exit $exit -- see the log"
    }
    else {
        Write-Log "$name -- done" -Level Ok
        Add-Result -Step 'apps' -Name $name -Status Changed
    }
}

# Programs listed in Settings > Apps, matched on their name (wildcards ok).
function Get-InstalledProgram {
    param([Parameter(Mandatory)][string]$DisplayName)
    @(Get-ItemProperty -ErrorAction SilentlyContinue -Path @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        ) | Where-Object { $_.DisplayName -and $_.DisplayName -like $DisplayName })
}

# For an app winget cannot install reliably: downloads the installer, refuses it
# unless it is validly signed by the expected publisher, then runs it.
function Install-FromUrl {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Signer,
        [Parameter(Mandatory)][string]$Detect,
        [string]$Arguments = ''
    )

    if (Get-InstalledProgram $Detect) {
        Write-Log "$Name -- already installed" -Level Skip
        Add-Result -Step 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would download and install"
        Add-Result -Step 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    $file = Join-Path $env:TEMP ([IO.Path]::GetFileName(([uri]$Url).AbsolutePath))
    try {
        Write-Log "$Name -- downloading $Url"
        $ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads crawl
        Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing -ErrorAction Stop

        $sig = Get-AuthenticodeSignature -FilePath $file
        $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { 'unsigned' }
        if ($sig.Status -ne 'Valid' -or $subject -notmatch "(^|, )O=$([regex]::Escape($Signer))(,|$)") {
            throw "signature check failed: $($sig.Status), $subject"
        }

        Write-Log "$Name -- installing..."
        $proc = @{ FilePath = $file; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
        if ($Arguments) { $proc.ArgumentList = $Arguments }
        $p = Start-Process @proc
        if ($p.ExitCode -ne 0) { throw "installer exit $($p.ExitCode)" }

        Write-Log $Name -Level Ok
        Add-Result -Step 'apps' -Name $Name -Status Changed
    }
    catch {
        Write-Log "$Name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'apps' -Name $Name -Status Failed -Detail $_.Exception.Message
    }
    finally {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
}


# === 1. Removing =============================================================

# Desktop, Documents etc. that OneDrive folder backup has moved into OneDrive.
# Uninstalling OneDrive while any are listed would leave Explorer pointing at
# placeholders for files that may only exist in the cloud.
function Get-FoldersInOneDrive {
    $roots = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)
    $accounts = 'HKCU:\Software\Microsoft\OneDrive\Accounts'
    if (Test-Path $accounts) {
        $roots += Get-ChildItem $accounts -ErrorAction SilentlyContinue |
            ForEach-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).UserFolder }
    }
    $roots = @($roots | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') } | Sort-Object -Unique)
    if (-not $roots) { return }

    $shell = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue
    if (-not $shell) { return }

    # Only the folders backup can move. The same key also lists OneDrive's own
    # folders ({24D89E24-...} and so on), which live inside OneDrive by definition.
    $folders = [ordered]@{
        'Desktop'                                = 'Desktop'
        'Personal'                               = 'Documents'
        'My Pictures'                            = 'Pictures'
        'My Music'                               = 'Music'
        'My Video'                               = 'Videos'
        '{374DE290-123F-4565-9164-39C4925E467B}' = 'Downloads'
    }
    foreach ($name in $folders.Keys) {
        if (-not $shell.$name) { continue }
        $path = [Environment]::ExpandEnvironmentVariables([string]$shell.$name).TrimEnd('\')
        foreach ($r in $roots) {
            if ($path.Equals($r, [StringComparison]::OrdinalIgnoreCase) -or
                $path.StartsWith("$r\", [StringComparison]::OrdinalIgnoreCase)) {
                $folders[$name]
                break
            }
        }
    }
}

# Never removed, whatever remove.psd1 says. Without the first two a machine
# has no way to install anything back. Packages Windows marks NonRemovable
# (Start, taskbar, Explorer...) are refused in Remove-StoreApp below.
$script:ProtectedPackages = @(
    'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsStore', 'Microsoft.SecHealthUI'
    'Microsoft.UI.Xaml*', 'Microsoft.VCLibs*', 'Microsoft.NET*', 'Microsoft.WindowsAppRuntime*'
    'Microsoft.Windows.Photos', 'Microsoft.WindowsNotepad', 'Microsoft.WindowsTerminal', 'Microsoft.Paint'
)

# Xbox and gaming parts: only ever removed when you answer yes to the Xbox
# question during a run (Remove-StoreApp -Xbox), never by accident.
$script:XboxPackages = @('Microsoft.Xbox*', 'Microsoft.GamingApp', 'Microsoft.GamingServices', 'Microsoft.Edge.GameAssist')

# Windows keeps a copy of its built-in apps and installs it for every new user
# account. Removing that copy ("deprovisioning") stops that, and Windows then
# also leaves the app out of feature updates -- Microsoft's Remove-
# AppxProvisionedPackage and "remove provisioned apps during update" docs.
# Read once per run; it is slow.
function Get-ProvisionedApp {
    if (-not (Test-IsAdmin)) { return }   # only possible in a -WhatIf run
    if ($null -eq $script:Provisioned) { $script:Provisioned = @(Get-AppxProvisionedPackage -Online) }
    $script:Provisioned
}

# Which accounts really have a Store app installed. With admin rights Windows
# also lists apps that are only "staged" (its copy, waiting for new users);
# those do not count here.
function Get-InstalledStoreApp {
    param([Parameter(Mandatory)][string]$Package)
    $admin = Test-IsAdmin
    @(Get-AppxPackage -AllUsers:$admin -Name $Package -ErrorAction SilentlyContinue |
        Where-Object { -not $admin -or ($_.PackageUserInformation | Where-Object { "$($_.InstallState)" -eq 'Installed' }) })
}

# Store apps: removed for every user on the PC, and deprovisioned.
# Anything removed here can be reinstalled from the Store.
function Remove-StoreApp {
    param([Parameter(Mandatory)][string]$Package, [Parameter(Mandatory)][string]$Name, [switch]$Xbox)

    if ($script:ProtectedPackages | Where-Object { $Package -like $_ }) {
        Write-Log "$Name -- refused, '$Package' is on the protected list" -Level Warn
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'protected'
        return
    }
    if (-not $Xbox -and ($script:XboxPackages | Where-Object { $Package -like $_ })) {
        Write-Log "$Name -- refused, Xbox parts only go when you say yes to the Xbox question" -Level Warn
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'Xbox'
        return
    }

    $installed = Get-InstalledStoreApp $Package
    if ($installed | Where-Object { $_.NonRemovable }) {
        Write-Log "$Name -- refused, Windows marks '$Package' as part of the system" -Level Warn
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'part of Windows'
        return
    }
    $provisioned = @(Get-ProvisionedApp | Where-Object { $_.DisplayName -like $Package })
    if (-not $installed -and -not $provisioned) {
        Write-Log "$Name -- not present" -Level Skip
        Add-Result -Step 'remove' -Name $Name -Status AlreadySet
        return
    }

    $what = @()
    if ($installed) { $what += 'installed' }
    if ($provisioned) { $what += 'copy for new users' }
    if ($WhatIfPreference) {
        Write-Log "$Name -- would remove ($($what -join ' + '))"
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }
    try {
        # Windows' copy first: removing it also records that Windows must not
        # put the app back during a feature update.
        if ($provisioned) { $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null }
        if ($installed) { $installed | Remove-AppxPackage -AllUsers -ErrorAction Stop }
        Write-Log "$Name -- removed ($($what -join ' + '))" -Level Ok
        Add-Result -Step 'remove' -Name $Name -Status Changed
    }
    catch {
        Write-Log "$Name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'remove' -Name $Name -Status Failed -Detail $_.Exception.Message
    }
}

# Which of the sponsored apps in remove.psd1 are on this PC, and who put them
# there. Pushed = $true: the app is in Windows' copy for new users, so Windows
# or the PC maker put it in and every new account gets it automatically --
# those go. Pushed = $false: it is only installed for an account, so someone on
# this PC got it from the Store (the sponsored tiles in Start are only shortcuts
# that download the app when clicked) -- those stay. All apps are read in one
# go: asking for each of the forty one by one takes a minute.
function Get-SponsoredApp {
    param([object[]]$List)
    $admin = Test-IsAdmin
    $all = @(Get-AppxPackage -AllUsers:$admin -ErrorAction SilentlyContinue)
    $provisioned = @(Get-ProvisionedApp)
    foreach ($s in $List) {
        $pushed = [bool]($provisioned | Where-Object { $_.DisplayName -like $s.Package })
        $hits = @($all | Where-Object { $_.Name -like $s.Package })
        if ($admin) { $hits = @($hits | Where-Object { $_.PackageUserInformation | Where-Object { "$($_.InstallState)" -eq 'Installed' } }) }
        if ($pushed -or $hits) { [pscustomobject]@{ Name = $s.Name; Package = $s.Package; Pushed = $pushed } }
    }
}

# Shows the sponsored apps found and returns the ones you want to keep.
# Just Enter keeps none.
function Read-SponsoredToKeep {
    param([Parameter(Mandatory)][object[]]$Found)
    Write-Host ''
    Write-Host '  Sponsored apps that came with this PC. They are removed, unless you keep them:' -ForegroundColor Cyan
    for ($i = 0; $i -lt $Found.Count; $i++) { Write-Host ('    {0,2}  {1}' -f ($i + 1), $Found[$i].Name) }
    try { $answer = Read-Host '  Numbers to keep (just Enter removes them all)' } catch { return }
    foreach ($token in ("$answer" -split '[,\s]+' | Where-Object { $_ })) {
        if ($token -match '^\d+$' -and [int]$token -ge 1 -and [int]$token -le $Found.Count) { $Found[[int]$token - 1] }
        else { Write-Log "'$token' is not one of the numbers -- ignored" -Level Warn }
    }
}

# Normal desktop programs, through their own uninstaller. MSI packages run
# fully silent; anything else uses its quiet uninstall command if it has one.
function Remove-DesktopApp {
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$StopProcess
    )

    $entries = @(Get-InstalledProgram $DisplayName | Where-Object { $_.QuietUninstallString -or $_.UninstallString })
    if (-not $entries) {
        Write-Log "$Name -- not present" -Level Skip
        Add-Result -Step 'remove' -Name $Name -Status AlreadySet
        return
    }
    if ($WhatIfPreference) {
        Write-Log "$Name -- would uninstall ($(($entries.DisplayName | Sort-Object -Unique) -join ', '))"
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    if ($StopProcess) {
        Get-Process -Name $StopProcess -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    $errors = @()
    foreach ($e in $entries) {
        $cmd = if ($e.QuietUninstallString) { $e.QuietUninstallString } else { $e.UninstallString }
        $cmd = [Environment]::ExpandEnvironmentVariables($cmd)

        if ($cmd -match 'msiexec' -and $cmd -match '(\{[0-9A-Fa-f-]{36}\})') {
            $exe, $arg = 'msiexec.exe', "/x $($Matches[1]) /qn /norestart"
        }
        elseif ($cmd -match '^\s*"([^"]+)"\s*(.*)$') { $exe, $arg = $Matches[1], $Matches[2] }
        elseif ($cmd -match '^\s*(.+?\.exe)\s*(.*)$') { $exe, $arg = $Matches[1], $Matches[2] }
        else { $errors += "$($e.DisplayName): cannot read '$cmd'"; continue }

        try {
            $proc = @{ FilePath = $exe; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
            if ($arg.Trim()) { $proc.ArgumentList = $arg.Trim() }
            $p = Start-Process @proc
            # 3010 = removed, restart pending. 1605 = MSI says it is already gone.
            if ($p.ExitCode -notin 0, 3010, 1605) { $errors += "$($e.DisplayName): exit $($p.ExitCode)" }
        }
        catch { $errors += "$($e.DisplayName): $($_.Exception.Message)" }
    }

    if ($errors) {
        Write-Log "$Name -- $($errors -join '; ')" -Level Fail
        Add-Result -Step 'remove' -Name $Name -Status Failed -Detail ($errors -join '; ')
    }
    else {
        Write-Log "$Name -- removed" -Level Ok
        Add-Result -Step 'remove' -Name $Name -Status Changed
    }
}

# Windows optional features ("Turn Windows features on or off"): turned off
# and their files removed. A feature that does not exist here counts as gone.
function Disable-OptionalFeature {
    param([Parameter(Mandatory)][string]$Feature, [Parameter(Mandatory)][string]$Name)

    if (-not (Test-IsAdmin)) {   # only possible in a -WhatIf run
        Write-Log "$Name -- cannot check without admin" -Level Skip
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'needs admin to check'
        return
    }

    $state = $null
    try { $state = (Get-WindowsOptionalFeature -Online -FeatureName $Feature -ErrorAction Stop).State } catch { }
    if (-not $state -or "$state" -like 'Disable*') {
        Write-Log "$Name -- $(if ($state) { "already $state" } else { 'not on this PC' })" -Level Skip
        Add-Result -Step 'remove' -Name $Name -Status AlreadySet
        return
    }
    if ($WhatIfPreference) {
        Write-Log "$Name -- would turn off and remove (currently $state)"
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }
    try {
        $r = Disable-WindowsOptionalFeature -Online -FeatureName $Feature -Remove -NoRestart -ErrorAction Stop
        $detail = if ($r.RestartNeeded) { 'restart to finish' } else { '' }
        Write-Log "$Name -- removed$(if ($detail) { " ($detail)" })" -Level Ok
        Add-Result -Step 'remove' -Name $Name -Status Changed -Detail $detail
    }
    catch {
        Write-Log "$Name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'remove' -Name $Name -Status Failed -Detail $_.Exception.Message
    }
}


# === 3 to 5. Registry settings (tweaks, personal, privacy) ===================

# Before Setup changes a registry value, it writes down how it was: an "Undo"
# line in this run's log, with the old value and its type exactly (the
# readable lines cut long values short). Setup.cmd -Restore reads them back.
# Created = the first key on the way down that did not exist yet, so a
# restore can remove the keys Setup made, not just the value.
function Save-Undo {
    param([Parameter(Mandatory)][string]$Key, [string]$Value = '', [Parameter(Mandatory)][string]$Label)
    $undo = [ordered]@{ Label = $Label; Key = $Key; Value = $Value; Existed = $false; Data = $null; Type = $null; Created = $null }
    $path = $Key
    while (-not (Test-Path -LiteralPath $path)) { $undo.Created = $path; $path = Split-Path $path }
    if (-not $undo.Created) {
        $k = Get-Item -LiteralPath $Key
        if ($k.GetValueNames() -contains $Value) {
            $undo.Existed = $true
            $undo.Data = $k.GetValue($Value, $null, 'DoNotExpandEnvironmentNames')
            $undo.Type = "$($k.GetValueKind($Value))"
        }
    }
    if ($script:LogPath) {
        "Undo`t$(ConvertTo-Json ([pscustomobject]$undo) -Compress -Depth 3)" | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false
    }
}

# Writes one registry value, only if it differs from what is there.
# Returns $true when it changed something.
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Key,
        [string]$Value = '',
        [Parameter(Mandatory)][AllowEmptyString()]$Data,
        [string]$Type = 'DWord',
        [Parameter(Mandatory)][string]$Label,
        [string]$Step = 'settings'
    )

    # An empty value name means the key's (default) value, and '(default)' is
    # what New-ItemProperty calls it -- it refuses an empty name.
    $valueName = if ($Value) { $Value } else { '(default)' }
    # Long values (the Start pins list) are cut short on screen.
    $shown = if ("$Data".Length -gt 50) { "$("$Data".Substring(0, 47))..." } else { "$Data" }

    try {
        $current = $null
        if (Test-Path -LiteralPath $Key) { $current = (Get-Item -LiteralPath $Key).GetValue($Value) }
        $was = if ($null -eq $current) { 'not set' } elseif ("$current".Length -gt 50) { 'something else' } else { "'$current'" }

        if ($null -ne $current -and "$current" -eq "$Data") {
            Write-Log "$Label -- already $valueName=$shown" -Level Skip
            Add-Result -Step $Step -Name $Label -Status AlreadySet
            return
        }
        if ($WhatIfPreference) {
            Write-Log "$Label -- would set $valueName=$shown (now $was)"
            Add-Result -Step $Step -Name $Label -Status Skipped -Detail 'WhatIf'
            return
        }

        Save-Undo -Key $Key -Value $Value -Label $Label
        if (-not (Test-Path -LiteralPath $Key)) { New-Item -Path $Key -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $Key -Name $valueName -Value $Data -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Log "$Label -- set $valueName=$shown (was $was)" -Level Ok
        Add-Result -Step $Step -Name $Label -Status Changed -Detail "was $was"
        return $true
    }
    catch {
        Write-Log "$Label -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step $Step -Name $Label -Status Failed -Detail $_.Exception.Message
    }
}

# Applies every entry of one settings file. Returns $true when something that
# needs an Explorer restart changed.
function Set-RegList {
    param([Parameter(Mandatory)][object[]]$Items, [Parameter(Mandatory)][string]$Step)
    $restart = $false
    foreach ($t in $Items) {
        # IfPresent: only where the key exists already. Creating a key for a
        # service this PC does not have would leave a broken service entry.
        if ($t.IfPresent -and -not (Test-Path -LiteralPath $t.Key)) {
            Write-Log "$($t.Name) -- not on this PC" -Level Skip
            Add-Result -Step $Step -Name $t.Name -Status AlreadySet
            continue
        }
        $type = if ($t.Type) { $t.Type } else { 'DWord' }
        $changed = Set-RegValue -Key $t.Key -Value "$($t.Value)" -Data $t.Data -Type $type -Label $t.Name -Step $Step
        if ($changed -and $t.Explorer) { $restart = $true }
    }
    $restart
}


# === 6. Extras you said yes to =================================================

# The new name takes effect after the next restart.
function Rename-ThisPC {
    param([Parameter(Mandatory)][string]$NewName)
    $name = 'Rename this PC'
    if ($WhatIfPreference) {
        Write-Log "$name -- would rename $env:COMPUTERNAME to $NewName"
        Add-Result -Step 'extras' -Name $name -Status Skipped -Detail 'WhatIf'
        return
    }
    try {
        Rename-Computer -NewName $NewName -Force -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Log "$name -- $env:COMPUTERNAME becomes $NewName after a restart" -Level Ok
        Add-Result -Step 'extras' -Name $name -Status Changed -Detail 'restart to finish'
    }
    catch {
        Write-Log "$name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'extras' -Name $name -Status Failed -Detail $_.Exception.Message
    }
}

# The calls Settings itself makes: the desktop picture (empty = none) and the
# desktop colour ("R G B", as in the registry). Both show straight away.
function Set-DesktopPicture {
    param([string]$Path, [string]$Colour)
    if (-not ('WIA.Wallpaper' -as [type])) {
        Add-Type -Namespace WIA -Name Wallpaper -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SystemParametersInfo(int action, int param, string value, int flags);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetSysColors(int count, int[] elements, int[] colors);
'@
    }
    if ($Colour -match '^\s*(\d+)\s+(\d+)\s+(\d+)\s*$') {
        $rgb = [int]$Matches[1] + 256 * [int]$Matches[2] + 65536 * [int]$Matches[3]
        $null = [WIA.Wallpaper]::SetSysColors(1, @(1), @($rgb))   # element 1 = the desktop colour
    }
    if (-not [WIA.Wallpaper]::SystemParametersInfo(0x14, 0, "$Path", 3)) { throw 'Windows refused the desktop background' }
}

# A plain black picture on the desktop and the lock screen. The sign-in screen
# shows the lock screen picture (Windows' default), so it goes black as well.
# Both stay changeable in Settings afterwards.
function Set-BlackBackground {
    $name = 'Black background'
    $file = Join-Path $script:WorkDir 'black.png'

    $desktop = Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue
    if ((Test-Path $file) -and $desktop.WallPaper -eq $file -and $desktop.WallpaperStyle -eq '10') {
        Write-Log "$name -- already set" -Level Skip
        Add-Result -Step 'extras' -Name $name -Status AlreadySet
        return
    }
    if ($WhatIfPreference) {
        Write-Log "$name -- would set it on the desktop and the lock / sign-in screen"
        Add-Result -Step 'extras' -Name $name -Status Skipped -Detail 'WhatIf'
        return
    }

    try {
        # The picture: 1920x1080, all black, made on the spot.
        New-Item -ItemType Directory -Path (Split-Path $file) -Force | Out-Null
        Add-Type -AssemblyName System.Drawing
        $bmp = New-Object System.Drawing.Bitmap 1920, 1080
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Black)
        $g.Dispose()
        $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()

        # Desktop. Fit is set to "Fill" first and the desktop colour to black,
        # so no screen shape or size can leave a coloured edge around the
        # picture. What was there is written down for Setup.cmd -Restore.
        $desktop = 'HKCU:\Control Panel\Desktop'
        foreach ($v in 'WallpaperStyle', 'TileWallpaper', 'WallPaper') { Save-Undo -Key $desktop -Value $v -Label $name }
        Save-Undo -Key 'HKCU:\Control Panel\Colors' -Value 'Background' -Label $name
        Set-ItemProperty $desktop -Name WallpaperStyle -Value '10'
        Set-ItemProperty $desktop -Name TileWallpaper -Value '0'
        Set-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -Value '0 0 0'
        Set-DesktopPicture -Path $file -Colour '0 0 0'

        # Lock screen: Windows' own lock screen API, the one apps use.
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
        $null = [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
        $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
        $awaitFile = ($asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1).MakeGenericMethod([Windows.Storage.StorageFile])
        $awaitAction = $asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
        $picture = $awaitFile.Invoke($null, @([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)))
        $picture.Wait()
        $setLock = $awaitAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($picture.Result)))
        $setLock.Wait()

        Write-Log "$name -- set on the desktop and the lock / sign-in screen" -Level Ok
        Add-Result -Step 'extras' -Name $name -Status Changed
    }
    catch {
        $msg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
        Write-Log "$name -- $msg" -Level Fail
        Add-Result -Step 'extras' -Name $name -Status Failed -Detail $msg
    }
}


# === 7. Clean-up =============================================================

# Windows keeps the old version of every part of itself that an update
# replaces, in C:\Windows\WinSxS. It clears out the ones it no longer needs on
# its own, about once a month and only after 30 days (the StartComponentCleanup
# scheduled task). This does the same straight away -- worth it right after a
# fresh install has pulled in a pile of updates. Installed updates can still be
# uninstalled afterwards; /ResetBase would take that away, so it is NOT used.
function Invoke-ComponentCleanup {
    $name = 'Clean up old update files'
    if ($WhatIfPreference) {
        Write-Log "$name -- would run DISM /Online /Cleanup-Image /StartComponentCleanup"
        Add-Result -Step 'cleanup' -Name $name -Status Skipped -Detail 'WhatIf'
        return
    }
    # DISM refuses while Windows waits for a restart to finish installing or
    # removing something -- an update, or Recall removed earlier in this run.
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        Write-Log "$name -- skipped, Windows is waiting for a restart. Restart, run Setup again and say yes to the clean-up." -Level Skip
        Add-Result -Step 'cleanup' -Name $name -Status Skipped -Detail 'restart pending'
        return
    }

    $drive = $env:SystemDrive.TrimEnd(':')
    $freeBefore = (Get-PSDrive $drive).Free
    Write-Log "$name -- running DISM, this can take 10 minutes or more..."
    # In this same window, so DISM's own progress bar shows. What DISM did is
    # in its own log, not Setup's.
    $p = Start-Process dism.exe -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup' -NoNewWindow -Wait -PassThru
    $freed = [math]::Round(((Get-PSDrive $drive).Free - $freeBefore) / 1GB, 1)

    if ($p.ExitCode -in 0, 3010) {
        if ($freed -ge 0.1) {
            Write-Log "$name -- done, about $freed GB freed" -Level Ok
            Add-Result -Step 'cleanup' -Name $name -Status Changed -Detail "about $freed GB freed"
        }
        else {
            Write-Log "$name -- done, there was nothing to clear" -Level Skip
            Add-Result -Step 'cleanup' -Name $name -Status AlreadySet
        }
    }
    else {
        $log = "$env:windir\Logs\DISM\dism.log"
        Write-Log "$name -- DISM exit $($p.ExitCode). Its log: $log" -Level Fail
        Add-Result -Step 'cleanup' -Name $name -Status Failed -Detail "DISM exit $($p.ExitCode) -- see $log"
    }
}


# === Setup.cmd -Restore ======================================================

# Puts one registry value back the way an Undo line recorded it, and removes
# the keys Setup created for it once they are empty again. Returns $true when
# it changed something.
function Restore-RegValue {
    param([Parameter(Mandatory)]$Undo)
    $name = "$($Undo.Value)"
    $valueName = if ($name) { $name } else { '(default)' }
    try {
        $key = if (Test-Path -LiteralPath $Undo.Key) { Get-Item -LiteralPath $Undo.Key }
        $isSet = $key -and ($key.GetValueNames() -contains $name)
        if ($Undo.Existed) {
            $now = if ($isSet) { $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames') }
            $same = $isSet -and (ConvertTo-Json @($now) -Compress) -eq (ConvertTo-Json @($Undo.Data) -Compress)
            $shown = if ("$($Undo.Data)".Length -gt 50) { "$("$($Undo.Data)".Substring(0, 47))..." } else { "'$($Undo.Data)'" }
            $would, $done = "put $valueName back to $shown", "$valueName put back to $shown"
        }
        else {
            $same = -not $isSet
            $would, $done = "remove $valueName, it was not set before", "$valueName removed, it was not set before"
        }

        if ($same) {
            Write-Log "$($Undo.Label) -- $valueName is already as it was" -Level Skip
            Add-Result -Step 'restore' -Name $Undo.Label -Status AlreadySet
            return
        }
        if ($WhatIfPreference) {
            Write-Log "$($Undo.Label) -- would $would"
            Add-Result -Step 'restore' -Name $Undo.Label -Status Skipped -Detail 'WhatIf'
            return
        }

        if ($Undo.Existed) {
            $data = switch ($Undo.Type) {
                'DWord'       { [int]$Undo.Data }
                'QWord'       { [long]$Undo.Data }
                'Binary'      { [byte[]]@($Undo.Data) }
                'MultiString' { [string[]]@($Undo.Data) }
                default       { [string]$Undo.Data }
            }
            if (-not $key) { New-Item -Path $Undo.Key -Force -ErrorAction Stop | Out-Null }
            New-ItemProperty -LiteralPath $Undo.Key -Name $valueName -Value $data -PropertyType $Undo.Type -Force -ErrorAction Stop | Out-Null
        }
        else {
            # Through .NET: PowerShell cannot delete a key's (default) value.
            $hive, $subKey = $key.Name -split '\\', 2
            $root = if ($hive -eq 'HKEY_LOCAL_MACHINE') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
            $writable = $root.OpenSubKey($subKey, $true)
            try { $writable.DeleteValue($name) } finally { $writable.Close() }
            # Some keys work by just being there (the F1 one does), so the
            # keys Setup created go as well -- once nothing else is in them.
            if ($Undo.Created) {
                $path = $Undo.Key
                while (Test-Path -LiteralPath $path) {
                    $k = Get-Item -LiteralPath $path
                    if ($k.ValueCount -or $k.SubKeyCount) { break }
                    Remove-Item -LiteralPath $path -Force -ErrorAction Stop
                    if ($path -eq $Undo.Created) { break }
                    $path = Split-Path $path
                }
            }
        }
        Write-Log "$($Undo.Label) -- $done" -Level Ok
        Add-Result -Step 'restore' -Name $Undo.Label -Status Changed
        $true
    }
    catch {
        Write-Log "$($Undo.Label) -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'restore' -Name $Undo.Label -Status Failed -Detail $_.Exception.Message
    }
}

# Puts back every registry value that earlier runs changed: the newest run
# first, and within a run the last change first, so everything ends up as it
# was before the first run. The runs come from the Undo lines in the logs in
# C:\WindowsInstallAutomation\logs. Each log then gets a "Restored" line, so
# it is never put back twice. Returns $true when something changed.
function Restore-Settings {
    $logs = Get-ChildItem (Join-Path $script:WorkDir 'logs') -Filter 'setup-*.log' -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    $runs = @(foreach ($log in $logs) {
            $lines = @(Get-Content $log.FullName -Encoding UTF8)
            if ($lines -match '^Restored\t') { continue }
            $undo = @($lines -like "Undo`t*" | ForEach-Object { $_.Substring(5) | ConvertFrom-Json })
            if ($undo) { [pscustomobject]@{ Log = $log; Undo = $undo } }
        })
    if (-not $runs) {
        Write-Log ('Nothing to put back: no run of Setup has changed a setting on this PC since the last restore. ' +
            'Runs from before Setup had -Restore did not write down the old values; for those, use the restore point.') -Level Skip
        return $false
    }

    $total = 0
    foreach ($run in $runs) {
        Write-Log "Run of $($run.Log.LastWriteTime.ToString('d MMM yyyy HH:mm')): $($run.Undo.Count) setting(s)"
        $total += $run.Undo.Count
    }
    if (-not $WhatIfPreference -and -not (Read-YesNo "Put these $total setting(s) back the way they were?")) {
        Write-Log 'Nothing put back -- you said no' -Level Skip
        return $false
    }

    $changed = $false
    $wallpaper = $false
    foreach ($run in $runs) {
        for ($i = $run.Undo.Count - 1; $i -ge 0; $i--) {
            $u = $run.Undo[$i]
            if (Restore-RegValue $u) {
                $changed = $true
                if ($u.Key -eq 'HKCU:\Control Panel\Desktop' -and $u.Value -eq 'WallPaper') { $wallpaper = $true }
            }
        }
        if (-not $WhatIfPreference) { "Restored`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $run.Log.FullName -Encoding UTF8 }
    }

    # The old desktop picture is back in the registry; this shows it now.
    if ($wallpaper) {
        try {
            Set-DesktopPicture -Path (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper `
                -Colour (Get-ItemProperty 'HKCU:\Control Panel\Colors').Background
        }
        catch { Write-Log "Desktop picture -- $($_.Exception.Message). It shows after signing out and in." -Level Warn }
        Write-Log 'The lock screen picture stays black: pick another in Settings > Personalization > Lock screen.' -Level Warn
    }
    $changed
}
