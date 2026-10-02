#!/usr/bin/env bash
# Runs every automated check:
#   1. pure-Lua unit tests (luajit)
#   2. shaping/bidi comparison against HarfBuzz and python-bidi
#   3. headless screenshots at 7 window sizes + pixel-perfect verification
# Requirements: luajit, love 11.x, xvfb-run, python3 with Pillow,
#               uharfbuzz, python-bidi, fontTools
set -u
cd "$(dirname "$0")/.."
status=0
echo "== Unit tests";        luajit tests/unit_tests.lua || status=1
echo "== Gameplay tests"
log=$(mktemp); luajit tests/gameplay_tests.lua >"$log" 2>&1 || status=1
grep -v "^\[" "$log"; rm -f "$log"   # hide the expected validation warnings
echo "== UI tests"
log=$(mktemp); luajit tests/ui_tests.lua >"$log" 2>&1 || status=1
grep -v "^\[" "$log"; rm -f "$log"
echo "== Save and persistence tests"
log=$(mktemp); luajit tests/save_tests.lua >"$log" 2>&1 || status=1
grep -vE "^\[" "$log"; rm -f "$log"   # hide the expected warnings about damaged test files
echo "== Reference tests";   python3 tests/compare_reference.py || status=1
echo "== Display checks"
for state in main_menu gameplay category settings scores statistics name; do
    tools/run_checks.sh $state "${1:-/tmp/hangman_checks}" 2>&1 \
        | grep -E "FAIL|non-uniform virtual pixels: [1-9]|letterbox pixels: [1-9]" && { echo "problem in state $state"; status=1; }
done
[ $status -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $status
