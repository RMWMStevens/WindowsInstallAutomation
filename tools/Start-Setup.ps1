# Starts Setup.ps1 as admin in a window of its own: Windows Terminal when it is
# on the PC (dark, like any terminal), otherwise a classic PowerShell window.
# Setup.cmd and Bootstrap.ps1 both come through here; anything after the script
# name is passed on to Setup.ps1, e.g.  -WhatIf  or  -Apps core,social

$setup = Join-Path (Split-Path $PSScriptRoot) 'Setup.ps1'
$command = @('powershell.exe', '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$setup`"") + $args

if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    try {
        Start-Process wt.exe -Verb RunAs -ArgumentList $command -ErrorAction Stop
        return
    }
    catch {
        # Error 1223 means no was clicked at the admin prompt: stop there. Any
        # other error means Terminal would not start: use the classic window.
        for ($e = $_.Exception; $e; $e = $e.InnerException) {
            if ($e.NativeErrorCode -eq 1223) { Write-Host 'Setup needs admin rights -- cancelled.'; return }
        }
    }
}
Start-Process powershell.exe -Verb RunAs -ArgumentList $command[1..($command.Count - 1)]
