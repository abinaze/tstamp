# Architecture

TStamp is a set of bash scripts. There is no background service, no network
access and no compiled code.

## Layout

| Path | Purpose |
|---|---|
| `bin/tstamp` | Command dispatcher for everything that does not need to change the running shell |
| `bin/tstamp-a` | Launcher that enables global tracking from outside a hooked shell |
| `shells/bash.sh` | The hook loaded into an interactive bash |
| `lib/config.sh` | Reads and writes the `key=value` config file |
| `lib/format.sh` | Timestamp formats 1 to 5 and custom format strings |
| `lib/clock.sh` | Microsecond clock, formatting and durations without forking `date` |
| `lib/state.sh` | Global flag, reboot detection and live sessions |
| `lib/export.sh` | Merges logs into one chronological report |
| `lib/profile.sh` | Adds and removes the marked block in `~/.bashrc` |
| `installer/` | Staging script and the Inno Setup script |
| `tests/` | Test scripts; `tests/run_all.sh` runs them all |

## How tracking works

`shells/bash.sh` is sourced by an interactive bash. It installs a `DEBUG`
trap and three functions in `PROMPT_COMMAND`:

1. `__tstamp_precmd` runs first at each prompt. If a tracked command was
   running, it prints the END line with the exit code and duration, then
   returns the original exit code so `$?` is preserved.
2. Any `PROMPT_COMMAND` entries the user already had run next.
3. `__tstamp_arm` runs last and marks the next `DEBUG` event as a real user
   command, so the prompt functions themselves are never tracked.

When the trap fires for a user command and tracking is enabled, the hook
reads the command text from `history 1`, prints the START line and records
the start time. Output, pipelines and exit codes of the user's commands are
not changed. If another tool already owns the `DEBUG` trap, TStamp refuses to
install rather than replace it.

## State folder

The state folder is `~/.tstamp`, or `$TSTAMP_HOME` when that is set.

| Path | Meaning |
|---|---|
| `config` | Plain `key=value` file; currently `format=` |
| `enabled` | Exists only while global tracking is on; records the boot it was created in and a `gen` value that changes with every `tstamp-a` |
| `stopall` | A value that changes with every `tstamp-a stop` |
| `sessions/Tn/pid` | One folder per live terminal |
| `logs/Tn-PID.log` | One log file per terminal |

The config file is parsed, never sourced, so it cannot run code.

## Sessions

A terminal claims the lowest free ID (`T1`, `T2`, ...) by creating
`sessions/Tn` with `mkdir`, which is atomic. If the folder exists and its
shell has exited, the slot is reclaimed. This keeps IDs short and makes
errors from different terminals easy to tell apart.

## Global tracking and reboots

`tstamp-a` creates the `enabled` file. Every hooked terminal checks for it
at each prompt, so tracking starts and stops without restarting terminals.
Terminals that never loaded the hook cannot follow it.

`tstamp stop` stops one terminal. When global tracking is on, that terminal
remembers the `gen` value it stopped under and stays off until the next
`tstamp-a` writes a new one. `tstamp-a stop` removes `enabled` and writes a
new `stopall` value; a terminal turned on by hand with `tstamp` compares the
value it saw then with the current one, and stops when they differ.

The file stores a boot token. Where `/proc/sys/kernel/random/boot_id`
exists it is used. Git Bash has no such file, so the boot time is estimated
from the uptime counter and compared with a tolerance of 120 seconds. A flag
written before the last reboot is ignored, so tracking is off after a reboot.

## Log format

One tab-separated line per event:

```text
epoch_microseconds  session  shell_pid  START|END  exit_code  duration_us  command
```

Exit code and duration are empty on START lines. Tabs and line breaks inside
the command are replaced with spaces.

## Export

`tstamp export` sorts all selected logs numerically by the first column and
prints them in the saved default format. Tabs are swapped for the ASCII unit
separator before parsing, because bash `read` would otherwise merge the empty
fields on START lines.

## Startup file editing

`lib/profile.sh` writes one block between `# >>> tstamp >>>` and
`# <<< tstamp <<<`. It makes a timestamped backup first, never touches lines
outside the block, refuses to remove a block that has no end marker, and
refuses install paths containing characters that could change the meaning of
the line it writes.

## Windows installer

`installer/stage.sh` copies only the runtime files to `dist/stage`.
`installer/tstamp.iss` packages that folder with Inno Setup as a per-user
installer. It looks for Git Bash, optionally runs `tstamp hook add --yes`
through it, and the uninstaller runs `tstamp hook remove --yes`. GitHub
Actions builds the installer, then silently installs and uninstalls it on a
clean Windows machine as a smoke test.

## Testing

Tests run real interactive shells by feeding commands on standard input and
check the transcript. They use temporary state folders and never touch the
real `~/.tstamp` or `~/.bashrc`. The compatibility table in the manual is
based only on what these tests, locally or in CI, have shown.

## Known limits

- Supported: bash 4.4 or newer, Windows PowerShell 5.1 and PowerShell 7. CMD is tracked only with the optional Clink add-on.
- A pipeline is recorded as one command.
- Full-screen programs, background jobs and several commands on one line
  are not tested yet.
- The reboot reset is simulated, not yet verified with a real restart.

## Releases

The `Release` workflow (`.github/workflows/release.yml`) first calls the CI
workflow, so the tests must pass on Ubuntu, macOS and Windows. It then
builds the Windows installer, the Debian package, the Unix tarball and the web
installer, and smoke-tests the Windows installer with a silent install and
uninstall. On a tag it creates a draft release and attaches every file plus
`SHA256SUMS.txt`. It never publishes; see `docs/RELEASING.md`.

File names carry no version, so the `releases/latest/download/<file>` links
used by the README and the website keep working.

## PowerShell, CMD and `run`

`shells/powershell.ps1` tracks commands in Windows PowerShell 5.1 and PowerShell 7. It uses
PSReadLine's `AddToHistoryHandler` to print the START line when a line is
submitted, and a wrapper around `prompt` to print the END line, taking the
exit code from `$?`, `$LASTEXITCODE` and the error list. It writes the same
state folder, global flag and tab-separated logs as the bash integration, so
`tstamp export` merges both. Sessions it owns carry a `kind` file, and bash
never reclaims or lists them, because their process IDs mean something else to
bash. The other commands run through Git Bash.

CMD has no hook that runs around each command, so the window is not tracked on
its own. Typing `tstamp` in CMD starts `shells/cmdsession.ps1` through
`bin/tstamp.cmd`: Windows PowerShell with the normal hook, where
`PSConsoleHostReadLine` is replaced so that each typed line runs in `cmd.exe`
(`__ts_cmdrun`). After each line, `cmd.exe` writes its exit code, folder and
environment to temporary files so that `cd` and `set` carry over. The hook's
`prompt` prints the END line from that exit code.

`bin/tstamp.cmd` and `bin/tstamp-a.cmd` run the normal commands
through Git Bash, and `tstamp run COMMAND` (`lib/run.sh`) times one command, from
any shell. Started from CMD, it runs the command through `cmd.exe` so built-ins
like `dir` work.
