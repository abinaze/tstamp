# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- START and END lines with exit code and duration for every command in
  Git Bash: `tstamp` and `tstamp N`.
- Global tracking across terminals: `tstamp-a`, `tstamp stop` and
  `tstamp status`. Global tracking switches off after a reboot.
- Per-terminal session IDs (T1, T2, ...) and one log file per terminal.
- Five built-in timestamp formats and custom date format strings:
  `tstamp format`, `tstamp set` and `tstamp reset`.
- `tstamp export` merges session logs in time order.
- `tstamp hook add|remove` edits a marked block in `~/.bashrc` after
  making a backup.
- Offline help: `tstamp help`, `tstamp man`, `tstamp examples` and
  `tstamp version`.
- Windows installer (Inno Setup, per user, no administrator rights),
  built and smoke-tested by GitHub Actions.
- Automated test suite and a GitHub Actions workflow.
- MIT license and contributor documentation.

### Known limitations

- Only bash in Git Bash is tested. Other shells and operating systems
  are not supported yet.
- The reboot reset is simulated in tests but not yet tested with a real
  restart.
- The Windows installer is not code-signed.
