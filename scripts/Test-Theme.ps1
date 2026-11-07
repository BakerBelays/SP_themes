# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

<#
.SYNOPSIS
  Validates one theme (-Name) or every theme (-All). Exits 1 on any failure.
.PARAMETER SkipPreview
  Do not fail when preview.png is missing (used while a theme is still being designed).
#>
[CmdletBinding(DefaultParameterSetName = 'One')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'One', Position = 0)][string]$Name,
    [Parameter(Mandatory = $true, ParameterSetName = 'All')][switch]$All,
    [switch]$SkipPreview
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-CssBraces {
    param([string]$Path, [string]$Rel, [System.Collections.Generic.List[string]]$Failures)
    $text = Read-Utf8 $Path
    $stack = New-Object System.Collections.Generic.Stack[int]
    $line = 1; $i = 0; $n = $text.Length
    $inComment = $false; $quote = [char]0; $commentLine = 0
    while ($i -lt $n) {
        $c = $text[$i]
        if ($c -eq "`n") { $line++ }
        if ($inComment) {
            if ($c -eq '*' -and $i + 1 -lt $n -and $text[$i + 1] -eq '/') { $inComment = $false; $i++ }
        } elseif ($quote -ne [char]0) {
            if ($c -eq '\') { $i++ } elseif ($c -eq $quote) { $quote = [char]0 }
        } elseif ($c -eq '/' -and $i + 1 -lt $n -and $text[$i + 1] -eq '*') {
            $inComment = $true; $commentLine = $line; $i++
        } elseif ($c -eq '"' -or $c -eq "'") {
            $quote = $c
        } elseif ($c -eq '{') {
            $stack.Push($line)
        } elseif ($c -eq '}') {
            if ($stack.Count -eq 0) { $Failures.Add("${Rel}:${line}: unmatched '}'") } else { [void]$stack.Pop() }
        }
        $i++
    }
    if ($inComment) { $Failures.Add("${Rel}:${commentLine}: unterminated /* comment") }
    foreach ($open in $stack) { $Failures.Add("${Rel}:${open}: '{' is never closed") }
}

function Test-OneTheme {
    param([string]$ThemeName, [switch]$SkipPreview)
    $failures = New-Object System.Collections.Generic.List[string]
    $dir = Join-Path $script:ThemesDir $ThemeName
    $rel = "themes/$ThemeName"
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        $failures.Add("${rel}: theme folder does not exist")
        return , $failures
    }
    if ($ThemeName -notmatch $script:NamePattern) { $failures.Add("${rel}: folder name must match $script:NamePattern") }

    $required = @('color.ini', 'user.css', 'theme.json', 'README.md')
    if (-not $SkipPreview) { $required += 'preview.png' }
    foreach ($f in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $dir $f) -PathType Leaf)) { $failures.Add("$rel/${f}: missing") }
    }

    # preview.png must really be a PNG
    $png = Join-Path $dir 'preview.png'
    if (Test-Path -LiteralPath $png -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($png)
        $sig = [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        $ok = $bytes.Length -ge 8
        for ($k = 0; $ok -and $k -lt 8; $k++) { if ($bytes[$k] -ne $sig[$k]) { $ok = $false } }
        if (-not $ok) { $failures.Add("$rel/preview.png:1: file is not a PNG image") }
    }

    # color.ini
    $ini = Join-Path $dir 'color.ini'
    if (Test-Path -LiteralPath $ini -PathType Leaf) {
        $stray = New-Object System.Collections.Generic.List[object]
        $sections = Read-ColorIni -Path $ini -Stray $stray
        foreach ($s in $stray) { $failures.Add("$rel/color.ini:$($s.Line): line is outside any [Scheme] section or is not 'key = value'") }
        if ($sections.Count -eq 0) { $failures.Add("$rel/color.ini:1: no [Scheme] sections found") }
        foreach ($sec in $sections.Keys) {
            $entries = $sections[$sec]
            $seen = @{}
            foreach ($e in $entries) {
                if ($seen.ContainsKey($e.Key)) { $failures.Add("$rel/color.ini:$($e.Line): [$sec] duplicate key '$($e.Key)'") }
                $seen[$e.Key] = $true
                if ($e.Value -notmatch '^[0-9A-Fa-f]{6}$') {
                    $failures.Add("$rel/color.ini:$($e.Line): [$sec] $($e.Key) = '$($e.Value)' is not a 6-digit hex color (no #)")
                }
            }
            foreach ($k in $script:StandardKeys) {
                if (-not $seen.ContainsKey($k)) { $failures.Add("$rel/color.ini: [$sec] missing standard key '$k'") }
            }
        }
    }

    # theme.json
    $tj = Join-Path $dir 'theme.json'
    if (Test-Path -LiteralPath $tj -PathType Leaf) {
        $meta = $null
        try { $meta = (Read-Utf8 $tj) | ConvertFrom-Json } catch { $failures.Add("$rel/theme.json:1: invalid JSON: $($_.Exception.Message)") }
        if ($null -ne $meta) {
            foreach ($field in @('name', 'description')) {
                $v = Get-JsonProp $meta $field
                if ($null -eq $v -or ([string]$v).Trim() -eq '') { $failures.Add("$rel/theme.json:1: '$field' is missing or empty") }
            }
        }
    }

    # user.css
    $css = Join-Path $dir 'user.css'
    if (Test-Path -LiteralPath $css -PathType Leaf) { Test-CssBraces -Path $css -Rel "$rel/user.css" -Failures $failures }

    return , $failures
}

try {
    . (Join-Path $PSScriptRoot 'lib\Common.ps1')
    if ($All) {
        if (-not (Test-Path -LiteralPath $script:ThemesDir)) { throw 'No themes/ folder.' }
        $names = @(Get-ChildItem -LiteralPath $script:ThemesDir -Directory | Sort-Object Name | ForEach-Object { $_.Name })
        if ($names.Count -eq 0) { throw 'No themes found in themes/.' }
    } else {
        $names = @($Name)
    }

    $total = 0
    foreach ($t in $names) {
        $f = Test-OneTheme -ThemeName $t -SkipPreview:$SkipPreview
        if ($f.Count -eq 0) {
            Write-Host "PASS $t" -ForegroundColor Green
        } else {
            Write-Host "FAIL $t ($($f.Count) problem(s))" -ForegroundColor Red
            foreach ($msg in $f) { Write-Host "  $msg" }
            $total += $f.Count
        }
    }
    if ($total -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
