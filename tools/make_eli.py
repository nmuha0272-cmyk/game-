"""Eli (the Son), detailed, in a T-pose, for Godot:
  "2015 young man age 21, lean, messy dark hair, light stubble, worn brown
   canvas jacket over gray hoodie, jeans, sneakers, small backpack,
   realistic game character, full body, T-pose"

Makes:
  assets/models/eli_tpose.obj (+ .mtl) ... the model (one file, many materials)
  assets/textures/eli_*.jpg .............. fabric / skin textures
  assets/materials/eli/*.tres ............ Godot materials (textures mapped
                                           "triplanar", so no UVs are needed)
  scenes/characters/eli_tpose.tscn ....... a scene that shows him, turning
Run:  python3 tools/make_eli.py   (needs numpy scikit-image trimesh fast-simplification pillow)
"""
import math, os, sys
import numpy as np
import trimesh
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sculpt import *

rng = np.random.default_rng(21)
TEX = "assets/textures/"
MAT = "assets/materials/eli/"


# ======================================================================= textures
def fbm(n, scale, octaves=5, seed=0):
    r = np.random.default_rng(seed)
    out = np.zeros((n, n))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        f = scale * (2 ** o)
        g = r.random((int(f) + 2, int(f) + 2))
        xs = np.linspace(0, f, n, endpoint=False)
        i = xs.astype(int); t = xs - i; t = t * t * (3 - 2 * t)
        a = g[i][:, i] * (1 - t)[None, :] + g[i][:, i + 1] * t[None, :]
        b = g[i + 1][:, i] * (1 - t)[None, :] + g[i + 1][:, i + 1] * t[None, :]
        out += amp * (a * (1 - t)[:, None] + b * t[:, None])
        total += amp; amp *= 0.5
    return out / total


def save_tex(name, albedo, height, strength=3.0):
    Image.fromarray((np.clip(albedo, 0, 1) * 255).astype(np.uint8)).save(f"{TEX}eli_{name}_albedo.jpg", quality=92)
    gy, gx = np.gradient(height)
    nrm = np.stack([-gx * strength, -gy * strength, np.ones_like(height)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8)).save(f"{TEX}eli_{name}_normal.jpg", quality=92)


def tint(v, c0, c1):
    return np.array(c0)[None, None] * (1 - v[..., None]) + np.array(c1)[None, None] * v[..., None]


def textures():
    n = 512
    y, x = np.mgrid[0:n, 0:n] / n
    # Canvas: a plain weave, worn lighter in patches, a few dark stains.
    weave = (np.sin(x * 2 * math.pi * 40) * np.sin(y * 2 * math.pi * 40)) * 0.5 + 0.5
    wear = fbm(n, 4, seed=1); grime = fbm(n, 6, seed=2)
    v = 0.55 * weave + 0.45 * wear
    alb = tint(v, (0.25, 0.15, 0.08), (0.46, 0.31, 0.18))
    alb *= (1 - 0.35 * np.clip((grime - 0.62) * 4, 0, 1))[..., None]
    alb += 0.12 * np.clip((wear - 0.7) * 4, 0, 1)[..., None]          # rubbed pale
    save_tex("canvas", alb, weave * 0.6 + wear * 0.4, 4.0)
    # Hoodie knit: soft vertical ribs, fluffy noise.
    rib = np.abs(np.sin(x * 2 * math.pi * 48)) ** 0.6
    fluff = fbm(n, 32, 3, seed=3)
    v = 0.5 * rib + 0.5 * fluff
    save_tex("knit", tint(v, (0.36, 0.36, 0.37), (0.55, 0.55, 0.56)), rib * 0.5 + fluff * 0.5, 2.5)
    # Denim: diagonal twill, faded, with white threads.
    tw = np.sin((x * 1.0 + y * 1.0) * 2 * math.pi * 48) * 0.5 + 0.5
    fade = fbm(n, 3, seed=4); speck = (rng.random((n, n)) > 0.985).astype(float)
    v = 0.6 * tw + 0.4 * fade
    alb = tint(v, (0.09, 0.14, 0.25), (0.26, 0.35, 0.52)) + 0.25 * speck[..., None]
    save_tex("denim", alb, tw, 3.0)
    # Skin: soft blotches and tiny pores.
    blot = fbm(n, 6, seed=5); pores = fbm(n, 90, 2, seed=6)
    alb = tint(blot, (0.74, 0.55, 0.44), (0.84, 0.66, 0.54)) * (0.96 + 0.04 * pores)[..., None]
    save_tex("skin", alb, pores, 1.5)
    # Stubble: dark dots on skin.
    dots = (rng.random((n, n)) > 0.86).astype(float)            # LIGHT stubble: few short dark hairs
    dots = np.clip(dots * 0.7 + fbm(n, 60, 2, seed=7) * 0.15, 0, 1)
    save_tex("stubble", tint(dots, (0.76, 0.58, 0.47), (0.22, 0.17, 0.14)), dots, 0.8)
    # Backpack nylon: tight ripstop grid.
    grid = np.maximum(np.abs(np.sin(x * 2 * math.pi * 40)) ** 30, np.abs(np.sin(y * 2 * math.pi * 40)) ** 30)
    save_tex("nylon", tint(grid * 0.6 + fbm(n, 8, seed=8) * 0.4, (0.08, 0.085, 0.09), (0.2, 0.21, 0.22)), grid, 2.0)


