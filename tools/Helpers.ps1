# Functions for Setup.ps1, which dot-sources this file, so -WhatIf reaches them.
# Each one checks first and leaves alone what is already right.

$script:Results = [System.Collections.Generic.List[object]]::new()
$script:LogPath = $null
$script:DocsDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsInstallAutomation'
$script:SpareDir = Join-Path $env:SystemDrive 'WindowsInstallAutomation'   # when Documents is blocked
$script:WorkDir = $script:DocsDir   # logs and black.png; Start-Log picks one of the two
# In every log name, so logs that OneDrive syncs in from other PCs are left alone.
$script:PcId = "$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -ErrorAction SilentlyContinue).MachineGuid)" -replace '^(.{8}).*', '$1'

# Loaded with -WhatIf off: under -WhatIf they print a screen of "What if" lines.
$whatIf = $global:WhatIfPreference
$global:WhatIfPreference = $false
Import-Module Appx, Dism, CimCmdlets -Global -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$global:WhatIfPreference = $whatIf

# winget writes UTF-8.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }


# === Logging, questions, answers =============================================

# Logs go to Documents. When that is blocked (Controlled folder access, say),
# to C:\WindowsInstallAutomation. Get-SetupLog reads both.
function Start-Log {
    param([Parameter(Mandatory)][string]$Name)
    $os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $header = "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Windows $($os.DisplayVersion) build $($os.CurrentBuild) $($os.EditionID) ==="
    $problem = $null
    foreach ($dir in $script:DocsDir, $script:SpareDir) {
        try {
            New-Item -ItemType Directory -Path "$dir\logs" -Force -WhatIf:$false -ErrorAction Stop | Out-Null
            $header | Set-Content "$dir\logs\$Name" -Encoding UTF8 -WhatIf:$false -ErrorAction Stop
            $script:WorkDir, $script:LogPath = $dir, "$dir\logs\$Name"
            break
        }
        catch { $problem = "Cannot write to $dir\logs: $($_.Exception.Message)" }
    }
    if ($problem) { Write-Log "$problem $(if ($script:LogPath) { "Logging to $script:LogPath instead." } else { 'No log for this run.' })" -Level Warn }
    if (-not $script:LogPath) { return }
    Set-Content (Join-Path $script:WorkDir 'README.txt') -Encoding UTF8 -WhatIf:$false -ErrorAction SilentlyContinue -Value @'
WindowsInstallAutomation set up this PC: it installed apps, removed
pre-installed ones and changed settings. What it does and why:
https://github.com/RMWMStevens/WindowsInstallAutomation

Made by Roel Stevens, https://roelstevens.dev

logs\       one log per run. To put the settings back, paste this in PowerShell:
            & ([scriptblock]::Create((irm https://roelie.cc/wia))) -Restore
            That needs these logs. It does not put removed apps back.
black.png   the black background, if chosen.
'@
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

# Logs "Name: message" and records the result for the summary. -Warn shows a
# Skipped result in yellow, for something you may want to act on.
function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Changed', 'AlreadySet', 'Skipped', 'Failed', 'WhatIf')][string]$Status,
        [string]$Message,
        [string]$Detail,
        [switch]$Warn
    )
    $level = if ($Warn) { 'Warn' } else { @{ Changed = 'Ok'; AlreadySet = 'Skip'; Skipped = 'Skip'; Failed = 'Fail'; WhatIf = 'Info' }[$Status] }
    if ($Message) { Write-Log "${Name}: $Message" -Level $level }
    if ($Status -eq 'WhatIf') { $Status, $Detail = 'Skipped', 'WhatIf' }
    elseif ($Status -eq 'Failed' -and -not $Detail) { $Detail = $Message }
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
    Write-Host ''
    Write-Host " $(@($script:Results | Where-Object Status -eq 'Changed').Count) change(s) applied. Log: $script:LogPath"
}

function Request-ExplorerRestart {
    Write-Host ''
    if (Read-YesNo 'Restart Explorer now so the taskbar and Explorer changes show?' -Default $true) {
        # Only in this session: other accounts that are signed in keep theirs.
        $session = (Get-Process -Id $PID).SessionId
        Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

# Enter gives the default, and so does a run without a console.
function Read-YesNo {
    param([Parameter(Mandatory)][string]$Question, [bool]$Default = $false)
    $hint = if ($Default) { '[Y/n]' } else { '[y/N]' }
    try { $answer = Read-Host "  $Question $hint" } catch { return $Default }
    if ($answer -match '^[yY]') { return $true }
    if ($answer -match '^[nN]') { return $false }
    $Default
}

# Log lines for the script itself: a tag, a tab, then JSON.
function Write-LogData {
    param([Parameter(Mandatory)][string]$Tag, [Parameter(Mandatory)]$Data)
    if ($script:LogPath) { "$Tag`t$(ConvertTo-Json ([pscustomobject]$Data) -Compress -Depth 3)" | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }
}

function Read-LogData {
    param([Parameter(Mandatory)]$Log, [Parameter(Mandatory)][string]$Tag)
    @(Get-Content $Log.FullName -Encoding UTF8) -like "$Tag`t*" | ForEach-Object { $_.Substring($Tag.Length + 1) | ConvertFrom-Json }
}

# Logs of earlier runs on this PC, newest first. Date: when the run started,
# from the name; -Restore writes to a log afterwards, which changes its file date.
function Get-SetupLog {
    Get-ChildItem "$script:DocsDir\logs", "$script:SpareDir\logs" -Filter 'setup-*.log' -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.Name -match "^setup-$script:PcId-(\d{8}-\d{6})\.log$") {
                $_ | Add-Member Date ([datetime]::ParseExact($Matches[1], 'yyyyMMdd-HHmmss', $null)) -PassThru
            }
        } |
        Sort-Object Date -Descending -Unique
}

# The answers of the newest real run (not a dry run), with its date.
function Get-LastAnswers {
    foreach ($log in Get-SetupLog) {
        $answers = Read-LogData $log 'Answers' | Where-Object { -not $_.DryRun } | Select-Object -Last 1
        if ($answers) { return $answers | Add-Member Date $log.Date -PassThru }
    }
}

# Only questions that were answered last time are shown.
function Format-Answers {
    param([Parameter(Mandatory)]$Answers)
    $labels = [ordered]@{ WorkPC = 'work PC'; Tweaks = 'tweaks'; Privacy = 'privacy'; PrivacyStrict = 'strict privacy'
        UpdateApps = 'update apps'; RemoveXbox = 'remove Xbox'; Personal = 'personal'; StartPins = 'Start pins'; Cleanup = 'clean-up' }
    $parts = @(foreach ($key in $labels.Keys) {
            if ($null -ne $Answers.$key) { "$($labels[$key]) $(if ($Answers.$key) { 'yes' } else { 'no' })" }
        })
    $kept = @($Answers.Keep | Where-Object { $_ })
    if ($kept) { $parts += "kept: $($kept -join ', ')" }
    $parts -join ', '
}

# With $Reuse (last time's answers), takes the answer from there. Asks when
# there is none, as for a question added since.
function Read-Answer {
    param($Reuse, [Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$Question, [bool]$Default = $false)
    if ($Reuse -and $null -ne $Reuse.$Key) { return [bool]$Reuse.$Key }
    Read-YesNo $Question -Default $Default
}

# Windows' made-up names: DESKTOP-1A2B3C4, LAPTOP-1A2B3C4D, WIN-...
function Test-DefaultComputerName { $env:COMPUTERNAME -match '^(DESKTOP|LAPTOP|WIN)-[A-Z0-9]{5,11}$' }

# Returns nothing when you keep the current name.
function Read-NewComputerName {
    try { $new = "$(Read-Host "  This PC is called $env:COMPUTERNAME. New name (Enter keeps it)")".Trim() } catch { return }
    if (-not $new) { return }
    # Up to 15 letters, digits or hyphens; not only digits; no hyphen at either end.
    if ($new -notmatch '^[A-Za-z0-9-]{1,15}$' -or $new -match '^\d+$' -or $new -match '^-|-$') {
        Write-Log "'$new' is not a valid PC name (up to 15 letters, digits or hyphens). Keeping $env:COMPUTERNAME." -Level Warn
        return
    }
    $new
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Why an organisation manages this PC, or nothing: joined to a domain or to
# Entra ID, or enrolled in device management (Intune and the like). Adding a
# work account to a personal PC does not count.
function Get-ManagedReason {
    if ((Get-CimInstance Win32_ComputerSystem).PartOfDomain) { return 'joined to a domain' }
    if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\*') { return 'joined to Entra ID' }
    # Windows keeps entries of its own here; those have no user.
    $mdm = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
        Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.ProviderID -and $_.UPN }
    if ($mdm) { 'enrolled in device management' }
}


# === 0. Restore point ========================================================

# Returns $true when there is one to fall back on. Turns on System Protection
# for the system drive when it is off.
function New-RestorePoint {
    $name = 'Restore point'
    if ($WhatIfPreference) { Add-Result safety $name WhatIf 'would create one'; return $true }
    try {
        Write-Log "${name}: creating one, this takes a minute..."
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        $warning = $null
        Checkpoint-Computer -Description 'Before WindowsInstallAutomation' -RestorePointType MODIFY_SETTINGS `
            -ErrorAction Stop -WarningVariable warning -WarningAction SilentlyContinue
        # Windows makes at most one a day.
        if ($warning) { Add-Result safety $name AlreadySet 'Windows made one in the last 24 hours, that one covers this run' }
        else { Add-Result safety $name Changed "created ('Before WindowsInstallAutomation')" }
        $true
    }
    catch { Add-Result safety $name Failed $_.Exception.Message; $false }
}


# === 1. Removing =============================================================

# Why OneDrive is in use, or nothing: someone is signed in to it, or OneDrive
# backup moved user folders (Desktop, Documents...) into it. Removing it then
# would stop the sync without a word and leave files that are only in the
# cloud unopenable.
function Get-OneDriveUse {
    $accounts = @(Get-ChildItem 'HKCU:\Software\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | Get-ItemProperty -ErrorAction SilentlyContinue)
    if ($accounts | Where-Object { $_.UserEmail }) { return 'someone is signed in to OneDrive' }
    $roots = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial) + @($accounts | ForEach-Object { $_.UserFolder })
    $roots = @($roots | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') } | Sort-Object -Unique)
    $shell = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue
    if (-not $roots -or -not $shell) { return }

    # Only the folders backup can move. The key also lists OneDrive's own folders.
    $folders = [ordered]@{ 'Desktop' = 'Desktop'; 'Personal' = 'Documents'; 'My Pictures' = 'Pictures'; 'My Music' = 'Music'
        'My Video' = 'Videos'; '{374DE290-123F-4565-9164-39C4925E467B}' = 'Downloads' }
    $moved = @(foreach ($name in $folders.Keys) {
            if (-not $shell.$name) { continue }
            $path = [Environment]::ExpandEnvironmentVariables([string]$shell.$name).TrimEnd('\')
            if ($roots | Where-Object { $path -eq $_ -or $path.StartsWith("$_\", [StringComparison]::OrdinalIgnoreCase) }) { $folders[$name] }
        })
    if ($moved) { "OneDrive backs up $($moved -join ', ')" }
}

# Never removed, whatever apps-remove.psd1 says: without the Store and winget nothing
# can be installed back. Packages Windows marks as part of the system are
# refused as well.
$script:ProtectedPackages = @(
    'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsStore', 'Microsoft.SecHealthUI'
    'Microsoft.UI.Xaml*', 'Microsoft.VCLibs*', 'Microsoft.NET*', 'Microsoft.WindowsAppRuntime*'
    'Microsoft.Windows.Photos', 'Microsoft.WindowsNotepad', 'Microsoft.WindowsTerminal', 'Microsoft.Paint'
)
# Only removed through the Xbox question.
$script:XboxPackages = @('Microsoft.Xbox*', 'Microsoft.GamingApp', 'Microsoft.GamingServices', 'Microsoft.Edge.GameAssist')

# Windows' copy of an app that every new account gets ("provisioned"). Read
# once per run, it is slow; Remove-StoreApp keeps it current. Needs admin, so
# empty in a dry run without it.
function Get-ProvisionedApp {
    if (-not (Test-IsAdmin)) { return }
    if ($null -eq $script:Provisioned) { $script:Provisioned = @(Get-AppxProvisionedPackage -Online) }
    $script:Provisioned
}

# Installed for an account. With admin, Windows also lists copies only waiting
# for new accounts; those do not count.
function Get-InstalledStoreApp {
    param([Parameter(Mandatory)][string]$Package)
    $admin = Test-IsAdmin
    @(Get-AppxPackage -AllUsers:$admin -Name $Package -ErrorAction SilentlyContinue |
        Where-Object { -not $admin -or ($_.PackageUserInformation | Where-Object { "$($_.InstallState)" -eq 'Installed' }) })
}

# Removed for every account, with its data, and from Windows' copy, which also
# keeps it out of feature updates. Most can be reinstalled from the Store.
# Guard 'OneDrive': kept while OneDrive is in use.
function Remove-StoreApp {
    param([Parameter(Mandatory)][string]$Package, [Parameter(Mandatory)][string]$Name, [switch]$Xbox, [string]$Guard)
    if ($script:ProtectedPackages | Where-Object { $Package -like $_ }) { return Add-Result remove $Name Skipped "refused, '$Package' is protected" }
    if (-not $Xbox -and ($script:XboxPackages | Where-Object { $Package -like $_ })) { return Add-Result remove $Name Skipped 'refused, Xbox parts only go through the Xbox question' }

    $installed = Get-InstalledStoreApp $Package
    if ($installed | Where-Object { $_.NonRemovable }) { return Add-Result remove $Name Skipped 'refused, Windows marks it as part of the system' }
    $provisioned = @(Get-ProvisionedApp | Where-Object { $_.DisplayName -like $Package })
    if (-not $installed -and -not $provisioned) { return Add-Result remove $Name AlreadySet 'not present' }
    if ($Guard -eq 'OneDrive' -and ($use = Get-OneDriveUse)) { return Add-Result remove $Name Skipped "kept, $use" }

    $what = @($(if ($installed) { 'installed' }), $(if ($provisioned) { 'copy for new users' }) | Where-Object { $_ }) -join ' + '
    if ($WhatIfPreference) { return Add-Result remove $Name WhatIf "would remove ($what)" }
    try {
        # Windows' copy first, so a feature update does not bring it back.
        if ($provisioned) {
            $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
            $script:Provisioned = @($script:Provisioned | Where-Object { $_.PackageName -notin $provisioned.PackageName })
        }
        if ($installed) { $installed | Remove-AppxPackage -AllUsers -ErrorAction Stop }
        Add-Result remove $Name Changed "removed ($what)"
    }
    catch { Add-Result remove $Name Failed $_.Exception.Message }
}

# The entries of apps-remove.psd1's Remove and Sponsored lists that are on this
# PC, for the keep list. Pushed: in Windows' copy for new accounts, so Windows
# or the PC maker put it there. A sponsored app without that was installed by
# someone from the Store (the sponsored tiles in Start only download the app
# when clicked). Windows features are left out.
function Get-PresentApp {
    param([object[]]$Remove, [object[]]$Sponsored)
    $admin = Test-IsAdmin
    $all = @(Get-AppxPackage -AllUsers:$admin -ErrorAction SilentlyContinue)
    $provisioned = @(Get-ProvisionedApp)
    foreach ($e in @($Remove) + @($Sponsored | ForEach-Object { $_ + @{ Sponsored = $true } })) {
        $pushed = $false
        if ($e.Uninstall) { $here = [bool](Get-InstalledProgram $e.Uninstall) }
        elseif ($e.Package) {
            $pushed = [bool]($provisioned | Where-Object { $_.DisplayName -like $e.Package })
            $hits = @($all | Where-Object { $_.Name -like $e.Package })
            if ($admin) { $hits = @($hits | Where-Object { $_.PackageUserInformation | Where-Object { "$($_.InstallState)" -eq 'Installed' } }) }
            $here = $pushed -or $hits
        }
        else { continue }
        if ($here) {
            [pscustomobject]@{ Name = $e.Name; Package = $e.Package; Sponsored = [bool]$e.Sponsored; Pushed = $pushed
                KeepOnWork = [bool]$e.KeepOnWork; PartOf = $e.PartOf }
        }
    }
}

# The keep list. Returns the names you keep; Enter keeps none.
function Read-AppsToKeep {
    param([Parameter(Mandatory)][object[]]$Apps)
    Write-Host ''
    Write-Host '  Setup removes these apps from this PC, with their data. Keep any?' -ForegroundColor Cyan
    for ($i = 0; $i -lt $Apps.Count; $i++) { Write-Host ('    {0,2}  {1}{2}' -f ($i + 1), $Apps[$i].Name, $(if ($Apps[$i].Sponsored) { '  (sponsored)' })) }
    try { $answer = Read-Host '  Numbers to keep (Enter removes them all)' } catch { return }
    foreach ($token in ("$answer" -split '[,\s]+' | Where-Object { $_ })) {
        if ($token -match '^\d+$' -and [int]$token -ge 1 -and [int]$token -le $Apps.Count) { $Apps[[int]$token - 1].Name }
        else { Write-Log "'$token' is not one of the numbers, ignored" -Level Warn }
    }
}

# Programs in Settings > Apps, by name (wildcards ok, several names ok).
function Get-InstalledProgram {
    param([Parameter(Mandatory)][string[]]$DisplayName)
    @(Get-ItemProperty -ErrorAction SilentlyContinue -Path @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        ) | Where-Object { $n = $_.DisplayName; $n -and ($DisplayName | Where-Object { $n -like $_ }) })
}

# Through the program's own uninstaller: MSI ones silently, others with the
# arguments they list, so an entry needs an uninstaller that asks nothing.
# Guard 'OneDrive': kept while OneDrive is in use.
function Remove-DesktopApp {
    param([Parameter(Mandatory)][string]$DisplayName, [Parameter(Mandatory)][string]$Name, [string[]]$StopProcess, [string]$Guard)
    $entries = @(Get-InstalledProgram $DisplayName | Where-Object { $_.QuietUninstallString -or $_.UninstallString })
    if (-not $entries) { return Add-Result remove $Name AlreadySet 'not present' }
    if ($Guard -eq 'OneDrive' -and ($use = Get-OneDriveUse)) { return Add-Result remove $Name Skipped "kept, $use" }
    if ($WhatIfPreference) { return Add-Result remove $Name WhatIf "would uninstall ($(($entries.DisplayName | Sort-Object -Unique) -join ', '))" }

    if ($StopProcess) { Get-Process -Name $StopProcess -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
    $errors = foreach ($e in $entries) {
        $cmd = [Environment]::ExpandEnvironmentVariables($(if ($e.QuietUninstallString) { $e.QuietUninstallString } else { $e.UninstallString }))
        if ($cmd -match 'msiexec' -and $cmd -match '(\{[0-9A-Fa-f-]{36}\})') { $exe, $arg = 'msiexec.exe', "/x $($Matches[1]) /qn /norestart" }
        elseif ($cmd -match '^\s*"([^"]+)"\s*(.*)$' -or $cmd -match '^\s*(.+?\.exe)\s*(.*)$') { $exe, $arg = $Matches[1], $Matches[2].Trim() }
        else { "$($e.DisplayName): cannot read '$cmd'"; continue }
        try {
            $proc = @{ FilePath = $exe; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
            if ($arg) { $proc.ArgumentList = $arg }
            $exit = (Start-Process @proc).ExitCode
            # 3010: restart pending. 1605: already gone.
            if ($exit -notin 0, 3010, 1605) { "$($e.DisplayName): exit $exit" }
        }
        catch { "$($e.DisplayName): $($_.Exception.Message)" }
    }
    if ($errors) { Add-Result remove $Name Failed ($errors -join '; ') }
    else { Add-Result remove $Name Changed 'removed' }
}

# A Windows optional feature, turned off and its files removed. Turning it on
# again in Windows Features downloads them again.
function Disable-OptionalFeature {
    param([Parameter(Mandatory)][string]$Feature, [Parameter(Mandatory)][string]$Name)
    if (-not (Test-IsAdmin)) { return Add-Result remove $Name Skipped 'cannot check without admin' }
    $state = $null
    try { $state = (Get-WindowsOptionalFeature -Online -FeatureName $Feature -ErrorAction Stop).State } catch { }
    if (-not $state -or "$state" -like 'Disable*') { return Add-Result remove $Name AlreadySet $(if ($state) { "already $state" } else { 'not on this PC' }) }
    if ($WhatIfPreference) { return Add-Result remove $Name WhatIf "would turn off and remove (now $state)" }
    try {
        $r = Disable-WindowsOptionalFeature -Online -FeatureName $Feature -Remove -NoRestart -ErrorAction Stop
        if ($r.RestartNeeded) { Add-Result remove $Name Changed 'removed (restart to finish)' 'restart to finish' }
        else { Add-Result remove $Name Changed 'removed' }
    }
    catch { Add-Result remove $Name Failed $_.Exception.Message }
}


# === 2. Installing and updating ==============================================

# The numbered app menu. $Choice skips it and takes the same input: all, none,
# group names, numbers, ranges like 20-25.
function Select-Apps {
    param([Parameter(Mandatory)][object[]]$Apps, [string[]]$Choice)
    $interactive = -not $Choice
    while ($true) {
        if ($interactive) {
            $group = $null
            for ($i = 0; $i -lt $Apps.Count; $i++) {
                if ($Apps[$i].Group -ne $group) { $group = $Apps[$i].Group; Write-Host ''; Write-Host "  $group" -ForegroundColor Cyan }
                Write-Host ('    {0,2}  {1}{2}' -f ($i + 1), $Apps[$i].Name, $(if ($Apps[$i].Ask) { '  (asks first)' }))
            }
            Write-Host ''
            Write-Host '  Type numbers, ranges or group names, e.g.  all   or   core social tools   or   1-5 9' -ForegroundColor Gray
            Write-Host '  Enter installs nothing (the removals and settings still run).' -ForegroundColor Gray
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
                    if ($inGroup) { $inGroup } else { Write-Log "'$token' is not a number or a group, ignored" -Level Warn }
                }
            }
            foreach ($n in $numbers) {
                if ($n -lt 1 -or $n -gt $Apps.Count) { Write-Log "There is no app $n, ignored" -Level Warn }
                elseif (-not $picked.Contains($n)) { $picked.Add($n) }
            }
        }
        $result = @($picked | Sort-Object | ForEach-Object { $Apps[$_ - 1] })

        # Something typed that matched nothing (a typo): ask again. Only Enter
        # or 'none' means no apps.
        if ($interactive -and -not $result -and "$Choice".Trim() -and $Choice -notmatch '\bnone\b') {
            Write-Host '  Nothing in that matched an app number or a group. Try again.' -ForegroundColor Yellow
            continue
        }
        if (-not $interactive -or -not $result) { return $result }
        Write-Host ''
        Write-Host "  $($result.Count) app(s): $($result.Name -join ', ')"
        if ((Read-Host '  Go ahead? [Y/n] (n picks again)') -notmatch '^[nN]') { return $result }
    }
}

# On a new install winget only appears once the Store has updated App
# Installer. Registering it is Microsoft's documented fix. Versions before 1.6
# lack options Setup uses.
function Initialize-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log 'winget not found, registering App Installer...'
        try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop } catch { }
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { $what = 'missing' }
    else {
        $version = "$(& winget --version 2>$null)" -replace '^v|-.*$'
        if (($version -as [version]) -ge [version]'1.6') { return $true }
        $what = "version $version is too old"
    }
    Add-Result apps winget Failed "$what. Update ""App Installer"" in the Microsoft Store, then run Setup again."
    $false
}

function Test-AppInstalled {
    param([Parameter(Mandatory)][hashtable]$App)
    if ($App.Url) { return [bool](Get-InstalledProgram $App.Detect) }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    $source = if ($App.Source) { $App.Source } else { 'winget' }
    $listed = & winget list --id $App.Id --exact --source $source --accept-source-agreements 2>$null
    $LASTEXITCODE -eq 0 -and ($listed -join "`n") -match [regex]::Escape($App.Id)
}

# The winget exit codes Setup explains, from winget's returnCodes.md. Any other
# code is a failure; the log has winget's own words.
$script:WingetResults = @{
    -1978335189 = 'AlreadySet', 'up to date'                                                     # UPDATE_NOT_APPLICABLE
    -1978335135 = 'AlreadySet', 'already installed'                                              # PACKAGE_ALREADY_INSTALLED
    -1978335128 = 'AlreadySet', 'kept on its version by a winget pin'                            # PACKAGE_IS_PINNED
    -1978334967 = 'Changed', 'done, restart the PC to finish'                                    # INSTALL_REBOOT_REQUIRED_TO_FINISH
    -1978335212 = 'Failed', 'not found in winget, run tools\Test-AppIds.ps1'                     # NO_APPLICATIONS_FOUND
    -1978335090 = 'Skipped', 'the new version installs differently: uninstall the app, then install it again'   # UPDATE_INSTALL_TECHNOLOGY_MISMATCH
    -1978334975 = 'Failed', 'it is open: close it and run Setup again'                           # INSTALL_PACKAGE_IN_USE
    -1978334973 = 'Failed', 'it is open: close it and run Setup again'                           # INSTALL_FILE_IN_USE
    -1978335146 = 'Failed', 'its installer will not run as admin: install it yourself'           # INSTALLER_PROHIBITS_ELEVATION
}

# Records a winget install or update by its exit code. $Done: the word for 0.
function Add-WingetResult {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][int]$Exit, [Parameter(Mandatory)][string]$Done)
    $status, $message = 'Failed', "winget exit $Exit (see the log)"
    if ($Exit -eq 0) { $status, $message = 'Changed', $Done }
    elseif ($script:WingetResults.ContainsKey($Exit)) { $status, $message = $script:WingetResults[$Exit] }
    Add-Result apps $Name $status $message -Warn:($status -eq 'Skipped')
}

function Install-WingetApp {
    param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Name, [string]$Source = 'winget')
    if (Test-AppInstalled @{ Id = $Id; Source = $Source }) { return Add-Result apps $Name AlreadySet 'already installed' }
    if ($WhatIfPreference) { return Add-Result apps $Name WhatIf 'would install' }

    Write-Log "${Name}: installing..."
    $out = & winget install --id $Id --exact --silent --source $Source `
        --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    if ($script:LogPath) { $out | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }
    Add-WingetResult $Name $LASTEXITCODE 'installed'
}

# "Update apps": the winget apps from the menu that are on this PC, one at a
# time. Store apps are left to the Store, NoUpdate ones update another way.
# SameMajor: a winget pin keeps it on its major version, read from Settings >
# Apps (Detect). That pin stays after Setup.
function Update-Apps {
    param([Parameter(Mandatory)][object[]]$Apps)
    $common = '--exact', '--source', 'winget', '--accept-source-agreements', '--disable-interactivity'
    $any = $false
    foreach ($app in $Apps | Where-Object { $_.Id -and -not $_.Source -and -not $_.NoUpdate }) {
        if ($app.SameMajor -and -not $WhatIfPreference -and "$(@(Get-InstalledProgram $app.Detect)[0].DisplayVersion)" -match '^v?(\d+)\.') {
            $null = & winget pin add --id $app.Id --version "$($Matches[1]).*" --force @common 2>&1
        }
        # Lists the app only when it is installed and has a newer version.
        $listed = & winget list --id $app.Id --upgrade-available @common 2>$null
        if (($listed -join "`n") -notmatch [regex]::Escape($app.Id)) { continue }
        $any = $true
        if ($WhatIfPreference) { Add-Result apps $app.Name WhatIf 'would update'; continue }

        Write-Log "$($app.Name): updating..."
        $out = & winget upgrade --id $app.Id --silent --accept-package-agreements @common 2>&1 | Out-String
        if ($script:LogPath) { $out | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }
        Add-WingetResult $app.Name $LASTEXITCODE 'updated'
    }
    if (-not $any) { Add-Result apps 'Update apps' AlreadySet 'the apps from the menu are up to date' }
}

