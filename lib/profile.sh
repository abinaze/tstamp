#!/usr/bin/env bash
# TStamp startup-file editing. Source this file; do not execute it.
# Adds or removes one clearly marked block in a startup file such as
# ~/.bashrc or a PowerShell profile. It never touches anything outside
# that block.

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

# Usage: tstamp_profile_add FILE ROOT [bash|powershell]
tstamp_profile_add() {
  local file="$1" root="$2" kind="${3:-bash}" line win
  if [ -z "$root" ] || [[ "$root" == *'"'* || "$root" == *'$'* || "$root" == *'`'* || "$root" == *'\'* ]]; then
    echo "tstamp: unsafe install path: $root" >&2
    return 1
  fi
  if [ "$kind" = powershell ]; then
    if [ ! -f "$root/shells/powershell.ps1" ]; then
      echo "tstamp: $root/shells/powershell.ps1 was not found, so the PowerShell hook was not added." >&2
      return 1
    fi
    win="$(cygpath -w "$root" 2>/dev/null)" || win=""
    if [ -z "$win" ] || [[ "$win" == *"'"* ]] || LC_ALL=C grep -q '[^ -~]' <<<"$win"; then
      echo "tstamp: the install path cannot be used in a PowerShell profile: $root" >&2
      return 1
    fi
    if [ -f "$file" ]; then
      case "$(head -c 2 "$file" | od -An -tx1 | tr -d ' \n')" in
        fffe|feff)
          echo "tstamp: $file is saved as UTF-16. Open it in an editor, save it as UTF-8, then run this again." >&2
          return 1
          ;;
      esac
    fi
    mkdir -p "$(dirname "$file")" || return 1
    line="if (Test-Path -LiteralPath '$win\\shells\\powershell.ps1') { . '$win\\shells\\powershell.ps1' }"
  else
    line="[ -f \"$root/shells/bash.sh\" ] && source \"$root/shells/bash.sh\""
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
    printf '%s\n' "$line"
    printf '%s\n' "$TSTAMP_MARK_END"
  } >> "$file" || return 1
  echo "TStamp block added to $file."
}

# Usage: tstamp_profile_remove FILE
tstamp_profile_remove() {
  local file="$1" tmp line l skip
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
  # A plain loop keeps every byte of the other lines, including Windows line
  # endings. (The awk that ships with Git Bash turns CRLF into LF.)
  {
    skip=0
    while IFS= read -r line || [ -n "$line" ]; do
      l="${line%$'\r'}"
      if [ "$l" = "$TSTAMP_MARK_BEGIN" ]; then skip=1; continue; fi
      if [ "$l" = "$TSTAMP_MARK_END" ]; then skip=0; continue; fi
      [ "$skip" -eq 1 ] || printf '%s\n' "$line"
    done < "$file"
  } > "$tmp" || { rm -f "$tmp"; return 1; }
  cat "$tmp" > "$file" && rm -f "$tmp"
  echo "TStamp block removed from $file."
}

# Prints "exe|profile path" for each PowerShell found (Windows PowerShell,
# PowerShell 7). TSTAMP_PS_PROFILE overrides this, for tests.
__tstamp_ps_profiles() {
  local exe p
  if [ -n "${TSTAMP_PS_PROFILE:-}" ]; then
    printf 'powershell|%s\n' "$TSTAMP_PS_PROFILE"
    return 0
  fi
  for exe in powershell pwsh; do
    command -v "$exe" >/dev/null 2>&1 || continue
    p="$("$exe" -NoProfile -Command '$PROFILE' 2>/dev/null | tr -d '\r')"
    [ -n "$p" ] || continue
    p="$(cygpath -u "$p" 2>/dev/null)" || continue
    printf '%s|%s\n' "$exe" "$p"
  done
}

__tstamp_ps_policy_hint() { # EXE
  local pol
  [ -z "${TSTAMP_PS_PROFILE:-}" ] || return 0
  pol="$("$1" -NoProfile -Command 'Get-ExecutionPolicy' 2>/dev/null | tr -d '\r')"
  case "$pol" in
    Restricted|AllSigned)
      echo "Note: PowerShell's execution policy is $pol, so profile scripts will not load."
      echo "To allow your own scripts, for your user only, run this in PowerShell:"
      echo "  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
      ;;
  esac
}

# Usage: tstamp_cmd_hook add|remove [--yes] [--powershell] [FILE]
# Needs TSTAMP_ROOT. Asks for confirmation unless --yes is given.
tstamp_cmd_hook() {
  local action="${1:-}" yes=0 ps=0 file="" ans t exe pf kind rc=0 targets=() list=""
  shift 2>/dev/null
  case "$action" in
    add|remove) ;;
    *)
      echo "usage: tstamp hook add|remove [--yes] [--powershell] [FILE]" >&2
      return 2
      ;;
  esac
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes|-y) yes=1 ;;
      --powershell) ps=1 ;;
      -*)
        echo "tstamp hook: unknown option: $1" >&2
        return 2
        ;;
      *) file="$1" ;;
    esac
    shift
  done

  if [ "$ps" -eq 1 ]; then
    while IFS='|' read -r exe pf; do
      [ -n "$pf" ] && targets+=("$exe|$pf")
    done < <(__tstamp_ps_profiles)
    if [ "${#targets[@]}" -eq 0 ]; then
      echo "tstamp hook: PowerShell was not found." >&2
      return 1
    fi
  else
    if [ -n "$file" ]; then
      targets=("bash|$file")
    elif [ "$(uname -s)" = Darwin ]; then
      # Terminal on a Mac starts login shells (.bash_profile); typing "bash"
      # starts a plain one (.bashrc). The hook loads only once either way.
      targets=("bash|$HOME/.bash_profile" "bash|$HOME/.bashrc")
    else
      targets=("bash|$HOME/.bashrc")
    fi
  fi
  for t in "${targets[@]}"; do list="$list ${t#*|}"; done

  if [ "$yes" -ne 1 ]; then
    if [ ! -t 0 ]; then
      echo "tstamp hook: refusing to edit$list without confirmation (use --yes)." >&2
      return 2
    fi
    if [ "$action" = add ]; then
      printf 'This adds a TStamp block to:%s\n(a backup is made first).\n' "$list"
    else
      printf 'This removes the TStamp block from:%s\n(a backup is made first).\n' "$list"
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

  kind=bash
  [ "$ps" -eq 1 ] && kind=powershell
  for t in "${targets[@]}"; do
    exe="${t%%|*}"
    pf="${t#*|}"
    if [ "$action" = add ]; then
      tstamp_profile_add "$pf" "$TSTAMP_ROOT" "$kind" || rc=1
      [ "$ps" -eq 1 ] && __tstamp_ps_policy_hint "$exe"
    else
      tstamp_profile_remove "$pf" || rc=1
    fi
  done
  if [ "$action" = add ] && [ "$rc" -eq 0 ]; then
    if [ "$ps" -eq 1 ]; then
      echo "Open a new PowerShell window to load it. To undo: tstamp hook remove --powershell"
    else
      echo "Open a new window to load it. To undo: tstamp hook remove"
    fi
  fi
  return "$rc"
}
