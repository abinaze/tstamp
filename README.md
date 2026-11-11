<p align="center">
  <img src="assets/brand/png/tstamp-banner.png" alt="tstamp: timestamp every command in your terminal" width="640">
</p>

<p align="center">
  <a href="https://github.com/abinaze/tstamp/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/abinaze/tstamp/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-14181D"></a>
  <img alt="Platforms: Windows, Linux, macOS" src="https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS-14181D">
  <img alt="Shell: bash" src="https://img.shields.io/badge/shell-bash-14181D">
</p>

<p align="center">
  <a href="#install">Install</a> &middot;
  <a href="docs/quick-start.md">Quick start</a> &middot;
  <a href="docs/commands.md">Commands</a> &middot;
  <a href="docs/README.md">Documentation</a> &middot;
  <a href="CHANGELOG.md">Changelog</a>
</p>

---

**tstamp** shows you when every command in your terminal started, when it
ended, whether it worked, and how long it took. It is free, open source, and
runs only on your computer.

```text
[T1][2026-10-29 19:42:01.100] START: npm run build
Build failed.
[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s
```

`EXIT=0` means the command worked. Any other number means it failed. Your
command and its output are not changed.

## Why tstamp

| | |
|---|---|
| **Answers "when?" and "how long?"** | Every command gets a start time, an end time and a duration. |
| **Tells windows apart** | Each terminal window has its own label (`T1`, `T2`, ...). |
| **One switch for everything** | `tstamp-a` turns it on in every window, including windows already open. |
| **One timeline** | `tstamp export` merges all windows into a single list in time order. |
| **Your time style** | Five built-in styles, or write your own. |
| **Private** | No internet, no account, no tracking, no background program. |

## Install

Choose your computer. You only need one.

| Your computer | Package | How |
|---|---|---|
| **Windows** | `tstamp-windows-setup.exe` | Download from the [Releases page](https://github.com/abinaze/tstamp/releases/latest) and open it |
| **Ubuntu, Debian** | `tstamp.deb` | `sudo apt install ./tstamp.deb`, then `tstamp hook add` |
| **Other Linux, Mac, WSL** | `tstamp-unix.tar.gz` | Paste the command below |

```bash
curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash
```


Windows needs [Git for Windows](https://git-scm.com/download/win) (the installer
checks). On a Mac, use bash 5: `brew install bash`, then type `bash`. Step-by-step
help, including uninstalling, is in [Installation](docs/installation.md).

## Quick start

```bash
tstamp-a          # turn it on in every terminal
echo hello        # run anything: you now see START and END lines
tstamp status     # see what is on
tstamp stop       # turn it off in this terminal
tstamp-a stop     # turn it off in every terminal
```

Open a **new** terminal first (Git Bash or PowerShell on Windows). Tracking switches itself off when the computer
restarts: type `tstamp-a` again. The full walk-through is in the
[Quick start](docs/quick-start.md).

## Commands

| Command | What it does |
|---|---|
| `tstamp-a` | Turn on in all terminals |
| `tstamp` | Turn on in this terminal only |
| `tstamp stop` | Turn off in this terminal only |
| `tstamp-a stop` | Turn off in every terminal |
| `tstamp status` | Show what is on |
| `tstamp format` / `tstamp set 2` | See and choose the time style |
| `tstamp export` | Merge all windows into one timeline |
| `tstamp help` / `tstamp man` | Short help / full offline manual |

Every command is explained in [Commands](docs/commands.md).

## Documentation

| Page | Contents |
|---|---|
| [Introduction](docs/introduction.md) | What tstamp does, in plain words |
| [Installation](docs/installation.md) | Install and uninstall on each system |
| [Quick start](docs/quick-start.md) | Your first five minutes |
| [Commands](docs/commands.md) | Every command |
| [Timestamp formats](docs/timestamp-formats.md) | Time styles and your own patterns |
| [Examples](docs/examples.md) | Real situations and what to type |
| [Compatibility](docs/compatibility.md) | What is tested, and what is not |
| [Troubleshooting](docs/troubleshooting.md) | Problems and fixes |
| [Contributing](docs/contributing.md) | Report a problem or help build tstamp |
| [Changelog](docs/changelog.md) | Version history |

## Compatibility

| Where | Status |
|---|---|
| Windows (Git Bash) | Tested in CI, including the installer |
| Ubuntu (bash) | Tested in CI, including the `.deb` |
| macOS (bash 5) | Tested in CI |
| Windows PowerShell 5.1 | Tested in CI and by hand |
| CMD | The window is not tracked on its own. Typing `tstamp` starts a tracked session that runs each line in cmd.exe (experimental, installs nothing). `tstamp run COMMAND` times one command. The optional Clink add-on tracks the real window |
| zsh, fish | Not supported yet |
| WSL, Windows Terminal, IDE terminals | Not tested yet |

Details and requirements: [Compatibility](docs/compatibility.md).

## Privacy and safety

tstamp never connects to the internet. It saves a log of your commands in
`~/.tstamp/logs`. **A password typed inside a command is saved in that log.**
Type `tstamp stop` in that terminal before doing that, and delete old logs. Security problems
should be reported privately: see [SECURITY.md](SECURITY.md).

## Contributing

Bug reports, ideas, documentation fixes and testing on other systems are all
welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). To run the tests: `bash tests/run_all.sh`.

## License

Free to use, change and share under the MIT license. See [LICENSE](LICENSE).
