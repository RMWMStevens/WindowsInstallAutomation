@echo off
rem Double-click this to set up the PC. It asks for admin rights, then runs
rem Setup.ps1 in a new window (Windows Terminal when available) that stays open.
rem Arguments are passed on, e.g.   Setup.cmd -WhatIf   or   Setup.cmd -Apps all
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Start-Setup.ps1" %*
