@{
    # One entry per app. Adding an app is one line.
    #
    # Tags drive the profiles in Setup.ps1:
    #   core       -- goes on every machine, including other people's
    #   comms      -- chat / calls
    #   media      -- music, video, images
    #   personal   -- my own machines only
    #   dev        -- development
    #   gaming     -- game launchers
    #   mediatools -- ripping / editing audio and video. Not part of any other
    #                 profile; install with:  .\Setup.ps1 -Profile MediaTools
    #
    # Find an exact ID with:  winget search "<name>"
    # Check every ID still resolves with:  .\tools\Test-AppIds.ps1
    #
    # Source defaults to 'winget'; set it to 'msstore' for Store-only apps, and
    # for apps whose Store build is the one already installed. winget treats the
    # Store build and the winget build as two different apps, so pointing at the
    # other one installs a second copy next to it.
    #
    # An app winget cannot install reliably is downloaded directly instead:
    #   Url    -- the installer, fetched fresh on every install
    #   Signer -- O= of the Authenticode signature; any other signer is refused
    #   Args   -- installer arguments; {data} becomes the path of this data\ folder
    #   Detect -- DisplayName in Settings > Apps (wildcards ok) meaning "installed"
    Apps = @(
        # --- core -------------------------------------------------------
        @{ Id = '7zip.7zip';                       Name = '7-Zip';                 Tags = @('core') }
        @{ Id = 'voidtools.Everything';            Name = 'Everything';            Tags = @('core') }
        @{ Id = 'VideoLAN.VLC';                    Name = 'VLC';                   Tags = @('core') }
        @{ Id = 'AnyDesk.AnyDesk';                 Name = 'AnyDesk';               Tags = @('core') }
        @{ Id = 'Microsoft.PowerToys';             Name = 'PowerToys';             Tags = @('core') }
        @{ Id = '9PLJWWSV01LK';                    Name = 'Twinkle Tray';          Tags = @('core')
           Source = 'msstore' }

        # --- comms ------------------------------------------------------
        @{ Id = '9NKSQGP7F2NH';                    Name = 'WhatsApp';              Tags = @('comms')
           Source = 'msstore'
           Note = 'Store-only. Needs a signed-in Microsoft account, so it may fail on a fresh machine -- see MANUAL.md' }
        @{ Id = 'Discord.Discord';                 Name = 'Discord';               Tags = @('comms', 'personal') }
        @{ Id = 'OpenWhisperSystems.Signal';       Name = 'Signal';                Tags = @('comms') }

        # --- media ------------------------------------------------------
        @{ Id = '9NCBCSZSJRSB';                    Name = 'Spotify';               Tags = @('media')
           Source = 'msstore' }
        @{ Id = 'Plex.Plex';                       Name = 'Plex';                  Tags = @('media', 'personal') }

        # --- personal ---------------------------------------------------
        @{ Id = 'REALiX.HWiNFO';                   Name = 'HWiNFO';                Tags = @('personal')
           Note = 'Configured by modules/30-app-config.ps1' }
        @{ Id = 'TransIP.STACK';                   Name = 'TransIP STACK';         Tags = @('personal') }
        @{ Id = 'CPUID.CPU-Z';                     Name = 'CPU-Z';                 Tags = @('personal') }
        @{ Id = 'JonasJohn.RED.Beta';              Name = 'Remove Empty Directories'; Tags = @('personal') }
        @{ Id = 'Google.QuickShare';               Name = 'Quick Share';           Tags = @('personal') }
        @{ Id = 'Notion.Notion';                   Name = 'Notion';                Tags = @('personal') }
        @{ Id = 'Mozilla.Firefox.DeveloperEdition'; Name = 'Firefox Developer Edition'; Tags = @('personal') }
        # Not the winget package (Microsoft.Office): that one points at this same
        # setup.exe by hash, and breaks every time Microsoft updates the file before
        # the manifest catches up. This is the official Office Deployment Tool.
        @{ Name = 'Microsoft 365';                                                 Tags = @('personal')
           Url    = 'https://officecdn.microsoft.com/pr/wsus/setup.exe'
           Signer = 'Microsoft Corporation'
           Args   = '/configure "{data}\office.xml"'
           Detect = 'Microsoft 365*'
           Note   = 'Installed without OneDrive and Teams (data\office.xml). Sign in afterwards -- see MANUAL.md' }

        # --- dev --------------------------------------------------------
        @{ Id = 'Git.Git';                         Name = 'Git';                   Tags = @('dev') }
        @{ Id = 'GitHub.GitHubDesktop';            Name = 'GitHub Desktop';        Tags = @('dev') }
        @{ Id = 'Microsoft.VisualStudioCode';      Name = 'VS Code';               Tags = @('dev') }
        @{ Id = 'OpenJS.NodeJS.LTS';               Name = 'Node.js LTS';           Tags = @('dev') }
        @{ Id = 'Postman.Postman';                 Name = 'Postman';               Tags = @('dev') }
        @{ Id = 'Microsoft.VisualStudio.Community'; Name = 'Visual Studio Community 2026'; Tags = @('dev')
           Note = 'Large download. Sign in with a Microsoft account within 30 days -- see MANUAL.md' }

        # --- gaming -----------------------------------------------------
        @{ Id = 'Valve.Steam';                     Name = 'Steam';                 Tags = @('gaming') }
        @{ Id = 'GOG.Galaxy';                      Name = 'GOG Galaxy';            Tags = @('gaming') }
        @{ Id = 'ElectronicArts.EADesktop';        Name = 'EA Desktop';            Tags = @('gaming') }
        @{ Id = 'Ubisoft.Connect';                 Name = 'Ubisoft Connect';       Tags = @('gaming') }

        # --- mediatools (separate run: .\Setup.ps1 -Profile MediaTools) -
        @{ Id = 'Audacity.Audacity';               Name = 'Audacity';              Tags = @('mediatools') }
        @{ Id = 'HandBrake.HandBrake';             Name = 'HandBrake';             Tags = @('mediatools') }
        @{ Id = 'MoritzBunkus.MKVToolNix';         Name = 'MKVToolNix';            Tags = @('mediatools') }
        @{ Id = 'GuinpinSoft.MakeMKV';             Name = 'MakeMKV';               Tags = @('mediatools') }
        @{ Id = 'AndreWiethoff.ExactAudioCopy';    Name = 'Exact Audio Copy';      Tags = @('mediatools') }
        @{ Id = 'XnSoft.XnConvert';                Name = 'XnConvert';             Tags = @('mediatools') }
    )
}
