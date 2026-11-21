#!/usr/bin/env bash
# Static checks for the optional WSL workflow: manual start only, read-only
# permissions, and the third-party action pinned to one exact commit.
# Uses only grep, so it behaves the same on Linux, macOS and Windows.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="$ROOT/.github/workflows/wsl.yml"
pass=0
fail=0
has() { # description, regex: the workflow must contain it
  if grep -Eq -- "$2" "$WF"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1"; fi
}
lacks() { # description, regex: the workflow must not contain it
  if grep -Eq -- "$2" "$WF"; then fail=$((fail + 1)); echo "FAIL - $1"; else pass=$((pass + 1)); echo "ok   - $1"; fi
}

if [ -f "$WF" ]; then pass=$((pass + 1)); echo "ok   - the workflow exists"; else fail=$((fail + 1)); echo "FAIL - the workflow exists"; fi
has   "it starts by hand only"                              '^  workflow_dispatch:'
lacks "it has no push, pull request or release trigger"     '^  (push|pull_request|release|schedule|workflow_call):'
has   "it has read-only permissions"                        '^  contents: read'
has   "the setup action is pinned to a 40-character commit" 'uses: Vampire/setup-wsl@[0-9a-f]{40} # v[0-9]+\.[0-9]+\.[0-9]+'
lacks "it uses no secrets"                                  'secrets\.'
has   "it has a timeout"                                    'timeout-minutes: [0-9]+'

# Workflow files must have LF line endings on every system, because tests that
# read them with grep (for example "^  contents: read$") fail on a CR.
if grep -Eq '^\*\.yml text eol=lf$' "$ROOT/.gitattributes"; then pass=$((pass + 1)); echo "ok   - .gitattributes keeps LF in workflow files"; else fail=$((fail + 1)); echo "FAIL - .gitattributes keeps LF in workflow files"; fi

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
