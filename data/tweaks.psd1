@{
    # Registry tweaks, applied by modules/20-registry.ps1.
    #
    # Scope:   User    -> HKCU, applies to whoever runs the script
    #          Machine -> HKLM, needs admin, applies to everyone
    # Explorer: $true  -> Explorer must restart before the change shows
    #
    # Do NOT hand-write new entries from a blog post. Change the setting by
    # hand first, find the key with Process Monitor or `reg export`, then add
    # it here. See README.md -> "Adding a tweak".
    Tweaks = @(

        # --- F1 help key ------------------------------------------------
        @{
            Name  = 'F1 opens nothing (64-bit apps)'
            Why   = 'Stops the browser opening "Get help" every time F1 is hit by accident.'
            Path  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64'
            ValueName = ''
            Value = ''
            Type  = 'String'
            Scope = 'User'
            Tags  = @('core')
        }
        @{
            Name  = 'F1 opens nothing (32-bit apps)'
            Why   = 'Same as above, for the 32-bit help handler.'
            Path  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32'
            ValueName = ''
            Value = ''
            Type  = 'String'
            Scope = 'User'
            Tags  = @('core')
        }

        # --- Start menu / search web results -----------------------------
        @{
            Name  = 'No web suggestions in the search box'
            Why   = 'The policy value. This is the one that still works on current builds.'
            Path  = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
            ValueName = 'DisableSearchBoxSuggestions'
            Value = 1
            Type  = 'DWord'
            Scope = 'User'
            Tags  = @('core')
        }
        @{
            Name  = 'No Bing in Start search'
            Why   = 'Older key. Kept because it costs nothing and helps on older builds.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
            ValueName = 'BingSearchEnabled'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Tags  = @('core')
        }
        @{
            Name  = 'No Cortana in search'
            Why   = 'Older key, same reasoning as BingSearchEnabled.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
            ValueName = 'CortanaConsent'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Tags  = @('core')
        }
        @{
            Name  = 'No search highlights'
            Why   = 'Removes the rotating "highlights" content from the search box.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
            ValueName = 'IsDynamicSearchBoxEnabled'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Tags  = @('core')
        }

        # --- Explorer ----------------------------------------------------
		<# 
        @{
            Name  = 'Show file extensions'
            Why   = 'Hidden extensions make it easy to run a .exe that looks like a .pdf.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'HideFileExt'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('core')
        }
		#>
        @{
            Name  = 'Show hidden files'
            Why   = ''
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'Hidden'
            Value = 1
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('personal', 'dev')
        }
        @{
            Name  = 'Explorer opens on This PC'
            Why   = 'Rather than Home / Quick access.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'LaunchTo'
            Value = 1
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('core')
        }
        @{
            Name  = 'Taskbar icons on the left'
            Why   = 'Windows 10 layout.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'TaskbarAl'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('personal')
        }
        @{
            Name  = 'Hide the widgets button'
            Why   = 'Takes the news / weather widgets button off the taskbar.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'TaskbarDa'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('core')
        }
        @{
            Name  = 'Hide the chat button'
            Why   = 'Windows 11 21H2 / 22H2 only. 23H2 removed the button; elsewhere the value is ignored, so it is harmless to keep.'
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'TaskbarMn'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('core')
        }
        @{
            Name  = 'Hide the task view button'
            Why   = ''
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'ShowTaskViewButton'
            Value = 0
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('personal')
        }
		<#
        @{
            Name  = 'Seconds on the taskbar clock'
            Why   = ''
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'ShowSecondsInSystemClock'
            Value = 1
            Type  = 'DWord'
            Scope = 'User'
            Explorer = $true
            Tags  = @('personal')
        }
        @{
            Name  = 'Full right-click menu (no "Show more options")'
            Why   = 'Restores the Windows 10 context menu.'
            Path  = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
            ValueName = ''
            Value = ''
            Type  = 'String'
            Scope = 'User'
            Explorer = $true
            Tags  = @('core')
        }
		#>

        # --- machine-wide (needs admin) ----------------------------------
        @{
            Name  = 'Long path support'
            Why   = 'Lets tools handle paths over 260 characters. Saves pain with node_modules.'
            Path  = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
            ValueName = 'LongPathsEnabled'
            Value = 1
            Type  = 'DWord'
            Scope = 'Machine'
            Tags  = @('dev')
        }
        @{
            Name  = 'Verbose startup and shutdown messages'
            Why   = 'Says what Windows is actually waiting on during a slow boot.'
            Path  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'VerboseStatus'
            Value = 1
            Type  = 'DWord'
            Scope = 'Machine'
            Tags  = @('dev')
        }
    )
}
