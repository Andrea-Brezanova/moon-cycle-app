"""Renders the Moon Cycle iOS app icons from the brand mark's geometry.

The geometry is the one in design/assets/app-icon/icon-cream.svg (a 200-unit
ring of four arcs plus the "today" dot); only the scale changes, so the mark
fills more of the icon. Run: python3 tool/make_app_icon.py
"""
import json
import math
import os
from PIL import Image, ImageDraw

BG = (252, 250, 245)  # #FCFAF5 cream
PLUM = (55, 37, 92)  # #37255C
ARCS = [  # (start point, end point, colour); radius 62, centre (100, 100)
    ((102.16, 38.04), (154.89, 71.17), (229, 142, 115)),
    ((156.76, 75.07), (140.32, 147.09), (79, 138, 114)),
    ((136.94, 149.79), (88.32, 160.89), (228, 172, 36)),
    ((84.10, 159.93), (97.84, 38.04), (122, 99, 184)),
]
DOT = (155.86, 73.1)
STROKE = 30
R = 62
SCALE = 5.1  # the original icon used 3.77263
SS = 4  # supersampling


def render(px, scale=SCALE, bg=BG, dot=PLUM, gap=None):
    gap = gap or bg
    n = px * SS
    k = n / 1024 * scale
    off = n / 2 - 100 * k
    img = Image.new("RGB", (n, n), bg)
    d = ImageDraw.Draw(img)

    def p(x, y):
        return (off + x * k, off + y * k)

    def ang(pt):
        return math.degrees(math.atan2(pt[1] - 100, pt[0] - 100))

    for a, b, col in ARCS:
        a0, a1 = ang(a), ang(b)
        if a1 < a0:
            a1 += 360
        steps = 120
        outer, inner = [], []
        for i in range(steps + 1):
            t = math.radians(a0 + (a1 - a0) * i / steps)
            outer.append(p(100 + (R + STROKE / 2) * math.cos(t), 100 + (R + STROKE / 2) * math.sin(t)))
            inner.append(p(100 + (R - STROKE / 2) * math.cos(t), 100 + (R - STROKE / 2) * math.sin(t)))
        d.polygon(outer + inner[::-1], fill=col)

    def circle(c, r, fill):
        cx, cy = p(*c)
        d.ellipse([cx - r * k, cy - r * k, cx + r * k, cy + r * k], fill=fill)

    circle(DOT, 28, gap)
    circle(DOT, 22, dot)
    return img.resize((px, px), Image.LANCZOS)


if __name__ == "__main__":
    base = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.load(open(f"{base}/Contents.json"))
    kept = []
    for im in contents["images"]:
        if "appearances" in im:
            continue  # no dark variant: the approved mark stays on cream
        kept.append(im)
        size = float(im["size"].split("x")[0]) * int(im["scale"][0])
        render(round(size)).save(f"{base}/{im['filename']}")
    contents["images"] = kept
    json.dump(contents, open(f"{base}/Contents.json", "w"), separators=(",", ":"))
    for f in os.listdir(base):
        if "-Dark-" in f:
            os.remove(f"{base}/{f}")
