# Compatibility

This page lists only what automated tests have shown. Nothing is claimed beyond
that.

| Where | Status |
|---|---|
| Windows, Git Bash | Tested. All tests pass, and the installer was installed and removed on a clean machine. |
| Ubuntu, bash | Tested. All tests pass, including installing and removing the `.deb`. |
| macOS, bash 5 (from Homebrew) | Tested. All tests pass. |
| macOS built-in bash 3.2 | Not supported. The installer script runs, but tstamp itself needs bash 4.4 or newer. |
| Restart behaviour | Tested on Windows with a real restart (Git Bash and PowerShell). |
| WSL, other Linux | Not tested yet. |
| Windows Terminal, VS Code or other terminals running bash | Not tested yet. |
| Windows PowerShell 5.1 | Tested. START and END lines, exit codes, shared logs and the profile hook are tested in CI and were tried by hand on Windows 11. |
| PowerShell 7 | Not tested yet. |
| Command Prompt (CMD) | **Cannot be tracked automatically**, because CMD has no way to run code around each command. The `tstamp` commands and `tstamp run COMMAND` work there and are tested. |
| zsh (the Mac default), fish | Not supported yet. |

## What "tested" means

The tests start real bash windows, run commands, and check the START and END
lines, results, labels, logs, and the installers. They run on GitHub on Windows,
Ubuntu and macOS.

## Requirements

- **bash 4.4 or newer.** Check with `bash --version`. Git Bash qualifies.
- Windows needs Git for Windows, also for PowerShell and CMD, because most tstamp
  commands run through Git Bash.
- Only terminals that load tstamp can be tracked. Windows opened before tstamp was
  installed do not have it.
