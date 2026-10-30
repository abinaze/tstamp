#!/usr/bin/env bash
# Tests for lib/clock.sh (compared against GNU date).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TZ=UTC

# shellcheck source=/dev/null
source "$ROOT/lib/format.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/clock.sh"

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

check_match() { # description, regex, actual
  if [[ "$3" =~ $2 ]]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (regex '$2', got '$3')"
  fi
}

# --- clock_now ---
tstamp_clock_now; a="$TSTAMP_US"
tstamp_clock_now; b="$TSTAMP_US"
check_match "clock_now is 16 digits" '^[0-9]{16}$' "$a"
check "clock_now never goes backwards" yes "$([ "$b" -ge "$a" ] && echo yes || echo no)"

# --- clock_format against GNU date (2023-11-14 22:13:20.123456 UTC) ---
US=1700000000123456
for id in 1 2 3 4 5; do
  f="$(tstamp_format_string "$id")"
  expected="$(date -d @1700000000.123456 +"$f")"
  tstamp_clock_format "$US" "$f"
  check "format $id matches date" "$expected" "$TSTAMP_OUT"
done

tstamp_clock_format "$US" '%Y-%m-%d %H:%M:%S.%3N'
check "literal %3N" '2023-11-14 22:13:20.123' "$TSTAMP_OUT"
tstamp_clock_format "$US" '%H:%M:%S.%6N'
check "literal %6N" '22:13:20.123456' "$TSTAMP_OUT"
tstamp_clock_format "$US" '%S.%N'
check "literal %N" '20.123456000' "$TSTAMP_OUT"
tstamp_clock_format "$US" '%z'
check "UTC offset" '+0000' "$TSTAMP_OUT"

# --- duration ---
tstamp_clock_duration 3100000;  check "duration 3.10s" 3.10 "$TSTAMP_OUT"
tstamp_clock_duration 999999;   check "duration 0.99s" 0.99 "$TSTAMP_OUT"
tstamp_clock_duration 0;        check "duration 0.00s" 0.00 "$TSTAMP_OUT"
tstamp_clock_duration -5;       check "negative becomes 0.00" 0.00 "$TSTAMP_OUT"
tstamp_clock_duration 12345678; check "duration 12.34s" 12.34 "$TSTAMP_OUT"
tstamp_clock_duration 1050000;  check "duration 1.05s" 1.05 "$TSTAMP_OUT"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
