# WindowsInstallAutomation

Sets up a fresh Windows 11 install the way I want it: installs the
apps I pick, removes the pre-installed bloat, and applies my registry settings.

Run it as often as you like. Every step checks first and only changes what is
different, so a second run just removes whatever has come back -- after a
Windows update, say.

## Fresh install, in order

1. Install Windows 11, Pro or higher (see "Things to know" below).
2. Settings > Windows Update: install everything, restart, repeat until there
   is nothing left.
3. Open PowerShell (Start > type `powershell`) and paste:

   ```powershell
   irm https://roelie.cc/wia | iex
   ```

   It downloads the latest version from GitHub into a temp folder and starts
   Setup in a new admin window. Say yes to the admin prompt.
4. Pick your apps (below) and answer the questions. Each one defaults to the
   capital letter, so just pressing Enter gives the answer below:

   | Question                                                                                                                    | Default              |
   | --------------------------------------------------------------------------------------------------------------------------- | -------------------- |
   | New name for this PC? Only asked while it still has a made-up name like `DESKTOP-1A2B3C4`.                                  | keep                 |
   | Is this a work PC, managed by your employer? Keeps Teams, OneDrive, and other work apps, and skips `privacy-personal.psd1`. | no                   |
   | Apply the general tweaks (`data\tweaks.psd1`)? Sensible on any PC.                                                          | yes                  |
   | Apply the privacy settings (`data\privacy-general.psd1`, plus `privacy-personal.psd1` on your own PCs)?                     | yes                  |
   | Update all installed apps afterwards (`winget upgrade --all`)?                                                              | yes, no on a work PC |
   | Remove the Xbox apps too? Say no on a gaming PC -- games that sign in with Xbox need them.                                  | no                   |
   | Apply my personal preferences and Start pins? Say no on someone else's PC. Pins show after signing out and in.              | no                   |
   | Plain black background on the desktop and the lock / sign-in screen?                                                        | no                   |
   | At the end, clear out old Windows update files? Takes 10+ minutes; worth it after a fresh install's updates.                | no                   |

   **Running it again on the same PC?** Setup first shows the answers of the
   last run there and asks "Same answers as last time?" -- just press Enter and
   it skips the questions above. Handy after a restart (say, when the clean-up
   had to wait for one) or after some updates, and no risk of a different
   answer typed in a hurry. Two answers are never repeated this way: the new
   name, and the black background, because someone may have picked another
   background since. A question added to Setup after that run is asked on its
   own, and remembered from then on. Answer `n` to get every question again.
   The app menu still shows; Enter installs nothing.

   After that it runs on its own: a restore point first, then it removes the
   bloat, installs your apps, updates what is left, applies what you said yes
   to, and cleans up last if you asked. If no restore point can be made, it
   stops and asks before changing anything. When it is done, it tells you if a
   restart is needed.
5. Read `MANUAL.md` and work through what is left to do by hand.

No internet in PowerShell, or want a local copy? Download the repo (**Code >
Download ZIP**), extract it and double-click **`Setup.cmd`** instead.

Arguments work with the one-liner too, in this form:

```powershell
& ([scriptblock]::Create((irm https://roelie.cc/wia))) -WhatIf
```

## Picking apps

Setup shows every app in `data\apps.psd1` as a numbered list:

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

| You type            | You get                                       |
| ------------------- | --------------------------------------------- |
| `all`               | everything                                    |
| `core social tools` | those three groups                            |
| `1-5 9 12`          | those numbers                                 |
| *(just Enter)*      | no apps -- only the removals and settings run |

Groups: Core, Social, Tools, Media, Personal, Dev, Gaming, MediaTools.

Setup then lists what you picked and asks "Go ahead?" -- answer `n` to pick again.
To skip the menu: `Setup.cmd -Apps core,social` (or `-Apps all`, `-Apps none`).

**Microsoft 365** is a big download and needs a licence, so picking it asks one
more question straight after the menu -- unless it is already installed, then
it is simply skipped. It installs last, after the quicker apps. Setup only
installs it; activating it is up to you (sign in with the account that holds
the licence).

