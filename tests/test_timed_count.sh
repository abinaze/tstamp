#!/usr/bin/env bash
# "tstamp status" shows how many commands were timed: in this terminal and in
# all logs. Also checks that standalone "tstamp status" shows every line.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSTAMP_HOME="$(mktemp -d)"
export TSTAMP_HOME
OUT="$TSTAMP_HOME.transcript"
unset PROMPT_COMMAND
trap 'rm -rf "$TSTAMP_HOME" "$OUT"' EXIT

pass=0
fail=0
has() { # description, regex, text
  if printf '%s\n' "$3" | grep -Eq -- "$2"; then pass=$((pass + 1)); echo "ok   - $1"; else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $2)"; fi
}

# Standalone, nothing logged yet.
s0="$(bash "$ROOT/bin/tstamp" status 2>&1)"
has "standalone status shows the reboot check"      '^Reboot check  : ' "$s0"
has "standalone status shows live sessions"         '^Live sessions : none$' "$s0"
has "no logs: zero timed commands"                  '^Timed commands: 0 \(all terminals, 0 log files\)$' "$s0"

# Standalone, two log files with START and END lines.
mkdir -p "$TSTAMP_HOME/logs"
printf '1\tT1\t5\tSTART\t\t\tls\n2\tT1\t5\tEND\t0\t100\tls\n3\tT1\t5\tSTART\t\t\tx\n4\tT1\t5\tEND\t1\t100\tx\n5\tT1\t5\tSTART\t\t\trunning\n' > "$TSTAMP_HOME/logs/T1-5.log"
printf '1\tT2\t6\tSTART\t\t\tls\n2\tT2\t6\tEND\t0\t100\tls\n' > "$TSTAMP_HOME/logs/T2-6.log"
s1="$(bash "$ROOT/bin/tstamp" status 2>&1)"
has "counts END lines only, over all logs"          '^Timed commands: 3 \(all terminals, 2 log files\)$' "$s1"
rm -f "$TSTAMP_HOME/logs/T2-6.log"
s2="$(bash "$ROOT/bin/tstamp" status 2>&1)"
has "one log file is written in the singular"       '^Timed commands: 2 \(all terminals, 1 log file\)$' "$s2"
rm -f "$TSTAMP_HOME/logs/"*.log

# A hooked terminal.
HISTFILE="$TSTAMP_HOME/history" bash --noprofile --norc -i > "$OUT" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
tstamp status
tstamp 2
echo one
echo two
tstamp status
exit
INPUT
t="$(cat "$OUT")"
has "before any command: timed here is 0"           '^Timed here    : 0$' "$t"
has "after two commands: timed here is 2"           '^Timed here    : 2$' "$t"
has "after two commands: all terminals shows 2"     '^Timed commands: 2 \(all terminals, 1 log file\)$' "$t"

# The PowerShell script carries the same lines (it runs for real in the Windows tests).
ps="$(cat "$ROOT/shells/powershell.ps1")"
has "powershell status has a Timed here line"       "Timed here    : \{0\}" "$ps"
has "powershell status has a Timed commands line"   "Timed commands: \{0\} \(all terminals" "$ps"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
