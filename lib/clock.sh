#!/usr/bin/env bash
# TStamp clock helpers. Source this file; do not execute it.
# These functions set variables instead of printing, so the hook never
# has to fork a subshell just to read or format the time.

# Sets TSTAMP_US to the current time in whole microseconds since the epoch.
tstamp_clock_now() {
  local t sec frac
  if [ -n "${EPOCHREALTIME:-}" ]; then
    t="${EPOCHREALTIME/,/.}"
  else
    t="$(date +%s.%6N 2>/dev/null)"
  fi
  case "$t" in
    *.*) ;;
    *) t="${t:-0}.000000" ;;
  esac
  sec="${t%%.*}"
  frac="${t#*.}"
  [[ "$frac" =~ ^[0-9]+$ ]] || frac=0
  frac="${frac}000000"
  frac="${frac:0:6}"
  TSTAMP_US=$(( sec * 1000000 + 10#$frac ))
}

# Usage: tstamp_clock_format EPOCH_US FORMAT
# Sets TSTAMP_OUT. Supports every strftime code plus %3N, %6N and %N.
tstamp_clock_format() {
  local us="$1" fmt="$2" sec frac6
  sec=$(( us / 1000000 ))
  printf -v frac6 '%06d' $(( us % 1000000 ))
  fmt="${fmt//\%3N/${frac6:0:3}}"
  fmt="${fmt//\%6N/$frac6}"
  fmt="${fmt//\%N/${frac6}000}"
  printf -v TSTAMP_OUT "%($fmt)T" "$sec"
}

# Usage: tstamp_clock_duration DELTA_US
# Sets TSTAMP_OUT to seconds with two decimals, for example 3.10
tstamp_clock_duration() {
  local d="$1"
  [ "$d" -ge 0 ] 2>/dev/null || d=0
  printf -v TSTAMP_OUT '%d.%02d' $(( d / 1000000 )) $(( (d % 1000000) / 10000 ))
}