**Sponsored apps** (Candy Crush, TikTok, Netflix and the like) that Windows or
the PC maker put on the PC are removed. One that someone installed from the
Store stays: the sponsored tiles in Start only download the app once clicked,
and Setup can tell the difference. When the PC has any that came with it,
Setup lists them straight after the menu, so you can keep some -- on a
friend's PC, say. Type their numbers, or just press Enter to remove them all.
A PC without any is not asked. The tiles themselves are no app (nothing
installed, no memory used); unpin them by hand.

## What Setup does

In the order it runs. The parts under **Always** happen on every run, whatever
you answer; to change those, edit the file named (see "Adding things"). Your
answers decide the rest.

### Always

- **A restore point**, before anything changes. If Windows cannot make one,
  Setup stops and asks whether to go on without.
- **The bloat in `data\remove.psd1` goes**: Bing News, Weather and Search,
  Widgets, Tips, Get Help, Solitaire, People, Maps, Movies & TV, Mail &
  Calendar, Cortana, Feedback Hub, Phone Link, Copilot, Family Safety, the
  Microsoft 365 app and its companions, To Do, Power Automate, Sticky Notes,
  new Outlook, Quick Assist, OneDrive, Teams, and Recall and the AI Hub on
  Copilot+ PCs. Also the sponsored apps that came with the PC, except the
  ones you keep. Store
  apps go for every account on the PC, including accounts made later. Two
  exceptions: on a work PC the work apps stay (below), and OneDrive stays
  while Desktop or Documents are backed up into it.
- **The apps you picked are installed**, Microsoft 365 last. If an install
  brings a removed app back (Microsoft 365 does), it is removed again.
- **Everything is logged** in `C:\WindowsInstallAutomation\logs`.
- **A summary** at the end: what changed, what was already right, what failed.
  Setup offers to restart Explorer and says when the PC needs a restart.

**Never removed**: Edge, Windows Search, the Store, App Installer (winget),
Windows Security, Photos, Notepad, Terminal, Paint, Sound Recorder, Clipchamp
and Media Player -- nor the Xbox apps, unless you say so. Setup also leaves
services (except the Windows AI one, under privacy), scheduled tasks, the
firewall, antivirus settings and activation alone.

### Your answers decide

- **Work PC: yes** -- keeps Teams and its Outlook add-in, OneDrive, new
  Outlook, Quick Assist, the Microsoft 365 app and its companions, To Do,
  Power Automate and Sticky Notes. Skips `privacy-personal.psd1`, so
  diagnostic data, error reports, Find my device and Office's online features
  are left as they are. "Update all" defaults to no, leaving updates to IT.
  The Copilot app and the personal Teams app are still removed.
- **Tweaks: yes** (default) -- `data\tweaks.psd1` is applied.
- **Privacy: yes** (default) -- `data\privacy-general.psd1` is applied, and on
  your own PCs `data\privacy-personal.psd1` too.
- **Update all: yes** -- `winget upgrade --all` after the installs. Microsoft
  365, Windows Terminal and App Installer are skipped (they update
  themselves), and Node.js stays within its current major version.
- **Xbox: yes** -- the eight Xbox parts at the bottom of `data\remove.psd1`
  are removed too.
- **Personal: yes** -- `data\personal.psd1` is applied, and the apps in
  `data\start-pins.json` are pinned to Start once; after that Start is yours
  to change.
- **Black background: yes** -- the desktop, lock screen and sign-in screen
  turn plain black.
- **A new name** -- the PC is renamed; the name changes at the next restart.
- **Clean-up: yes** -- as the very last step,
  `DISM /Online /Cleanup-Image /StartComponentCleanup` deletes the old copies
  of Windows parts that updates have replaced. Windows does this itself about
  once a month, 30 days after each update; this just does it now. Without
  `/ResetBase`, so installed updates can still be uninstalled. Skipped while
  Windows is waiting for a restart (DISM refuses then): restart, run Setup
  again and say yes.

## What the settings do

The short version, per file. Each setting's `Why` line in the file says exactly
what it does and where it comes from.

**General tweaks** (`data\tweaks.psd1`) -- fewer distractions:

- **Search** finds things on this PC only: no Bing results, web suggestions or
  highlights. The search box leaves the taskbar; typing in Start still searches.
  Search no longer runs a hidden Edge (WebView2) to show its results, which
  saves roughly 75 to 150 MB of memory.
- **Taskbar**: icons on the left, no chat or task view button, and the clock
  also shows in the notification center.
