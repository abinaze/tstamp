#!/usr/bin/env bash
# The history handler that was set before TStamp's (a script block, or a .NET
# delegate such as the one the VS Code terminal sets) must be called correctly.
# The static checks run everywhere; the PowerShell run is Windows only.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
has() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}
hasnt() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $2)"; else pass=$((pass + 1)); echo "ok   - $1"; fi
}

src="$(cat "$ROOT/shells/powershell.ps1")"
has   "the wrapper function exists"                      'function global:__ts_call_prev' "$src"
has   "the wrapper handles .NET delegates"               'PrevHandler -is \[System\.Delegate\]|\$prev -is \[System\.Delegate\]' "$src"
has   "the handler calls the wrapper"                    '^    __ts_call_prev \$line$' "$src"
hasnt "the old direct call is gone"                      '& \$global:__TS\.PrevHandler \$line' "$src"

run_ps=1
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) run_ps=0; echo "skip - the PowerShell run is Windows only" ;;
esac
if [ "$run_ps" = 1 ] && ! command -v "${TSTAMP_TEST_POWERSHELL:-powershell}" >/dev/null 2>&1; then
  run_ps=0; echo "skip - powershell.exe not found"
fi

if [ "$run_ps" = 1 ]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  W() { cygpath -w "$1"; }
  out="$("${TSTAMP_TEST_POWERSHELL:-powershell}" -NoProfile -ExecutionPolicy Bypass -File "$(W "$ROOT/tests/ps/prevhandler.ps1")" "$(W "$TMP/state")" "$(W "$ROOT/shells/powershell.ps1")" 2>&1 | tr -d '\r')"
  has "no previous handler: the command is kept"         '^NONE True$' "$out"
  has "a script block handler is called"                 '^SCRIPTBLOCK SB:b$' "$out"
  has "a delegate handler is called"                     '^DELEGATE DELEGATE:c$' "$out"
  has "a failing handler keeps the command"              '^FAILING True$' "$out"
fi

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ] || { [ "$run_ps" = 1 ] && { echo "--- output ---"; printf '%s\n' "${out:-}"; }; }
[ "$fail" -eq 0 ]
