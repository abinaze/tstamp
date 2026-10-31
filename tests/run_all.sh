#!/usr/bin/env bash
# Runs every tests/test_*.sh file and prints one PASS/FAIL line per file.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

for t in "$ROOT"/tests/test_*.sh; do
  name="${t##*/}"
  if bash "$t" >/dev/null 2>&1; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    failed=$((failed + 1))
  fi
done

echo
if [ "$failed" -eq 0 ]; then
  echo "ALL TESTS PASS"
else
  echo "$failed test file(s) failed"
fi
[ "$failed" -eq 0 ]
