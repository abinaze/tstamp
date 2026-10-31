#!/usr/bin/env bash
# Unit tests for lib/state.sh. Uses a temporary TSTAMP_HOME.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSTAMP_HOME="$(mktemp -d)"
export TSTAMP_HOME
trap 'rm -rf "$TSTAMP_HOME"' EXIT

# shellcheck source=/dev/null
source "$ROOT/lib/config.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/format.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/state.sh"

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

rc() { "$@" >/dev/null 2>&1; echo "$?"; }

# --- boot token ---
tstamp_boot_token
check_match "boot token has a known kind" '^(id:.+|ts:[0-9]+|none)$' "$TSTAMP_BOOT"

# --- the boot marker is a real one on this platform ---
case "$(uname -s)" in
  Linux) kind='^id:.+' ;;
  Darwin|MINGW*|MSYS*|CYGWIN*) kind='^ts:[0-9]+$' ;;
  *) kind='^(id:.+|ts:[0-9]+|none)$' ;;
esac
check_match "boot marker on $(uname -s) is not 'unknown'" "$kind" "$TSTAMP_BOOT"

# --- boot comparison ---
check "same id" 0 "$(rc tstamp_boot_same id:abc id:abc)"
check "different id" 1 "$(rc tstamp_boot_same id:abc id:xyz)"
check "ts within tolerance" 0 "$(rc tstamp_boot_same ts:1000 ts:1060)"
check "ts too far apart" 1 "$(rc tstamp_boot_same ts:1000 ts:1500)"
check "ts too far apart (reversed)" 1 "$(rc tstamp_boot_same ts:1500 ts:1000)"
check "unknown boot never expires (a)" 0 "$(rc tstamp_boot_same none ts:5)"
check "unknown boot never expires (b)" 0 "$(rc tstamp_boot_same ts:5 none)"
check "empty token is stale" 1 "$(rc tstamp_boot_same '' ts:5)"
check "mixed kinds are stale" 1 "$(rc tstamp_boot_same id:abc ts:5)"

# --- global flag ---
TSTAMP_BOOT="ts:1000000"
tstamp_global_state
check "off with no flag" off "$TSTAMP_GLOBAL"

tstamp_global_enable
tstamp_global_state
check "on after enable" on "$TSTAMP_GLOBAL"
check_match "since is an epoch" '^[0-9]+$' "$TSTAMP_GLOBAL_SINCE"
check "flag file exists" yes "$([ -f "$TSTAMP_HOME/enabled" ] && echo yes || echo no)"

printf 'boot=ts:9000000\nsince=1\n' > "$TSTAMP_HOME/enabled"
tstamp_global_state
check "flag from another boot is stale" stale "$TSTAMP_GLOBAL"

TSTAMP_BOOT="none"
tstamp_global_state
check "unknown boot keeps the flag on" on "$TSTAMP_GLOBAL"

tstamp_global_disable
tstamp_global_state
check "off after disable" off "$TSTAMP_GLOBAL"
check "flag file removed" no "$([ -f "$TSTAMP_HOME/enabled" ] && echo yes || echo no)"

# --- tstamp_cmd_global_on ---
TSTAMP_BOOT="ts:1000000"
tstamp_cmd_global_on 2 >/dev/null 2>&1
check "global-on saved format 2" 2 "$(tstamp_config_get format x)"
tstamp_global_state
check "global-on enabled the flag" on "$TSTAMP_GLOBAL"
check "global-on rejects bad format" 2 "$(rc tstamp_cmd_global_on abc)"
check "bad format did not change config" 2 "$(tstamp_config_get format x)"

# --- live sessions ---
mkdir -p "$TSTAMP_HOME/sessions/T1" "$TSTAMP_HOME/sessions/T2" "$TSTAMP_HOME/sessions/T3"
echo "$$" > "$TSTAMP_HOME/sessions/T1/pid"
dead="$(bash -c 'echo $$')"
echo "$dead" > "$TSTAMP_HOME/sessions/T2/pid"
echo "notapid" > "$TSTAMP_HOME/sessions/T3/pid"
check "only the live session is listed" "$(printf 'T1\t%s' "$$")" "$(tstamp_sessions_live)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
