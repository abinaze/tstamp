# TStamp integration for PowerShell 5.1 and 7. Load it with:
#   . path\to\shells\powershell.ps1
# It shares ~/.tstamp (the same folder, global switch, session labels and
# logs) with the bash integration, so "tstamp export" merges both.
# Needs PSReadLine (included with Windows PowerShell 5.1 and PowerShell 7).

if ($global:__TS) { return }
try { Import-Module PSReadLine -ErrorAction Stop } catch {
  Write-Warning 'tstamp: PSReadLine is required, so tracking was not installed.'
  return
}

$global:__TS = @{
  Root = (Split-Path -Parent $PSScriptRoot)
  Home = $(if ($env:TSTAMP_HOME) { $env:TSTAMP_HOME } else { Join-Path $env:USERPROFILE '.tstamp' })
  Local = $false; LocalFmt = ''; Sid = ''; Log = ''; Boot = ''
  StopSeen = ''; MutedGen = ''
  Pending = $null; Start = [long]0; Prev = $null; Err0 = $null; Fmt = ''
  Prompt = $null; PrevHandler = $null
}

function global:__ts_us { [long](([DateTime]::UtcNow.Ticks - 621355968000000000) / 10) }

function global:__ts_fmt {
  param([long]$us, [string]$fmt)
  $sec = [long][math]::Floor($us / 1000000)
  $frac = '{0:000000}' -f [long]($us % 1000000)
  $dt = [DateTimeOffset]::FromUnixTimeSeconds($sec).ToLocalTime()
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $ev = [Text.RegularExpressions.MatchEvaluator]{
    param($m)
    switch -CaseSensitive ($m.Groups[1].Value) {
      'Y' { $dt.ToString('yyyy', $inv) }
      'y' { $dt.ToString('yy', $inv) }
      'm' { $dt.ToString('MM', $inv) }
      'd' { $dt.ToString('dd', $inv) }
      'e' { $dt.Day.ToString().PadLeft(2) }
      'H' { $dt.ToString('HH', $inv) }
      'M' { $dt.ToString('mm', $inv) }
      'S' { $dt.ToString('ss', $inv) }
      'b' { $dt.ToString('MMM', $inv) }
      'B' { $dt.ToString('MMMM', $inv) }
      'a' { $dt.ToString('ddd', $inv) }
      'A' { $dt.ToString('dddd', $inv) }
      'j' { '{0:000}' -f $dt.DayOfYear }
      'T' { $dt.ToString('HH:mm:ss', $inv) }
      'F' { $dt.ToString('yyyy-MM-dd', $inv) }
      'D' { $dt.ToString('MM/dd/yy', $inv) }
      'z' { $o = $dt.Offset; '{0}{1:00}{2:00}' -f $(if ($o.Ticks -lt 0) { '-' } else { '+' }), [math]::Abs($o.Hours), [math]::Abs($o.Minutes) }
      '3N' { $frac.Substring(0, 3) }
      '6N' { $frac }
      'N' { $frac + '000' }
      '%' { '%' }
      default { '%' + $m.Groups[1].Value }
    }
  }
  [regex]::Replace($fmt, '%(3N|6N|[A-Za-z%])', $ev)
}

function global:__ts_fmt_string {
  param([string]$id)
  switch ($id) {
    '1' { '%H:%M' }
    '2' { '%H:%M:%S' }
    '3' { '%Y-%m-%d %H:%M:%S' }
    '4' { '%Y-%m-%d %H:%M:%S.%3N' }
    '5' { '%Y-%m-%d %H:%M:%S %z' }
    default { if ($id -like '*%*' -and $id -notmatch '[\r\n]') { $id } }
  }
}

function global:__ts_config_format {
  $f = Join-Path $global:__TS.Home 'config'
  if (Test-Path -LiteralPath $f) {
    foreach ($l in [IO.File]::ReadAllLines($f)) { if ($l.StartsWith('format=')) { return $l.Substring(7) } }
  }
  '4'
}

