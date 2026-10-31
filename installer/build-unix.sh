#!/usr/bin/env bash
# Builds dist/tstamp-unix.tar.gz for Linux, macOS and WSL.
# The archive holds one folder, tstamp-VERSION, with the runtime files and
# the install and uninstall scripts. It never contains tests or git files.

set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT/VERSION")"
NAME="tstamp-$VERSION"
WORK="$ROOT/dist/unix"

# Only ever delete the generated work folder.
case "$WORK" in
  "$ROOT"/dist/unix) ;;
  *) echo "build-unix: refusing to touch $WORK" >&2; exit 1 ;;
esac

bash "$ROOT/installer/stage.sh" >/dev/null
rm -rf "$WORK"
mkdir -p "$WORK/$NAME"
cp -R "$ROOT/dist/stage/." "$WORK/$NAME/"
cp "$ROOT/installer/unix/install.sh" "$ROOT/installer/unix/uninstall.sh" "$WORK/$NAME/"
chmod +x "$WORK/$NAME"/bin/* "$WORK/$NAME/install.sh" "$WORK/$NAME/uninstall.sh"

rm -f "$ROOT/dist/tstamp-unix.tar.gz"
tar -czf "$ROOT/dist/tstamp-unix.tar.gz" -C "$WORK" "$NAME"
echo "Built dist/tstamp-unix.tar.gz ($NAME)"
