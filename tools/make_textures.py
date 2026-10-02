"""Makes the game's textures from math (no downloads needed).

Every texture tiles seamlessly. For each surface we write:
  <name>_albedo.jpg  the colors
  <name>_normal.png  tiny bumps for lighting
  <name>_rough.jpg   how shiny each spot is (white = dull)
Run:  python3 tools/make_textures.py   (needs numpy, scipy, pillow)
"""
import numpy as np
from PIL import Image
from scipy import ndimage

OUT = "assets/textures/"
rng = np.random.default_rng(7)


def noise(n, scale, octaves=5, persistence=0.5):
    """Tileable fractal noise in 0..1 (filtered random noise in frequency space)."""
    total = np.zeros((n, n))
    amp = 1.0
    for o in range(octaves):
        white = rng.standard_normal((n, n))
        f = np.fft.fftfreq(n)
        fx, fy = np.meshgrid(f, f)
        r = np.sqrt(fx ** 2 + fy ** 2)
        cutoff = (2 ** o) / scale
        filt = np.exp(-(r / cutoff) ** 2)
        layer = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
        layer = (layer - layer.mean()) / (layer.std() + 1e-9)
        total += layer * amp
        amp *= persistence
    total = (total - total.min()) / (total.max() - total.min())
    return total


def cells(n, count, sharp=False):
    """Tileable Voronoi distance (for pebbles, cracks, rust spots)."""
    pts = rng.random((count, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n]
    best = np.full((n, n), 1e9)
    second = np.full((n, n), 1e9)
    for px, py in pts:
        dx = np.abs(xx - px); dx = np.minimum(dx, n - dx)
        dy = np.abs(yy - py); dy = np.minimum(dy, n - dy)
        d = np.sqrt(dx * dx + dy * dy)
        second = np.where(d < best, best, np.minimum(second, d))
        best = np.minimum(best, d)
    return best, second


def cracks(n, count, width=1.2):
    """Thin dark lines along Voronoi cell edges, broken up by noise."""
    a, b = cells(n, count)
    edge = np.clip(1.0 - (b - a) / width, 0, 1)
    mask = noise(n, 6, 3) > 0.55
    return edge * mask


def colorize(v, c0, c1):
    c0 = np.array(c0, float); c1 = np.array(c1, float)
    return c0 + (c1 - c0) * v[..., None]


def save(name, albedo, height, rough, strength=2.0):
    albedo = np.clip(albedo, 0, 1)
    Image.fromarray((albedo * 255).astype(np.uint8)).save(OUT + name + "_albedo.jpg", quality=88)
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8)).save(OUT + name + "_rough.jpg", quality=88)
    gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength * height.shape[0] / 256
    gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * strength * height.shape[0] / 256
    nrm = np.dstack([-gx, gy, np.ones_like(gx)])  # OpenGL style (Godot)
    nrm /= np.linalg.norm(nrm, axis=2, keepdims=True)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8)).save(OUT + name + "_normal.jpg", quality=92)
    print("made", name)


N = 1024

# --- Concrete wall: pale, blotchy, with dark water streaks running down.
base = noise(N, 40)
fine = noise(N, 2, 3)
streak = ndimage.uniform_filter1d(noise(N, 30, 2), 260, axis=0, mode="wrap")
streak = np.clip((streak - 0.52) * 4, 0, 1) * 0.7
pits = (noise(N, 1.5, 2) > 0.78).astype(float)
v = 0.55 + 0.25 * base + 0.1 * fine - 0.35 * streak - 0.25 * pits
alb = colorize(np.clip(v, 0, 1), (0.18, 0.18, 0.17), (0.72, 0.71, 0.67))
save("concrete_wall", alb, base * 0.3 + fine * 0.5 - pits * 0.6, 0.85 + 0.1 * fine - 0.2 * streak)

# --- Concrete floor: darker, stained, cracked.
base = noise(N, 60); fine = noise(N, 2, 3)
stain = ndimage.gaussian_filter((noise(N, 80, 3) > 0.6).astype(float), 18, mode="wrap") * 0.6
cr = cracks(N, 26)
v = 0.45 + 0.25 * base + 0.12 * fine - 0.25 * stain - 0.5 * cr
alb = colorize(np.clip(v, 0, 1), (0.10, 0.10, 0.09), (0.55, 0.54, 0.5))
save("concrete_floor", alb, fine * 0.6 + base * 0.2 - cr, 0.8 + 0.15 * fine - 0.3 * stain)

