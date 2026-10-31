#!/usr/bin/env bash
# Tests for the web installer, using local files as the "release".

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

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

url_for() { # DIR
  if command -v cygpath >/dev/null 2>&1; then
    printf 'file:///%s' "$(cygpath -m "$1")"
  else
    printf 'file://%s' "$1"
  fi
}

V="$(tr -d '\r\n' < "$ROOT/VERSION")"
bash "$ROOT/installer/build-unix.sh" >/dev/null 2>&1
check "package builds" 0 "$?"

REL="$TMP/release"
mkdir -p "$REL"
cp "$ROOT/dist/tstamp-unix.tar.gz" "$REL/"
printf '%s  %s\n' "$(sha256_of "$REL/tstamp-unix.tar.gz")" tstamp-unix.tar.gz > "$REL/SHA256SUMS.txt"

H="$TMP/home"
mkdir -p "$H"

# --- a good download ---
HOME="$H" TSTAMP_BASE_URL="$(url_for "$REL")" bash "$ROOT/installer/get.sh" \
  --prefix "$TMP/share/tstamp" --bin "$TMP/bin" --no-hook </dev/null > "$TMP/good.out" 2>&1
check "get.sh succeeds" 0 "$?"
check "checksum reported OK" 1 "$(grep -c 'Checksum OK' "$TMP/good.out" || true)"
check "program installed" yes "$(exists "$TMP/share/tstamp/bin/tstamp")"
check "installed command works" "tstamp $V" "$("$TMP/bin/tstamp" version)"
check "no startup file edited without --hook" no "$(exists "$H/.bashrc")"

# --- a damaged download ---
REL2="$TMP/release-bad"
cp -R "$REL" "$REL2"
printf 'x' >> "$REL2/tstamp-unix.tar.gz"
HOME="$H" TSTAMP_BASE_URL="$(url_for "$REL2")" bash "$ROOT/installer/get.sh" \
  --prefix "$TMP/share2/tstamp" --bin "$TMP/bin2" --no-hook </dev/null > "$TMP/bad.out" 2>&1
check "a damaged download is refused (exit 1)" 1 "$?"
check "mismatch is reported" 1 "$(grep -c 'checksum mismatch' "$TMP/bad.out" || true)"
check "nothing installed after a mismatch" no "$(exists "$TMP/share2/tstamp/bin")"

# --- a checksum list without our file ---
REL3="$TMP/release-nosum"
cp -R "$REL" "$REL3"
printf '%s  %s\n' "0000000000000000000000000000000000000000000000000000000000000000" other-file.zip > "$REL3/SHA256SUMS.txt"
HOME="$H" TSTAMP_BASE_URL="$(url_for "$REL3")" bash "$ROOT/installer/get.sh" \
  --prefix "$TMP/share3/tstamp" --bin "$TMP/bin3" --no-hook </dev/null >/dev/null 2>&1
check "a missing checksum entry is refused (exit 1)" 1 "$?"
check "nothing installed without a checksum" no "$(exists "$TMP/share3/tstamp/bin")"

# --- missing files on the server ---
mkdir -p "$TMP/empty"
HOME="$H" TSTAMP_BASE_URL="$(url_for "$TMP/empty")" bash "$ROOT/installer/get.sh" \
  --prefix "$TMP/share4/tstamp" --bin "$TMP/bin4" --no-hook </dev/null >/dev/null 2>&1
rc=$?
check "a failed download is an error" yes "$([ "$rc" -ne 0 ] && echo yes || echo no)"
check "nothing installed after a failed download" no "$(exists "$TMP/share4/tstamp/bin")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