function global:__ts_boot {
  if (-not $global:__TS.Boot) {
    try {
      $b = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
      $global:__TS.Boot = 'ts:' + [DateTimeOffset]::new($b).ToUnixTimeSeconds()
    } catch { $global:__TS.Boot = 'none' }
  }
  $global:__TS.Boot
}

function global:__ts_same_boot {
  param($a, $b)
  if ($a -eq 'none' -or $b -eq 'none') { return $true }
  if ($a -match '^ts:(\d+)$') { $x = [long]$Matches[1] } else { return ($a -eq $b) }
  if ($b -match '^ts:(\d+)$') { $y = [long]$Matches[1] } else { return $false }
  [math]::Abs($x - $y) -le 120
}

# Returns the "gen" value of the global flag when global tracking is on for
# this boot ("legacy" for a flag written without one), otherwise $null.
function global:__ts_global_gen {
  $f = Join-Path $global:__TS.Home 'enabled'
  if (-not (Test-Path -LiteralPath $f)) { return $null }
  $boot = ''; $gen = ''
  try {
    foreach ($l in [IO.File]::ReadAllLines($f)) {
      if ($l.StartsWith('boot=')) { $boot = $l.Substring(5) }
      elseif ($l.StartsWith('gen=')) { $gen = $l.Substring(4) }
    }
  } catch { return $null }
  if (-not (__ts_same_boot $boot (__ts_boot))) { return $null }
  if ($gen) { return $gen }
  'legacy'
}

function global:__ts_global_on {
  $null -ne (__ts_global_gen)
}

# Returns the current "stopall" value (empty when there is none).
function global:__ts_stopall {
  $f = Join-Path $global:__TS.Home 'stopall'
  if (-not (Test-Path -LiteralPath $f)) { return '' }
  try { ([IO.File]::ReadAllText($f)).Trim() } catch { '' }
}

# True when this terminal should track the next command: it was turned on
# here (and "tstamp-a stop" has not been typed anywhere since), or global
# tracking is on and this terminal was not stopped under the current tstamp-a.
function global:__ts_enabled {
  if ($global:__TS.Local) {
    if ((__ts_stopall) -eq $global:__TS.StopSeen) { return $true }
    $global:__TS.Local = $false
    $global:__TS.LocalFmt = ''
  }
  $g = __ts_global_gen
  if ($null -eq $g) { return $false }
  $g -ne $global:__TS.MutedGen
}

function global:__ts_session {
  if ($global:__TS.Sid) { return $true }
  $base = Join-Path $global:__TS.Home 'sessions'
  try {
    [void][IO.Directory]::CreateDirectory($base)
    [void][IO.Directory]::CreateDirectory((Join-Path $global:__TS.Home 'logs'))
  } catch { return $false }
  for ($n = 1; $n -le 999; $n++) {
    $d = Join-Path $base "T$n"
    if (Test-Path -LiteralPath $d) {
      if (-not (Test-Path -LiteralPath (Join-Path $d 'kind'))) { continue }
      $p = 0
      try { [void][int]::TryParse(([IO.File]::ReadAllText((Join-Path $d 'pid'))).Trim(), [ref]$p) } catch { }
      if ($p -gt 0 -and (Get-Process -Id $p -ErrorAction SilentlyContinue)) { continue }
      Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path -LiteralPath $d) { continue }
    }
    try {
      [void][IO.Directory]::CreateDirectory($d)
      $fs = [IO.File]::Open((Join-Path $d 'pid'), 'CreateNew', 'Write')
      $fs.Dispose()
      [IO.File]::WriteAllText((Join-Path $d 'pid'), "$PID`n")
      [IO.File]::WriteAllText((Join-Path $d 'kind'), "windows`n")
    } catch { continue }
    $global:__TS.Sid = "T$n"
    $global:__TS.Log = Join-Path (Join-Path $global:__TS.Home 'logs') "T$n-$PID.log"
    return $true
  }
  $false
}