# For an app winget cannot install reliably. Refused unless validly signed by
# $Signer. Left alone when anything matching $Detect is installed.
function Install-FromUrl {
    param(
        [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Url, [Parameter(Mandatory)][string]$Signer,
        [Parameter(Mandatory)][string[]]$Detect, [string]$Arguments
    )
    if ($found = @(Get-InstalledProgram $Detect)) { return Add-Result apps $Name AlreadySet "already installed: $($found[0].DisplayName)" }
    if ($WhatIfPreference) { return Add-Result apps $Name WhatIf 'would download and install' }

    $file = Join-Path $env:TEMP ([IO.Path]::GetFileName(([uri]$Url).AbsolutePath))
    try {
        Write-Log "${Name}: downloading $Url"
        $ProgressPreference = 'SilentlyContinue'   # the progress bar slows downloads down
        Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing -ErrorAction Stop
        $sig = Get-AuthenticodeSignature -FilePath $file
        $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { 'unsigned' }
        if ($sig.Status -ne 'Valid' -or $subject -notmatch "(^|, )O=$([regex]::Escape($Signer))(,|$)") {
            throw "signature check failed: $($sig.Status), $subject"
        }
        Write-Log "${Name}: installing..."
        $proc = @{ FilePath = $file; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
        if ($Arguments) { $proc.ArgumentList = $Arguments }
        $exit = (Start-Process @proc).ExitCode
        if ($exit -ne 0) { throw "installer exit $exit" }
        Add-Result apps $Name Changed 'installed'
    }
    catch { Add-Result apps $Name Failed $_.Exception.Message }
    finally { Remove-Item $file -Force -ErrorAction SilentlyContinue }
}


# === 3 to 5. Registry settings ===============================================

# Writes down a value as it is before Setup changes it, for -Restore. Created
# is the first key on the way down that does not exist yet.
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
    Write-LogData 'Undo' $undo
}

# Returns $true when it changed something. An empty $Value is the key's
# (default) value. A value someone set to something else is left alone with
# $IfData (only change it from that value, Windows' default) and, on a work
# PC, with -KeepPolicies for policies, which IT may have set.
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Key, [string]$Value = '', [Parameter(Mandatory)][AllowEmptyString()]$Data,
        [string]$Type = 'DWord', [Parameter(Mandatory)][string]$Label, [string]$Step = 'settings',
        [string]$IfData, [switch]$KeepPolicies
    )
    $valueName = if ($Value) { $Value } else { '(default)' }
    $shown = if ("$Data".Length -gt 50) { "$("$Data".Substring(0, 47))..." } else { "$Data" }
    try {
        $current = if (Test-Path -LiteralPath $Key) { (Get-Item -LiteralPath $Key).GetValue($Value) }
        $was = if ($null -eq $current) { 'not set' } elseif ("$current".Length -gt 50) { 'something else' } else { "'$current'" }
        if ($null -ne $current -and "$current" -eq "$Data") { return Add-Result $Step $Label AlreadySet "already $valueName=$shown" }
        if ($null -ne $current -and (($IfData -and "$current" -ne $IfData) -or ($KeepPolicies -and $Key -like '*\Policies\*'))) {
            return Add-Result $Step $Label Skipped "left alone, someone set $valueName to $was"
        }
        if ($WhatIfPreference) { return Add-Result $Step $Label WhatIf "would set $valueName=$shown (now $was)" }

        Save-Undo -Key $Key -Value $Value -Label $Label
        if (-not (Test-Path -LiteralPath $Key)) { New-Item -Path $Key -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $Key -Name $valueName -Value $Data -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Add-Result $Step $Label Changed "set $valueName=$shown (was $was)" "was $was"
        $true
    }
    catch { Add-Result $Step $Label Failed $_.Exception.Message }
}

