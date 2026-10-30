#!/usr/bin/env bash
# Tests for startup-file editing. Only temporary files are touched; the
# real ~/.bashrc is never read or changed.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/bin/tstamp"
TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
trap 'rm -rf "$TMP"' EXIT

# shellcheck source=/dev/null
source "$ROOT/lib/profile.sh"

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

same() { cmp -s "$1" "$2" && echo yes || echo no; }
count() { grep -cF -- "$1" "$2"; }
rc() { "$@" >/dev/null 2>&1; echo "$?"; }

# --- add and remove on a normal file ---
RC="$TMP/rc1"
printf 'export FOO=1\nalias ll="ls -l"\n# end\n' > "$RC"
cp "$RC" "$TMP/rc1.orig"
tstamp_profile_add "$RC" "$ROOT" >/dev/null
check "begin marker added once" 1 "$(count '# >>> tstamp >>>' "$RC")"
check "end marker added once" 1 "$(count '# <<< tstamp <<<' "$RC")"
check "original lines kept" "$(cat "$TMP/rc1.orig")" "$(head -n 3 "$RC")"
check "source line points at the install folder" 1 "$(count "source \"$ROOT/shells/bash.sh\"" "$RC")"
set -- "$RC".tstamp-backup-*
check "one backup created" 1 "$#"
check "backup equals the original" yes "$(same "$1" "$TMP/rc1.orig")"

tstamp_profile_add "$RC" "$ROOT" >/dev/null
check "second add changes nothing" 1 "$(count '# >>> tstamp >>>' "$RC")"
set -- "$RC".tstamp-backup-*
check "second add makes no extra backup" 1 "$#"

tstamp_profile_remove "$RC" >/dev/null
check "remove restores the original byte for byte" yes "$(same "$RC" "$TMP/rc1.orig")"
check "remove again is harmless" 0 "$(rc tstamp_profile_remove "$RC")"

# --- file without a trailing newline ---
RC2="$TMP/rc2"
printf 'a\nb' > "$RC2"
tstamp_profile_add "$RC2" "$ROOT" >/dev/null
check "no-newline file: lines kept" "$(printf 'a\nb')" "$(head -n 2 "$RC2")"
check "no-newline file: marker on its own line" 1 "$(grep -cx -- '# >>> tstamp >>>' "$RC2")"
tstamp_profile_remove "$RC2" >/dev/null
check "no-newline file: content restored" "$(printf 'a\nb')" "$(cat "$RC2")"

# --- file that does not exist yet ---
RC3="$TMP/rc3"
tstamp_profile_add "$RC3" "$ROOT" >/dev/null
check "missing file is created with the block" 1 "$(count '# >>> tstamp >>>' "$RC3")"
set -- "$RC3".tstamp-backup-*
check "no backup for a file that did not exist" "$RC3.tstamp-backup-*" "$1"

# --- unsafe paths and damaged blocks ---
RC4="$TMP/rc4"
printf 'x\n' > "$RC4"
check "path with a quote is refused" 1 "$(rc tstamp_profile_add "$RC4" '/bad"path')"
check "path with a dollar sign is refused" 1 "$(rc tstamp_profile_add "$RC4" '/bad$path')"
check "refused add leaves the file alone" x "$(cat "$RC4")"

RC5="$TMP/rc5"
printf 'x\n# >>> tstamp >>>\ny\n' > "$RC5"
cp "$RC5" "$TMP/rc5.orig"
check "remove refuses without an end marker" 1 "$(rc tstamp_profile_remove "$RC5")"
check "refused remove leaves the file alone" yes "$(same "$RC5" "$TMP/rc5.orig")"

# --- the tstamp hook command ---
RC6="$TMP/rc6"
printf 'keep\n' > "$RC6"
cp "$RC6" "$TMP/rc6.orig"
check "hook add without --yes and no terminal exits 2" 2 "$(bash "$T" hook add "$RC6" </dev/null >/dev/null 2>&1; echo $?)"
check "refused hook add left the file alone" yes "$(same "$RC6" "$TMP/rc6.orig")"
bash "$T" hook add --yes "$RC6" >/dev/null 2>&1
check "hook add --yes adds the block" 1 "$(count '# >>> tstamp >>>' "$RC6")"
bash "$T" hook remove --yes "$RC6" >/dev/null 2>&1
check "hook remove --yes restores the file" yes "$(same "$RC6" "$TMP/rc6.orig")"
check "unknown hook action exits 2" 2 "$(bash "$T" hook bogus >/dev/null 2>&1; echo $?)"
check "hook without an action exits 2" 2 "$(bash "$T" hook >/dev/null 2>&1; echo $?)"

# --- a new terminal really loads the hook from the added block ---
mkdir -p "$TMP/home"
bash "$T" hook add --yes "$TMP/home/.bashrc" >/dev/null 2>&1
HOME="$TMP/home" bash --rcfile "$TMP/home/.bashrc" -i > "$TMP/load.out" 2>&1 <<'IN'
type tstamp
type tstamp-a
exit
IN
check "new terminal has the tstamp function" 1 "$(grep -c 'tstamp is a function' "$TMP/load.out")"
check "new terminal has the tstamp-a function" 1 "$(grep -c 'tstamp-a is a function' "$TMP/load.out")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
