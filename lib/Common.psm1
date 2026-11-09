# Shared helpers for every module.
#
# This is a .psm1 on purpose. The run state below ($script:Results, the log path)
# has to stay the same object for the modules under modules\, which Setup.ps1
# invokes with & and which therefore get their own script scope. Inside a real
# module, $script: means the module's own scope for every function in it, no
# matter who calls them. Dot-sourcing a .ps1 does not give that.

$script:Results = [System.Collections.Generic.List[object]]::new()
$script:LogPath = $null

function Start-SetupLog {
    param([string]$Path)
    $script:LogPath = $Path
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force -WhatIf:$false | Out-Null }
    "=== WindowsInstallAutomation run $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Set-Content $Path -Encoding utf8 -WhatIf:$false
    "OS build: $([Environment]::OSVersion.Version) / $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion)" | Add-Content $Path -Encoding utf8 -WhatIf:$false
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
    if ($Level -eq 'Step') {
        Write-Host ''
        Write-Host "== $Message" -ForegroundColor $colour
    }
    else {
        Write-Host "$prefix$Message" -ForegroundColor $colour
    }
    if ($script:LogPath) { "$Level`t$Message" | Add-Content $script:LogPath -Encoding utf8 -WhatIf:$false }
}

function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Area,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Changed', 'AlreadySet', 'Skipped', 'Failed')][string]$Status,
        [string]$Detail = ''
    )
    $script:Results.Add([pscustomobject]@{
            Area   = $Area
            Name   = $Name
            Status = $Status
            Detail = $Detail
        })
}

function Get-LastResult {
    if ($script:Results.Count -eq 0) { return $null }
    $script:Results[$script:Results.Count - 1]
}

function Request-ExplorerRestart { $script:RestartExplorerWanted = $true }
function Test-ExplorerRestartWanted { [bool]$script:RestartExplorerWanted }

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Writes a registry value only when it differs from what is already there.
# Returns nothing; records the outcome so the final summary can show it.
function Set-RegValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Name,
        [Parameter(Mandatory)][AllowEmptyString()]$Value,
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'DWord',
        [string]$Label,
        [string]$Area = 'registry'
    )

    if (-not $Label) { $Label = "$Path\$Name" }
    # An empty Name means the key's (Default) value.
    $valueName = if ([string]::IsNullOrEmpty($Name)) { '(default)' } else { $Name }

    try {
        $existing = $null
        if (Test-Path $Path) {
            $key = Get-Item -LiteralPath $Path
            $existing = if ([string]::IsNullOrEmpty($Name)) { $key.GetValue('') } else { $key.GetValue($Name) }
        }

        $was = if ($null -eq $existing) { 'not set' } else { "'$existing'" }

        if ($null -ne $existing -and "$existing" -eq "$Value") {
            Write-Log "$Label -- already $valueName=$Value" -Level Skip
            Add-Result -Area $Area -Name $Label -Status AlreadySet
            return
        }

        if ($WhatIfPreference) {
            Write-Log "$Label -- would set $valueName=$Value (currently $was)" -Level Info
            Add-Result -Area $Area -Name $Label -Status Skipped -Detail 'WhatIf'
            return
        }

        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        # $valueName, not $Name: New-ItemProperty rejects an empty -Name, and
        # '(default)' is how the registry provider addresses the default value.
        New-ItemProperty -Path $Path -Name $valueName -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null

        Write-Log "$Label -- set $valueName=$Value (was $was)" -Level Ok
        Add-Result -Area $Area -Name $Label -Status Changed -Detail "was $was"
    }
    catch {
        Write-Log "$Label -- $($_.Exception.Message)" -Level Fail
        Add-Result -Area $Area -Name $Label -Status Failed -Detail $_.Exception.Message
    }
}

function Test-WingetPresent {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try { $null = & winget --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false }
}

# Installs one winget package, skipping it when it is already there.
function Install-App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string]$Source = 'winget',
        [string[]]$ExtraArgs = @()
    )

    $listed = & winget list --id $Id --exact --source $Source --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed -join "`n") -match [regex]::Escape($Id)) {
        Write-Log "$Name ($Id)" -Level Skip
        Add-Result -Area 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name ($Id) -- would install" -Level Info
        Add-Result -Area 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    Write-Log "$Name ($Id) -- installing..." -Level Info
    $wgArgs = @(
        'install', '--id', $Id, '--exact', '--silent',
        '--source', $Source,
        '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    ) + $ExtraArgs

    & winget @wgArgs 2>&1 | Out-String | ForEach-Object { if ($script:LogPath) { $_ | Add-Content $script:LogPath -Encoding utf8 -WhatIf:$false } }

    # winget returns a 0x8A15.... code for "no applicable upgrade / already installed"; treat those as fine.
    if ($LASTEXITCODE -eq 0) {
        Write-Log "$Name" -Level Ok
        Add-Result -Area 'apps' -Name $Name -Status Changed
    }
    elseif ($LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335135) {
        Write-Log "$Name -- already current" -Level Skip
        Add-Result -Area 'apps' -Name $Name -Status AlreadySet
    }
    else {
        Write-Log "$Name -- winget exit $LASTEXITCODE (see log)" -Level Fail
        Add-Result -Area 'apps' -Name $Name -Status Failed -Detail "winget exit $LASTEXITCODE"
    }
}

# Programs listed in Settings > Apps, matched on DisplayName (wildcards ok).
function Get-ArpEntry {
    param([Parameter(Mandatory)][string]$DisplayName)
    $roots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    @(Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.DisplayName -like $DisplayName })
}

