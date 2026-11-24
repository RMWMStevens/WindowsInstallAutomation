# WindowsInstallAutomation

Sets up a fresh Windows 11 install the way I want it: installs the apps I pick,
removes the pre-installed bloat and applies my settings.

Run it as often as you like. Every step checks first and only changes what is
different, so a second run just removes whatever has come back, after a Windows
update for example.

## Fresh install

1. Install Windows 11. Windows 10 is not supported; for Home, see "Good to
   know".
2. Settings > Windows Update: install everything, restart, and repeat until
   nothing is left. Then Microsoft Store > Downloads > Get updates, so winget
   (App Installer) is up to date too.
3. Open PowerShell and paste:

   ```powershell
   irm https://roelie.cc/wia | iex
   ```

   This downloads the latest version from GitHub to a temp folder and starts
   Setup in a new window. Say yes to the admin prompt.
4. Pick your apps (see "Picking apps") and answer the questions. Enter gives
   the capital letter, which is the default below:

   | Question                                                                                     | Default                 |
   | -------------------------------------------------------------------------------------------- | ----------------------- |
   | Is this a work PC, managed by your employer?                                                 | no, yes on a managed PC |
   | New name for this PC? Not on a work PC, and only while it has a name like `DESKTOP-1A2B3C4`. | keep                    |
   | Which of the apps Setup removes do you keep? (see "Picking apps")                            | none                    |
   | Apply the general tweaks (`data\tweaks-general.psd1`)?                                       | yes                     |
   | Apply the privacy settings (`data\privacy-general.psd1`)?                                    | yes                     |
   | Apply the strict privacy settings too (`data\privacy-strict.psd1`)? Not on a work PC.        | no                      |
   | Update the apps from the menu that are already on this PC?                                   | no                      |
   | Remove the Xbox apps too? Say no on a gaming PC.                                             | no                      |
   | Apply my personal preferences (`data\tweaks-personal.psd1`)? Say no on someone else's PC.    | no                      |
   | Replace the Start pins with mine? Only asked after a yes to the personal preferences.        | no                      |
   | Plain black background on the desktop and the lock / sign-in screen?                         | no                      |
   | At the end, clear out old Windows update files? Takes 10+ minutes.                           | no                      |

   A PC is managed when it is joined to a domain or to Entra ID, or enrolled
   in device management such as Intune. The work PC question then says so.

   Ran it on this PC before? Then, after the app menu, Setup shows last time's
   answers and asks "Same answers as last time?". Enter reuses them and skips
   the questions, which is useful after a restart or some updates. The PC
   name and the black background are never repeated (someone may have picked
   another background since), and a question added after that run is asked on
   its own. Apps to remove that are new since that run go without asking. On
   a managed PC, the work PC question comes back if last time's answer was no.
   Answer `n` to go through all questions again.

   After the questions it runs on its own: a restore point first, then it
   removes the bloat, installs your apps, updates them if you said so, applies
   what you said yes to and cleans up last. It keeps the PC and the screen
   awake until it is done, so keep a laptop plugged in. If no restore point can
   be made, it stops and asks before changing anything. At the end it says
   whether to restart.

The one-liner always runs the version that is on GitHub at that moment. To run
your own changes to the `data` files, download the repo (**Code > Download
ZIP**), extract it, make the changes and double-click `Setup.cmd`.

Arguments work with the one-liner too:

```powershell
& ([scriptblock]::Create((irm https://roelie.cc/wia))) -WhatIf
```

## Picking apps

Setup shows every app in `data\apps-install.psd1` as a numbered list:

```
  Core
     1  7-Zip
     2  Everything
     ...
     6  Microsoft 365  (asks first)
  Social
     7  WhatsApp
  ...
```

Type numbers, ranges or group names, separated by spaces or commas:

| You type            | You get                                      |
| ------------------- | -------------------------------------------- |
| `all`               | everything                                   |
| `core social tools` | those three groups                           |
| `1-5 9 12`          | those numbers                                |
| just Enter          | no apps; the removals and settings still run |

