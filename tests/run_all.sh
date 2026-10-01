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
echo "== Reference tests";   python3 tests/compare_reference.py || status=1
echo "== Display checks";    tools/run_checks.sh diagnostics "${1:-/tmp/hangman_checks}" | grep -E "FAIL|non-uniform virtual pixels: [1-9]|letterbox pixels: [1-9]" && status=1
[ $status -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $status