# Applies one settings file. Returns $true when Explorer needs a restart.
function Set-RegList {
    param([Parameter(Mandatory)][object[]]$Items, [Parameter(Mandatory)][string]$Step, [switch]$WorkPC)
    $restart = $false
    foreach ($t in $Items) {
        if ($WorkPC -and $t.NotOnWork) { Add-Result $Step $t.Name Skipped 'left alone, this is a work PC'; continue }
        if ($t.TaskbarAutoHide) { Set-TaskbarAutoHide -Name $t.Name -Step $Step; continue }
        # Never create the key of a service this PC does not have.
        if ($t.IfPresent -and -not (Test-Path -LiteralPath $t.Key)) { Add-Result $Step $t.Name AlreadySet 'not on this PC'; continue }
        $type = if ($t.Type) { $t.Type } else { 'DWord' }
        $set = Set-RegValue -Key $t.Key -Value "$($t.Value)" -Data $t.Data -Type $type -Label $t.Name -Step $Step `
            -IfData "$($t.IfData)" -KeepPolicies:$WorkPC
        if ($set -and $t.Explorer) { $restart = $true }
    }
    $restart
}

# Reads taskbar auto-hide, or sets it with -On, through the call Windows
# documents for it (SHAppBarMessage), as Settings does: it shows at once.
# Returns whether it is on.
function Invoke-AutoHide {
    param($On)
    Add-NativeType
    $bar = New-Object WIA.Native+APPBARDATA
    $bar.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($bar)
    # ABM_SETSTATE is 10, ABM_GETSTATE 4; ABS_AUTOHIDE is 1.
    if ($null -ne $On) { $bar.lParam = [IntPtr][int][bool]$On; $null = [WIA.Native]::SHAppBarMessage(10, [ref]$bar) }
    [bool]([WIA.Native]::SHAppBarMessage(4, [ref]$bar).ToUInt64() -band 1)
}

# "Automatically hide the taskbar", on or off. Windows writes it to its own
# value (byte 8 of StuckRects3\Settings) only later, so Setup sets that bit
# too: otherwise restarting Explorer undoes it. Only that bit, also in
# -Restore: the rest of the value is the screen layout.
$script:StuckRects = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
function Set-TaskbarAutoHide {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Step, [bool]$On = $true)
    $word = if ($On) { 'on' } else { 'off' }
    $blob = (Get-Item -LiteralPath $script:StuckRects -ErrorAction SilentlyContinue).GetValue('Settings')
    $stored = $blob -isnot [byte[]] -or $blob.Length -le 8 -or [bool]($blob[8] -band 1) -eq $On   # a new account has no value yet
    if ($stored -and (Invoke-AutoHide) -eq $On) { return Add-Result $Step $Name AlreadySet "already $word" }
    if ($WhatIfPreference) { return Add-Result $Step $Name WhatIf "would turn it $word" }
    try {
        Save-Undo -Key $script:StuckRects -Value 'Settings' -Label $Name
        if ((Invoke-AutoHide $On) -ne $On) { throw "Windows did not turn it $word" }
        if (-not $stored) {
            $blob[8] = if ($On) { $blob[8] -bor 1 } else { $blob[8] -band 254 }
            Set-ItemProperty -LiteralPath $script:StuckRects -Name Settings -Value $blob -ErrorAction Stop
        }
        Add-Result $Step $Name Changed "turned $word"
    }
    catch { Add-Result $Step $Name Failed "$($_.Exception.Message)" }
}


# === 6. Extras ===============================================================

function Rename-ThisPC {
    param([Parameter(Mandatory)][string]$NewName)
    $name = 'Rename this PC'
    if ($WhatIfPreference) { return Add-Result extras $name WhatIf "would rename $env:COMPUTERNAME to $NewName" }
    try {
        Rename-Computer -NewName $NewName -Force -ErrorAction Stop -WarningAction SilentlyContinue
        Add-Result extras $name Changed "$env:COMPUTERNAME becomes $NewName after a restart" 'restart to finish'
    }
    catch { Add-Result extras $name Failed $_.Exception.Message }
}

# Windows functions PowerShell has no command for, compiled on first use.
function Add-NativeType {
    if ('WIA.Native' -as [type]) { return }
    Add-Type -Namespace WIA -Name Native -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SystemParametersInfo(int action, int param, string value, int flags);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetSysColors(int count, int[] elements, int[] colors);
[DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint flags);
[StructLayout(LayoutKind.Sequential)]
public struct APPBARDATA { public int cbSize; public IntPtr hWnd; public uint uCallbackMessage; public uint uEdge; public int left, top, right, bottom; public IntPtr lParam; }
[DllImport("shell32.dll")]
public static extern UIntPtr SHAppBarMessage(uint message, ref APPBARDATA data);
'@
}

# Keeps the PC awake while Setup runs on its own, so a laptop does not go to
# sleep halfway. The screen stays on too: only that keeps a Modern Standby
# laptop out of standby.
function Set-KeepAwake {
    param([Parameter(Mandatory)][bool]$On)
    Add-NativeType
    # ES_CONTINUOUS (0x80000000), plus ES_SYSTEM_REQUIRED and ES_DISPLAY_REQUIRED (1 and 2) when on.
    $null = [WIA.Native]::SetThreadExecutionState($(if ($On) { 2147483651 } else { 2147483648 }))
}

# The desktop picture (empty = none) and colour ("R G B"), the way Settings
# sets them. Both show straight away.
function Set-DesktopPicture {
    param([string]$Path, [string]$Colour)
    Add-NativeType
    if ($Colour -match '^\s*(\d+)\s+(\d+)\s+(\d+)\s*$') {
        $null = [WIA.Native]::SetSysColors(1, @(1), @([int]$Matches[1] + 256 * [int]$Matches[2] + 65536 * [int]$Matches[3]))
    }
    if (-not [WIA.Native]::SystemParametersInfo(0x14, 0, "$Path", 3)) { throw 'Windows refused the desktop background' }
}

# A policy Setup sets outside the data files. -Restore puts back policies and
# values for the whole PC only when they are here or in the data files.
$script:OwnValues = @('HKCU:\Software\Policies\Microsoft\Windows\Explorer|ConfigureStartPins')

# Black on the desktop and the lock screen, so also on the sign-in screen.
# Changeable in Settings afterwards.
function Set-BlackBackground {
    $name = 'Black background'
    $file = Join-Path $script:WorkDir 'black.png'
    $desktop = 'HKCU:\Control Panel\Desktop'
    $now = Get-ItemProperty $desktop -ErrorAction SilentlyContinue
    if ((Test-Path $file) -and $now.WallPaper -eq $file -and $now.WallpaperStyle -eq '10') { return Add-Result extras $name AlreadySet 'already set' }
    if ($WhatIfPreference) { return Add-Result extras $name WhatIf 'would set it on the desktop and the lock / sign-in screen' }

    try {
        New-Item -ItemType Directory -Path (Split-Path $file) -Force | Out-Null
        Add-Type -AssemblyName System.Drawing
        $bmp = New-Object System.Drawing.Bitmap 1920, 1080
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Black)
        $g.Dispose()
        $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()

        # Fill and a black desktop colour, so no screen shape leaves a coloured edge.
        foreach ($v in 'WallpaperStyle', 'TileWallpaper', 'WallPaper') { Save-Undo -Key $desktop -Value $v -Label $name }
        Save-Undo -Key 'HKCU:\Control Panel\Colors' -Value 'Background' -Label $name
        Set-ItemProperty $desktop -Name WallpaperStyle -Value '10'
        Set-ItemProperty $desktop -Name TileWallpaper -Value '0'
        Set-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -Value '0 0 0'
        Set-DesktopPicture -Path $file -Colour '0 0 0'

        # Lock screen: Windows' own lock screen API.
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
        $null = [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
        $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
        $awaitFile = ($asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1).MakeGenericMethod([Windows.Storage.StorageFile])
        $awaitAction = $asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
        $picture = $awaitFile.Invoke($null, @([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)))
        $picture.Wait()
        $awaitAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($picture.Result))).Wait()

        Add-Result extras $name Changed 'set on the desktop and the lock / sign-in screen'
    }
    catch {
        $msg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
        Add-Result extras $name Failed $msg
    }
}


# === 7. Clean-up =============================================================

# Deletes old versions of Windows components that updates replaced. Windows
# does this itself once they are 30 days old. No /ResetBase, so installed
# updates can still be uninstalled.
function Invoke-ComponentCleanup {
    $name = 'Clean up old update files'
    if ($WhatIfPreference) { return Add-Result cleanup $name WhatIf 'would run DISM /Online /Cleanup-Image /StartComponentCleanup' }
    # DISM refuses while a restart is pending (an update, or Recall removed in this run).
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        return Add-Result cleanup $name Skipped 'Windows is waiting for a restart. Restart, then run Setup again.' 'restart pending'
    }

    $drive = $env:SystemDrive.TrimEnd(':')
    $freeBefore = (Get-PSDrive $drive).Free
    Write-Log "${name}: running DISM, this can take 10 minutes or more..."
    # In this window, so DISM's progress bar shows. DISM keeps its own log.
    $exit = (Start-Process dism.exe -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup' -NoNewWindow -Wait -PassThru).ExitCode
    $freed = [math]::Round(((Get-PSDrive $drive).Free - $freeBefore) / 1GB, 1)

    if ($exit -notin 0, 3010) { Add-Result cleanup $name Failed "DISM exit $exit, see $env:windir\Logs\DISM\dism.log" }
    elseif ($freed -ge 0.1) { Add-Result cleanup $name Changed "done, about $freed GB freed" }
    else { Add-Result cleanup $name AlreadySet 'done, nothing to clear' }
}


# === -Restore ================================================================

# Puts one value back as Save-Undo found it, and removes the keys Setup created
# for it once they are empty. Returns $true when it changed something.
function Restore-RegValue {
    param([Parameter(Mandatory)]$Undo)
    $label, $name = $Undo.Label, "$($Undo.Value)"
    $valueName = if ($name) { $name } else { '(default)' }
    try {
        $key = if (Test-Path -LiteralPath $Undo.Key) { Get-Item -LiteralPath $Undo.Key }
        $isSet = $key -and ($key.GetValueNames() -contains $name)
        if ($Undo.Existed) {
            $now = if ($isSet) { $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames') }
            $same = $isSet -and (ConvertTo-Json @($now) -Compress) -eq (ConvertTo-Json @($Undo.Data) -Compress)
            $shown = if ("$($Undo.Data)".Length -gt 50) { "$("$($Undo.Data)".Substring(0, 47))..." } else { "'$($Undo.Data)'" }
            $would = $done = "put $valueName back to $shown"
        }
        else {
            $same = -not $isSet
            $would, $done = "remove $valueName, it was not set before", "removed $valueName, it was not set before"
        }
        if ($same) { return Add-Result restore $label AlreadySet "$valueName is already as it was" }
        if ($WhatIfPreference) { return Add-Result restore $label WhatIf "would $would" }

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
            # .NET, because PowerShell cannot delete a (default) value.
            $hive, $subKey = $key.Name -split '\\', 2
            $root = if ($hive -eq 'HKEY_LOCAL_MACHINE') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
            $writable = $root.OpenSubKey($subKey, $true)
            try { $writable.DeleteValue($name) } finally { $writable.Close() }
            # Some keys work just by existing (the F1 one), so they go too.
            $path = $Undo.Key
            while ($Undo.Created -and (Test-Path -LiteralPath $path)) {
                $k = Get-Item -LiteralPath $path
                if ($k.ValueCount -or $k.SubKeyCount) { break }
                Remove-Item -LiteralPath $path -Force -ErrorAction Stop
                if ($path -eq $Undo.Created) { break }
                $path = Split-Path $path
            }
        }
        Add-Result restore $label Changed $done
        $true
    }
    catch { Add-Result restore $label Failed $_.Exception.Message }
}

# Puts back every value earlier runs changed: newest run first, last change
# first. Policies and values for the whole PC only when they are in $Allowed
# (the data files and Setup's own), so a log someone edited cannot change them
# through this admin run. Other values of this account the account can change
# itself. A run that put everything back gets a "Restored" line, so it is not
# used twice. Returns $true when something changed.
function Restore-Settings {
    param([Parameter(Mandatory)][string[]]$Allowed)
    $runs = @(foreach ($log in Get-SetupLog) {
            if (Select-String -LiteralPath $log.FullName -Pattern '^Restored\t' -Quiet) { continue }
            $undo = @(Read-LogData $log 'Undo')
            if ($undo) { [pscustomobject]@{ Log = $log; Undo = $undo } }
        })
    if (-not $runs) {
        Write-Log 'Nothing to put back. Runs before -Restore existed did not record old values; use the restore point for those.' -Level Skip
        return $false
    }
    foreach ($run in $runs) { Write-Log "Run of $($run.Log.Date.ToString('d MMM yyyy HH:mm')): $($run.Undo.Count) setting(s)" }
    $total = ($runs | ForEach-Object { $_.Undo.Count } | Measure-Object -Sum).Sum
    if (-not $WhatIfPreference -and -not (Read-YesNo "Put these $total setting(s) back the way they were?")) {
        Write-Log 'Nothing put back.' -Level Skip
        return $false
    }

    $changed = $wallpaper = $false
    foreach ($run in $runs) {
        $failedBefore = @($script:Results | Where-Object Status -eq 'Failed').Count
        for ($i = $run.Undo.Count - 1; $i -ge 0; $i--) {
            $u = $run.Undo[$i]
            if ($u.Key -eq $script:StuckRects) {
                Set-TaskbarAutoHide -Name $u.Label -Step restore -On ($u.Existed -and @($u.Data).Count -gt 8 -and [bool](@($u.Data)[8] -band 1))
                continue
            }
            if ("$($u.Key)" -match '^HKLM:|\\Policies\\' -and "$($u.Key)|$($u.Value)" -notin $Allowed) {
                Add-Result restore $u.Label Skipped "left alone, $($u.Key) $($u.Value) is not in Setup's lists (any more)" -Warn
                continue
            }
            if (Restore-RegValue $u) {
                $changed = $true
                if ($u.Value -eq 'WallPaper') { $wallpaper = $true }
            }
        }
        # Can fail when Documents is blocked; then the next -Restore finds its values already back.
        $failed = @($script:Results | Where-Object Status -eq 'Failed').Count -gt $failedBefore
        if (-not $failed -and -not $WhatIfPreference) {
            "Restored`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $run.Log.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
    if ($wallpaper) {
        try { Set-DesktopPicture (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper (Get-ItemProperty 'HKCU:\Control Panel\Colors').Background }
        catch { Write-Log "Desktop picture: $($_.Exception.Message). It shows after signing out and in." -Level Warn }
        Write-Log 'The lock screen stays black. Pick another picture in Settings > Personalization > Lock screen.' -Level Warn
    }
    $changed
}
