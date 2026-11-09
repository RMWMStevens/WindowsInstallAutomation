<#
.SYNOPSIS
    Sets up a fresh Windows 11 install: apps, registry tweaks, app config.

.DESCRIPTION
    Safe to run more than once. Every step checks the current state first and
    only changes what is actually different, so a second run is nearly a no-op.

.PARAMETER Profile
    Which set of tags to apply. See $Profiles below.

.PARAMETER Tags
    Use tags directly instead of a profile.

.PARAMETER Only
    Run only these modules: apps, debloat, registry, config.

.PARAMETER Skip
    Skip these modules.

.EXAMPLE
    .\Setup.ps1 -Profile Mine -WhatIf
    Shows everything it would do, changes nothing. Always start here.

.EXAMPLE
    .\Setup.ps1 -Profile Friend

.EXAMPLE
    .\Setup.ps1 -Profile Mine -Only registry
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Mine', 'Friend', 'Minimal', 'MediaTools')]
    [string]$Profile = 'Mine',

    [string[]]$Tags,

    [ValidateSet('apps', 'debloat', 'registry', 'config')]
    [string[]]$Only,

    [ValidateSet('apps', 'debloat', 'registry', 'config')]
    [string[]]$Skip = @(),

    [switch]$NoElevate
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

# Tag sets per profile. 'nogaming' is what turns Xbox removal on.
# MediaTools is an add-on: it only installs the media tools, run it on its own.
$Profiles = @{
    Mine       = @('core', 'comms', 'media', 'personal', 'dev', 'gaming')
    Friend     = @('core', 'comms', 'media', 'nogaming')
    Minimal    = @('core')
    MediaTools = @('mediatools')
}

if (-not $Tags) { $Tags = $Profiles[$Profile] }

$modules = [ordered]@{
    apps     = '10-apps.ps1'
    debloat  = '15-debloat.ps1'
    registry = '20-registry.ps1'
    config   = '30-app-config.ps1'
}

$toRun = $modules.Keys | Where-Object {
    (-not $Only -or $Only -contains $_) -and ($Skip -notcontains $_)
}

Import-Module (Join-Path $RepoRoot 'lib\Common.psm1') -Force -Global

# Propagate -WhatIf into the helper functions, which all use ShouldProcess.
$global:WhatIfPreference = [bool]$WhatIfPreference

Start-SetupLog (Join-Path $RepoRoot "logs\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log")

Write-Host ''
Write-Host '  Windows setup' -ForegroundColor Cyan
Write-Host "  profile : $Profile" -ForegroundColor Gray
Write-Host "  tags    : $($Tags -join ', ')" -ForegroundColor Gray
Write-Host "  modules : $($toRun -join ', ')" -ForegroundColor Gray
if ($WhatIfPreference) { Write-Host '  DRY RUN -- nothing will be changed' -ForegroundColor Yellow }

# Windows 11 only. Not blocked, because it mostly still works on 10, but
# nothing here is tested or tuned for it.
if ([Environment]::OSVersion.Version.Build -lt 22000) {
    Write-Log 'This is Windows 10. The script is written for Windows 11 -- it will run, but untested, and some tweaks do nothing here.' -Level Warn
}

# --- elevation ---------------------------------------------------------------
if (-not (Test-IsAdmin) -and -not $NoElevate -and -not $WhatIfPreference) {
    Write-Log 'Not running as admin. Machine-wide tweaks and scheduled tasks will be skipped.' -Level Warn
    $answer = Read-Host '  Restart elevated? [Y/n]'
    if ($answer -notmatch '^[nN]') {
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
            '-Profile', $Profile, '-NoElevate')
        if ($Only) { $argList += @('-Only', ($Only -join ',')) }
        if ($Skip) { $argList += @('-Skip', ($Skip -join ',')) }
        Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList $argList
        return
    }
}

# --- run ---------------------------------------------------------------------
foreach ($key in $toRun) {
    $path = Join-Path $RepoRoot "modules\$($modules[$key])"
    if (-not (Test-Path $path)) {
        Write-Log "module missing: $path" -Level Fail
        continue
    }
    try {
        & $path -Tags $Tags -RepoRoot $RepoRoot
    }
    catch {
        Write-Log "module '$key' stopped: $($_.Exception.Message)" -Level Fail
        Add-Result -Area $key -Name 'module' -Status Failed -Detail $_.Exception.Message
    }
}

# --- finish ------------------------------------------------------------------
Show-Summary

if (Test-ExplorerRestartWanted -and -not $WhatIfPreference) {
    Write-Host ''
    $answer = Read-Host '  Restart Explorer now to apply the taskbar and Explorer changes? [Y/n]'
    if ($answer -notmatch '^[nN]') {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log 'Explorer restarted.' -Level Ok
    }
}

$manual = Join-Path $RepoRoot 'MANUAL.md'
if (Test-Path $manual) {
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor Yellow
    Write-Host ' Still to do by hand' -ForegroundColor Yellow
    Write-Host ('=' * 62) -ForegroundColor Yellow
    Get-Content $manual | Where-Object { $_ -match '^\s*- \[ \]' } | ForEach-Object {
        Write-Host "  $($_.Trim())"
    }
    Write-Host ''
    Write-Host " Full list: $manual"
}

$global:WhatIfPreference = $false

# Exit non-zero if anything failed, and never leak winget's exit code.
$failures = Get-FailureCount
exit ([int]($failures -gt 0))
