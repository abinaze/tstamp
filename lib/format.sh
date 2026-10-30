#!/usr/bin/env bash
# TStamp format engine. Source this file; do not execute it.

# Print the date format string for a format ID (1-5) or a custom string.
# A custom string must contain at least one % and no newline.
tstamp_format_string() {
  case "$1" in
    *$'\n'*) return 1 ;;
    1) printf '%s\n' '%H:%M' ;;
    2) printf '%s\n' '%H:%M:%S' ;;
    3) printf '%s\n' '%Y-%m-%d %H:%M:%S' ;;
    4) printf '%s\n' '%Y-%m-%d %H:%M:%S.%3N' ;;
    5) printf '%s\n' '%Y-%m-%d %H:%M:%S %z' ;;
    *%*) printf '%s\n' "$1" ;;
    *) return 1 ;;
  esac
}

# Succeeds only if the ID or custom string produces non-empty output.
tstamp_format_validate() {
  local fmt out
  fmt="$(tstamp_format_string "$1")" || return 1
  out="$(date +"$fmt" 2>/dev/null)" || return 1
  [ -n "$out" ]
}

# Current time in the given date format string.
tstamp_now() {
  date +"$1"
}

tstamp_format_describe() {
  case "$1" in
    1) printf 'Hours and minutes' ;;
    2) printf 'Hours, minutes and seconds' ;;
    3) printf 'Date and time' ;;
    4) printf 'Date, time and milliseconds' ;;
    5) printf 'Date, time and UTC offset' ;;
  esac
}

# Usage: tstamp_format_list CURRENT_FORMAT
tstamp_format_list() {
  local current="$1" id marker fmt
  printf 'Timestamp formats (* = current default):\n\n'
  for id in 1 2 3 4 5; do
    fmt="$(tstamp_format_string "$id")"
    marker=" "
    [ "$id" = "$current" ] && marker="*"
    printf '%s %s  %-30s %s\n' "$marker" "$id" "$(tstamp_format_describe "$id")" "$(tstamp_now "$fmt")"
  done
  printf '\n'
  case "$current" in
    [1-5]) ;;
    *) printf '* custom  %s\n\n' "$current" ;;
  esac
  printf 'Custom format: tstamp set "%%d/%%m/%%Y %%H:%%M"\n'
  printf 'Any date format string works. Use %%3N for milliseconds.\n'
}
