#!/usr/bin/env bash
# Tests for installer/stage.sh and for running TStamp from the staged copy.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$ROOT/dist/stage"
TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
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

exists() { [ -e "$1" ] && echo yes || echo no; }

bash "$ROOT/installer/stage.sh" >/dev/null 2>&1
check "stage.sh succeeds" 0 "$?"
bash "$ROOT/installer/stage.sh" >/dev/null 2>&1
check "stage.sh can run twice" 0 "$?"

for f in bin/tstamp bin/tstamp-a lib/config.sh lib/format.sh lib/clock.sh lib/state.sh \
         lib/export.sh lib/profile.sh shells/bash.sh docs/help.txt docs/manual.txt \
         docs/examples.txt VERSION README.md; do
  check "staged $f" yes "$(exists "$S/$f")"
done

check "tests are not staged" no "$(exists "$S/tests")"
check "installer sources are not staged" no "$(exists "$S/installer")"
check "git files are not staged" no "$(exists "$S/.git")"
check "no CRLF in staged scripts" 0 "$(cat "$S"/bin/* "$S"/lib/* "$S"/shells/* "$S/VERSION" | tr -cd "\r" | wc -c | tr -d ' ')"

check "staged copy reports the version" "tstamp $(cat "$ROOT/VERSION")" "$(bash "$S/bin/tstamp" version)"
bash "$S/bin/tstamp" help >/dev/null 2>&1
check "staged help works" 0 "$?"

printf 'x\n' > "$TMP/rc"
bash "$S/bin/tstamp" hook add --yes "$TMP/rc" >/dev/null 2>&1
check "staged hook points at the staged folder" 1 "$(grep -cF "source \"$S/shells/bash.sh\"" "$TMP/rc")"

mkdir -p "$TMP/home"
bash "$S/bin/tstamp" hook add --yes "$TMP/home/.bashrc" >/dev/null 2>&1
HOME="$TMP/home" bash --rcfile "$TMP/home/.bashrc" -i > "$TMP/load.out" 2>&1 <<'IN'
type tstamp
type tstamp-a
exit
IN
check "terminal loads the staged hook: tstamp" 1 "$(grep -c 'tstamp is a function' "$TMP/load.out")"
check "terminal loads the staged hook: tstamp-a" 1 "$(grep -c 'tstamp-a is a function' "$TMP/load.out")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