# ======================================================================= the model
# Meters, Y up, he faces -Z. T-pose: arms straight out along X.
H = 1.78
SH_Y = 1.43        # shoulder height
WRIST_X = 0.71


def head_parts():
    hc = (0.0, 1.655, -0.005)
    hx, hy, hz = hc
    skin = [capsule((0, 1.47, 0.0), (0, 1.58, -0.005), 0.052),                         # neck
            ellipsoid(hc, (0.079, 0.108, 0.097)),                                       # skull
            ellipsoid((hx, hy - 0.058, hz - 0.03), (0.063, 0.058, 0.07)),                # jaw
            ellipsoid((hx, hy - 0.09, hz - 0.055), (0.03, 0.022, 0.03)),                 # chin
            ellipsoid((hx - 0.045, hy - 0.005, hz - 0.065), (0.022, 0.018, 0.025)),      # cheekbones
            ellipsoid((hx + 0.045, hy - 0.005, hz - 0.065), (0.022, 0.018, 0.025)),
            capsule((hx, hy + 0.025, hz - 0.093), (hx, hy - 0.02, hz - 0.108), 0.011),   # nose bridge
            ellipsoid((hx, hy - 0.025, hz - 0.108), (0.017, 0.014, 0.015)),               # nose tip
            ellipsoid((hx - 0.011, hy - 0.03, hz - 0.1), (0.009, 0.007, 0.008)),          # nostrils
            ellipsoid((hx + 0.011, hy - 0.03, hz - 0.1), (0.009, 0.007, 0.008)),
            capsule((hx - 0.04, hy + 0.035, hz - 0.088), (hx + 0.04, hy + 0.035, hz - 0.088), 0.012),  # brow ridge
            ellipsoid((hx - 0.08, hy + 0.0, hz + 0.008), (0.012, 0.03, 0.019)),           # ears
            ellipsoid((hx + 0.08, hy + 0.0, hz + 0.008), (0.012, 0.03, 0.019))]
    eye_sockets = [ellipsoid((hx - 0.031, hy + 0.012, hz - 0.095), (0.018, 0.011, 0.014)),
                   ellipsoid((hx + 0.031, hy + 0.012, hz - 0.095), (0.018, 0.011, 0.014))]
    skin_shape = cut(blend(skin, 0.018), union(eye_sockets))
    eyes = [sphere((hx - 0.031, hy + 0.011, hz - 0.08), 0.0105), sphere((hx + 0.031, hy + 0.011, hz - 0.08), 0.0105)]
    iris = [sphere((hx - 0.031, hy + 0.011, hz - 0.0885), 0.0042), sphere((hx + 0.031, hy + 0.011, hz - 0.0885), 0.0042)]
    lids = [capsule((hx - 0.044, hy + 0.019, hz - 0.087), (hx - 0.018, hy + 0.02, hz - 0.091), 0.0035),
            capsule((hx + 0.044, hy + 0.019, hz - 0.087), (hx + 0.018, hy + 0.02, hz - 0.091), 0.0035)]
    brows = [capsule((hx - 0.05, hy + 0.028, hz - 0.093), (hx - 0.014, hy + 0.032, hz - 0.104), 0.0042),
             capsule((hx + 0.05, hy + 0.028, hz - 0.093), (hx + 0.014, hy + 0.032, hz - 0.104), 0.0042)]
    lips = [capsule((hx - 0.019, hy - 0.06, hz - 0.1015), (hx + 0.019, hy - 0.06, hz - 0.1015), 0.003),
            capsule((hx - 0.015, hy - 0.0655, hz - 0.0995), (hx + 0.015, hy - 0.0655, hz - 0.0995), 0.0036)]
    # Light stubble: a thin shell over the jaw, chin and upper lip.
    jaw_shell = blend([ellipsoid((hx, hy - 0.058, hz - 0.03), (0.0642, 0.0592, 0.0712)),
                       ellipsoid((hx, hy - 0.09, hz - 0.055), (0.0312, 0.0232, 0.0312)),
                       ellipsoid((hx, hy - 0.045, hz - 0.098), (0.024, 0.011, 0.012))], 0.015)
    stubble_zone = box((hx, hy - 0.072, hz - 0.03), (0.1, 0.05, 0.1))
    stubble = cut(cut(jaw_shell, ellipsoid((hx, hy - 0.063, hz - 0.104), (0.019, 0.0065, 0.012))),  # keep the lips clear
                  cut(box((0, 0, 0), (5, 5, 5)), stubble_zone))                                 # only low on the face
    # Messy dark hair: a cap plus clumps sticking out in all directions.
    hair = [bumpy(ellipsoid((hx, hy + 0.035, hz + 0.008), (0.088, 0.083, 0.1)), 0.012, 50, 3)]
    for i in range(26):
        a = rng.uniform(0, 2 * math.pi); up = rng.uniform(0.15, 0.95)
        dx, dz = math.cos(a) * math.sqrt(1 - up * up), math.sin(a) * math.sqrt(1 - up * up)
        root = (hx + dx * 0.075, hy + 0.04 + up * 0.07, hz + dz * 0.085)
        if dz < -0.4 and up < 0.5:
            continue  # not over the eyes
        tip = (root[0] + dx * 0.04 + rng.uniform(-0.015, 0.015), root[1] + rng.uniform(-0.02, 0.012),
               root[2] + dz * 0.04 - (0.03 if dz < 0 else -0.01))
        hair.append(capsule(root, tip, 0.016, 0.004))
    for i in range(6):  # a messy fringe falling on the forehead
        x0 = -0.052 + i * 0.019 + (0.008 if i >= 3 else 0)
        hair.append(capsule((x0, hy + 0.09, hz - 0.06), (x0 + rng.uniform(-0.02, 0.02), hy + 0.05, hz - 0.098), 0.011, 0.003))
    hair_shape = cut(blend(hair, 0.012), union([box((hx, hy - 0.035, hz - 0.08), (0.12, 0.06, 0.07)),
                                                ellipsoid((hx, hy + 0.0, hz - 0.13), (0.07, 0.045, 0.06))]))
    return skin_shape, eyes, iris, lids, brows, lips, stubble, hair_shape


