# Notes for Claude

My Windows 11 setup script. PowerShell 5.1, console only, no GUI. Started with
`irm https://roelie.cc/wia | iex` (runs Bootstrap.ps1 from main) or Setup.cmd.

## How I work

- I commit and push myself.
- Short and plain everywhere: code, comments, messages, docs. No em dashes or
  " -- ". Comments only where the code is not obvious. No notes to self in the
  code; they go in this file.
- Less code is better. Keep the shape: all questions first, then an unattended
  run; lists in `data\*.psd1`; every step checks first and supports -WhatIf.
- Reviewing another tool (winutil, Win11Debloat): give me a numbered list to
  pick from, and add nothing before I pick.
- A question with a good default beats a new switch. I only remember the one-liner.

## Settings

- Only settings I understand. A value is captured on my own PC after flipping
  the switch (no mark), or documented by Microsoft `(policy)`. Otherwise
  `(unchecked)`: flip the switch by hand once and check. `(not documented)`:
  it works, but Microsoft does not describe it; it can go with `(unchecked)`.
  Never from blog posts.
- On a work PC, Office is IT's: Setup never installs or removes Office or
  its parts (every Outlook, Teams and its add-in, OneDrive, the Microsoft 365
  app). Settings with `NotOnWork` are left alone there too, except the Edge
  Copilot ones that tweaks-personal.psd1 repeats, for my own work laptop.
- Leave services, scheduled tasks, firewall, Defender and activation alone.
  Exception, on request: the Windows AI service (WSAIFabricSvc).
- Every registry write goes through Set-RegValue or Save-Undo, so -Restore can undo it.
- A new yes/no question needs a Read-Answer key in Setup.ps1, the answer in
  the Answers record, and a label in Format-Answers.

## Decided against (do not suggest again)

- Num Lock at boot, animations off, HDR, Game Bar recording, notification
  preferences, verbose startup and shutdown messages.
- Turning off fast startup, hibernation, Delivery Optimization (sharing updates
  on the home network is wanted), the search indexer, location or BitLocker.
- Removing Edge, Sound Recorder, Clipchamp, Media Player, Clock or the codecs.
- From winutil: vendor apps on device plug-in, End task in the taskbar, battery
  percentage, hiding Home, Gallery or Start's Recommended section, folder type
  discovery, the WPBT block, Store search suggestions (it locks store.db).
- The "websites can use my language list" setting.
- Clock seconds and the classic context menu. Show file extensions is commented
  out on purpose. Mouse acceleration stays on.
- Turning off cloud content in Windows search on a work PC (work account
  results are wanted there). Elsewhere it is in privacy-strict.psd1, if wanted.
- Not worth automating: Windows Update, anything with 2FA, restoring data.
- A MANUAL.md checklist; it was too specific to me.
- A stable branch or tag for the one-liner; it runs main.
- Windows 10 support. Setup stops on it.
- Removing an older Office to install Microsoft 365; Setup leaves any Office alone.
- Keeping Recall on a work PC; it goes everywhere. Accepting a Dutch "j" for yes.
- Gaming tweaks: Windows' defaults cover Game Mode and GPU scheduling; the rest
  is BIOS, the graphics driver or blog-post folklore.

## Background

- Widgets: Windows blocks scripts from writing its policy (AllowNewsAndInterests,
  "unauthorized operation"), so apps-remove.psd1 removes the app instead.
- Search without WebView2 (feature 1694661260), tested Nov 2026 on build 26300:
  Search's 6 WebView2 processes (214 MB of RAM) went away, SearchHost grew from 58 MB to
  117-197 MB. If search breaks after an update, suspect this first.
- Sponsored apps count as sponsored only when provisioned (Windows or the PC
  maker put them there). Installed but not provisioned: someone chose it, it stays.
- With Copilot and Recall removed, the Copilot key opens Windows Search.
- Managed PC: domain joined, Entra joined (CloudDomainJoin\JoinInfo) or an
  Enrollments entry with both ProviderID and UPN. Windows keeps 30-odd
  entries of its own under Enrollments, without a UPN.
- `winget list --upgrade-available` exits 0 also when nothing matches, so
  Update-Apps looks for the ID in its output instead.
- Taskbar auto-hide is set with SHAppBarMessage (ABM_SETSTATE), as Settings
  does; it shows at once. Windows only writes it to byte 8 of
  StuckRects3\Settings later, so Setup sets that bit too, or restarting
  Explorer brings the taskbar back. The rest of that value is screen layout:
  never write the whole value from the data files.
- Start-Process -Wait in Windows PowerShell also waits for every process the
  installer starts. Kept on purpose: uninstallers that restart themselves from
  %TEMP% need it. An installer that leaves a program running (a browser, say)
  makes Setup wait until it closes.
- The spare log folder must stay private to the account (AppData\Local):
  -Restore trusts the logs for this account's own settings.
- Friends' PCs have one account, an admin. The account check and the keep
  list are there as protection anyway.
