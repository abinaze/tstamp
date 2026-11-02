#!/usr/bin/env bash
# Tests for "tstamp run", the one-command timer.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/bin/tstamp"
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

out="$(bash "$T" run echo hello world 2>&1)"; rc=$?
check "run returns the command's exit code (0)" 0 "$rc"
has "START line with a label and the command" '^\[T1\]\[[0-9-]+ [0-9:.]+\] START: echo hello world$' "$out"
has "the command's own output is untouched" '^hello world$' "$out"
has "END line with exit code and duration" '^\[T1\]\[[0-9-]+ [0-9:.]+\] END: echo hello world \| EXIT=0 \| DURATION=[0-9]+\.[0-9]{2}s$' "$out"

out="$(bash "$T" run sh -c 'exit 7' 2>&1)"; rc=$?
check "a failing command's exit code is passed on" 7 "$rc"
has "END line shows EXIT=7" 'END: sh -c exit 7 \| EXIT=7 ' "$out"

bash "$T" run no-such-command-tstamp-xyz >/dev/null 2>&1; rc=$?
check "an unknown command fails" yes "$([ "$rc" -ne 0 ] && echo yes || echo no)"

bash "$T" run >/dev/null 2>&1
check "run without a command exits 2" 2 "$?"

check "the temporary session label is released" 0 "$(ls "$TSTAMP_HOME/sessions" | wc -l | tr -d ' ')"

rep="$(bash "$T" export 2>&1)"
check "export shows all three runs (6 events)" 6 "$(printf '%s\n' "$rep" | grep -c 'START:\|END:')"
has "export shows the first run" 'START: echo hello world$' "$rep"

# started from CMD, commands go through cmd.exe, not bash's own lookup
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
    mkdir -p "$TMP/fakebin"
    printf '#!/bin/sh\necho "CMDSTUB $*"\n' > "$TMP/fakebin/cmd.exe"
    chmod +x "$TMP/fakebin/cmd.exe"
    out="$(TSTAMP_RUN_SHELL=cmd PATH="$TMP/fakebin:$PATH" bash "$T" run echo hi 2>&1)"
    has "from CMD, the command is run through cmd.exe" '^CMDSTUB /c echo hi$' "$out"
    ;;
esac

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
