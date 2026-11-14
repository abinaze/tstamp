#!/usr/bin/env bash
# The optional Command Prompt AutoRun: static checks everywhere, and runs on Windows.

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
check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}

A="$ROOT/bin/tstamp-autorun.cmd"
S="$ROOT/shells/cmdsession.ps1"
ISS="$ROOT/installer/tstamp.iss"

has   "autorun: never starts inside a session"            "$A" 'if defined TSTAMP_CMD_SESSION goto :eof'
has   "autorun: can be switched off for a window"         "$A" 'if defined TSTAMP_NO_AUTORUN goto :eof'
has   "autorun: leaves cmd /c windows alone"              "$A" 'TSA_L:/c='
has   "autorun: leaves cmd /r windows alone"              "$A" 'TSA_L:/r='
has   "autorun: needs the global flag"                    "$A" 'if not exist "%TSA_H%\\enabled" goto done'
has   "autorun: starts the session with -Auto"            "$A" 'cmdsession.ps1" -Auto'
has   "autorun: closes the window only after exit 0"      "$A" 'if errorlevel 1 goto :eof'
hasnt "autorun: changes no system setting"                "$A" 'Set-ExecutionPolicy|reg add|setx|Set-ItemProperty|HKLM|HKCU'
crlf="$(grep -c $'\r' "$A")"
if [ "$crlf" -gt 15 ]; then pass=$((pass + 1)); echo "ok   - autorun keeps Windows line endings"; else fail=$((fail + 1)); echo "FAIL - autorun lost its Windows line endings"; fi

has   "session: -Auto switch exists"                      "$S" '\[switch\]\$Auto'
has   "session: -Auto exits 2 when global tracking is off" "$S" 'exit 2'
has   "iss: the AutoRun box is a task"                    "$ISS" 'Name: "cmdautorun"'
has   "iss: the AutoRun box is not ticked by default"     "$ISS" 'Name: "cmdautorun".*Flags: unchecked'
has   "iss: install adds the AutoRun command"             "$ISS" 'AddCmdAutoRun;'
has   "iss: uninstall removes the AutoRun command"        "$ISS" 'RemoveCmdAutoRun;'
has   "iss: the old AutoRun value is kept"                "$ISS" "AutoRunBefore"
has   "iss: the command does nothing if the file is gone" "$ISS" "'if exist \""
has   "iss: the file is shipped by the stage script"      "$ROOT/installer/stage.sh" '\*\.cmd'

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    W() { cygpath -w "$1"; }
    mkdir -p "$TMP/state"
    export TSTAMP_HOME="$TMP/state"
    printf 'boot=none\nsince=1\ngen=x\n' > "$TMP/state/enabled"
    # Under cmd /c the script must do nothing, even with global tracking on.
    out="$(cmd //c "$(W "$A")" 2>&1 | tr -d '\r')"
    check "autorun: prints nothing under cmd /c" "" "$out"
    cmd //c "$(W "$A")" >/dev/null 2>&1
    check "autorun: exit status 0 under cmd /c" 0 "$?"
    check "autorun: no session was started under cmd /c" no "$([ -e "$TMP/state/sessions" ] && echo yes || echo no)"

    PS="${TSTAMP_TEST_POWERSHELL:-powershell}"
    if command -v "$PS" >/dev/null 2>&1; then
      rm -f "$TMP/state/enabled"
      "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(W "$S")" -Auto </dev/null >/dev/null 2>&1
      check "session -Auto: exit code 2 when global tracking is off" 2 "$?"
      printf 'boot=ts:1\nsince=1\ngen=x\n' > "$TMP/state/enabled"
      "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(W "$S")" -Auto </dev/null >/dev/null 2>&1
      check "session -Auto: exit code 2 for a flag from before a reboot" 2 "$?"
      check "session -Auto: the leftover flag is removed" no "$([ -e "$TMP/state/enabled" ] && echo yes || echo no)"
      printf 'boot=none\nsince=1\ngen=x\n' > "$TMP/state/enabled"
      out="$("$PS" -NoProfile -ExecutionPolicy Bypass -File "$(W "$S")" -Auto </dev/null 2>&1 | tr -d '\r')"
      hasout "session -Auto: starts when global tracking is on" 'TStamp is tracking this window' "$out"
      hasout "session -Auto: tracking is on in the window"      'Tracking enabled in this terminal' "$out"
      [ "$fail" -eq 0 ] || { echo "--- output ---"; printf '%s\n' "$out"; }
    else
      echo "skip - powershell.exe not found"
    fi
    ;;
  *) echo "skip - the AutoRun runs on Windows only" ;;
esac

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
