#!/usr/bin/env python3
"""
Iris — abstract topographic wallpaper generator.

Nested closed contour lines on a pitch black (#000000) ground, like a real
topographic map. No colour: black, grey and white only.

Method
------
1. A height field h(x, y) is built from fbm (sum of value-noise octaves) and
   domain-warped by a second fbm to look organic.
2. Contours come from splitting h into N levels:  s = h * N,
   d = |s - round(s)| -> distance to the nearest level (in level units).
   Dividing by |grad s| turns this into a distance in PIXELS, so lines have a
   constant width regardless of slope (no marching squares needed, and the
   curves are closed by construction).
3. Every 5th level is an "index contour": slightly thicker and brighter, as
   on real topographic maps.
4. Everything is computed at SS times the resolution and downsampled with a
   2x2 average for clean anti-aliasing.
5. A composition mask gathers the contours in one region of the screen and
   leaves the rest pure black. The top edge (panel area) is kept clear.
6. A very light triangular dither breaks up banding, only where there is
   signal; pure black areas stay exactly 0.

Deterministic: the seed is fixed (default 20260914).
"""

from __future__ import annotations

import argparse
import os

import numpy as np
from PIL import Image

# ----------------------------------------------------------------------------
# Default parameters
# ----------------------------------------------------------------------------
DEFAULTS = dict(
    width=2880,
    height=1800,
    seed=20260914,
    ss=2,                 # supersampling factor
    octaves=4,            # number of fbm octaves
    base_freq=2.2,        # cells across the width at the lowest octave
    lacunarity=2.0,
    gain=0.5,
    warp=0.20,            # domain warp amount (normalised coordinates)
    warp_freq=1.7,
    levels=26,            # number of contour levels
    line_w=0.95,          # regular contour width (final pixels)
    index_w=1.7,          # index contour width (final pixels)
    index_every=5,
    line_a=0.14,          # regular contour opacity (0-1)
    index_a=0.33,         # index contour opacity (0-1), kept under 35%
    min_spacing=7.0,      # lines closer than this (final px) are faded out
    # composition mask (normalised coordinates, 0..1)
    cx=0.665,
    cy=0.665,
    rx=0.355,
    ry=0.365,
    feather=0.50,         # mask edge softness (fraction of radius)
    mask_warp=0.090,      # noise distortion of the mask edge
    top_guard=0.20,       # no detail above this fraction of the height (panel area)
    top_soft=0.14,        # softness of the top guard transition
    dither=1.0,           # triangular dither amplitude (LSB)
)


# ----------------------------------------------------------------------------
# Noise
# ----------------------------------------------------------------------------
def _smoothstep(t: np.ndarray) -> np.ndarray:
    return t * t * (3.0 - 2.0 * t)


def value_noise(h: int, w: int, gx: int, gy: int, rng: np.random.Generator) -> np.ndarray:
    """Separable interpolated value noise. Memory friendly."""
    gx = max(int(gx), 1)
    gy = max(int(gy), 1)
    lat = rng.random((gy + 1, gx + 1), dtype=np.float32)
    # wrap the edges -> seamlessly tiling field
    lat[-1, :] = lat[0, :]
    lat[:, -1] = lat[:, 0]

    fx = (np.arange(w, dtype=np.float32) + 0.5) / w * gx
    fy = (np.arange(h, dtype=np.float32) + 0.5) / h * gy
    ix = np.floor(fx).astype(np.int32)
    iy = np.floor(fy).astype(np.int32)
    tx = _smoothstep(fx - ix)
    ty = _smoothstep(fy - iy)
    ix = np.clip(ix, 0, gx - 1)
    iy = np.clip(iy, 0, gy - 1)

    # first along x: (gy+1, w)
    row = lat[:, ix] * (1.0 - tx) + lat[:, ix + 1] * tx
    # then along y: (h, w)
    out = row[iy, :] * (1.0 - ty)[:, None] + row[iy + 1, :] * ty[:, None]
    return out.astype(np.float32)


def fbm(h: int, w: int, octaves: int, base_freq: float, lacunarity: float,
        gain: float, rng: np.random.Generator, aspect: float) -> np.ndarray:
    """Fractional Brownian motion: sum of value-noise octaves."""
    total = np.zeros((h, w), dtype=np.float32)
    amp = 1.0
    norm = 0.0
    freq = base_freq
    for _ in range(octaves):
        gx = max(int(round(freq)), 1)
        gy = max(int(round(freq / aspect)), 1)
        total += amp * value_noise(h, w, gx, gy, rng)
        norm += amp
        amp *= gain
        freq *= lacunarity
    total /= norm
    return total


