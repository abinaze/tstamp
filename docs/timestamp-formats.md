# Timestamp formats

A format is the style of the time shown in START and END lines.

| Number | Shows | Example |
|---|---|---|
| 1 | Hours and minutes | `19:42` |
| 2 | Hours, minutes, seconds | `19:42:01` |
| 3 | Date and time | `2026-10-29 19:42:01` |
| 4 (default) | Date, time, thousandths of a second | `2026-10-29 19:42:01.100` |
| 5 | Date, time and time zone | `2026-10-29 19:42:01 +0530` |

## Choosing one

```bash
tstamp set 2        # save as the default
tstamp 3            # this window only
tstamp-a 5          # all windows, and save it
tstamp format       # list them, with the current time as an example
```

## Making your own

Write a pattern with these pieces. Put it in quotes.

| Piece | Meaning | Piece | Meaning |
|---|---|---|---|
| `%Y` | Year (2026) | `%H` | Hour, 00 to 23 |
| `%m` | Month, 01 to 12 | `%M` | Minute |
| `%d` | Day | `%S` | Second |
| `%b` | Month name (Oct) | `%3N` | Thousandths of a second |
| `%a` | Weekday (Thu) | `%z` | Time zone (+0530) |

```bash
tstamp set "%d/%m/%Y %H:%M"      # 29/10/2026 19:42
tstamp set "%H:%M:%S.%3N"        # 19:42:01.100
```

A pattern must contain at least one `%`. tstamp checks it and tells you if it
is not valid. `%6N` gives millionths of a second.

The pieces in the table work in Git Bash, PowerShell and every other shell. Other
date codes (such as `%p` for AM or PM) work in bash but are not supported in
PowerShell yet, and show up there as typed.

## Order of choice

A window's own format (`tstamp 2`) wins over the saved default (`tstamp set`),
which wins over format 4.