- **Explorer** opens on This PC and the copy window shows its details. F1 no
  longer opens "Get help" in the browser. Alt+Tab shows windows, not browser
  tabs.
- **No nags**: no tips, suggestions or "finish setting up" screens; no
  recommendations or account notices in Start; no fun facts or widgets on the
  lock screen; no feedback requests; no sponsored apps installed unasked; no
  OneDrive and Microsoft 365 banners in Explorer; no "use your phone with
  Windows" suggestions. Settings opens on System instead of its Home page, and
  shows no Microsoft 365 ads (Education and Enterprise).
- **Edge** really closes when you close it and no longer starts at sign-in, so
  it uses no memory while you are not using it. No news feed, sponsored tiles,
  first-run screens, "make Edge your default" prompts, shopping assistant,
  Rewards, Acrobat button or feedback requests.
- **Battery**: a sleeping laptop on battery drops Wi-Fi instead of draining
  the battery on it; mail and messages arrive once it wakes.
- **Startup apps** start as soon as you sign in, instead of about 10 seconds
  later.
- **Dark mode** for Windows and apps.
- **Typing**: no autocorrect or text suggestions, and pressing Shift five times
  or holding right Shift no longer turns on Sticky Keys or Filter Keys.
- **Housekeeping**: clipboard history (Win+V) on; Storage Sense clears temp
  files and Recycle Bin items older than 30 days (Downloads is never touched);
  long file paths work; Windows Update does not restart the PC between 07:00
  and 01:00.

**Personal** (`data\personal.psd1`) -- my own taste:

- Explorer shows hidden files, and no recently used files or frequent folders.
- Start shows no recently added apps, and gets my pins.
- A blue screen shows the error details, which usually name the driver at fault.

**Privacy, every PC** (`data\privacy-general.psd1`):

- Apps get no advertising ID, so ads are not personalised, and Microsoft does
  not use your diagnostic data to tailor tips and offers.
- Windows keeps no activity history of what you do, and does not track which
  apps you start.
- Speech is not sent to the cloud, so voice typing (Win+H) may not work.
- Windows does not learn from what you type and write, and sends none of it.
- AI: Recall is off and any snapshots are deleted (Copilot+ PCs), no Click to
  Do, no AI agent in Settings, no AI in Paint or Notepad, and the Windows AI
  service is switched off. Edge: no sidebar or Copilot, no AI writing or AI
  history search, and no on-device AI model (deleted if it was downloaded).

**Privacy, own PCs only** (`data\privacy-personal.psd1`, skipped on a work PC):

- Windows sends only the diagnostic data it requires (on Education and
  Enterprise: none at all), and no crash reports.
- Find my device is off, so a lost laptop cannot be located.
- Explorer shows no files from Office.com.
- Office drops its online extras (Designer, Editor, online pictures and
  templates, translation, dictation) and sends no optional diagnostic data.
  Licensing and mail keep working.

### How the settings behave

- **Setup compares before it writes**, so a second run only changes what has
  drifted back.
- **A setting without `(policy)`** is an ordinary preference, mostly a switch
  in Settings. You can flip it back there, but the next run sets it again. To
  keep it your way, wrap it in `<# ... #>` in the file -- that stops Setup
  setting it, but does not undo it (`Setup.cmd -Restore` does, below).
- **A `(policy)` setting** locks its switch: Settings greys it out and may say
  "Some of these settings are managed by your organization", and Edge says it
  is managed by your organization. That is expected. To undo one, delete its
  value in regedit (the key is in the file), or undo everything with
  `Setup.cmd -Restore`.
- **When it shows**: taskbar and Explorer changes once Explorer restarts (Setup
  offers to), Start pins after signing out and in, policies and the new name
  after a restart.

## Dry run

```
Setup.cmd -WhatIf
```

Shows everything it would install, remove and set, and changes nothing.

## Undo: -Restore

```
Setup.cmd -Restore
```

Puts every setting Setup changed back the way it was before the first run:
the tweaks, personal and privacy settings, the Start pins policy, the Windows
AI service and the desktop background. Before Setup changes a setting, it
writes the old value into that run's log; `-Restore` reads those lines back
from `C:\WindowsInstallAutomation\logs`, newest run first, and asks once before
changing anything. Each run is put back only once, so running it twice does
nothing the second time. `Setup.cmd -Restore -WhatIf` shows what it would put
back.