Groups: Core, Social, Tools, Media, Personal, Dev, Gaming, MediaTools.
Setup then shows what you picked and asks "Go ahead?"; `n` lets you pick
again. To skip the menu: `Setup.cmd -Apps core,social` (or `-Apps all`,
`-Apps none`).

**Microsoft 365** is installed as a basic setup: Word, Excel and PowerPoint
only, in the language Windows uses plus Dutch (`data\apps-office.xml`). The
menus follow Windows; to drop Dutch, uninstall its own entry (ending in
"- nl-nl") in Settings > Apps. Picking it asks once more, because it is a big
download, and then whether you will sign in with a work or school account;
say no for Microsoft 365 Family or Personal. Setup does
not activate it: open Word and sign in. It installs last. When Office is
already on the PC, Microsoft 365 or an older Office like Office 2021, Setup
leaves it alone; to switch, uninstall it in Settings > Apps first. On a work
PC, leave Office to IT.

**The keep list**: after the first questions, Setup lists the apps from
`data\apps-remove.psd1` that are on this PC, with the sponsored apps (Candy
Crush, TikTok, Netflix and the like) that Windows or the PC maker put there. Type the
numbers of the ones to keep, on a friend's PC for example; Enter removes them
all. Sponsored apps someone installed from the Store are not listed and stay.
The sponsored tiles in Start are not apps, only links to the Store; unpin them
by hand.

## What Setup does

In the order it runs. The parts under **Always** happen on every run; to
change those, edit the file named (see "Adding things"). Your answers decide
the rest.

### Always

- **A restore point**, before anything changes. Setup turns on System
  Protection for the system drive when it is off. Windows makes at most one a
  day; when there is one from the last 24 hours, Setup counts on that one.
- **The bloat in `data\apps-remove.psd1` goes**, except what you keep: Bing
  News, Weather and Search, Widgets and the Microsoft Start feed, Tips, Get Help,
  Solitaire, People, Maps, Movies & TV, Mail & Calendar, Cortana, Feedback
  Hub, Phone Link and Mobile devices (with it go the phone features in
  Settings > Bluetooth & devices), Copilot, Family Safety, the Microsoft 365
  app and its companions, To Do, Power Automate, Sticky Notes, new Outlook,
  Quick Assist, OneDrive, Teams, and Recall and the AI Hub on Copilot+ PCs.
  Store apps go for every account on the PC, including accounts made later,
  and their data goes with them (Sticky Notes that were not synced, for
  example). On a work PC the work apps stay (below). OneDrive stays while it
  is in use (see "Good to know").
- **Sponsored apps** that came with the PC go, except the ones you keep.
- **The apps you picked are installed**, Microsoft 365 last. If installing an
  app brings a removed one back (Microsoft 365 brings its companion apps), it
  is removed again.
- **Everything is logged** in `Documents\WindowsInstallAutomation\logs`.
- **A summary** at the end: what changed, what was already right and what
  failed. Setup offers to restart Explorer and says when the PC needs a
  restart.

**Never removed**: Edge, Windows Search, the Store, App Installer (winget),
Windows Security, Photos, Notepad, Terminal, Paint, Sound Recorder, Clipchamp
and Media Player, and the Xbox apps unless you say so. Setup also leaves
services alone (except the Windows AI service, see privacy), as well as
scheduled tasks, the firewall, antivirus settings and activation.

### Your answers decide

- **Work PC: yes** keeps Teams and its Outlook add-in, OneDrive, new Outlook,
  Quick Assist, the Microsoft 365 app and its companions, To Do, Power
  Automate and Sticky Notes. It skips the rename and the strict privacy
  settings, so diagnostic data, error reports, Find my device and Office's
  online features stay the way IT set them. A policy that already has another
  value is left alone, as IT may have set it. The Copilot app and the personal
  Teams app are still removed.
