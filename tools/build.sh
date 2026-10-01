#!/usr/bin/env bash
# Builds release packages into build/:
#   build/PixelHangman.love         runs anywhere LÖVE 11.5 is installed
#   build/PixelHangman-win64.zip    standalone Windows build (no install needed)
# Usage: tools/build.sh
# The Windows build downloads the official LÖVE 11.5 binaries once (cached in build/cache).
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=PixelHangman
LOVE_VERSION=11.5
OUT=build
CACHE="$OUT/cache"
mkdir -p "$OUT" "$CACHE"

# 1. .love file: a zip with main.lua at its root (game files only).
rm -f "$OUT/$NAME.love"
zip -9 -q -r "$OUT/$NAME.love" main.lua conf.lua src data assets -x "*.gitkeep"
echo "Built $OUT/$NAME.love"

# 2. Windows: love.exe + .love fused into one exe, next to LÖVE's DLLs.
WIN_ZIP="$CACHE/love-$LOVE_VERSION-win64.zip"
if [ ! -f "$WIN_ZIP" ]; then
    curl -sSL -o "$WIN_ZIP" "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-win64.zip"
fi
WORK="$OUT/win64"
rm -rf "$WORK" && mkdir -p "$WORK"
unzip -q -o "$WIN_ZIP" -d "$WORK/tmp"
SRC=$(dirname "$(find "$WORK/tmp" -name love.exe | head -1)")
cat "$SRC/love.exe" "$OUT/$NAME.love" > "$WORK/$NAME.exe"
cp "$SRC"/*.dll "$WORK/"
cp "$SRC/license.txt" "$WORK/LOVE-license.txt"
rm -rf "$WORK/tmp"
rm -f "$OUT/$NAME-win64.zip"
(cd "$WORK" && zip -9 -q -r "../$NAME-win64.zip" .)
echo "Built $OUT/$NAME-win64.zip"
