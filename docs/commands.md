# Commands

Type these in a terminal where tstamp is installed.

| Command | What it does |
|---|---|
| `tstamp-a [FORMAT]` | Turn on in **every** terminal that has tstamp loaded |
| `tstamp [FORMAT]` | Turn on in **this** terminal only |
| `tstamp stop` | Turn off in this terminal only |
| `tstamp-a stop` | Turn off in **every** terminal |
| `tstamp status` | Show what is on |
| `tstamp format` | List the time styles, with live examples |
| `tstamp set FORMAT` | Save a new default time style |
| `tstamp export [-o FILE] [T1 T2 ...]` | Combine logs into one timeline |
| `tstamp hook add [--powershell]` | Load tstamp in every new bash (or PowerShell) window |
| `tstamp hook remove [--powershell]` | Undo `hook add` |
| `tstamp help` | Short help |
| `tstamp man` | The full manual, offline |
| `tstamp examples` | Ready-to-use examples |
| `tstamp version` | Show the installed version |
| `tstamp reset` | Restore the default settings |
| `tstamp run COMMAND [ARGS...]` | Time one command, in any shell including CMD |

`FORMAT` is a number from 1 to 5, or your own pattern. See
[timestamp formats](timestamp-formats.md).

## tstamp-a

Turns tracking on for all terminals. Terminals that are already open start at
their next prompt; new ones start with their first command. With a format,
`tstamp-a 2` also saves it as the default. Global tracking ends when the computer
restarts.

## tstamp

Turns tracking on in the current window only. A format, such as `tstamp 2`,
applies to this window only.

## tstamp stop

Turns tracking off in this window only. Other windows are not affected. If
global tracking is on, this window stays off until the next `tstamp-a`. Type
`tstamp` to turn it on again in this window alone.

In a window where tstamp is not loaded (for example Command Prompt) there is
nothing to stop, and `tstamp stop` says so.

## tstamp-a stop

Turns tracking off in every window. Windows that have tstamp loaded stop at
their next prompt, including windows where you typed `tstamp` yourself. Type
`tstamp-a` to start again.

## tstamp status

Shows this window's state and label, the saved time style, whether global
tracking is on, and which windows are open. Example:

```text
This terminal : on (global)
Session ID    : T1
Format here   : %H:%M:%S
Global        : on (since 2026-10-30 07:37:50)
Default format: 2
Live sessions : T1(pid 1173) T2(pid 1199)
```

## tstamp export

Combines the logs of your windows into one list, oldest first, in your saved
time style.

```bash
tstamp export                     # all windows, on screen
tstamp export T1 T3               # only windows T1 and T3
tstamp export -o report.txt       # save to a file
```

It never overwrites an existing file. If it finds no logs it says so and exits
with status 1.

## tstamp hook add and remove

`hook add` adds a short block to your bash startup file (`~/.bashrc`; on a Mac
both `~/.bash_profile` and `~/.bashrc`) so new windows load tstamp. With
`--powershell` it edits your PowerShell profile instead. It asks first, saves a
backup, and never touches other lines. `hook remove` takes the block out again.
Add `--yes` to skip the question. The installers run these for you.

## tstamp run

Runs one command and prints a START and an END line around it, with the exit code
and the duration. It writes to the same log as your other windows, so
`tstamp export` includes it. It returns the command's own exit code.

```bash
tstamp run npm run build
```

It works in every shell, and it is the way to time commands in Command Prompt,
which cannot be tracked automatically. In Command Prompt it uses CMD's own
commands, so `tstamp run dir` and `tstamp run ver` work.

## Where tstamp keeps things

| Place | Contents |
|---|---|
| `~/.tstamp/config` | Your saved time style |
| `~/.tstamp/logs/` | One log file per window |
| `~/.tstamp/enabled` | Exists only while global tracking is on |
| `~/.tstamp/stopall` | Changes every time you type `tstamp-a stop` |

## Privacy

The logs contain the full text of every command, including any password you
type inside a command. They are not encrypted and never leave your computer. Run
`tstamp stop` in that window before typing secrets, and delete logs you no longer need:

```bash
rm -rf ~/.tstamp/logs
```
