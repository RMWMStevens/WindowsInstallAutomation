# WindowsInstallAutomation

Sets up a fresh Windows 11 install the way I want it: installs the apps I pick,
removes the pre-installed bloat and applies my settings.

Run it as often as you like. Every step checks first and only changes what is
different, so a second run just removes whatever has come back, after a Windows
update for example.

## Fresh install

1. Install Windows 11, Pro or higher (see "Good to know").
2. Settings > Windows Update: install everything, restart, and repeat until
   nothing is left.
3. Open PowerShell and paste:

   ```powershell
   irm https://roelie.cc/wia | iex
   ```

   This downloads the latest version from GitHub to a temp folder and starts
   Setup in a new window. Say yes to the admin prompt.
4. Pick your apps (see "Picking apps") and answer the questions. Enter gives
   the capital letter, which is the default below:

   | Question                                                                             | Default              |
   | ------------------------------------------------------------------------------------ | -------------------- |
   | New name for this PC? Only asked while it has a made-up name like `DESKTOP-1A2B3C4`. | keep                 |
   | Is this a work PC, managed by your employer?                                         | no                   |
   | Apply the general tweaks (`data\tweaks.psd1`)?                                       | yes                  |
   | Apply the privacy settings (`data\privacy-*.psd1`)?                                  | yes                  |
   | Update all installed apps afterwards (`winget upgrade --all`)?                       | yes, no on a work PC |
   | Remove the Xbox apps too? Say no on a gaming PC.                                     | no                   |
   | Apply my personal preferences (`data\personal.psd1`)? Say no on someone else's PC.   | no                   |
   | Pin my apps to Start too? Only asked after a yes to the personal preferences.        | no                   |
   | Plain black background on the desktop and the lock / sign-in screen?                 | no                   |
   | At the end, clear out old Windows update files? Takes 10+ minutes.                   | no                   |

   Ran it on this PC before? Then Setup first shows last time's answers and
   asks "Same answers as last time?". Enter reuses them and skips the
   questions, which is useful after a restart or some updates. The PC name and
   the black background are never repeated (someone may have picked another
   background since), and a question added after that run is asked on its
   own. Answer `n` to go through all questions again.

   After the questions it runs on its own: a restore point first, then it
   removes the bloat, installs your apps, updates the rest, applies what you
   said yes to and cleans up last. If no restore point can be made, it stops
   and asks before changing anything. At the end it says whether to restart.

No internet in PowerShell, or want a local copy? Download the repo (**Code >
Download ZIP**), extract it and double-click `Setup.cmd`.

Arguments work with the one-liner too:

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
only (`data\office.xml`). Setup does not activate it; open Word and sign in
with an account that has a Microsoft 365 licence. It is meant for home PCs,
so leave Office on a work PC to IT. Picking it asks once more, because it is a
big download, and it installs last. When it is already installed, it is
skipped.

**Sponsored apps** (Candy Crush, TikTok, Netflix and the like) that Windows or
the PC maker put on the PC are removed. When there are any, Setup lists them
straight after the menu so you can keep some, on a friend's PC for example.
Apps someone installed from the Store stay. The sponsored tiles in Start are
not apps, only links to the Store; unpin them by hand.

## What Setup does

In the order it runs. The parts under **Always** happen on every run; to
change those, edit the file named (see "Adding things"). Your answers decide
the rest.

### Always

- **A restore point**, before anything changes.
- **The bloat in `data\remove.psd1` goes**: Bing News, Weather and Search,
  Widgets, Tips, Get Help, Solitaire, People, Maps, Movies & TV, Mail &
  Calendar, Cortana, Feedback Hub, Phone Link, Copilot, Family Safety, the
  Microsoft 365 app and its companions, To Do, Power Automate, Sticky Notes,
  new Outlook, Quick Assist, OneDrive, Teams, and Recall and the AI Hub on
  Copilot+ PCs. Store apps go for every account on the PC, including accounts
  made later. On a work PC the work apps stay (below), and OneDrive stays
  while Desktop or Documents are backed up into it.
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
  Automate and Sticky Notes. It skips `privacy-personal.psd1`, so diagnostic
  data, error reports, Find my device and Office's online features stay the
  way IT set them. "Update all" defaults to no, leaving updates to IT. The
  Copilot app and the personal Teams app are still removed.
- **Tweaks: yes** (default) applies `data\tweaks.psd1`.
- **Privacy: yes** (default) applies `data\privacy-general.psd1`, and on your
  own PCs `data\privacy-personal.psd1` too.
- **Update all: yes** runs `winget upgrade --all` after the installs.
  Microsoft 365, Windows Terminal and App Installer are skipped because they
  update themselves, and Node.js stays on its current major version.
