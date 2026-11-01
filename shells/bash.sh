#!/usr/bin/env bash
# TStamp integration for bash (Git Bash first). Source this file; do not execute it.
# Phase 5: per-terminal tracking plus global tracking (tstamp-a, tstamp stop).
# This file is sourced into an interactive shell, so it must never use
# "set -e" or "set -u".

[ -n "${BASH_VERSION:-}" ] || return 0
case "$-" in *i*) ;; *) return 0 ;; esac
[ -z "${__TSTAMP_LOADED:-}" ] || return 0

# Needs bash 4.4+ (uses ${var@a} and printf %()T).
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 4 ]; }; then
  echo "tstamp: bash 4.4 or newer is required; tracking not installed." >&2
  return 1
fi

__tstamp_dir="${BASH_SOURCE[0]}"
case "$__tstamp_dir" in
  */*) __tstamp_dir="${__tstamp_dir%/*}" ;;
  *) __tstamp_dir="." ;;
esac
__TSTAMP_ROOT="$(cd "$__tstamp_dir/.." 2>/dev/null && pwd)"
unset __tstamp_dir
if [ -z "$__TSTAMP_ROOT" ] || [ ! -f "$__TSTAMP_ROOT/lib/clock.sh" ]; then
  echo "tstamp: cannot locate its install directory; tracking not installed." >&2
  return 1
fi

if [ -n "$(trap -p DEBUG)" ]; then
  echo "tstamp: another DEBUG trap is already set in this shell; tracking not installed." >&2
  return 1
fi

# shellcheck source=/dev/null
source "$__TSTAMP_ROOT/lib/config.sh"
# shellcheck source=/dev/null
source "$__TSTAMP_ROOT/lib/format.sh"
# shellcheck source=/dev/null
source "$__TSTAMP_ROOT/lib/clock.sh"
# shellcheck source=/dev/null
source "$__TSTAMP_ROOT/lib/state.sh"

__TSTAMP_LOADED=1
tstamp_boot_token           # reboot token, computed once per terminal
__tstamp_local=0            # 1 = tracking is on in this terminal
__tstamp_local_fmt=""       # format chosen with "tstamp N" (empty = use default)
__tstamp_armed=0            # 1 = next DEBUG event is a user command
__tstamp_active=0           # 1 = a tracked command is running
__tstamp_sid=""             # session ID, for example T1
__tstamp_log=""             # log file for this session
__tstamp_start_us=0
__tstamp_cmd=""
__tstamp_fmt=""             # resolved date format string
__tstamp_fmt_raw="<unset>"  # raw value the cached format was resolved from
__tstamp_last_hist=""

__tstamp_setret() {
  return "${1:-0}"
}

# Succeeds if this terminal should track the next command:
# tracking was enabled here, or the global flag is on for this boot.
__tstamp_enabled() {
  [ "$__tstamp_local" = 1 ] && return 0
  [ -e "$TSTAMP_HOME/enabled" ] || return 1
  tstamp_global_state
  [ "$TSTAMP_GLOBAL" = on ]
}

# Claim the lowest free session ID (T1, T2, ...). Slots whose shell has
# exited are reclaimed automatically.
__tstamp_ensure_session() {
  [ -z "$__tstamp_sid" ] || return 0
  local base="$TSTAMP_HOME/sessions" n=1 d pid
  mkdir -p "$base" "$TSTAMP_HOME/logs" 2>/dev/null || return 1
  while [ "$n" -le 999 ]; do
    d="$base/T$n"
    if mkdir "$d" 2>/dev/null; then
      printf '%s\n' "$$" > "$d/pid"
      __tstamp_sid="T$n"
      __tstamp_log="$TSTAMP_HOME/logs/$__tstamp_sid-$$.log"
      return 0
    fi
    [ -f "$d/kind" ] && { n=$((n + 1)); continue; }
    pid=""
    [ -f "$d/pid" ] && read -r pid < "$d/pid"
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
      rm -rf "$d" 2>/dev/null
      [ -d "$d" ] && n=$((n + 1))
    else
      n=$((n + 1))
    fi
  done
  return 1
}

# Sets __tstamp_fmt from the terminal override or the saved default.
# The format string is only re-resolved when the raw value changes.
__tstamp_resolve_format() {
  local raw="" k v
  if [ -n "$__tstamp_local_fmt" ]; then
    raw="$__tstamp_local_fmt"
  elif [ -f "$TSTAMP_HOME/config" ]; then
    while IFS='=' read -r k v || [ -n "$k" ]; do
      if [ "$k" = format ]; then raw="$v"; break; fi
    done < "$TSTAMP_HOME/config"
  fi
  [ -n "$raw" ] || raw="$TSTAMP_DEFAULT_FORMAT"
  if [ "$raw" != "$__tstamp_fmt_raw" ]; then
    __tstamp_fmt="$(tstamp_format_string "$raw")" || __tstamp_fmt="$(tstamp_format_string "$TSTAMP_DEFAULT_FORMAT")"
    __tstamp_fmt_raw="$raw"
  fi
}

# Log line (tab separated): epoch_us, session, pid, event, exit, duration_us, command
__tstamp_log_event() { # EVENT EPOCH_US EXIT DURATION_US
  local c="${__tstamp_cmd//$'\t'/ }"
  c="${c//$'\n'/ }"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$__tstamp_sid" "$$" "$1" "$3" "$4" "$c" >> "$__tstamp_log" 2>/dev/null
}

__tstamp_start() { # $1 = fallback command text
  local fallback="$1" h num text
  h="$(HISTTIMEFORMAT= builtin history 1 2>/dev/null)"
  h="${h#"${h%%[![:space:]]*}"}"
  num="${h%%[!0-9]*}"
  text="${h#"$num"}"
  text="${text#\*}"
  text="${text#"${text%%[![:space:]]*}"}"
  if [ -z "$num" ] || [ -z "$text" ] || [ "$num" = "$__tstamp_last_hist" ]; then
    text="$fallback"
  else
    __tstamp_last_hist="$num"
  fi
  case "$text" in
    tstamp|tstamp\ *|tstamp-a|tstamp-a\ *) return 0 ;;
  esac
  __tstamp_ensure_session || return 0
  __tstamp_resolve_format
  tstamp_clock_now
  __tstamp_start_us="$TSTAMP_US"
  __tstamp_cmd="$text"
  __tstamp_active=1
  tstamp_clock_format "$__tstamp_start_us" "$__tstamp_fmt"
  printf '[%s][%s] START: %s\n' "$__tstamp_sid" "$TSTAMP_OUT" "$text"
  __tstamp_log_event START "$__tstamp_start_us" "" ""
}

# Runs from the DEBUG trap, before each command.
__tstamp_debug() {
  local rc=$? last="${1:-}" cmd="${2:-}"
  if [ "$__tstamp_armed" = 1 ] && [ -z "${COMP_POINT:-}" ]; then
    __tstamp_armed=0
    if __tstamp_enabled; then
      __tstamp_start "$cmd"
    fi
  fi
  __tstamp_setret "$rc" "$last"
}

# Runs first in PROMPT_COMMAND, after each command.
__tstamp_precmd() {
  local rc=$? end_us stamp delta
  if [ "$__tstamp_active" = 1 ]; then
    tstamp_clock_now
    end_us="$TSTAMP_US"
    __tstamp_active=0
    delta=$(( end_us - __tstamp_start_us ))
    tstamp_clock_format "$end_us" "$__tstamp_fmt"
    stamp="$TSTAMP_OUT"
    tstamp_clock_duration "$delta"
    printf '[%s][%s] END: %s | EXIT=%s | DURATION=%ss\n' "$__tstamp_sid" "$stamp" "$__tstamp_cmd" "$rc" "$TSTAMP_OUT"
    __tstamp_log_event END "$end_us" "$rc" "$delta"
  fi
  return "$rc"
}

# Runs last in PROMPT_COMMAND: the next DEBUG event is a user command.
__tstamp_arm() {
  local rc=$?
  __tstamp_armed=1
  return "$rc"
}

tstamp() {
  case "${1:-}" in
    ""|[0-9]*|*%*)
      local want="${1:-}"
      if [ -n "$want" ] && ! tstamp_format_validate "$want"; then
        echo "tstamp: invalid format: $want" >&2
        echo "Use a number 1-5 or a custom date format string containing %." >&2
        return 2
      fi
      if ! __tstamp_ensure_session; then
        echo "tstamp: cannot create session state in $TSTAMP_HOME" >&2
        return 1
      fi
      __tstamp_local_fmt="$want"
      __tstamp_local=1
      __tstamp_resolve_format
      printf 'Tracking enabled in this terminal (session %s).\n' "$__tstamp_sid"
      printf 'Timestamp format: %s\n' "$__tstamp_fmt"
      ;;
    stop)
      __tstamp_local=0
      __tstamp_local_fmt=""
      tstamp_global_disable
      echo "Tracking stopped globally and in this terminal."
      ;;
    status)
      local state=off
      if [ "$__tstamp_local" = 1 ]; then
        state=on
      elif __tstamp_enabled; then
        state="on (global)"
      fi
      __tstamp_resolve_format
      printf 'This terminal : %s\n' "$state"
      printf 'Session ID    : %s\n' "${__tstamp_sid:-not assigned yet}"
      printf 'Format here   : %s\n' "$__tstamp_fmt"
      printf 'State dir     : %s\n' "$TSTAMP_HOME"
      tstamp_print_global_status
      ;;
    *)
      TSTAMP_HOME="$TSTAMP_HOME" command "$__TSTAMP_ROOT/bin/tstamp" "$@"
      ;;
  esac
}

# Enable tracking in every terminal that has the hook loaded.
tstamp-a() {
  tstamp_cmd_global_on "$@"
}

__tstamp_install() {
  trap '__tstamp_debug "$_" "$BASH_COMMAND"' DEBUG
  if [[ "${PROMPT_COMMAND@a}" == *a* ]]; then
    PROMPT_COMMAND=(__tstamp_precmd "${PROMPT_COMMAND[@]}" __tstamp_arm)
  else
    PROMPT_COMMAND="__tstamp_precmd${PROMPT_COMMAND:+$'\n'$PROMPT_COMMAND}"$'\n'"__tstamp_arm"
  fi
}
__tstamp_install
