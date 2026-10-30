#!/usr/bin/env bash
# Tests for help, man, examples, and consistency between the documents.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/bin/tstamp"
TSTAMP_HOME="/tmp/tstamp-docs-test-$$"
export TSTAMP_HOME
trap 'rm -rf "$TSTAMP_HOME"' EXIT

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

contains() { # description, text, needle
  if printf '%s\n' "$2" | grep -qF -- "$3"; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (missing: $3)"
  fi
}

COMMANDS=("tstamp-a" "tstamp stop" "tstamp status" "tstamp format" "tstamp set" \
  "tstamp export" "tstamp help" "tstamp man" "tstamp examples" "tstamp version" "tstamp reset")
HEADINGS=("NAME" "SYNOPSIS" "DESCRIPTION" "COMMANDS" "FORMATS" "CONFIGURATION" \
  "OUTPUT AND LOGS" "SHELL COMPATIBILITY" "EXAMPLES" "TROUBLESHOOTING" "PRIVACY" \
  "INSTALLATION" "UNINSTALLATION" "LIMITATIONS")

help_out="$(bash "$T" help)"; check "help exits 0" 0 "$?"
man_out="$(bash "$T" man)"; check "man exits 0" 0 "$?"
ex_out="$(bash "$T" examples)"; check "examples exits 0" 0 "$?"
ver_out="$(bash "$T" version)"; check "version exits 0" 0 "$?"
bare_out="$(bash "$T")"; check "bare tstamp exits 0" 0 "$?"

check "bare tstamp shows the help" "$help_out" "$bare_out"
check "man output equals docs/manual.txt" yes "$(printf '%s\n' "$man_out" | cmp -s - "$ROOT/docs/manual.txt" && echo yes || echo no)"
contains "version output" "$ver_out" "tstamp $(cat "$ROOT/VERSION")"

for c in "${COMMANDS[@]}"; do
  contains "help lists '$c'" "$help_out" "$c"
  contains "manual documents '$c'" "$man_out" "$c"
done

for h in "${HEADINGS[@]}"; do
  if printf '%s\n' "$man_out" | grep -qx -- "$h"; then
    pass=$((pass + 1)); echo "ok   - manual has section $h"
  else
    fail=$((fail + 1)); echo "FAIL - manual lacks section $h"
  fi
done

contains "examples show tstamp-a 4" "$ex_out" "tstamp-a 4"
contains "examples show a custom format" "$ex_out" 'tstamp "%d/%m/%Y %H:%M:%S"'

for f in help.txt examples.txt manual.txt; do
  check "docs/$f has no line over 78 characters" 0 "$(awk 'length > 78' "$ROOT/docs/$f" | wc -l | tr -d ' ')"
done

check "docs commands did not create a state folder" no "$([ -e "$TSTAMP_HOME" ] && echo yes || echo no)"

bash "$T" nonsense >/dev/null 2>&1; check "unknown command exits 2" 2 "$?"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
