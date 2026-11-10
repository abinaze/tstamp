#!/usr/bin/env bash
# The PowerShell hook must ignore the saved history that PSReadLine replays
# through the history handler when it starts. Static check: the handler asks
# __ts_live_line before it records a START, and __ts_live_line compares the
# command line with the submitted text.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
F="$ROOT/shells/powershell.ps1"
pass=0
fail=0
has() { # description, regex
  if grep -Eq -- "$2" "$F"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}
has "the live-line check exists"                      'function global:__ts_live_line'
has "it reads the PSReadLine command line"            'GetBufferState'
has "it compares the command line with the submitted text" '\.Trim\(\) -eq \(\$line'
has "the handler checks it before recording START"    'if \(__ts_live_line \$line\) \{ \$null = __ts_submit \$line \}'

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
