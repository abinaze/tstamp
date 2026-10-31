#!/usr/bin/env bash
# Cross-terminal test, run entirely in the foreground (Git Bash suspends
# background interactive shells).
# Terminal A is a live hooked shell. It runs tstamp-a and tstamp stop as
# separate processes, exactly like another window would.
# Terminal B is a new terminal opened while global tracking is on.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSTAMP_HOME="$(mktemp -d)"
export TSTAMP_HOME
OUT="$TSTAMP_HOME.transcript"
unset PROMPT_COMMAND
trap 'rm -rf "$TSTAMP_HOME" "$OUT"' EXIT

HISTFILE="$TSTAMP_HOME/history" bash --noprofile --norc -i > "$OUT" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
echo A-off-1
bash "$ROOT/bin/tstamp-a" 2
echo A-on-2
tstamp status
bash --noprofile --norc -i <<'INNER'
source "$ROOT/shells/bash.sh"
echo B-on-1
tstamp status
exit
INNER
bash "$ROOT/bin/tstamp" stop
echo A-off-3
exit
INPUT

pass=0
fail=0

has() { # description, regex
  if grep -Eq -- "$2" "$OUT"; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"
  fi
}

hasnt() { # description, regex
  if grep -Eq -- "$2" "$OUT"; then
    fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $2)"
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

T='[0-9]{2}:[0-9]{2}:[0-9]{2}'

hasnt "A: not tracked before tstamp-a" 'START: echo A-off-1'
has   "tstamp-a reports success" '^Global tracking enabled\.$'
has   "A: tracked after tstamp-a, no restart, new default format" "^\[T1\]\[$T\] START: echo A-on-2\$"
has   "A: END line has exit code and duration" 'END: echo A-on-2 \| EXIT=0 \| DURATION=[0-9]+\.[0-9]{2}s$'
has   "A: status says on (global)" 'This terminal : on \(global\)'
has   "A: status shows session T1" 'Session ID +: T1$'
has   "status shows global on" 'Global +: on \(since '
has   "B: new terminal tracked from its first command" "^\[T2\]\[$T\] START: echo B-on-1\$"
has   "B: END line has exit code and duration" 'END: echo B-on-1 \| EXIT=0 \| DURATION=[0-9]+\.[0-9]{2}s$'
has   "tstamp stop reports success" '^Global tracking stopped\.$'
hasnt "A: not tracked after tstamp stop" 'START: echo A-off-3'
has   "A: command still ran after stop" '^A-off-3$'
check "global flag removed" no "$([ -e "$TSTAMP_HOME/enabled" ] && echo yes || echo no)"

set -- "$TSTAMP_HOME"/logs/*.log
check "one log file per terminal" 2 "$#"

echo
echo "--- transcript ---"
cat "$OUT"
echo "--- end transcript ---"
echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
