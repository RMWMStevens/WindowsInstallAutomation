@{
    # Privacy settings for my own PCs only. Applied with the privacy question,
    # but skipped on a work PC: an employer's management and security tools can
    # rely on Windows diagnostic data, error reports and Find my device, and
    # Office's online features (Designer, online pictures, office.com files)
    # are wanted at work. data\privacy-general.psd1 holds the rest.
    #
    # Same format and source marks as data\tweaks.psd1 -- see the explanation at
    # the top of that file.
    Privacy = @(

        # --- diagnostics ---------------------------------------------------
        @{ Name = 'Only required diagnostic data'
           Why  = 'Privacy > Diagnostics & feedback > "Send optional diagnostic data" off. The value Settings writes; the policy below goes one step further on Enterprise and Education.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
           Value = 'AllowTelemetry'; Data = 1 }
        @{ Name = 'Diagnostic data off'
           Why  = '(policy) System/AllowTelemetry = 0. Off entirely on Education and Enterprise; Microsoft treats 0 as "required only" on other editions.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
           Value = 'AllowTelemetry'; Data = 0 }
        @{ Name = 'No error reports to Microsoft'
           Why  = '(policy) "Disable Windows Error Reporting": crash details are no longer sent. Reliability Monitor still records crashes locally.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'
           Value = 'Disabled'; Data = 1 }
        @{ Name = 'Find my device off'
           Why  = '(policy) Experience/AllowFindMyDevice = 0: the PC stops reporting its location to Microsoft. Also means you cannot locate a lost laptop -- comment this out on one you carry around if you want that back.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
           Value = 'AllowFindMyDevice'; Data = 0 }

        # --- Office online --------------------------------------------------
        @{ Name = 'Explorer: no files from Office.com'
           Why  = 'Folder Options > Privacy: "Show files from Office.com" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
           Value = 'ShowCloudFilesInQuickAccess'; Data = 0; Explorer = $true }
        # Microsoft's "Manage privacy controls for Microsoft 365 Apps" policies.
        # They only take effect once Office is installed; harmless before that.
        @{ Name = 'Office: no connected experiences'
           Why  = '(policy) "Allow the use of connected experiences in Office" = Disabled (2). Turns off everything Office does online: Designer, Editor, online pictures and templates, translation, dictation. Licensing and Outlook mail sync keep working.'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'disconnectedstate'; Data = 2 }
        @{ Name = 'Office: no content analysis'
           Why  = '(policy) "...connected experiences in Office that analyze content" = Disabled (2). Covered by the one above; set as well so it stays off if that one is ever loosened.'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'usercontentdisabled'; Data = 2 }
        @{ Name = 'Office: no downloaded online content'
           Why  = '(policy) "...connected experiences in Office that download online content" = Disabled (2).'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'downloadcontentdisabled'; Data = 2 }
        @{ Name = 'Office: no optional connected experiences'
           Why  = '(policy) "Allow the use of additional optional connected experiences in Office" = Disabled (2).'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy'
           Value = 'controllerconnectedservicesenabled'; Data = 2 }
        @{ Name = 'Office: no diagnostic data'
           Why  = '(policy) "Configure the level of client software diagnostic data sent by Office" = Neither (3). Microsoft: required service data is still sent.'
           Key  = 'HKCU:\Software\Policies\Microsoft\office\common\clienttelemetry'
           Value = 'sendtelemetry'; Data = 3 }
    )
}
