#!/usr/bin/env bash
# Keeps the manual in the conventional order of a man page, and keeps its
# layout tidy: headings flush left, everything else indented.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M="$ROOT/docs/manual.txt"
pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}

ORDER="NAME|SYNOPSIS|DESCRIPTION|GETTING STARTED|COMMANDS|FORMATS|EXIT STATUS|ENVIRONMENT|FILES AND CONFIGURATION|OUTPUT AND LOGS|EXAMPLES|SHELL COMPATIBILITY|LIMITATIONS|PRIVACY|INSTALLATION|UNINSTALLATION|TROUBLESHOOTING|SEE ALSO"
want="$(printf '%s' "$ORDER" | tr '|' '\n')"
got="$(grep -E '^[^ ]' "$M")"
check "the flush-left lines are exactly the headings, in this order" "$want" "$got"
check "no line is longer than 78 characters" 0 "$(awk 'length > 78' "$M" | wc -l | tr -d ' ')"
check "no tab characters" 0 "$(tr -cd '\t' < "$M" | wc -c | tr -d ' ')"
check "no trailing spaces" 0 "$(grep -c ' $' "$M" || true)"
check "the file ends with exactly one newline" 1 "$([ "$(tail -c 1 "$M" | od -An -c | tr -d ' ')" = '\n' ] && [ -n "$(tail -n 1 "$M")" ] && echo 1 || echo 0)"
check "every command in SYNOPSIS is explained under COMMANDS" 0 "$(for c in 'tstamp-a' 'tstamp stop' 'tstamp status' 'tstamp format' 'tstamp set' 'tstamp export' 'tstamp run' 'tstamp hook add' 'tstamp reset' 'tstamp help' 'tstamp man' 'tstamp examples' 'tstamp version'; do awk '/^COMMANDS$/ {on=1; next} /^FORMATS$/ {on=0} on' "$M" | grep -qF -- "$c" || echo "$c"; done | wc -l | tr -d ' ')"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
