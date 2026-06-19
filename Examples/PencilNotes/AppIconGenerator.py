#!/usr/bin/env python3
"""Generates the PencilNotes app icon: a stylish classic pencil drawn diagonally
on an indigo→cyan gradient, with a small Markdown ↓ accent. Run from this dir:
    python3 AppIconGenerator.py   (requires Pillow)
"""
from PIL import Image, ImageDraw, ImageFilter

S = 1024
TOP = (91, 79, 245)     # indigo #5B4FF5
BOT = (56, 217, 255)    # cyan   #38D9FF
ICONSET = "App/Assets.xcassets/AppIcon.appiconset"


def gradient() -> Image.Image:
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * (S - 1))
            px[x, y] = tuple(int(TOP[i] + (BOT[i] - TOP[i]) * t) for i in range(3))
    return img


def draw_pencil() -> Image.Image:
    """Draw a horizontal pencil (tip on the left) on a transparent layer."""
    W, H = 1400, 1400
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    cy = H // 2
    th = 150               # body thickness
    x = 360                # left start (graphite point)
    graphite, wood = 70, 150
    body_len, ferrule, eraser = 560, 70, 110

    tip_x = x
    wood_x = x + graphite
    body_x0 = wood_x + wood
    body_x1 = body_x0 + body_len
    ferrule_x1 = body_x1 + ferrule
    eraser_x1 = ferrule_x1 + eraser

    half = th // 2
    # graphite tip (dark) + wood cone (tan)
    d.polygon([(tip_x, cy), (wood_x, cy - 26), (wood_x, cy + 26)], fill=(40, 44, 60, 255))
    d.polygon([(wood_x, cy - 26), (wood_x, cy + 26),
               (body_x0, cy + half), (body_x0, cy - half)], fill=(244, 215, 160, 255))
    d.line([(wood_x, cy), (body_x0, cy)], fill=(40, 44, 60, 120), width=4)
    # yellow body
    d.rectangle([body_x0, cy - half, body_x1, cy + half], fill=(255, 200, 61, 255))
    # subtle top highlight stripe
    d.rectangle([body_x0, cy - half, body_x1, cy - half + 26], fill=(255, 224, 130, 255))
    # silver ferrule with two grooves
    d.rectangle([body_x1, cy - half, ferrule_x1, cy + half], fill=(196, 201, 210, 255))
    for gx in (body_x1 + 22, body_x1 + 46):
        d.line([(gx, cy - half), (gx, cy + half)], fill=(150, 156, 168, 255), width=6)
    # pink eraser (rounded right end)
    d.rounded_rectangle([ferrule_x1, cy - half, eraser_x1, cy + half],
                        radius=half, fill=(255, 122, 156, 255))
    return layer


def main() -> None:
    bg = gradient().convert("RGBA")

    pencil = draw_pencil().rotate(45, expand=True, resample=Image.BICUBIC)
    pencil = pencil.crop(pencil.getbbox())   # trim transparent margins

    # scale so the longer side fills ~80% of the canvas, then center
    target = int(S * 0.80)
    w, h = pencil.size
    k = target / max(w, h)
    pencil = pencil.resize((int(w * k), int(h * k)), Image.LANCZOS)
    pw, ph = pencil.size
    off = ((S - pw) // 2, (S - ph) // 2)

    # soft drop shadow from the pencil alpha
    shadow = Image.new("RGBA", pencil.size, (0, 0, 0, 0))
    shadow.paste((10, 20, 60, 150), (0, 0), pencil.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(20))
    bg.alpha_composite(shadow, (off[0] + 14, off[1] + 20))
    bg.alpha_composite(pencil, off)

    master = bg.convert("RGB")
    master.save(f"{ICONSET}/icon_1024.png", "PNG")  # iOS universal single size
    print("PencilNotes icon written to", ICONSET)


if __name__ == "__main__":
    main()
