#!/usr/bin/env python3
"""Erzeugt die freigestellten Manny-Grafiken aus den Quellbildern.

Aufruf (aus dem Projektstamm):  python3 docs/design/manny/make_manny_assets.py
Benötigt: Python 3, Pillow, NumPy. Keine weiteren Abhängigkeiten.

Eingabe : docs/design/manny/quelle/manny-mit-brille.webp, manny-ohne-brille.webp
Ausgabe : docs/design/manny/{brille,ohne}/{normal,freudig,traurig,kopf}.png   (1x)
          docs/design/manny/{brille,ohne}/2.0x/*.png, 3.0x/*.png              (Flutter-Konvention)
          docs/design/manny/manny-uebersicht.png                              (Kontaktbogen)

Verfahren (kein globaler Weiß-Schlüssel):
 1. Hintergrund = nahezu weiße, neutrale Pixel, die per Flood-Fill vom Bildrand
    erreichbar sind. Bauch und Glanzlichter liegen hinter der Kontur und bleiben erhalten.
    Der weiche Bodenschatten ist hellgrau-neutral und wird mit entfernt.
 2. Kantenband (2 px um den Hintergrund): Farbe = nächste Innenfarbe, Alpha aus dem
    Mischverhältnis zu Weiß (Unmatting) -> kein weißer Saum auf dunklem Grund.
 3. Alle drei Körperposen je Variante teilen eine Leinwand, ausgerichtet an Fußlinie und
    Körpermitte (Pose-Wechsel ohne Springen); der Kopf hat eine eigene quadratische Leinwand.
 4. Master = 3x; 2x und 1x per Skalierung mit vormultipliziertem Alpha.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SRC = HERE / "quelle"
VARIANTS = {"brille": "manny-mit-brille.webp", "ohne": "manny-ohne-brille.webp"}

# Suchbereiche im Quellbild (x0, y0, x1, y1); schließen die Beschriftungen aus.
REGIONS = {
    "normal":  (0, 0, 515, 578),
    "freudig": (515, 0, 1000, 578),
    "traurig": (1000, 0, 1536, 578),
    "kopf":    (560, 640, 960, 936),
}
MARGIN = 24          # px im 3x-Master, gleicher Rand an allen Seiten
HEAD_MARGIN = 12
BAND = 2             # Kantenband in px


def load(name):
    return np.array(Image.open(SRC / name).convert("RGB")).astype(np.int16)


_BG_CACHE = {}


def background_mask(a):
    """Flood-Fill (4er-Nachbarschaft) vom Rand über nahezu weiße, neutrale Pixel."""
    key = id(a)
    if key in _BG_CACHE:
        return _BG_CACHE[key]
    mn = a.min(axis=2)
    mx = a.max(axis=2)
    cand = ((mn >= 225) & (mx - mn <= 16))
    h, w = cand.shape
    flat = cand.ravel().tolist()
    seen = bytearray(h * w)
    stack = []
    for x in range(w):
        stack += [x, (h - 1) * w + x]
    for y in range(h):
        stack += [y * w, y * w + w - 1]
    while stack:
        i = stack.pop()
        if seen[i] or not flat[i]:
            continue
        seen[i] = 1
        x = i % w
        if x > 0: stack.append(i - 1)
        if x < w - 1: stack.append(i + 1)
        if i >= w: stack.append(i - w)
        if i < (h - 1) * w: stack.append(i + w)
    out = np.frombuffer(bytes(seen), np.uint8).reshape(h, w).astype(bool)
    _BG_CACHE[key] = out
    return out


def shift(m, dy, dx):
    out = np.zeros_like(m)
    h, w = m.shape
    ys = slice(max(dy, 0), h + min(dy, 0))
    yd = slice(max(-dy, 0), h + min(-dy, 0))
    xs = slice(max(dx, 0), w + min(dx, 0))
    xd = slice(max(-dx, 0), w + min(-dx, 0))
    out[ys, xs] = m[yd, xd]
    return out


def dilate(m, n):
    for _ in range(n):
        acc = m.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                acc |= shift(m, dy, dx)
        m = acc
    return m


def cut_out(a, region):
    """Gibt RGBA (float 0..255) der Region plus Körper-Bounding-Box (dunkle Pixel) zurück."""
    x0, y0, x1, y1 = region
    bg = background_mask(a)
    fg = ~bg
    sel = np.zeros_like(fg)
    sel[y0:y1, x0:x1] = True
    fg &= sel
    band = dilate(bg, BAND) & fg
    interior = fg & ~band
    # Innenfarbe in das Kantenband hineinziehen
    col = np.where(interior[..., None], a, 0).astype(np.float32)
    valid = interior.copy()
    todo = band.copy()
    for _ in range(BAND + 2):
        if not todo.any():
            break
        s = np.zeros_like(col)
        n = np.zeros(valid.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                v = shift(valid, dy, dx)
                s += np.where(v[..., None], shift_f(col, dy, dx), 0)
                n += v
        newly = todo & (n > 0)
        col[newly] = s[newly] / n[newly][:, None]
        valid |= newly
        todo &= ~newly
    c0 = col
    p = a.astype(np.float32)
    d = 255.0 - c0
    num = ((255.0 - p) * d).sum(axis=2)
    den = np.maximum((d * d).sum(axis=2), 1.0)
    alpha = np.clip(num / den, 0, 1)
    alpha = np.where(band, alpha, 1.0) * fg
    rgb = np.where(band[..., None], c0, p)
    rgba = np.dstack([rgb, alpha * 255.0])
    dark = fg & (a.max(axis=2) < 90)
    ys, xs = np.where(dark)
    body = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    ys, xs = np.where(fg & (alpha > 0.05))
    full = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    return rgba, body, full


def shift_f(arr, dy, dx):
    out = np.zeros_like(arr)
    h, w = arr.shape[:2]
    ys = slice(max(dy, 0), h + min(dy, 0))
    yd = slice(max(-dy, 0), h + min(-dy, 0))
    xs = slice(max(dx, 0), w + min(dx, 0))
    xd = slice(max(-dx, 0), w + min(-dx, 0))
    out[ys, xs] = arr[yd, xd]
    return out


def up(n, k=3):
    return -(-n // k) * k


def to_img(arr):
    return Image.fromarray(np.clip(arr + 0.5, 0, 255).astype(np.uint8), "RGBA")


def resize_premult(im, size):
    a = np.array(im).astype(np.float32)
    al = a[..., 3:4] / 255.0
    pm = np.dstack([a[..., :3] * al, a[..., 3:4]])
    chans = [Image.fromarray(pm[..., i], "F").resize(size, Image.LANCZOS) for i in range(4)]
    r = np.stack([np.array(c) for c in chans], axis=-1)
    alpha = np.clip(r[..., 3], 0, 255)
    safe = np.maximum(alpha / 255.0, 1e-6)[..., None]
    rgb = np.clip(r[..., :3] / safe, 0, 255)
    rgb[alpha < 1] = 0
    return Image.fromarray(np.dstack([rgb, alpha]).round().astype(np.uint8), "RGBA")


def main():
    cuts = {}
    for v, f in VARIANTS.items():
        a = load(f)
        for pose, reg in REGIONS.items():
            cuts[(v, pose)] = cut_out(a, reg)

    # gemeinsame Körper-Leinwand (beide Varianten, drei Posen)
    L = R = T = B = 0
    for (v, pose), (_, body, full) in cuts.items():
        if pose == "kopf":
            continue
        cx = (body[0] + body[2]) / 2
        L = max(L, cx - full[0]); R = max(R, full[2] - cx)
        T = max(T, body[3] - full[1]); B = max(B, full[3] - body[3])
    half = int(np.ceil(max(L, R)))
    cw = up(2 * half + 2 * MARGIN)
    ch = up(int(np.ceil(T + B)) + 2 * MARGIN)
    # Kopf-Leinwand: quadratisch
    hs = 0
    for (v, pose), (_, body, full) in cuts.items():
        if pose == "kopf":
            hs = max(hs, full[2] - full[0], full[3] - full[1])
    hside = up(int(hs) + 2 * HEAD_MARGIN)
    print(f"Körper-Leinwand 3x: {cw}x{ch}  (= {cw/3:g}x{ch/3:g} dp);  Kopf-Leinwand 3x: {hside}x{hside} (= {hside/3:g} dp)")

    for (v, pose), (rgba, body, full) in cuts.items():
        if pose == "kopf":
            canvas = np.zeros((hside, hside, 4), np.float32)
            cx = (full[0] + full[2]) / 2; cy = (full[1] + full[3]) / 2
            ox = int(round(hside / 2 - cx)); oy = int(round(hside / 2 - cy))
        else:
            canvas = np.zeros((ch, cw, 4), np.float32)
            cx = (body[0] + body[2]) / 2
            ox = int(round(cw / 2 - cx))
            oy = int(round(ch - MARGIN - body[3]))
        H, W = canvas.shape[:2]
        sy0, sx0 = max(0, -oy), max(0, -ox)
        dy0, dx0 = max(0, oy), max(0, ox)
        hh = min(rgba.shape[0] - sy0, H - dy0); ww = min(rgba.shape[1] - sx0, W - dx0)
        canvas[dy0:dy0 + hh, dx0:dx0 + ww] = rgba[sy0:sy0 + hh, sx0:sx0 + ww]
        # nur die Region ausschneiden (Nachbarposen/Beschriftung ausschließen)
        master = to_img(canvas)
        out = HERE / v
        for scale, sub in ((3, "3.0x"), (2, "2.0x"), (1, "")):
            d = out / sub if sub else out
            d.mkdir(parents=True, exist_ok=True)
            size = (master.width * scale // 3, master.height * scale // 3)
            im = master if scale == 3 else resize_premult(master, size)
            im.save(d / f"{pose}.png", optimize=True)
    contact_sheet(hside // 3)


def contact_sheet(head_dp):
    LIGHT = (250, 246, 238, 255)
    DARK = (11, 16, 32, 255)
    font = ImageFont.load_default(size=15)
    names = ["normal", "freudig", "traurig", "kopf"]
    label = {"brille": "mit Brille", "ohne": "ohne Brille"}
    pad = 24
    tile = {(v, n): Image.open(HERE / v / "2.0x" / f"{n}.png") for v in VARIANTS for n in names}
    tw = max(t.width for t in tile.values()); th = max(t.height for t in tile.values())
    W = pad + 4 * (tw + pad)

    def ink(bg):
        return (20, 20, 30, 255) if bg == LIGHT else (230, 230, 240, 255)

    def panel(bg, title):
        h = 40 + 2 * (th + 30) + pad
        im = Image.new("RGBA", (W, h), bg)
        d = ImageDraw.Draw(im)
        d.text((pad, 12), title, fill=ink(bg), font=font)
        for r, v in enumerate(VARIANTS):
            for c, n in enumerate(names):
                t = tile[(v, n)]
                x = pad + c * (tw + pad) + (tw - t.width) // 2
                y = 40 + r * (th + 30) + (th - t.height) // 2
                im.alpha_composite(t, (x, y))
                d.text((pad + c * (tw + pad), 40 + r * (th + 30) + th + 4), f"{label[v]} / {n}", fill=ink(bg), font=font)
        return im

    sizes = [40, 56, 80]

    def head_panel(bg, title):
        row_h = 3 * 80 + 34
        im = Image.new("RGBA", (W, 40 + 2 * row_h), bg)
        d = ImageDraw.Draw(im)
        d.text((pad, 12), title, fill=ink(bg), font=font)
        for r, v in enumerate(VARIANTS):
            src = Image.open(HERE / v / "3.0x" / "kopf.png")
            x = pad
            y0 = 40 + r * row_h
            for s in sizes:
                for scale in (1, 3):
                    px = s * scale
                    t = resize_premult(src, (px, px))
                    im.alpha_composite(t, (x, y0 + (3 * 80 - px) // 2 if scale == 3 else y0 + 3 * 80 // 2 - px // 2))
                    d.text((x, y0 + 3 * 80 + 6), f"{label[v][:3]}. {s}dp@{scale}x", fill=ink(bg), font=font)
                    x += max(px, 96) + 12
        return im

    parts = [
        panel(LIGHT, "Alle Posen auf hellem Grund (#FAF6EE), Anzeige 2x"),
        panel(DARK, "Alle Posen auf dunklem Grund (#0B1020), Anzeige 2x"),
        head_panel(LIGHT, "Kopf bei 40 / 56 / 80 dp, hell: je 1x (pixelgenau) und 3x (Handy-Dichte)"),
        head_panel(DARK, "Kopf bei 40 / 56 / 80 dp, dunkel: je 1x und 3x"),
    ]
    sheet = Image.new("RGBA", (W, sum(p.height for p in parts)), LIGHT)
    y = 0
    for p in parts:
        sheet.alpha_composite(p, (0, y)); y += p.height
    sheet.convert("RGB").save(HERE / "manny-uebersicht.png", optimize=True)


if __name__ == "__main__":
    main()
