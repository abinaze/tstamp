# Releasing TStamp

Releases are built by the **Release** workflow and always start as a draft.
Nothing becomes public until the maintainer presses **Publish release**.

## Files in every release

| File | For | Built on |
|---|---|---|
| `tstamp-windows-setup.exe` | Windows (Git Bash) | Windows runner, Inno Setup |
| `tstamp.deb` | Debian, Ubuntu | Ubuntu runner, `dpkg-deb` |
| `tstamp-unix.tar.gz` | Linux, macOS, WSL | Ubuntu runner |
| `get.sh` | One-line web install | copied from `installer/get.sh` |
| `SHA256SUMS.txt` | Checksums of the four files above | generated |

The names carry no version on purpose, so
`https://github.com/abinaze/tstamp/releases/latest/download/<file>` always
points at the newest published release. GitHub's "latest" ignores
pre-releases.

## Steps

1. Move the `Unreleased` entries in `CHANGELOG.md` under a new version
   heading with the date.
2. Set `VERSION` (for example `0.1.0`, or `0.1.0-rc1` for a pre-release) and
   commit it.
3. Run the **CI** workflow on `main` and wait for all three systems to pass.
4. Tag and push. The tag must be `v` followed by the contents of `VERSION`;
   the workflow refuses a mismatch.

   ```bash
   git tag -a v0.1.0 -m "TStamp 0.1.0"
   git push origin v0.1.0
   ```

5. Wait for the **Release** workflow. It runs the tests on three systems,
   builds every package, installs and uninstalls the Windows installer on a
   clean machine, then creates the draft with all files and checksums.
6. Open the Releases page and check the draft: title, notes, the five files
   and `SHA256SUMS.txt`. Download the file for your own system and try it.
7. Press **Publish release**. A version with a hyphen (`0.1.0-rc1`) is marked
   as a pre-release automatically.

## Dry run

Start **Release** by hand from the Actions tab. It builds and tests
everything but creates no release.

## Discarding a bad draft

Delete the draft on the Releases page, then delete the tag:

```bash
git push --delete origin v0.1.0
git tag -d v0.1.0
```
