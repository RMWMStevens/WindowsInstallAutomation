:: Uninstall pre-installed Microsoft bloatware
:: ----------------------------------------------------------------------
@echo off
echo Uninstalling Cortana
winget uninstall cortana --exact --silent

echo Uninstalling Skype
winget uninstall skype --exact --silent

echo Uninstalling Groove-Music
winget uninstall Microsoft.ZuneMusic_8wekyb3d8bbwe --exact --silent

echo Uninstalling FeedBack-Hub
winget uninstall Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe --exact --silent

echo Uninstalling Microsoft-Tips
winget uninstall Microsoft.Getstarted_8wekyb3d8bbwe --exact --silent

echo Uninstalling 3D-Viewer
winget uninstall Microsoft.3DViewer_8wekyb3d8bbwe --exact --silent
winget uninstall Microsoft.Microsoft3DViewer_8wekyb3d8bbwe  --exact --silent
echo Uninstalling Microsoft Solitaire Collection
winget uninstall Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe --exact --silent

echo Uninstalling Paint-3D
winget uninstall Microsoft.MSPaint_8wekyb3d8bbwe --exact --silent

echo Uninstalling MSN Weather
winget uninstall Microsoft.BingWeather_8wekyb3d8bbwe --exact --silent

echo Uninstalling Mail & Calendar
winget uninstall microsoft.windowscommunicationsapps_8wekyb3d8bbwe --exact --silent

echo Uninstalling Microsoft Contacts
winget uninstall Microsoft.People_8wekyb3d8bbwe --exact --silent

echo Uninstalling Microsoft.Pay/Wallet
winget uninstall Microsoft.Wallet_8wekyb3d8bbwe --exact --silent

echo Uninstalling Microsoft Maps
winget uninstall Microsoft.WindowsMaps_8wekyb3d8bbwe --exact --silent

echo Uninstalling OneNote
winget uninstall Microsoft.Office.OneNote_8wekyb3d8bbwe --exact --silent

echo Uninstalling Office
winget uninstall Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe --exact --silent

echo Uninstalling Voice Recorder
winget uninstall Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe --exact --silent

echo Uninstalling Movies and TV
winget uninstall Microsoft.ZuneVideo_8wekyb3d8bbwe --exact --silent

echo Uninstalling Mixed Reality-Portal
winget uninstall Microsoft.MixedReality.Portal_8wekyb3d8bbwe --exact --silent

echo Uninstalling Sticky Notes
winget uninstall Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe --exact --silent

echo Uninstalling Get Help
winget uninstall Microsoft.GetHelp_8wekyb3d8bbwe --exact --silent

echo Uninstalling OneDrive
winget uninstall Microsoft.OneDrive --exact --silent

echo Uninstalling other Microsoft-related bloatware
winget uninstall Microsoft.Todos_8wekyb3d8bbwe --exact --silent
winget uninstall Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe --exact --silent
winget uninstall Microsoft.BingNews_8wekyb3d8bbwe --exact --silent
winget uninstall MicrosoftTeams_8wekyb3d8bbwe --exact --silent

pause