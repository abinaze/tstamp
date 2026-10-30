#!/usr/bin/env bash
# TStamp startup-file editing. Source this file; do not execute it.
# Adds or removes one clearly marked block in a startup file such as
# ~/.bashrc. It never touches anything outside that block.

TSTAMP_MARK_BEGIN="# >>> tstamp >>>"
TSTAMP_MARK_END="# <<< tstamp <<<"

# Succeeds if FILE contains the TStamp begin marker.
tstamp_profile_has() {
  [ -f "$1" ] && grep -qF -- "$TSTAMP_MARK_BEGIN" "$1"
}

# Copies FILE to FILE.tstamp-backup-DATE-TIME. Does nothing if FILE is missing.
__tstamp_profile_backup() {
  local file="$1" backup
  [ -f "$file" ] || return 0
  backup="$file.tstamp-backup-$(date +%Y%m%d-%H%M%S)"
  cp -p -- "$file" "$backup" || return 1
  echo "Backup saved: $backup"
}

# Usage: tstamp_profile_add FILE ROOT
tstamp_profile_add() {
  local file="$1" root="$2"
  if [ -z "$root" ] || [[ "$root" == *'"'* || "$root" == *'$'* || "$root" == *'`'* || "$root" == *'\'* ]]; then
    echo "tstamp: unsafe install path: $root" >&2
    return 1
  fi
  if tstamp_profile_has "$file"; then
    echo "The TStamp block is already in $file. Nothing changed."
    return 0
  fi
  __tstamp_profile_backup "$file" || return 1
  {
    if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
      printf '\n'
    fi
    printf '%s\n' "$TSTAMP_MARK_BEGIN"
    printf '%s\n' '# Added by TStamp. Remove this block (or run "tstamp hook remove") to undo.'
    printf '%s\n' "[ -f \"$root/shells/bash.sh\" ] && source \"$root/shells/bash.sh\""
    printf '%s\n' "$TSTAMP_MARK_END"
  } >> "$file" || return 1
  echo "TStamp block added to $file."
}

# Usage: tstamp_profile_remove FILE
tstamp_profile_remove() {
  local file="$1" tmp
  if ! tstamp_profile_has "$file"; then
    echo "No TStamp block found in $file. Nothing changed."
    return 0
  fi
  if ! grep -qF -- "$TSTAMP_MARK_END" "$file"; then
    echo "tstamp: found the start marker but not the end marker in $file." >&2
    echo "Nothing was changed. Remove the block by hand." >&2
    return 1
  fi
  __tstamp_profile_backup "$file" || return 1
  tmp="$file.tstamp-tmp.$$"
  awk -v b="$TSTAMP_MARK_BEGIN" -v e="$TSTAMP_MARK_END" '
    { l = $0; sub(/\r$/, "", l) }
    l == b { skip = 1; next }
    l == e { skip = 0; next }
    !skip  { print }
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  cat "$tmp" > "$file" && rm -f "$tmp"
  echo "TStamp block removed from $file."
}

# Usage: tstamp_cmd_hook add|remove [--yes] [FILE]
# Needs TSTAMP_ROOT. Asks for confirmation unless --yes is given.
tstamp_cmd_hook() {
  local action="${1:-}" yes=0 file="" ans
  shift 2>/dev/null
  case "$action" in
    add|remove) ;;
    *)
      echo "usage: tstamp hook add|remove [--yes] [FILE]" >&2
      return 2
      ;;
  esac
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes|-y) yes=1 ;;
      -*)
        echo "tstamp hook: unknown option: $1" >&2
        return 2
        ;;
      *) file="$1" ;;
    esac
    shift
  done
  [ -n "$file" ] || file="$HOME/.bashrc"

  if [ "$yes" -ne 1 ]; then
    if [ ! -t 0 ]; then
      echo "tstamp hook: refusing to edit $file without confirmation (use --yes)." >&2
      return 2
    fi
    if [ "$action" = add ]; then
      printf 'This adds a TStamp block to %s (a backup is made first).\n' "$file"
    else
      printf 'This removes the TStamp block from %s (a backup is made first).\n' "$file"
    fi
    printf 'Continue? [y/N] '
    read -r ans
    case "$ans" in
      y|Y|yes|YES) ;;
      *)
        echo "Cancelled. Nothing was changed."
        return 1
        ;;
    esac
  fi

  if [ "$action" = add ]; then
    tstamp_profile_add "$file" "$TSTAMP_ROOT" || return 1
    echo "Open a new Git Bash window to load it. To undo: tstamp hook remove"
  else
    tstamp_profile_remove "$file"
  fi
}
