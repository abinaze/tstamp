#!/usr/bin/env bash
# Runs the PowerShell tests again with PowerShell 7 (pwsh) instead of Windows
# PowerShell 5.1. Windows only, and skipped when pwsh is not installed.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "skip - the PowerShell 7 run is Windows only"; echo; echo "passed=0 failed=0 skipped=1"; exit 0 ;;
esac
if ! command -v pwsh >/dev/null 2>&1; then
  # On a developer machine this is a skip. In CI the claim "the PowerShell tests
  # run on PowerShell 7" must hold, so a missing pwsh there is a failure.
  if [ "${CI:-}" = "true" ]; then
    echo "FAIL - pwsh is not installed on this CI machine, so PowerShell 7 was not tested"
    echo; echo "passed=0 failed=1"; exit 1
  fi
  echo "skip - pwsh not found"; echo; echo "passed=0 failed=0 skipped=1"; exit 0
fi

pass=0
fail=0
echo "PowerShell 7 version: $(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null | tr -d '\r')"
for t in test_powershell.sh test_powershell_scope.sh test_cmdsession.sh; do
  if out="$(TSTAMP_TEST_POWERSHELL=pwsh bash "$ROOT/tests/$t" 2>&1)"; then
    pass=$((pass + 1)); echo "ok   - $t passes on PowerShell 7"
  else
    fail=$((fail + 1)); echo "FAIL - $t on PowerShell 7"; printf '%s\n' "$out" | tail -n 40
  fi
done

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
