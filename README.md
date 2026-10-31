<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/svg/tstamp-horizontal-light.svg">
    <img alt="tstamp" src="assets/brand/svg/tstamp-horizontal-dark.svg" width="300">
  </picture>
</p>

<p align="center"><strong>See exactly when every command in your terminal started, ended and how long it took.</strong></p>

<p align="center">Free and open source &middot; Runs only on your computer &middot; No account, no tracking</p>

---

## What is tstamp?

The terminal is the text window where you type commands. It does not tell you
*when* you typed something, *how long* it took, or *whether it worked*.

**tstamp** adds that information for you. Around every command it prints one
line when the command starts and one when it ends, with the time, the result
and the duration:

```text
[T1][2026-10-29 19:42:01.100] START: npm run build
Build failed.
[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s
```

`EXIT=0` means the command worked. Any other number means it failed.

## Why use it?

- **Find out what went wrong, and when.** Every error has a time stamp.
- **Many terminals, no confusion.** Each window gets its own label (`T1`, `T2`, ...).
- **Keep a record.** One command combines all your windows into a single timeline.
- **Private by design.** It never connects to the internet. Everything stays on your computer.
- **Stays out of the way.** Your commands, their output and their results are not changed.

## Install

Choose the one for your computer. You only need one.

| Your computer | What to download | How |
|---|---|---|
| **Windows** | `tstamp-windows-setup.exe` | Download from the [Releases page](https://github.com/abinaze/tstamp/releases/latest) and open it |
| **Ubuntu or Debian** | `tstamp.deb` | `sudo apt install ./tstamp.deb`, then `tstamp hook add` |
| **Other Linux, Mac or WSL** | `tstamp-unix.tar.gz` | Paste the command below into your terminal |

```bash
curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash
```

> **Not released yet.** The download links above start working when the first
> version is published. Until then you can try tstamp from this repository:
> `source shells/bash.sh`

**Good to know**

- On Windows, tstamp runs inside **Git Bash**, which comes with [Git for Windows](https://git-scm.com/download/win). The installer tells you if it is missing.
- Windows may warn you about the installer ("unknown publisher"), because it is not code-signed. Choose **More info**, then **Run anyway**.
- tstamp works with **bash** only. On a Mac, install a newer bash with `brew install bash` and start it by typing `bash`.

## Your first minute

1. Open a **new** terminal (Git Bash on Windows).
2. Type `tstamp-a` and press Enter. This switches tstamp on in every window.
3. Run any command, for example `echo hello`. You will see the START and END lines.
4. Type `tstamp stop` to switch it off.

Tracking switches itself off when the computer restarts. Type `tstamp-a` again to turn it back on.

## The commands you need

| Type this | What happens |
|---|---|
| `tstamp-a` | Turn on in all terminals |
| `tstamp` | Turn on in this terminal only |
| `tstamp stop` | Turn off |
| `tstamp status` | Show what is on |
| `tstamp format` | Show the time styles you can choose |
| `tstamp set 2` | Choose a time style (1 to 5, or your own) |
| `tstamp export` | Combine all windows into one timeline |
| `tstamp help` | Short help; `tstamp man` shows the full manual |

## Privacy

tstamp saves a log of the commands you run in `~/.tstamp/logs`. **If you type a
password directly into a command, it is saved in that log.** Type `tstamp stop`
before doing that, and delete old logs you no longer need. The logs are never
sent anywhere.

## Works on

Tested automatically on Windows (Git Bash), Ubuntu and macOS (with bash 5). zsh,
fish, PowerShell and CMD are not supported yet. Details are in the
[manual](docs/manual.txt).

## Learn more

- [Manual](docs/manual.txt): every command, also available offline with `tstamp man`
- [How it works](docs/ARCHITECTURE.md): for the curious
- [Changelog](CHANGELOG.md): what changed in each version
- [Releasing](docs/RELEASING.md): how new versions are published

## Contributing

Bug reports and improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md)
first, and see the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go
through [SECURITY.md](SECURITY.md). To run the tests: `bash tests/run_all.sh`.

## License

Free to use, change and share under the MIT license. See [LICENSE](LICENSE).
