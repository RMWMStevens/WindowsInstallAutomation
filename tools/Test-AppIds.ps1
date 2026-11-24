# Checks that every app in data\apps-install.psd1 still exists in winget, and that
# direct downloads still answer. IDs get renamed; Setup then reports the app
# as "not found in winget".

$apps = (Import-PowerShellDataFile (Join-Path (Split-Path $PSScriptRoot) 'data\apps-install.psd1')).Apps
$bad = foreach ($app in $apps) {
    if ($app.Url) {
        $what = $app.Url
        try { $null = Invoke-WebRequest -Uri $app.Url -Method Head -UseBasicParsing -ErrorAction Stop; $ok = $true } catch { $ok = $false }
    }
    else {
        $what = $app.Id
        $null = & winget show --id $app.Id --exact --source $(if ($app.Source) { $app.Source } else { 'winget' }) --accept-source-agreements 2>&1
        $ok = $LASTEXITCODE -eq 0
    }
    if ($ok) { Write-Host ("  ok    {0,-45} {1}" -f $what, $app.Name) -ForegroundColor DarkGray }
    else { Write-Host ("  GONE  {0,-45} {1}" -f $what, $app.Name) -ForegroundColor Red; $app }
}

if ($bad) {
    Write-Host "`nFind the new IDs with: winget search `"<name>`"" -ForegroundColor Yellow
    exit 1
}
Write-Host "`nAll IDs resolve." -ForegroundColor Green
