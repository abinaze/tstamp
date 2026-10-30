#!/usr/bin/env bash
# TStamp export. Source this file; do not execute it.
# Requires lib/config.sh, lib/format.sh and lib/clock.sh.

# Usage: __tstamp_export_stream LOGFILE...
# Merges the logs in time order and prints them in the saved default format.
__tstamp_export_stream() {
  local raw fmt us sid pid ev rc dur cmd stamp
  raw="$(tstamp_config_get format "$TSTAMP_DEFAULT_FORMAT")"
  fmt="$(tstamp_format_string "$raw")" || fmt="$(tstamp_format_string "$TSTAMP_DEFAULT_FORMAT")"
  # Tabs become \037 so empty fields (START lines) are not collapsed by read.
  sort -s -t $'\t' -k1,1n -- "$@" | tr '\t' '\037' |
  while IFS=$'\037' read -r us sid pid ev rc dur cmd; do
    [[ "$us" =~ ^[0-9]+$ ]] || continue
    tstamp_clock_format "$us" "$fmt"
    stamp="$TSTAMP_OUT"
    case "$ev" in
      START)
        printf '[%s][%s] START: %s\n' "$sid" "$stamp" "$cmd"
        ;;
      END)
        tstamp_clock_duration "${dur:-0}"
        printf '[%s][%s] END: %s | EXIT=%s | DURATION=%ss\n' "$sid" "$stamp" "$cmd" "$rc" "$TSTAMP_OUT"
        ;;
    esac
  done
}

# Usage: tstamp_export [-o FILE] [SESSION...]
tstamp_export() {
  local out="" sessions=() files=() f name s
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "tstamp export: $1 needs a file name" >&2
          return 2
        fi
        out="$2"
        shift
        ;;
      -*)
        echo "tstamp export: unknown option: $1" >&2
        return 2
        ;;
      *)
        if [[ ! "$1" =~ ^T[0-9]+$ ]]; then
          echo "tstamp export: invalid session ID: $1 (expected T1, T2, ...)" >&2
          return 2
        fi
        sessions+=("$1")
        ;;
    esac
    shift
  done

  for f in "$TSTAMP_HOME"/logs/T*.log; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    name="${name%%-*}"
    if [ "${#sessions[@]}" -eq 0 ]; then
      files+=("$f")
      continue
    fi
    for s in "${sessions[@]}"; do
      if [ "$s" = "$name" ]; then
        files+=("$f")
        break
      fi
    done
  done

  if [ "${#files[@]}" -eq 0 ]; then
    echo "tstamp export: no matching logs in $TSTAMP_HOME/logs" >&2
    return 1
  fi

  if [ -n "$out" ]; then
    if [ -e "$out" ]; then
      echo "tstamp export: $out already exists; choose another name" >&2
      return 1
    fi
    __tstamp_export_stream "${files[@]}" > "$out" || return 1
    echo "Exported ${#files[@]} log file(s) to $out"
  else
    __tstamp_export_stream "${files[@]}"
  fi
}