Not put back: removed apps (reinstall them from the Microsoft Store),
installed apps, the PC's name and the lock screen picture. Runs from before
`-Restore` existed (November 2026) did not write down the old values, so there
is nothing to put back for those. For all of it at once, there is System
Restore and the restore point Setup makes at the start of every run.

With the one-liner: `& ([scriptblock]::Create((irm https://roelie.cc/wia))) -Restore`

## What is where

```
Bootstrap.ps1          		the one-liner's target: downloads the repo, starts Setup.ps1
Setup.cmd              		same, from a downloaded copy: asks for admin, runs Setup.ps1
Setup.ps1              		the whole run, top to bottom -- read this to see what happens
data\apps.psd1         		the apps you can pick
data\remove.psd1       		what gets removed, every run (Xbox list only if you say so)
data\tweaks.psd1       		general tweaks, sensible on any PC: no nags, no web search, Edge out of memory
data\personal.psd1     		my own preferences: hidden files, no recent files, Start lists, blue screen details
data\privacy-general.psd1   privacy on every PC: ads, typing and speech data, activity history, AI
data\privacy-personal.psd1  privacy on my own PCs only: diagnostics, error reports, Office online
data\start-pins.json   		your Start pins (exported with Export-StartLayout), applied with personal.psd1
data\office.xml        		how Microsoft 365 is installed (Word, Excel, PowerPoint only)
tools\Start-Setup.ps1  		opens Setup as admin in Windows Terminal (or a classic window)
tools\Helpers.ps1      		the functions Setup.ps1 calls
tools\Test-AppIds.ps1  		checks every app ID still exists in winget
MANUAL.md              		what is left to do by hand after Setup
```

## Adding things

**An app** -- one line in `data\apps.psd1`:

```powershell
@{ Group = 'Tools'; Name = 'Firefox'; Id = 'Mozilla.Firefox' }
```

Get the ID with `winget search firefox`. For a Store app add `Source = 'msstore'`.
IDs get renamed and a renamed ID fails quietly, so after a Windows release (or
when an app is mysteriously missing) run `.\tools\Test-AppIds.ps1`.

**Something to remove** -- one line in `data\remove.psd1`. Find a Store app's
package name with `Get-AppxPackage *name* | Select-Object Name`.

**A registry setting** -- change the setting by hand first, find which value
changed (regedit, or Process Monitor), then add a block with a `Why` line to:
`data\tweaks.psd1` if it suits any PC, `data\personal.psd1` if it is just your
taste, or `data\privacy-general.psd1` if it limits what is sent to Microsoft
(`privacy-personal.psd1` if an employer might need it left alone). Do not
copy keys from blog posts: they are often wrong or out of date. Policies
Microsoft documents are the exception -- note where in `Why`.

**Start pins** -- arrange Start the way you want it, then run
`Export-StartLayout -Path data\start-pins.json` and put `"applyOnce": true,` back
at the top of the file. Without it, Windows resets Start to this list at every
sign-in.

## Things to know

- **Registry keys move between Windows releases.** If a setting quietly stops
  working after a feature update, re-capture it rather than adding another key
  from a forum post.
- **`HKCU` settings apply to the account that runs Setup.** Another account on
  the same PC needs its own run.
- **OneDrive is only removed when nothing lives in it.** If Desktop or Documents
  are backed up into OneDrive, Setup refuses and tells you how to stop that.
- **Removed Store apps can be reinstalled** from the Store at any time.
- **Logs** go to `C:\WindowsInstallAutomation\logs`, one per run, wherever Setup
  ran from. The black background picture lives in that folder too, next to a
  `README.txt` saying what the folder is. Delete the folder whenever you like;
  only `-Restore` needs the logs.
- **Made for Windows 11 Pro and up.** Settings marked `(policy)` are Group
  Policies, which Windows Home ignores. On Home they are still written, and the
  summary may count them as changed, but they do nothing. That is expected.

## Test it in Windows Sandbox

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All
```

Restart, open Windows Sandbox, copy the repo in, run `Setup.cmd`. You get a clean
Windows in seconds and throw it away afterwards. Sandbox has no Microsoft Store,
so the Store apps fail there but work on a real PC.
