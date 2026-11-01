#!/usr/bin/env bash
# Checks that the standard repository files exist and say what they should.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

has() { # description, file, fixed text
  if grep -qF -- "$3" "$ROOT/$2"; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (missing: $3)"
  fi
}

FILES=(
  LICENSE README.md CHANGELOG.md CONTRIBUTING.md CODE_OF_CONDUCT.md
  SECURITY.md SUPPORT.md .editorconfig docs/ARCHITECTURE.md
  .github/CODEOWNERS .github/dependabot.yml .github/pull_request_template.md
  .github/ISSUE_TEMPLATE/bug_report.yml
  .github/ISSUE_TEMPLATE/feature_request.yml
  .github/ISSUE_TEMPLATE/config.yml
)

for f in "${FILES[@]}"; do
  check "$f exists and is not empty" yes "$([ -s "$ROOT/$f" ] && echo yes || echo no)"
done

has "LICENSE is MIT" LICENSE 'MIT License'
has "LICENSE names the copyright holder" LICENSE 'Copyright (c) 2026 '
has "LICENSE has the warranty clause" LICENSE 'WITHOUT WARRANTY OF ANY KIND'
has "CHANGELOG has an Unreleased section" CHANGELOG.md '## [Unreleased]'
has "SECURITY explains private reporting" SECURITY.md 'Report a vulnerability'
has "README links the license" README.md '[LICENSE](LICENSE)'
has "README links CONTRIBUTING" README.md '[CONTRIBUTING.md](CONTRIBUTING.md)'
has "bug template is a bug report" .github/ISSUE_TEMPLATE/bug_report.yml 'name: Bug report'
has "issue config disables blank issues" .github/ISSUE_TEMPLATE/config.yml 'blank_issues_enabled: false'

tabs=0
for f in .github/dependabot.yml .github/ISSUE_TEMPLATE/bug_report.yml \
         .github/ISSUE_TEMPLATE/feature_request.yml .github/ISSUE_TEMPLATE/config.yml; do
  tabs=$((tabs + $(tr -cd '\t' < "$ROOT/$f" | wc -c)))
done
check "YAML files contain no tab characters" 0 "$tabs"

leaks="$(cd "$ROOT" && grep -lE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' \
  LICENSE CHANGELOG.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md SUPPORT.md \
  docs/ARCHITECTURE.md .github/CODEOWNERS 2>/dev/null | wc -l | tr -d ' ')"
check "no email addresses in the new documents" 0 "$leaks"

bash "$ROOT/installer/stage.sh" >/dev/null 2>&1
check "the installer package includes the license" yes "$([ -f "$ROOT/dist/stage/LICENSE" ] && echo yes || echo no)"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
