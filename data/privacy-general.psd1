@{
    # Privacy settings for every PC, work laptops included: no ads tracking, no
    # typing and speech collection, no activity history, no AI features. Setup
    # applies these when you say yes to the privacy question. The ones a company
    # may rely on (diagnostic data, Office's online features...) are in
    # data\privacy-personal.psd1, which is skipped on a work PC.
    #
    # Same format and source marks as data\tweaks.psd1 -- see the explanation at
    # the top of that file.
    #
    # Deliberately NOT here:
    #   - Cloud content in Windows search (Microsoft / work account results).
    #     It only does anything when Windows is signed in to an account; my own
    #     PCs are not, and on my work laptop I want those results.
    #   - "Let websites show me locally relevant content by accessing my
    #     language list": language-specific content is fine.
    #   - Sharing Windows updates with PCs on the home network: that is wanted,
    #     and Windows' default.
    Privacy = @(

        # --- ads and tracking ---------------------------------------------
        @{ Name = 'No personalised ads'
           Why  = 'Privacy > General > "Let apps show me personalized ads by using my advertising ID" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
           Value = 'Enabled'; Data = 0 }
        @{ Name = 'Advertising ID off'
           Why  = '(policy) Privacy/DisableAdvertisingId, "Turn off the advertising ID", for every account on the PC.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
           Value = 'DisabledByGroupPolicy'; Data = 1 }
        @{ Name = 'No tailored experiences'
           Why  = 'Privacy > Diagnostics & feedback > "Tailored experiences" off.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
           Value = 'TailoredExperiencesWithDiagnosticDataEnabled'; Data = 0 }
        @{ Name = 'No tailored experiences (policy)'
           Why  = '(policy) Experience/AllowTailoredExperiencesWithDiagnosticData, user scope.'
           Key  = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableTailoredExperiencesWithDiagnosticData'; Data = 1 }

        # --- activity, speech, typing -------------------------------------
        @{ Name = 'No activity history (1/3)'
           Why  = '(policy) Privacy/EnableActivityFeed = 0: apps and Windows cannot record what you do.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'EnableActivityFeed'; Data = 0 }
        @{ Name = 'No activity history (2/3)'
           Why  = '(policy) Privacy/PublishUserActivities = 0.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'PublishUserActivities'; Data = 0 }
        @{ Name = 'No activity history (3/3)'
           Why  = '(policy) Privacy/UploadUserActivities = 0: nothing is sent to Microsoft.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'UploadUserActivities'; Data = 0 }
        @{ Name = 'No online speech recognition'
           Why  = '(unchecked) Privacy > Speech > "Online speech recognition" off. Voice typing then only works offline, if at all.'
           Key  = 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'
           Value = 'HasAccepted'; Data = 0 }
        @{ Name = 'No online speech recognition (policy)'
           Why  = '(policy) Privacy/AllowInputPersonalization = 0, "Allow users to enable online speech recognition services".'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization'
           Value = 'AllowInputPersonalization'; Data = 0 }
        @{ Name = 'No custom inking and typing dictionary (1/4)'
           Why  = '(unchecked) Privacy > Inking & typing personalization off: Windows stops collecting what you type and write to build a word list.'
           Key  = 'HKCU:\Software\Microsoft\Personalization\Settings'
           Value = 'AcceptedPrivacyPolicy'; Data = 0 }
        @{ Name = 'No custom inking and typing dictionary (2/4)'
           Key  = 'HKCU:\Software\Microsoft\InputPersonalization'
           Value = 'RestrictImplicitInkCollection'; Data = 1 }
        @{ Name = 'No custom inking and typing dictionary (3/4)'
           Key  = 'HKCU:\Software\Microsoft\InputPersonalization'
           Value = 'RestrictImplicitTextCollection'; Data = 1 }
        @{ Name = 'No custom inking and typing dictionary (4/4)'
           Key  = 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore'
           Value = 'HarvestContacts'; Data = 0 }
        @{ Name = 'Do not send inking and typing data'
           Why  = '(unchecked) Privacy > Diagnostics & feedback > "Improve inking and typing" off.'
           Key  = 'HKCU:\Software\Microsoft\Input\TIPC'
           Value = 'Enabled'; Data = 0 }
        @{ Name = 'No tracking of app launches'
           Why  = '(unchecked) Privacy > General > "Let Windows improve Start and search results by tracking app launches" off. Start no longer shows a "most used" list.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_TrackProgs'; Data = 0; Explorer = $true }

        # --- AI features ---------------------------------------------------
        @{ Name = 'Recall not allowed'
           Why  = '(policy) WindowsAI/AllowRecallEnablement = 0. Microsoft: Recall is disabled, its files removed and any snapshots deleted, after a restart. Copilot+ PCs, 24H2 build 26100.3915+.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'AllowRecallEnablement'; Data = 0 }
        @{ Name = 'No Recall snapshots'
           Why  = '(policy) WindowsAI/DisableAIDataAnalysis = 1, "Turn off saving snapshots for use with Recall". Backstop for the one above.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableAIDataAnalysis'; Data = 1 }
        @{ Name = 'No Click to Do'
           Why  = '(policy) WindowsAI/DisableClickToDo = 1: no analysing what is on screen. Copilot+ PCs.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableClickToDo'; Data = 1 }
        @{ Name = 'Paint: no Cocreator'
           Why  = '(policy) WindowsAI/DisableCocreator = 1.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableCocreator'; Data = 1 }
        @{ Name = 'Paint: no Image Creator'
           Why  = '(policy) WindowsAI/DisableImageCreator = 1: no prompts or pictures sent to the cloud.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableImageCreator'; Data = 1 }
        @{ Name = 'Paint: no generative fill'
           Why  = '(policy) WindowsAI/DisableGenerativeFill = 1.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableGenerativeFill'; Data = 1 }
        @{ Name = 'Notepad: no AI'
           Why  = '(policy) "Disable AI features in Notepad" (learn.microsoft.com, Manage Notepad): no Copilot rewrite, summarise or write. Notepad 11.2503.16 and later.'
           Key  = 'HKLM:\SOFTWARE\Policies\WindowsNotepad'
           Value = 'DisableAIFeatures'; Data = 1 }
        @{ Name = 'Settings: no AI agent'
           Why  = '(policy) WindowsAI/DisableSettingsAgent = 1: searching Settings no longer goes through the AI agent (Copilot+ PCs). Education / Enterprise only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableSettingsAgent'; Data = 1 }
        # The service that runs Windows' on-device AI models (Click to Do, Recall,
        # the AI parts of Photos, Paint and Notepad, smarter search on Copilot+
        # PCs). It runs on every Windows 11 PC, Copilot+ or not. Its packages
        # (CoreAI, AIFabric) are part of Windows and cannot be removed, so the
        # service is switched off instead. IfPresent: older builds do not have it.
        @{ Name = 'Windows AI service off'
           Why  = '(unchecked, not documented by Microsoft) "Windows AI Components Host" (WSAIFabricSvc) disabled; it stops at the next restart. Nothing else depends on it. Any AI feature still switched on stops working. Setup.cmd -Restore, or Start = 2, puts it back.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Services\WSAIFabricSvc'
           Value = 'Start'; Data = 4; IfPresent = $true }

        # Edge's AI. Every one is a documented Edge policy (learn.microsoft.com,
        # Microsoft Edge browser policies). Several only matter for work
        # (Entra) accounts; they cost nothing elsewhere.
        @{ Name = 'Edge: no sidebar'
           Why  = '(policy) HubsSidebarEnabled = 0: no sidebar, which is where Copilot and the other Microsoft tools sit.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'HubsSidebarEnabled'; Data = 0 }
        @{ Name = 'Edge: no Copilot Chat button'
           Why  = '(policy) Microsoft365CopilotChatIconEnabled = 0. Work accounts.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'Microsoft365CopilotChatIconEnabled'; Data = 0 }
        @{ Name = 'Edge: Copilot cannot read the page'
           Why  = '(policy) CopilotPageContext = 0.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'CopilotPageContext'; Data = 0 }
        @{ Name = 'Edge: work Copilot cannot read pages or history'
           Why  = '(policy) EdgeEntraCopilotPageContext = 0. Work accounts.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'EdgeEntraCopilotPageContext'; Data = 0 }
        @{ Name = 'Edge: no AI writing in text fields'
           Why  = '(policy) ComposeInlineEnabled = 0.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'ComposeInlineEnabled'; Data = 0 }
        @{ Name = 'Edge: no AI search of your history'
           Why  = '(policy) EdgeHistoryAISearchEnabled = 0: history search matches the words you type, nothing more.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'EdgeHistoryAISearchEnabled'; Data = 0 }
        @{ Name = 'Edge: no local AI model'
           Why  = '(policy) GenAILocalFoundationalModelSettings = 1 (Disallowed): Edge does not download its on-device AI model, and deletes it if it already did -- that also frees the disk space.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'GenAILocalFoundationalModelSettings'; Data = 1 }
        @{ Name = 'Edge: no Bing chat on the new tab page'
           Why  = '(policy) NewTabPageBingChatEnabled = 0.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'NewTabPageBingChatEnabled'; Data = 0 }
    )
}