def torso_parts():
    hoodie = [box((0, 1.22, 0.0), (0.165, 0.26, 0.098), 0.07), box((0, 0.97, 0.0), (0.155, 0.07, 0.095), 0.06),
              capsule((-0.17, 1.42, 0.0), (0.17, 1.42, 0.0), 0.068)]
    # The hood is DOWN: bunched up behind the neck.
    hood = blend([ellipsoid((0, 1.485, 0.075), (0.105, 0.048, 0.055)),           # a soft roll of fabric
                  ellipsoid((-0.075, 1.495, 0.035), (0.045, 0.045, 0.055)),
                  ellipsoid((0.075, 1.495, 0.035), (0.045, 0.045, 0.055))], 0.02)
    strings = [capsule((-0.03, 1.47, -0.09), (-0.036, 1.3, -0.105), 0.0035), capsule((0.03, 1.47, -0.09), (0.036, 1.32, -0.105), 0.0035)]
    aglets = [capsule((-0.036, 1.3, -0.105), (-0.037, 1.28, -0.106), 0.0045), capsule((0.036, 1.32, -0.105), (0.037, 1.3, -0.106), 0.0045)]
    # The jacket: open at the front (you see the hoodie), a collar, pockets, snaps.
    jacket_body = blend([box((0, 1.21, 0.0), (0.18, 0.27, 0.11), 0.075), box((0, 0.94, 0.0), (0.17, 0.06, 0.105), 0.06),
                         capsule((-0.18, 1.425, 0.0), (0.18, 1.425, 0.0), 0.078)], 0.03)
    opening = box((0, 1.2, -0.14), (0.055, 0.32, 0.06), 0.02)
    jacket = bumpy(cut(jacket_body, opening), 0.003, 40, 5)
    collar = torus_y((0, 1.497, 0.008), 0.074, 0.014, z_scale=0.85)
    pockets = [box((-0.1, 1.27, -0.112), (0.045, 0.042, 0.008), 0.006), box((0.1, 1.27, -0.112), (0.045, 0.042, 0.008), 0.006),
               box((-0.11, 1.0, -0.106), (0.05, 0.055, 0.008), 0.008), box((0.11, 1.0, -0.106), (0.05, 0.055, 0.008), 0.008)]
    flaps = [box((-0.1, 1.31, -0.12), (0.048, 0.014, 0.007), 0.004), box((0.1, 1.31, -0.12), (0.048, 0.014, 0.007), 0.004)]
    seams = [capsule((-0.18, 1.45, -0.01), (-0.17, 0.9, -0.03), 0.0025), capsule((0.18, 1.45, -0.01), (0.17, 0.9, -0.03), 0.0025),
             capsule((-0.17, 0.9, -0.105), (0.17, 0.9, -0.105), 0.003)]
    snaps = [sphere((x, y, -0.127), 0.0055) for x in (-0.1, 0.1) for y in (1.31,)] + \
            [sphere((s * 0.062, y, -0.112), 0.006) for s in (-1, 1) for y in (1.36, 1.2, 1.04)]
    # A small backpack, with straps over the shoulders.
    pack = [box((0, 1.2, 0.17), (0.13, 0.17, 0.06), 0.045), box((0, 1.12, 0.235), (0.1, 0.08, 0.025), 0.02)]
    straps = [capsule((-0.1, 1.47, 0.04), (-0.12, 1.47, -0.07), 0.016), capsule((-0.12, 1.47, -0.07), (-0.13, 1.1, -0.12), 0.016),
              capsule((0.1, 1.47, 0.04), (0.12, 1.47, -0.07), 0.016), capsule((0.12, 1.47, -0.07), (0.13, 1.1, -0.12), 0.016),
              capsule((-0.13, 1.1, -0.12), (-0.14, 1.04, 0.1), 0.012), capsule((0.13, 1.1, -0.12), (0.14, 1.04, 0.1), 0.012)]
    handle = cut(torus_y((0, 1.37, 0.17), 0.03, 0.007), box((0, 1.35, 0.17), (0.05, 0.02, 0.05)))
    zips = [capsule((-0.1, 1.2, 0.262), (0.1, 1.2, 0.262), 0.003), capsule((-0.12, 1.34, 0.17), (0.12, 1.34, 0.17), 0.003)]
    return dict(hoodie=blend(hoodie + [hood], 0.03), strings=union(strings), aglets=union(aglets), jacket=jacket,
                collar=collar, pocket=union(pockets + flaps), seam=union(seams), metal=union(snaps + zips),
                pack=blend(pack, 0.02), straps=union(straps + [handle]))


