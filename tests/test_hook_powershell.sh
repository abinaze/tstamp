#!/usr/bin/env bash
# Tests for "tstamp hook add --powershell". Windows only. They use a temporary
# profile file (TSTAMP_PS_PROFILE); the real PowerShell profile is never touched.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "skip - PowerShell profile tests run on Windows only"; echo; echo "passed=0 failed=0 skipped=1"; exit 0 ;;
esac
command -v powershell >/dev/null 2>&1 || { echo "skip - powershell.exe not found"; echo; echo "passed=0 failed=0 skipped=1"; exit 0; }

TMP="$(mktemp -d)"
export TSTAMP_HOME="$TMP/state"
export TSTAMP_PS_PROFILE="$TMP/profile/dir/Microsoft.PowerShell_profile.ps1"
trap 'rm -rf "$TMP"' EXIT
T="$ROOT/bin/tstamp"
P="$TSTAMP_PS_PROFILE"
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
count() { grep -cF -- "$1" "$2" || true; }
same() { cmp -s "$1" "$2" && echo yes || echo no; }

bash "$T" hook add --powershell </dev/null >/dev/null 2>&1
check "no --yes and no terminal is refused (exit 2)" 2 "$?"
check "refused add created nothing" no "$([ -e "$P" ] && echo yes || echo no)"

bash "$T" hook add --powershell --yes >/dev/null 2>&1
check "add succeeds and creates the missing profile folder" 0 "$?"
check "one block in the profile" 1 "$(count '# >>> tstamp >>>' "$P")"
WIN="$(cygpath -w "$ROOT")"
check "block loads powershell.ps1 from the install folder" 1 "$(count "'$WIN\\shells\\powershell.ps1'" "$P")"

out="$(powershell -NoProfile -ExecutionPolicy Bypass -Command ". '$(cygpath -w "$P")'; if (Get-Command tstamp-a -ErrorAction SilentlyContinue) { 'loaded' }" 2>&1)"
check "PowerShell loads tstamp from the profile" 1 "$(printf '%s\n' "$out" | grep -c '^loaded' || true)"

bash "$T" hook add --powershell --yes >/dev/null 2>&1
check "adding twice keeps one block" 1 "$(count '# >>> tstamp >>>' "$P")"
bash "$T" hook remove --powershell --yes >/dev/null 2>&1
check "remove takes the block out" 0 "$(count '# >>> tstamp >>>' "$P")"

# an existing profile with Windows line endings comes back byte for byte
printf 'Write-Host "hello"\r\nSet-Alias ll Get-ChildItem\r\n' > "$P"
cp "$P" "$TMP/orig"
bash "$T" hook add --powershell --yes >/dev/null 2>&1
check "existing lines survive the add" 'Write-Host "hello"' "$(head -n 1 "$P" | tr -d '\r')"
bash "$T" hook remove --powershell --yes >/dev/null 2>&1
check "remove restores the original profile byte for byte" yes "$(same "$P" "$TMP/orig")"
check "a backup was made" yes "$(ls "$P".tstamp-backup-* >/dev/null 2>&1 && echo yes || echo no)"

# a UTF-16 profile is refused, not corrupted
printf '\377\376A\000' > "$P"
cp "$P" "$TMP/utf16"
bash "$T" hook add --powershell --yes >/dev/null 2>&1
check "a UTF-16 profile is refused (exit 1)" 1 "$?"
check "the UTF-16 profile is unchanged" yes "$(same "$P" "$TMP/utf16")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
