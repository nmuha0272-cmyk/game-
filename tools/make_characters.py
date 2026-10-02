"""Sculpts the four players and the Long Man as smooth 3D models, saved to
assets/models/*.obj (+ .mtl colors). Each character is split into parts
(body, arms, legs, head) so the game can swing arms and legs when walking.
Run:  python3 tools/make_characters.py   (needs numpy scikit-image trimesh fast-simplification)
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sculpt import *

OUT = "assets/models/"

CHARACTERS = {
    # name: colors from the concept art + build
    "son": dict(height=1.80, width=1.0, skin=(0.80, 0.62, 0.50), hair=(0.06, 0.05, 0.04),
                top=(0.36, 0.23, 0.13), under=(0.42, 0.42, 0.42), pants=(0.16, 0.22, 0.36), boots=(0.15, 0.14, 0.13),
                extra=(0.10, 0.10, 0.10), style="son"),
    "journalist": dict(height=1.72, width=0.9, skin=(0.82, 0.64, 0.53), hair=(0.12, 0.08, 0.06),
                       top=(0.62, 0.50, 0.34), under=(0.07, 0.07, 0.08), pants=(0.08, 0.08, 0.09), boots=(0.10, 0.08, 0.07),
                       extra=(0.25, 0.17, 0.10), style="journalist"),
    "engineer": dict(height=1.72, width=1.0, skin=(0.80, 0.65, 0.57), hair=(0.62, 0.62, 0.60),
                     top=(0.14, 0.18, 0.30), under=(0.14, 0.18, 0.30), pants=(0.14, 0.18, 0.30), boots=(0.22, 0.15, 0.09),
                     extra=(0.30, 0.20, 0.11), style="engineer"),
    "guard": dict(height=1.86, width=1.15, skin=(0.74, 0.56, 0.44), hair=(0.12, 0.10, 0.08),
                  top=(0.27, 0.30, 0.19), under=(0.18, 0.20, 0.14), pants=(0.25, 0.27, 0.18), boots=(0.08, 0.08, 0.08),
                  extra=(0.12, 0.10, 0.08), style="guard"),
}


def humanoid(c):
    s = c["height"] / 1.8; w = c["width"]
    def P(x, y, z):
        return (x * w, y * s, z * w)
    hip_y, knee_y, ankle_y = 0.95 * s, 0.52 * s, 0.09 * s
    sh_y = 1.45 * s
    st = c["style"]
    head_c = P(0, 1.69, -0.01)
    if st == "engineer":
        head_c = P(0, 1.67, -0.04)  # a little hunched

    # ------------------------------------------------ body (doesn't move)
    torso = [box(P(0, 1.24, 0), (0.17 * w, 0.24 * s, 0.10 * w), 0.07),
             box(P(0, 0.99, 0), (0.15 * w, 0.09 * s, 0.095 * w), 0.06),
             capsule(P(-0.18, 1.43, 0), P(0.18, 1.43, 0), 0.07 * w)]
    under, extra, hair = [], [], []
    if st == "son":
        under += [box(P(0, 1.27, -0.075), (0.065 * w, 0.2 * s, 0.035), 0.02),
                  capsule(P(0, 1.52, 0.07), P(0, 1.6, 0.09), 0.08)]                         # hood joins the neck
        extra += [box(P(0, 1.22, 0.16), (0.14 * w, 0.19 * s, 0.07), 0.05),                  # backpack
                  capsule(P(-0.11, 1.42, 0.06), P(-0.12, 1.08, 0.13), 0.018),
                  capsule(P(0.11, 1.42, 0.06), P(0.12, 1.08, 0.13), 0.018)]
        torso += [box(P(0, 0.92, 0), (0.16 * w, 0.06 * s, 0.1 * w), 0.05)]                 # jacket hem
    elif st == "journalist":
        torso += [cone(0.98 * s, 0.17 * w, 0.42 * s, 0.27 * w, z_scale=0.75),               # long trench coat
                  capsule(P(-0.09, 1.5, -0.06), P(0.09, 1.5, -0.06), 0.035)]                # collar
        under += [cylinder_y(P(0, 1.55, 0), 0.06, 0.05 * s)]                              # turtleneck
        extra += [box(P(0.21, 0.95, 0.02), (0.05, 0.11, 0.12), 0.03),                       # shoulder bag
                  capsule(P(-0.15, 1.44, -0.02), P(0.2, 1.05, 0.0), 0.012)]
    elif st == "engineer":
        extra += [torus_y(P(0, 1.0, 0), 0.16 * w, 0.03, z_scale=0.65),                     # tool belt
                  box(P(-0.16, 0.92, -0.06), (0.04, 0.07, 0.04), 0.015), box(P(0.16, 0.92, -0.06), (0.04, 0.07, 0.04), 0.015),
                  box(P(0.17, 0.92, 0.05), (0.035, 0.06, 0.04), 0.015)]
        torso += [box(P(0.07, 1.3, -0.1), (0.05, 0.05, 0.015), 0.01)]                      # chest pocket
    elif st == "guard":
        torso += [box(P(-0.09, 1.3, -0.1), (0.05, 0.05, 0.02), 0.012), box(P(0.09, 1.3, -0.1), (0.05, 0.05, 0.02), 0.012),
                  box(P(0, 0.93, 0), (0.17 * w, 0.06 * s, 0.11 * w), 0.05)]                # field jacket hem
        extra += [torus_y(P(0, 0.99, 0), 0.155 * w, 0.025, z_scale=0.68)]                   # belt
        under += [box(P(0, 1.3, -0.085), (0.06 * w, 0.18 * s, 0.03), 0.02)]                  # plain T-shirt
    skin = [capsule(P(0, 1.5, 0), P(0, 1.6, -0.01), 0.055 * w),                             # neck
            ellipsoid(head_c, (0.085, 0.112, 0.1)),                                         # head
            ellipsoid((head_c[0], head_c[1] - 0.06, head_c[2] - 0.035), (0.065, 0.06, 0.07)),  # jaw
            ellipsoid((head_c[0], head_c[1] - 0.005, head_c[2] - 0.098), (0.016, 0.028, 0.022)),  # nose
            ellipsoid((head_c[0] - 0.085, head_c[1], head_c[2] + 0.005), (0.014, 0.03, 0.02)),     # ears
            ellipsoid((head_c[0] + 0.085, head_c[1], head_c[2] + 0.005), (0.014, 0.03, 0.02))]
    hx, hy, hz = head_c
    if st == "son":       # messy dark hair poking out of his hood
        hair += [bumpy(ellipsoid((hx, hy + 0.035, hz - 0.03), (0.09, 0.07, 0.08)), 0.014, 55, 1)]
        hair_cut = union([box((hx, hy - 0.03, hz - 0.08), (0.12, 0.06, 0.06)), box((hx, hy, hz + 0.1), (0.2, 0.2, 0.12))])
        # The hood is UP: a thick shell around the head, open at the face.
        hood_outer = ellipsoid((hx, hy + 0.02, hz + 0.02), (0.125, 0.145, 0.14))
        hood_inner = ellipsoid((hx, hy + 0.01, hz + 0.0), (0.103, 0.125, 0.118))
        face_hole = ellipsoid((hx, hy - 0.01, hz - 0.13), (0.085, 0.11, 0.09))
        under.append(cut(cut(hood_outer, hood_inner), face_hole))
    elif st == "journalist":  # hair pulled back into a bun
        hair += [ellipsoid((hx, hy + 0.025, hz + 0.01), (0.092, 0.095, 0.104)), sphere((hx, hy, hz + 0.115), 0.045)]
        hair_cut = box((hx, hy - 0.02, hz - 0.09), (0.12, 0.07, 0.06))
    elif st == "engineer":    # gray at the sides, thin on top
        hair += [bumpy(ellipsoid((hx, hy + 0.0, hz + 0.01), (0.092, 0.08, 0.104)), 0.01, 60, 2)]
        hair_cut = union([box((hx, hy - 0.04, hz - 0.08), (0.12, 0.08, 0.06)), sphere((hx, hy + 0.08, hz - 0.01), 0.075)])
        extra += [torus_y((hx - 0.035, hy + 0.005, hz - 0.098), 0.022, 0.004), torus_y((hx + 0.035, hy + 0.005, hz - 0.098), 0.022, 0.004)]
    else:                     # buzz cut
        hair += [ellipsoid((hx, hy + 0.02, hz + 0.005), (0.089, 0.098, 0.103))]
        hair_cut = box((hx, hy - 0.035, hz - 0.075), (0.12, 0.07, 0.06))
    # A face: eyes, eyebrows, a mouth (small dark shapes sitting on the skin).
    face = [sphere((hx - 0.032, hy + 0.012, hz - 0.086), 0.012), sphere((hx + 0.032, hy + 0.012, hz - 0.086), 0.012),
            capsule((hx - 0.016, hy - 0.058, hz - 0.093), (hx + 0.016, hy - 0.058, hz - 0.093), 0.005)]
    brows = [capsule((hx - 0.05, hy + 0.04, hz - 0.088), (hx - 0.016, hy + 0.044, hz - 0.095), 0.007),
             capsule((hx + 0.05, hy + 0.04, hz - 0.088), (hx + 0.016, hy + 0.044, hz - 0.095), 0.007)]
    scar = []
    if st == "guard":
        brows = [cut(b, box((hx - 0.033, hy + 0.042, hz - 0.09), (0.004, 0.02, 0.03))) for b in brows]  # gap in the brow
        scar = [capsule((hx - 0.037, hy + 0.07, hz - 0.087), (hx - 0.03, hy + 0.0, hz - 0.091), 0.0035)]
    body_lo, body_hi = (-0.42 * w, 0.38 * s, -0.25), (0.42 * w, 1.9 * s, 0.3)
    body = [("top", c["top"], mesh(bumpy(blend(torso, 0.04), 0.004, 30), body_lo, body_hi, 0.009, 9000)),
            ("skin", c["skin"], mesh(blend(skin, 0.02), body_lo, body_hi, 0.006, 6000)),
            ("hair", c["hair"], mesh(cut(union(hair), hair_cut), body_lo, body_hi, 0.006, 3000)),
            ("brows", c["hair"], mesh(union(brows), body_lo, body_hi, 0.004, 600, smooth=0)),
            ("eyes", (0.05, 0.04, 0.035), mesh(union(face), body_lo, body_hi, 0.003, 800, smooth=0))]
    if scar:
        body.append(("scar", (0.86, 0.62, 0.56), mesh(union(scar), body_lo, body_hi, 0.0025, 300, smooth=0)))
    if under:
        body.append(("under", c["under"], mesh(blend(under, 0.02), body_lo, body_hi, 0.008, 3000)))
    if extra:
        body.append(("extra", c["extra"], mesh(union(extra), body_lo, body_hi, 0.006, 4000)))

    # ------------------------------------------------ arms (rotate at the shoulder)
    arms = {}
    for side, x in (("l", -1), ("r", 1)):
        sh = P(0.2 * x, 1.44, 0); el = P(0.235 * x, 1.17, 0.01); wr = P(0.25 * x, 0.9, -0.01)
        sleeve = [capsule(sh, el, 0.058 * w, 0.05 * w), capsule(el, wr, 0.05 * w, 0.044 * w)]
        hand = [ellipsoid((wr[0], wr[1] - 0.075, wr[2]), (0.032, 0.065, 0.045)),
                capsule((wr[0], wr[1] - 0.04, wr[2] - 0.035), (wr[0], wr[1] - 0.08, wr[2] - 0.05), 0.014)]  # thumb
        lo = (min(sh[0], wr[0]) - 0.12, 0.7 * s, -0.15); hi = (max(sh[0], wr[0]) + 0.12, 1.56 * s, 0.15)
        arms[side] = ([("sleeve", c["top"], mesh(bumpy(blend(sleeve, 0.03), 0.003, 35), lo, hi, 0.007, 3500)),
                       ("skin", c["skin"], mesh(blend(hand, 0.02), lo, hi, 0.005, 1500))], sh)

    # ------------------------------------------------ legs (rotate at the hip)
    legs = {}
    for side, x in (("l", -1), ("r", 1)):
        hp = (0.095 * x * w, hip_y, 0); kn = (0.1 * x * w, knee_y, -0.01); an = (0.1 * x * w, ankle_y, 0.0)
        r_thigh = 0.085 * w if st == "guard" else 0.078 * w
        pants = [capsule(hp, kn, r_thigh, 0.062 * w), capsule(kn, an, 0.062 * w, 0.05)]
        if st == "guard":
            pants.append(box((0.14 * x * w, 0.68 * s, 0.0), (0.03, 0.06, 0.05), 0.02))  # cargo pocket
        boot = [box((an[0], 0.055, an[2] - 0.04), (0.055, 0.055, 0.125), 0.04), capsule((an[0], 0.06, an[2]), (an[0], 0.16 * s, an[2]), 0.055)]
        lo = (hp[0] - 0.15, 0.0, -0.22); hi = (hp[0] + 0.15, hip_y + 0.1, 0.16)
        legs[side] = ([("pants", c["pants"], mesh(bumpy(blend(pants, 0.03), 0.003, 30), lo, hi, 0.008, 3500)),
                       ("boots", c["boots"], mesh(blend(boot, 0.02), lo, hi, 0.006, 2000))], hp)
    return body, arms, legs


import json
rigs = {}
for name, c in CHARACTERS.items():
    body, arms, legs = humanoid(c)
    rigs[name] = {"shoulder_l": list(arms["l"][1]), "shoulder_r": list(arms["r"][1]),
                  "hip_l": list(legs["l"][1]), "hip_r": list(legs["r"][1])}
    save_obj(f"{OUT}{name}_body.obj", body)
    for side in ("l", "r"):
        save_obj(f"{OUT}{name}_arm_{side}.obj", arms[side][0], pivot=arms[side][1])
        save_obj(f"{OUT}{name}_leg_{side}.obj", legs[side][0], pivot=legs[side][1])
    print("made", name, "| shoulder", [round(v, 3) for v in arms["r"][1]], "hip", [round(v, 3) for v in legs["r"][1]])
json.dump(rigs, open(OUT + "rigs.json", "w"), indent=1)
