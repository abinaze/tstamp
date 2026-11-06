#!/usr/bin/env bash
# Static checks for the website deploy workflow and for the site it publishes.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="$ROOT/.github/workflows/pages.yml"
pass=0
fail=0

has() { # description, fixed text
  if grep -qF -- "$2" "$WF"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (missing: $2)"; fi
}
hasnt() { # description, fixed text
  if grep -qF -- "$2" "$WF"; then fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $2)"; else pass=$((pass + 1)); echo "ok   - $1"; fi
}
check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}

has   "publishes only the site folder" 'path: site'
has   "runs when the site changes" '      - "site/**"'
has   "can be started by hand" 'workflow_dispatch:'
has   "is skipped while the repository is private" 'github.event.repository.private == false'
has   "may write Pages" 'pages: write'
has   "may request the Pages token" 'id-token: write'
has   "uses the Pages deploy action" 'actions/deploy-pages@'
has   "never overlaps with itself" 'cancel-in-progress: false'
hasnt "avoids pull_request_target" 'pull_request_target'
hasnt "does not run on pull requests" 'pull_request:'
check "read-only by default" 1 "$(grep -c '^  contents: read$' "$WF")"
check "no tab characters" 0 "$(tr -cd '\t' < "$WF" | wc -c | tr -d ' ')"

# the site must work from a sub-path (https://USER.github.io/tstamp/)
check "the site uses no absolute local links" 0 "$(grep -cE '(href|src)="/[^/]' "$ROOT/site/index.html" || true)"
check "the site has a .nojekyll file" yes "$([ -e "$ROOT/site/.nojekyll" ] && echo yes || echo no)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
