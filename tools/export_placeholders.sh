#!/usr/bin/env bash
# Writes the code-drawn placeholder art into assets/ as PNG files (dummy
# assets / templates for the real art). Existing files are NEVER overwritten
# unless --force is given, so real art is safe.
#   tools/export_placeholders.sh [--force]
# Needs: love 11.x and xvfb-run (or a display).
set -euo pipefail
cd "$(dirname "$0")/.."
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
SAVE_DIR="$HOME/.local/share/love/pixel_hangman"
rm -rf "${SAVE_DIR:?}/export"
if [ -n "${DISPLAY:-}" ]; then
    love . --export-placeholders >/dev/null 2>&1 || true
else
    xvfb-run -a love . --export-placeholders >/dev/null 2>&1 || true
fi
SRC="$SAVE_DIR/export/assets"
[ -d "$SRC" ] || { echo "Export failed (nothing in $SRC)"; exit 1; }
cd "$SRC"
find . -type f -name "*.png" | sort | while read -r f; do
    dest="$OLDPWD/assets/${f#./}"
    if [ -f "$dest" ] && [ $FORCE -eq 0 ]; then
        echo "kept     assets/${f#./} (already exists)"
    else
        mkdir -p "$(dirname "$dest")"
        cp "$f" "$dest"
        echo "written  assets/${f#./}"
    fi
done
