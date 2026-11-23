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
    # KeepOnWork = $true keeps an app when you answer yes to "Is this a work PC?":
    # Teams, OneDrive, Outlook, Quick Assist (IT helpdesks use it), the
    # Microsoft 365 apps, To Do, Power Automate and Sticky Notes.
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
        @{ Name = 'Office Hub';               Package = 'Microsoft.MicrosoftOfficeHub'; KeepOnWork = $true }
        @{ Name = 'Solitaire';                Package = 'Microsoft.MicrosoftSolitaireCollection' }
        @{ Name = 'People';                   Package = 'Microsoft.People' }
        @{ Name = 'Power Automate';           Package = 'Microsoft.PowerAutomateDesktop'; KeepOnWork = $true }
        @{ Name = 'To Do';                    Package = 'Microsoft.Todos'; KeepOnWork = $true }
        @{ Name = 'Feedback Hub';             Package = 'Microsoft.WindowsFeedbackHub' }
        @{ Name = 'Maps';                     Package = 'Microsoft.WindowsMaps' }
        @{ Name = 'Movies & TV';              Package = 'Microsoft.ZuneVideo' }
        @{ Name = 'Mail & Calendar';          Package = 'microsoft.windowscommunicationsapps' }
        @{ Name = 'Cortana';                  Package = 'Microsoft.549981C3F5F10' }
        @{ Name = 'Sticky Notes';             Package = 'Microsoft.MicrosoftStickyNotes'; KeepOnWork = $true }
        @{ Name = 'New Outlook';              Package = 'Microsoft.OutlookForWindows'; KeepOnWork = $true }
        @{ Name = 'Quick Assist';             Package = 'MicrosoftCorporationII.QuickAssist'; KeepOnWork = $true }
        @{ Name = 'Phone Link';               Package = 'Microsoft.YourPhone' }
        @{ Name = 'Mobile devices';           Package = 'MicrosoftWindows.CrossDevice' }   # Phone Link's background half
        @{ Name = 'Copilot';                  Package = 'Microsoft.Copilot' }
        @{ Name = 'Copilot+ AI Hub';          Package = 'Microsoft.Windows.AIHub' }   # Copilot+ PCs only
        @{ Name = 'Microsoft 365 companions'; Package = 'Microsoft.M365Companions'; KeepOnWork = $true }   # Office may put it back; the next run removes it
        @{ Name = 'Family Safety';            Package = 'MicrosoftCorporationII.MicrosoftFamily' }

        # OneDrive and Teams, every part of them. data\office.xml keeps
        # Microsoft 365 from installing them again.
        @{ Name = 'OneDrive';                 Uninstall = 'Microsoft OneDrive'; StopProcess = 'OneDrive'; Guard = 'OneDriveFolders'; KeepOnWork = $true }
        @{ Name = 'OneDrive shell integration'; Package = 'Microsoft.OneDriveSync'; Guard = 'OneDriveFolders'; KeepOnWork = $true }
        @{ Name = 'Teams';                    Package = 'MSTeams'; KeepOnWork = $true }
        @{ Name = 'Teams (personal)';         Package = 'MicrosoftTeams' }
        @{ Name = 'Teams Outlook add-in';     Uninstall = 'Microsoft Teams Meeting Add-in*'; KeepOnWork = $true }

        # Copilot+ PCs only; anywhere else the feature does not exist. The
        # 'Recall not allowed' policy in tweaks.psd1 keeps it from coming back.
        @{ Name = 'Recall';                   Feature = 'Recall' }
    )

    # Sponsored apps: games, streaming and social media apps that Windows or
    # the PC maker put on the PC unasked. Only those go: an app from this list
    # counts as sponsored when it is in Windows' copy for new users, which
    # every new account gets automatically. One that is only installed for an
    # account was got from the Store by someone on the PC, so it stays -- the
    # sponsored tiles in Start are only shortcuts that download the app when
    # clicked. (Those tiles themselves are no app at all: nothing to remove,
    # no memory used. Unpin them by hand.)
    #
    # When any sponsored apps are found, Setup lists them straight after the
    # app menu and asks which to keep; a PC with none is not asked. The list
    # comes from Win11Debloat (github.com/Raphire/Win11Debloat). A * matches
    # any text, for names whose publisher prefix differs per app.
    Sponsored = @(
        @{ Name = 'ACG Media Player';         Package = '*ACGMediaPlayer*' }
        @{ Name = 'Actipro Software';         Package = '*ActiproSoftwareLLC*' }
        @{ Name = 'Adobe Photoshop Express';  Package = 'AdobeSystemsIncorporated.AdobePhotoshopExpress' }
        @{ Name = 'Amazon';                   Package = 'Amazon.com.Amazon' }
        @{ Name = 'Prime Video';              Package = 'AmazonVideo.PrimeVideo' }
        @{ Name = 'Asphalt 8';                Package = '*Asphalt8Airborne*' }
        @{ Name = 'Autodesk SketchBook';      Package = '*AutodeskSketchBook*' }
        @{ Name = 'Caesars Slots';            Package = '*CaesarsSlotsFreeCasino*' }
        @{ Name = 'Cooking Fever';            Package = '*COOKINGFEVER*' }
        @{ Name = 'CyberLink Media Suite';    Package = '*CyberLinkMediaSuiteEssentials*' }
        @{ Name = 'Disney Magic Kingdoms';    Package = '*DisneyMagicKingdoms*' }
        @{ Name = 'Disney+';                  Package = 'Disney.37853FC22B2CE' }
        @{ Name = 'Drawboard PDF';            Package = '*DrawboardPDF*' }
        @{ Name = 'Duolingo';                 Package = '*Duolingo-LearnLanguagesforFree*' }
        @{ Name = 'Facebook';                 Package = 'FACEBOOK.FACEBOOK' }
        @{ Name = 'Instagram';                Package = 'Facebook.Instagram' }
        @{ Name = 'FarmVille 2';              Package = '*FarmVille2CountryEscape*' }
        @{ Name = 'Flipboard';                Package = '*Flipboard*' }
        @{ Name = 'Hidden City';              Package = '*HiddenCity*' }
        @{ Name = 'Hulu';                     Package = 'HULULLC.HULUPLUS' }
        @{ Name = 'iHeartRadio';              Package = '*iHeartRadio*' }
        @{ Name = 'Bubble Witch 3 Saga';      Package = 'king.com.BubbleWitch3Saga' }
        @{ Name = 'Candy Crush Saga';         Package = 'king.com.CandyCrushSaga' }
        @{ Name = 'Candy Crush Soda Saga';    Package = 'king.com.CandyCrushSodaSaga' }
        @{ Name = 'LinkedIn';                 Package = '*LinkedInforWindows*' }
        @{ Name = 'March of Empires';         Package = '*MarchofEmpires*' }
        @{ Name = 'Netflix';                  Package = '4DF9E0F8.Netflix' }
        @{ Name = 'NYT Crossword';            Package = '*NYTCrossword*' }
        @{ Name = 'One Calendar';             Package = '*OneCalendar*' }
        @{ Name = 'Pandora';                  Package = '*PandoraMediaInc*' }
        @{ Name = 'Phototastic Collage';      Package = '*PhototasticCollage*' }
        @{ Name = 'PicsArt';                  Package = '*PicsArt-PhotoStudio*' }
        @{ Name = 'Polarr Photo Editor';      Package = '*PolarrPhotoEditorAcademicEdition*' }
        @{ Name = 'Royal Revolt';             Package = 'flaregamesGmbH.RoyalRevolt' }
        @{ Name = 'Live Wallpaper';           Package = 'Sidia.LiveWallpaper' }
        @{ Name = 'Sling TV';                 Package = '*SlingTV*' }
        @{ Name = 'Spotify';                  Package = 'SpotifyAB.SpotifyMusic' }
        @{ Name = 'TikTok';                   Package = 'BytedancePte.Ltd.TikTok' }
        @{ Name = 'TuneIn Radio';             Package = '*TuneInRadio*' }
        @{ Name = 'WinZip';                   Package = '*WinZipUniversal*' }
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
