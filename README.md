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

   | Question                                                                                                       | Default |
   | -------------------------------------------------------------------------------------------------------------- | ------- |
   | New name for this PC? Only asked while it still has a made-up name like `DESKTOP-1A2B3C4`.                     | keep    |
   | Apply the general tweaks (`data\tweaks.psd1`)? Sensible on any PC.                                             | yes     |
   | Apply the privacy settings (`data\privacy.psd1`)?                                                              | yes     |
   | Update all installed apps afterwards (`winget upgrade --all`)?                                                 | yes     |
   | Remove the Xbox apps too? Say no on a gaming PC -- games that sign in with Xbox need them.                     | no      |
   | Apply my personal preferences and Start pins? Say no on someone else's PC. Pins show after signing out and in. | no      |
   | Plain black background on the desktop and the lock / sign-in screen?                                           | no      |

   After that it runs on its own: a restore point first, then it removes the
   bloat, installs your apps, updates what is left, and applies what you said
   yes to.
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

To skip the menu: `Setup.cmd -Apps core,social` (or `-Apps all`, `-Apps none`).

**Microsoft 365** is a big download and needs a licence, so picking it asks one
more question straight after the menu -- unless it is already installed, then
it is simply skipped. It installs last, after the quicker apps. Setup only
installs it; activating it is up to you (sign in with the account that holds
the licence).

## Dry run

```
Setup.cmd -WhatIf
```

Shows everything it would install, remove and set, and changes nothing.

## What is where

```
Bootstrap.ps1          the one-liner's target: downloads the repo, starts Setup.ps1
Setup.cmd              same, from a downloaded copy: asks for admin, runs Setup.ps1
Setup.ps1              the whole run, top to bottom -- read this to see what happens
data\apps.psd1         the apps you can pick
data\remove.psd1       what gets removed, every run (Xbox list only if you say so)
data\tweaks.psd1       general tweaks, sensible on any PC: no nags, no web search, Edge out of memory
data\personal.psd1     my own preferences: hidden files, no recent files, Start lists
data\privacy.psd1      what Windows and Office send to Microsoft, and the AI features
data\start-pins.json   your Start pins (exported with Export-StartLayout), applied with personal.psd1
data\office.xml        how Microsoft 365 is installed (Word, Excel, PowerPoint only)
tools\Helpers.ps1      the functions Setup.ps1 calls
tools\Test-AppIds.ps1  checks every app ID still exists in winget
MANUAL.md              what is left to do by hand after Setup
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
taste, or `data\privacy.psd1` if it limits what is sent to Microsoft. Do not
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
  `README.txt` saying what the folder is. Delete the folder whenever you like.
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
