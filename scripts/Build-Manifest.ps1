# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

<#
.SYNOPSIS
  Generates the root manifest.json (Spicetify Marketplace format) from themes/*/theme.json.
  Never hand-edit manifest.json; edit theme.json and re-run this.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'lib\Common.ps1')
    $entries = New-Object System.Collections.Generic.List[object]
    if (Test-Path -LiteralPath $script:ThemesDir) {
        foreach ($dir in (Get-ChildItem -LiteralPath $script:ThemesDir -Directory)) {
            $folder = $dir.Name
            $tj = Join-Path $dir.FullName 'theme.json'
            if (-not (Test-Path -LiteralPath $tj -PathType Leaf)) { throw "themes/$folder/theme.json is missing." }
            $meta = (Read-Utf8 $tj) | ConvertFrom-Json
            $name = [string](Get-JsonProp $meta 'name')
            $desc = [string](Get-JsonProp $meta 'description')
            if ($name.Trim() -eq '') { throw "themes/$folder/theme.json: 'name' is empty." }

            $base = "themes/$folder"
            $e = [ordered]@{
                name        = $name
                description = $desc
                preview     = "$base/preview.png"
                readme      = "$base/README.md"
                usercss     = "$base/user.css"
                schemes     = "$base/color.ini"
                branch      = 'main'
            }
            $authors = Get-JsonProp $meta 'authors'
            if ($null -ne $authors -and @($authors).Count -gt 0) {
                $e['authors'] = @(foreach ($a in @($authors)) {
                    [ordered]@{ name = [string](Get-JsonProp $a 'name'); url = [string](Get-JsonProp $a 'url') }
                })
            }
            $tags = Get-JsonProp $meta 'tags'
            if ($null -ne $tags -and @($tags).Count -gt 0) { $e['tags'] = @(@($tags) | ForEach-Object { [string]$_ }) }
            $include = Get-JsonProp $meta 'include'
            if ($null -ne $include -and @($include).Count -gt 0) {
                foreach ($u in @($include)) {
                    if ([string]$u -match 'raw\.githubusercontent\.com') {
                        throw "themes/$folder/theme.json: include URL '$u' uses raw.githubusercontent.com, which Marketplace cannot load. Host it on GitHub Pages."
                    }
                }
                $e['include'] = @(@($include) | ForEach-Object { [string]$_ })
            }
            $entries.Add($e)
        }
    }

    $sorted = @($entries | Sort-Object -Property @{ Expression = { $_['name'] } })
    $json = ConvertTo-StudioJson -Value $sorted
    $out = Join-Path $script:StudioRoot 'manifest.json'
    Write-Utf8NoBom -Path $out -Text ($json + "`n")
    Write-Host "Wrote manifest.json with $($sorted.Count) theme(s)." -ForegroundColor Green
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
