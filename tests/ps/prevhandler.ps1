# Test helper. Calls the "previous history handler" wrapper with every kind of
# handler a terminal can have set before TStamp: none, a script block, a .NET
# delegate (as VS Code sets), and a delegate that fails.
#   prevhandler.ps1 <state dir> <shells\powershell.ps1>
$env:TSTAMP_HOME = $args[0]
. $args[1]

$global:__TS.PrevHandler = $null
Write-Host ('NONE ' + (__ts_call_prev 'a'))
$global:__TS.PrevHandler = { param($l) "SB:$l" }
Write-Host ('SCRIPTBLOCK ' + (__ts_call_prev 'b'))
$global:__TS.PrevHandler = [Func[string,object]]{ param($l) "DELEGATE:$l" }
Write-Host ('DELEGATE ' + (__ts_call_prev 'c'))
$global:__TS.PrevHandler = [Func[string,object]]{ param($l) throw 'boom' }
Write-Host ('FAILING ' + (__ts_call_prev 'd'))
