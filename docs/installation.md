# Installation

Pick **one** section for your computer. If you are not sure which, look at the
first line of each section.


## Windows

You need **Git for Windows**, because tstamp runs in Git Bash. Get it from
https://git-scm.com/download/win. The tstamp installer tells you if it is missing.

1. Download `tstamp-windows-setup.exe` from the
   [Releases page](https://github.com/abinaze/tstamp/releases/latest).
2. Open the file. You do not need administrator rights.
3. Windows may say "unknown publisher", because the installer is not
   code-signed. Choose **More info**, then **Run anyway**.
4. Keep the three boxes ticked: **Git Bash**, **PowerShell**, and **CMD and
   PowerShell commands**. The installer saves a backup of your `~/.bashrc` and
   of your PowerShell profile first. The last box adds tstamp to your user PATH
   only.
5. Open a new Git Bash or PowerShell window and type `tstamp-a`. In Command
   Prompt, type `tstamp` to start a tracked session (see below), or time one
   command at a time with `tstamp run COMMAND`.

If PowerShell says that running scripts is disabled, run this once in PowerShell:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Uninstall:** Windows Settings, then Apps, find tstamp, then Uninstall. It asks
whether to also delete your saved logs. The default answer is No.

### Command Prompt: the tstamp session (experimental)

Type `tstamp` in Command Prompt. It starts a tracked session in the same window.
Each line you type is run by `cmd.exe` and gets START and END lines, an exit
code and a duration, in the same logs as the other shells. Type `exit` to go
back to your normal prompt.

It uses only Windows PowerShell 5.1 and `cmd.exe`, which Windows already has.
It installs nothing and changes no setting or registry entry, and it lasts only
as long as the session.

Inside it, `tstamp stop`, `tstamp-a stop` and `tstamp 2` work as in the other
shells, `cd` and `set` carry over from line to line, and Ctrl+C stops the running
command and keeps the session.

Good to know:

- It is a separate session, not your original window. Changes made with `cd` and
  `set` do not carry back out when you type `exit`.
- Each command carries about 0.1 second of overhead for starting `cmd.exe`, and
  the first one about half a second.
- Tab completes the PowerShell way, and the colours are PowerShell's.
- A line with an odd number of quote marks, such as `echo it's`, waits for more
  input. Finish the quote, or press Ctrl+C.
- `doskey` macros and the `pushd` stack are not kept between lines.

### Command Prompt with Clink (optional)

The session above is separate from your normal window. To track the real Command
Prompt window itself, something has to attach to it, because Command Prompt
cannot run code around each command. [Clink](https://github.com/chrisant996/clink)
is a free, third-party add-on that does that, and tstamp ships a script for it.
This is optional, and tstamp works without it.

It was tried by hand with Clink 1.9.36 on Windows 11. CI tests the script's
logic with a fake Clink, not the real one. Only Command Prompt windows where
Clink is loaded are tracked.

1. Install Clink yourself from its
   [Releases page](https://github.com/chrisant996/clink/releases) (the setup
   file, or `winget install clink`).
2. In a Clink window, type `clink info` and note the folder on the **state** line.
3. Copy the script there. Replace `STATE` with that folder:

   ```bat
   copy "%LOCALAPPDATA%\Programs\TStamp\shells\clink\tstamp.lua" "STATE"
   ```

4. Type this once, so tstamp can read exit codes:

   ```bat
   clink set cmd.get_errorlevel true
   ```

5. Then type `tstamp-a`. Every command in that window now gets START and END
   lines, and `tstamp stop`, `tstamp-a stop` and `tstamp 2` work as in the
   other shells.

To load Clink in every new Command Prompt window, type `clink autorun install`.
It adds a per-user Windows registry entry, and `clink autorun uninstall`
removes it. Without it, start Clink in a window with `clink inject`.

Good to know:

- The first tracked command in each window can take about a second, because
  tstamp asks Windows for the exact time and the boot time once.
- tstamp sets `%ERRORLEVEL%` to 0 before each command, so the exit code shown
  is the command's own. Your history keeps what you typed. If a command
  misbehaves, type `set TSTAMP_CLINK_NOWRAP=1` in that window.
- Two Command Prompt windows opened in the same instant could pick the same
  session label. This is rare.
- `tstamp status` shows the global state only.

## Ubuntu and Debian

1. Download `tstamp.deb` from the Releases page.
2. In a terminal, run: `sudo apt install ./tstamp.deb`
3. Run once: `tstamp hook add` (it asks before changing anything)
4. Open a new terminal.

**Uninstall:** `tstamp hook remove`, then `sudo apt remove tstamp`.

## Other Linux, Mac and WSL

Paste this into a terminal. It needs no `sudo`.

```bash
curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash
```

It downloads the package, checks that the download is not damaged, and installs
into your own folder (`~/.local`). It changes no startup file unless you add
`-s -- --hook` after `bash`. Otherwise run `tstamp hook add` yourself later.

**Mac:** the built-in terminal uses zsh, which tstamp does not support yet. Run
`brew install bash`, then type `bash` to start a bash window before you install.

**Uninstall:** `bash ~/.local/share/tstamp/uninstall.sh`

## Try it without installing

If you downloaded or cloned the repository, in one terminal run:

```bash
source shells/bash.sh
```

Nothing is installed. Closing the window removes it.

## Check your download

Each release has `SHA256SUMS.txt`. Compare your file with the matching line.
A match means the file is not damaged. It does not protect you if a release
itself were replaced.

## What the installers change on your computer

- They add one marked block to your bash startup file (`~/.bashrc`, or
  `~/.bash_profile` on a Mac), after saving a backup named like
  `.bashrc.tstamp-backup-DATE-TIME`.
- Removing tstamp takes out exactly that block.
- tstamp keeps its settings and logs in `~/.tstamp`.

Next: the [quick start](quick-start.md).
