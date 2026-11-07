# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

<#
.SYNOPSIS
  Links themes/<Name> into %APPDATA%\spicetify\Themes via a directory junction,
  selects it in Spicetify and runs 'spicetify apply'. -Watch then live-reloads.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Name,
    [string]$Scheme = '',
    [switch]$Watch
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'lib\Common.ps1')
    Assert-ThemeName $Name

    $themeDir = Join-Path $script:ThemesDir $Name
    if (-not (Test-Path -LiteralPath $themeDir -PathType Container)) { throw "themes/$Name does not exist." }
    $ini = Join-Path $themeDir 'color.ini'
    if (-not (Test-Path -LiteralPath $ini -PathType Leaf)) { throw "themes/$Name/color.ini is missing." }

    $schemes = @((Read-ColorIni -Path $ini).Keys)
    if ($schemes.Count -eq 0) { throw "themes/$Name/color.ini has no [Scheme] sections." }
    if ($Scheme -eq '') { $Scheme = $schemes[0] }
    if ($schemes -notcontains $Scheme) { throw "Scheme '$Scheme' not found. Available: $($schemes -join ', ')" }

    if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) { throw "'spicetify' is not on PATH." }

    $spiceThemes = Join-Path $env:APPDATA 'spicetify\Themes'
    if (-not (Test-Path -LiteralPath $spiceThemes)) { New-Item -ItemType Directory -Path $spiceThemes | Out-Null }
    $link = Join-Path $spiceThemes $Name

    if (Test-Path -LiteralPath $link) {
        $item = Get-Item -LiteralPath $link -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            # rmdir on a junction removes only the link, never the target's contents.
            Invoke-Native -FilePath 'cmd.exe' -ArgumentList @('/c', 'rmdir', $link)
        } else {
            throw "$link is a real folder, not a junction. Move or delete it yourself; this script will not overwrite it."
        }
    }
    New-Item -ItemType Junction -Path $link -Target $themeDir | Out-Null
    Write-Host "Linked $link -> $themeDir"

    Invoke-Native -FilePath 'spicetify' -ArgumentList @('config', 'current_theme', $Name, 'color_scheme', $Scheme, 'inject_css', '1', 'replace_colors', '1')
    Invoke-Native -FilePath 'spicetify' -ArgumentList @('apply')
    Write-Host "Applied $Name ($Scheme)." -ForegroundColor Green

    if ($Watch) {
        Write-Host 'Watching for changes (Ctrl+C to stop)...'
        Invoke-Native -FilePath 'spicetify' -ArgumentList @('watch', '-s')
    }
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
