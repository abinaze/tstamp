#!/usr/bin/env bash
# TStamp config handling. Source this file; do not execute it.
# Config is a plain key=value file. It is parsed, never sourced.

: "${TSTAMP_HOME:=$HOME/.tstamp}"
TSTAMP_DEFAULT_FORMAT="4"

_tstamp_config_file() {
  printf '%s/config' "$TSTAMP_HOME"
}

# Create the home directory and a default config if missing.
tstamp_config_init() {
  local f
  mkdir -p "$TSTAMP_HOME" || return 1
  f="$(_tstamp_config_file)"
  [ -e "$f" ] || printf 'format=%s\n' "$TSTAMP_DEFAULT_FORMAT" > "$f"
}

# Usage: tstamp_config_get KEY [DEFAULT]
tstamp_config_get() {
  local key="$1" default="${2-}" f k v
  f="$(_tstamp_config_file)"
  if [ -f "$f" ]; then
    while IFS='=' read -r k v || [ -n "$k" ]; do
      if [ "$k" = "$key" ]; then
        printf '%s\n' "$v"
        return 0
      fi
    done < "$f"
  fi
  printf '%s\n' "$default"
}

# Usage: tstamp_config_set KEY VALUE
tstamp_config_set() {
  local key="$1" value="$2" f tmp k v found=0
  tstamp_config_init || return 1
  f="$(_tstamp_config_file)"
  tmp="$f.tmp.$$"
  : > "$tmp" || return 1
  while IFS='=' read -r k v || [ -n "$k" ]; do
    if [ "$k" = "$key" ]; then
      printf '%s=%s\n' "$key" "$value" >> "$tmp"
      found=1
    elif [ -n "$k" ]; then
      printf '%s=%s\n' "$k" "$v" >> "$tmp"
    fi
  done < "$f"
  [ "$found" -eq 1 ] || printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$f"
}

# Restore the default configuration.
tstamp_config_reset() {
  mkdir -p "$TSTAMP_HOME" || return 1
  printf 'format=%s\n' "$TSTAMP_DEFAULT_FORMAT" > "$(_tstamp_config_file)"
}
