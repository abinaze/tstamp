#!/usr/bin/env bash
# TStamp web installer for Linux, macOS, WSL and Git Bash.
#
#   curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash
#   curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash -s -- --hook
#
# Downloads the Unix package, checks it against SHA256SUMS.txt from the same
# release, then runs its install.sh. Options are passed on to install.sh.
# The checksum catches a damaged download; it cannot protect you if the
# release itself were replaced.
# Written to run on the old bash 3.2 that ships with macOS.

set -eu

BASE="${TSTAMP_BASE_URL:-https://github.com/abinaze/tstamp/releases/latest/download}"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "get.sh: $1 is required but was not found." >&2
    exit 1
  fi
}

sha256_of() { # FILE
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    echo "get.sh: sha256sum or shasum is required but was not found." >&2
    exit 1
  fi
}

need curl
need tar

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading TStamp from $BASE"
curl -fsSL "$BASE/tstamp-unix.tar.gz" -o "$TMP/tstamp-unix.tar.gz"
curl -fsSL "$BASE/SHA256SUMS.txt" -o "$TMP/SHA256SUMS.txt"

want="$(tr -d '\r' < "$TMP/SHA256SUMS.txt" | grep -E ' \*?tstamp-unix\.tar\.gz$' | head -n 1 | cut -d ' ' -f 1)"
have="$(sha256_of "$TMP/tstamp-unix.tar.gz")"
if [ -z "$want" ] || [ "$want" != "$have" ]; then
  echo "get.sh: checksum mismatch; nothing was installed." >&2
  exit 1
fi
echo "Checksum OK"

tar -xzf "$TMP/tstamp-unix.tar.gz" -C "$TMP"
dir="$(ls -d "$TMP"/tstamp-*/ | head -n 1)"
if [ ! -f "${dir}install.sh" ]; then
  echo "get.sh: the package does not contain install.sh; nothing was installed." >&2
  exit 1
fi
bash "${dir}install.sh" "$@"
