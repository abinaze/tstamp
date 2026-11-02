#!/usr/bin/env bash
# Startup files saved with Windows line endings must come back byte for byte
# after an add and a remove, on every system.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# shellcheck source=/dev/null
source "$ROOT/lib/profile.sh"
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
same() { cmp -s "$1" "$2" && echo yes || echo no; }

F="$TMP/crlf"
printf 'export A=1\r\nalias ll="ls -l"\r\n' > "$F"
cp "$F" "$TMP/orig"
tstamp_profile_add "$F" "$ROOT" >/dev/null
check "add keeps the original CRLF lines" "$(head -c 24 "$TMP/orig" | od -An -c)" "$(head -c 24 "$F" | od -An -c)"
tstamp_profile_remove "$F" >/dev/null
check "CRLF file is restored byte for byte" yes "$(same "$F" "$TMP/orig")"

G="$TMP/mixed"
printf 'one\r\ntwo\n\r\nthree\r\n' > "$G"
cp "$G" "$TMP/orig2"
tstamp_profile_add "$G" "$ROOT" >/dev/null
tstamp_profile_remove "$G" >/dev/null
check "a file with mixed line endings and a blank CRLF line is restored" yes "$(same "$G" "$TMP/orig2")"

H="$TMP/backslashes"
printf 'echo "a\\tb" \\\r\nnext\r\n' > "$H"
cp "$H" "$TMP/orig3"
tstamp_profile_add "$H" "$ROOT" >/dev/null
tstamp_profile_remove "$H" >/dev/null
check "backslashes and leading spaces survive" yes "$(same "$H" "$TMP/orig3")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
