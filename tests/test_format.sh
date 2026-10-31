#!/usr/bin/env bash
# Tests for lib/format.sh and lib/config.sh. Uses a temporary TSTAMP_HOME.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSTAMP_HOME="$(mktemp -d)"
export TSTAMP_HOME
trap 'rm -rf "$TSTAMP_HOME"' EXIT

# shellcheck source=/dev/null
source "$ROOT/lib/config.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/format.sh"

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

check_match() { # description, regex, actual
  if [[ "$3" =~ $2 ]]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (regex '$2', got '$3')"
  fi
}

# --- format ID mapping ---
check "format 1" '%H:%M' "$(tstamp_format_string 1)"
check "format 2" '%H:%M:%S' "$(tstamp_format_string 2)"
check "format 3" '%Y-%m-%d %H:%M:%S' "$(tstamp_format_string 3)"
check "format 4" '%Y-%m-%d %H:%M:%S.%3N' "$(tstamp_format_string 4)"
check "format 5" '%Y-%m-%d %H:%M:%S %z' "$(tstamp_format_string 5)"
check "custom passes through" '%d/%m/%Y' "$(tstamp_format_string '%d/%m/%Y')"

tstamp_format_string abc >/dev/null 2>&1; check "text without % rejected" 1 "$?"
tstamp_format_string 9 >/dev/null 2>&1; check "ID 9 rejected" 1 "$?"
tstamp_format_validate 4 >/dev/null 2>&1; check "validate 4 ok" 0 "$?"
tstamp_format_validate abc >/dev/null 2>&1; check "validate abc fails" 1 "$?"

# --- real output shapes ---
check_match "format 1 output" '^[0-9]{2}:[0-9]{2}$' "$(tstamp_now "$(tstamp_format_string 1)")"
check_match "format 2 output" '^[0-9]{2}:[0-9]{2}:[0-9]{2}$' "$(tstamp_now "$(tstamp_format_string 2)")"
check_match "format 3 output" '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$' "$(tstamp_now "$(tstamp_format_string 3)")"
check_match "format 4 output" '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}$' "$(tstamp_now "$(tstamp_format_string 4)")"
check_match "format 5 output" '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}$' "$(tstamp_now "$(tstamp_format_string 5)")"

# --- config ---
tstamp_config_init
check "config file created" yes "$([ -f "$TSTAMP_HOME/config" ] && echo yes || echo no)"
check "default format is 4" 4 "$(tstamp_config_get format x)"
check "missing key returns default" fallback "$(tstamp_config_get nokey fallback)"

tstamp_config_set format 2
check "set format 2" 2 "$(tstamp_config_get format x)"

tstamp_config_set format '%d/%m/%Y %H:%M=x'
check "custom format with spaces and =" '%d/%m/%Y %H:%M=x' "$(tstamp_config_get format x)"

tstamp_config_set other val
check "other key stored" val "$(tstamp_config_get other x)"
check "format kept after other key" '%d/%m/%Y %H:%M=x' "$(tstamp_config_get format x)"

tstamp_config_reset
check "reset restores default" 4 "$(tstamp_config_get format x)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
