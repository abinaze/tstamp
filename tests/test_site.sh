#!/usr/bin/env bash
# Static checks for the website. They cannot render the page; they catch
# broken anchors, drift from the release file names and the install command,
# and anything that would break the strict Content-Security-Policy.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE="$ROOT/site"
HTML="$SITE/index.html"
CSS="$SITE/styles.css"
JS="$SITE/app.js"

pass=0
fail=0

check() { # description, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (expected '$2', got '$3')"
  fi
}

has() { # description, file, fixed text
  if grep -qF -- "$3" "$2"; then
    pass=$((pass + 1)); echo "ok   - $1"
  else
    fail=$((fail + 1)); echo "FAIL - $1 (missing: $3)"
  fi
}

hasnt() { # description, file, fixed text
  if grep -qF -- "$3" "$2"; then
    fail=$((fail + 1)); echo "FAIL - $1 (unexpected: $3)"
  else
    pass=$((pass + 1)); echo "ok   - $1"
  fi
}

# --- files ---
for f in index.html styles.css app.js favicon.svg robots.txt; do
  check "site/$f exists and is not empty" yes "$([ -s "$SITE/$f" ] && echo yes || echo no)"
done
check "site/.nojekyll exists" yes "$([ -e "$SITE/.nojekyll" ] && echo yes || echo no)"
check "site is small (under 200 KB)" yes "$([ "$(cat "$SITE"/* "$SITE"/.nojekyll 2>/dev/null | wc -c | tr -d ' ')" -lt 200000 ] && echo yes || echo no)"

# --- page basics ---
has "html declares a language" "$HTML" '<html lang="en">'
has "html has a viewport tag" "$HTML" 'name="viewport"'
has "html has a title" "$HTML" '<title>TStamp'
has "html has a description" "$HTML" 'name="description"'
has "html has a skip link" "$HTML" 'class="skip"'
check "exactly one h1" 1 "$(grep -c '<h1' "$HTML")"
has "html links the stylesheet" "$HTML" 'href="styles.css"'
has "html links the script" "$HTML" 'src="app.js"'

# --- strict Content-Security-Policy ---
has "CSP meta tag present" "$HTML" 'Content-Security-Policy'
has "CSP blocks everything by default" "$HTML" "default-src 'none'"
has "CSP only allows the GitHub API for requests" "$HTML" 'connect-src https://api.github.com'
check "no inline script blocks" 0 "$(grep -c '<script>' "$HTML")"
check "no inline style attributes" 0 "$(grep -c ' style="' "$HTML")"
check "no inline event handlers" 0 "$(grep -cE ' on[a-z]+=' "$HTML")"
check "no external scripts, styles or images" 0 "$(grep -cE '<(script|link|img)[^>]*(src|href)="https?://' "$HTML")"

# --- downloads match the release pipeline ---
for name in tstamp-windows-setup.exe tstamp.deb tstamp-unix.tar.gz get.sh SHA256SUMS.txt; do
  has "html links $name" "$HTML" "releases/latest/download/$name"
  has "RELEASING.md lists $name" "$ROOT/docs/RELEASING.md" "$name"
done
CMD='curl -fsSL https://github.com/abinaze/tstamp/releases/latest/download/get.sh | bash'
has "site shows the one-line install" "$HTML" "$CMD"
has "README shows the same one-line install" "$ROOT/README.md" "$CMD"
has "Debian command matches the README" "$ROOT/README.md" 'sudo apt install ./tstamp.deb'
has "uninstall command matches the manual" "$ROOT/docs/manual.txt" 'bash ~/.local/share/tstamp/uninstall.sh'

# --- anchors and ids ---
for a in $(grep -o 'href="#[A-Za-z0-9_-]*"' "$HTML" | sed 's/^href="#//; s/"$//' | sort -u); do
  [ -n "$a" ] || continue
  check "link #$a has exactly one target" 1 "$(grep -c "id=\"$a\"" "$HTML")"
done
for a in $(grep -o 'aria-controls="[A-Za-z0-9_-]*"' "$HTML" | sed 's/^aria-controls="//; s/"$//' | sort -u); do
  check "aria-controls $a has a target" 1 "$(grep -c "id=\"$a\"" "$HTML")"
done
for a in $(grep -o "getElementById('[A-Za-z0-9_-]*')" "$JS" | sed "s/^getElementById('//; s/')\$//" | sort -u); do
  check "app.js element $a exists in the page" 1 "$(grep -c "id=\"$a\"" "$HTML")"
done
for a in $(grep -o 'data-copy="[A-Za-z0-9_-]*"' "$HTML" | sed 's/^data-copy="//; s/"$//' | sort -u); do
  check "copy button target $a exists" 1 "$(grep -c "id=\"$a\"" "$HTML")"
done

# --- honesty about support ---
has "page says zsh is not supported" "$HTML" 'zsh (macOS default), fish'
has "page says PowerShell and CMD are not supported" "$HTML" 'PowerShell, CMD'
has "page admits what is not tested" "$HTML" 'Not tested yet'
has "page mentions the unsigned installer" "$HTML" 'not code-signed'
has "page warns that logs hold full commands" "$HTML" 'full text of every tracked command'

# --- privacy ---
check "no email addresses on the site" 0 "$(grep -cE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$HTML" "$JS" "$CSS" | awk -F: '{s+=$NF} END {print s+0}')"
check "app.js talks to exactly two hosts" 2 "$(grep -o 'https://[a-zA-Z.]*' "$JS" | sort -u | wc -l | tr -d ' ')"

# --- script and style hygiene ---
has   "app.js is strict" "$JS" "'use strict'"
hasnt "app.js never uses innerHTML" "$JS" 'innerHTML'
hasnt "app.js never uses eval" "$JS" 'eval('
hasnt "app.js never uses document.write" "$JS" 'document.write'
has   "css supports dark mode" "$CSS" 'prefers-color-scheme: dark'
has   "css respects reduced motion" "$CSS" 'prefers-reduced-motion'
has   "css keeps visible focus outlines" "$CSS" ':focus-visible'
has   "css has a mobile layout" "$CSS" 'max-width: 860px'

if command -v node >/dev/null 2>&1; then
  node --check "$JS" >/dev/null 2>&1
  check "app.js passes node --check" 0 "$?"
else
  echo "skip - node is not installed here; app.js was not syntax-checked"
fi

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
