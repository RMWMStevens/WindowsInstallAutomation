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
  `(unchecked)`: flip the switch by hand once and check. Never from blog posts.
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
  results are wanted there). On my own PCs it is off, in privacy-personal.psd1.
- Not worth automating: Windows Update, anything with 2FA, restoring data.
- A MANUAL.md checklist; it was too specific to me.

## Background

- Widgets: Windows blocks scripts from writing its policy (AllowNewsAndInterests,
  "unauthorized operation"), so remove.psd1 removes the app instead.
- Search without WebView2 (feature 1694661260), tested Nov 2026 on build 26300:
  Search's 6 WebView2 processes (214 MB) went away, SearchHost grew from 58 MB to
  117-197 MB. If search breaks after an update, suspect this first.
- Sponsored apps count as sponsored only when provisioned (Windows or the PC
  maker put them there). Installed but not provisioned: someone chose it, it stays.
- With Copilot and Recall removed, the Copilot key opens Windows Search.
