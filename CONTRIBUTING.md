# Contributing to TStamp

Thanks for helping. TStamp is a small, local-first tool, and the aim is to
keep it that way: no network access, no telemetry and no background service.

## Set up

TStamp is plain bash. You need bash 4.4 or newer and Git. On Windows, use
Git for Windows (Git Bash).

```bash
git clone https://github.com/abinaze/tstamp.git
cd tstamp
bash tests/run_all.sh
```

Every test file should print `PASS`. The tests use temporary folders and
never touch your real `~/.tstamp` or `~/.bashrc`.

## Ground rules

- Files that are loaded into interactive shells (`shells/*.sh`, `lib/*.sh`)
  must not use `set -e` or `set -u`, and must not leak variables or
  functions with generic names. Internal names start with `tstamp_` or
  `__tstamp_`.
- A change comes with a test. Tests run real shells and check behavior; a
  test that only checks that a file exists is not enough.
- Update the docs when behavior changes: `docs/manual.txt`,
  `docs/help.txt`, the README and `CHANGELOG.md`.
- Do not claim support for a shell or operating system without a passing
  test on it. The compatibility table in the manual says what is tested.
- Never change command output, exit codes, pipelines or the working
  directory of the commands a user runs.
- Write commit messages as `type(scope): summary`, where type is one of
  `feat`, `fix`, `docs`, `test`, `build`, `ci` or `chore`. Keep commits
  small.

## Adding a shell integration

A new integration (for example Zsh or Fish) must:

1. Record a START and an END line with exit code and duration.
2. Use the same state folder and log format described in
   `docs/ARCHITECTURE.md`, so `tstamp export` works across shells.
3. Follow the global flag at every prompt and give each terminal its own
   session ID.
4. Ship tests that drive a real interactive session of that shell.
5. Add a row to the compatibility table in `docs/manual.txt`, marked
   according to what the tests prove.

If your shell reports process IDs that bash cannot check (as PowerShell does), write
a `kind` file next to `pid` in its session folder, so bash never reclaims the
label. See `shells/powershell.ps1`.

## Pull requests

Fill in the pull request template and make sure `bash tests/run_all.sh`
passes. GitHub Actions runs the same tests on a clean Windows machine.

## Bugs and security

Use the issue templates for bugs and feature requests. Report security
problems privately, as described in `SECURITY.md`.

## License

By contributing you agree that your work is released under the MIT license
in `LICENSE`.