def warped_field(h: int, w: int, p: dict, rng: np.random.Generator) -> np.ndarray:
    """Domain-warped height field."""
    aspect = w / h

    # warp fields (low frequency, few octaves)
    wx = fbm(h, w, 3, p["warp_freq"], p["lacunarity"], p["gain"], rng, aspect) - 0.5
    wy = fbm(h, w, 3, p["warp_freq"], p["lacunarity"], p["gain"], rng, aspect) - 0.5

    # instead of sampling the main field at warped coordinates,
    # apply the warp as an extra low-frequency term plus a local shift:
    base = fbm(h, w, p["octaves"], p["base_freq"], p["lacunarity"], p["gain"], rng, aspect)

    # local shift: resample with a per-pixel displacement
    amp_x = p["warp"] * w
    amp_y = p["warp"] * h
    xs = np.clip((np.arange(w, dtype=np.float32)[None, :] + wx * amp_x), 0, w - 1.001)
    ys = np.clip((np.arange(h, dtype=np.float32)[:, None] + wy * amp_y), 0, h - 1.001)
    del wx, wy

    x0 = xs.astype(np.int32)
    y0 = ys.astype(np.int32)
    fxr = xs - x0
    fyr = ys - y0
    del xs, ys
    x1 = np.minimum(x0 + 1, w - 1)
    y1 = np.minimum(y0 + 1, h - 1)

    v00 = base[y0, x0]
    v10 = base[y0, x1]
    v01 = base[y1, x0]
    v11 = base[y1, x1]
    del base, x0, x1, y0, y1

    top = v00 * (1.0 - fxr) + v10 * fxr
    bot = v01 * (1.0 - fxr) + v11 * fxr
    del v00, v10, v01, v11, fxr
    field = top * (1.0 - fyr) + bot * fyr
    del top, bot, fyr

    # normalise to 0..1
    lo, hi = float(field.min()), float(field.max())
    field = (field - lo) / max(hi - lo, 1e-6)
    return field.astype(np.float32)


# ----------------------------------------------------------------------------
# Contour extraction
# ----------------------------------------------------------------------------
def contour_layers(field: np.ndarray, p: dict, ss: int):
    """(normal_alpha, index_alpha), each 0..1 at SS resolution."""
    s = field * float(p["levels"])

    # level index and distance to the nearest level
    k = np.rint(s)
    d = np.abs(s - k).astype(np.float32)

    # |grad s| (level change per pixel), central difference
    gx = np.empty_like(s)
    gy = np.empty_like(s)
    gx[:, 1:-1] = (s[:, 2:] - s[:, :-2]) * 0.5
    gx[:, 0] = s[:, 1] - s[:, 0]
    gx[:, -1] = s[:, -1] - s[:, -2]
    gy[1:-1, :] = (s[2:, :] - s[:-2, :]) * 0.5
    gy[0, :] = s[1, :] - s[0, :]
    gy[-1, :] = s[-1, :] - s[-2, :]
    grad = np.sqrt(gx * gx + gy * gy)
    del gx, gy, s

    np.maximum(grad, 1e-5, out=grad)
    dist = d / grad          # distance to the line in SS pixels
    del d

    # Crowding fade: as the line spacing (1/|grad|) shrinks, contours
    # merge into a grey smear. Below min_spacing fade the opacity
    # smoothly to zero so steep slopes stay sparse and no moiré
    # appears.
    ms = float(p["min_spacing"]) * ss
    if ms > 0:
        spacing = 1.0 / grad
        crowd = _smoothstep(np.clip((spacing - ms) / (1.8 * ms), 0.0, 1.0)).astype(np.float32)
        del spacing
    else:
        crowd = None
    del grad

    is_index = (np.mod(k, p["index_every"]) == 0)
    del k

    aa = 0.75  # smoothing band in SS pixels

    def band(width_final: float) -> np.ndarray:
        half = width_final * ss * 0.5
        t = (half + aa - dist) / (2.0 * aa)
        return np.clip(t, 0.0, 1.0).astype(np.float32)

    normal = band(p["line_w"])
    index = band(p["index_w"])

    a_norm = np.where(is_index, 0.0, normal).astype(np.float32)
    a_idx = np.where(is_index, index, 0.0).astype(np.float32)
    if crowd is not None:
        a_norm *= crowd
        a_idx *= crowd
    return a_norm, a_idx


