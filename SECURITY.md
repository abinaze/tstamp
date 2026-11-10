# Security policy

## Supported versions

TStamp is pre-1.0. Only the latest release receives security fixes.

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Use GitHub's private reporting: open the **Security** tab of this
repository and choose **Report a vulnerability**. If that option is not
available, contact the maintainer through the profile at
https://github.com/abinaze and ask for a private channel before sharing
details.

Please include the TStamp version (`tstamp version`), your shell and
operating system, and the steps to reproduce the problem. I aim to reply
within a week.

## What counts as a vulnerability

- Code execution, privilege escalation or file damage triggered through
  TStamp's hook, installer, config file or log files.
- A way to make TStamp edit files outside its marked block in a startup
  file, or outside its own state folder.
- Anything that sends data off the machine. TStamp must never do that.

## Things to know by design

- Logs contain the full text of every tracked command, including any
  secret typed on a command line. They are stored unencrypted in
  `~/.tstamp/logs` and are readable by your own user account. Run
  `tstamp stop` in that terminal before typing secrets, and delete old logs.
- The Windows installer is not code-signed. Compare your download with
  `SHA256SUMS.txt` from the same release page.
- The hook adds one block, marked `# >>> tstamp >>>` and
  `# <<< tstamp <<<`, to `~/.bashrc` (and your PowerShell profile, if you choose) after making a backup.
