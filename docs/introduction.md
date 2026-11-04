# Introduction

## What is a terminal?

A terminal is a window where you control your computer by typing commands.
Programmers, students and system administrators use it every day. On Windows
this guide uses **Git Bash** (a terminal that comes with Git for Windows) and
**PowerShell**.

## What does tstamp do?

A terminal does not show **when** you ran a command, **how long** it took, or
**whether it worked**. tstamp adds that. Around every command it prints two
lines:

```text
[T1][2026-10-29 19:42:01.100] START: npm run build
Build failed.
[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s
```

| Part | Meaning |
|---|---|
| `T1` | The label of this terminal window. A second window is `T2`, and so on. |
| `2026-10-29 19:42:01.100` | The date and time, down to a thousandth of a second. |
| `START` / `END` | The command began / the command finished. |
| `EXIT=1` | The result. `0` means it worked. Any other number means it failed. |
| `DURATION=3.10s` | How long it took. |

Your command and its output are not changed.

## Who is it for?

Anyone who wants a clear record of what happened in their terminal: finding
which step of a build failed, how long a task really takes, or what happened
first when several windows are open.

## What tstamp is not

- It does not need internet, an account or a background program.
- It does not send anything anywhere. Everything stays on your computer.
- It is not a security tool. See "Privacy" in the [commands](commands.md) page.

## Next

[Install tstamp](installation.md), then follow the [quick start](quick-start.md).
