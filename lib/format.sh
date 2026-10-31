#!/usr/bin/env bash
# TStamp format engine. Source this file; do not execute it.
# Times are formatted by lib/clock.sh, not by the date command, so that
# milliseconds (%3N) behave the same on Linux, macOS and Windows.

__tstamp_fmt_dir="${BASH_SOURCE[0]}"
case "$__tstamp_fmt_dir" in
  */*) __tstamp_fmt_dir="${__tstamp_fmt_dir%/*}" ;;
  *) __tstamp_fmt_dir="." ;;
esac
# shellcheck source=/dev/null
source "$__tstamp_fmt_dir/clock.sh"
unset __tstamp_fmt_dir

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
  local fmt
  fmt="$(tstamp_format_string "$1")" || return 1
  tstamp_clock_format 0 "$fmt" 2>/dev/null || return 1
  [ -n "$TSTAMP_OUT" ]
}

# Current time in the given date format string.
tstamp_now() {
  tstamp_clock_now
  tstamp_clock_format "$TSTAMP_US" "$1"
  printf '%s\n' "$TSTAMP_OUT"
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
