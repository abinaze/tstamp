#!/usr/bin/env bash
# Tests for the .deb package. Needs dpkg-deb, so it only runs on Debian,
# Ubuntu and similar systems; elsewhere it reports a skip.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "skip - dpkg-deb is not available here; the .deb is built and tested on Ubuntu in CI"
  echo
  echo "passed=0 failed=0 skipped=1"
  exit 0
fi

TMP="$(mktemp -d)"
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

V="$(tr -d '\r\n' < "$ROOT/VERSION")"
DV="$(printf '%s' "$V" | sed 's/-/~/')"

bash "$ROOT/installer/build-deb.sh" >/dev/null 2>&1
check "build-deb.sh succeeds" 0 "$?"
DEB="$ROOT/dist/tstamp.deb"
check "tstamp.deb exists" yes "$([ -f "$DEB" ] && echo yes || echo no)"

check "package name" tstamp "$(dpkg-deb -f "$DEB" Package)"
check "package version" "$DV" "$(dpkg-deb -f "$DEB" Version)"
check "architecture" all "$(dpkg-deb -f "$DEB" Architecture)"
check "depends on a new enough bash" "bash (>= 4.4)" "$(dpkg-deb -f "$DEB" Depends)"

LIST="$(dpkg-deb -c "$DEB")"
for f in ./usr/bin/tstamp ./usr/bin/tstamp-a ./usr/share/tstamp/bin/tstamp \
         ./usr/share/tstamp/lib/config.sh ./usr/share/tstamp/lib/profile.sh \
         ./usr/share/tstamp/shells/bash.sh ./usr/share/tstamp/docs/manual.txt \
         ./usr/share/doc/tstamp/copyright; do
  check "contains $f" 1 "$(printf '%s\n' "$LIST" | grep -c " $f\$" || true)"
done
check "no tests inside" 0 "$(printf '%s\n' "$LIST" | grep -c '/tests' || true)"
check "no installer sources inside" 0 "$(printf '%s\n' "$LIST" | grep -c '/installer' || true)"
check "every entry is owned by root" "$(printf '%s\n' "$LIST" | wc -l | tr -d ' ')" "$(printf '%s\n' "$LIST" | grep -c ' root/root ' || true)"

dpkg-deb -x "$DEB" "$TMP/x"
check "program runs from the extracted package" "tstamp $V" "$(bash "$TMP/x/usr/share/tstamp/bin/tstamp" version)"
check "wrapper points at the installed program" 'exec /usr/share/tstamp/bin/tstamp "$@"' "$(sed -n 2p "$TMP/x/usr/bin/tstamp")"
check "wrapper is executable" yes "$([ -x "$TMP/x/usr/bin/tstamp" ] && echo yes || echo no)"
check "tstamp-a wrapper is executable" yes "$([ -x "$TMP/x/usr/bin/tstamp-a" ] && echo yes || echo no)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
