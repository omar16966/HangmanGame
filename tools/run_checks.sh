#!/usr/bin/env bash
# Headless smoke test: starts the game at several window sizes, saves a
# screenshot of each and checks it is pixel-perfect.
# Needs: love (11.x), xvfb-run, python3 + Pillow.
#   tools/run_checks.sh [state] [output_dir]
set -u
cd "$(dirname "$0")/.."
STATE="${1:-diagnostics}"
OUT="${2:-/tmp/hangman_checks}"
SAVE_DIR="$HOME/.local/share/love/pixel_hangman"
mkdir -p "$OUT"
status=0
for size in 320x180 640x360 960x540 1280x720 1920x1080 1366x768 1000x700; do
    name="check_${STATE}_${size}.png"
    log="$OUT/${STATE}_${size}.log"
    timeout 30 xvfb-run -a -s "-screen 0 2560x1440x24" \
        love . --size "$size" --state "$STATE" --screenshot "$name" \
        --screenshot-after 1 --quit-after 1.5 >"$log" 2>&1
    if grep -E "ERROR|Error:|stack traceback" "$log" >/dev/null; then
        echo "FAIL $size: errors in log ($log)"
        status=1
    fi
    if [ -f "$SAVE_DIR/$name" ]; then
        mv "$SAVE_DIR/$name" "$OUT/$name"
        python3 tools/verify_pixels.py "$OUT/$name" || status=1
    else
        echo "FAIL $size: no screenshot"
        status=1
    fi
done
exit $status
