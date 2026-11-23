# Starts Setup.ps1 as admin, in Windows Terminal when the PC has it. Used by
# Setup.cmd and Bootstrap.ps1; arguments go on to Setup.ps1.

$setup = Join-Path (Split-Path $PSScriptRoot) 'Setup.ps1'
$command = @('powershell.exe', '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$setup`"") + $args

if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    try {
        Start-Process wt.exe -Verb RunAs -ArgumentList $command -ErrorAction Stop
        return
    }
    catch {
        # 1223: no was clicked at the admin prompt. Anything else: Terminal would not start.
        for ($e = $_.Exception; $e; $e = $e.InnerException) {
            if ($e.NativeErrorCode -eq 1223) { Write-Host 'Setup needs admin rights. Cancelled.'; return }
        }
    }
}
Start-Process powershell.exe -Verb RunAs -ArgumentList $command[1..($command.Count - 1)]