def arm_parts(x):
    sh = (0.2 * x, SH_Y, 0.0); el = (0.46 * x, SH_Y, 0.008); wr = (WRIST_X * x, SH_Y - 0.01, 0.0)
    sleeve = bumpy(blend([capsule(sh, el, 0.062, 0.054), capsule(el, (0.67 * x, SH_Y - 0.008, 0.0), 0.054, 0.05)], 0.03), 0.003, 40, 6)
    cuff = capsule((0.665 * x, SH_Y - 0.008, 0), (0.69 * x, SH_Y - 0.009, 0), 0.044)       # gray hoodie cuff peeking out
    # A hand, palm down, fingers together, thumb forward.
    palm = box((0.765 * x, SH_Y - 0.012, 0.0), (0.045, 0.014, 0.042), 0.012)
    fingers = [capsule((0.80 * x, SH_Y - 0.013, z), (0.875 * x, SH_Y - 0.02, z * 1.1), 0.0095, 0.008)
               for z in (-0.027, -0.009, 0.009, 0.027)]
    thumb = capsule((0.74 * x, SH_Y - 0.018, -0.035), (0.79 * x, SH_Y - 0.03, -0.07), 0.011, 0.009)
    wrist = capsule(wr, (0.73 * x, SH_Y - 0.012, 0.0), 0.033)
    return sleeve, cuff, blend([palm, wrist, thumb] + fingers, 0.012)


