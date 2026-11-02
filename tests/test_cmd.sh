#!/usr/bin/env bash
# Tests for the CMD launchers (tstamp.cmd, tstamp-a.cmd). Windows only.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "skip - the CMD launchers run on Windows only"; echo; echo "passed=0 failed=0 skipped=1"; exit 0 ;;
esac

TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
has() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}

BAT="$(cygpath -w "$ROOT/bin/tstamp.cmd")"
BATA="$(cygpath -w "$ROOT/bin/tstamp-a.cmd")"
V="$(tr -d '\r\n' < "$ROOT/VERSION")"

check "tstamp.cmd has Windows line endings" 1 "$(head -c 2000 "$ROOT/bin/tstamp.cmd" | grep -c $'\r' | awk '$1 > 0 { print 1 }')"
out="$(cmd //c "$BAT version" 2>&1 | tr -d '\r')"
check "tstamp version works from CMD" "tstamp $V" "$out"

out="$(cmd //c "$BAT run cmd /c exit 3" 2>&1 | tr -d '\r')"
has "run from CMD prints START" '^\[T1\]\[[0-9-]+ [0-9:.]+\] START: cmd /c exit 3$' "$out"
has "run from CMD keeps the native exit code" 'END: cmd /c exit 3 \| EXIT=3 ' "$out"
cmd //c "$BAT run cmd /c exit 3" >/dev/null 2>&1
check "the exit code reaches CMD" 3 "$?"

out="$(cmd //c "$BATA 2" 2>&1 | tr -d '\r')"
has "tstamp-a works from CMD" 'Global tracking enabled\.' "$out"
check "tstamp-a saved the format" "format=2" "$(grep '^format=' "$TSTAMP_HOME/config" | tr -d '\r')"
cmd //c "$BAT stop" >/dev/null 2>&1
check "tstamp stop works from CMD" no "$([ -e "$TSTAMP_HOME/enabled" ] && echo yes || echo no)"

out="$(TSTAMP_BASH='C:\no-such-folder\bash.exe' cmd //c "$BAT version" 2>&1 | tr -d '\r')"
has "a missing Git Bash gives a clear message" 'Git Bash was not found' "$out"
TSTAMP_BASH='C:\no-such-folder\bash.exe' cmd //c "$BAT version" >/dev/null 2>&1
check "and exit status 1" 1 "$?"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
