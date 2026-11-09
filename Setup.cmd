@echo off
rem Double-click this to set up the PC. It asks for admin rights, then runs
rem Setup.ps1 in a new window that stays open so you can read the summary.
rem Arguments are passed on, e.g.   Setup.cmd -WhatIf   or   Setup.cmd -Apps all
powershell.exe -NoProfile -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -NoExit -ExecutionPolicy Bypass -File \"%~dp0Setup.ps1\" %*'"
