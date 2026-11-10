# Test helper. Simulates one PowerShell terminal and the other terminals'
# actions on the shared state folder, without a console.
#   scope.ps1 <state dir> <shells\powershell.ps1>
$env:TSTAMP_HOME = $args[0]
. $args[1]

function step($name, $line) {
  __ts_submit $line
  $null = prompt
  Write-Host "RAN $name"
}

tstamp-a 2
step 'g1' 'echo g1'
tstamp stop
step 'g2' 'echo g2'
tstamp status
tstamp-a
step 'g3' 'echo g3'
tstamp-a stop
step 'h1' 'echo h1'
tstamp 2
step 'h2' 'echo h2'
tstamp-a stop
step 'h3' 'echo h3'
tstamp status
tstamp 2
step 'h4' 'echo h4'
