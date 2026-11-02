#!/usr/bin/env bash
# tstamp run: time one command, from any shell, including CMD.
# Source this file; do not execute it.
# Needs lib/config.sh, lib/format.sh and lib/clock.sh.

# Usage: tstamp_run COMMAND [ARGS...]
# Prints START and END lines, logs them in the shared format, and returns the
# command's own exit code. The temporary session label is released at the end.
tstamp_run() {
  local base="$TSTAMP_HOME/sessions" n=1 sid="" raw fmt text us0 us1 rc stamp log
  if [ $# -lt 1 ]; then
    echo "usage: tstamp run COMMAND [ARGS...]" >&2
    return 2
  fi
  mkdir -p "$base" "$TSTAMP_HOME/logs" || return 1
  while [ "$n" -le 999 ]; do
    __tstamp_run_dir="$base/T$n"
    if mkdir "$__tstamp_run_dir" 2>/dev/null; then
      sid="T$n"
      break
    fi
    n=$((n + 1))
  done
  if [ -z "$sid" ]; then
    echo "tstamp run: no free session label" >&2
    return 1
  fi
  printf '%s\n' "$$" > "$__tstamp_run_dir/pid"
  printf 'run\n' > "$__tstamp_run_dir/kind"
  trap 'rm -rf "$__tstamp_run_dir"' EXIT

  raw="$(tstamp_config_get format "$TSTAMP_DEFAULT_FORMAT")"
  fmt="$(tstamp_format_string "$raw")" || fmt="$(tstamp_format_string "$TSTAMP_DEFAULT_FORMAT")"
  text="$*"
  text="${text//$'\t'/ }"
  text="${text//$'\n'/ }"
  log="$TSTAMP_HOME/logs/$sid-$$.log"

  tstamp_clock_now
  us0="$TSTAMP_US"
  tstamp_clock_format "$us0" "$fmt"
  printf '[%s][%s] START: %s\n' "$sid" "$TSTAMP_OUT" "$text"
  printf '%s\t%s\t%s\tSTART\t\t\t%s\n' "$us0" "$sid" "$$" "$text" >> "$log"

  if command -v "$1" >/dev/null 2>&1; then
    "$@"
    rc=$?
  elif command -v cmd.exe >/dev/null 2>&1; then
    MSYS2_ARG_CONV_EXCL='*' cmd.exe /c "$@"
    rc=$?
  else
    echo "tstamp run: command not found: $1" >&2
    rc=127
  fi

  tstamp_clock_now
  us1="$TSTAMP_US"
  tstamp_clock_format "$us1" "$fmt"
  stamp="$TSTAMP_OUT"
  tstamp_clock_duration $((us1 - us0))
  printf '[%s][%s] END: %s | EXIT=%s | DURATION=%ss\n' "$sid" "$stamp" "$text" "$rc" "$TSTAMP_OUT"
  printf '%s\t%s\t%s\tEND\t%s\t%s\t%s\n' "$us1" "$sid" "$$" "$rc" "$((us1 - us0))" "$text" >> "$log"
  return "$rc"
}
