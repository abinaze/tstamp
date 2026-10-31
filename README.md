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

Early development. Bash is the only supported shell. It passes the full test
suite in CI on Windows (Git Bash), Ubuntu and macOS (current Homebrew bash).
Zsh, Fish, PowerShell and CMD are not supported yet.

Working today:

- Per-terminal tracking: `tstamp`, `tstamp 2`, `tstamp "%H:%M"`
- Global tracking across terminals: `tstamp-a`, `tstamp stop`
- Formats: `tstamp format`, `tstamp set`, `tstamp reset`
- Offline docs: `tstamp help`, `tstamp man`, `tstamp examples`
- Merged report of all sessions: `tstamp export`
- Windows installer (Git Bash), built and smoke-tested by GitHub Actions

Not built yet: other shells (Zsh, Fish, PowerShell, CMD) and Linux or macOS testing.

## Install on Windows

1. Install [Git for Windows](https://git-scm.com/download/win) if you do not
   have it. TStamp runs inside Git Bash.
2. Download the `tstamp-setup` file from the
   [latest release](https://github.com/abinaze/tstamp/releases/latest) and run it.
3. Open a new Git Bash window and type `tstamp-a`.

The installer is not code-signed, so Windows SmartScreen may warn you. Choose
More info, then Run anyway. Compare the download with `SHA256SUMS.txt` if you
want to check it. Uninstall from Windows Settings, Apps.

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
- `installer/` Windows installer script and staging
- `tests/`  test scripts (`bash tests/run_all.sh` runs them all)

## Documentation

- `tstamp man` shows the full offline manual ([docs/manual.txt](docs/manual.txt))
- [Architecture](docs/ARCHITECTURE.md): how tracking, state and the installer work
- [Changelog](CHANGELOG.md)

## Contributing

Bug reports and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md)
first, and see the [Code of Conduct](CODE_OF_CONDUCT.md). Security issues go
through [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
