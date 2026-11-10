@{
    # Everything here is removed on every run. If something comes back after an
    # update, the next run removes it again. Three kinds of entry:
    #
    #   Package    a Store app. Removed for every user, and also from the copy
    #              Windows keeps for new users, so it stays gone. Find the name:
    #                Get-AppxPackage *<part of name>* | Select-Object Name
    #   Uninstall  a normal desktop program, by its name in Settings > Apps
    #              (wildcards ok). StopProcess is closed first.
    #   Feature    a Windows optional feature ("Turn Windows features on or off").
    #
    # Guard = 'OneDriveFolders' refuses while Desktop, Documents or another user
    # folder is still backed up into OneDrive -- uninstalling then would leave
    # those folders pointing at files that may only exist in the cloud.
    #
    # Never removed, even if listed here (tools\Helpers.ps1 refuses): App Installer
    # (winget), the Store, Windows Security, Photos, Notepad, Terminal, Paint,
    # runtime libraries, and anything Windows itself marks as part of the system
    # (Start, taskbar, Explorer and the like). Xbox parts only through the Xbox
    # list at the bottom.
    #
    # Kept by choice -- do not re-add: Sound Recorder, Clipchamp, Media Player.
    Remove = @(
        @{ Name = 'Bing News';                Package = 'Microsoft.BingNews' }
        @{ Name = 'Bing Weather';             Package = 'Microsoft.BingWeather' }
        @{ Name = 'Microsoft Bing';           Package = 'Microsoft.BingSearch' }   # web results in Windows search
        # Widgets. Windows blocks scripts from setting the policy that switches
        # them off, so the app goes instead. Reinstall: "Windows Web Experience
        # Pack" in the Store.
        @{ Name = 'Widgets';                  Package = 'MicrosoftWindows.Client.WebExperience' }
        @{ Name = 'Microsoft Start feed';     Package = 'Microsoft.StartExperiencesApp' }   # news for Widgets
        @{ Name = 'Get Help';                 Package = 'Microsoft.GetHelp' }
        @{ Name = 'Tips';                     Package = 'Microsoft.Getstarted' }
        @{ Name = 'Office Hub';               Package = 'Microsoft.MicrosoftOfficeHub' }
        @{ Name = 'Solitaire';                Package = 'Microsoft.MicrosoftSolitaireCollection' }
        @{ Name = 'People';                   Package = 'Microsoft.People' }
        @{ Name = 'Power Automate';           Package = 'Microsoft.PowerAutomateDesktop' }
        @{ Name = 'To Do';                    Package = 'Microsoft.Todos' }
        @{ Name = 'Feedback Hub';             Package = 'Microsoft.WindowsFeedbackHub' }
        @{ Name = 'Maps';                     Package = 'Microsoft.WindowsMaps' }
        @{ Name = 'Movies & TV';              Package = 'Microsoft.ZuneVideo' }
        @{ Name = 'Mail & Calendar';          Package = 'microsoft.windowscommunicationsapps' }
        @{ Name = 'Cortana';                  Package = 'Microsoft.549981C3F5F10' }
        @{ Name = 'Sticky Notes';             Package = 'Microsoft.MicrosoftStickyNotes' }
        @{ Name = 'New Outlook';              Package = 'Microsoft.OutlookForWindows' }
        @{ Name = 'Quick Assist';             Package = 'MicrosoftCorporationII.QuickAssist' }
        @{ Name = 'Phone Link';               Package = 'Microsoft.YourPhone' }
        @{ Name = 'Mobile devices';           Package = 'MicrosoftWindows.CrossDevice' }   # Phone Link's background half
        @{ Name = 'Copilot';                  Package = 'Microsoft.Copilot' }
        @{ Name = 'Microsoft 365 companions'; Package = 'Microsoft.M365Companions' }   # Office may put it back; the next run removes it
        @{ Name = 'Family Safety';            Package = 'MicrosoftCorporationII.MicrosoftFamily' }

        # OneDrive and Teams, every part of them. data\office.xml keeps
        # Microsoft 365 from installing them again.
        @{ Name = 'OneDrive';                 Uninstall = 'Microsoft OneDrive'; StopProcess = 'OneDrive'; Guard = 'OneDriveFolders' }
        @{ Name = 'OneDrive shell integration'; Package = 'Microsoft.OneDriveSync'; Guard = 'OneDriveFolders' }
        @{ Name = 'Teams';                    Package = 'MSTeams' }
        @{ Name = 'Teams (personal)';         Package = 'MicrosoftTeams' }
        @{ Name = 'Teams Outlook add-in';     Uninstall = 'Microsoft Teams Meeting Add-in*' }

        # Copilot+ PCs only; anywhere else the feature does not exist. The
        # 'Recall not allowed' policy in tweaks.psd1 keeps it from coming back.
        @{ Name = 'Recall';                   Feature = 'Recall' }
    )

    # Removed only when you answer yes to "Also remove the Xbox apps?" at the
    # start of the removal step; the answer is asked every run. Keep them on a
    # gaming PC: games that sign in with Xbox (Forza, Sea of Thieves, Game Pass)
    # need them. Apps first, the shared parts they depend on last.
    Xbox = @(
        @{ Name = 'Xbox app';                 Package = 'Microsoft.GamingApp' }
        @{ Name = 'Xbox Game Bar';            Package = 'Microsoft.XboxGamingOverlay' }
        @{ Name = 'Xbox Game Bar plugin';     Package = 'Microsoft.XboxGameOverlay' }
        @{ Name = 'Xbox Game Speech';         Package = 'Microsoft.XboxSpeechToTextOverlay' }
        @{ Name = 'Edge Game Assist';         Package = 'Microsoft.Edge.GameAssist' }
        @{ Name = 'Xbox TCUI';                Package = 'Microsoft.Xbox.TCUI' }
        @{ Name = 'Xbox Identity Provider';   Package = 'Microsoft.XboxIdentityProvider' }
        @{ Name = 'Gaming Services';          Package = 'Microsoft.GamingServices' }
    )
}
