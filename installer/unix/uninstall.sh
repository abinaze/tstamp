#!/usr/bin/env bash
# Removes a per-user TStamp install made by install.sh.
# Run it from the install folder:  bash ~/.local/share/tstamp/uninstall.sh
# Written to run on the old bash 3.2 that ships with macOS.

main() {
  set -eu
  local prefix mark bindir rc name item state ans
  prefix="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  mark="# tstamp-wrapper"

  if [ ! -f "$prefix/bin/tstamp" ] || [ ! -f "$prefix/.bindir" ]; then
    echo "uninstall.sh: $prefix does not look like a TStamp install; nothing removed." >&2
    return 1
  fi
  bindir="$(cat "$prefix/.bindir")"

  for rc in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && grep -qF '# >>> tstamp >>>' "$rc"; then
      "$prefix/bin/tstamp" hook remove --yes "$rc" || echo "Could not edit $rc. Remove the TStamp block by hand."
    fi
  done

  for name in tstamp tstamp-a; do
    if [ -f "$bindir/$name" ] && grep -qF "$mark" "$bindir/$name"; then
      rm -f "$bindir/$name"
    fi
  done

  for item in bin lib shells docs VERSION README.md LICENSE install.sh .bindir; do
    rm -rf "${prefix:?}/$item"
  done
  echo "TStamp program files removed from $prefix"

  state="${TSTAMP_HOME:-$HOME/.tstamp}"
  if [ -d "$state" ] && [ "$state" != "$HOME" ] && [ "$state" != "/" ] \
     && { [ -f "$state/config" ] || [ -d "$state/logs" ]; } \
     && [ -t 0 ] && [ -t 1 ]; then
    printf 'Also delete your TStamp settings and logs in %s? [y/N] ' "$state"
    read -r ans || ans=n
    case "$ans" in
      y|Y|yes|YES)
        rm -rf "$state"
        echo "Deleted $state"
        ;;
    esac
  fi

  rm -f "$prefix/uninstall.sh" 2>/dev/null || true
  rmdir "$prefix" 2>/dev/null || true
  return 0
}

main "$@"
exit $?
