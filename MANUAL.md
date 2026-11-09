# Still to do by hand

Things a script should not do: anything needing a password, a licence key, or a
decision. `Setup.ps1` prints every unticked line below when it finishes.

Copy this file per machine if you want to actually tick things off, or just use
it as a read-through checklist.

## Sign-ins

- [ ] Windows: sign in / link Microsoft account, or keep it local
- [ ] Browser: sign in and let the profile sync
- [ ] Bitwarden or other password manager -- do this early, the rest gets easier
- [ ] Spotify, Discord, WhatsApp + Signal (link from phone), Notion, Plex, Steam / GOG / EA / Ubisoft

## Microsoft Store

- [ ] Sign in to the Store once. WhatsApp, Spotify and Twinkle Tray come from
      the Store, so they can fail on a fresh machine until an account is
      signed in. Re-run `.\Setup.ps1 -Profile Mine -Only apps` afterwards.

## Licences

- [ ] Microsoft 365 -- open Word and sign in with the account that holds the licence
- [ ] Visual Studio Community 2026 -- sign in with a Microsoft account within 30 days

## Security

- [ ] Turn on BitLocker and **save the recovery key somewhere off this machine**
- [ ] Check Windows Update and install everything, then reboot and check again
- [ ] Set up Windows Hello / PIN
- [ ] Confirm Windows Security is not reporting anything

## Hardware and per-machine

- [ ] GPU drivers (nvidia / amd -- winget has these but a clean install is better)
- [ ] Chipset drivers from the motherboard or laptop vendor
- [ ] Monitor layout, refresh rate, scaling
- [ ] Audio devices, default output
- [ ] Printer
- [ ] Power plan -- laptops especially

## Things worth checking after a run

- [ ] Explorer shows file extensions
- [ ] F1 does nothing in Explorer
- [ ] Start menu search returns no web results
- [ ] Win+W does nothing after a reboot (widgets fully off)
- [ ] Copilot+ PC: after a reboot, Settings > Privacy & security has no "Recall & snapshots"
- [ ] HWiNFO starts on login in sensors-only mode without a UAC prompt

## Not worth automating

Kept here so I stop re-deciding it every time:

- **Windows Update** -- it reboots, it retries, it is fine on its own.
- **Anything with 2FA.** No exceptions.
- **Restoring data.** Different every time; a script would be more dangerous than useful.