function global:__ts_log {
  param([string]$ev, [long]$us, $exit, $durUs, [string]$cmd)
  $c = $cmd -replace "[\t\r\n]", ' '
  $line = "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`n" -f $us, $global:__TS.Sid, $PID, $ev, $exit, $durUs, $c
  try { [IO.File]::AppendAllText($global:__TS.Log, $line, (New-Object Text.UTF8Encoding($false))) } catch { }
}

function global:__ts_submit {
  param([string]$line)
  $t = $line.Trim()
  if (-not $t -or $t -match '^(tstamp|tstamp-a|exit|logout)(\s|$)') { return }
  if (-not (__ts_enabled)) { return }
  if (-not (__ts_session)) { return }
  $want = if ($global:__TS.LocalFmt) { $global:__TS.LocalFmt } else { __ts_config_format }
  $fmt = __ts_fmt_string $want
  if (-not $fmt) { $fmt = __ts_fmt_string '4' }
  $us = __ts_us
  $global:__TS.Pending = $t
  $global:__TS.Start = $us
  $global:__TS.Fmt = $fmt
  $global:__TS.Prev = $global:LASTEXITCODE
  $global:__TS.Err0 = $(if ($global:Error.Count) { $global:Error[0] } else { $null })
  Write-Host ('[{0}][{1}] START: {2}' -f $global:__TS.Sid, (__ts_fmt $us $fmt), $t)
  __ts_log 'START' $us '' '' $t
}

function global:__ts_bash {
  foreach ($p in @("$env:ProgramFiles\Git\bin\bash.exe", "${env:ProgramFiles(x86)}\Git\bin\bash.exe", "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe")) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  foreach ($k in 'HKCU:\SOFTWARE\GitForWindows', 'HKLM:\SOFTWARE\GitForWindows') {
    try {
      $i = (Get-ItemProperty $k -ErrorAction Stop).InstallPath
      if ($i -and (Test-Path -LiteralPath "$i\bin\bash.exe")) { return "$i\bin\bash.exe" }
    } catch { }
  }
}

function global:__ts_delegate {
  param($a)
  $b = __ts_bash
  if (-not $b) { Write-Error 'tstamp: Git Bash was not found. Install Git for Windows: https://git-scm.com/download/win'; return }
  $script = (Join-Path $global:__TS.Root 'bin\tstamp') -replace '\\', '/'
  & $b $script @a
}

