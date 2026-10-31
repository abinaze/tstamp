#!/usr/bin/env bash
# Hook test: runs real interactive bash sessions with shells/bash.sh loaded.
# Everything happens in a temporary TSTAMP_HOME and a temporary history file.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSTAMP_HOME="$(mktemp -d)"
export TSTAMP_HOME
OUT="$TSTAMP_HOME.transcript"
unset PROMPT_COMMAND
trap 'rm -rf "$TSTAMP_HOME" "$OUT"' EXIT

HISTFILE="$TSTAMP_HOME/history" bash --noprofile --norc -i > "$OUT" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
echo before-enable
tstamp
echo hello
false
echo "rc=\$?"
sleep 1
echo piped | tr a-z A-Z
tstamp status
bash --noprofile --norc -i <<'INNER'
source "$ROOT/shells/bash.sh"
tstamp
echo inner
exit
INNER
tstamp 2
echo fmt2
tstamp stop
echo after-stop
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

has   "enable message" 'Tracking enabled in this terminal \(session T1\)'
hasnt "no START before enabling" 'START: echo before-enable'
has   "START line format" '\[T1\]\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\] START: echo hello$'
has   "END line with exit 0 and duration" 'END: echo hello \| EXIT=0 \| DURATION=0\.[0-9]{2}s$'
has   "exit code 1 recorded" 'END: false \| EXIT=1 \| DURATION='
has   "exit code preserved for next command" 'rc=1$'
has   "sleep 1 duration" 'END: sleep 1 \| EXIT=0 \| DURATION=1\.[0-4][0-9]s$'
has   "pipeline START recorded" 'START: echo piped'
has   "pipeline output intact" 'PIPED$'
hasnt "tstamp commands not tracked" 'START: tstamp'
has   "second terminal gets its own ID" '\[T2\]\[[^]]+\] START: echo inner'
has   "per-terminal format override" '\[T1\]\[[0-9]{2}:[0-9]{2}:[0-9]{2}\] START: echo fmt2$'
hasnt "no START after stop" 'START: echo after-stop'
has   "command still ran after stop" 'after-stop$'

if grep -Eq -- 'START: echo piped \| tr a-z A-Z' "$OUT"; then
  echo "info - full pipeline text captured: yes"
else
  echo "info - full pipeline text captured: no (only first command shown)"
fi

if ls "$TSTAMP_HOME"/logs/T1-*.log >/dev/null 2>&1; then
  pass=$((pass + 1)); echo "ok   - T1 log file exists"
else
  fail=$((fail + 1)); echo "FAIL - T1 log file missing"
fi
if grep -Eq $'\tEND\t1\t[0-9]+\tfalse$' "$TSTAMP_HOME"/logs/T1-*.log 2>/dev/null; then
  pass=$((pass + 1)); echo "ok   - log has END record for false"
else
  fail=$((fail + 1)); echo "FAIL - log missing END record for false"
fi
if [ -d "$TSTAMP_HOME/sessions/T1" ] && [ -d "$TSTAMP_HOME/sessions/T2" ]; then
  pass=$((pass + 1)); echo "ok   - session folders T1 and T2 exist"
else
  fail=$((fail + 1)); echo "FAIL - session folders missing"
fi

echo
echo "--- transcript ---"
cat "$OUT"
echo "--- end transcript ---"
echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
