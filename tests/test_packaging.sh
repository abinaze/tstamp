#!/usr/bin/env bash
# Static checks for the installer script and the build workflows.
# They do NOT compile the installer; they catch typos and drift between
# files. The real test is the workflow run on GitHub.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISS="$ROOT/installer/tstamp.iss"
REL="$ROOT/.github/workflows/release.yml"
CI="$ROOT/.github/workflows/ci.yml"
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
has   "iss: output file name has no version in it" "$ISS" 'OutputBaseFilename=tstamp-windows-setup'
has   "iss: installs the staged files" "$ISS" 'Source: "..\dist\stage\*"'
has   "iss: bashrc edit is a task the user can untick" "$ISS" 'Name: "bashhook"'
has   "iss: calls hook add" "$ISS" "RunTstamp('add')"
has   "iss: calls hook remove on uninstall" "$ISS" "RunTstamp('remove')"
has   "iss: passes --yes to the hook command" "$ISS" ' --yes"'
has   "iss: stops cleanly when Git Bash is missing" "$ISS" 'Install Git for Windows'
check "iss: no { } comment contains another brace" 0 "$(grep -cE '^\{[^}]*\{' "$ISS" || true)"
has   "iss: PowerShell profile is a task" "$ISS" 'Name: "powershellhook"'
has   "iss: PATH is a task" "$ISS" 'Name: "addtopath"'
has   "iss: Command Prompt AutoRun is a task" "$ISS" 'Name: "cmdautorun"'
has   "iss: PowerShell hook uses the tested command" "$ISS" '--powershell --yes"'
has   "iss: the environment change is broadcast" "$ISS" 'ChangesEnvironment=yes'
has   "iss: uninstall removes the PATH entry" "$ISS" 'RemoveFromUserPath;'
has   "iss: uninstall removes the PowerShell block" "$ISS" "RunTstampPS('remove')"
has   "release: checks the PATH entry after install" "$REL" 'GetEnvironmentVariable'
has   "iss: deleting user data defaults to No" "$ISS" 'MB_DEFBUTTON2'
has   "stage.sh writes where the installer script reads" "$STAGE" 'dist/stage'
has   "stage.sh ships the PowerShell integration" "$STAGE" 'shells/powershell.ps1'

# --- old Windows-only workflow is gone ---
check "installer.yml is gone (release.yml replaces it)" no "$([ -e "$ROOT/.github/workflows/installer.yml" ] && echo yes || echo no)"

# --- release workflow ---
has   "release: can be started by hand" "$REL" 'workflow_dispatch:'
has   "release: tag trigger" "$REL" '      - "v*"'
has   "release: runs the CI tests first" "$REL" 'uses: ./.github/workflows/ci.yml'
has   "release: compiles the installer script" "$REL" 'installer\tstamp.iss'
has   "release: passes the version to the compiler" "$REL" '/DMyAppVersion='
has   "release: smoke-tests a silent install" "$REL" '/VERYSILENT'
has   "release: builds the tarball" "$REL" 'installer/build-unix.sh'
has   "release: builds the .deb" "$REL" 'installer/build-deb.sh'
has   "release: ships get.sh" "$REL" 'dist/get.sh'
has   "release: writes checksums" "$REL" 'SHA256SUMS.txt'
has   "release: creates the release as a draft" "$REL" '--draft'
has   "release: only touches releases for tags" "$REL" "if: github.ref_type == 'tag'"
has   "release: creates with gh" "$REL" 'gh release create'
has   "release: uploads with gh" "$REL" 'gh release upload'
has   "release: verifies the tag exists" "$REL" '--verify-tag'
has   "release: Windows file name" "$REL" 'tstamp-windows-setup.exe'
has   "release: Unix file name" "$REL" 'tstamp-unix.tar.gz'
has   "release: Debian file name" "$REL" 'tstamp.deb'
hasnt "release: avoids pull_request_target" "$REL" 'pull_request_target'
hasnt "release: never publishes by itself" "$REL" '--draft=false'
hasnt "release: no pipe into head (SIGPIPE fails a step under pipefail)" "$REL" '| head'
check "release: write access only in the 4 jobs that need it" 4 "$(grep -cF 'contents: write' "$REL")"
check "release: read-only by default" 1 "$(grep -c '^  contents: read$' "$REL")"
check "release: no tab characters" 0 "$(tr -cd '\t' < "$REL" | wc -c | tr -d ' ')"

# --- test workflow ---
has   "ci: can be started by hand" "$CI" 'workflow_dispatch:'
has   "ci: can be called by the release workflow" "$CI" 'workflow_call:'
has   "ci: runs the test suite" "$CI" 'tests/test_*.sh'
check "ci: read-only" 0 "$(grep -cF 'contents: write' "$CI")"
check "ci: no tab characters" 0 "$(tr -cd '\t' < "$CI" | wc -c | tr -d ' ')"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
