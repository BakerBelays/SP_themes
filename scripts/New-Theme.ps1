# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

<#
.SYNOPSIS
  Creates themes/<Name>/ from template/ and fills theme.json and README.md.
.EXAMPLE
  .\scripts\New-Theme.ps1 -Name OceanNight -Description "Deep blue with coral accents" -Tags dark,blue
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Description = '',
    [string[]]$Tags = @(),
    [string]$Author = '',
    [string]$AuthorUrl = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'lib\Common.ps1')
    Assert-ThemeName $Name
    if ($Author -eq '') { $Author = "$script:DefaultUser (generated with Claude)" }
    if ($AuthorUrl -eq '') { $AuthorUrl = "https://github.com/$script:DefaultUser" }

    $dest = Join-Path $script:ThemesDir $Name
    if (Test-Path -LiteralPath $dest) { throw "themes/$Name already exists. Pick another name or edit the existing theme." }
    if (-not (Test-Path -LiteralPath $script:TemplateDir)) { throw "template/ folder not found at $script:TemplateDir" }
    if (-not (Test-Path -LiteralPath $script:ThemesDir)) { New-Item -ItemType Directory -Path $script:ThemesDir | Out-Null }

    Copy-Item -LiteralPath $script:TemplateDir -Destination $dest -Recurse

    if ($Description.Trim() -eq '') { $Description = "$Name, a Spicetify theme." }
    $tagList = @($Tags | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

    $meta = [ordered]@{
        name        = $Name
        description = $Description.Trim()
        tags        = $tagList
        authors     = @([ordered]@{ name = $Author; url = $AuthorUrl })
    }
    Write-Utf8NoBom -Path (Join-Path $dest 'theme.json') -Text ((ConvertTo-StudioJson -Value $meta) + "`n")

    $schemes = @((Read-ColorIni -Path (Join-Path $dest 'color.ini')).Keys)
    $readmePath = Join-Path $dest 'README.md'
    $readme = Read-Utf8 $readmePath
    $readme = $readme.Replace('{{NAME}}', $Name).Replace('{{DESCRIPTION}}', $Description.Trim())
    $readme = $readme.Replace('{{SCHEMES}}', (($schemes | ForEach-Object { "- ``$_``" }) -join "`n"))
    $readme = $readme.Replace('{{USER}}', $script:DefaultUser).Replace('{{REPO}}', $script:DefaultRepo)
    Write-Utf8NoBom -Path $readmePath -Text $readme

    Write-Host "Created themes/$Name (schemes: $($schemes -join ', '))" -ForegroundColor Green
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
