@{
    # Config files to drop into place, applied by modules/30-app-config.ps1.
    #
    # Source      -- relative to data\config\
    # Destination -- supports environment variables like %APPDATA%
    # OnlyIf      -- path that must exist first, so a config is not written
    #                for an app that was never installed
    # Overwrite   -- $false leaves an existing file alone (default)
    #
    # Capture a config from an already-configured machine with:
    #   .\tools\Capture-Settings.ps1 -File "<path to the app's config file>"
    Files = @(

        # Example, left in as a template. Delete or replace it.
        # @{
        #     Name        = 'HWiNFO settings'
        #     Source      = 'HWiNFO64.INI'
        #     Destination = '%ProgramFiles%\HWiNFO64\HWiNFO64.INI'
        #     OnlyIf      = '%ProgramFiles%\HWiNFO64\HWiNFO64.EXE'
        #     Overwrite   = $true
        #     Tags        = @('personal')
        # }
    )
}
