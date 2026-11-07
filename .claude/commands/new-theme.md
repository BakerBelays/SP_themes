---
description: Create, design, validate and install a new Spicetify theme
argument-hint: <ThemeName> <plain-language description of the look>
model: claude-sonnet-5-5
---

Create a new Spicetify theme from: `$ARGUMENTS`

The first word is the theme name (must match `^[A-Za-z0-9_-]+$`). Everything after it describes the look. If no description is given, ask for one before continuing.

1. Run from the repo root:
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/New-Theme.ps1 -Name <Name> -Description "<one-sentence summary>" -Tags <comma,separated,tags>`
   If it fails because the folder exists, stop and ask whether to edit the existing theme instead.
2. Design `themes/<Name>/color.ini` to match the description:
   - Keep the header comment. Use one `[Section]` per scheme (at least one dark or light variant; add more if the description implies them). Give schemes short names without spaces.
   - Every section must contain all 15 standard keys: text, subtext, main, sidebar, player, card, shadow, selected-row, button, button-active, button-disabled, tab-active, notification, notification-error, misc.
   - Values are 6-digit hex with no `#` and no inline comments.
   - Keep text/main contrast at least 7:1 and subtext/main at least 4.5:1.
3. Write `themes/<Name>/user.css` to match the description. Use only `var(--spice-*)` and `rgba(var(--spice-rgb-*), a)` for colors. Prefer stable selectors (`data-testid`, `aria-label`, `.Root__*`, `.main-*`, `.x-*`) over hashed class names. Comment every section.
4. Update `themes/<Name>/README.md`: description and the scheme list, which must match the color.ini sections.
5. Validate: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-Theme.ps1 -Name <Name> -SkipPreview`. Fix every reported problem and re-run until it passes.
6. Install: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-Theme.ps1 -Name <Name>`.
7. Tell the user to look at Spotify, take a screenshot of the full window, and save it as `themes/<Name>/preview.png`. Mention `/test-theme <Name>` for live reload while tweaking, and `/publish-theme` once the preview exists.