- **Xbox: yes** also removes the eight Xbox parts at the bottom of
  `data\remove.psd1`. Games that sign in with Xbox need them.
- **Personal: yes** applies `data\personal.psd1`.
- **Start pins: yes** pins the apps in `data\start-pins.json`, my own
  selection, at the next sign-in. After that Start is yours to change.
- **Black background: yes** turns the desktop, lock screen and sign-in screen
  plain black.
- **A new name** takes effect at the next restart.
- **Clean-up: yes** runs `DISM /Online /Cleanup-Image /StartComponentCleanup`
  as the last step. It deletes old versions of Windows components that updates
  replaced, which Windows otherwise does itself 30 days after each update.
  Without `/ResetBase`, so installed updates can still be uninstalled. DISM
  refuses while Windows waits for a restart; then restart and run Setup again.

## What the settings do

Each setting's `Why` line in its file says what it does and where it comes
from.

**General tweaks** (`data\tweaks.psd1`), for any PC:

- **Search** only finds things on this PC: no Bing, web suggestions or
  highlights. The search box leaves the taskbar; typing in Start still
  searches. Search no longer runs a hidden Edge (WebView2), which saves 75 to
  150 MB.
- **Taskbar**: icons on the left, no task view or chat button, and the clock
  also shows in the notification center.
- **Explorer** opens on This PC, the copy window shows details and F1 no
  longer opens "Get help". Alt+Tab shows windows, not browser tabs.
- **No ads or nags**: no tips, suggestions, "finish setting up" screens or
  account notices in Start and Settings; no fun facts or widgets on the lock
  screen; no OneDrive banners in Explorer; no feedback requests; no sponsored
  apps installed unasked. Settings opens on System, without Microsoft 365 ads.
- **Edge** really closes when you close it and no longer starts at sign-in. No
  news feed, sponsored tiles, first-run screens, "make Edge your default"
  prompts, shopping assistant, Rewards or Acrobat button.
- **Startup apps** start right away instead of about 10 seconds after sign-in.
- **Battery**: a sleeping laptop on battery drops Wi-Fi; mail and messages
  arrive once it wakes.
- **Dark mode** for Windows and apps.
- **Typing**: no autocorrect or text suggestions. Pressing Shift five times or
  holding right Shift no longer turns on Sticky Keys or Filter Keys.
- **Misc**: clipboard history (Win+V); Storage Sense clears temp files and the
  Recycle Bin after 30 days (never Downloads); long file paths work; no update
  restarts between 07:00 and 01:00.

**Personal** (`data\personal.psd1`), my own taste:

- Explorer shows hidden files, and no recent files or frequent folders.
- Start shows no recently added apps.
- A blue screen shows the error details, which usually name the driver at fault.

**Privacy, every PC** (`data\privacy-general.psd1`):

- No advertising ID or tailored experiences.
- No activity history, and Windows does not track which apps you start.
- Speech, typing and handwriting are not sent to Microsoft or learned from, so
  voice typing (Win+H) may not work.
- AI: Recall and its snapshots, Click to Do and the AI in Settings, Paint and
  Notepad are off, and the Windows AI service is disabled. Edge: no sidebar or
  Copilot, no AI writing or history search, and its local AI model is deleted.

**Privacy, own PCs only** (`data\privacy-personal.psd1`, skipped on a work PC):

- Only the diagnostic data Windows requires (none on Education and
  Enterprise), and no crash reports.
- Find my device is off, so a lost laptop cannot be located.
- No cloud content in Windows search: no results from OneDrive, Outlook or
  other accounts. On a work PC those results stay.
- No Office.com files in Explorer. Office's online features (Designer, Editor,
  online pictures, translation, dictation) and optional diagnostic data are
  off. Licensing and mail keep working.

### How the settings behave

- **Setup compares before it writes**, so a later run only changes what has
  drifted back.
- **A setting without `(policy)`** is a normal switch in Settings. You can flip
  it back, but the next run sets it again. To keep it your way, wrap its block
  in `<# ... #>` in the file. That stops Setup setting it but does not undo it;
  `-Restore` does.
- **A `(policy)` setting** locks its switch: Settings greys it out and may say
  "managed by your organization", and so does Edge. That is expected.
- **When it shows**: taskbar and Explorer changes once Explorer restarts (Setup
  offers to), Start pins after signing out and in, policies and the new name
  after a restart.

## Dry run

```
Setup.cmd -WhatIf
```

Shows everything it would install, remove and change, and changes nothing.

## Undo: -Restore

```
Setup.cmd -Restore
```

