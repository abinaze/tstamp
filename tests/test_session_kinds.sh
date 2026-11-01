#!/usr/bin/env bash
# Sessions owned by another shell family (PowerShell) must never be reclaimed
# or listed by bash, because their process IDs mean something else to bash.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}

mkdir -p "$TSTAMP_HOME/sessions/T1" "$TSTAMP_HOME/sessions/T2"
echo 4194000 > "$TSTAMP_HOME/sessions/T1/pid"
echo windows > "$TSTAMP_HOME/sessions/T1/kind"
bash -c 'echo $$' > "$TSTAMP_HOME/sessions/T2/pid"

# shellcheck source=/dev/null
source "$ROOT/lib/config.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/format.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/state.sh"
check "bash does not list a session owned by another shell family" 0 "$(tstamp_sessions_live | grep -c '^T1' || true)"

HISTFILE="$TMP/history" bash --noprofile --norc -i > "$TMP/out" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
tstamp
exit
INPUT
check "bash skips the other family's session and does not reclaim it" 1 "$(grep -c 'session T3' "$TMP/out" || true)"
check "the other family's session folder is untouched" yes "$([ -f "$TSTAMP_HOME/sessions/T1/kind" ] && echo yes || echo no)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
