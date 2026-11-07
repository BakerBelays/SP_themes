# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

<#
.SYNOPSIS
  Validates all themes, rebuilds manifest.json, commits and pushes to GitHub main.
  Never force-pushes and never rewrites history.
.PARAMETER Yes
  Pre-answers the "type yes" prompt for creating/linking the GitHub repo. Only pass
  this after the user has explicitly typed yes for that exact action.
#>
[CmdletBinding()]
param(
    [string]$Message = '',
    [string]$GitHubUser = '',
    [string]$Repo = '',
    [switch]$Yes
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'lib\Common.ps1')
    if ($GitHubUser -eq '') { $GitHubUser = $script:DefaultUser }
    if ($Repo -eq '') { $Repo = $script:DefaultRepo }
    $full = "$GitHubUser/$Repo"
    Set-Location -LiteralPath $script:StudioRoot

    & (Join-Path $PSScriptRoot 'Test-Theme.ps1') -All
    if ($LASTEXITCODE -ne 0) { throw 'Validation failed; nothing was published.' }
    & (Join-Path $PSScriptRoot 'Build-Manifest.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Build-Manifest failed; nothing was published.' }

    $branch = ((Invoke-Native git @('rev-parse', '--abbrev-ref', 'HEAD') -Capture).Output -join '').Trim()
    if ($branch -ne 'main') { throw "Current branch is '$branch'; switch to 'main' before publishing." }

    # Commit
    Invoke-Native git @('add', '-A')
    $staged = @((Invoke-Native git @('diff', '--cached', '--name-only') -Capture).Output | Where-Object { $_ -ne '' })
    if ($staged.Count -gt 0) {
        if ($Message -eq '') {
            $changed = @($staged | Where-Object { $_ -match '^themes/([^/]+)/' } | ForEach-Object { ($_ -split '/')[1] } | Sort-Object -Unique)
            if ($changed.Count -gt 0) { $Message = "Update themes: $($changed -join ', ')" } else { $Message = 'Update theme studio' }
        }
        Invoke-Native git @('commit', '-m', $Message)
    } else {
        Write-Host 'No changes to commit.'
    }

    # Remote
    $remotes = @((Invoke-Native git @('remote') -Capture).Output)
    if ($remotes -notcontains 'origin') {
        $exists = (Invoke-Native gh @('repo', 'view', $full, '--json', 'name') -Capture -AllowFailure).ExitCode -eq 0
        if ($exists) {
            $plan = "GitHub repo $full already exists. I will run: git remote add origin https://github.com/$full.git"
        } else {
            $plan = "No 'origin' remote. I will run: gh repo create $full --public --source . --remote origin --push"
        }
        Write-Host $plan -ForegroundColor Yellow
        if (-not $Yes) {
            $answer = Read-Host 'Type yes to continue'
            if ($answer -ne 'yes') { throw 'Aborted by user; nothing was pushed.' }
        }
        if ($exists) {
            Invoke-Native git @('remote', 'add', 'origin', "https://github.com/$full.git")
        } else {
            Invoke-Native gh @('repo', 'create', $full, '--public', '--source', '.', '--remote', 'origin', '--push')
        }
    }

    Invoke-Native gh @('repo', 'edit', $full, '--add-topic', 'spicetify-themes')

    $push = Invoke-Native git @('push', 'origin', 'main') -Capture -AllowFailure
    $push.Output + $push.Errors | ForEach-Object { Write-Host $_ }
    if ($push.ExitCode -ne 0) {
        throw "git push failed. If the remote has newer commits, run 'git pull --no-rebase origin main', resolve, and publish again. Never force-push."
    }

    Write-Host "Published to https://github.com/$full" -ForegroundColor Green
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
