#!/usr/bin/env bash
# Collects the runtime files into dist/stage for the Windows installer.
# Tests, installer sources and git files are deliberately left out.

set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="$ROOT/dist/stage"

# Only ever delete the generated staging folder.
case "$STAGE" in
  "$ROOT"/dist/stage) ;;
  *) echo "stage: refusing to touch $STAGE" >&2; exit 1 ;;
esac
rm -rf "$STAGE"

mkdir -p "$STAGE/bin" "$STAGE/lib" "$STAGE/shells" "$STAGE/docs"
cp "$ROOT/bin/tstamp" "$ROOT/bin/tstamp-a" "$STAGE/bin/"
cp "$ROOT"/lib/*.sh "$STAGE/lib/"
cp "$ROOT/shells/bash.sh" "$STAGE/shells/"
cp "$ROOT"/docs/*.txt "$STAGE/docs/"
cp "$ROOT/VERSION" "$ROOT/README.md" "$STAGE/"
if [ -f "$ROOT/LICENSE" ]; then
  cp "$ROOT/LICENSE" "$STAGE/"
fi

# Scripts with Windows line endings break on the shebang line.
# (tr is used because grep cannot take a bare CR as a pattern in Git Bash.)
bad=""
for f in "$STAGE"/bin/* "$STAGE"/lib/* "$STAGE"/shells/* "$STAGE/VERSION"; do
  if [ -n "$(tr -cd '\r' < "$f" | head -c 1)" ]; then
    bad="$bad$f"$'\n'
  fi
done
if [ -n "$bad" ]; then
  echo "stage: CRLF line endings found in:" >&2
  printf '%s' "$bad" >&2
  exit 1
fi

echo "Staged $(find "$STAGE" -type f | wc -l | tr -d ' ') files in dist/stage"
