#!/usr/bin/env bash
# Static checks for the optional WSL workflow: manual start only, read-only
# permissions, and the third-party action pinned to one exact commit.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="$ROOT/.github/workflows/wsl.yml"
pass=0
fail=0
check() { # description, yes|no
  if [ "$2" = yes ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1"; fi
}
has() { grep -Eq -- "$1" "$WF" && echo yes || echo no; }

check "the workflow exists"                              "$([ -f "$WF" ] && echo yes || echo no)"
check "it starts by hand only"                           "$(has '^  workflow_dispatch:$')"
check "it has no push, pull request or release trigger"  "$(has '^  (push|pull_request|release|schedule|workflow_call):' | sed 's/yes/no/;t;s/no/yes/')"
check "it has read-only permissions"                     "$(has '^  contents: read$')"
check "the setup action is pinned to a 40-character commit" "$(has 'uses: Vampire/setup-wsl@[0-9a-f]{40} # v[0-9]+\.[0-9]+\.[0-9]+$')"
check "it uses no secrets"                               "$(has 'secrets\.' | sed 's/yes/no/;t;s/no/yes/')"
check "it has a timeout"                                 "$(has 'timeout-minutes: [0-9]+')"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