- **Tweaks: yes** (default) applies `data\tweaks-general.psd1`.
- **Privacy: yes** (default) applies `data\privacy-general.psd1`.
- **Strict privacy: yes** also applies `data\privacy-strict.psd1`.
- **Update apps: yes** updates the apps from `data\apps-install.psd1` that are
  on this PC, one by one with winget, also ones that were installed by hand. Apps
  that are not in the menu are left alone, and so are Store apps (the Store
  updates them), Microsoft 365 (updates itself) and Visual Studio (the Visual
  Studio Installer offers its updates). Node.js stays on its major version:
  Setup pins it in winget, and that pin stays. `winget pin remove --id
  OpenJS.NodeJS.LTS` lets it move on.
- **Xbox: yes** also removes the eight Xbox parts at the bottom of
  `data\apps-remove.psd1`. Games that sign in with Xbox need them.
- **Personal: yes** applies `data\tweaks-personal.psd1`.
- **Start pins: yes** replaces the pins in Start with the apps in
  `data\start-pins.json`, my own selection, at the next sign-in. After that
  Start is yours to change.
- **Black background: yes** turns the desktop, lock screen and sign-in screen
  plain black.
- **A new name** takes effect at the next restart.
- **Clean-up: yes** runs `DISM /Online /Cleanup-Image /StartComponentCleanup`
  as the last step. It deletes old versions of Windows components that updates
  replaced, which Windows otherwise does itself 30 days after each update.
  Without `/ResetBase`, so installed updates can still be uninstalled. DISM
  refuses while Windows waits for a restart; then restart and run Setup again.

## What the settings do

Where a setting's name is not enough, its `Why` line in its file says what it
does and where it comes from.

**General tweaks** (`data\tweaks-general.psd1`), for any PC:

- **Search**: no Bing, web suggestions or highlights in Windows search.
- **Explorer and taskbar**: no chat button and no OneDrive banners in
  Explorer. F1 no longer opens "Get help".
- **No ads or nags**: no tips, suggestions, "finish setting up" screens or
  account notices in Start and Settings; no phone suggestions; no fun facts or
  widgets on the lock screen; no feedback requests; no sponsored apps installed
  unasked. Settings opens on System instead of its Home page, and shows no
  Microsoft 365 ads on Education and Enterprise.
- **Edge** really closes when you close it and no longer starts at sign-in. No
  news feed, sponsored tiles, first-run screens, "make Edge your default"
  prompts, feature recommendations, tips, shopping assistant, Rewards, Acrobat
  button or feedback requests. Open tabs are not sent to Microsoft for
  grouping suggestions, and a page that fails to load is not looked up there.
- **Keyboard**: pressing Shift five times or holding right Shift no longer
  turns on Sticky Keys or Filter Keys. Only changed while they are as Windows
  set them, so someone who uses them keeps them.
- **Faster, not documented by Microsoft**: startup apps start right away
  instead of about 10 seconds after sign-in. Search no longer runs a hidden
  Edge (WebView2), which saves 75 to 150 MB of RAM. If Windows search
  misbehaves after an update, suspect this first.
- **Misc**: Storage Sense clears temp files and Recycle Bin items older than
  30 days, only when the disk runs low (never Downloads); long file paths work
  in apps that support them; no update restarts between 07:00 and 01:00.

**Personal** (`data\tweaks-personal.psd1`), my own taste:

- **Taskbar**: hides itself until you point at it, icons on the left, no task
  view button and no search box
  (typing in Start still searches); the clock also shows in the notification
  center. Start shows no recently added apps. Alt+Tab shows windows, not
  browser tabs.
- **Explorer** opens on This PC, shows hidden files and the copy window's
  details, and shows no recent files or frequent folders.
- **Dark mode** for Windows and apps.
- **Typing**: no autocorrect or text suggestions.
- **Misc**: clipboard history (Win+V); a sleeping laptop on battery drops
  Wi-Fi, so mail and messages arrive once it wakes; a blue screen shows the
  error details, which usually name the driver at fault.

**Privacy** (`data\privacy-general.psd1`), for any PC:

