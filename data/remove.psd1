@{
    # Removed on every run, so whatever comes back goes again. Kinds of entry:
    #   Package     a Store app, removed for every account and from Windows' copy
    #               for new accounts. Name: Get-AppxPackage *name* | Select Name
    #   Uninstall   a desktop program, by its name in Settings > Apps (wildcards ok)
    #   Feature     a Windows optional feature
    #   KeepOnWork  kept when you answer yes to "Is this a work PC?"
    #   Guard       OneDriveFolders: refused while user folders are backed up into OneDrive
    # tools\Helpers.ps1 refuses system parts (Store, winget, Security, Photos,
    # Notepad, Terminal, Paint, runtimes), and Xbox parts outside the Xbox list.
    Remove = @(
        @{ Name = 'Bing News';                Package = 'Microsoft.BingNews' }
        @{ Name = 'Bing Weather';             Package = 'Microsoft.BingWeather' }
        @{ Name = 'Microsoft Bing';           Package = 'Microsoft.BingSearch' }   # web results in search
        # Windows blocks the policy that turns Widgets off, so it's uninstalled instead.
        # To get it back: "Windows Web Experience Pack" in the Store.
        @{ Name = 'Widgets';                  Package = 'MicrosoftWindows.Client.WebExperience' }
        @{ Name = 'Microsoft Start feed';     Package = 'Microsoft.StartExperiencesApp' }
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
        @{ Name = 'Mobile devices';           Package = 'MicrosoftWindows.CrossDevice' }   # Phone Link's background part
        @{ Name = 'Copilot';                  Package = 'Microsoft.Copilot' }
        @{ Name = 'Copilot+ AI Hub';          Package = 'Microsoft.Windows.AIHub' }
        @{ Name = 'Microsoft 365 companions'; Package = 'Microsoft.M365Companions'; KeepOnWork = $true }
        @{ Name = 'Family Safety';            Package = 'MicrosoftCorporationII.MicrosoftFamily' }
        # OneDrive and Teams, every part. data\office.xml keeps Microsoft 365 from bringing them back.
        @{ Name = 'OneDrive';                 Uninstall = 'Microsoft OneDrive'; StopProcess = 'OneDrive'; Guard = 'OneDriveFolders'; KeepOnWork = $true }
        @{ Name = 'OneDrive shell integration'; Package = 'Microsoft.OneDriveSync'; Guard = 'OneDriveFolders'; KeepOnWork = $true }
        @{ Name = 'Teams';                    Package = 'MSTeams'; KeepOnWork = $true }
        @{ Name = 'Teams (personal)';         Package = 'MicrosoftTeams' }
        @{ Name = 'Teams Outlook add-in';     Uninstall = 'Microsoft Teams Meeting Add-in*'; KeepOnWork = $true }
        @{ Name = 'Recall';                   Feature = 'Recall' }   # Copilot+ PCs only
    )

    # Removed only when Windows or the PC maker put them there (they are in
    # Windows' copy for new accounts), unless you keep them. Installed by
    # someone from the Store: they stay. List from Win11Debloat.
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

    # Only with a yes to the Xbox question. Keep them on a gaming PC: games that
    # sign in with Xbox need them. Apps first, shared parts last.
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
