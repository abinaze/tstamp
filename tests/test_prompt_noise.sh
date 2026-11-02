#!/usr/bin/env bash
# The hook must never track its own prompt code, an empty Enter, or other
# tools' PROMPT_COMMAND entries.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}

HISTFILE="$TMP/history" bash --noprofile --norc -i > "$TMP/out" 2>&1 <<INPUT
PROMPT_COMMAND='OTHERTOOL=1'
source "$ROOT/shells/bash.sh"
tstamp


echo a

echo b
exit
INPUT

check "empty Enter does not track the hook's own functions" 0 "$(grep -c 'START: __tstamp' "$TMP/out" || true)"
check "another tool's prompt command is not tracked" 0 "$(grep -c 'START: OTHERTOOL' "$TMP/out" || true)"
check "echo a is tracked once" 1 "$(grep -c 'START: echo a$' "$TMP/out" || true)"
check "echo b is tracked once" 1 "$(grep -c 'START: echo b$' "$TMP/out" || true)"
check "exactly two commands were tracked, besides exit" 2 "$(grep 'START:' "$TMP/out" | grep -vc 'START: exit$' || true)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
