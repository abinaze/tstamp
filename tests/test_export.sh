#!/usr/bin/env bash
# Tests for tstamp export, using hand-made logs with known timestamps.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/bin/tstamp"
TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
export TZ=UTC
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }

mkdir -p "$TSTAMP_HOME/logs"
{
  row 1700000001000000 T1 100 START "" "" build
  row 1700000004100000 T1 100 END 1 3100000 build
} > "$TSTAMP_HOME/logs/T1-100.log"
{
  row 1700000002500000 T2 200 START "" "" "echo hi"
  row 1700000002600000 T2 200 END 0 100000 "echo hi"
} > "$TSTAMP_HOME/logs/T2-200.log"

L1='[T1][2023-11-14 22:13:21.000] START: build'
L2='[T2][2023-11-14 22:13:22.500] START: echo hi'
L3='[T2][2023-11-14 22:13:22.600] END: echo hi | EXIT=0 | DURATION=0.10s'
L4='[T1][2023-11-14 22:13:24.100] END: build | EXIT=1 | DURATION=3.10s'
ALL="$L1"$'\n'"$L2"$'\n'"$L3"$'\n'"$L4"

check "all sessions merged in time order" "$ALL" "$(bash "$T" export)"
check "only T2" "$L2"$'\n'"$L3" "$(bash "$T" export T2)"
check "only T1" "$L1"$'\n'"$L4" "$(bash "$T" export T1)"
check "T1 and T2 together" "$ALL" "$(bash "$T" export T1 T2)"
check "order of session arguments does not matter" "$ALL" "$(bash "$T" export T2 T1)"

bash "$T" set 2 >/dev/null
check "export follows the saved format" '[T1][22:13:21] START: build' "$(bash "$T" export T1 | head -n 1)"
bash "$T" reset >/dev/null

OUTF="$TMP/report.txt"
bash "$T" export -o "$OUTF" >/dev/null 2>&1
check "-o writes the report to a file" "$ALL" "$(cat "$OUTF")"
bash "$T" export -o "$OUTF" >/dev/null 2>&1
check "-o refuses to overwrite (exit 1)" 1 "$?"
check "-o left the existing file unchanged" "$ALL" "$(cat "$OUTF")"

bash "$T" export foo >/dev/null 2>&1
check "invalid session ID exits 2" 2 "$?"
bash "$T" export --bogus >/dev/null 2>&1
check "unknown option exits 2" 2 "$?"
bash "$T" export -o >/dev/null 2>&1
check "-o without a name exits 2" 2 "$?"
bash "$T" export T9 >/dev/null 2>&1
check "session with no logs exits 1" 1 "$?"

TSTAMP_HOME="$TMP/empty" bash "$T" export >/dev/null 2>&1
check "no logs at all exits 1" 1 "$?"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
