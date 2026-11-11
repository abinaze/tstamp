# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Command Prompt session (experimental): typing `tstamp` in Command Prompt starts
  a tracked session in the same window. Each line runs in `cmd.exe` with START
  and END lines, exit code, duration and the shared logs. It uses only Windows
  PowerShell 5.1 and `cmd.exe` and changes nothing on the computer.

## [0.1.0] - 2026-11-11

### Added

- START and END lines with exit code and duration for every command in
  bash: `tstamp` and `tstamp N`.
- Global tracking across terminals: `tstamp-a`, `tstamp-a stop` and
  `tstamp status`. Global tracking switches off after a reboot.
- `tstamp stop` stops only the terminal where it is typed; `tstamp-a stop`
  stops every terminal, including those turned on by hand.
- Optional Command Prompt tracking through the third-party Clink add-on
  (`shells/clink/tstamp.lua`), with the same flag, session labels, logs and
  stop rules as the other shells. Tried by hand with Clink 1.9.36; CI tests its
  logic with a fake Clink.
- PowerShell ignores the saved history that PSReadLine replays when it starts,
  so a new window no longer prints old START lines and is not slow to start.
- Per-terminal session IDs (T1, T2, ...) and one log file per terminal.
- Five built-in timestamp formats and custom date format strings:
  `tstamp format`, `tstamp set` and `tstamp reset`.
- `tstamp export` merges session logs in time order.
- `tstamp hook add|remove` edits a marked block in a bash startup file
  after making a backup.
- Offline help: `tstamp help`, `tstamp man`, `tstamp examples` and
  `tstamp version`.
- Windows installer (Inno Setup, per user, no administrator rights),
  built and smoke-tested by GitHub Actions.
- Automated test suite, run in CI on Ubuntu, macOS (current Homebrew
  bash) and Windows (Git Bash).
- MIT license and contributor documentation.
- PowerShell support (Windows PowerShell 5.1): START and END lines, state shared
  with Git Bash, and `tstamp hook add --powershell`.
- `tstamp run COMMAND` times one command from any shell, and `tstamp.cmd` and
  `tstamp-a.cmd` launchers let Command Prompt use the tstamp commands.
- The Windows installer can add the PowerShell profile block and a user PATH
  entry, and removes both on uninstall.
- Separate packages per system: Windows installer, Debian package, and a
  Unix tarball with install and uninstall scripts for Linux, macOS and WSL.
- Web installer (`get.sh`) that verifies a checksum before installing.
- Project website in `site/`. It detects the visitor's system and shows only
  that system's install steps, loads nothing from third parties and enforces a
  strict Content-Security-Policy.

### Fixed

- Millisecond timestamps in `tstamp format` and `tstamp set` on macOS.
- Reboot detection on macOS.

### Known limitations

- Supported: bash and Windows PowerShell 5.1. CMD cannot be tracked automatically. Zsh and Fish are not
  supported yet.
- macOS needs a current bash (for example from Homebrew); the built-in
  bash 3.2 is too old.
- The reboot reset is checked through simulated boot markers, but not yet
  with a real restart.
- The Windows installer is not code-signed.
