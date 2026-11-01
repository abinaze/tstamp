# Examples

## See which step of a build failed

```bash
tstamp-a
npm install
npm run build
```

Look at the END lines. The first one with `EXIT=` other than 0 is the step that
failed, and the time shows when.

## Find out how long something really takes

Run it once with tstamp on. The `DURATION=` on the END line is the answer.

## Work in several windows

Open two windows and type `tstamp-a` once. Windows are labelled `T1` and `T2`, so
you can tell which window an error came from.

## Send a clear record to someone helping you

```bash
tstamp export -o report.txt
```

Open `report.txt`, remove anything private such as passwords, and share it.

## Compare two windows only

```bash
tstamp export T1 T2
```

## Show only the time of day

```bash
tstamp set 2
```

## Use your own style

```bash
tstamp set "%d/%m/%Y %H:%M:%S"
```

## Keep a password out of the log

```bash
tstamp stop
# type the command that needs the password
tstamp-a
```

## Start fresh

```bash
tstamp reset
rm -rf ~/.tstamp/logs
```

More are built into the program: type `tstamp examples`.
