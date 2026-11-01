# Installation

Pick **one** section for your computer. If you are not sure which, look at the
first line of each section.

> tstamp has not been released yet. The download links work after the first
> version is published. Until then, see "Try it without installing" below.

## Windows

You need **Git for Windows**, because tstamp runs in Git Bash. Get it from
https://git-scm.com/download/win. The tstamp installer tells you if it is missing.

1. Download `tstamp-windows-setup.exe` from the
   [Releases page](https://github.com/abinaze/tstamp/releases/latest).
2. Open the file. You do not need administrator rights.
3. Windows may say "unknown publisher", because the installer is not
   code-signed. Choose **More info**, then **Run anyway**.
4. Leave **Load tstamp in every new Git Bash window** ticked. The installer
   makes a backup of your `~/.bashrc` file first.
5. Open a new Git Bash window.

**Uninstall:** Windows Settings, then Apps, find tstamp, then Uninstall. It asks
whether to also delete your saved logs. The default answer is No.

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