- No advertising ID or tailored experiences.
- No activity history, and Windows does not track which apps you start.
- Speech, typing and handwriting are not sent to Microsoft or learned from, so
  voice typing (Win+H) may not work.
- AI: Recall and its snapshots, Click to Do and the AI in Settings, Paint and
  Notepad are off, and the Windows AI service is disabled. Edge: no sidebar or
  Copilot, no AI writing or history search, and its local AI model is deleted.

**Strict privacy** (`data\privacy-strict.psd1`), never on a work PC:

- Only the diagnostic data Windows requires (none on Education and
  Enterprise), and no crash reports.
- Find my device is off, so a lost laptop cannot be located.
- No cloud content in Windows search: no results from OneDrive, Outlook or
  other accounts.
- No Office.com files in Explorer. Office's online features (Designer, Editor,
  online pictures, translation, dictation) and its diagnostic data are off.
  Licensing and mail keep working.

### How the settings behave

- **Setup compares before it writes**, so a later run only changes what has
  drifted back.
- **Most settings without `(policy)`** are a normal switch in Settings. You can
  flip one back, but the next run sets it again. A few have no switch at all
  (F1, the startup delay, search without WebView2, the blue screen details and
  the Windows AI service); only `-Restore` or regedit undoes those.
- **To keep a setting your way**, wrap its block in `<# ... #>` in a downloaded
  copy and start Setup with `Setup.cmd`. That stops Setup setting it but does
  not undo it; `-Restore` does.
- **A `(policy)` setting** locks its switch: Settings greys it out and may say
  "managed by your organization", and so does Edge. That is expected.
- **When it shows**: taskbar and Explorer changes once Explorer restarts (Setup
  offers to), Start pins after signing out and in, policies and the new name
  after a restart.

## Dry run

```
Setup.cmd -WhatIf
```

Shows everything it would install, remove, update and change. It changes
nothing; it only writes its log.

## Undo: -Restore

```
Setup.cmd -Restore
```

Puts the settings Setup changed back to how they were before the first run:
the tweaks, personal and privacy settings, the Windows AI service and the
desktop background, and it removes the Start pins policy. Before Setup changes
a setting, it writes the old value in that run's log. `-Restore` reads those
back, newest run first, and asks once before changing anything. It only puts
back settings that are in Setup's data files, so a log someone edited cannot
set anything else. Each run is put back once; if something failed, the next
`-Restore` tries that run again. Restart afterwards: policies and services only
change back after a restart. `Setup.cmd -Restore -WhatIf` shows what it would
put back.

Not put back:

- Removed apps. Reinstall them from the Microsoft Store, OneDrive from
  onedrive.com. Recall: after `-Restore` and a restart, turn it on again in
  Windows Features.
- Installed apps. Uninstall them in Settings > Apps if you want.
- The PC's name, the lock screen picture and the Start pins (Start keeps
  them). Change them in Settings.
