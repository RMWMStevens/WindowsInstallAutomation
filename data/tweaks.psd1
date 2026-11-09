@{
    # Registry settings, applied on every run. One block each:
    #
    #   Key       the registry key (HKCU: = you, HKLM: = the whole PC)
    #   Value     the value's name; leave it out for the key's (default) value
    #   Data      what to set it to
    #   Type      DWord unless stated
    #   Explorer  $true = Explorer must restart before it shows (Setup offers to)
    #   Why       what it is for -- in two years this is the only thing that
    #             tells you whether a setting that stopped working still matters
    #
    # Do NOT copy a key from a blog post. Change the setting by hand first, find
    # what changed (regedit, or Process Monitor), then add it here. Policies are
    # the exception when Microsoft documents them -- say where in Why.
    #
    # To switch one off, wrap it in <# ... #>. That only stops it being set from
    # now on; a PC that already has it keeps it until you change it back by hand.
    Tweaks = @(

        # --- F1 ---------------------------------------------------------
        @{ Name = 'F1 opens nothing (64-bit apps)'
           Why  = 'Stops the browser opening "Get help" every time F1 is hit by accident.'
           Key  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64'
           Data = ''; Type = 'String' }
        @{ Name = 'F1 opens nothing (32-bit apps)'
           Why  = 'Same as above, for the 32-bit help handler.'
           Key  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32'
           Data = ''; Type = 'String' }

        # --- search -----------------------------------------------------
        @{ Name = 'No web suggestions in the search box'
           Why  = 'The policy value. This is the one that still works on current builds.'
           Key  = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
           Value = 'DisableSearchBoxSuggestions'; Data = 1 }
        @{ Name = 'No Bing in Start search'
           Why  = 'Older key. Kept because it costs nothing and helps on older builds.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'BingSearchEnabled'; Data = 0 }
        @{ Name = 'No Cortana in search'
           Why  = 'Older key, same reasoning as BingSearchEnabled.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'CortanaConsent'; Data = 0 }
        @{ Name = 'No search highlights'
           Why  = 'Removes the rotating "highlights" content from the search box.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
           Value = 'IsDynamicSearchBoxEnabled'; Data = 0 }

        # --- Explorer and taskbar ---------------------------------------
        <#
        @{ Name = 'Show file extensions'
           Why  = 'Hidden extensions make it easy to run a .exe that looks like a .pdf.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'HideFileExt'; Data = 0; Explorer = $true }
        #>
        @{ Name = 'Show hidden files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Hidden'; Data = 1; Explorer = $true }
        @{ Name = 'Explorer opens on This PC'
           Why  = 'Rather than Home / Quick access.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'LaunchTo'; Data = 1; Explorer = $true }
        @{ Name = 'Taskbar icons on the left'
           Why  = 'Windows 10 layout.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'TaskbarAl'; Data = 0; Explorer = $true }
        # Widgets: no setting here. Windows refuses scripts that write the "Allow
        # widgets" policy (AllowNewsAndInterests -- "unauthorized operation", Nov
        # 2026) and reportedly the button value (TaskbarDa) too, so remove.psd1
        # removes the Widgets app itself. That also takes the button away.
        @{ Name = 'Hide the chat button'
           Why  = 'Windows 11 21H2 / 22H2 only. 23H2 removed the button; elsewhere the value is ignored, so it is harmless to keep.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'TaskbarMn'; Data = 0; Explorer = $true }
        @{ Name = 'Hide the task view button'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowTaskViewButton'; Data = 0; Explorer = $true }
        <#
        @{ Name = 'Seconds on the taskbar clock'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowSecondsInSystemClock'; Data = 1; Explorer = $true }
        @{ Name = 'Full right-click menu (no "Show more options")'
           Why  = 'Restores the Windows 10 context menu.'
           Key  = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
           Data = ''; Type = 'String'; Explorer = $true }
        #>

        # --- policies documented by Microsoft (whole PC) ----------------
        @{ Name = 'No sponsored apps or Start suggestions'
           Why  = 'Group Policy "Turn off Microsoft consumer experiences" (Policy CSP Experience/AllowWindowsConsumerFeatures). Stops Windows installing promoted apps and adding Start pins after sign-in. Education / Enterprise only -- Home and Pro ignore it.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableWindowsConsumerFeatures'; Data = 1 }
        @{ Name = 'Recall not allowed'
           Why  = 'Group Policy "Allow Recall to be enabled" = Disabled (Policy CSP WindowsAI/AllowRecallEnablement). Microsoft: Recall is disabled, its files removed and any snapshots deleted, after a restart. Copilot+ PCs, 24H2 build 26100.3915+.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'AllowRecallEnablement'; Data = 0 }

        # --- whole PC ---------------------------------------------------
        @{ Name = 'Long path support'
           Why  = 'Lets tools handle paths over 260 characters. Saves pain with node_modules.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
           Value = 'LongPathsEnabled'; Data = 1 }
        @{ Name = 'Verbose startup and shutdown messages'
           Why  = 'Says what Windows is actually waiting on during a slow boot.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
           Value = 'VerboseStatus'; Data = 1 }
    )
}
