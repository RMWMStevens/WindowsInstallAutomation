@{
    # My own preferences -- fine on my PCs, not something to push onto anyone
    # else's. Setup asks whether to apply these (default no); a yes also pins
    # the apps in data\start-pins.json to Start. Same format as data\tweaks.psd1;
    # see the explanation at the top of that file.
    Personal = @(
        @{ Name = 'Show hidden files'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Hidden'; Data = 1; Explorer = $true }
        @{ Name = 'Start: no recently added apps'
           Why  = 'Start > "Show recently added apps" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'
           Value = 'ShowRecentList'; Data = 0; Explorer = $true }
        @{ Name = 'Explorer: no recently used files'
           Why  = 'Folder Options > Privacy: "Show recently used files" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowRecent'; Data = 0; Explorer = $true }
        @{ Name = 'Explorer: no frequently used folders'
           Why  = 'Folder Options > Privacy: "Show frequently used folders" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowFrequent'; Data = 0; Explorer = $true }
        @{ Name = 'Verbose startup and shutdown messages'
           Why  = 'Says what Windows is actually waiting on during a slow boot. Whole PC, needs admin.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
           Value = 'VerboseStatus'; Data = 1 }
    )
}
