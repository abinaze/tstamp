#!/usr/bin/env bash
# "tstamp hook add" without a file chooses the right startup files: ~/.bashrc
# normally, and both ~/.bash_profile and ~/.bashrc on a Mac. Uses a temporary HOME.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"
# shellcheck source=/dev/null
source "$ROOT/lib/profile.sh"
TSTAMP_ROOT="$ROOT"
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
blocks() { if [ -f "$1" ]; then grep -cF '# >>> tstamp >>>' "$1" || true; else echo 0; fi; }

uname() { echo Linux; }
tstamp_cmd_hook add --yes >/dev/null 2>&1
check "Linux: the block goes into ~/.bashrc" 1 "$(blocks "$HOME/.bashrc")"
check "Linux: ~/.bash_profile is not touched" no "$([ -e "$HOME/.bash_profile" ] && echo yes || echo no)"
tstamp_cmd_hook remove --yes >/dev/null 2>&1
check "Linux: remove takes it out again" 0 "$(blocks "$HOME/.bashrc")"

uname() { echo Darwin; }
tstamp_cmd_hook add --yes >/dev/null 2>&1
check "Mac: the block goes into ~/.bash_profile" 1 "$(blocks "$HOME/.bash_profile")"
check "Mac: and into ~/.bashrc" 1 "$(blocks "$HOME/.bashrc")"
tstamp_cmd_hook add --yes >/dev/null 2>&1
check "Mac: adding twice keeps one block" 1 "$(blocks "$HOME/.bash_profile")"
tstamp_cmd_hook remove --yes >/dev/null 2>&1
check "Mac: remove clears ~/.bash_profile" 0 "$(blocks "$HOME/.bash_profile")"
check "Mac: remove clears ~/.bashrc" 0 "$(blocks "$HOME/.bashrc")"

tstamp_cmd_hook add --yes "$TMP/custom" >/dev/null 2>&1
check "an explicit file always wins" 1 "$(blocks "$TMP/custom")"
check "and nothing else is touched then" 0 "$(blocks "$HOME/.bash_profile")"
unset -f uname

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
