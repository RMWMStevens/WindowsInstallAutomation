@{
    # Privacy on every PC, work laptops included: no ad tracking, no typing and
    # speech collection, no activity history, no AI. What an employer may rely
    # on is in privacy-personal.psd1. Format: see tweaks.psd1.
    Privacy = @(

        # --- ads and tracking ---
        @{ Name = 'No personalised ads'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
           Value = 'Enabled'; Data = 0 }
        @{ Name = 'Advertising ID off'
           Why  = '(policy) Privacy/DisableAdvertisingId, for every account.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
           Value = 'DisabledByGroupPolicy'; Data = 1 }
        @{ Name = 'No tailored experiences'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
           Value = 'TailoredExperiencesWithDiagnosticDataEnabled'; Data = 0 }
        @{ Name = 'No tailored experiences (policy)'
           Why  = '(policy) Experience/AllowTailoredExperiencesWithDiagnosticData.'
           Key  = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
           Value = 'DisableTailoredExperiencesWithDiagnosticData'; Data = 1 }
        @{ Name = 'No tracking of app launches'
           Why  = '(unchecked) Start no longer shows a "most used" list.'
           Key  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
           Value = 'Start_TrackProgs'; Data = 0; Explorer = $true }

        # --- activity, speech, typing ---
        @{ Name = 'No activity history (1/3)'
           Why  = '(policy) Privacy/EnableActivityFeed.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'EnableActivityFeed'; Data = 0 }
        @{ Name = 'No activity history (2/3)'
           Why  = '(policy) Privacy/PublishUserActivities.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'PublishUserActivities'; Data = 0 }
        @{ Name = 'No activity history (3/3)'
           Why  = '(policy) Privacy/UploadUserActivities.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
           Value = 'UploadUserActivities'; Data = 0 }
        @{ Name = 'No online speech recognition'
           Why  = '(unchecked) Voice typing then works offline only, if at all.'
           Key  = 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'
           Value = 'HasAccepted'; Data = 0 }
        @{ Name = 'No online speech recognition (policy)'
           Why  = '(policy) Privacy/AllowInputPersonalization.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization'
           Value = 'AllowInputPersonalization'; Data = 0 }
        @{ Name = 'No custom inking and typing dictionary (1/4)'
           Why  = '(unchecked) Windows stops collecting what you type and write.'
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
           Why  = '(unchecked)'
           Key  = 'HKCU:\Software\Microsoft\Input\TIPC'
           Value = 'Enabled'; Data = 0 }

        # --- AI ---
        @{ Name = 'Recall not allowed'
           Why  = '(policy) WindowsAI/AllowRecallEnablement. Removes Recall and its snapshots after a restart. Copilot+ PCs.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'AllowRecallEnablement'; Data = 0 }
        @{ Name = 'No Recall snapshots'
           Why  = '(policy) WindowsAI/DisableAIDataAnalysis.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableAIDataAnalysis'; Data = 1 }
        @{ Name = 'No Click to Do'
           Why  = '(policy) WindowsAI/DisableClickToDo: nothing on screen gets analysed. Copilot+ PCs.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableClickToDo'; Data = 1 }
        @{ Name = 'Settings: no AI agent'
           Why  = '(policy) WindowsAI/DisableSettingsAgent. Education and Enterprise only.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
           Value = 'DisableSettingsAgent'; Data = 1 }
        @{ Name = 'Paint: no Cocreator'
           Why  = '(policy) WindowsAI/DisableCocreator.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableCocreator'; Data = 1 }
        @{ Name = 'Paint: no Image Creator'
           Why  = '(policy) WindowsAI/DisableImageCreator: no prompts or pictures sent to the cloud.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableImageCreator'; Data = 1 }
        @{ Name = 'Paint: no generative fill'
           Why  = '(policy) WindowsAI/DisableGenerativeFill.'
           Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'
           Value = 'DisableGenerativeFill'; Data = 1 }
        @{ Name = 'Notepad: no AI'
           Why  = '(policy) From Microsoft''s "Manage Notepad": no Copilot rewriting or summaries. Notepad 11.2503.16 and later.'
           Key  = 'HKLM:\SOFTWARE\Policies\WindowsNotepad'
           Value = 'DisableAIFeatures'; Data = 1 }
        @{ Name = 'Windows AI service off'
           Why  = '(unchecked, not documented) WSAIFabricSvc runs Windows'' on-device AI. Disabled from the next restart; its packages cannot be removed. Any AI feature still on stops working. -Restore puts it back.'
           Key  = 'HKLM:\SYSTEM\CurrentControlSet\Services\WSAIFabricSvc'
           Value = 'Start'; Data = 4; IfPresent = $true }

        # --- Edge AI (Edge policies; some only matter for work accounts) ---
        @{ Name = 'Edge: no sidebar'
           Why  = '(policy) The sidebar is where Copilot sits.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'HubsSidebarEnabled'; Data = 0 }
        @{ Name = 'Edge: no Copilot Chat button'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'Microsoft365CopilotChatIconEnabled'; Data = 0 }
        @{ Name = 'Edge: Copilot cannot read the page'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'CopilotPageContext'; Data = 0 }
        @{ Name = 'Edge: work Copilot cannot read pages or history'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'EdgeEntraCopilotPageContext'; Data = 0 }
        @{ Name = 'Edge: no AI writing in text fields'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'ComposeInlineEnabled'; Data = 0 }
        @{ Name = 'Edge: no AI search of your history'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'EdgeHistoryAISearchEnabled'; Data = 0 }
        @{ Name = 'Edge: no local AI model'
           Why  = '(policy) 1 = not downloaded, and deleted if it was.'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'GenAILocalFoundationalModelSettings'; Data = 1 }
        @{ Name = 'Edge: no Bing chat on the new tab page'
           Why  = '(policy)'
           Key  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
           Value = 'NewTabPageBingChatEnabled'; Data = 0 }
    )
}
