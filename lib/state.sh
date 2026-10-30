#!/usr/bin/env bash
# TStamp shared state: reboot detection, global flag, live sessions.
# Source this file; do not execute it.
# Requires lib/config.sh and lib/format.sh to be sourced first.

# Sets TSTAMP_BOOT to a token that changes when the machine reboots:
#   id:<kernel boot id>  (Linux, WSL)
#   ts:<epoch>           (boot time estimated from /proc/uptime, for example Git Bash)
#   none                 (cannot be determined; the global flag then never expires)
tstamp_boot_token() {
  local id up rest now
  if [ -r /proc/sys/kernel/random/boot_id ]; then
    read -r id < /proc/sys/kernel/random/boot_id
    TSTAMP_BOOT="id:$id"
    return 0
  fi
  if [ -r /proc/uptime ]; then
    read -r up rest < /proc/uptime
    up="${up%%.*}"
    now="${EPOCHSECONDS:-$(date +%s)}"
    if [[ "$up" =~ ^[0-9]+$ ]]; then
      TSTAMP_BOOT="ts:$(( now - up ))"
      return 0
    fi
  fi
  TSTAMP_BOOT="none"
}

# Usage: tstamp_boot_same TOKEN_A TOKEN_B
# Succeeds if both tokens describe the same boot.
tstamp_boot_same() {
  local a="$1" b="$2" d
  [ "$a" = none ] && return 0
  [ "$b" = none ] && return 0
  if [[ "$a" =~ ^ts:[0-9]+$ && "$b" =~ ^ts:[0-9]+$ ]]; then
    d=$(( ${a#ts:} - ${b#ts:} ))
    [ "$d" -lt 0 ] && d=$(( -d ))
    [ "$d" -le 120 ]
    return
  fi
  [ "$a" = "$b" ]
}

# Create the global flag: tracking on for every hooked terminal until reboot.
tstamp_global_enable() {
  local f tmp now
  mkdir -p "$TSTAMP_HOME" || return 1
  [ -n "${TSTAMP_BOOT:-}" ] || tstamp_boot_token
  f="$TSTAMP_HOME/enabled"
  tmp="$f.tmp.$$"
  now="${EPOCHSECONDS:-$(date +%s)}"
  printf 'boot=%s\nsince=%s\n' "$TSTAMP_BOOT" "$now" > "$tmp" && mv "$tmp" "$f"
}

tstamp_global_disable() {
  rm -f "$TSTAMP_HOME/enabled"
}

# Sets TSTAMP_GLOBAL to on, off or stale, and TSTAMP_GLOBAL_SINCE.
# "stale" means a flag exists but was written before the last reboot.
tstamp_global_state() {
  local f="$TSTAMP_HOME/enabled" k v boot="" since=""
  TSTAMP_GLOBAL="off"
  TSTAMP_GLOBAL_SINCE=""
  [ -f "$f" ] || return 0
  while IFS='=' read -r k v || [ -n "$k" ]; do
    case "$k" in
      boot) boot="$v" ;;
      since) since="$v" ;;
    esac
  done < "$f"
  [ -n "${TSTAMP_BOOT:-}" ] || tstamp_boot_token
  if tstamp_boot_same "$boot" "$TSTAMP_BOOT"; then
    TSTAMP_GLOBAL="on"
    TSTAMP_GLOBAL_SINCE="$since"
  else
    TSTAMP_GLOBAL="stale"
  fi
}

# Prints "T1<TAB>pid" for each session whose shell is still running.
tstamp_sessions_live() {
  local d pid
  for d in "$TSTAMP_HOME"/sessions/T*; do
    [ -d "$d" ] || continue
    pid=""
    [ -f "$d/pid" ] && read -r pid < "$d/pid"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      printf '%s\t%s\n' "${d##*/}" "$pid"
    fi
  done
}

# Usage: tstamp_cmd_global_on [FORMAT]
# Shared by "tstamp-a" (hooked shell) and "tstamp global-on" (standalone).
tstamp_cmd_global_on() {
  local want="${1:-}"
  if [ -n "$want" ]; then
    if ! tstamp_format_validate "$want"; then
      echo "tstamp-a: invalid format: $want" >&2
      echo "Use a number 1-5 or a custom date format string containing %." >&2
      return 2
    fi
    tstamp_config_set format "$want" || return 1
  fi
  if ! tstamp_global_enable; then
    echo "tstamp-a: cannot write state in $TSTAMP_HOME" >&2
    return 1
  fi
  echo "Global tracking enabled."
  echo "Terminals with the TStamp hook loaded start tracking at their next prompt."
  echo "Tracking turns off after a reboot."
}

tstamp_print_global_status() {
  local s pid list="" since_txt
  tstamp_global_state
  case "$TSTAMP_GLOBAL" in
    on)
      since_txt="$TSTAMP_GLOBAL_SINCE"
      if [[ "$since_txt" =~ ^[0-9]+$ ]]; then
        printf -v since_txt '%(%Y-%m-%d %H:%M:%S)T' "$since_txt"
      fi
      printf 'Global        : on (since %s)\n' "$since_txt"
      ;;
    stale)
      printf 'Global        : off (ignored a leftover flag from before the last reboot)\n'
      ;;
    *)
      printf 'Global        : off\n'
      ;;
  esac
  printf 'Default format: %s\n' "$(tstamp_config_get format "$TSTAMP_DEFAULT_FORMAT")"
  printf 'Reboot check  : %s\n' "${TSTAMP_BOOT%%:*}"
  while IFS=$'\t' read -r s pid; do
    [ -n "$s" ] && list="$list $s(pid $pid)"
  done < <(tstamp_sessions_live)
  printf 'Live sessions :%s\n' "${list:- none}"
}
