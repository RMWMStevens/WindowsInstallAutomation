# WindowsInstallAutomation

Sets up a fresh Windows 11 (Education) install the way I want it: installs the
apps I pick, removes the pre-installed bloat, and applies my registry settings.

Run it as often as you like. Every step checks first and only changes what is
different, so a second run just removes whatever has come back -- after a
Windows update, say.

## Fresh install, in order

1. Install Windows 11 Education and sign in.
2. Settings > Windows Update: install everything, restart, repeat until there
   is nothing left.
3. Open PowerShell (Start > type `powershell`) and paste:

   ```powershell
   irm https://raw.githubusercontent.com/RMWMStevens/WindowsInstallAutomation/main/Bootstrap.ps1 | iex
   ```

   It downloads the latest version from GitHub into a temp folder and starts
   Setup in a new admin window. Say yes to the admin prompt.
4. Pick your apps (below). Setup then removes the bloat and applies the settings.
5. Read `MANUAL.md` and work through what is left to do by hand.

No internet in PowerShell, or want a local copy? Download the repo (**Code >
Download ZIP**), extract it and double-click **`Setup.cmd`** instead.

Arguments work with the one-liner too, in this form:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/RMWMStevens/WindowsInstallAutomation/main/Bootstrap.ps1))) -WhatIf
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

| You type | You get |
|---|---|
| `all` | everything |
| `core social tools` | those three groups |
| `1-5 9 12` | those numbers |
| *(just Enter)* | no apps -- only the removals and settings run |

Groups: Core, Social, Tools, Media, Personal, Dev, Gaming, MediaTools.

To skip the menu: `Setup.cmd -Apps core,social` (or `-Apps all`, `-Apps none`).

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
data\remove.psd1       what gets removed, every run
data\tweaks.psd1       registry settings, every run
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
changed (regedit, or Process Monitor), then add a block to `data\tweaks.psd1`
with a `Why` line. Do not copy keys from blog posts: they are often wrong or out
of date. Policies Microsoft documents are the exception -- note where in `Why`.

## Things to know

- **Registry keys move between Windows releases.** If a setting quietly stops
  working after a feature update, re-capture it rather than adding another key
  from a forum post.
- **`HKCU` settings apply to the account that runs Setup.** Another account on
  the same PC needs its own run.
- **OneDrive is only removed when nothing lives in it.** If Desktop or Documents
  are backed up into OneDrive, Setup refuses and tells you how to stop that.
- **Removed Store apps can be reinstalled** from the Store at any time.

## Test it in Windows Sandbox

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All
```

Restart, open Windows Sandbox, copy the repo in, run `Setup.cmd`. You get a clean
Windows in seconds and throw it away afterwards. Sandbox has no Microsoft Store,
so the Store apps fail there but work on a real PC.
