#!/usr/bin/env bash
# Tests for the Unix package: build, install, reinstall, refusals, uninstall.
# Everything happens in a temporary HOME. Real files are never touched.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
count() { grep -cF -- "$1" "$2" || true; }
crcount() { tr -cd '\r' < "$1" | wc -c | tr -d ' '; }

# --- build the package ---
bash "$ROOT/installer/build-unix.sh" >/dev/null 2>&1
check "build-unix.sh succeeds" 0 "$?"
PKG="$ROOT/dist/tstamp-unix.tar.gz"
check "package file exists" yes "$(exists "$PKG")"

V="$(tr -d '\r\n' < "$ROOT/VERSION")"
tar -xzf "$PKG" -C "$TMP"
D="$TMP/tstamp-$V"

for f in bin/tstamp bin/tstamp-a lib/config.sh lib/format.sh lib/clock.sh lib/state.sh \
         lib/export.sh lib/profile.sh shells/bash.sh docs/manual.txt docs/help.txt \
         docs/examples.txt VERSION README.md LICENSE install.sh uninstall.sh; do
  check "package contains $f" yes "$(exists "$D/$f")"
done
check "package has no tests" 0 "$(tar -tzf "$PKG" | grep -c '/tests/' || true)"
check "package has no installer sources" 0 "$(tar -tzf "$PKG" | grep -c '/installer/' || true)"
check "package has no git files" 0 "$(tar -tzf "$PKG" | grep -c '\.git' || true)"
check "install.sh has no CRLF" 0 "$(crcount "$D/install.sh")"
check "uninstall.sh has no CRLF" 0 "$(crcount "$D/uninstall.sh")"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
    check "install.sh is executable in the package" yes "$([ -x "$D/install.sh" ] && echo yes || echo no)"
    check "bin/tstamp is executable in the package" yes "$([ -x "$D/bin/tstamp" ] && echo yes || echo no)"
    ;;
esac

# --- install without the hook ---
H="$TMP/home"
P="$TMP/share/tstamp"
B="$TMP/bin"
mkdir -p "$H"
if [ "$(uname -s)" = Darwin ]; then RC="$H/.bash_profile"; else RC="$H/.bashrc"; fi

HOME="$H" bash "$D/install.sh" --prefix "$P" --bin "$B" --no-hook >/dev/null 2>&1
check "install --no-hook succeeds" 0 "$?"
check "program installed" yes "$(exists "$P/bin/tstamp")"
check "tstamp command created" yes "$(exists "$B/tstamp")"
check "tstamp-a command created" yes "$(exists "$B/tstamp-a")"
check "bin folder recorded" "$B" "$(cat "$P/.bindir")"
check "no startup file created with --no-hook" no "$(exists "$RC")"
check "wrapper runs the installed program" "tstamp $V" "$("$B/tstamp" version)"

"$B/tstamp-a" 2 >/dev/null 2>&1
check "tstamp-a wrapper enables global tracking" yes "$(exists "$TSTAMP_HOME/enabled")"
"$B/tstamp" stop >/dev/null 2>&1
check "tstamp stop wrapper disables it" no "$(exists "$TSTAMP_HOME/enabled")"

# --- install with the hook, then reinstall ---
HOME="$H" bash "$D/install.sh" --prefix "$P" --bin "$B" --hook >/dev/null 2>&1
check "install --hook succeeds" 0 "$?"
check "hook block added to the startup file" 1 "$(count '# >>> tstamp >>>' "$RC")"
check "block points at the installed copy" 1 "$(count "source \"$P/shells/bash.sh\"" "$RC")"

HOME="$H" bash --rcfile "$RC" -i > "$TMP/load.out" 2>&1 <<'IN'
type tstamp
exit
IN
check "a new bash loads the installed hook" 1 "$(grep -c 'tstamp is a function' "$TMP/load.out" || true)"

HOME="$H" bash "$D/install.sh" --prefix "$P" --bin "$B" --hook >/dev/null 2>&1
check "reinstall succeeds" 0 "$?"
check "reinstall keeps a single hook block" 1 "$(count '# >>> tstamp >>>' "$RC")"

# --- refusals ---
mkdir -p "$TMP/bin2"
printf '#!/bin/sh\necho mine\n' > "$TMP/bin2/tstamp"
HOME="$H" bash "$D/install.sh" --prefix "$TMP/share2/tstamp" --bin "$TMP/bin2" --no-hook >/dev/null 2>&1
check "a foreign tstamp command is not overwritten (exit 1)" 1 "$?"
check "the foreign command is unchanged" "echo mine" "$(sed -n 2p "$TMP/bin2/tstamp")"

mkdir -p "$TMP/other"
echo keep > "$TMP/other/file.txt"
HOME="$H" bash "$D/install.sh" --prefix "$TMP/other" --bin "$TMP/bin3" --no-hook >/dev/null 2>&1
check "a foreign non-empty folder is refused (exit 1)" 1 "$?"
check "the foreign folder is unchanged" keep "$(cat "$TMP/other/file.txt")"

HOME="$H" bash "$D/install.sh" --prefix '/tmp/bad"dir' --bin "$TMP/bin4" --no-hook >/dev/null 2>&1
check "an unsafe prefix is refused (exit 2)" 2 "$?"
HOME="$H" bash "$D/install.sh" --prefix relative/dir --bin "$TMP/bin4" --no-hook >/dev/null 2>&1
check "a relative prefix is refused (exit 2)" 2 "$?"
HOME="$H" bash "$D/install.sh" --bogus >/dev/null 2>&1
check "an unknown option is refused (exit 2)" 2 "$?"

# --- uninstall ---
HOME="$H" bash "$P/uninstall.sh" </dev/null >/dev/null 2>&1
check "uninstall succeeds" 0 "$?"
check "hook block removed from the startup file" 0 "$(count '# >>> tstamp >>>' "$RC")"
check "tstamp command removed" no "$(exists "$B/tstamp")"
check "tstamp-a command removed" no "$(exists "$B/tstamp-a")"
check "program files removed" no "$(exists "$P/bin")"
check "settings and logs are kept without a prompt" yes "$(exists "$TSTAMP_HOME/config")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
