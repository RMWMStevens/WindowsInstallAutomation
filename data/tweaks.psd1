@{
    # General tweaks: sensible on any PC, mine or someone else's. Mostly things
    # that are simply annoying. Setup asks whether to apply them (default yes).
    # My own taste lives in data\personal.psd1; real privacy settings in
    # data\privacy.psd1. Each is asked about separately. One block each:
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
    # Where each one comes from, in its Why (same in all three files):
    #   (policy)    a Group Policy documented by Microsoft on learn.microsoft.com.
    #               Pro / Education / Enterprise; Home ignores them.
    #   (unchecked) the value the Settings switch is known to write, but NOT yet
    #               seen on my own PC. Flip the switch by hand once and check.
    #   no mark     read from my own PC (Nov 2026) after setting it by hand.
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

        # --- Windows search only searches this PC ----------------------
        @{ Name = 'No web suggestions in the search box'
           Why  = 'Typing in Windows search finds things on this PC, never Bing results. The policy value; the one that still works on current builds.'
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
        @{ Name = 'Explorer opens on This PC'
           Why  = 'Rather than Home / Quick access.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'LaunchTo'; Data = 1; Explorer = $true }
        @{ Name = 'Copy dialog shows details'
           Why  = 'The file copy / move window opens with "More details" expanded.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager'
           Value = 'EnthusiastMode'; Data = 1 }
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
        @{ Name = 'Hide search on the taskbar'
           Why  = 'Taskbar > Search: Hide. Start still searches when you type.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'SearchboxTaskbarMode'; Data = 0; Explorer = $true }
        @{ Name = 'Clock in the notification center'
           Why  = 'Date & time > "Show time in the Notification Center".'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowClockInNotificationCenter'; Data = 1; Explorer = $true }
        @{ Name = 'Alt+Tab shows windows only'
           Why  = 'Multitasking > "Show tabs from apps when snapping or pressing Alt+Tab": Don''t show tabs.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'MultiTaskingAltTabFilter'; Data = 3 }
        <#
        @{ Name = 'Seconds on the taskbar clock'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowSecondsInSystemClock'; Data = 1; Explorer = $true }
        @{ Name = 'Full right-click menu (no "Show more options")'
           Why  = 'Restores the Windows 10 context menu.'
           Key  = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
           Data = ''; Type = 'String'; Explorer = $true }
        #>

        # --- no tips, suggestions, nags or promoted apps -----------------
        @{ Name = 'Start: no tips, shortcuts or new-app recommendations'
           Why  = 'Start > "Show recommendations for tips, shortcuts, new apps, and more" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_IrisRecommendations'; Data = 0; Explorer = $true }
        @{ Name = 'Start: no account notifications'
           Why  = '(unchecked) Start > "Show account-related notifications" off: no "back up your PC" / "finish your account" nags.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_AccountNotifications'; Data = 0; Explorer = $true }
        @{ Name = 'No tips and suggestions'
           Why  = 'Notifications > Additional settings > "Get tips and suggestions when using Windows" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338389Enabled'; Data = 0 }
        @{ Name = 'No welcome experience after updates'
           Why  = '(unchecked) Notifications > Additional settings > "Show the Windows welcome experience after updates" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-310093Enabled'; Data = 0 }
        @{ Name = 'No "finish setting up" suggestions'
           Why  = '(unchecked) Notifications > Additional settings > "Suggest ways to finish setting up my device" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
           Value = 'ScoobeSystemSettingEnabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (1/3)'
           Why  = '(unchecked) Privacy > General > "Show me suggested content in the Settings app" off. Windows splits it over three values.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338393Enabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (2/3)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-353694Enabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (3/3)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-353696Enabled'; Data = 0 }
        @{ Name = 'No notifications in Settings'
           Why  = '(unchecked) Privacy > General > "Show me notifications in the Settings app" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications'
           Value = 'EnableAccountNotifications'; Data = 0 }
        @{ Name = 'Settings opens without its Home page'
           Why  = '(policy) "Settings Page Visibility" = hide:home (Policy CSP Settings/PageVisibilityList). The Home page mostly shows recommendations and Microsoft 365 offers; Settings opens on System instead.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
           Value = 'SettingsPageVisibility'; Data = 'hide:home'; Type = 'String' }
        @{ Name = 'No fun facts and tips on the lock screen (1/2)'
           Why  = '(unchecked) Lock screen > "Get fun facts, tips, tricks, and more on your lock screen" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'RotatingLockScreenOverlayEnabled'; Data = 0 }
        @{ Name = 'No fun facts and tips on the lock screen (2/2)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338387Enabled'; Data = 0 }
        @{ Name = 'No lock screen widgets'
           Why  = 'Lock screen > "Your widgets": none. Moot once remove.psd1 has taken Widgets away; kept for completeness.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen'
           Value = 'LockScreenWidgetsEnabled'; Data = 0 }
        @{ Name = 'Feedback requests: never'
           Why  = '(unchecked) Privacy > Diagnostics & feedback > Feedback frequency: Never.'
           Key  = 'HKCU:\Software\Microsoft\Siuf\Rules'
           Value = 'NumberOfSIUFInPeriod'; Data = 0 }
        @{ Name = 'No feedback notifications'
           Why  = '(policy) Experience/DoNotShowFeedbackNotifications: Windows never asks for feedback.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
           Value = 'DoNotShowFeedbackNotifications'; Data = 1 }
        @{ Name = 'No silently installed sponsored apps'
           Why  = '(unchecked, and not documented anywhere) The Home / Pro counterpart of the policy below. Harmless if Windows ignores it.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SilentInstalledAppsEnabled'; Data = 0 }
        @{ Name = 'No sponsored apps or Start suggestions'
           Why  = '(policy) "Turn off Microsoft consumer experiences" (Experience/AllowWindowsConsumerFeatures). Stops Windows installing promoted apps and adding Start pins after sign-in. Education / Enterprise only -- Home and Pro ignore it.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableWindowsConsumerFeatures'; Data = 1 }

        # --- Edge stays out of memory when you are not using it ----------
        # Any Edge policy makes Edge say "managed by your organization".
        @{ Name = 'Edge: no startup boost'
           Why  = '(policy) Edge StartupBoostEnabled = 0: Edge no longer starts at sign-in or restarts in the background after you close it.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'StartupBoostEnabled'; Data = 0 }
        @{ Name = 'Edge: nothing running after closing'
           Why  = '(policy) Edge BackgroundModeEnabled = 0: closing the last Edge window really closes Edge.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'BackgroundModeEnabled'; Data = 0 }

        # --- look -------------------------------------------------------
        @{ Name = 'Dark mode for apps'
           Why  = 'Colors > "Choose your mode": Dark (this half covers apps).'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'AppsUseLightTheme'; Data = 0; Explorer = $true }
        @{ Name = 'Dark mode for Windows'
           Why  = 'Colors > "Choose your mode": Dark (this half covers the taskbar and Start).'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'SystemUsesLightTheme'; Data = 0; Explorer = $true }

        # --- keyboard and typing ----------------------------------------
        @{ Name = 'No Sticky Keys shortcut'
           Why  = 'Pressing Shift five times no longer asks to turn on Sticky Keys -- mid-game especially.'
           Key  = 'HKCU:\Control Panel\Accessibility\StickyKeys'
           Value = 'Flags'; Data = '506'; Type = 'String' }
        @{ Name = 'No Filter Keys shortcut'
           Why  = 'Holding right Shift for 8 seconds no longer turns on Filter Keys.'
           Key  = 'HKCU:\Control Panel\Accessibility\Keyboard Response'
           Value = 'Flags'; Data = '26'; Type = 'String' }
        @{ Name = 'No autocorrect'
           Why  = 'Typing > "Autocorrect misspelled words" off.'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowAutoCorrection'; Data = 0 }
        @{ Name = 'No text suggestions'
           Why  = 'Typing > "Show text suggestions" off.'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowTextPrediction'; Data = 0 }
        @{ Name = 'No autocorrect on the touch keyboard'
           Key  = 'HKCU:\Software\Microsoft\TabletTip\1.7'
           Value = 'EnableAutocorrection'; Data = 0 }

        # --- system -----------------------------------------------------
        @{ Name = 'Clipboard history on'
           Why  = 'Win+V keeps a history of what you copied. Stays on this PC; syncing across devices is a separate switch and stays off.'
           Key  = 'HKCU:\Software\Microsoft\Clipboard'
           Value = 'EnableClipboardHistory'; Data = 1 }
        @{ Name = 'Storage Sense on'
           Why  = 'Storage > Storage Sense on: clears temp files and an old Recycle Bin automatically (30 days, Downloads never touched).'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
           Value = '01'; Data = 1 }
        @{ Name = 'Long path support'
           Why  = 'Lets tools handle paths over 260 characters. Saves pain with node_modules.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
           Value = 'LongPathsEnabled'; Data = 1 }
        @{ Name = 'Windows Update active hours start 07:00'
           Why  = 'Windows Update > Advanced options > Active hours, set by hand to 07:00-01:00: no restarts in that window.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
           Value = 'ActiveHoursStart'; Data = 7 }
        @{ Name = 'Windows Update active hours end 01:00'
           Key  = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
           Value = 'ActiveHoursEnd'; Data = 1 }
        # Updates from other PCs: deliberately nothing here. Windows' default
        # (Delivery Optimization "LAN") already shares updates between PCs on the
        # same home network, which is what I want.
    )
}
