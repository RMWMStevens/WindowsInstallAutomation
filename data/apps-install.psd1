@{
    # The app menu. Nothing is installed unless picked.
    #   Id         winget ID (winget search "<name>"). Check them all: tools\Test-AppIds.ps1
    #   Source     'msstore' for Store apps. Use it too when you already have the Store
    #              version: winget sees the two versions as different apps.
    #   Ask        $true: big or licensed, one more question and installed last
    #   Note       shown when it is picked
    #   NoUpdate   $true: "Update apps" leaves it alone, it updates another way
    #   SameMajor  $true: "Update apps" keeps it on its major version, with a winget pin
    #   Detect     its name in Settings > Apps, wildcards ok (for Url and SameMajor)
    #   Url, Signer, Args: a direct download, for apps winget cannot install reliably
    Apps = @(
        @{ Group = 'Core'; Name = '7-Zip';          Id = '7zip.7zip' }
        @{ Group = 'Core'; Name = 'Everything';     Id = 'voidtools.Everything' }
        @{ Group = 'Core'; Name = 'VLC';            Id = 'VideoLAN.VLC' }
        @{ Group = 'Core'; Name = 'HWiNFO';         Id = 'REALiX.HWiNFO' }
        @{ Group = 'Core'; Name = 'CPU-Z';          Id = 'CPUID.CPU-Z' }
        # winget's Microsoft.Office checks setup.exe against a stored hash and
        # fails whenever Microsoft updates it, so this downloads it directly.
        # Any Office already there, older ones too, is left alone.
        @{ Group = 'Core'; Name = 'Microsoft 365';  Ask = $true
           Url    = 'https://officecdn.microsoft.com/pr/wsus/setup.exe'   # Office Deployment Tool
           Signer = 'Microsoft Corporation'
           Args   = '/configure "{data}\apps-office.xml"'   # {data} = this folder; Setup asks which licence
           Detect = 'Microsoft 365*', 'Microsoft Office*'
           Note   = 'Word, Excel and PowerPoint only, not activated. Open Word and sign in with an account that has a licence.' }

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
        @{ Group = 'Dev'; Name = 'Node.js LTS';     Id = 'OpenJS.NodeJS.LTS'; SameMajor = $true; Detect = 'Node.js' }
        @{ Group = 'Dev'; Name = 'Postman';         Id = 'Postman.Postman' }
        # The Visual Studio Installer offers its updates; through winget they fail.
        @{ Group = 'Dev'; Name = 'Visual Studio Community 2026'; Id = 'Microsoft.VisualStudio.Community'; NoUpdate = $true
           Note = 'Large download. Installs without workloads: add them in the Visual Studio Installer. Sign in with a Microsoft account within 30 days, or it locks until you do.' }

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
