#!/usr/bin/env bash
# Builds dist/tstamp.deb for Debian, Ubuntu and derivatives.
# Needs dpkg-deb. Exits with status 3 where it is not available.

set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT/VERSION")"
# Debian sorts 0.1.0~rc1 before 0.1.0, which is what a release candidate needs.
DEB_VERSION="$(printf '%s' "$VERSION" | sed 's/-/~/')"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "build-deb: dpkg-deb not found. Build this package on Debian or Ubuntu." >&2
  exit 3
fi
if [[ ! "$DEB_VERSION" =~ ^[0-9][A-Za-z0-9.+~]*$ ]]; then
  echo "build-deb: unsupported version for a .deb: $DEB_VERSION" >&2
  exit 1
fi

WORK="$ROOT/dist/deb"
case "$WORK" in
  "$ROOT"/dist/deb) ;;
  *) echo "build-deb: refusing to touch $WORK" >&2; exit 1 ;;
esac

bash "$ROOT/installer/stage.sh" >/dev/null
rm -rf "$WORK"
PKG="$WORK/tstamp"
mkdir -p "$PKG/DEBIAN" "$PKG/usr/bin" "$PKG/usr/share/tstamp" "$PKG/usr/share/doc/tstamp"

cp -R "$ROOT/dist/stage/." "$PKG/usr/share/tstamp/"
cp "$ROOT/LICENSE" "$PKG/usr/share/doc/tstamp/copyright"

for name in tstamp tstamp-a; do
  {
    printf '#!/bin/sh\n'
    printf 'exec /usr/share/tstamp/bin/%s "$@"\n' "$name"
  } > "$PKG/usr/bin/$name"
done

find "$PKG" -type d -exec chmod 755 {} +
find "$PKG" -type f -exec chmod 644 {} +
chmod 755 "$PKG"/usr/bin/* "$PKG"/usr/share/tstamp/bin/*

SIZE="$(du -sk "$PKG/usr" | cut -f 1)"
cat > "$PKG/DEBIAN/control" <<CONTROL
Package: tstamp
Version: $DEB_VERSION
Architecture: all
Maintainer: abinaze <abinaze@users.noreply.github.com>
Depends: bash (>= 4.4)
Installed-Size: $SIZE
Section: utils
Priority: optional
Homepage: https://github.com/abinaze/tstamp
Description: Timestamp every command in your terminal
 TStamp prints a START and an END line, with exit code and duration,
 around every command you run in bash. It works across terminals, keeps
 one log per terminal and stays local: no network, no telemetry and no
 background service.
 .
 After installing, run "tstamp hook add" once to load it in new bash
 windows. Run "tstamp hook remove" before removing the package.
CONTROL
chmod 644 "$PKG/DEBIAN/control"

mkdir -p "$ROOT/dist"
rm -f "$ROOT/dist/tstamp.deb"
dpkg-deb --root-owner-group --build "$PKG" "$ROOT/dist/tstamp.deb" >/dev/null
echo "Built dist/tstamp.deb ($DEB_VERSION)"
