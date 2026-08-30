#!/usr/bin/env python3
"""
Placeholder app-icon generator for Sisyphus/LatiLearn (pure Python stdlib).

A 2D hill with a boulder on its slope -- a literal nod to the app's
internal name, Sisyphus. Flat, single focal point (the boulder), no text,
no baked lighting -- a placeholder for the iOS 26+ Liquid Glass icon,
finished later in Icon Composer.

Renders natively at whatever size is requested (better anti-aliasing at
small sizes than upscaling a single large render).
"""
import struct
import zlib
import math
import sys


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(3))


def coverage(dist, aa):
    return max(0.0, min(1.0, 0.5 - dist / aa))


def hill_surface_y(x, n, peak_x, peak_y, base_y):
    """Height of the hill's slope at x: an asymmetric wedge -- a long,
    gentle rise on the left up to the peak, a shorter, steeper drop on the
    right -- reading as an actual hillside rather than a symmetric dome."""
    if x <= peak_x:
        k = (base_y - peak_y) / (peak_x * peak_x)
        return peak_y + k * (peak_x - x) ** 2
    else:
        k = (base_y - peak_y) / ((n - peak_x) ** 2)
        return peak_y + k * (x - peak_x) ** 2


def render(n, bg_top, bg_bottom, hill_color, boulder_color, out_path, transparent_bg=False):
    channels = 4 if transparent_bg else 3
    aa = max(1.0, n * 0.0025)  # keep the edge softness proportional to size

    peak_x, peak_y, base_y = n * 0.66, n * 0.40, n * 1.02

    # Boulder: resting low on the long gentle left slope, well short of the
    # peak -- the rest of the climb still clearly ahead.
    boulder_r = n * 0.135
    boulder_x = n * 0.22
    surface_y = hill_surface_y(boulder_x, n, peak_x, peak_y, base_y)
    boulder_y = surface_y - boulder_r * 0.62

    rows = []
    for y in range(n):
        row = bytearray(n * channels)
        vt = y / max(1, n - 1)
        bg = None if transparent_bg else mix(bg_top, bg_bottom, vt)

        for x in range(n):
            surface = hill_surface_y(x, n, peak_x, peak_y, base_y)
            # coverage() treats negative distance as "inside" -- below the
            # slope line (y > surface) should be filled (hill), so negate.
            d_hill = surface - y

            bdx = x - boulder_x
            bdy = y - boulder_y
            d_boulder = math.hypot(bdx, bdy) - boulder_r

            if transparent_bg:
                color = (0, 0, 0)
                alpha = 0.0
            else:
                color = bg
                alpha = 1.0

            hill_cov = coverage(d_hill, aa)
            if hill_cov > 0:
                color = mix(color, hill_color, hill_cov) if not transparent_bg or alpha > 0 else hill_color
                alpha = max(alpha, hill_cov) if transparent_bg else 1.0

            boulder_cov = coverage(d_boulder, aa)
            if boulder_cov > 0:
                color = mix(color, boulder_color, boulder_cov)
                alpha = max(alpha, boulder_cov) if transparent_bg else 1.0

            i = x * channels
            row[i] = int(color[0] + 0.5)
            row[i + 1] = int(color[1] + 0.5)
            row[i + 2] = int(color[2] + 0.5)
            if transparent_bg:
                row[i + 3] = int(alpha * 255 + 0.5)

        rows.append(row)

    write_png(out_path, rows, n, channels)


def write_png(path, rows, n, channels):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(
            ">I", zlib.crc32(tag + data) & 0xffffffff
        )

    color_type = 6 if channels == 4 else 2  # 6 = RGBA, 2 = RGB
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)

    ihdr = struct.pack(">IIBBBBB", n, n, 8, color_type, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 6)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


APP_BLUE_TOP = hex_to_rgb("#0a4fa8")
APP_BLUE_BOTTOM = hex_to_rgb("#0a6ee6")
WHITE = hex_to_rgb("#ffffff")
GOLD = hex_to_rgb("#ffd60a")
GRAY_HILL = hex_to_rgb("#d8d8dc")   # tinted-variant grayscale
GRAY_BOULDER = hex_to_rgb("#4a4a4f")
GRAY_BG_TOP = hex_to_rgb("#3a3a3d")
GRAY_BG_BOTTOM = hex_to_rgb("#1a1a1c")
DARK_BG_TOP = hex_to_rgb("#041f42")
DARK_BG_BOTTOM = hex_to_rgb("#0a3d80")

ICON_SIZES = [16, 20, 29, 32, 40, 48, 50, 55, 57, 58, 60, 64, 66, 72, 76, 80,
              87, 88, 92, 100, 102, 108, 114, 120, 128, 144, 152, 167, 172,
              180, 196, 216, 234, 256, 258, 512, 1024]


if __name__ == "__main__":
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."

    for size in ICON_SIZES:
        render(size, APP_BLUE_TOP, APP_BLUE_BOTTOM, WHITE, GOLD, f"{out_dir}/{size}.png")

    # Appearance-variant previews at 1024 (not installed into the legacy
    # per-size catalog, which predates appearance variants -- kept for
    # reference / for a future move to the modern single-size format).
    render(1024, DARK_BG_TOP, DARK_BG_BOTTOM, WHITE, GOLD, f"{out_dir}/preview_dark_1024.png")
    render(1024, GRAY_BG_TOP, GRAY_BG_BOTTOM, GRAY_HILL, GRAY_BOULDER, f"{out_dir}/preview_tinted_1024.png")

    # Layered source art for Icon Composer -- flat, no baked lighting.
    render(1024, APP_BLUE_TOP, APP_BLUE_BOTTOM, WHITE, GOLD, f"{out_dir}/layer_1_background_1024.png")
    render(1024, None, None, WHITE, GOLD, f"{out_dir}/layer_2_foreground_1024.png", transparent_bg=True)

    print(f"wrote {len(ICON_SIZES) + 4} files to {out_dir}")
