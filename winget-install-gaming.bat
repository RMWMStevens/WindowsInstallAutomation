:: Install gaming applications
:: ----------------------------------------------------------------------
@echo off
echo Installing GOG Galaxy
winget install --id GOG.Galaxy --exact --silent

echo Installing Origin
winget install --id ElectronicArts.EADesktop --exact --silent

echo Installing Steam
winget install --id Valve.Steam --exact --silent

echo Installing Ubisoft Connect
winget install --id Ubisoft.Connect --exact --silent

pause