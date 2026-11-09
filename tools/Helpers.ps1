# The functions Setup.ps1 uses. Setup.ps1 dot-sources this file, so everything
# here runs inside Setup.ps1 and sees its -WhatIf.
#
# Every function checks the current state first and does nothing when it is
# already right. Under -WhatIf they say what they would do and change nothing.

$script:Results = [System.Collections.Generic.List[object]]::new()
$script:LogPath = $null

# Load the Store-app and Windows-feature modules now, with -WhatIf switched off
# just for this: loading them under -WhatIf prints a screen of "What if: Set
# Alias" lines from their own setup code. Modules read the global setting.
$whatIf = $global:WhatIfPreference
$global:WhatIfPreference = $false
Import-Module Appx, Dism -Global -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$global:WhatIfPreference = $whatIf


# === Logging and the summary =================================================

function Start-Log {
    param([Parameter(Mandatory)][string]$Path)
    $script:LogPath = $Path
    New-Item -ItemType Directory -Path (Split-Path $Path) -Force -WhatIf:$false | Out-Null
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

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


# === 1. Installing ===========================================================

# Shows every app as a numbered list, grouped, and returns the ones picked.
# $Choice skips the menu. It takes the same input as the menu: 'all', 'none',
# group names, numbers, and ranges like 20-25.
function Select-Apps {
    param([Parameter(Mandatory)][object[]]$Apps, [string[]]$Choice)

    $interactive = -not $Choice
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

    if ($interactive -and $result) {
        Write-Host ''
        Write-Host "  $($result.Count) app(s): $($result.Name -join ', ')"
        if ((Read-Host '  Go ahead? [Y/n]') -match '^[nN]') { return }
    }
    $result
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

# Asks before installing an app marked Ask = $true in apps.psd1.
function Confirm-Install {
    param([Parameter(Mandatory)][string]$Name)
    if ((Read-Host "  Install $Name now? [y/N]") -match '^[yY]') { return $true }
    Write-Log "$Name -- not installed, you said no" -Level Skip
    Add-Result -Step 'apps' -Name $Name -Status Skipped -Detail 'declined'
    $false
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string]$Source = 'winget',
        [switch]$Ask
    )

    $listed = & winget list --id $Id --exact --source $Source --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed -join "`n") -match [regex]::Escape($Id)) {
        Write-Log "$Name -- already installed" -Level Skip
        Add-Result -Step 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would install$(if ($Ask) { ' (asks first)' })"
        Add-Result -Step 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }
    if ($Ask -and -not (Confirm-Install $Name)) { return }

    Write-Log "$Name -- installing..."
    $out = & winget install --id $Id --exact --silent --source $Source `
        --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    if ($script:LogPath) { $out | Add-Content $script:LogPath -Encoding UTF8 -WhatIf:$false }

    # These two codes mean "already installed / nothing newer"; both are fine.
    if ($LASTEXITCODE -in 0, -1978335189, -1978335135) {
        Write-Log $Name -Level Ok
        Add-Result -Step 'apps' -Name $Name -Status Changed
    }
    else {
        Write-Log "$Name -- winget exit $LASTEXITCODE (see log)" -Level Fail
        Add-Result -Step 'apps' -Name $Name -Status Failed -Detail "winget exit $LASTEXITCODE"
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
        [string]$Arguments = '',
        [switch]$Ask
    )

    if (Get-InstalledProgram $Detect) {
        Write-Log "$Name -- already installed" -Level Skip
        Add-Result -Step 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would download and install$(if ($Ask) { ' (asks first)' })"
        Add-Result -Step 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }
    if ($Ask -and -not (Confirm-Install $Name)) { return }

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


# === 2. Removing =============================================================

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
# has no way to install anything back. The Xbox and gaming parts stay too.
# Packages Windows marks NonRemovable (Start, taskbar, Explorer...) are refused
# in Remove-StoreApp below.
$script:ProtectedPackages = @(
    'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsStore', 'Microsoft.SecHealthUI'
    'Microsoft.UI.Xaml*', 'Microsoft.VCLibs*', 'Microsoft.NET*', 'Microsoft.WindowsAppRuntime*'
    'Microsoft.Windows.Photos', 'Microsoft.WindowsNotepad', 'Microsoft.WindowsTerminal', 'Microsoft.Paint'
    'Microsoft.Xbox*', 'Microsoft.GamingApp', 'Microsoft.GamingServices', 'Microsoft.Edge.GameAssist'
)

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

# Store apps: removed for every user on the PC, and deprovisioned.
# Anything removed here can be reinstalled from the Store.
function Remove-StoreApp {
    param([Parameter(Mandatory)][string]$Package, [Parameter(Mandatory)][string]$Name)

    if ($script:ProtectedPackages | Where-Object { $Package -like $_ }) {
        Write-Log "$Name -- refused, '$Package' is on the protected list" -Level Warn
        Add-Result -Step 'remove' -Name $Name -Status Skipped -Detail 'protected'
        return
    }

    $admin = Test-IsAdmin
    # With admin rights this also lists apps that are only "staged" (Windows'
    # copy, waiting for new users). Count an app as installed only where an
    # account really has it.
    $installed = @(Get-AppxPackage -AllUsers:$admin -Name $Package -ErrorAction SilentlyContinue |
        Where-Object { -not $admin -or ($_.PackageUserInformation | Where-Object { "$($_.InstallState)" -eq 'Installed' }) })
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


# === 3. Registry settings ====================================================

# Writes one registry value, only if it differs from what is there.
# Returns $true when it changed something.
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Key,
        [string]$Value = '',
        [Parameter(Mandatory)][AllowEmptyString()]$Data,
        [string]$Type = 'DWord',
        [Parameter(Mandatory)][string]$Label
    )

    # An empty value name means the key's (default) value, and '(default)' is
    # what New-ItemProperty calls it -- it refuses an empty name.
    $valueName = if ($Value) { $Value } else { '(default)' }

    try {
        $current = $null
        if (Test-Path -LiteralPath $Key) { $current = (Get-Item -LiteralPath $Key).GetValue($Value) }
        $was = if ($null -eq $current) { 'not set' } else { "'$current'" }

        if ($null -ne $current -and "$current" -eq "$Data") {
            Write-Log "$Label -- already $valueName=$Data" -Level Skip
            Add-Result -Step 'settings' -Name $Label -Status AlreadySet
            return
        }
        if ($WhatIfPreference) {
            Write-Log "$Label -- would set $valueName=$Data (now $was)"
            Add-Result -Step 'settings' -Name $Label -Status Skipped -Detail 'WhatIf'
            return
        }

        if (-not (Test-Path -LiteralPath $Key)) { New-Item -Path $Key -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $Key -Name $valueName -Value $Data -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Log "$Label -- set $valueName=$Data (was $was)" -Level Ok
        Add-Result -Step 'settings' -Name $Label -Status Changed -Detail "was $was"
        return $true
    }
    catch {
        Write-Log "$Label -- $($_.Exception.Message)" -Level Fail
        Add-Result -Step 'settings' -Name $Label -Status Failed -Detail $_.Exception.Message
    }
}