def leg_parts(x):
    hp = (0.095 * x, 0.95, 0.0); kn = (0.11 * x, 0.52, -0.012); an = (0.125 * x, 0.1, 0.0)
    jeans = bumpy(blend([capsule(hp, kn, 0.076, 0.058), capsule(kn, (an[0], 0.13, an[2]), 0.058, 0.05)], 0.03), 0.0035, 45, 7)
    hem = bumpy(torus_y((an[0], 0.135, an[2]), 0.047, 0.012), 0.004, 60, 8)              # bunched at the ankle
    seams = [capsule((hp[0] + 0.073 * x, 0.92, 0.0), (an[0] + 0.049 * x, 0.15, 0.0), 0.0015)]   # outer seam
    # Sneaker: charcoal upper, white sole, laces.
    upper = blend([box((an[0], 0.065, an[2] - 0.035), (0.045, 0.04, 0.11), 0.035), capsule((an[0], 0.06, an[2] + 0.02), (an[0], 0.12, an[2] + 0.01), 0.048)], 0.02)
    sole = box((an[0], 0.017, an[2] - 0.033), (0.05, 0.017, 0.125), 0.015)
    toe = box((an[0], 0.04, an[2] - 0.13), (0.045, 0.022, 0.02), 0.018)
    laces = [capsule((an[0] - 0.02, 0.1 - i * 0.012, an[2] - 0.04 - i * 0.022), (an[0] + 0.02, 0.1 - i * 0.012, an[2] - 0.04 - i * 0.022), 0.003) for i in range(4)]
    return jeans, hem, union(seams), upper, union([sole, toe]), union(laces)