# --- Cinder block tunnel wall: rows of blocks with mortar, grime near the bottom of each block.
yy, xx = np.mgrid[0:N, 0:N]
bh, bw = N / 8, N / 4
row = (yy // bh).astype(int)
xo = (xx + (row % 2) * bw / 2) % bw
yo = yy % bh
mortar = ((xo < 6) | (yo < 6)).astype(float)
mortar = ndimage.gaussian_filter(mortar, 1.2, mode="wrap")
block_tone = rng.random(64)[(row * 7 + ((xx + (row % 2) * bw / 2) // bw).astype(int)) % 64]
fine = noise(N, 1.5, 3); grime = noise(N, 30, 4)
v = 0.5 + 0.12 * block_tone + 0.2 * fine - 0.35 * mortar - 0.3 * np.clip(grime - 0.5, 0, 1) * 2
alb = colorize(np.clip(v, 0, 1), (0.12, 0.13, 0.12), (0.62, 0.62, 0.58))
save("cinder_block", alb, fine * 0.4 - mortar * 1.0, 0.9 - 0.1 * mortar)

# --- Raw rock (cell, shaft).
big = noise(N, 120, 6, 0.6); fine = noise(N, 3, 4)
cr = cracks(N, 40, 2)
v = 0.35 + 0.35 * big + 0.15 * fine - 0.4 * cr
alb = colorize(np.clip(v, 0, 1), (0.08, 0.08, 0.07), (0.45, 0.43, 0.38))
save("rock", alb, big + fine * 0.4 - cr, 0.9 + 0.05 * fine)

# --- Dirt and gravel ground (outside).
n512 = 1024
a, b = cells(n512, 900)
pebble = np.clip(1 - a / 9, 0, 1) * (noise(n512, 4, 2) > 0.45)
dirt = noise(n512, 50); fine = noise(n512, 1.5, 3); leaves = noise(n512, 6, 3) > 0.7
v = 0.35 + 0.25 * dirt + 0.1 * fine + 0.25 * pebble
alb = colorize(np.clip(v, 0, 1), (0.07, 0.06, 0.045), (0.42, 0.38, 0.32))
alb = np.where(leaves[..., None], alb * np.array([0.9, 0.75, 0.5]), alb)
save("ground", alb, dirt * 0.3 + pebble * 0.8 + fine * 0.3, 0.95 - 0.2 * pebble)

# --- Asphalt road: dark with light stones, cracks.
n = 1024
fine = noise(n, 1.2, 2); spk = (noise(n, 0.8, 1) > 0.8).astype(float); cr = cracks(n, 20, 1.5)
big = noise(n, 90, 3)
v = 0.25 + 0.12 * big + 0.15 * fine + 0.3 * spk - 0.3 * cr
alb = colorize(np.clip(v, 0, 1), (0.03, 0.03, 0.035), (0.4, 0.4, 0.41))
save("asphalt", alb, fine * 0.5 + spk * 0.3 - cr, 0.85 + 0.1 * fine)

# --- Rusty painted metal (doors, elevator, generator, consoles).
n = 1024
paint = noise(n, 30, 4); rust_mask = noise(n, 150, 6, 0.6) ; fine = noise(n, 1.5, 3)
rust = np.clip((rust_mask - 0.6) * 5, 0, 1)
paint_col = colorize(0.6 + 0.4 * paint, (0.14, 0.18, 0.16), (0.28, 0.33, 0.29))
rust_col = colorize(fine, (0.16, 0.08, 0.04), (0.38, 0.22, 0.11))
alb = paint_col * (1 - rust[..., None]) + rust_col * rust[..., None]
save("rusty_metal", alb, fine * 0.3 * rust + paint * 0.1 - rust * 0.2, 0.45 + 0.5 * rust)
Image.fromarray((np.clip(0.7 * (1 - rust), 0, 1) * 255).astype(np.uint8)).save(OUT + "rusty_metal_metal.jpg", quality=88)

# --- Wood planks (desks, crates, shed).
n = 1024
yy, xx = np.mgrid[0:n, 0:n]
plank = (xx // (n / 6)).astype(int)
offs = rng.random(16)[plank % 16]
grain = noise(n, 8, 3)
grain = ndimage.uniform_filter1d(grain, 60, axis=0, mode="wrap")
rings = np.sin((grain * 40 + offs * 10)) * 0.5 + 0.5
gap = ((xx % (n / 6)) < 4).astype(float)
v = 0.45 + 0.2 * rings + 0.15 * offs - 0.5 * gap
alb = colorize(np.clip(v, 0, 1), (0.08, 0.05, 0.03), (0.5, 0.35, 0.2))
save("wood", alb, rings * 0.3 - gap, 0.75 + 0.1 * rings)

# --- Office floor: old checkered linoleum tiles, worn and dirty.
n = 1024
yy, xx = np.mgrid[0:n, 0:n]
t = n / 4
checker = (((xx // t) + (yy // t)) % 2).astype(float)
seam = (((xx % t) < 3) | ((yy % t) < 3)).astype(float)
wear = noise(n, 60, 4); fine = noise(n, 2, 3)
light = colorize(0.7 + 0.3 * fine, (0.42, 0.40, 0.33), (0.62, 0.60, 0.50))
dark = colorize(0.7 + 0.3 * fine, (0.10, 0.12, 0.11), (0.18, 0.20, 0.18))
alb = light * checker[..., None] + dark * (1 - checker[..., None])
alb *= (0.7 + 0.3 * wear)[..., None]
alb *= (1 - 0.5 * seam)[..., None]
save("lino_floor", alb, -seam + fine * 0.15, 0.55 + 0.35 * wear)

# --- Painted plaster wall (office), plain; the shader makes it two-tone.
n = 1024
fine = noise(n, 2, 3); blot = noise(n, 50, 4); chip = noise(n, 6, 3) > 0.74
v = 0.75 + 0.1 * fine + 0.1 * blot
alb = np.dstack([v, v, v]) * (1 - 0.55 * chip[..., None])
save("plaster", alb, fine * 0.3 - chip * 0.6, 0.8 + 0.1 * chip)

# --- Chain-link fence (alpha cutout).
n = 512
yy, xx = np.mgrid[0:n, 0:n]
cell = n / 8
d1 = np.abs(((xx + yy) % cell) - cell / 2)
d2 = np.abs(((xx - yy) % cell) - cell / 2)
wire = np.clip(1 - np.minimum(d1, d2) / 2.2, 0, 1)
fine = noise(n, 2, 2)
col = colorize(fine, (0.25, 0.25, 0.24), (0.55, 0.53, 0.5))
rgba = np.dstack([col, wire[..., None]])
Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT + "chainlink_albedo.png", optimize=True)
print("made chainlink")

# --- The Long Man's skin: pale and grayish, with dark veins, bruises and grime.
n = 1024
base = noise(n, 60, 4); fine = noise(n, 1.5, 3)
veins = cracks(n, 60, 1.6) + 0.6 * cracks(n, 140, 1.0)
veins = ndimage.gaussian_filter(np.clip(veins, 0, 1), 1.0, mode="wrap")
bruise = np.clip((noise(n, 90, 4) - 0.6) * 3, 0, 1)
grime = np.clip((noise(n, 40, 5) - 0.55) * 2.5, 0, 1)
skin = colorize(0.75 + 0.25 * base, (0.55, 0.53, 0.48), (0.78, 0.76, 0.70))
skin = skin * (1 - 0.55 * veins[..., None]) + np.array([0.22, 0.24, 0.36]) * 0.55 * veins[..., None]   # bluish veins
skin = skin * (1 - 0.35 * bruise[..., None]) + np.array([0.35, 0.22, 0.32]) * 0.35 * bruise[..., None]  # purple bruises
skin = skin * (1 - 0.4 * grime[..., None])
save("longman_skin", skin * (0.92 + 0.08 * fine[..., None]), fine * 0.4 - veins * 0.5 + base * 0.2, 0.55 + 0.3 * grime)