# ----------------------------------------------------------------------------
# Kompozisyon maskesi
# ----------------------------------------------------------------------------
def composition_mask(h: int, w: int, p: dict, rng: np.random.Generator) -> np.ndarray:
    aspect = w / h
    yy = (np.arange(h, dtype=np.float32) / h)[:, None]
    xx = (np.arange(w, dtype=np.float32) / w)[None, :]

    dx = (xx - p["cx"]) / p["rx"]
    dy = (yy - p["cy"]) / p["ry"]
    r = np.sqrt(dx * dx + dy * dy).astype(np.float32)
    del dx, dy

    # distort the edge with noise so it does not look like a perfect ellipse
    if p["mask_warp"] > 0:
        n = fbm(h, w, 3, 2.2, 2.0, 0.5, rng, aspect) - 0.5
        r += (n * (2.0 * p["mask_warp"] / max(p["rx"], p["ry"]))).astype(np.float32)
        del n

    inner = 1.0 - p["feather"]
    m = np.clip((1.0 - r) / max(p["feather"], 1e-3), 0.0, 1.0).astype(np.float32)
    m = _smoothstep(m)
    del r, inner

    # top edge guard (panel)
    tg = p["top_guard"]
    ts = max(p["top_soft"], 1e-3)
    guard = np.clip((yy - tg) / ts, 0.0, 1.0).astype(np.float32)
    guard = _smoothstep(guard)
    m *= guard
    return m


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
def render(p: dict) -> Image.Image:
    W, H, ss = int(p["width"]), int(p["height"]), int(p["ss"])
    sw, sh = W * ss, H * ss

    rng = np.random.default_rng(int(p["seed"]))

    field = warped_field(sh, sw, p, rng)
    a_norm, a_idx = contour_layers(field, p, ss)
    del field

    mask = composition_mask(sh, sw, p, rng)

    # line intensity (0..1 linear light)
    sig = a_norm * float(p["line_a"]) + a_idx * float(p["index_a"])
    del a_norm, a_idx
    sig *= mask
    del mask

    # SS -> final resolution (2x2 box average)
    sig = sig.reshape(H, ss, W, ss).mean(axis=(1, 3))

    v = sig * 255.0

    # very light triangular dither only where there is signal (breaks banding);
    # pure black stays exactly 0.
    if p["dither"] > 0:
        d_rng = np.random.default_rng(int(p["seed"]) + 977)
        tri = (d_rng.random(v.shape, dtype=np.float32)
               - d_rng.random(v.shape, dtype=np.float32)) * float(p["dither"])
        tri *= (v > 0.02)
        v = v + tri

    v = np.clip(np.rint(v), 0, 255).astype(np.uint8)
    return Image.fromarray(v, mode="L").convert("RGB")


def main() -> None:
    ap = argparse.ArgumentParser(description="Iris topographic wallpaper generator")
    ap.add_argument("output", nargs="?",
                    default="wallpaper/iris-topo-2880x1800.png",
                    help="output PNG path")
    for key, val in DEFAULTS.items():
        ap.add_argument(f"--{key.replace('_', '-')}",
                        type=type(val), default=val, dest=key)
    ap.add_argument("--preview", default=None,
                    help="also write a downscaled preview to this path")
    ap.add_argument("--preview-width", type=int, default=1440)
    args = ap.parse_args()

    p = {k: getattr(args, k) for k in DEFAULTS}
    img = render(p)

    out = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out, "PNG", optimize=True)
    print(f"written: {out}  ({img.width}x{img.height})")

    if args.preview:
        pw = args.preview_width
        ph = round(img.height * pw / img.width)
        prev = img.resize((pw, ph), Image.LANCZOS)
        pout = os.path.abspath(args.preview)
        os.makedirs(os.path.dirname(pout), exist_ok=True)
        prev.save(pout, "PNG")
        print(f"preview: {pout}  ({pw}x{ph})")


if __name__ == "__main__":
    main()
