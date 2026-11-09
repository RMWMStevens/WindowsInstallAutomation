@{
    # What to remove, applied by modules/15-debloat.ps1. Two kinds of entry:
    #
    #   Pattern   -- a Store (Appx) package, removed for the current user with
    #                Remove-AppxPackage. Find the name with:
    #                  Get-AppxPackage *<part of name>* | Select-Object Name
    #   Uninstall -- a normal desktop program, by its DisplayName in
    #                Settings > Apps (wildcards ok). Runs the program's own
    #                uninstaller; MSI packages run fully silent.
    #                StopProcess lists processes to close first.
    #   Feature   -- a Windows optional feature ("Turn Windows features on or
    #                off"), turned off and its files removed. Needs admin.
    #
    # Guard = 'OneDriveFolders' refuses the removal while Desktop, Documents or
    # another user folder is backed up into OneDrive. Uninstalling then would
    # leave those folders pointing at files that may only exist in the cloud.
    #
    # Deliberately NOT in this list, because removing them breaks things:
    #   Microsoft.DesktopAppInstaller  -- this is winget itself
    #   Microsoft.WindowsStore         -- needed to get anything back
    #   Microsoft.UI.Xaml.*, Microsoft.VCLibs.*, *.WindowsAppRuntime.*
    #   Microsoft.SecHealthUI          -- Windows Security UI
    # modules/15-debloat.ps1 refuses to touch those even if listed here.
    #
    # Kept by choice -- do not re-add: Sound Recorder, Clipchamp, Media Player.
    Remove = @(
        @{ Name = 'Bing News';           Pattern = 'Microsoft.BingNews';                     Tags = @('core') }
        @{ Name = 'Bing Weather';        Pattern = 'Microsoft.BingWeather';                  Tags = @('core') }
        @{ Name = 'Get Help';            Pattern = 'Microsoft.GetHelp';                      Tags = @('core') }
        @{ Name = 'Tips';                Pattern = 'Microsoft.Getstarted';                   Tags = @('core') }
        @{ Name = 'Office Hub';          Pattern = 'Microsoft.MicrosoftOfficeHub';           Tags = @('core') }
        @{ Name = 'Solitaire';           Pattern = 'Microsoft.MicrosoftSolitaireCollection'; Tags = @('core') }
        @{ Name = 'People';              Pattern = 'Microsoft.People';                       Tags = @('core') }
        @{ Name = 'Power Automate';      Pattern = 'Microsoft.PowerAutomateDesktop';         Tags = @('core') }
        @{ Name = 'To Do';               Pattern = 'Microsoft.Todos';                        Tags = @('core') }
        @{ Name = 'Feedback Hub';        Pattern = 'Microsoft.WindowsFeedbackHub';           Tags = @('core') }
        @{ Name = 'Maps';                Pattern = 'Microsoft.WindowsMaps';                  Tags = @('core') }
        @{ Name = 'Movies & TV';         Pattern = 'Microsoft.ZuneVideo';                    Tags = @('core') }
        @{ Name = 'Mail & Calendar';     Pattern = 'microsoft.windowscommunicationsapps';    Tags = @('core') }
        @{ Name = 'Cortana';             Pattern = 'Microsoft.549981C3F5F10';                Tags = @('core') }
        # Widgets are switched off by the 'Widgets off entirely' policy in
        # tweaks.psd1; this is the news feed that kept running for them.
        @{ Name = 'Microsoft Start feed'; Pattern = 'Microsoft.StartExperiencesApp';         Tags = @('core') }
        # Web results in Windows search -- off already via DisableSearchBoxSuggestions.
        @{ Name = 'Microsoft Bing';      Pattern = 'Microsoft.BingSearch';                   Tags = @('core') }

        # OneDrive and Teams -- gone on every machine, every part of them.
        # data\office.xml keeps Microsoft 365 from installing them again.
        @{ Name = 'OneDrive';            Uninstall = 'Microsoft OneDrive';                   Tags = @('core')
           StopProcess = @('OneDrive')
           Guard = 'OneDriveFolders' }
        @{ Name = 'OneDrive shell integration'; Pattern = 'Microsoft.OneDriveSync';          Tags = @('core')
           Guard = 'OneDriveFolders' }
        @{ Name = 'Teams';               Pattern = 'MSTeams';                                Tags = @('core') }
        @{ Name = 'Teams (personal)';    Pattern = 'MicrosoftTeams';                         Tags = @('core') }
        @{ Name = 'Teams Outlook add-in'; Uninstall = 'Microsoft Teams Meeting Add-in*';     Tags = @('core') }

        # Judgement calls -- on my machines only.
        @{ Name = 'Sticky Notes';        Pattern = 'Microsoft.MicrosoftStickyNotes';         Tags = @('personal') }
        @{ Name = 'New Outlook';         Pattern = 'Microsoft.OutlookForWindows';            Tags = @('personal') }
        @{ Name = 'Quick Assist';        Pattern = 'MicrosoftCorporationII.QuickAssist';     Tags = @('personal') }
        @{ Name = 'Phone Link';          Pattern = 'Microsoft.YourPhone';                    Tags = @('personal') }
        @{ Name = 'Mobile devices';      Pattern = 'MicrosoftWindows.CrossDevice';           Tags = @('personal')
           Note = 'The background half of Phone Link. Google Quick Share is separate and unaffected.' }
        @{ Name = 'Copilot';             Pattern = 'Microsoft.Copilot';                      Tags = @('personal') }
        @{ Name = 'Microsoft 365 companions'; Pattern = 'Microsoft.M365Companions';          Tags = @('personal')
           Note = 'Microsoft 365 can put this back on update; the next run removes it again.' }
        @{ Name = 'Family Safety';       Pattern = 'MicrosoftCorporationII.MicrosoftFamily'; Tags = @('personal') }
        # Copilot+ PCs only; on anything else the feature does not exist. The
        # 'Recall not allowed' policy in tweaks.psd1 keeps it from coming back.
        @{ Name = 'Recall';              Feature = 'Recall';                                 Tags = @('personal') }

        # Xbox parts -- removed on non-gaming machines only, so they are
        # tagged so that the Gaming profile keeps them.
        @{ Name = 'Xbox Game Bar';       Pattern = 'Microsoft.XboxGamingOverlay';            Tags = @('nogaming') }
        @{ Name = 'Xbox Game Speech';    Pattern = 'Microsoft.XboxSpeechToTextOverlay';      Tags = @('nogaming') }
        @{ Name = 'Xbox app';            Pattern = 'Microsoft.GamingApp';                    Tags = @('nogaming') }
    )
}
