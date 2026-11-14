#!/usr/bin/env bash
# The Command Prompt session ("tstamp" typed in CMD): static checks everywhere,
# and a run through real Windows PowerShell and cmd.exe on Windows.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
has() { # description, file, regex
  if grep -Eq -- "$3" "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $3)"; fi
}
hasnt() { # description, file, regex
  if grep -Eq -- "$3" "$2"; then fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $3)"; else pass=$((pass + 1)); echo "ok   - $1"; fi
}
hasout() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}

S="$ROOT/shells/cmdsession.ps1"
B="$ROOT/bin/tstamp.cmd"
has   "the session script replaces the line reader"      "$S" 'function global:PSConsoleHostReadLine'
has   "the session runs lines through cmd.exe"           "$S" 'function global:__ts_cmdrun'
has   "it turns local tracking on"                       "$S" '^tstamp \$Format'
has   "tstamp.cmd starts the session without arguments"  "$B" 'if "%~1"=="" goto session'
has   "tstamp.cmd starts the session for tstamp cmd"     "$B" 'if /i "%~1"=="cmd" goto session'
has   "the session needs no policy change"               "$B" 'powershell.exe .*-ExecutionPolicy Bypass .*cmdsession.ps1'
hasnt "the session script changes no system setting"     "$S" 'Set-ExecutionPolicy|reg add|setx|Set-ItemProperty|New-ItemProperty|HKLM|HKCU'
hasnt "the launcher changes no system setting"           "$B" 'Set-ExecutionPolicy|reg add|setx|Set-ItemProperty|HKLM|HKCU'
has   "the hook lets the session report the exit code"   "$ROOT/shells/powershell.ps1" 'CmdExit'
has   "the session marks itself with TSTAMP_CMD_SESSION"  "$S" "TSTAMP_CMD_SESSION = '1'"
has   "tstamp.cmd does not start a session in a session"  "$B" 'if defined TSTAMP_CMD_SESSION goto insession'
BA="$ROOT/bin/tstamp-a.cmd"
has   "tstamp-a.cmd turns global tracking on first"       "$BA" 'tstamp.cmd" global-on %\*'
has   "tstamp-a.cmd then starts the session"              "$BA" 'tstamp.cmd" cmd'
has   "tstamp-a.cmd leaves tstamp-a stop alone"           "$BA" 'if /i "%~1"=="stop" exit /b 0'
has   "tstamp-a.cmd does not nest sessions"               "$BA" 'if defined TSTAMP_CMD_SESSION exit /b 0'
hasnt "tstamp-a.cmd changes no system setting"            "$BA" 'Set-ExecutionPolicy|reg add|setx|Set-ItemProperty|HKLM|HKCU'
crlf="$(grep -c $'\r' "$B")"
if [ "$crlf" -gt 20 ]; then pass=$((pass + 1)); echo "ok   - tstamp.cmd keeps Windows line endings"; else fail=$((fail + 1)); echo "FAIL - tstamp.cmd lost its Windows line endings"; fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v "${TSTAMP_TEST_POWERSHELL:-powershell}" >/dev/null 2>&1; then
      TMP="$(mktemp -d)"
      trap 'rm -rf "$TMP"' EXIT
      W() { cygpath -w "$1"; }
      out="$(cd "$ROOT" && "${TSTAMP_TEST_POWERSHELL:-powershell}" -NoProfile -ExecutionPolicy Bypass -File "$(W "$ROOT/tests/ps/cmdrun.ps1")" "$(W "$TMP/state")" "$(W "$S")" 2>&1 | tr -d '\r')"
      hasout "session: tracking is on in the session"        'Tracking enabled in this terminal' "$out"
      hasout "session: cd carries over"                      '^CWD_CHANGED=True$' "$out"
      hasout "session: set carries over, with no trailing space" '^ENV=\[hello world\]$' "$out"
      hasout "session: an unset variable is removed"         '^ENV_REMOVED=True$' "$out"
      hasout "session: exit code 7 is reported"              '^EXIT7=7$' "$out"
      hasout "session: a builtin reports 0, not the last code" '^EXIT0=0$' "$out"
      hasout "session: a failing command reports 1"          '^EXIT_DIR=1$' "$out"
      hasout "session: START line"                           'START: echo hi$' "$out"
      hasout "session: END line carries the cmd exit code"   'END: cmd /c exit 7 \| EXIT=7' "$out"
      hasout "session: quotes inside the line survive"       '^"quoted text" *$' "$out"
      hasout "session: a command after & runs"               '^second$' "$out"
      hasout "session: an apostrophe is not a problem"       "^it's a test$" "$out"
      [ "$fail" -eq 0 ] || { echo "--- output ---"; printf '%s\n' "$out"; }
    else
      echo "skip - powershell.exe not found"
    fi
    ;;
  *) echo "skip - the run through PowerShell and cmd.exe is Windows only" ;;
esac

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
