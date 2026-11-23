@{
    # General tweaks, fine on any PC. One block per registry value:
    #   Key        HKCU: this account, HKLM: the whole PC
    #   Value      value name; leave it out for the key's (default) value
    #   Data       what to set it to
    #   Type       DWord unless stated
    #   Explorer   $true: shows after Explorer restarts
    #   IfPresent  $true: only where the key already exists
    #   Why        what it does and where it comes from. (policy): documented by
    #              Microsoft, Pro and up. (unchecked): not confirmed on my own PC
    #              yet. No mark: captured on my own PC.
    # Wrap a block in <# #> to stop setting it; that does not undo it.
    # personal.psd1 and the privacy files use the same format.
    Tweaks = @(

        # --- F1 ---
        @{ Name = 'F1 opens nothing (64-bit apps)'
           Why  = 'F1 no longer opens "Get help" in the browser.'
           Key  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64'
           Data = ''; Type = 'String' }
        @{ Name = 'F1 opens nothing (32-bit apps)'
           Key  = 'HKCU:\Software\Classes\TypeLib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32'
           Data = ''; Type = 'String' }

        # --- search only searches this PC ---
        @{ Name = 'No web suggestions in the search box'
           Why  = 'Windows search finds things on this PC only, no Bing results.'
           Key  = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
           Value = 'DisableSearchBoxSuggestions'; Data = 1 }
        @{ Name = 'No Bing in Start search'
           Why  = 'Older key, for older builds.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'BingSearchEnabled'; Data = 0 }
        @{ Name = 'No Cortana in search'
           Why  = 'Older key, for older builds.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'CortanaConsent'; Data = 0 }
        @{ Name = 'No search highlights'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
           Value = 'IsDynamicSearchBoxEnabled'; Data = 0 }
        @{ Name = 'Search without WebView2'
           Why  = '(not documented by Microsoft) Feature override 1694661260 off: search draws its results without Edge WebView2, about 75 to 150 MB less. Takes a restart; an update may undo it.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260'
           Value = 'EnabledState'; Data = 1 }

        # --- Explorer and taskbar ---
        <#
        @{ Name = 'Show file extensions'
           Why  = 'Hidden extensions make it easy to run a .exe that looks like a .pdf.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'HideFileExt'; Data = 0; Explorer = $true }
        #>
        @{ Name = 'Explorer opens on This PC'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'LaunchTo'; Data = 1; Explorer = $true }
        @{ Name = 'Copy dialog shows details'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager'
           Value = 'EnthusiastMode'; Data = 1 }
        @{ Name = 'Taskbar icons on the left'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'TaskbarAl'; Data = 0; Explorer = $true }
        @{ Name = 'Hide the chat button'
           Why  = 'Windows 11 21H2 and 22H2 only; ignored elsewhere.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'TaskbarMn'; Data = 0; Explorer = $true }
        @{ Name = 'Hide the task view button'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowTaskViewButton'; Data = 0; Explorer = $true }
        @{ Name = 'Hide search on the taskbar'
           Why  = 'Typing in Start still searches.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
           Value = 'SearchboxTaskbarMode'; Data = 0; Explorer = $true }
        @{ Name = 'Clock in the notification center'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowClockInNotificationCenter'; Data = 1; Explorer = $true }
        @{ Name = 'Explorer: no OneDrive and Microsoft 365 ads'
           Why  = '(unchecked) Folder Options > View: "Show sync provider notifications" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'ShowSyncProviderNotifications'; Data = 0; Explorer = $true }
        @{ Name = 'Alt+Tab shows windows only'
           Why  = 'No browser tabs in Alt+Tab.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'MultiTaskingAltTabFilter'; Data = 3 }

        # --- no tips, ads or nags ---
        @{ Name = 'Start: no tips, shortcuts or new-app recommendations'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_IrisRecommendations'; Data = 0; Explorer = $true }
        @{ Name = 'Start: no account notifications'
           Why  = '(unchecked) No "back up your PC" or "finish your account" nags in Start.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_AccountNotifications'; Data = 0; Explorer = $true }
        @{ Name = 'No tips and suggestions'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338389Enabled'; Data = 0 }
        @{ Name = 'No welcome experience after updates'
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-310093Enabled'; Data = 0 }
        @{ Name = 'No "finish setting up" suggestions'
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
           Value = 'ScoobeSystemSettingEnabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (1/3)'
           Why  = '(unchecked) One switch, three values.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338393Enabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (2/3)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-353694Enabled'; Data = 0 }
        @{ Name = 'No suggested content in Settings (3/3)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-353696Enabled'; Data = 0 }
        @{ Name = 'No notifications in Settings'
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications'
           Value = 'EnableAccountNotifications'; Data = 0 }
        @{ Name = 'No phone suggestions'
           Why  = '(unchecked) Mobile devices: "Show me suggestions for using my mobile device with Windows" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Mobility'
           Value = 'OptedIn'; Data = 0 }
        @{ Name = 'No Microsoft 365 ads in Settings'
           Why  = '(policy) Experience/DisableConsumerAccountStateContent, which Win11Debloat uses against the Microsoft 365 and Copilot ads in Settings. Education and Enterprise only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableConsumerAccountStateContent'; Data = 1 }
        @{ Name = 'Settings opens without its Home page'
           Why  = '(policy) Settings/PageVisibilityList = hide:home. Home is mostly recommendations and offers.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
           Value = 'SettingsPageVisibility'; Data = 'hide:home'; Type = 'String' }
        @{ Name = 'No fun facts and tips on the lock screen (1/2)'
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'RotatingLockScreenOverlayEnabled'; Data = 0 }
        @{ Name = 'No fun facts and tips on the lock screen (2/2)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SubscribedContent-338387Enabled'; Data = 0 }
        @{ Name = 'No lock screen widgets'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen'
           Value = 'LockScreenWidgetsEnabled'; Data = 0 }
        @{ Name = 'Feedback requests: never'
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Siuf\Rules'
           Value = 'NumberOfSIUFInPeriod'; Data = 0 }
        @{ Name = 'No feedback notifications'
           Why  = '(policy) Experience/DoNotShowFeedbackNotifications.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
           Value = 'DoNotShowFeedbackNotifications'; Data = 1 }
        @{ Name = 'No silently installed sponsored apps'
           Why  = '(unchecked, not documented) The Home and Pro counterpart of the policy below.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
           Value = 'SilentInstalledAppsEnabled'; Data = 0 }
        @{ Name = 'No sponsored apps or Start suggestions'
           Why  = '(policy) Experience/AllowWindowsConsumerFeatures: Windows stops installing promoted apps and adding Start pins after sign-in. Education and Enterprise only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableWindowsConsumerFeatures'; Data = 1 }

        # --- Edge: no memory use when closed, no ads (Edge policies) ---
        @{ Name = 'Edge: no startup boost'
           Why  = '(policy) Edge no longer starts at sign-in or in the background.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'StartupBoostEnabled'; Data = 0 }
        @{ Name = 'Edge: nothing running after closing'
           Why  = '(policy) Closing the last window really closes Edge.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'BackgroundModeEnabled'; Data = 0 }
        @{ Name = 'Edge: no news on the new tab page'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'NewTabPageContentEnabled'; Data = 0 }
        @{ Name = 'Edge: no sponsored tiles on the new tab page'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'NewTabPageHideDefaultTopSites'; Data = 1 }
        @{ Name = 'Edge: no first-run screens'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'HideFirstRunExperience'; Data = 1 }
        @{ Name = 'Edge: no "make Edge your default" prompts'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'DefaultBrowserSettingsCampaignEnabled'; Data = 0 }
        @{ Name = 'Edge: no feature recommendations'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'ShowRecommendationsEnabled'; Data = 0 }
        @{ Name = 'Edge: no tips and suggestions'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'SpotlightExperiencesAndRecommendationsEnabled'; Data = 0 }
        @{ Name = 'Edge: no shopping assistant'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'EdgeShoppingAssistantEnabled'; Data = 0 }
        @{ Name = 'Edge: no Microsoft Rewards'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'ShowMicrosoftRewards'; Data = 0 }
        @{ Name = 'Edge: no Acrobat subscription button'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'ShowAcrobatSubscriptionButton'; Data = 0 }
        @{ Name = 'Edge: no feedback requests'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'UserFeedbackAllowed'; Data = 0 }
        @{ Name = 'Edge: no tab grouping suggestions'
           Why  = '(policy) Open tabs are not sent to Microsoft for grouping suggestions.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'TabServicesEnabled'; Data = 0 }
        @{ Name = 'Edge: no "similar pages" on errors'
           Why  = '(policy) A page that fails to load is not looked up at Microsoft.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'AlternateErrorPagesEnabled'; Data = 0 }

        # --- look ---
        @{ Name = 'Dark mode for apps'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'AppsUseLightTheme'; Data = 0; Explorer = $true }
        @{ Name = 'Dark mode for Windows'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'SystemUsesLightTheme'; Data = 0; Explorer = $true }

        # --- keyboard and typing ---
        @{ Name = 'No Sticky Keys shortcut'
           Why  = 'Pressing Shift five times no longer asks to turn on Sticky Keys.'
           Key  = 'HKCU:\Control Panel\Accessibility\StickyKeys'
           Value = 'Flags'; Data = '506'; Type = 'String' }
        @{ Name = 'No Filter Keys shortcut'
           Why  = 'Holding right Shift no longer turns on Filter Keys.'
           Key  = 'HKCU:\Control Panel\Accessibility\Keyboard Response'
           Value = 'Flags'; Data = '26'; Type = 'String' }
        @{ Name = 'No autocorrect'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowAutoCorrection'; Data = 0 }
        @{ Name = 'No text suggestions'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowTextPrediction'; Data = 0 }
        @{ Name = 'No autocorrect on the touch keyboard'
           Key  = 'HKCU:\Software\Microsoft\TabletTip\1.7'
           Value = 'EnableAutocorrection'; Data = 0 }

        # --- startup apps start straight away, not 10 seconds after sign-in ---
        @{ Name = 'Startup apps: no delay'
           Why  = '(unchecked, not documented) Read by explorer.exe on build 26300. Comment out on a PC with a hard disk; delete both values to get the delay back.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
           Value = 'StartupDelayInMSec'; Data = 0 }
        @{ Name = 'Startup apps: no waiting for the PC to go quiet'
           Why  = '(unchecked, not documented)'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
           Value = 'WaitForIdleState'; Data = 0 }

        # --- battery ---
        @{ Name = 'Battery: no Wi-Fi while asleep'
           Why  = '(policy) ADMX_Power DCConnectivityInStandby_2 off: a sleeping laptop on battery drops Wi-Fi. Mail and messages wait until it wakes; plugged in, nothing changes. Laptops with Modern Standby only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'
           Value = 'DCSettingIndex'; Data = 0 }

        # --- system ---
        @{ Name = 'Clipboard history on'
           Why  = 'Win+V. Stays on this PC; syncing is a separate switch.'
           Key  = 'HKCU:\Software\Microsoft\Clipboard'
           Value = 'EnableClipboardHistory'; Data = 1 }
        @{ Name = 'Storage Sense on'
           Why  = 'Clears temp files and the Recycle Bin after 30 days. Downloads is never touched.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
           Value = '01'; Data = 1 }
        @{ Name = 'Long path support'
           Why  = 'Paths over 260 characters, for node_modules and the like.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
           Value = 'LongPathsEnabled'; Data = 1 }
        @{ Name = 'Windows Update active hours start 07:00'
           Why  = 'No update restarts between 07:00 and 01:00.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
           Value = 'ActiveHoursStart'; Data = 7 }
        @{ Name = 'Windows Update active hours end 01:00'
           Key  = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
           Value = 'ActiveHoursEnd'; Data = 1 }
    )
}
