#!/usr/bin/env bash
# Stop scope in shells/powershell.ps1 on Windows (Windows PowerShell 5.1):
# "tstamp stop" stops this terminal only, "tstamp-a stop" stops every one.
# Skipped where powershell.exe is not available.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "skip - PowerShell tests run on Windows only"; echo; echo "passed=0 failed=0 skipped=1"; exit 0 ;;
esac
if ! command -v powershell >/dev/null 2>&1; then
  echo "skip - powershell.exe not found"; echo; echo "passed=0 failed=0 skipped=1"; exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0
has() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}
hasnt() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $2)"; else pass=$((pass + 1)); echo "ok   - $1"; fi
}

W() { cygpath -w "$1"; }
out="$(powershell -NoProfile -ExecutionPolicy Bypass -File "$(W "$ROOT/tests/ps/scope.ps1")" "$(W "$TMP/state")" "$(W "$ROOT/shells/powershell.ps1")" 2>&1 | tr -d '\r')"

has   "tstamp-a turns tracking on"                  'Global tracking enabled\.' "$out"
has   "global: tracked"                             'START: echo g1$' "$out"
has   "tstamp stop only stops this terminal"        'Tracking stopped in this terminal\. Other terminals are not affected\.' "$out"
has   "tstamp stop points to tstamp-a stop"         'To stop everywhere, type: tstamp-a stop' "$out"
hasnt "stopped terminal is not tracked"             'START: echo g2$' "$out"
has   "the stopped command still ran"               'RAN g2$' "$out"
has   "status explains the stopped terminal"        'off \(stopped here; global tracking is on elsewhere\)' "$out"
has   "the next tstamp-a switches it back on"       'START: echo g3$' "$out"
has   "tstamp-a stop reports success"               'Global tracking stopped\.' "$out"
hasnt "tstamp-a stop turns global tracking off"     'START: echo h1$' "$out"
has   "tstamp turns this terminal on by hand"       'START: echo h2$' "$out"
hasnt "tstamp-a stop also stops a hand-enabled terminal" 'START: echo h3$' "$out"
has   "tstamp turns it on again"                    'START: echo h4$' "$out"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ] || { echo "--- output ---"; printf '%s\n' "$out"; }
[ "$fail" -eq 0 ]
