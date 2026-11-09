param(
    [string[]]$Tags = @('core'),
    [string]$RepoRoot
)

Write-Log 'Applications' -Level Step

if (-not (Test-WingetPresent)) {
    Write-Log 'winget is not available. Open the Microsoft Store, update "App Installer", then re-run.' -Level Fail
    Add-Result -Area 'apps' -Name 'winget' -Status Failed -Detail 'not installed'
    return
}

$data = Import-PowerShellDataFile (Join-Path $RepoRoot 'data\apps.psd1')
$selected = @($data.Apps | Where-Object { $_.Tags | Where-Object { $Tags -contains $_ } })

if (-not $selected) {
    Write-Log "No apps match tags: $($Tags -join ', ')" -Level Warn
    return
}

Write-Log "$($selected.Count) app(s) match tags: $($Tags -join ', ')"

foreach ($app in $selected) {
    if ($app.Note) { Write-Log "$($app.Name): $($app.Note)" -Level Warn }

    if ($app.Url) {
        $directArgs = @{ Name = $app.Name; Url = $app.Url; Signer = $app.Signer; Detect = $app.Detect }
        if ($app.Args) { $directArgs.Arguments = $app.Args.Replace('{data}', (Join-Path $RepoRoot 'data')) }
        Install-DirectApp @directArgs
        continue
    }

    $installArgs = @{ Id = $app.Id; Name = $app.Name }
    if ($app.Source) { $installArgs.Source = $app.Source }
    Install-App @installArgs
}
