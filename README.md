# WindowsInstallAutomation

Sets up a fresh Windows 11 install the way I want it: installs software, removes
the pre-installed junk, and applies the registry tweaks I otherwise redo by hand
every time.

Safe to run more than once. Every step checks the current state first, so a
second run only fixes what has drifted.

## Use it

On a fresh machine, in PowerShell:

```powershell
git clone https://github.com/RMWMStevens/WindowsInstallAutomation
cd WindowsInstallAutomation
.\Setup.ps1 -Profile Mine -WhatIf     # see what it would do
.\Setup.ps1 -Profile Mine             # do it
```

No git yet? Download the repo as a zip, unblock it, and run the same thing:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
Get-ChildItem -Recurse | Unblock-File
.\Setup.ps1 -Profile Mine -WhatIf
```

It asks once to restart elevated. Machine-wide tweaks and scheduled tasks are
skipped if you say no; everything else still runs.

### Profiles

| Profile | Tags | For |
|---|---|---|
| `Mine` | core, comms, media, personal, dev, gaming | my own machines |
| `Friend` | core, comms, media, nogaming | someone else's machine -- no dev tools, no personal apps |
| `Minimal` | core | just the essentials |
| `MediaTools` | mediatools | add-on, run on its own: ripping / editing tools (Audacity, HandBrake, MKVToolNix, MakeMKV, EAC, XnConvert) |

OneDrive and Teams are removed by every profile. Microsoft 365 is installed
through the Office Deployment Tool with `data\office.xml`, which leaves both out.

### Useful switches

```powershell
.\Setup.ps1 -Profile Mine -WhatIf          # dry run, changes nothing
.\Setup.ps1 -Profile Mine -Only registry   # just the tweaks
.\Setup.ps1 -Profile Mine -Skip apps       # everything except installs
.\Setup.ps1 -Tags core,dev                 # ignore profiles, pick tags
```

Every run writes a log to `logs\`. The summary at the end lists what changed and
what failed, so you never have to scroll back through winget output.

## Layout

```
Setup.ps1              entry point -- profiles, elevation, logging, summary
lib/Common.psm1        shared helpers (idempotent registry write, winget install, logging)
modules/
  10-apps.ps1          install from data/apps.psd1
  15-debloat.ps1       remove from data/debloat.psd1
  20-registry.ps1      apply data/tweaks.psd1
  30-app-config.ps1    import data/reg/*.reg, copy data/config/*, register data/tasks/*.xml
data/                  all the lists -- this is the only part you edit day to day
tools/
  Capture-Settings.ps1 export settings from a configured machine INTO this repo
  Test-AppIds.ps1      check every package ID still resolves in winget
MANUAL.md              the checklist of things a script must not do
legacy/                the original .bat scripts
```

The modules are generic. Adding an app, a tweak or a config file means editing a
`data\*.psd1` file, not writing code.

## Adding things

### An app

One line in `data\apps.psd1`:

```powershell
@{ Id = 'Mozilla.Firefox'; Name = 'Firefox'; Tags = @('core') }
```

Get the exact ID with `winget search firefox`. Use the ID, never the name --
names are not stable. For a Store-only app, add `Source = 'msstore'`. Do the
same when the copy you already have came from the Store: winget sees the Store
build and the winget build as two different apps and installs the second one
next to the first.

IDs get renamed, and a renamed ID fails silently -- the app just never installs.
Check them all after a Windows release, or whenever an app is mysteriously
missing:

```powershell
.\tools\Test-AppIds.ps1
```

This is not hypothetical. The first run of this check found two dead IDs that had
been quietly failing in the old batch scripts.

### A registry tweak

**Do not copy a registry path out of a blog post.** Change the setting by hand
first, confirm it does what you want, then export it:

```powershell
.\tools\Capture-Settings.ps1 -RegKey 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
```

Open the resulting `.reg`, cut it down to the one value you changed, and add it
to `data\tweaks.psd1` with a `Why` line saying what it is for. The `Why` is not
decoration -- in two years it is the only thing that will tell you whether a
tweak that stopped working is still worth fixing.

### An app's config

```powershell
.\tools\Capture-Settings.ps1 -File 'C:\Program Files\HWiNFO64\HWiNFO64.INI'
```

It copies the file into `data\config\` and prints the `data\files.psd1` entry to
paste in. Check the file for licence keys or hardware IDs before committing.

### An app that must autostart with admin rights

Do not use a `Run` registry key -- it triggers UAC on every login. Build the task
in Task Scheduler once (trigger: at log on, tick "Run with highest privileges"),
then:

```powershell
.\tools\Capture-Settings.ps1 -ScheduledTask 'HWiNFO sensors'
```

Edit the `<UserId>` in the XML to `S-1-5-32-544` so it also registers on another
machine. `30-app-config.ps1` picks up everything in `data\tasks\`.

## Test it in Windows Sandbox

Do this before running anything on someone else's machine:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All
```

Reboot, start Windows Sandbox, copy the repo in, run it. You get a clean Windows
in about ten seconds and can throw it away when it breaks. Note that Sandbox has
no Microsoft Store, so a few winget packages will fail there but work on a real
machine.

## A warning about registry tweaks

These keys move between Windows releases. The Start-menu web-search one has
already changed twice. `20-registry.ps1` prints the build number it ran on; if a
tweak quietly stops working after a feature update, re-capture it rather than
piling on another key from a forum post.

Tweaks under `HKCU` apply to whoever runs the script. A second account on the
same machine does not inherit them -- run it again as that user.
