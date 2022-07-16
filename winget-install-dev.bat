:: Install dev applications
:: ----------------------------------------------------------------------
@echo off
echo Installing Git
winget install --id Git.Git --exact --silent

echo Installing GitHub Desktop
winget install --id GitHub.GitHubDesktop --exact --silent

echo Installing LINQPad 7
winget install --id LINQPad.LINQPad.7 --exact --silent

echo Installing Microsoft Visual Studio Code
winget install --id Microsoft.VisualStudioCode --exact --silent

echo Installing Node.js LTS
winget install --id OpenJS.NodeJS.LTS --exact --silent

echo Installing Postman
winget install --id Postman.Postman --exact --silent

echo Installing Visual Studio Enterprise 2022
winget install --id Microsoft.VisualStudio.2022.Enterprise --exact --silent

pause