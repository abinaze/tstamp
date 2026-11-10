# Quick start

You need tstamp [installed](installation.md) and a **new** terminal window
(Git Bash on Windows).

## 1. Turn it on

```bash
tstamp-a
```

tstamp now watches every terminal window that has it loaded, including windows
that are already open.

## 2. Run something

```bash
echo hello
```

You see:

```text
[T1][2026-10-29 19:42:01.100] START: echo hello
hello
[T1][2026-10-29 19:42:01.103] END: echo hello | EXIT=0 | DURATION=0.00s
```

(Your date and time will differ.)

## 3. See what happens when a command fails

```bash
ls /this-folder-does-not-exist
```

The END line shows a number other than 0 after `EXIT=`. That is how you spot
a failure.

## 4. Check the status

```bash
tstamp status
```

It shows whether tstamp is on, this window's label (`T1`), and the time style.

## 5. Turn it off

```bash
tstamp stop      # this window only
tstamp-a stop    # every window
```

## Good to know

- tstamp does not time the `tstamp` commands themselves.
- Tracking switches itself off when the computer restarts. Type `tstamp-a` again.
- To turn it on in just one window, type `tstamp` instead of `tstamp-a`.
- On Windows you can use Git Bash or PowerShell. In Command Prompt, time one
  command at a time with `tstamp run COMMAND`.
- Change the time style with `tstamp set 2`. See [timestamp formats](timestamp-formats.md).

Something not working? See [troubleshooting](troubleshooting.md).
