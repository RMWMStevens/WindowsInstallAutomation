@{
    # My own taste, not for other people's PCs. Applied together with the Start
    # pins in start-pins.json. Format: see tweaks.psd1.
    Personal = @(
        @{ Name = 'Show hidden files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Hidden'; Data = 1; Explorer = $true }
        @{ Name = 'Start: no recently added apps'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'
           Value = 'ShowRecentList'; Data = 0; Explorer = $true }
        @{ Name = 'Explorer: no recently used files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowRecent'; Data = 0; Explorer = $true }
        @{ Name = 'Explorer: no frequently used folders'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowFrequent'; Data = 0; Explorer = $true }
        @{ Name = 'Blue screen shows the details'
           Why  = '(unchecked) The details usually name the driver that crashed.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
           Value = 'DisplayParameters'; Data = 1 }
    )
}
