# Test helper. Simulates what PSReadLine and the host do, without a console.
#   simulate.ps1 run <state dir> <shells\powershell.ps1>
#   simulate.ps1 fmt <microseconds> <format> <shells\powershell.ps1>
$mode = $args[0]
if ($mode -eq 'fmt') {
  . $args[3]
  [Console]::Out.Write((__ts_fmt ([long]$args[1]) $args[2]))
  return
}
$env:TSTAMP_HOME = $args[1]
. $args[2]
tstamp 4
__ts_submit 'echo hi'
$null = prompt
__ts_submit 'cmd /c exit 3'
cmd /c exit 3
$null = prompt
__ts_submit 'Get-ChildItem C:\no-such-folder-tstamp'
Get-ChildItem C:\no-such-folder-tstamp -ErrorAction SilentlyContinue
$null = prompt
__ts_submit 'tstamp status'
tstamp status
$null = prompt
