#!/usr/bin/env bash
# TStamp installer for Linux, macOS, WSL and Git Bash.
# Installs for the current user only. No sudo needed.
# Run it from the unpacked package:
#   bash install.sh [--prefix DIR] [--bin DIR] [--hook | --no-hook]
# Written to run on the old bash 3.2 that ships with macOS.

set -eu

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/tstamp"
BINDIR="$HOME/.local/bin"
HOOK=ask
MARK="# tstamp-wrapper"
ITEMS="bin lib shells docs VERSION README.md LICENSE install.sh uninstall.sh"

usage() {
  cat <<'USAGE'
Usage: bash install.sh [options]

  --prefix DIR   Install the program files in DIR
                 (default: ~/.local/share/tstamp)
  --bin DIR      Put the tstamp and tstamp-a commands in DIR
                 (default: ~/.local/bin)
  --hook         Add TStamp to your bash startup file without asking
  --no-hook      Do not touch any startup file
  -h, --help     Show this help
USAGE
}

need_value() { # OPTION ARGUMENT_COUNT
  if [ "$2" -lt 2 ]; then
    echo "install.sh: $1 needs a value" >&2
    exit 2
  fi
}

check_path() { # NAME VALUE
  case "$2" in
    /*) ;;
    *)
      echo "install.sh: $1 must be an absolute path: $2" >&2
      exit 2
      ;;
  esac
  case "$2" in
    *'"'*|*'$'*|*'`'*|*'\'*)
      echo "install.sh: $1 must not contain \" \$ \` or \\ : $2" >&2
      exit 2
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) need_value "$1" "$#"; PREFIX="$2"; shift 2 ;;
    --bin) need_value "$1" "$#"; BINDIR="$2"; shift 2 ;;
    --hook) HOOK=yes; shift ;;
    --no-hook) HOOK=no; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "install.sh: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

PREFIX="${PREFIX%/}"
BINDIR="${BINDIR%/}"
check_path --prefix "$PREFIX"
check_path --bin "$BINDIR"

if [ ! -f "$SRC/bin/tstamp" ] || [ ! -f "$SRC/shells/bash.sh" ]; then
  echo "install.sh: run this from the unpacked TStamp package." >&2
  exit 1
fi

if [ "$PREFIX" = "$SRC" ]; then
  echo "install.sh: --prefix must not be the folder you are installing from." >&2
  exit 1
fi

if [ -e "$PREFIX" ] && [ ! -f "$PREFIX/bin/tstamp" ]; then
  if [ -n "$(ls -A "$PREFIX" 2>/dev/null)" ]; then
    echo "install.sh: $PREFIX exists and is not a TStamp install; choose another --prefix." >&2
    exit 1
  fi
fi

for name in tstamp tstamp-a; do
  if [ -e "$BINDIR/$name" ] && ! grep -qF "$MARK" "$BINDIR/$name" 2>/dev/null; then
    echo "install.sh: $BINDIR/$name already exists and is not a TStamp command; not overwriting it." >&2
    exit 1
  fi
done

ver="$(bash -c 'printf "%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"' 2>/dev/null || echo 0.0)"
maj="${ver%%.*}"
min="${ver#*.}"
if [ "$maj" -lt 4 ] || { [ "$maj" -eq 4 ] && [ "$min" -lt 4 ]; }; then
  echo "Warning: TStamp needs bash 4.4 or newer; the bash on your PATH is $ver." >&2
  echo "On macOS you can install a current one with: brew install bash" >&2
fi

mkdir -p "$PREFIX" "$BINDIR"
for item in $ITEMS; do
  rm -rf "${PREFIX:?}/$item"
done
for item in $ITEMS; do
  if [ -e "$SRC/$item" ]; then
    cp -R "$SRC/$item" "$PREFIX/$item"
  fi
done
chmod +x "$PREFIX"/bin/* "$PREFIX/install.sh" "$PREFIX/uninstall.sh" 2>/dev/null || true
printf '%s\n' "$BINDIR" > "$PREFIX/.bindir"

for name in tstamp tstamp-a; do
  {
    printf '#!/bin/sh\n%s\n' "$MARK"
    printf 'exec "%s/bin/%s" "$@"\n' "$PREFIX" "$name"
  } > "$BINDIR/$name"
  chmod +x "$BINDIR/$name"
done

RC="$HOME/.bashrc"
if [ "$(uname -s)" = Darwin ]; then
  RC="$HOME/.bash_profile"
fi

do_hook=no
case "$HOOK" in
  yes) do_hook=yes ;;
  no) ;;
  ask)
    if [ -t 0 ] && [ -t 1 ]; then
      printf 'Load TStamp in every new bash window? This edits %s after making a backup. [y/N] ' "$RC"
      read -r ans || ans=n
      case "$ans" in
        y|Y|yes|YES) do_hook=yes ;;
      esac
    fi
    ;;
esac

if [ "$do_hook" = yes ]; then
  "$PREFIX/bin/tstamp" hook add --yes "$RC"
else
  echo "Hook not added. To load TStamp in new bash windows later, run:"
  echo "  tstamp hook add $RC"
fi

echo "TStamp $(cat "$PREFIX/VERSION") installed in $PREFIX"
echo "Commands: $BINDIR/tstamp and $BINDIR/tstamp-a"
case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) echo "Note: $BINDIR is not on your PATH. The hook still works in new bash windows." ;;
esac
echo "Open a new bash window, then type: tstamp-a"
