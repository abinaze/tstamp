#!/usr/bin/env bash
# Tests for shells/powershell.ps1 on Windows (Windows PowerShell 5.1).
# They simulate the prompt and the command line without a console, then check
# that bash reads the same logs. Skipped where powershell.exe is not available.
# Typing at a real PowerShell prompt is checked by hand, not here.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "skip - PowerShell tests run on Windows only"; echo; echo "passed=0 failed=0 skipped=1"; exit 0 ;;
esac
if ! command -v "${TSTAMP_TEST_POWERSHELL:-powershell}" >/dev/null 2>&1; then
  echo "skip - powershell.exe not found"; echo; echo "passed=0 failed=0 skipped=1"; exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
has() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}

W() { cygpath -w "$1"; }
PS1="$(W "$ROOT/shells/powershell.ps1")"
SIM="$(W "$ROOT/tests/ps/simulate.ps1")"
PSH=("${TSTAMP_TEST_POWERSHELL:-powershell}" -NoProfile -ExecutionPolicy Bypass -File)

# --- time formats: PowerShell must print exactly what bash prints ---
US=1700000000123456
for f in '%H:%M' '%H:%M:%S' '%Y-%m-%d %H:%M:%S' '%Y-%m-%d %H:%M:%S.%3N' '%Y-%m-%d %H:%M:%S %z' '%d/%m/%Y %b %a %j %6N'; do
  want="$(bash -c 'source "$1/lib/clock.sh"; tstamp_clock_format "$2" "$3"; printf %s "$TSTAMP_OUT"' _ "$ROOT" "$US" "$f")"
  got="$("${PSH[@]}" "$SIM" fmt "$US" "$f" "$PS1" 2>&1)"
  check "format '$f' matches bash" "$want" "$got"
done

# --- a simulated session, written to a temporary state folder ---
STATE="$TMP/state"
out="$("${PSH[@]}" "$SIM" run "$(W "$STATE")" "$PS1" 2>&1)"
has "PowerShell prints a START line" '^\[T1\]\[[0-9-]+ [0-9:.]+\] START: echo hi$' "$out"
has "PowerShell prints an END line with exit 0" 'END: echo hi \| EXIT=0 \| DURATION=[0-9]+\.[0-9]{2}s$' "$out"
has "a native failure keeps its own exit code" 'END: cmd /c exit 3 \| EXIT=3 ' "$out"
has "a failing cmdlet is EXIT=1, not the old native code" 'END: Get-ChildItem C:.no-such-folder-tstamp \| EXIT=1 ' "$out"
has "tstamp commands are not tracked" 'This terminal : on' "$out"
check "tstamp status is not logged" 0 "$(printf '%s\n' "$out" | grep -c 'START: tstamp status' || true)"

check "session folder created" yes "$([ -d "$STATE/sessions/T1" ] && echo yes || echo no)"
check "session is marked as a Windows session" windows "$(tr -d '\r\n' < "$STATE/sessions/T1/kind")"
LOG="$(ls "$STATE"/logs/T1-*.log 2>/dev/null | head -n 1)"
check "log file written" yes "$([ -n "$LOG" ] && echo yes || echo no)"
check "log has no CR characters" 0 "$(tr -cd '\r' < "$LOG" | wc -c | tr -d ' ')"
check "log has 6 events (3 commands, START and END)" 6 "$(grep -c . "$LOG")"

# --- bash reads what PowerShell wrote ---
rep="$(TSTAMP_HOME="$STATE" bash "$ROOT/bin/tstamp" export 2>&1)"
has "bash export shows PowerShell START" '^\[T1\]\[[0-9-]+ [0-9:.]+\] START: echo hi$' "$rep"
has "bash export shows PowerShell END" 'END: cmd /c exit 3 \| EXIT=3 \| DURATION=' "$rep"
check "export lists all 6 events" 6 "$(printf '%s\n' "$rep" | grep -c 'START:\|END:')"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