def build():
    parts = {}
    def add(mat, m):
        if m is None:
            return
        # Drop any long stray "spike" triangles the mesh simplifier can leave behind.
        e = np.max(np.stack([np.linalg.norm(m.vertices[m.faces[:, i]] - m.vertices[m.faces[:, (i + 1) % 3]], axis=1)
                             for i in range(3)]), axis=0)
        m.update_faces(e < 0.15)  # (a safety net: real spikes are much longer)
        m.remove_unreferenced_vertices()
        parts.setdefault(mat, []).append(m)
    skin, eyes, iris, lids, brows, lips, stubble, hair = head_parts()
    hlo, hhi = (-0.11, 1.42, -0.13), (0.11, 1.80, 0.12)
    add("skin", mesh(skin, hlo, hhi, 0.003, 27000))
    add("stubble", mesh(stubble, hlo, hhi, 0.002, 7500, smooth=1))
    add("hair", mesh(hair, hlo, hhi, 0.003, 21000))
    add("hair", mesh(union(brows), hlo, hhi, 0.002, 1800, smooth=0))
    add("skin", mesh(union(lids), hlo, hhi, 0.002, 1500, smooth=0))
    add("eye_white", mesh(union(eyes), hlo, hhi, 0.002, 2400, smooth=0))
    add("iris", mesh(union(iris), hlo, hhi, 0.0015, 900, smooth=0))
    add("lips", mesh(union(lips), hlo, hhi, 0.002, 1500, smooth=0))
    t = torso_parts()
    blo, bhi = (-0.27, 0.82, -0.17), (0.27, 1.6, 0.29)
    add("hoodie", mesh(t["hoodie"], blo, bhi, 0.006, 18000))
    add("hoodie", mesh(t["strings"], blo, bhi, 0.002, 1800, smooth=0))
    add("metal", mesh(t["aglets"], blo, bhi, 0.002, 600, smooth=0))
    add("jacket", mesh(t["jacket"], blo, bhi, 0.006, 27000))
    add("collar", mesh(t["collar"], blo, bhi, 0.004, 6000))
    add("jacket", mesh(t["pocket"], blo, bhi, 0.003, 4500, smooth=0))
    add("seam", mesh(t["seam"], blo, bhi, 0.002, 3600, smooth=0))
    add("metal", mesh(t["metal"], blo, bhi, 0.002, 3000, smooth=0))
    add("pack", mesh(t["pack"], blo, bhi, 0.005, 9000))
    add("straps", mesh(t["straps"], blo, bhi, 0.004, 7500))
    for x in (-1, 1):
        sleeve, cuff, hand = arm_parts(x)
        lo = (min(0.13 * x, 0.92 * x), SH_Y - 0.1, -0.11); hi = (max(0.13 * x, 0.92 * x), SH_Y + 0.1, 0.11)
        add("jacket", mesh(sleeve, lo, hi, 0.005, 12000))
        add("hoodie", mesh(cuff, lo, hi, 0.004, 2400))
        add("skin", mesh(hand, lo, hi, 0.003, 9000))
        jeans, hem, seams, upper, sole, laces = leg_parts(x)
        lo = (0.095 * x - 0.13, 0.0, -0.18); hi = (0.095 * x + 0.13, 1.02, 0.12)
        add("jeans", mesh(jeans, lo, hi, 0.006, 15000))
        add("jeans", mesh(hem, lo, hi, 0.004, 3000))
        add("seam_denim", mesh(seams, lo, hi, 0.002, 1800, smooth=0))
        add("sneaker", mesh(upper, lo, hi, 0.004, 7500))
        add("sole", mesh(sole, lo, hi, 0.004, 4500))
        add("laces", mesh(laces, lo, hi, 0.0018, 1500, smooth=0))
    return parts


# Material name -> (color, texture or None, roughness)
MATERIALS = [
    ("skin", (0.80, 0.62, 0.50), "skin", 0.6), ("stubble", (0.42, 0.33, 0.28), "stubble", 0.8),
    ("hair", (0.05, 0.04, 0.035), None, 0.85), ("eye_white", (0.92, 0.9, 0.86), None, 0.2),
    ("iris", (0.16, 0.10, 0.06), None, 0.1), ("lips", (0.66, 0.46, 0.42), None, 0.55),
    ("hoodie", (0.47, 0.47, 0.48), "knit", 0.95), ("jacket", (0.42, 0.28, 0.16), "canvas", 0.9),
    ("collar", (0.24, 0.15, 0.09), "canvas", 0.95), ("seam", (0.20, 0.12, 0.07), None, 0.9),
    ("metal", (0.55, 0.52, 0.45), None, 0.35), ("pack", (0.13, 0.13, 0.14), "nylon", 0.7),
    ("straps", (0.07, 0.07, 0.075), "nylon", 0.8), ("jeans", (0.20, 0.27, 0.42), "denim", 0.9),
    ("seam_denim", (0.50, 0.40, 0.24), None, 0.8), ("sneaker", (0.20, 0.20, 0.22), None, 0.75),
    ("sole", (0.90, 0.89, 0.86), None, 0.7), ("laces", (0.88, 0.88, 0.86), None, 0.8),
]


def write_materials():
    for name, color, tex, rough in MATERIALS:
        lines = ['[gd_resource type="StandardMaterial3D" load_steps=%d format=3]' % (3 if tex else 1), ""]
        if tex:
            lines += [f'[ext_resource type="Texture2D" path="res://{TEX}eli_{tex}_albedo.jpg" id="1"]',
                      f'[ext_resource type="Texture2D" path="res://{TEX}eli_{tex}_normal.jpg" id="2"]', ""]
        lines += ["[resource]", f'resource_name = "eli_{name}"']
        if tex:  # the texture has the color in it
            lines += ['albedo_texture = ExtResource("1")', "normal_enabled = true", 'normal_texture = ExtResource("2")',
                      "uv1_triplanar = true", "uv1_scale = Vector3(%d, %d, %d)" % ((3, 3, 3) if tex in ("skin", "stubble") else (4, 4, 4))]
        else:
            lines.append("albedo_color = Color(%.3f, %.3f, %.3f, 1)" % color)
        lines.append(f"roughness = {rough}")
        if name == "metal":
            lines.append("metallic = 0.8")
        open(f"{MAT}{name}.tres", "w").write("\n".join(lines) + "\n")


