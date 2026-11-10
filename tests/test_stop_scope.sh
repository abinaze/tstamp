#!/usr/bin/env bash
# Stop scope: "tstamp stop" stops only the current terminal, and
# "tstamp-a stop" stops every terminal. Everything runs in the foreground;
# a nested bash is a second terminal that is open while the first one waits.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
unset PROMPT_COMMAND
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

has() { # description, file, regex
  if grep -Eq -- "$3" "$2"; then pass=$((pass + 1)); echo "ok   - $1"
  else fail=$((fail + 1)); echo "FAIL - $1 (pattern: $3)"; fi
}
hasnt() { # description, file, regex
  if grep -Eq -- "$3" "$2"; then fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $3)"
  else pass=$((pass + 1)); echo "ok   - $1"; fi
}
check() { # description, expected, actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   - $1"
  else fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"; fi
}
gen_of() { grep '^gen=' "$1/enabled" 2>/dev/null; }

# ---------- Flow 1: global tracking, one terminal stops itself ----------
H1="$TMP/h1"; O1="$TMP/o1"; mkdir -p "$H1"
TSTAMP_HOME="$H1" HISTFILE="$TMP/hist1" bash --noprofile --norc -i > "$O1" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
tstamp-a 2
echo A-1
bash --noprofile --norc -i <<'INNER'
source "$ROOT/shells/bash.sh"
echo B-1
tstamp stop
echo B-2
tstamp status
bash "$ROOT/bin/tstamp-a"
echo B-3
exit
INNER
echo A-2
bash --noprofile --norc -i <<'INNER'
source "$ROOT/shells/bash.sh"
echo C-1
exit
INNER
exit
INPUT

has   "global: tstamp-a turns tracking on"          "$O1" '^Global tracking enabled\.$'
has   "global: A is tracked"                        "$O1" 'START: echo A-1$'
has   "global: B is tracked before it stops"        "$O1" 'START: echo B-1$'
has   "tstamp stop says it only stopped this terminal" "$O1" '^Tracking stopped in this terminal\. Other terminals are not affected\.$'
has   "tstamp stop points to tstamp-a stop"         "$O1" '^To stop everywhere, type: tstamp-a stop$'
hasnt "global: B is not tracked after tstamp stop"  "$O1" 'START: echo B-2$'
has   "global: the command still ran"               "$O1" '^B-2$'
has   "status explains the stopped terminal"        "$O1" '^This terminal : off \(stopped here; global tracking is on elsewhere\)$'
has   "status still shows global on"                "$O1" '^Global +: on \(since '
has   "global: the next tstamp-a switches B back on" "$O1" 'START: echo B-3$'
has   "global: A is not affected by B's stop"       "$O1" 'START: echo A-2$'
has   "global: a new terminal is tracked"           "$O1" 'START: echo C-1$'

# ---------- Flow 2: a terminal turned on by hand, tstamp-a stop elsewhere ----------
H2="$TMP/h2"; O2="$TMP/o2"; mkdir -p "$H2"
TSTAMP_HOME="$H2" HISTFILE="$TMP/hist2" bash --noprofile --norc -i > "$O2" 2>&1 <<INPUT
source "$ROOT/shells/bash.sh"
tstamp 2
echo H-1
bash --noprofile --norc -i <<'INNER'
source "$ROOT/shells/bash.sh"
tstamp-a stop
exit
INNER
echo H-2
tstamp status
tstamp
echo H-3
exit
INPUT

has   "by hand: tracked after tstamp"               "$O2" 'START: echo H-1$'
has   "tstamp-a stop reports success"               "$O2" '^Global tracking stopped\.$'
hasnt "by hand: stopped by tstamp-a stop elsewhere" "$O2" 'START: echo H-2$'
has   "by hand: status says off"                    "$O2" '^This terminal : off$'
has   "by hand: tstamp turns it on again"           "$O2" 'START: echo H-3$'

# ---------- Flow 3: standalone commands and files ----------
H3="$TMP/h3"; export TSTAMP_HOME="$H3"
bash "$ROOT/bin/tstamp-a" >/dev/null 2>&1
g1="$(gen_of "$H3")"
check "tstamp-a writes a gen value"                 yes "$([ -n "$g1" ] && echo yes || echo no)"
bash "$ROOT/bin/tstamp-a" >/dev/null 2>&1
check "each tstamp-a writes a new gen value"        yes "$([ "$(gen_of "$H3")" != "$g1" ] && echo yes || echo no)"

out="$(bash "$ROOT/bin/tstamp" stop 2>&1)"; rc=$?
check "standalone tstamp stop succeeds"             0 "$rc"
check "standalone tstamp stop leaves global on"     yes "$([ -e "$H3/enabled" ] && echo yes || echo no)"
printf '%s\n' "$out" > "$TMP/o3"
has   "standalone tstamp stop explains itself"      "$TMP/o3" '^Nothing is tracked in this window'
has   "standalone tstamp stop points to tstamp-a stop" "$TMP/o3" 'tstamp-a stop'

bash "$ROOT/bin/tstamp-a" stop >/dev/null 2>&1
check "tstamp-a stop removes the global flag"       no "$([ -e "$H3/enabled" ] && echo yes || echo no)"
check "tstamp-a stop writes stopall"                yes "$([ -s "$H3/stopall" ] && echo yes || echo no)"
s1="$(cat "$H3/stopall")"
bash "$ROOT/bin/tstamp-a" stop >/dev/null 2>&1
check "each tstamp-a stop writes a new value"       yes "$([ "$(cat "$H3/stopall")" != "$s1" ] && echo yes || echo no)"
bash "$ROOT/bin/tstamp-a" stop extra >/dev/null 2>&1
check "tstamp-a stop with extra words is a usage error" 2 "$?"

# a flag written by an older version has no gen value
printf 'boot=none\nsince=1\n' > "$H3/enabled"
got="$(bash -c 'source "$1/lib/config.sh"; source "$1/lib/format.sh"; source "$1/lib/clock.sh"; source "$1/lib/state.sh"; tstamp_global_state; printf "%s %s" "$TSTAMP_GLOBAL" "$TSTAMP_GLOBAL_GEN"' _ "$ROOT")"
check "a flag without gen reads as legacy"          "on legacy" "$got"

echo
echo "passed=$pass failed=$fail"
if [ "$fail" -ne 0 ]; then
  echo "--- flow 1 transcript ---"; cat "$O1"
  echo "--- flow 2 transcript ---"; cat "$O2"
fi
[ "$fail" -eq 0 ]
