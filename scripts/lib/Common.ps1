# This code was generated with a large language model. This code is free.
# It is necessarily probabilistic and its results unreliable.
# Keep it far from critical infrastructure. Licensed under the GNU GPL v3.

# Shared helpers dot-sourced by the scripts in ..\  (not run directly).
# Must stay ASCII-only: Windows PowerShell 5.1 reads BOM-less files as ANSI.

Set-StrictMode -Version Latest

# $MyInvocation.MyCommand.Path is this file even when dot-sourced ($PSCommandPath is the caller).
$script:StudioRoot      = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$script:ThemesDir       = Join-Path $script:StudioRoot 'themes'
$script:TemplateDir     = Join-Path $script:StudioRoot 'template'
$script:StandardKeys    = @('text', 'subtext', 'main', 'sidebar', 'player', 'card', 'shadow',
                            'selected-row', 'button', 'button-active', 'button-disabled',
                            'tab-active', 'notification', 'notification-error', 'misc')
$script:NamePattern     = '^[A-Za-z0-9_-]+$'
$script:DefaultUser     = 'BakerBelays'
$script:DefaultRepo     = 'SP_themes'

function Write-Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Assert-ThemeName {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ($Name -notmatch $script:NamePattern) {
        throw "Theme name '$Name' is invalid. Use only letters, digits, '_' and '-'."
    }
}

# Runs a native executable without PowerShell 5.1 turning stderr into terminating errors.
# Without -Capture, output streams to the console and nothing is returned.
# With -Capture, returns [pscustomobject]@{ ExitCode; Output (stdout lines); Errors (stderr lines) }.
# Throws on non-zero exit unless -AllowFailure.
function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [switch]$Capture,
        [switch]$AllowFailure
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = New-Object System.Collections.Generic.List[string]
    $err = New-Object System.Collections.Generic.List[string]
    try {
        if ($Capture) {
            & $FilePath @ArgumentList 2>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) { $err.Add($_.Exception.Message) }
                else { $out.Add([string]$_) }
            }
        } else {
            & $FilePath @ArgumentList 2>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) { Write-Host $_.Exception.Message }
                else { Write-Host ([string]$_) }
            }
        }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($null -eq $code) { $code = 0 }
    if (-not $AllowFailure -and $code -ne 0) {
        $detail = ''
        if ($err.Count -gt 0) { $detail = "`n" + ($err -join "`n") }
        throw "'$FilePath $($ArgumentList -join ' ')' failed with exit code $code.$detail"
    }
    if ($Capture) {
        return [pscustomobject]@{ ExitCode = $code; Output = $out.ToArray(); Errors = $err.ToArray() }
    }
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Read-Utf8 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-JsonProp {
    param($Object, [Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function ConvertTo-JsonString {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    foreach ($ch in $Value.ToCharArray()) {
        $c = [int]$ch
        switch ($c) {
            34 { [void]$sb.Append('\"') }
            92 { [void]$sb.Append('\\') }
            8  { [void]$sb.Append('\b') }
            12 { [void]$sb.Append('\f') }
            10 { [void]$sb.Append('\n') }
            13 { [void]$sb.Append('\r') }
            9  { [void]$sb.Append('\t') }
            default {
                if ($c -lt 32) { [void]$sb.Append(('\u{0:x4}' -f $c)) }
                else { [void]$sb.Append($ch) }
            }
        }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

# Deterministic JSON with 2-space indentation (ConvertTo-Json in 5.1 uses odd spacing
# and unwraps single-element arrays).
function ConvertTo-StudioJson {
    param([AllowNull()]$Value, [int]$Level = 0)
    $ind  = '  ' * $Level
    $ind2 = '  ' * ($Level + 1)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return (ConvertTo-JsonString $Value) }
    if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }
    if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
        return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0}', $Value)
    }
    $pairs = $null
    if ($Value -is [System.Collections.IDictionary]) {
        $pairs = @(foreach ($k in $Value.Keys) { ,@([string]$k, $Value[$k]) })
    } elseif ($Value -is [System.Management.Automation.PSCustomObject]) {
        $pairs = @(foreach ($p in $Value.PSObject.Properties) { ,@($p.Name, $p.Value) })
    }
    if ($null -ne $pairs) {
        if ($pairs.Count -eq 0) { return '{}' }
        $items = foreach ($pair in $pairs) {
            $ind2 + (ConvertTo-JsonString $pair[0]) + ': ' + (ConvertTo-StudioJson -Value $pair[1] -Level ($Level + 1))
        }
        return "{`n" + ($items -join ",`n") + "`n$ind}"
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $arr = @($Value)
        if ($arr.Count -eq 0) { return '[]' }
        $items = foreach ($v in $arr) { $ind2 + (ConvertTo-StudioJson -Value $v -Level ($Level + 1)) }
        return "[`n" + ($items -join ",`n") + "`n$ind]"
    }
    return (ConvertTo-JsonString ([string]$Value))
}

# Parses color.ini. Returns an ordered dictionary: section name -> list of
# [pscustomobject]@{ Key; Value; Line }. Also returns stray (out-of-section) lines
# through the -Stray reference list if given.
function Read-ColorIni {
    param([Parameter(Mandatory = $true)][string]$Path, [System.Collections.Generic.List[object]]$Stray)
    $sections = [ordered]@{}
    $current = $null
    $lineNo = 0
    foreach ($raw in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        $lineNo++
        $line = $raw.Trim()
        if ($line -eq '' -or $line.StartsWith(';') -or $line.StartsWith('#')) { continue }
        if ($line -match '^\[(.+)\]$') {
            $current = $Matches[1].Trim()
            if (-not $sections.Contains($current)) {
                $sections[$current] = New-Object System.Collections.Generic.List[object]
            }
            continue
        }
        $entry = $null
        if ($line -match '^([^=]+)=(.*)$') {
            $val = $Matches[2]
            $semi = $val.IndexOf(';')
            if ($semi -ge 0) { $val = $val.Substring(0, $semi) }
            $entry = [pscustomobject]@{ Key = $Matches[1].Trim(); Value = $val.Trim(); Line = $lineNo }
        } else {
            $entry = [pscustomobject]@{ Key = $null; Value = $line; Line = $lineNo }
        }
        if ($null -eq $current -or $null -eq $entry.Key) {
            if ($null -ne $Stray) { $Stray.Add($entry) }
        } else {
            $sections[$current].Add($entry)
        }
    }
    return $sections
}
