# Troubleshooting

## "tstamp: command not found"

You are in a window that does not have tstamp. Open a **new** terminal. If it
still fails, run `tstamp hook add`, or on Linux and Mac make sure `~/.local/bin`
is in your PATH.

## I typed `tstamp-a` but one window shows nothing

Only windows that loaded tstamp follow it. A window opened before the install
did not. Close it and open a new one.

## "tstamp 2 needs the shell hook loaded in this terminal"

The command ran outside a tstamp window. Open a new terminal, or type
`source shells/bash.sh` if you are running from the repository.

## "another DEBUG trap is already set"

Another tool in your terminal already uses the hook tstamp needs. tstamp will
not replace it, so it stays off in that window. Remove the other tool, or use a
different terminal.

## "bash 4.4 or newer is required"

Your bash is too old. Check with `bash --version`. On a Mac, run
`brew install bash` and start it by typing `bash`.

## One window still tracks after I stopped it in another window

`tstamp stop` only stops the window where you type it. To stop every window,
type `tstamp-a stop`.

## A window stays off after I typed `tstamp stop` in it

This is intended: it stays off while global tracking is on. Type `tstamp-a` to
turn every window back on, or `tstamp` to turn on this window alone.

## It stopped working after a restart

This is intended. Type `tstamp-a` again.

## `tstamp export` says "no matching logs"

Nothing was tracked yet, or the window names you gave (like `T3`) have no logs.
Run `tstamp status` to see the live windows.

## Windows warns about an unknown publisher

The installer is not code-signed. Choose **More info**, then **Run anyway**.

## Windows says Git Bash was not found

Install Git for Windows from https://git-scm.com/download/win, then run the
tstamp installer again.

## The time looks wrong

tstamp uses your computer's clock and time zone. Use format 5 to show the time
zone: `tstamp set 5`.

## I want to remove everything

Follow [installation](installation.md) to uninstall, then delete the folder
`~/.tstamp`. Backups of your startup file stay next to it and can be deleted.

## A new Git Bash window does not have tstamp

Git Bash reads `~/.bash_profile` first. Make sure that file loads
`~/.bashrc`, where tstamp's block lives, for example with this line:

```bash
[ -f ~/.bashrc ] && . ~/.bashrc
```

## PowerShell says running scripts is disabled

Windows blocks script files by default. Allow your own scripts, for your user
only, by running this once in PowerShell:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Then open a new PowerShell window.

## PowerShell is slow to start, or typed text appears late

Windows PowerShell 5.1 comes with PSReadLine 2.0.0. On one test computer the
first prompt froze for about ten seconds, with and without tstamp, and the delay
went away after installing a newer PSReadLine. Check your version:

```powershell
(Get-Module PSReadLine).Version
```

If you want a newer one, this installs it for your user only. It may first ask
to install the NuGet package provider:

```powershell
Install-Module PSReadLine -Scope CurrentUser -Force
```

Then open a new PowerShell window. tstamp ignores the old history lines that
PSReadLine replays at start, but an old PSReadLine can still be slow on some
computers.

## Nothing is timed in Command Prompt

That is expected. CMD has no way to run code around each command, so it is only
tracked in a window where the optional Clink add-on is loaded (see
[installation](installation.md)). A new Command Prompt window does not have
Clink unless you set Clink to start with every window. Otherwise use
`tstamp run COMMAND` to time one command.

## "tstamp" is not recognized in Command Prompt

Open a **new** Command Prompt window after installing, and keep the box
**CMD and PowerShell commands** ticked in the installer. Until then you can run
`tstamp.cmd` from the `bin` folder of the install.

## Still stuck?

Open an issue and include the output of `tstamp version` and `tstamp status`:
https://github.com/abinaze/tstamp/issues. Remove any password first.
