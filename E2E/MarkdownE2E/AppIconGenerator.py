#!/usr/bin/env python3
"""Regenerates the example app icon (App/Assets.xcassets/AppIcon.appiconset).

A full-bleed Markdown "M↓" mark on a blue→cyan diagonal gradient. Run from this
directory:  python3 AppIconGenerator.py   (requires Pillow)
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

S = 1024
TOP = (11, 95, 255)    # #0B5FFF
BOT = (56, 217, 255)   # #38D9FF
FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
ICONSET = "App/Assets.xcassets/AppIcon.appiconset"


def render_master() -> Image.Image:
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * (S - 1))
            px[x, y] = tuple(int(TOP[i] + (BOT[i] - TOP[i]) * t) for i in range(3))

    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, 560)
    mbox = draw.textbbox((0, 0), "M", font=font)
    mw, mh = mbox[2] - mbox[0], mbox[3] - mbox[1]

    shaft_w, head_w, gap = 86, 210, 70
    group_w = mw + gap + head_w
    gx = (S - group_w) // 2
    top_y = (S - mh) // 2
    mx, my = gx - mbox[0], top_y - mbox[1]

    def mark(d, fill, oy=0):
        d.text((mx, my + oy), "M", font=font, fill=fill)
        ax = gx + mw + gap + head_w // 2
        a_top, a_bot, head_h = top_y + oy, top_y + mh + oy, 200
        d.rectangle([ax - shaft_w // 2, a_top, ax + shaft_w // 2, a_bot - head_h + 30], fill=fill)
        d.polygon([(ax - head_w // 2, a_bot - head_h), (ax + head_w // 2, a_bot - head_h), (ax, a_bot)], fill=fill)

    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    mark(ImageDraw.Draw(shadow), (0, 30, 80, 120), oy=14)
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")
    mark(ImageDraw.Draw(img), (255, 255, 255))
    return img


def main() -> None:
    master = render_master()
    for s in (16, 32, 64, 128, 256, 512, 1024):
        master.resize((s, s), Image.LANCZOS).save(f"{ICONSET}/icon_{s}.png", "PNG")
    print("Regenerated icons in", ICONSET)


if __name__ == "__main__":
    main()