Puts every setting Setup changed back to how it was before the first run: the
tweaks, personal and privacy settings, the Start pins, the Windows AI service
and the desktop background. Before Setup changes a setting, it writes the old
value in that run's log. `-Restore` reads those back, newest run first, and
asks once before changing anything. Each run is put back only once. Restart
afterwards: policies and services only change back after a restart.
`Setup.cmd -Restore -WhatIf` shows what it would put back.

Not put back:

- Removed apps. Reinstall them from the Microsoft Store.
- Installed apps. Uninstall them in Settings > Apps if you want.
- The PC's name and the lock screen picture. Change them in Settings.
- Runs from before `-Restore` existed (November 2026), which did not write
  down the old values, and runs whose logs were deleted.

To undo all of it at once, use System Restore with the restore point "Before
WindowsInstallAutomation" that Setup makes at the start of each run.

With the one-liner: `& ([scriptblock]::Create((irm https://roelie.cc/wia))) -Restore`

## What is where

```
Bootstrap.ps1               what the one-liner runs: downloads the repo, starts Setup
Setup.cmd                   starts Setup from a downloaded copy
Setup.ps1                   the whole run, top to bottom
data\apps.psd1              the apps you can choose from
data\remove.psd1            what gets removed, every run
data\tweaks.psd1            general tweaks, fine on any PC
data\personal.psd1          my own preferences
data\privacy-general.psd1   privacy on every PC: ads, typing and speech data, activity history, AI
data\privacy-personal.psd1  privacy on my own PCs: diagnostics, error reports, Office online
data\start-pins.json        my personal Start pins
data\office.xml             how Microsoft 365 is installed (Word, Excel, PowerPoint)
tools\Helpers.ps1           the functions Setup.ps1 uses
tools\Start-Setup.ps1       opens Setup as admin, in Windows Terminal when there
tools\Test-AppIds.ps1       checks that every app ID still exists in winget
```

## Adding things

**An app**: one line in `data\apps.psd1`:

```powershell
@{ Group = 'Tools'; Name = 'Firefox'; Id = 'Mozilla.Firefox' }
```

Get the ID with `winget search firefox`. For a Store app add `Source = 'msstore'`.
IDs get renamed, and an install with a renamed ID fails quietly, so after a
Windows release (or when an app is mysteriously missing) run
`.\tools\Test-AppIds.ps1`.

**Something to remove**: one line in `data\remove.psd1`. Find a Store app's
package name with `Get-AppxPackage *name* | Select-Object Name`.

**A registry setting**: change the setting by hand first, find which value
changed (regedit or Process Monitor), then add a block with a `Why` line to
`tweaks.psd1` (fine on any PC), `personal.psd1` (your taste),
`privacy-general.psd1` (limits what is sent to Microsoft) or
`privacy-personal.psd1` (when an employer might need it left alone). Don't copy
keys from blog posts; they are often wrong or out of date. Policies Microsoft
documents are fine; say where in `Why`.

**Start pins**: arrange Start the way you want it, run
`Export-StartLayout -Path data\start-pins.json` and put `"applyOnce": true,` back
at the top of the file. Without it, Windows resets Start to this list at every
sign-in.

## Good to know

- **Made for Windows 11 Pro and up.** `(policy)` settings are Group Policies,
  which Windows Home ignores. On Home they are still written and may count as
  changed in the summary, but they do nothing.
- **`HKCU` settings apply to the account that runs Setup.** Another account on
  the same PC needs its own run.
- **OneDrive is only removed when nothing lives in it.** If Desktop or Documents
  are backed up into OneDrive, Setup refuses and tells you how to stop that.
- **Store apps** (WhatsApp, Spotify, Twinkle Tray) can fail when you are not
  signed in to the Microsoft Store. Sign in there and run Setup again.
- **Removed Store apps can be reinstalled** from the Store at any time.
- **Logs** go to `Documents\WindowsInstallAutomation\logs`, one per run,
  wherever Setup ran from. They are in the Documents of the account that
  approved the admin prompt, and sync along when Documents is backed up to
  OneDrive. If Setup cannot write there (Controlled folder access can block
  it), it says so and uses `C:\WindowsInstallAutomation` instead; `-Restore`
  reads both. The summary always shows where the log is. The black
  background picture lives in that folder too, next to a `README.txt`. Delete
  the folder whenever you like; only `-Restore` needs the logs.
- **Registry keys move between Windows releases.** If a setting stops working
  after a feature update, capture it again rather than taking a key from a
  forum post.

## Test it in Windows Sandbox

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All
```

Restart, open Windows Sandbox, copy the repo in and run `Setup.cmd`. You get a
clean Windows in seconds and throw it away afterwards. Sandbox has no Microsoft
Store, so Store apps fail there.
