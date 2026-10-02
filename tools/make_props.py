"""Sculpts nicer props (rounded edges, rims, planks, drawers) to replace the
plain boxes: assets/models/prop_*.obj. The game gives them textured
materials, so these only need their shape. Run: python3 tools/make_props.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sculpt import *

OUT = "assets/models/"
GRAY = (0.5, 0.5, 0.5)

# Oil drum: 0.9 m tall, 0.32 m radius, two rolled rims and a lid ring. Origin at the bottom.
barrel = union([
    cut(cylinder_y((0, 0.45, 0), 0.32, 0.45, 0.02), cylinder_y((0, 0.9, 0), 0.29, 0.015, 0.005)),
    torus_y((0, 0.3, 0), 0.32, 0.012), torus_y((0, 0.6, 0), 0.32, 0.012),
    torus_y((0, 0.885, 0), 0.305, 0.01), torus_y((0, 0.015, 0), 0.31, 0.012),
    cylinder_y((0.12, 0.885, 0.08), 0.03, 0.012, 0.004),   # bung cap
])
save_obj(OUT + "prop_barrel.obj", [("metal", GRAY, mesh(barrel, (-0.36, -0.01, -0.36), (0.36, 0.93, 0.36), 0.006, 5000, smooth=0))])

# Wooden crate, 1 m: planks with gaps, a frame around each face. Origin at the center.
plank_gaps = union([box((0, y, 0), (0.6, 0.008, 0.6)) for y in (-0.25, 0.0, 0.25)])
crate = union([
    cut(box((0, 0, 0), (0.47, 0.47, 0.47), 0.02), cut(plank_gaps, box((0, 0, 0), (0.455, 0.6, 0.455)))),
] + [box((sx * 0.47, 0, sz * 0.47), (0.04, 0.5, 0.04), 0.01) for sx in (-1, 1) for sz in (-1, 1)]
  + [box((0, sy * 0.47, sz * 0.47), (0.5, 0.04, 0.04), 0.01) for sy in (-1, 1) for sz in (-1, 1)]
  + [box((sx * 0.47, sy * 0.47, 0), (0.04, 0.04, 0.5), 0.01) for sx in (-1, 1) for sy in (-1, 1)])
save_obj(OUT + "prop_crate.obj", [("wood", GRAY, mesh(crate, (-0.53, -0.53, -0.53), (0.53, 0.53, 0.53), 0.008, 6000, smooth=0))])

# Old office desk, 1 x 0.9 x 0.6 m with a drawer stack. Origin on the floor at the center.
desk = union([
    box((0, 0.875, 0), (0.5, 0.025, 0.3), 0.012),                       # top
    box((-0.36, 0.43, 0), (0.13, 0.42, 0.28), 0.01),                     # drawer stack
    box((0.46, 0.43, 0), (0.025, 0.42, 0.28), 0.008),                    # side panel
    box((0.05, 0.6, 0.27), (0.42, 0.24, 0.01), 0.005),                   # back panel
])
drawer_lines = union([box((-0.36, y, -0.285), (0.12, 0.006, 0.01)) for y in (0.29, 0.57)])
handles = union([box((-0.36, y, -0.295), (0.04, 0.008, 0.01), 0.004) for y in (0.15, 0.43, 0.71)])
save_obj(OUT + "prop_desk.obj", [("wood", GRAY, mesh(union([cut(desk, drawer_lines), handles]), (-0.55, -0.01, -0.35), (0.55, 0.92, 0.35), 0.006, 6000, smooth=0))])

# Swivel office chair. Origin on the floor.
chair = union([
    box((0, 0.46, 0), (0.22, 0.035, 0.22), 0.03),                       # seat
    box((0, 0.78, 0.2), (0.21, 0.2, 0.025), 0.025),                      # back
    capsule((0, 0.5, 0.19), (0, 0.6, 0.2), 0.02),
    capsule((0, 0.05, 0), (0, 0.44, 0), 0.025),                          # post
] + [capsule((0, 0.05, 0), (0.24 * dx, 0.03, 0.24 * dz), 0.018) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))]
  + [sphere((0.24 * dx, 0.025, 0.24 * dz), 0.025) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))])
save_obj(OUT + "prop_chair.obj", [("metal", GRAY, mesh(chair, (-0.3, -0.01, -0.3), (0.3, 1.0, 0.3), 0.006, 5000, smooth=0))])

# Filing cabinet (decoration), 0.6 x 1.35 x 0.65 with 4 drawers and handles. Origin on the floor.
cab = box((0, 0.675, 0), (0.3, 0.675, 0.325), 0.015)
seams = union([box((0, y, -0.33), (0.29, 0.005, 0.01)) for y in (0.34, 0.67, 1.0)])
pulls = union([box((0, y, -0.335), (0.07, 0.012, 0.012), 0.005) for y in (0.25, 0.58, 0.91, 1.24)])
save_obj(OUT + "prop_cabinet.obj", [("metal", GRAY, mesh(union([cut(cab, seams), pulls]), (-0.33, -0.01, -0.36), (0.33, 1.37, 0.36), 0.006, 4000, smooth=0))])
print("props done")
