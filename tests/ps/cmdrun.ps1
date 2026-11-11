# Test helper for the Command Prompt session (shells\cmdsession.ps1).
# Runs lines through cmd.exe the way the session does, without a console.
#   cmdrun.ps1 <state dir> <shells\cmdsession.ps1>
$env:TSTAMP_HOME = $args[0]
. $args[1]

function step($line) {
  __ts_submit $line
  __ts_cmdrun $line
  $global:LastCmdExit = $global:__TS.CmdExit
  $null = prompt
}

$cwd0 = (Get-Location).Path
step 'cd ..'
"CWD_CHANGED=" + ((Get-Location).Path -ne $cwd0)
step 'set TSTEST_VAR=hello world'
"ENV=[" + $env:TSTEST_VAR + "]"
step 'set TSTEST_VAR='
"ENV_REMOVED=" + ($null -eq $env:TSTEST_VAR)
step 'cmd /c exit 7'
"EXIT7=" + $global:LastCmdExit
step 'echo hi'
"EXIT0=" + $global:LastCmdExit
step 'dir C:\no-such-folder-tstamp'
"EXIT_DIR=" + $global:LastCmdExit
step 'echo "quoted text" & echo second'
step 'echo it''s a test'
