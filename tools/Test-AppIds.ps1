<#
.SYNOPSIS
    Checks that every package ID in data\apps.psd1 still exists in winget.

.DESCRIPTION
    Package IDs get renamed. When that happens a plain install script fails
    silently and you only notice months later that an app never got installed.
    Run this after a Windows release, or whenever an app is mysteriously absent.

.EXAMPLE
    .\tools\Test-AppIds.ps1
#>
[CmdletBinding()]
param()

$RepoRoot = Split-Path $PSScriptRoot -Parent
$apps = (Import-PowerShellDataFile (Join-Path $RepoRoot 'data\apps.psd1')).Apps

Write-Host "Checking $($apps.Count) package IDs against winget..." -ForegroundColor Cyan
Write-Host ''

$bad = @()
foreach ($app in $apps) {
    # Direct-download entries: check the installer URL still answers.
    if ($app.Url) {
        try {
            $null = Invoke-WebRequest -Uri $app.Url -Method Head -UseBasicParsing -ErrorAction Stop
            Write-Host ("  ok    {0,-45} {1}" -f $app.Url, $app.Name) -ForegroundColor DarkGray
        }
        catch {
            Write-Host ("  GONE  {0,-45} {1}" -f $app.Url, $app.Name) -ForegroundColor Red
            $bad += $app
        }
        continue
    }

    $source = if ($app.Source) { $app.Source } else { 'winget' }
    $null = & winget show --id $app.Id --exact --source $source --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ("  ok    {0,-45} {1}" -f $app.Id, $app.Name) -ForegroundColor DarkGray
    }
    else {
        Write-Host ("  GONE  {0,-45} {1}" -f $app.Id, $app.Name) -ForegroundColor Red
        $bad += $app
    }
}

Write-Host ''
if ($bad) {
    Write-Host "$($bad.Count) ID(s) no longer resolve:" -ForegroundColor Red
    foreach ($app in $bad) {
        Write-Host "  $($app.Name) -- find the new ID with: winget search `"$($app.Name)`"" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host 'All IDs resolve.' -ForegroundColor Green
exit 0
