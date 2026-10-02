"""Sculpts the Long Man (Subject 7) as one smooth creature:
assets/models/long_man_body.obj (skin + torn gown) and long_man_head.obj
(the head is separate so it can twitch). Run: python3 tools/make_long_man.py"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from sculpt import *

OUT = "assets/models/"
SKIN = (0.50, 0.46, 0.42)
GOWN = (0.45, 0.50, 0.44)
HOLE = (0.03, 0.0, 0.0)

skin = []
# Legs: thin, knobby knees, long feet.
for x in (-1, 1):
    hip = (0.12 * x, 1.33, 0.0); knee = (0.13 * x, 0.66, -0.05); ankle = (0.13 * x, 0.08, 0.0)
    skin += [capsule(hip, knee, 0.072, 0.048), sphere(knee, 0.06), capsule(knee, ankle, 0.048, 0.032),
             sphere(ankle, 0.04), ellipsoid((0.13 * x, 0.035, -0.1), (0.05, 0.03, 0.17))]
    for t in range(4):
        skin.append(capsule((0.13 * x + (t - 1.5) * 0.022, 0.02, -0.22), (0.13 * x + (t - 1.5) * 0.026, 0.012, -0.3), 0.012))
# Hips, a hunched spine and a starved ribcage.
skin += [ellipsoid((0, 1.36, 0.0), (0.17, 0.1, 0.11)),
         capsule((0, 1.4, 0.0), (0, 1.85, -0.04), 0.1, 0.12),
         ellipsoid((0, 2.17, -0.12), (0.17, 0.25, 0.12)),
         capsule((0, 2.05, -0.06), (0, 2.45, -0.2), 0.13, 0.1)]
for k in range(6):
    y = 1.95 + k * 0.065
    for x in (-1, 1):
        skin.append(capsule((0.16 * x, y + 0.02, -0.07), (0.02 * x, y - 0.03, -0.235 + k * 0.003), 0.017))
for k in range(9):
    skin.append(sphere((0, 1.45 + k * 0.11, 0.06 + k * 0.004 - (0.12 if k > 5 else 0) * (k - 5) / 3), 0.03))  # spine knobs
# Shoulders, collarbones, neck.
for x in (-1, 1):
    skin += [sphere((0.27 * x, 2.47, -0.18), 0.06), capsule((0.27 * x, 2.47, -0.2), (0.02 * x, 2.45, -0.27), 0.022)]
skin += [capsule((0, 2.48, -0.22), (0, 2.82, -0.38), 0.05, 0.042),
         capsule((-0.03, 2.5, -0.25), (-0.02, 2.78, -0.4), 0.015), capsule((0.03, 2.5, -0.25), (0.02, 2.78, -0.4), 0.015)]
# Very long arms with knobby elbows, hands almost to the ground, spindly fingers.
for x in (-1, 1):
    sh = (0.28 * x, 2.46, -0.18); el = (0.34 * x, 1.66, -0.25); wr = (0.37 * x, 0.83, -0.3)
    skin += [capsule(sh, el, 0.05, 0.037), sphere(el, 0.045), capsule(el, wr, 0.037, 0.027),
             ellipsoid((0.375 * x, 0.73, -0.31), (0.026, 0.085, 0.045))]
    for f in range(4):
        fx = 0.375 * x + (f - 1.5) * 0.019
        length = 0.3 - abs(f - 1.5) * 0.04
        mid = (fx + (f - 1.5) * 0.008, 0.66 - length * 0.55, -0.32)
        tip = (fx + (f - 1.5) * 0.012, 0.66 - length, -0.35)
        skin += [capsule((fx, 0.66, -0.31), mid, 0.011, 0.009), capsule(mid, tip, 0.009, 0.005), sphere(mid, 0.012)]
    skin.append(capsule((0.36 * x, 0.72, -0.34), (0.36 * x - 0.01 * x, 0.55, -0.37), 0.01))  # thumb

# About 9 feet (2.75 m) tall, like the art guide says.
SCALE = (0.92, 0.885, 0.92)
# A ragged tear in his belly, just under the ribs, with his guts showing.
tear = bumpy(ellipsoid((0.01, 1.72, -0.145), (0.075, 0.115, 0.07)), 0.012, 70, 9)
body_skin = transformed(cut(bumpy(blend(skin, 0.035), 0.004, 45, 3), tear), scale=SCALE)
path = []
for i in range(60):
    t = i / 59
    path.append((0.05 * math.sin(7 * math.pi * t), 1.81 - 0.17 * t + 0.015 * math.sin(11 * math.pi * t),
                 -0.13 - 0.012 * math.cos(7 * math.pi * t)))
# One loop sags out of the tear, over the top of the gown.
path += [(0.02, 1.63, -0.15), (0.035, 1.57, -0.175), (0.03, 1.52, -0.19), (0.01, 1.53, -0.185), (-0.01, 1.58, -0.17), (-0.015, 1.64, -0.15)]
intestines = [capsule(a, b, 0.017) for a, b in zip(path, path[1:])]
guts = transformed(bumpy(union(intestines), 0.002, 120, 11), scale=SCALE)
# The dark, wet inside of the wound behind them.
flesh = transformed(bumpy(ellipsoid((0.01, 1.72, -0.1), (0.07, 0.108, 0.05)), 0.006, 60, 12), scale=SCALE)
# What's left of a military ID bracelet on his left wrist.
bracelet = transformed(union([torus_y((-0.37, 0.87, -0.3), 0.034, 0.008), box((-0.405, 0.87, -0.3), (0.006, 0.012, 0.018), 0.003)]), scale=SCALE)


def gown(P):
    """A torn hospital gown hanging from the waist: a thin flared tube with a
    ragged bottom edge."""
    y = P[:, 1]
    angle = np.arctan2(P[:, 2], P[:, 0])
    t = np.clip((1.62 - y) / (1.62 - 0.9), 0, 1)
    r = 0.13 + 0.17 * t
    radial = np.sqrt(P[:, 0] ** 2 + (P[:, 2] + 0.02) ** 2)
    shell = np.abs(radial - r) - 0.008
    hem = 0.92 + 0.07 * np.sin(angle * 7.0) + 0.05 * np.sin(angle * 13.0 + 1.0) + 0.04 * np.sin(angle * 3.0 + 2.0)
    return np.maximum(shell, np.maximum(y - 1.62, hem - y))


lo, hi = (-0.6, 0.0, -0.55), (0.6, 2.75, 0.3)
save_obj(OUT + "long_man_body.obj", [
    ("skin", SKIN, mesh(body_skin, lo, hi, 0.007, 30000, smooth=2)),
    ("gown", GOWN, mesh(transformed(bumpy(gown, 0.006, 25, 5), scale=SCALE), lo, hi, 0.005, 9000, smooth=1)),
    ("bracelet", (0.45, 0.45, 0.42), mesh(bracelet, (-0.42, 0.65, -0.36), (-0.25, 0.85, -0.2), 0.003, 800, smooth=0)),
    ("guts", (0.32, 0.06, 0.05), mesh(guts, (-0.13, 1.27, -0.3), (0.13, 1.68, -0.02), 0.003, 7000, smooth=1)),
    ("flesh", (0.12, 0.02, 0.02), mesh(flesh, (-0.13, 1.27, -0.3), (0.13, 1.68, -0.02), 0.004, 2000, smooth=1)),
])
print("body done")

# The head, built around its own pivot (where the neck meets it).
skull = blend([
    ellipsoid((0, 0.09, 0.0), (0.11, 0.19, 0.13)),                     # long skull
    ellipsoid((0, -0.08, -0.025), (0.07, 0.11, 0.075)),                # long hanging jaw
    ellipsoid((-0.07, 0.05, -0.07), (0.035, 0.03, 0.04)), ellipsoid((0.07, 0.05, -0.07), (0.035, 0.03, 0.04)),  # cheekbones
], 0.04)
holes = union([
    ellipsoid((-0.05, 0.11, -0.125), (0.032, 0.026, 0.04)), ellipsoid((0.05, 0.11, -0.125), (0.032, 0.026, 0.04)),  # sockets
    ellipsoid((0, -0.1, -0.1), (0.024, 0.065, 0.05)),                  # open mouth
    ellipsoid((-0.09, -0.01, -0.06), (0.025, 0.04, 0.04)), ellipsoid((0.09, -0.01, -0.06), (0.025, 0.04, 0.04)),  # sunken cheeks
])
head = transformed(bumpy(cut(skull, holes), 0.003, 60, 7), scale=(0.92, 0.92, 0.92))
inside = union([ellipsoid((-0.05, 0.11, -0.105), (0.03, 0.024, 0.03)), ellipsoid((0.05, 0.11, -0.105), (0.03, 0.024, 0.03)),
                ellipsoid((0, -0.1, -0.075), (0.022, 0.06, 0.04))])
inside = transformed(inside, scale=(0.92, 0.92, 0.92))
hlo, hhi = (-0.2, -0.3, -0.25), (0.2, 0.32, 0.2)
save_obj(OUT + "long_man_head.obj", [
    ("skin", SKIN, mesh(head, hlo, hhi, 0.004, 9000, smooth=1)),
    ("hole", HOLE, mesh(inside, hlo, hhi, 0.004, 1500, smooth=1)),
])
print("head done")

# ---------------------------------------------------------------- crawling pose
# He usually crawls on all fours like a spider: body low and level, knees up
# high, long arms reaching forward. Split into parts so the game can move the
# arms and legs (pivots at the shoulders and hips).
CRAWL = {"shoulder_l": (-0.27, 1.05, -0.55), "shoulder_r": (0.27, 1.05, -0.55),
         "hip_l": (-0.14, 1.0, 0.45), "hip_r": (0.14, 1.0, 0.45), "head": (0, 1.08, -0.82)}

torso = [ellipsoid((0, 1.12, -0.32), (0.17, 0.13, 0.27)),                    # ribcage, now level
         capsule((0, 1.12, -0.1), (0, 1.02, 0.42), 0.11, 0.1),               # spine to hips
         ellipsoid((0, 1.0, 0.45), (0.17, 0.11, 0.1)),                       # hips
         capsule((0, 1.12, -0.55), (0, 1.1, -0.8), 0.05, 0.043)]             # neck reaching forward
for k in range(6):                                                           # ribs underneath
    z = -0.52 + k * 0.065
    for x in (-1, 1):
        torso.append(capsule((0.16 * x, 1.12, z), (0.02 * x, 0.98, z + 0.02), 0.017))
for k in range(9):                                                           # spine knobs along the back
    torso.append(sphere((0, 1.24 - 0.01 * k, -0.48 + k * 0.11), 0.03))
for x in (-1, 1):
    torso.append(sphere((0.27 * x, 1.06, -0.55), 0.06))
crawl_tear = bumpy(ellipsoid((0.01, 0.98, 0.05), (0.07, 0.06, 0.11)), 0.01, 70, 9)
crawl_body = cut(bumpy(blend(torso, 0.035), 0.004, 45, 3), crawl_tear)
crawl_guts = union([capsule((0.04 * math.sin(i), 0.97 - 0.01 * math.cos(i * 1.7), -0.05 + i * 0.022), (0.04 * math.sin(i + 1), 0.97, -0.05 + (i + 1) * 0.022), 0.017) for i in range(8)]
                   + [capsule((0.02, 0.97, 0.06), (0.03, 0.82, 0.08), 0.017), capsule((0.03, 0.82, 0.08), (0.0, 0.85, 0.12), 0.017)])
crawl_gown = cut(bumpy(cylinder_y((0, 0.98, 0.3), 0.2, 0.09, 0.03), 0.01, 25, 5),
                 cylinder_y((0, 0.98, 0.3), 0.17, 0.2, 0.01))                 # gown bunched around the hips
clo, chi = (-0.35, 0.7, -0.95), (0.35, 1.35, 0.65)
save_obj(OUT + "long_man_crawl_body.obj", [
    ("skin", SKIN, mesh(crawl_body, clo, chi, 0.007, 16000, smooth=2)),
    ("gown", GOWN, mesh(crawl_gown, clo, chi, 0.005, 3000, smooth=1)),
    ("guts", (0.32, 0.06, 0.05), mesh(crawl_guts, (-0.12, 0.75, -0.12), (0.12, 1.05, 0.2), 0.003, 3000, smooth=1)),
])
print("crawl body done")

for side, x in (("l", -1), ("r", 1)):
    sh = CRAWL["shoulder_" + side]
    elbow = (0.5 * x, 0.95, -0.9); wrist = (0.42 * x, 0.08, -1.2)
    arm = [capsule(sh, elbow, 0.05, 0.037), sphere(elbow, 0.045), capsule(elbow, wrist, 0.037, 0.027),
           ellipsoid((0.42 * x, 0.04, -1.27), (0.045, 0.025, 0.085))]
    for f in range(4):                                                       # fingers splayed on the floor
        fx = 0.42 * x + (f - 1.5) * 0.028
        arm.append(capsule((fx, 0.03, -1.32), (fx + (f - 1.5) * 0.03, 0.015, -1.55 + abs(f - 1.5) * 0.04), 0.01, 0.006))
    if side == "l":
        arm.append(torus_y((-0.43, 0.2, -1.17), 0.034, 0.008))               # ID bracelet
    lo = (min(sh[0], wrist[0]) - 0.2, -0.02, -1.65); hi = (max(sh[0], wrist[0]) + 0.2, 1.15, -0.45)
    save_obj(OUT + f"long_man_crawl_arm_{side}.obj", [("skin", SKIN, mesh(bumpy(blend(arm, 0.03), 0.003, 45, 4), lo, hi, 0.006, 5000, smooth=2))], pivot=sh)
    hp = CRAWL["hip_" + side]
    knee = (0.42 * x, 1.4, 0.75); ankle = (0.36 * x, 0.08, 0.95)
    leg = [capsule(hp, knee, 0.072, 0.048), sphere(knee, 0.06), capsule(knee, ankle, 0.048, 0.032),
           ellipsoid((0.36 * x, 0.035, 0.85), (0.05, 0.03, 0.16))]
    lo = (min(hp[0], knee[0]) - 0.2, -0.02, 0.3); hi = (max(hp[0], knee[0]) + 0.2, 1.5, 1.15)
    save_obj(OUT + f"long_man_crawl_leg_{side}.obj", [("skin", SKIN, mesh(bumpy(blend(leg, 0.03), 0.003, 45, 5), lo, hi, 0.006, 5000, smooth=2))], pivot=hp)
print("crawl limbs done")
import json
json.dump(CRAWL, open(OUT + "long_man_crawl_rig.json", "w"), indent=1)
