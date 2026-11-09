param(
    [string[]]$Tags = @('core'),
    [string]$RepoRoot
)

Write-Log 'Registry tweaks' -Level Step

$build = [Environment]::OSVersion.Version.Build
Write-Log "Windows build $build. Keys move between Windows 11 releases; if one has no effect, re-capture it."

$data = Import-PowerShellDataFile (Join-Path $RepoRoot 'data\tweaks.psd1')
$selected = @($data.Tweaks | Where-Object { $_.Tags | Where-Object { $Tags -contains $_ } })

if (-not $selected) {
    Write-Log "No tweaks match tags: $($Tags -join ', ')" -Level Warn
    return
}

$isAdmin = Test-IsAdmin
$needExplorerRestart = $false

foreach ($t in $selected) {
    if ($t.Scope -eq 'Machine' -and -not $isAdmin) {
        Write-Log "$($t.Name) -- needs admin, re-run elevated" -Level Warn
        Add-Result -Area 'registry' -Name $t.Name -Status Skipped -Detail 'needs admin'
        continue
    }

    Set-RegValue -Path $t.Path -Name $t.ValueName -Value $t.Value -Type $t.Type -Label $t.Name -Area 'registry'

    if ($t.Explorer -and (Get-LastResult).Status -eq 'Changed') { $needExplorerRestart = $true }
}

if ($needExplorerRestart) {
    Write-Log 'Some changes need Explorer to restart.' -Level Warn
    Request-ExplorerRestart
}
