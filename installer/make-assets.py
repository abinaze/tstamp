#!/usr/bin/env python3
"""Builds the installer artwork in installer/assets from the brand files.

Run it only when the logo or the wizard design changes (needs Pillow and
DejaVu Sans Mono). The results are committed, so building the installer
needs neither.

  python3 installer/make-assets.py
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, "assets", "brand", "png")
OUT = os.path.join(ROOT, "installer", "assets")

INK = (0x14, 0x18, 0x1D)
PAPER = (0xF4, 0xF6, 0xF8)
MUTED = (0x8A, 0x93, 0x9C)
TICK = (0x2A, 0x30, 0x38)
WHITE = (0xFF, 0xFF, 0xFF)

FONT_DIRS = ["/usr/share/fonts/truetype/dejavu", "C:/Windows/Fonts", "/Library/Fonts"]


def font(name, px):
    for d in FONT_DIRS:
        p = os.path.join(d, name)
        if os.path.exists(p):
            return ImageFont.truetype(p, px)
    sys.exit("DejaVu Sans Mono was not found: " + name)


def logo(name):
    return Image.open(os.path.join(BRAND, name)).convert("RGBA")


def panel(w, h):
    """The tall picture on the Welcome and Finish pages (designed at 164 wide)."""
    k = 4  # draw 4 times larger, then shrink for smooth edges
    s = w / 164.0
    W, H = w * k, h * k
    im = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(im)

    # ruler ticks along the right edge, echoing the symbol
    step = 10 * s * k
    y, i = step, 1
    while y < H - step:
        long_tick = i % 5 == 0
        length = (14 if long_tick else 7) * s * k
        d.rectangle([W - length, y - s * k * 0.5, W, y + s * k * 0.5], fill=TICK)
        y += step
        i += 1

    # logo
    lw = int(124 * s * k)
    lg = logo("tstamp-horizontal-light.png")
    lg = lg.crop(lg.getbbox())  # drop the empty margin so the left edges line up
    lh = int(lg.height * lw / lg.width)
    lg = lg.resize((lw, lh), Image.LANCZOS)
    top = int(38 * s * k)
    im.paste(lg, (int(20 * s * k), top), lg)

    # tagline
    f = font("DejaVuSansMono.ttf", int(11.5 * s * k))
    ty = top + lh + int(34 * s * k)
    for line in ("Timestamp every", "command in your", "terminal."):
        d.text((int(20 * s * k), ty), line, font=f, fill=PAPER)
        ty += int(11.5 * 1.55 * s * k)

    # sample output, anchored to the bottom
    fb = font("DejaVuSansMono-Bold.ttf", int(10 * s * k))
    fr = font("DejaVuSansMono.ttf", int(10 * s * k))
    lh2 = int(10 * 1.6 * s * k)
    by = H - int(34 * s * k) - 2 * lh2
    d.rectangle([int(20 * s * k), by - int(12 * s * k), int(60 * s * k), by - int(12 * s * k) + max(k, int(s * k))], fill=MUTED)
    x0 = int(20 * s * k)
    cw = fr.getlength("0")
    d.text((x0, by), "START", font=fb, fill=PAPER)
    d.text((x0 + 6 * cw, by), "npm test", font=fr, fill=MUTED)
    d.text((x0, by + lh2), "END", font=fb, fill=PAPER)
    d.text((x0 + 6 * cw, by + lh2), "EXIT=0 3.1s", font=fr, fill=MUTED)

    return im.resize((w, h), Image.LANCZOS)


def small(w, h):
    """The small picture at the top right of the inner pages."""
    k = 4
    im = Image.new("RGB", (w * k, h * k), WHITE)
    side = int(min(w, h) * 0.86 * k)
    ic = logo("tstamp-icon-512.png").resize((side, side), Image.LANCZOS)
    im.paste(ic, ((w * k - side) // 2, (h * k - side) // 2), ic)
    return im.resize((w, h), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    # Sizes Inno Setup suggests for 100%, 125%, 150% and 200% display scaling.
    for tag, (w, h) in {"100": (164, 314), "125": (192, 386), "150": (246, 459), "200": (328, 604)}.items():
        panel(w, h).save(os.path.join(OUT, "wizard-%s.bmp" % tag))
    for tag, (w, h) in {"100": (55, 55), "125": (64, 68), "150": (83, 80), "200": (110, 106)}.items():
        small(w, h).save(os.path.join(OUT, "small-%s.bmp" % tag))
    ic = logo("tstamp-icon-512.png")
    ic.save(os.path.join(OUT, "tstamp.ico"), sizes=[(n, n) for n in (16, 24, 32, 48, 64, 128, 256)])
    print("Wrote", len(os.listdir(OUT)), "files to", OUT)


if __name__ == "__main__":
    main()
