# TStamp session for Command Prompt commands (experimental).
# Started by typing "tstamp" in Command Prompt (bin\tstamp.cmd). It runs in
# Windows PowerShell 5.1 with the TStamp hook loaded, but every line you type is
# run by cmd.exe instead of PowerShell. Type exit to go back to Command Prompt.
# It changes nothing on the computer: no registry entry, no setting, no install.
param([string]$Format = '')

# The prompt looks like Command Prompt's. It is defined first so that the hook
# wraps it, and the hook then prints the END line before each prompt.
function global:prompt { (Get-Location).Path + '>' }

. (Join-Path $PSScriptRoot 'powershell.ps1')
if (-not $global:__TS) {
  Write-Host 'tstamp: the PowerShell integration could not be loaded, so there is no session.'
  exit 1
}
$global:__TS.CmdExit = $null

# Runs one line in cmd.exe. After the line, cmd.exe writes the exit code, the
# current folder and its environment to temporary files, so that cd and set
# carry over to the next line.
function global:__ts_cmdrun {
  param([string]$line)
  $tag = Join-Path ([IO.Path]::GetTempPath()) ('tstamp-cmd-{0}-{1}' -f $PID, [guid]::NewGuid().ToString('N').Substring(0, 8))
  $fRc = "$tag.rc"; $fCwd = "$tag.cwd"; $fEnv = "$tag.env"
  $pre = @{}
  foreach ($e in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) { $pre[[string]$e.Key] = [string]$e.Value }

  # No space before the first & : cmd.exe would take it as part of the line, so
  # "set X=1 &" would store "1 " instead of "1".
  $wrapped = $line + '&call echo %^errorlevel% >"' + $fRc + '"&cd >"' + $fCwd + '"&set >"' + $fEnv + '"'
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $(if ($env:ComSpec) { $env:ComSpec } else { 'cmd.exe' })
  $psi.Arguments = '/d /s /c "' + $wrapped + '"'
  $psi.UseShellExecute = $false
  $psi.WorkingDirectory = (Get-Location).ProviderPath
  $rc = 1
  try {
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    $rc = $p.ExitCode
  } catch {
    Write-Host ('tstamp: cannot start cmd.exe: ' + $_.Exception.Message)
    $global:__TS.CmdExit = 127
    return
  }

  if (Test-Path -LiteralPath $fRc) {
    $t = ([IO.File]::ReadAllText($fRc)).Trim()
    if ($t -match '^-?\d+$') { $rc = [int]$t }
  }
  if (Test-Path -LiteralPath $fCwd) {
    $d = ([IO.File]::ReadAllText($fCwd)).Trim()
    if ($d -and (Test-Path -LiteralPath $d)) { Set-Location -LiteralPath $d }
  }
  if (Test-Path -LiteralPath $fEnv) {
    $post = @{}
    foreach ($l in [IO.File]::ReadAllLines($fEnv)) {
      $i = $l.IndexOf('=', 1)
      if ($i -gt 0) { $post[$l.Substring(0, $i)] = $l.Substring($i + 1) }
    }
    foreach ($k in @($post.Keys)) {
      if ((-not $pre.ContainsKey($k)) -or ($pre[$k] -ne $post[$k])) { [Environment]::SetEnvironmentVariable($k, $post[$k], 'Process') }
    }
    foreach ($k in @($pre.Keys)) {
      # Remove-Item works the same in Windows PowerShell and PowerShell 7. Passing $null
      # to SetEnvironmentVariable would leave an empty variable behind in PowerShell 7.
      if (-not $post.ContainsKey($k)) { Remove-Item -LiteralPath ('Env:' + $k) -ErrorAction SilentlyContinue }
    }
  }
  Remove-Item -LiteralPath $fRc, $fCwd, $fEnv -ErrorAction SilentlyContinue
  $global:__TS.CmdExit = $rc
}

# PowerShell asks this function for each line. The line stays on screen as you
# typed it, and the text that is run is replaced with a call to __ts_cmdrun.
$global:__TS.OrigReadLine = $null
$cmd = Get-Command PSConsoleHostReadLine -ErrorAction SilentlyContinue
if ($cmd -and $cmd.ScriptBlock) { $global:__TS.OrigReadLine = $cmd.ScriptBlock }

function global:PSConsoleHostReadLine {
  if ($global:__TS.OrigReadLine) { $line = & $global:__TS.OrigReadLine }
  else { $line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext) }
  $t = ([string]$line).Trim()
  if (-not $t -or $t -match '^(tstamp|tstamp-a|exit|logout)(\s|$)') { return $line }
  $global:__TS.CmdExit = $null
  "__ts_cmdrun '" + $t.Replace("'", "''") + "'"
}

Write-Host 'TStamp session for Command Prompt commands (experimental).'
Write-Host 'Lines you type are run by cmd.exe. Type exit to go back.'
tstamp $Format
