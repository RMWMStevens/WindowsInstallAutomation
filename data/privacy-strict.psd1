@{
    # Stricter privacy, for whoever wants it: Setup asks, default no. Never on a
    # work PC, where IT may rely on diagnostics and Find my device, and Office's
    # online features are wanted. Format: see tweaks-general.psd1.
    Privacy = @(

        # --- diagnostics ---
        @{ Name = 'Only required diagnostic data'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
           Value = 'AllowTelemetry'; Data = 1 }
        @{ Name = 'Diagnostic data off'
           Why  = '(policy) System/AllowTelemetry. Fully off on Education and Enterprise, "required only" elsewhere.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
           Value = 'AllowTelemetry'; Data = 0 }
        @{ Name = 'No error reports to Microsoft'
           Why  = '(policy) Crashes are still recorded locally in Reliability Monitor.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'
           Value = 'Disabled'; Data = 1 }
        @{ Name = 'Find my device off'
           Why  = '(policy) Experience/AllowFindMyDevice. A lost laptop cannot be located either; comment this out on one you carry around if you want that.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
           Value = 'AllowFindMyDevice'; Data = 0 }

        # --- search ---
        @{ Name = 'No cloud content in search'
           Why  = '(policy) Search/AllowCloudSearch: no OneDrive, Outlook or other account results in Windows search.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
           Value = 'AllowCloudSearch'; Data = 0 }
        @{ Name = 'No cloud content in search (Microsoft account)'
           Why  = '(unchecked) Search permissions > Cloud content search: Microsoft account off. For Home, which ignores the policy.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
           Value = 'IsMSACloudSearchEnabled'; Data = 0 }

        # --- Office online (Microsoft 365 privacy controls, they do nothing until Office is installed) ---
        @{ Name = 'Explorer: no files from Office.com'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowCloudFilesInQuickAccess'; Data = 0; Explorer = $true }
        @{ Name = 'Office: no connected experiences'
           Why  = '(policy) No Designer, Editor, online pictures, translation or dictation. Licensing and mail keep working.'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'disconnectedstate'; Data = 2 }
        @{ Name = 'Office: no content analysis'
           Why  = '(policy)'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'usercontentdisabled'; Data = 2 }
        @{ Name = 'Office: no downloaded online content'
           Why  = '(policy)'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'downloadcontentdisabled'; Data = 2 }
        @{ Name = 'Office: no optional connected experiences'
           Why  = '(policy)'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'controllerconnectedservicesenabled'; Data = 2 }
        @{ Name = 'Office: no diagnostic data'
           Why  = '(policy) 3 = neither required nor optional diagnostic data. Required service data is still sent.'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\common\clienttelemetry'
           Value = 'sendtelemetry'; Data = 3 }
    )
}
