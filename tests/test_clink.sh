#!/usr/bin/env bash
# The Command Prompt integration (shells/clink/tstamp.lua) is run against a
# fake Clink with a Lua interpreter, then its log is read back with
# "tstamp export". Skipped when no Lua interpreter is installed.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA=""
for c in lua lua5.4 lua5.3 lua5.2 luajit texlua; do
  if command -v "$c" >/dev/null 2>&1; then LUA="$c"; break; fi
done
if [ -z "$LUA" ]; then
  echo "skip - no Lua interpreter found"
  echo
  echo "passed=0 failed=0 skipped=1"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

out="$(cd "$ROOT/tests/clink" && TZ=UTC "$LUA" mock.lua "$ROOT" "$TMP/home" "$TMP" 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 0 ]; then pass=$((pass + 1)); echo "ok   - the mock run passed"; else fail=$((fail + 1)); echo "FAIL - the mock run failed"; fi

exp="$(TSTAMP_HOME="$TMP/home" bash "$ROOT/bin/tstamp" export 2>&1)"
if printf '%s\n' "$exp" | grep -q 'START: echo reuse'; then
  pass=$((pass + 1)); echo "ok   - tstamp export reads the log written by the Clink script"
else
  fail=$((fail + 1)); echo "FAIL - tstamp export did not show the Clink log"; printf '%s\n' "$exp"
fi

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
