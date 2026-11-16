#!/usr/bin/env python3
"""Procedural muzzle flash GIF generator.

Every frame is rendered as a float intensity map (0..1) and mapped through a
fixed 256-colour ramp. Palette index 0 is EXACTLY (0,0,0) and every pixel below
a small threshold is forced to index 0, so black-keying / additive blending in
your engine is clean (no dark-gray fringing from quantisation).

Usage: make_flashes.py OUTDIR [SIZE]
"""
import sys, os
import numpy as np
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
SIZE = int(sys.argv[2]) if len(sys.argv) > 2 else 128
FRAME_MS = 40  # per-frame delay

os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- palettes --
RAMPS = {
    # intensity stops -> RGB
    "fire": [(0.00, (0, 0, 0)), (0.12, (60, 8, 0)), (0.30, (190, 50, 0)),
             (0.55, (255, 140, 20)), (0.78, (255, 220, 100)), (1.00, (255, 255, 235))],
    "hot":  [(0.00, (0, 0, 0)), (0.10, (70, 20, 0)), (0.28, (200, 90, 0)),
             (0.55, (255, 190, 50)), (0.80, (255, 245, 170)), (1.00, (255, 255, 255))],
    "plasma": [(0.00, (0, 0, 0)), (0.12, (0, 10, 70)), (0.32, (0, 70, 220)),
               (0.58, (60, 170, 255)), (0.80, (190, 235, 255)), (1.00, (255, 255, 255))],
    "green": [(0.00, (0, 0, 0)), (0.12, (0, 50, 5)), (0.32, (20, 170, 20)),
              (0.58, (120, 255, 60)), (0.80, (220, 255, 170)), (1.00, (255, 255, 255))],
}

def build_palette(name):
    stops = RAMPS[name]
    pal = np.zeros((256, 3), np.uint8)
    xs = np.linspace(0, 1, 256)
    for c in range(3):
        pal[:, c] = np.interp(xs, [s[0] for s in stops], [s[1][c] for s in stops])
    pal[0] = (0, 0, 0)
    return pal

def edge_window(size, margin=0.10):
    """Smoothly fade to black at the sprite borders so nothing is cut off."""
    t = np.linspace(-1, 1, size, dtype=np.float32)
    w1 = np.clip((1 - np.abs(t)) / margin, 0, 1)
    w1 = w1 * w1 * (3 - 2 * w1)
    return np.outer(w1, w1)

def to_image(intensity, palette):
    idx = np.clip(intensity * edge_window(intensity.shape[0]), 0, 1)
    idx = (idx * 255 + 0.5).astype(np.uint8)
    idx[idx < 6] = 0                      # hard black floor => clean alpha key
    im = Image.fromarray(idx, "P")
    im.putpalette(palette.flatten().tolist())
    return im

# ----------------------------------------------------------------- shapes ---
def grid(size):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    return (x - (size - 1) / 2) / (size / 2), (y - (size - 1) / 2) / (size / 2)

def star(size, rng, scale, n_spikes, spike_len, spike_w, core, jitter=1.0, rot=None):
    """Radial burst: gaussian core + randomly-angled tapered spikes."""
    x, y = grid(size)
    r = np.hypot(x, y) + 1e-6
    th = np.arctan2(y, x)
    I = np.exp(-(r / (core * scale)) ** 2) * 1.15
    base = rng.uniform(0, 2 * np.pi) if rot is None else rot
    for i in range(n_spikes):
        a = base + 2 * np.pi * i / n_spikes + rng.normal(0, 0.25 * jitter)
        L = spike_len * scale * rng.uniform(0.55, 1.0 if jitter else 0.6) * (1 if i % 2 == 0 else 0.7)
        w = spike_w * rng.uniform(0.7, 1.3)
        d = np.angle(np.exp(1j * (th - a)))
        ang = np.exp(-(d / (w * (1 + 1.5 * (1 - np.clip(r / L, 0, 1))))) ** 2)
        rad = np.clip(1 - r / L, 0, 1) ** 1.4
        I += 0.95 * ang * rad
    return I

