#!/usr/bin/env bash
# Static checks for the installer script and the build workflow.
# They do NOT compile the installer; they catch typos and drift between
# files. The real test is the workflow run on GitHub.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISS="$ROOT/installer/tstamp.iss"
WF="$ROOT/.github/workflows/installer.yml"
STAGE="$ROOT/installer/stage.sh"

pass=0
fail=0

has() { # description, file, fixed text
  if grep -qF -- "$3" "$2"; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (missing: $3)"
  fi
}

hasnt() { # description, file, fixed text
  if grep -qF -- "$3" "$2"; then
    fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $3)"
  else
    pass=$((pass + 1)); echo "ok   - $1"
  fi
}

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

# --- installer script ---
has   "iss: per-user install, no admin prompt" "$ISS" 'PrivilegesRequired=lowest'
hasnt "iss: never asks for admin" "$ISS" 'PrivilegesRequired=admin'
has   "iss: installs under the per-user program folder" "$ISS" 'DefaultDirName={autopf}\TStamp'
has   "iss: output name carries the version" "$ISS" 'OutputBaseFilename=tstamp-windows-setup'
has   "iss: installs the staged files" "$ISS" 'Source: "..\dist\stage\*"'
has   "iss: bashrc edit is a task the user can untick" "$ISS" 'Name: "bashhook"'
has   "iss: calls hook add" "$ISS" "RunTstamp('add')"
has   "iss: calls hook remove on uninstall" "$ISS" "RunTstamp('remove')"
has   "iss: passes --yes to the hook command" "$ISS" ' --yes"'
has   "iss: stops cleanly when Git Bash is missing" "$ISS" 'Install Git for Windows'
has   "iss: deleting user data defaults to No" "$ISS" 'MB_DEFBUTTON2'
has   "stage.sh writes where the installer script reads" "$STAGE" 'dist/stage'

# --- workflow ---
has   "workflow: can be started by hand" "$WF" 'workflow_dispatch:'
has   "workflow: tag trigger" "$WF" '      - "v*"'
has   "workflow: compiles the installer script" "$WF" 'installer\tstamp.iss'
has   "workflow: passes the version to the compiler" "$WF" '/DMyAppVersion='
has   "workflow: runs the test suite" "$WF" 'tests/test_*.sh'
has   "workflow: smoke-tests a silent install" "$WF" '/VERYSILENT'
has   "workflow: writes checksums" "$WF" 'sha256sum'
has   "workflow: publishes only for tags" "$WF" "if: github.ref_type == 'tag'"
has   "workflow: publishes with gh" "$WF" 'gh release create'
hasnt "workflow: avoids pull_request_target" "$WF" 'pull_request_target'
check "workflow: write permission appears once" 1 "$(grep -cF 'contents: write' "$WF")"
check "workflow: no tab characters" 0 "$(tr -cd '\t' < "$WF" | wc -c | tr -d ' ')"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
