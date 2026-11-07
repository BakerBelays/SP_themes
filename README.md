# SP_themes

Spicetify themes by [BakerBelays](https://github.com/BakerBelays), available in the [Spicetify Marketplace](https://github.com/spicetify/marketplace).

## Themes

Each theme lives in `themes/<Name>/` with its own README, screenshot and color schemes.

| Theme | Folder |
|---|---|
| SolarizedDark | [themes/SolarizedDark](themes/SolarizedDark) |
| StudioSample | [themes/StudioSample](themes/StudioSample) |

## Install

**Marketplace:** open Marketplace in Spotify, go to **Themes**, search for the theme name, and click **Install**.

**Manual:** copy `themes/<Name>` to `%APPDATA%\spicetify\Themes\<Name>` (Windows) or `~/.config/spicetify/Themes/<Name>`, then run:

```
spicetify config current_theme <Name> color_scheme <Scheme>
spicetify apply
```

## Making themes (Windows, PowerShell)

This repo is a small theme studio. With [Claude Code](https://claude.com/claude-code) open in this folder, use these commands:

- `/new-theme <Name> <description>` creates, designs, validates and installs a theme.
- `/test-theme <Name>` live-reloads a theme while you edit it.
- `/publish-theme` validates everything, regenerates `manifest.json` and pushes.

You can also run the scripts directly:

```powershell
.\scripts\New-Theme.ps1 -Name MyTheme -Description "..." -Tags dark
.\scripts\Test-Theme.ps1 -Name MyTheme
.\scripts\Install-Theme.ps1 -Name MyTheme -Watch
.\scripts\Publish-Themes.ps1
```

`manifest.json` is generated from each theme's `theme.json`. Do not edit it by hand.

## License

This code was generated with a large language model. This code is free.
It is necessarily probabilistic and its results unreliable.
Keep it far from critical infrastructure. Licensed under the GNU GPL v3: https://www.gnu.org/licenses/gpl-3.0.html
