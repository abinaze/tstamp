#!/usr/bin/env bash
# Checks the documentation pages: they exist, start with a heading, and every
# relative link in the README and docs/*.md points at a file that exists.

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

for p in README introduction installation quick-start commands timestamp-formats \
         examples compatibility troubleshooting contributing changelog; do
  f="$ROOT/docs/$p.md"
  check "docs/$p.md exists and starts with a heading" yes "$([ -s "$f" ] && head -n 1 "$f" | grep -q '^# ' && echo yes || echo no)"
done

check "README has the white banner" 1 "$(grep -c 'assets/brand/png/tstamp-banner.png' "$ROOT/README.md")"
check "the banner file exists" yes "$([ -s "$ROOT/assets/brand/png/tstamp-banner.png" ] && echo yes || echo no)"
check "the social preview image exists" yes "$([ -s "$ROOT/assets/brand/png/tstamp-social-preview.png" ] && echo yes || echo no)"

for md in "$ROOT/README.md" "$ROOT"/docs/*.md; do
  dir="$(dirname "$md")"
  bad=0
  for target in $(grep -o '\](\([^)]*\))' "$md" | sed 's/^](//; s/)$//; s/#.*$//' | grep -v -e '^$' -e '^http' -e '^mailto'); do
    [ -e "$dir/$target" ] || { bad=$((bad + 1)); echo "     broken link in ${md#"$ROOT"/}: $target"; }
  done
  for target in $(grep -o '\(src\|href\)="[^"#:]*"' "$md" | sed 's/^[a-z]*="//; s/"$//' | grep -v '^$'); do
    [ -e "$dir/$target" ] || { bad=$((bad + 1)); echo "     broken link in ${md#"$ROOT"/}: $target"; }
  done
  check "no broken relative links in ${md#"$ROOT"/}" 0 "$bad"
done

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