function global:__ts_save_format {
  param([string]$fmt)
  [void][IO.Directory]::CreateDirectory($global:__TS.Home)
  $f = Join-Path $global:__TS.Home 'config'
  $keep = @()
  if (Test-Path -LiteralPath $f) { $keep = @([IO.File]::ReadAllLines($f) | Where-Object { $_ -and -not $_.StartsWith('format=') }) }
  [IO.File]::WriteAllText($f, ((@("format=$fmt") + $keep) -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
}

function global:__ts_write_file {
  param([string]$name, [string]$text)
  [void][IO.Directory]::CreateDirectory($global:__TS.Home)
  $f = Join-Path $global:__TS.Home $name
  [IO.File]::WriteAllText("$f.tmp", $text, (New-Object Text.UTF8Encoding($false)))
  Move-Item -LiteralPath "$f.tmp" -Destination $f -Force
}

function global:tstamp-a {
  param([string]$Format)
  if ($Format -eq 'stop') {
    $f = Join-Path $global:__TS.Home 'enabled'
    Remove-Item -LiteralPath $f -ErrorAction SilentlyContinue
    __ts_write_file 'stopall' ("{0}`n" -f [guid]::NewGuid().ToString('N'))
    Write-Host 'Global tracking stopped.'
    Write-Host 'Terminals with the shell hook stop at their next prompt.'
    return
  }
  if ($Format) {
    if (-not (__ts_fmt_string $Format)) { Write-Error "tstamp-a: invalid format: $Format"; return }
    __ts_save_format $Format
  }
  $text = "boot={0}`nsince={1}`ngen={2}`n" -f (__ts_boot), [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(), [guid]::NewGuid().ToString('N')
  __ts_write_file 'enabled' $text
  Write-Host 'Global tracking enabled.'
  Write-Host 'Terminals with the TStamp hook loaded start tracking at their next prompt.'
  Write-Host 'Tracking turns off after a reboot.'
}

function global:tstamp {
  $a = @($args)
  $c = if ($a.Count) { [string]$a[0] } else { '' }
  if ($c -eq '' -or $c -match '^[1-5]$' -or $c -like '*%*') {
    if ($c -and -not (__ts_fmt_string $c)) { Write-Error "tstamp: invalid format: $c"; return }
    if (-not (__ts_session)) { Write-Error 'tstamp: cannot create session state'; return }
    $global:__TS.LocalFmt = $c
    $global:__TS.StopSeen = (__ts_stopall)
    $global:__TS.MutedGen = ''
    $global:__TS.Local = $true
    Write-Host ("Tracking enabled in this terminal (session {0})." -f $global:__TS.Sid)
    return
  }
  switch ($c) {
    'stop' {
      $global:__TS.Local = $false
      $global:__TS.LocalFmt = ''
      $g = __ts_global_gen
      if ($null -ne $g) { $global:__TS.MutedGen = $g }
      Write-Host 'Tracking stopped in this terminal. Other terminals are not affected.'
      Write-Host 'To stop everywhere, type: tstamp-a stop'
    }
    'status' {
      $g = __ts_global_gen
      $state = 'off'
      if (__ts_enabled) { $state = if ($global:__TS.Local) { 'on' } else { 'on (global)' } } elseif ($null -ne $g) { $state = 'off (stopped here; global tracking is on elsewhere)' }
      $want = if ($global:__TS.LocalFmt) { $global:__TS.LocalFmt } else { __ts_config_format }
      Write-Host ('This terminal : {0}' -f $state)
      Write-Host ('Session ID    : {0}' -f $(if ($global:__TS.Sid) { $global:__TS.Sid } else { 'not assigned yet' }))
      Write-Host ('Format here   : {0}' -f (__ts_fmt_string $want))
      Write-Host ('State dir     : {0}' -f $global:__TS.Home)
      Write-Host ('Global        : {0}' -f $(if ($null -ne $g) { 'on' } else { 'off' }))
    }
    default { __ts_delegate $a }
  }
}

$global:__TS.Prompt = (Get-Command prompt).ScriptBlock
$global:__TS.PrevHandler = (Get-PSReadLineOption).AddToHistoryHandler

function global:prompt {
  $ok = $?
  $code = $global:LASTEXITCODE
  if ($global:__TS.Pending) {
    $us = __ts_us
    if ($code -ne $global:__TS.Prev) { $exit = [int]$code }
    elseif ($ok) { $exit = 0 }
    else {
      $errNew = ($global:Error.Count -gt 0) -and -not [object]::ReferenceEquals($global:Error[0], $global:__TS.Err0)
      $exit = if ((-not $errNew) -and $code) { [int]$code } else { 1 }
    }
    $d = $us - $global:__TS.Start
    if ($d -lt 0) { $d = 0 }
    $dur = '{0}.{1:00}' -f [long][math]::Floor($d / 1000000), [long][math]::Floor(($d % 1000000) / 10000)
    Write-Host ('[{0}][{1}] END: {2} | EXIT={3} | DURATION={4}s' -f $global:__TS.Sid, (__ts_fmt $us $global:__TS.Fmt), $global:__TS.Pending, $exit, $dur)
    __ts_log 'END' $us $exit $d $global:__TS.Pending
    $global:__TS.Pending = $null
  }
  & $global:__TS.Prompt
}

try {
  Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)
    $null = __ts_submit $line
    if ($global:__TS.PrevHandler) { & $global:__TS.PrevHandler $line } else { $true }
  }
} catch {
  Write-Warning 'tstamp: could not hook the command line (no interactive console), so only manual calls work.'
}
