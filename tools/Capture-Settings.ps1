<#
.SYNOPSIS
    Captures settings from a machine you already configured by hand, into this repo.

.DESCRIPTION
    The reliable way to add something to this repo is to set it up once by hand,
    then export it -- not to copy a registry path out of a blog post. This script
    does the export.

.EXAMPLE
    .\tools\Capture-Settings.ps1 -RegKey 'HKCU:\Software\HWiNFO64'
    Writes data\reg\HKCU-Software-HWiNFO64.reg

.EXAMPLE
    .\tools\Capture-Settings.ps1 -File 'C:\Program Files\HWiNFO64\HWiNFO64.INI'
    Copies it to data\config\ and prints the entry to paste into data\files.psd1

.EXAMPLE
    .\tools\Capture-Settings.ps1 -ScheduledTask 'HWiNFO sensors'
    Writes data\tasks\HWiNFO sensors.xml, ready to be registered on the next machine.

.EXAMPLE
    .\tools\Capture-Settings.ps1 -InstalledApps
    Lists what winget knows is installed, as ready-made data\apps.psd1 lines.
#>
[CmdletBinding()]
param(
    [string]$RegKey,
    [string]$File,
    [string]$ScheduledTask,
    [switch]$InstalledApps
)

$RepoRoot = Split-Path $PSScriptRoot -Parent

if ($RegKey) {
    $dir = Join-Path $RepoRoot 'data\reg'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir -Force | Out-Null }

    # reg.exe wants HKEY_CURRENT_USER\..., not the HKCU:\... PowerShell form.
    $native = $RegKey -replace '^HKCU:?\\', 'HKEY_CURRENT_USER\' `
                      -replace '^HKLM:?\\', 'HKEY_LOCAL_MACHINE\' `
                      -replace '^HKCR:?\\', 'HKEY_CLASSES_ROOT\'
    $safe = ($RegKey -replace '[:\\]', '-' -replace '-+', '-').Trim('-')
    $out = Join-Path $dir "$safe.reg"

    & reg.exe export $native $out /y | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Exported to $out" -ForegroundColor Green
        Write-Host 'Open it and delete everything you did not actually change -- a raw export'
        Write-Host 'carries window positions and timestamps you do not want to force onto another machine.'
    }
    else {
        Write-Host "reg export failed for $native" -ForegroundColor Red
    }
}

if ($File) {
    if (-not (Test-Path $File)) { Write-Host "Not found: $File" -ForegroundColor Red; return }
    $dir = Join-Path $RepoRoot 'data\config'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir -Force | Out-Null }

    $name = Split-Path $File -Leaf
    Copy-Item $File (Join-Path $dir $name) -Force
    Write-Host "Copied to data\config\$name" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Add this to data\files.psd1 -> Files:'
    Write-Host ''
    Write-Host "        @{"
    Write-Host "            Name        = '$([IO.Path]::GetFileNameWithoutExtension($name)) settings'"
    Write-Host "            Source      = '$name'"
    Write-Host "            Destination = '$File'"
    Write-Host "            OnlyIf      = '$(Split-Path $File -Parent)'"
    Write-Host "            Overwrite   = `$true"
    Write-Host "            Tags        = @('personal')"
    Write-Host "        }"
    Write-Host ''
    Write-Host 'Check it for anything machine-specific (licence keys, paths, hardware IDs) before committing.' -ForegroundColor Yellow
}

if ($ScheduledTask) {
    $dir = Join-Path $RepoRoot 'data\tasks'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir -Force | Out-Null }

    $task = Get-ScheduledTask -TaskName $ScheduledTask -ErrorAction SilentlyContinue
    if (-not $task) { Write-Host "No scheduled task named '$ScheduledTask'" -ForegroundColor Red; return }

    $out = Join-Path $dir "$ScheduledTask.xml"
    Export-ScheduledTask -TaskName $ScheduledTask | Set-Content $out -Encoding Unicode
    Write-Host "Exported to $out" -ForegroundColor Green
    Write-Host 'The XML has a <UserId> in it. Replace it with the well-known SID S-1-5-32-544'
    Write-Host '(local Administrators) so the task also registers on someone else"s machine.' -ForegroundColor Yellow
}

if ($InstalledApps) {
    Write-Host 'Reading installed packages from winget...' -ForegroundColor Gray
    $tmp = Join-Path $env:TEMP "winget-export-$PID.json"
    & winget export --output $tmp --accept-source-agreements --nowarn 2>&1 | Out-Null

    if (-not (Test-Path $tmp)) { Write-Host 'winget export produced nothing.' -ForegroundColor Red; return }

    $json = Get-Content $tmp -Raw | ConvertFrom-Json
    Remove-Item $tmp -Force

    $known = (Import-PowerShellDataFile (Join-Path $RepoRoot 'data\apps.psd1')).Apps.Id

    Write-Host ''
    Write-Host 'Lines for data\apps.psd1 (already-listed apps are marked):'
    Write-Host ''
    foreach ($src in $json.Sources) {
        foreach ($p in $src.Packages) {
            $mark = if ($known -contains $p.PackageIdentifier) { '# already listed: ' } else { '' }
            Write-Host ("        {0}@{{ Id = '{1}'; Name = '{1}'; Tags = @('personal') }}" -f $mark, $p.PackageIdentifier)
        }
    }
    Write-Host ''
    Write-Host 'Fix up the Name and Tags by hand. Do not paste the whole list in --' -ForegroundColor Yellow
    Write-Host 'it includes things you installed once and never used.' -ForegroundColor Yellow
}

if (-not ($RegKey -or $File -or $ScheduledTask -or $InstalledApps)) {
    Get-Help $PSCommandPath -Detailed
}