def cone(size, rng, scale, length, width, tongues=1, noise=0.25):
    """Side-view directional flash firing to the right. Origin at left-centre."""
    x, y = grid(size)
    x = (x + 0.9)                       # origin near left edge
    I = np.zeros_like(x)
    for t in range(tongues):
        ang = 0 if tongues == 1 else (t - (tongues - 1) / 2) * 0.28
        xr = x * np.cos(ang) + y * np.sin(ang)
        yr = -x * np.sin(ang) + y * np.cos(ang)
        L = length * scale * rng.uniform(0.8, 1.0) * (1 if t == tongues // 2 else 0.7)
        u = np.clip(xr / L, 0, 1)
        half = width * scale * (0.25 + 0.75 * np.sin(np.pi * np.clip(u * 0.9 + 0.05, 0, 1)) ** 0.7) * (1 - u) ** 0.5
        half = np.maximum(half, 1e-3)
        v = np.clip(1 - np.abs(yr) / half, 0, 1) ** 1.3
        body = v * np.clip(1 - u, 0, 1) ** 0.7 * (xr > 0)
        I += body
    # ragged edge noise
    n = rng.random((size // 8 + 2, size // 8 + 2)).astype(np.float32)
    n = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((size, size), Image.BICUBIC), np.float32) / 255
    I *= (1 - noise) + noise * 2 * n
    # hot blob at the muzzle
    I += 1.1 * np.exp((-(x ** 2) / (0.05 * scale + 1e-3)) - (y ** 2) / (0.05 * scale + 1e-3))
    return I

def ring(size, scale, rad, thick):
    x, y = grid(size)
    r = np.hypot(x, y)
    return np.exp(-((r - rad * scale) / thick) ** 2)

def sparks(size, rng, scale, n, spread, length):
    x, y = grid(size)
    I = np.zeros_like(x)
    for _ in range(n):
        a = rng.uniform(-spread, spread)
        d = rng.uniform(0.25, 0.9) * scale
        px, py = d * np.cos(a) - 0.9 + 0.9, d * np.sin(a)
        dx, dy = np.cos(a), np.sin(a)
        # streak along direction
        t = (x - px) * dx + (y - py) * dy
        s = np.abs(-(x - px) * dy + (y - py) * dx)
        I += 0.9 * np.exp(-(s / 0.012) ** 2) * np.exp(-(t / (length * scale)) ** 2)
    return I

# ------------------------------------------------------------ definitions ---
# each: (name, ramp, frame-scale curve, frame-builder)
def mk_pistol(f, s, rng):
    return star(SIZE, rng, s, 6, 0.85, 0.16, 0.20)

def mk_rifle(f, s, rng):
    return star(SIZE, rng, s, 8, 0.95, 0.12, 0.17) + 0.35 * ring(SIZE, s, 0.18, 0.06)

def mk_smg(f, s, rng):
    return star(SIZE, rng, s, 5, 0.70, 0.18, 0.22)

def mk_shotgun(f, s, rng):
    return star(SIZE, rng, s, 12, 1.0, 0.10, 0.28) + 0.4 * ring(SIZE, s, 0.28, 0.08)

def mk_cone_pistol(f, s, rng):
    return cone(SIZE, rng, s, 1.6, 0.34, 1)

def mk_cone_rifle(f, s, rng):
    return cone(SIZE, rng, s, 1.8, 0.30, 1) + 0.6 * sparks(SIZE, rng, s, 4, 0.35, 0.18)

def mk_cone_shotgun(f, s, rng):
    return cone(SIZE, rng, s, 1.7, 0.46, 3, 0.35) + 0.7 * sparks(SIZE, rng, s, 6, 0.5, 0.2)

def mk_plasma(f, s, rng):
    return star(SIZE, rng, s, 6, 0.8, 0.2, 0.30, jitter=0.3) + 0.7 * ring(SIZE, s, 0.35, 0.07)

def mk_toxic(f, s, rng):
    return star(SIZE, rng, s, 7, 0.75, 0.16, 0.26, jitter=0.6)

CURVE_5 = [0.85, 1.00, 0.80, 0.52, 0.26]
CURVE_4 = [1.00, 0.80, 0.50, 0.24]
CURVE_6 = [0.70, 1.00, 0.92, 0.70, 0.45, 0.22]

VARIANTS = [
    ("star_pistol",       "hot",    CURVE_4, mk_pistol),
    ("star_rifle",        "fire",   CURVE_5, mk_rifle),
    ("star_smg",          "hot",    [1.0, 0.7, 0.35], mk_smg),
    ("star_shotgun",      "fire",   CURVE_6, mk_shotgun),
    ("cone_pistol",       "hot",    CURVE_4, mk_cone_pistol),
    ("cone_rifle",        "fire",   CURVE_5, mk_cone_rifle),
    ("cone_shotgun",      "fire",   CURVE_6, mk_cone_shotgun),
    ("energy_plasma",     "plasma", CURVE_5, mk_plasma),
    ("energy_toxic",      "green",  CURVE_5, mk_toxic),
]

def render(name, ramp, curve, fn, seed, out_name):
    rng = np.random.default_rng(seed)
    pal = build_palette(ramp)
    frames = [to_image(fn(i, s, rng), pal) for i, s in enumerate(curve)]
    path = os.path.join(OUT, out_name + ".gif")
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=FRAME_MS,
                   loop=0, disposal=2, optimize=False)
    return path

if __name__ == "__main__":
    for name, ramp, curve, fn in VARIANTS:
        for v in range(3):  # 3 random variations of each so shots don't look identical
            p = render(name, ramp, curve, fn, sum(map(ord, name)) + v * 97, f"{name}_{v+1}")
            print(p)
