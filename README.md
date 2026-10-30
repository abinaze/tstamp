# TStamp

A lightweight, local-first terminal timestamp utility. It prints a START
and an END line, with exit code and duration, around every command you run.

```text
[T1][2026-10-29 19:42:01.100] START: npm run build
Build failed.
[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s
```

No cloud accounts, telemetry, AI APIs or background service are required.

## Status

Early development. Bash on Git Bash (Windows) is the only supported
shell. Other shells and operating systems are not tested yet.

Working today:

- Per-terminal tracking: `tstamp`, `tstamp 2`, `tstamp "%H:%M"`
- Global tracking across terminals: `tstamp-a`, `tstamp stop`
- Formats: `tstamp format`, `tstamp set`, `tstamp reset`
- Offline docs: `tstamp help`, `tstamp man`, `tstamp examples`

Not built yet: `tstamp export`, the installer, other shells.

## Try it in one terminal

```bash
source /path/to/tstamp/shells/bash.sh
tstamp
```

Nothing is installed permanently. Closing the terminal removes it.

## Layout

- `bin/`    the `tstamp` command
- `lib/`    shared core (config, formats, clock, state)
- `shells/` shell integrations
- `docs/`   help, examples and the offline manual
- `tests/`  test scripts (`bash tests/run_all.sh` runs them all)
