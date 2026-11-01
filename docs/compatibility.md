# Compatibility

This page lists only what automated tests have shown. Nothing is claimed beyond
that.

| Where | Status |
|---|---|
| Windows, Git Bash | Tested. All tests pass, and the installer was installed and removed on a clean machine. |
| Ubuntu, bash | Tested. All tests pass, including installing and removing the `.deb`. |
| macOS, bash 5 (from Homebrew) | Tested. All tests pass. |
| macOS built-in bash 3.2 | Not supported. The installer script runs, but tstamp itself needs bash 4.4 or newer. |
| Restart behaviour | Partly tested. The check works with simulated restarts. A real restart has not been tested yet. |
| WSL, other Linux | Not tested yet. |
| Windows Terminal, VS Code or other terminals running bash | Not tested yet. |
| zsh (the Mac default), fish | Not supported yet. |
| PowerShell, CMD | Not supported yet. |

## What "tested" means

The tests start real bash windows, run commands, and check the START and END
lines, results, labels, logs, and the installers. They run on GitHub on Windows,
Ubuntu and macOS.

## Requirements

- **bash 4.4 or newer.** Check with `bash --version`. Git Bash qualifies.
- Windows needs Git for Windows.
- Only terminals that load tstamp can be tracked. Windows opened before tstamp was
  installed do not have it.
