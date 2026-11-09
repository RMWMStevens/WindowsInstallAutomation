param(
    [string[]]$Tags = @('core'),
    [string]$RepoRoot
)

Write-Log 'Application config' -Level Step

# --- 1. captured registry exports -------------------------------------------
# Anything dropped in data\reg\ is imported as-is. Capture these from a machine
# you already configured by hand; do not write them from scratch.
$regDir = Join-Path $RepoRoot 'data\reg'
if (Test-Path $regDir) {
    foreach ($reg in Get-ChildItem $regDir -Filter *.reg -ErrorAction SilentlyContinue) {
        if ($WhatIfPreference) {
            Write-Log "$($reg.Name) -- would import" -Level Info
            Add-Result -Area 'config' -Name $reg.Name -Status Skipped -Detail 'WhatIf'
            continue
        }
        $out = & reg.exe import $reg.FullName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$($reg.Name) -- imported" -Level Ok
            Add-Result -Area 'config' -Name $reg.Name -Status Changed
        }
        else {
            Write-Log "$($reg.Name) -- $out" -Level Fail
            Add-Result -Area 'config' -Name $reg.Name -Status Failed -Detail "$out"
        }
    }
}

# --- 2. config files ---------------------------------------------------------
$data = Import-PowerShellDataFile (Join-Path $RepoRoot 'data\files.psd1')
$selected = @($data.Files | Where-Object { $_.Tags | Where-Object { $Tags -contains $_ } })

foreach ($f in $selected) {
    $src = Join-Path $RepoRoot "data\config\$($f.Source)"
    $dst = [Environment]::ExpandEnvironmentVariables($f.Destination)

    if (-not (Test-Path $src)) {
        Write-Log "$($f.Name) -- source missing: $src" -Level Fail
        Add-Result -Area 'config' -Name $f.Name -Status Failed -Detail 'source missing'
        continue
    }
    if ($f.OnlyIf -and -not (Test-Path ([Environment]::ExpandEnvironmentVariables($f.OnlyIf)))) {
        Write-Log "$($f.Name) -- target app not installed" -Level Skip
        Add-Result -Area 'config' -Name $f.Name -Status Skipped -Detail 'app not installed'
        continue
    }
    if ((Test-Path $dst) -and -not $f.Overwrite) {
        Write-Log "$($f.Name) -- already exists, left alone" -Level Skip
        Add-Result -Area 'config' -Name $f.Name -Status AlreadySet
        continue
    }
    if ($WhatIfPreference) {
        Write-Log "$($f.Name) -- would copy to $dst" -Level Info
        Add-Result -Area 'config' -Name $f.Name -Status Skipped -Detail 'WhatIf'
        continue
    }

    try {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        if (Test-Path $dst) { Copy-Item $dst "$dst.bak" -Force }
        Copy-Item $src $dst -Force -ErrorAction Stop
        Write-Log "$($f.Name) -> $dst" -Level Ok
        Add-Result -Area 'config' -Name $f.Name -Status Changed
    }
    catch {
        Write-Log "$($f.Name) -- $($_.Exception.Message)" -Level Fail
        Add-Result -Area 'config' -Name $f.Name -Status Failed -Detail $_.Exception.Message
    }
}

# --- 3. scheduled tasks ------------------------------------------------------
# This is how an app autostarts with admin rights without a UAC prompt on every
# login. Build the task once in Task Scheduler, export it to XML, drop it here.
$taskDir = Join-Path $RepoRoot 'data\tasks'
if (Test-Path $taskDir) {
    foreach ($xml in Get-ChildItem $taskDir -Filter *.xml -ErrorAction SilentlyContinue) {
        $taskName = $xml.BaseName

        if (-not (Test-IsAdmin)) {
            Write-Log "$taskName -- needs admin to register" -Level Warn
            Add-Result -Area 'config' -Name "task: $taskName" -Status Skipped -Detail 'needs admin'
            continue
        }
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Write-Log "$taskName -- task already registered" -Level Skip
            Add-Result -Area 'config' -Name "task: $taskName" -Status AlreadySet
            continue
        }
        if ($WhatIfPreference) {
            Write-Log "$taskName -- would register scheduled task" -Level Info
            Add-Result -Area 'config' -Name "task: $taskName" -Status Skipped -Detail 'WhatIf'
            continue
        }

        try {
            Register-ScheduledTask -TaskName $taskName -Xml (Get-Content $xml.FullName -Raw) -Force -ErrorAction Stop | Out-Null
            Write-Log "$taskName -- registered" -Level Ok
            Add-Result -Area 'config' -Name "task: $taskName" -Status Changed
        }
        catch {
            Write-Log "$taskName -- $($_.Exception.Message)" -Level Fail
            Add-Result -Area 'config' -Name "task: $taskName" -Status Failed -Detail $_.Exception.Message
        }
    }
}
