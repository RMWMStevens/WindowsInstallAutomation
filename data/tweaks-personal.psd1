@{
    # My own taste, not for other people's PCs: taskbar, Explorer, dark mode
    # and typing. Applied together with the Start pins in start-pins.json.
    # Format: see tweaks-general.psd1.
    Personal = @(

        # --- taskbar, Start and Alt+Tab ---
        @{ Name = 'Hide the taskbar automatically'
           Why  = 'Taskbar behaviors: "Automatically hide the taskbar", set the way Settings does it.'
           TaskbarAutoHide = $true }
        @{ Name = 'Taskbar icons on the left'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'TaskbarAl'; Data = 0; Explorer = $true }
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
        @{ Name = 'Start: no recently added apps'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'
           Value = 'ShowRecentList'; Data = 0; Explorer = $true }
        @{ Name = 'Alt+Tab shows windows only'
           Why  = 'No browser tabs in Alt+Tab.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'MultiTaskingAltTabFilter'; Data = 3 }

        # --- Explorer ---
        @{ Name = 'Explorer opens on This PC'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'LaunchTo'; Data = 1; Explorer = $true }
        @{ Name = 'Show hidden files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Hidden'; Data = 1; Explorer = $true }
        @{ Name = 'Explorer: no recently used files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowRecent'; Data = 0; Explorer = $true }
        @{ Name = 'Explorer: no frequently used folders'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowFrequent'; Data = 0; Explorer = $true }
        @{ Name = 'Copy dialog shows details'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager'
           Value = 'EnthusiastMode'; Data = 1 }

        # --- look ---
        @{ Name = 'Dark mode for apps'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'AppsUseLightTheme'; Data = 0; Explorer = $true }
        @{ Name = 'Dark mode for Windows'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
           Value = 'SystemUsesLightTheme'; Data = 0; Explorer = $true }

        # --- typing ---
        @{ Name = 'No autocorrect'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowAutoCorrection'; Data = 0 }
        @{ Name = 'No text suggestions'
           Key  = 'HKCU:\Control Panel\International\User Profile'
           Value = 'ShowTextPrediction'; Data = 0 }
        @{ Name = 'No autocorrect on the touch keyboard'
           Key  = 'HKCU:\Software\Microsoft\TabletTip\1.7'
           Value = 'EnableAutocorrection'; Data = 0 }

        # --- system ---
        @{ Name = 'Clipboard history on'
           Why  = 'Win+V. Stays on this PC; syncing is a separate switch.'
           Key  = 'HKCU:\Software\Microsoft\Clipboard'
           Value = 'EnableClipboardHistory'; Data = 1 }
        @{ Name = 'Battery: no Wi-Fi while asleep'
           Why  = '(policy) ADMX_Power DCConnectivityInStandby_2 off: a sleeping laptop on battery drops Wi-Fi. Mail and messages wait until it wakes; plugged in, nothing changes. Laptops with Modern Standby only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'
           Value = 'DCSettingIndex'; Data = 0 }
        @{ Name = 'Blue screen shows the details'
           Why  = '(unchecked) The details usually name the driver that crashed.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
           Value = 'DisplayParameters'; Data = 1 }
    )
}
