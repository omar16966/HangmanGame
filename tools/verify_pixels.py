#!/usr/bin/env python3
"""Checks that a screenshot of the game is pixel-perfect.

Usage: verify_pixels.py screenshot.png [virtual_width virtual_height]

Computes the same scale/offset as src/graphics/renderer.lua and verifies that
every virtual pixel became a uniform block of scale x scale window
pixels, and that the letterbox bars are plain black.
"""
import math
import sys

from PIL import Image

VW, VH = 640, 360  # must match Config.virtualWidth / virtualHeight


def main():
    global VW, VH
    path = sys.argv[1]
    if len(sys.argv) >= 4:
        VW, VH = int(sys.argv[2]), int(sys.argv[3])
    img = Image.open(path).convert("RGB")
    w, h = img.size
    fit = min(w / VW, h / VH)
    scale = math.floor(fit) if fit >= 1 else fit
    ox = math.floor((w - VW * scale) / 2)
    oy = math.floor((h - VH * scale) / 2)
    px = img.load()
    print(f"{path}: window {w}x{h} scale {scale} offset {ox},{oy}")

    if scale != int(scale):
        print("  non-integer scale: block test skipped")
        return 0
    scale = int(scale)

    bad_blocks = 0
    for vy in range(VH):
        for vx in range(VW):
            x0, y0 = ox + vx * scale, oy + vy * scale
            c = px[x0, y0]
            for dy in range(scale):
                for dx in range(scale):
                    if px[x0 + dx, y0 + dy] != c:
                        bad_blocks += 1
                        break
                else:
                    continue
                break

    bad_bars = 0
    for y in range(h):
        for x in range(w):
            inside = ox <= x < ox + VW * scale and oy <= y < oy + VH * scale
            if not inside and px[x, y] != (0, 0, 0):
                bad_bars += 1

    print(f"  non-uniform virtual pixels: {bad_blocks}")
    print(f"  non-black letterbox pixels: {bad_bars}")
    return 1 if (bad_blocks or bad_bars) else 0


if __name__ == "__main__":
    sys.exit(main())