# Installs an app winget cannot handle: downloads the installer, refuses it
# unless it carries a valid signature from the expected publisher, runs it.
function Install-DirectApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Signer,
        [Parameter(Mandatory)][string]$Detect,
        [string]$Arguments = ''
    )

    if (Get-ArpEntry -DisplayName $Detect) {
        Write-Log "$Name (direct download)" -Level Skip
        Add-Result -Area 'apps' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would download $Url and install" -Level Info
        Add-Result -Area 'apps' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    $dir = Join-Path $env:TEMP 'WindowsInstallAutomation'
    $file = Join-Path $dir ([IO.Path]::GetFileName(([uri]$Url).AbsolutePath))
    try {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        Write-Log "$Name -- downloading $Url" -Level Info
        $prevProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'   # the progress bar makes 5.1 downloads crawl
        try { Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing -ErrorAction Stop }
        finally { $ProgressPreference = $prevProgress }

        $sig = Get-AuthenticodeSignature -FilePath $file
        $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { 'unsigned' }
        if ($sig.Status -ne 'Valid' -or $subject -notmatch "(^|, )O=$([regex]::Escape($Signer))(,|$)") {
            throw "signature check failed: $($sig.Status), $subject"
        }

        Write-Log "$Name -- installing..." -Level Info
        $proc = @{ FilePath = $file; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
        if ($Arguments) { $proc.ArgumentList = $Arguments }
        $p = Start-Process @proc
        if ($p.ExitCode -ne 0) { throw "installer exit $($p.ExitCode)" }

        Write-Log "$Name" -Level Ok
        Add-Result -Area 'apps' -Name $Name -Status Changed
    }
    catch {
        Write-Log "$Name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Area 'apps' -Name $Name -Status Failed -Detail $_.Exception.Message
    }
    finally {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
}

# Uninstalls a desktop program through its own uninstall entry. MSI packages
# are run with /qn; anything else runs its QuietUninstallString when it has one.
function Remove-Win32App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$StopProcess = @()
    )

    $entries = @(Get-ArpEntry -DisplayName $DisplayName |
        Where-Object { $_.QuietUninstallString -or $_.UninstallString })
    if (-not $entries) {
        Write-Log "$Name -- not present" -Level Skip
        Add-Result -Area 'debloat' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would uninstall ($(($entries.DisplayName | Sort-Object -Unique) -join ', '))" -Level Info
        Add-Result -Area 'debloat' -Name $Name -Status Skipped -Detail 'WhatIf'
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
        else {
            $errors += "$($e.DisplayName): cannot parse '$cmd'"
            continue
        }

        try {
            $proc = @{ FilePath = $exe; Wait = $true; PassThru = $true; ErrorAction = 'Stop' }
            if ($arg.Trim()) { $proc.ArgumentList = $arg.Trim() }
            $p = Start-Process @proc
            # 3010 = removed, reboot pending. 1605 = MSI says it is already gone.
            if ($p.ExitCode -notin 0, 3010, 1605) { $errors += "$($e.DisplayName): exit $($p.ExitCode)" }
        }
        catch { $errors += "$($e.DisplayName): $($_.Exception.Message)" }
    }

    if ($errors) {
        Write-Log "$Name -- $($errors -join '; ')" -Level Fail
        Add-Result -Area 'debloat' -Name $Name -Status Failed -Detail ($errors -join '; ')
    }
    else {
        Write-Log "$Name -- removed" -Level Ok
        Add-Result -Area 'debloat' -Name $Name -Status Changed
    }
}

function Remove-AppxApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Name
    )

    $pkgs = Get-AppxPackage -Name $Pattern -ErrorAction SilentlyContinue
    if (-not $pkgs) {
        Write-Log "$Name -- not present" -Level Skip
        Add-Result -Area 'debloat' -Name $Name -Status AlreadySet
        return
    }

    if ($WhatIfPreference) {
        Write-Log "$Name -- would remove" -Level Info
        Add-Result -Area 'debloat' -Name $Name -Status Skipped -Detail 'WhatIf'
        return
    }

    try {
        $pkgs | Remove-AppxPackage -ErrorAction Stop
        Write-Log "$Name -- removed" -Level Ok
        Add-Result -Area 'debloat' -Name $Name -Status Changed
    }
    catch {
        Write-Log "$Name -- $($_.Exception.Message)" -Level Fail
        Add-Result -Area 'debloat' -Name $Name -Status Failed -Detail $_.Exception.Message
    }
}

function Get-FailureCount {
    @($script:Results | Where-Object Status -eq 'Failed').Count
}

function Show-Summary {
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor Cyan
    Write-Host ' Summary' -ForegroundColor Cyan
    Write-Host ('=' * 62) -ForegroundColor Cyan

    if ($script:Results.Count -eq 0) {
        Write-Host ' Nothing ran.' -ForegroundColor Yellow
        return
    }

    $script:Results | Group-Object Area | ForEach-Object {
        $counts = $_.Group | Group-Object Status | ForEach-Object { "$($_.Name)=$($_.Count)" }
        Write-Host (" {0,-10} {1}" -f $_.Name, ($counts -join '  '))
    }

    $failed = @($script:Results | Where-Object Status -eq 'Failed')
    if ($failed.Count) {
        Write-Host ''
        Write-Host " Failed ($($failed.Count)):" -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "   - $($_.Name): $($_.Detail)" -ForegroundColor Red }
    }

    $changed = @($script:Results | Where-Object Status -eq 'Changed').Count
    Write-Host ''
    Write-Host " $changed change(s) applied. Log: $script:LogPath"
}

Export-ModuleMember -Function *-*