def write_scene():
    n = len(MATERIALS)
    ext = [f'[ext_resource type="Mesh" path="res://assets/models/eli_tpose.obj" id="mesh"]',
           f'[ext_resource type="Script" path="res://scripts/characters/turntable.gd" id="spin"]']
    ext += [f'[ext_resource type="Material" path="res://{MAT}{name}.tres" id="m{i}"]' for i, (name, *_) in enumerate(MATERIALS)]
    over = "\n".join(f'surface_material_override/{i} = ExtResource("m{i}")' for i in range(n))
    scene = f"""[gd_scene load_steps={n + 4} format=3]

{chr(10).join(ext)}

[sub_resource type="Environment" id="env"]
background_mode = 1
background_color = Color(0.06, 0.06, 0.07, 1)
ambient_light_source = 2
ambient_light_color = Color(0.35, 0.36, 0.4, 1)
ambient_light_energy = 0.6
tonemap_mode = 2
ssao_enabled = true
volumetric_fog_density = 0.0
fog_density = 0.0

[sub_resource type="PlaneMesh" id="floor"]
size = Vector2(6, 6)

[sub_resource type="StandardMaterial3D" id="floormat"]
albedo_color = Color(0.12, 0.12, 0.13, 1)
roughness = 0.9

[node name="EliTPose" type="Node3D"]

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")

[node name="Eli" type="MeshInstance3D" parent="."]
mesh = ExtResource("mesh")
script = ExtResource("spin")
{over}

[node name="Floor" type="MeshInstance3D" parent="."]
mesh = SubResource("floor")
surface_material_override/0 = SubResource("floormat")

[node name="KeyLight" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866, -0.25, 0.433, 0, 0.866, 0.5, -0.5, -0.433, 0.75, 0, 3, 0)
light_energy = 1.4
shadow_enabled = true

[node name="FrontLight" type="OmniLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.6, 1.9, -2.2)
light_color = Color(1, 0.94, 0.86, 1)
light_energy = 1.6
omni_range = 6.0

[node name="RimLight" type="OmniLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.2, 2.0, 1.5)
light_color = Color(0.7, 0.8, 1, 1)
light_energy = 1.5
omni_range = 5.0

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.995, 0.1, 0, -0.1, 0.995, 0, 1.05, -3.1)
current = true
fov = 45.0
"""
    # (camera looks along +z at him: he faces -z)
    scene = scene.replace("Transform3D(1, 0, 0, 0, 0.995, 0.1, 0, -0.1, 0.995, 0, 1.05, -3.1)",
                          "Transform3D(-1, 0, 0, 0, 0.995, -0.1, 0, -0.1, -0.995, 0, 1.05, -3.1)")
    os.makedirs("scenes/characters", exist_ok=True)
    open("scenes/characters/eli_tpose.tscn", "w").write(scene)
    os.makedirs("scripts/characters", exist_ok=True)
    open("scripts/characters/turntable.gd", "w").write(
        "extends Node3D\n## Slowly turns the model around, so you can see it from every side.\n\n"
        "@export var degrees_per_second := 20.0\n\n\nfunc _process(delta: float) -> void:\n"
        "\trotate_y(deg_to_rad(degrees_per_second) * delta)\n")


if __name__ == "__main__":
    textures()
    parts = build()
    ordered = []
    for name, color, *_ in MATERIALS:
        ms = parts.get(name)
        ordered.append((name, color, trimesh.util.concatenate(ms) if ms else trimesh.creation.icosphere(radius=0.0001)))
    save_obj("assets/models/eli_tpose.obj", ordered)
    write_materials()
    write_scene()
    total = sum(len(m.faces) for _, _, m in ordered)
    print("eli_tpose.obj:", total, "triangles,", len(ordered), "materials")
