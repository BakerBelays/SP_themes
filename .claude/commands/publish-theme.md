---
description: Validate all themes, rebuild manifest.json and push to GitHub for Spicetify Marketplace
argument-hint: [commit message]
model: claude-haiku-5-5
---

Optional commit message: `$ARGUMENTS`

1. Run from the repo root:
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Publish-Themes.ps1` (add `-Message "<message>"` if a message was given).
   - If it stops at "Type yes to continue", show the user the planned action it printed and ask them. Re-run with `-Yes` only if they reply yes.
   - If validation fails, report each problem (file:line) and stop. Do not work around it. Never publish a theme without `preview.png`.
   - If the push is rejected, report it. Never force-push and never rewrite history.
2. On success, report the repo URL (https://github.com/BakerBelays/SP_themes) and the themes included in `manifest.json`.
3. Tell the user that a new Marketplace listing can take a while to appear, because Marketplace finds themes through GitHub's topic search (`spicetify-themes`), which updates with a delay.