- System Protection, and the winget pin on Node.js.
- Runs from before `-Restore` existed (November 2026), which did not write
  down the old values, runs whose logs were deleted, and runs by another
  account (their logs are in that account's Documents).

System Restore can undo more, back to a restore point from before the first
run, but removed Store apps often come back broken, and a feature update
deletes restore points.

With the one-liner: `& ([scriptblock]::Create((irm https://roelie.cc/wia))) -Restore`

## What is where

```
Bootstrap.ps1               what the one-liner runs: downloads the repo, starts Setup
Setup.cmd                   starts Setup from a downloaded copy
Setup.ps1                   the whole run, top to bottom
data\apps-install.psd1      the apps you can choose from
data\apps-remove.psd1       what gets removed, every run
data\apps-office.xml        how Microsoft 365 is installed (Word, Excel, PowerPoint)
data\tweaks-general.psd1    general tweaks against ads and nags, and speed-ups, fine on any PC
data\tweaks-personal.psd1   my own taste: taskbar, Explorer, dark mode, typing
data\privacy-general.psd1   privacy on every PC: ads, typing and speech data, activity history, AI
data\privacy-strict.psd1    stricter privacy, if wanted: diagnostics, error reports, Office online
data\start-pins.json        my personal Start pins
tools\Helpers.ps1           the functions Setup.ps1 uses
tools\Start-Setup.ps1       opens Setup as admin, in Windows Terminal when there
tools\Test-AppIds.ps1       checks that every app ID still exists in winget
```

## Adding things

**An app**: one line in `data\apps-install.psd1`:

```powershell
@{ Group = 'Tools'; Name = 'Firefox'; Id = 'Mozilla.Firefox' }
```

Get the ID with `winget search firefox`. For a Store app add `Source = 'msstore'`.
IDs get renamed, and an app whose ID was renamed fails with "not found in
winget". So after a Windows release (or when an app is mysteriously missing)
run `.\tools\Test-AppIds.ps1`.

**Something to remove**: one line in `data\apps-remove.psd1`. Find a Store app's
package name with `Get-AppxPackage *name* | Select-Object Name`. A desktop
program needs an uninstaller that asks nothing, or Setup waits for it.

**A registry setting**: change the setting by hand first, find which value
changed (regedit or Process Monitor), then add a block with a `Why` line to
`tweaks-general.psd1` (fine on any PC), `tweaks-personal.psd1` (your taste),
`privacy-general.psd1` (limits what is sent to Microsoft) or
`privacy-strict.psd1` (stricter privacy, which an employer might rely on).
Don't copy keys from blog posts; they are often wrong or out of date. Policies
Microsoft documents are fine; say where in `Why`.

**Start pins**: arrange Start the way you want it, run
`Export-StartLayout -Path data\start-pins.json` and put `"applyOnce": true,` back
at the top of the file. Without it, Windows resets Start to this list at every
sign-in.

## Good to know

- **Windows 11 Home works too**, but `(policy)` settings are Group Policies and
  Home ignores some of them. They are still written and may count as changed
  in the summary. The `Why` line says which need Education or Enterprise.
- **`HKCU` settings apply to the account that runs Setup.** Another account on
  the same PC needs its own run. When the account signed in is not the one
  Setup runs as (someone typed another account's password at the admin
  prompt), Setup asks before it continues.
- **OneDrive stays while it is in use**: while someone is signed in to it, or
  while it backs up user folders like Desktop and Documents. To remove it
  anyway: stop the backup in OneDrive settings > Sync and backup > Manage back
  up, move your files from the OneDrive folder back into your own folders
  (they stay in OneDrive when the backup stops), sign out of OneDrive, then
  run Setup again.
- **Store apps** (WhatsApp, Spotify, Twinkle Tray) can fail when you are not
  signed in to the Microsoft Store. Sign in there and run Setup again.
- **Removed Store apps can be reinstalled** from the Store at any time.
- **Logs** go to `Documents\WindowsInstallAutomation\logs`, one per run,
  wherever Setup ran from. They are in the Documents of the account that
  approved the admin prompt, and sync along when Documents is backed up to
  OneDrive; each log carries the PC's ID, so Setup only reads this PC's. If
  Setup cannot write there (Controlled folder access can block it), it says
  so and uses `C:\WindowsInstallAutomation` instead; `-Restore` reads both.
  The summary always shows where the log is. The black background picture
  lives in that folder too, next to a `README.txt`. Delete the folder whenever
  you like; only `-Restore` needs the logs.
- **If PowerShell is restricted** on a PC (company policies can do that),
  Setup says so and stops.
- **Registry keys move between Windows releases.** If a setting stops working
  after a feature update, capture it again rather than taking a key from a
  forum post.

## Test it in Windows Sandbox

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All
```

Restart, open Windows Sandbox, copy the repo in and run `Setup.cmd`. You get a
clean Windows in seconds and throw it away afterwards. Sandbox needs Pro or
higher, and has no Microsoft Store and no winget, so only the removals and the
settings can be tried there.
