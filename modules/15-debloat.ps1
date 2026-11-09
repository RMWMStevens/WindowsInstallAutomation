param(
    [string[]]$Tags = @('core'),
    [string]$RepoRoot
)

Write-Log 'Remove pre-installed apps' -Level Step

# Import Appx explicitly. Autoloading it under -WhatIf prints a screen of
# "What if: Set Alias" noise from the module's own alias definitions.
# On PowerShell 7 the Appx cmdlets only work through the compatibility layer.
# Import-Module has no -WhatIf, so drop the preference around the call instead.
$prevWhatIf = $global:WhatIfPreference
$global:WhatIfPreference = $false
try {
    $appxArgs = @{ Name = 'Appx'; ErrorAction = 'SilentlyContinue' }
    if ($PSVersionTable.PSVersion.Major -ge 7) { $appxArgs.UseWindowsPowerShell = $true }
    Import-Module @appxArgs -WarningAction SilentlyContinue | Out-Null
}
finally { $global:WhatIfPreference = $prevWhatIf }

$haveAppx = [bool](Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)
if (-not $haveAppx) {
    Write-Log 'Appx cmdlets are not available -- Store apps will be skipped.' -Level Fail
    Add-Result -Area 'debloat' -Name 'Appx module' -Status Failed -Detail 'not available'
}

# Never remove these, whatever the data file says. Removing the first two in
# particular leaves a machine with no way to install anything back.
$protected = @(
    'Microsoft.DesktopAppInstaller'
    'Microsoft.WindowsStore'
    'Microsoft.SecHealthUI'
    'Microsoft.UI.Xaml*'
    'Microsoft.VCLibs*'
    'Microsoft.NET*'
    'Microsoft.WindowsAppRuntime*'
    'MicrosoftWindows.Client*'
    'Microsoft.Windows.Photos'
    'Microsoft.WindowsNotepad'
    'Microsoft.WindowsTerminal'
    'Microsoft.Paint'
)

# User folders (Desktop, Documents, ...) that OneDrive folder backup has moved
# into the OneDrive folder. Uninstalling OneDrive while any are listed leaves
# Explorer pointing at placeholders for files that may only be in the cloud.
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

    # Only the folders folder backup can move. The same key also holds OneDrive's
    # own folders ({24D89E24-...} etc.), which live inside OneDrive by definition.
    $folders = [ordered]@{
        'Desktop'                                = 'Desktop'
        'Personal'                               = 'Documents'
        'My Pictures'                            = 'Pictures'
        'My Music'                               = 'Music'
        'My Video'                               = 'Videos'
        '{374DE290-123F-4565-9164-39C4925E467B}' = 'Downloads'
    }
    foreach ($name in $folders.Keys) {
        $value = $shell.$name
        if (-not $value) { continue }
        $path = [Environment]::ExpandEnvironmentVariables([string]$value).TrimEnd('\')
        foreach ($r in $roots) {
            if ($path.Equals($r, [StringComparison]::OrdinalIgnoreCase) -or
                $path.StartsWith("$r\", [StringComparison]::OrdinalIgnoreCase)) {
                $folders[$name]
                break
            }
        }
    }
}

$data = Import-PowerShellDataFile (Join-Path $RepoRoot 'data\debloat.psd1')
$selected = @($data.Remove | Where-Object { $_.Tags | Where-Object { $Tags -contains $_ } })

if (-not $selected) {
    Write-Log "Nothing to remove for tags: $($Tags -join ', ')" -Level Warn
    return
}

foreach ($app in $selected) {
    if ($app.Guard -eq 'OneDriveFolders') {
        $held = @(Get-FoldersInOneDrive)
        if ($held) {
            $list = $held -join ', '
            Write-Log "$($app.Name) -- refused, these folders are backed up into OneDrive: $list. In OneDrive settings > Sync and backup > Manage back up, stop backing them up, then re-run." -Level Fail
            Add-Result -Area 'debloat' -Name $app.Name -Status Failed -Detail "folders still in OneDrive: $list"
            continue
        }
    }

    if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }

    if ($app.Feature) {
        Disable-OptionalFeature -Feature $app.Feature -Name $app.Name
        continue
    }

    if ($app.Uninstall) {
        $removeArgs = @{ DisplayName = $app.Uninstall; Name = $app.Name }
        if ($app.StopProcess) { $removeArgs.StopProcess = $app.StopProcess }
        Remove-Win32App @removeArgs
        continue
    }

    if (-not $haveAppx) {
        Add-Result -Area 'debloat' -Name $app.Name -Status Skipped -Detail 'Appx not available'
        continue
    }

    $blocked = $protected | Where-Object { $app.Pattern -like $_ }
    if ($blocked) {
        Write-Log "$($app.Name) -- refused, '$($app.Pattern)' is on the protected list" -Level Warn
        Add-Result -Area 'debloat' -Name $app.Name -Status Skipped -Detail 'protected'
        continue
    }

    Remove-AppxApp -Pattern $app.Pattern -Name $app.Name
}

Write-Log 'Store apps removed here can be reinstalled from the Microsoft Store.'
