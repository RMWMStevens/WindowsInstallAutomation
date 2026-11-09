@{
    # Every app Setup can install. Setup shows them as a numbered list, grouped
    # by Group, and you pick what you want -- nothing is installed unless picked.
    #
    #   Id      winget package ID. Find it with:  winget search "<name>"
    #   Source  'msstore' for Store apps. Also use the Store build when that is
    #           the one you already have: winget sees the Store build and the
    #           winget build as two different apps and would install both.
    #   Ask     $true = ask once more before installing (big or licensed apps)
    #   Note    printed when the app is installed
    #
    # Check every ID still exists with:  .\tools\Test-AppIds.ps1
    #
    # An app winget cannot install reliably can be downloaded directly instead,
    # with Url / Signer / Args / Detect -- see Microsoft 365 below. Apps that are
    # in neither winget nor the Store (FileZilla, say) are not listed here.
    Apps = @(
        @{ Group = 'Core'; Name = '7-Zip';          Id = '7zip.7zip' }
        @{ Group = 'Core'; Name = 'Everything';     Id = 'voidtools.Everything' }
        @{ Group = 'Core'; Name = 'VLC';            Id = 'VideoLAN.VLC' }
        @{ Group = 'Core'; Name = 'HWiNFO';         Id = 'REALiX.HWiNFO' }
        @{ Group = 'Core'; Name = 'CPU-Z';          Id = 'CPUID.CPU-Z' }
        # Not winget's Microsoft.Office: that package checks this same setup.exe
        # against a stored hash and fails every time Microsoft updates the file.
        @{ Group = 'Core'; Name = 'Microsoft 365';  Ask = $true
           Url    = 'https://officecdn.microsoft.com/pr/wsus/setup.exe'   # Office Deployment Tool
           Signer = 'Microsoft Corporation'        # refused unless signed by this publisher
           Args   = '/configure "{data}\office.xml"'   # {data} = this folder
           Detect = 'Microsoft 365*'               # name in Settings > Apps once installed
           Note   = 'Word, Excel and PowerPoint only (data\office.xml). Sign in afterwards -- see MANUAL.md' }

        @{ Group = 'Social'; Name = 'WhatsApp';     Id = '9NKSQGP7F2NH'; Source = 'msstore' }
        @{ Group = 'Social'; Name = 'Discord';      Id = 'Discord.Discord' }
        @{ Group = 'Social'; Name = 'Signal';       Id = 'OpenWhisperSystems.Signal' }

        @{ Group = 'Tools'; Name = 'AnyDesk';       Id = 'AnyDesk.AnyDesk' }
        @{ Group = 'Tools'; Name = 'Twinkle Tray';  Id = '9PLJWWSV01LK'; Source = 'msstore' }
        @{ Group = 'Tools'; Name = 'PowerToys';     Id = 'Microsoft.PowerToys' }

        @{ Group = 'Media'; Name = 'Plex';          Id = 'Plex.Plex' }
        @{ Group = 'Media'; Name = 'Spotify';       Id = '9NCBCSZSJRSB'; Source = 'msstore' }

        @{ Group = 'Personal'; Name = 'Quick Share';               Id = 'Google.QuickShare' }
        @{ Group = 'Personal'; Name = 'Firefox Developer Edition'; Id = 'Mozilla.Firefox.DeveloperEdition' }
        @{ Group = 'Personal'; Name = 'TransIP STACK';             Id = 'TransIP.STACK' }
        @{ Group = 'Personal'; Name = 'Notion';                    Id = 'Notion.Notion' }

        @{ Group = 'Dev'; Name = 'Git';             Id = 'Git.Git' }
        @{ Group = 'Dev'; Name = 'GitHub Desktop';  Id = 'GitHub.GitHubDesktop' }
        @{ Group = 'Dev'; Name = 'VS Code';         Id = 'Microsoft.VisualStudioCode' }
        @{ Group = 'Dev'; Name = 'Node.js LTS';     Id = 'OpenJS.NodeJS.LTS' }
        @{ Group = 'Dev'; Name = 'Postman';         Id = 'Postman.Postman' }
        @{ Group = 'Dev'; Name = 'Visual Studio Community 2026'; Id = 'Microsoft.VisualStudio.Community'
           Note = 'Large download. Sign in with a Microsoft account within 30 days -- see MANUAL.md' }

        @{ Group = 'Gaming'; Name = 'Steam';           Id = 'Valve.Steam' }
        @{ Group = 'Gaming'; Name = 'GOG Galaxy';      Id = 'GOG.Galaxy' }
        @{ Group = 'Gaming'; Name = 'EA app';          Id = 'ElectronicArts.EADesktop' }
        @{ Group = 'Gaming'; Name = 'Ubisoft Connect'; Id = 'Ubisoft.Connect' }

        @{ Group = 'MediaTools'; Name = 'Remove Empty Directories'; Id = 'JonasJohn.RED.Beta' }
        @{ Group = 'MediaTools'; Name = 'HandBrake';        Id = 'HandBrake.HandBrake' }
        @{ Group = 'MediaTools'; Name = 'Audacity';         Id = 'Audacity.Audacity' }
        @{ Group = 'MediaTools'; Name = 'MKVToolNix';       Id = 'MoritzBunkus.MKVToolNix' }
        @{ Group = 'MediaTools'; Name = 'MakeMKV';          Id = 'GuinpinSoft.MakeMKV' }
        @{ Group = 'MediaTools'; Name = 'Exact Audio Copy'; Id = 'AndreWiethoff.ExactAudioCopy' }
        @{ Group = 'MediaTools'; Name = 'XnConvert';        Id = 'XnSoft.XnConvert' }
    )
}
