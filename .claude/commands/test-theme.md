---
description: Install a theme into Spicetify and live-reload it while editing
argument-hint: <ThemeName> [Scheme]
model: claude-haiku-5-5
---

Arguments: `$ARGUMENTS`. The first word is the theme name and the optional second word is the scheme.

1. Run from the repo root, in the background because watch mode never exits:
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-Theme.ps1 -Name <Name> [-Scheme <Scheme>] -Watch`
2. Report whether the junction and `spicetify apply` succeeded. If it failed, show the error output.
3. Tell the user that edits to `themes/<Name>/color.ini` and `user.css` now reload in Spotify automatically, and that they can stop watching by asking you or pressing Ctrl+C in their own terminal.
