"""Makes the no-code Unreal kit (unreal_easy/): a level file Unreal's Python
script can build with plain blocks, no C++ needed.

The tricky part, the rock with tunnels cut out of it, is solved here: the
solid rock is split into plain boxes around every tunnel, and the sloped
stairs become real steps. Unreal then just places boxes.
Run:  python3 tools/make_unreal_easy.py   (after tools/export_for_unreal.gd)
"""
import json, math, os, shutil

SRC = "unreal/SubjectZero/Content/Data/chapter1.json"
OUT = "unreal_easy/SubjectZero_Kit"
d = json.load(open(SRC))


def aabb(f):
    """Axis-aligned bounds of an unrotated box entry (cm)."""
    p, s = f["p"], f["s"]
    return [p[i] - s[i] / 2 for i in range(3)] + [p[i] + s[i] / 2 for i in range(3)]


def is_aligned(f):
    return abs(abs(f["x"][0]) - 1) < 1e-3 and abs(abs(f["z"][2]) - 1) < 1e-3


def steps_for(f, rise=20.0):
    """A sloped carve (stairs) becomes a row of small level boxes (steps)."""
    p, (L, W, H) = f["p"], f["s"]
    X, Z = f["x"], f["z"]
    pitch = math.atan2(X[2], math.hypot(X[0], X[1]))
    run = abs(L * math.cos(pitch))
    total_drop = abs(L * math.sin(pitch))
    n = max(2, int(total_drop / rise + 0.5))
    clear = H / math.cos(pitch)
    out = []
    for i in range(n):
        t0 = -L / 2 + L * i / n
        t1 = -L / 2 + L * (i + 1) / n
        # Bottom of the slope at the middle of this step.
        tm = (t0 + t1) / 2
        bottom = [p[k] + X[k] * tm - Z[k] * H / 2 for k in range(3)]
        xa = p[0] + X[0] * t0; xb = p[0] + X[0] * t1
        ya = p[1] - W / 2; yb = p[1] + W / 2
        out.append([min(xa, xb), ya, bottom[2], max(xa, xb), yb, bottom[2] + clear])
    return out


def subtract(a, b):
    """Box a minus box b, as up to 6 boxes."""
    if any(a[i] >= b[i + 3] or b[i] >= a[i + 3] for i in range(3)):
        return [a]
    out = []
    a = list(a)
    for axis in range(3):
        if a[axis] < b[axis]:
            piece = list(a); piece[axis + 3] = b[axis]; out.append(piece); a[axis] = b[axis]
        if a[axis + 3] > b[axis + 3]:
            piece = list(a); piece[axis] = b[axis + 3]; out.append(piece); a[axis + 3] = b[axis + 3]
    return out


# 1. The rock: start with the big block, cut every tunnel, add back the fills.
pieces, holes = [], []
for i, part in enumerate(d["rock"]):
    boxes = [aabb(part)] if is_aligned(part) else steps_for(part)
    if i == 0:
        pieces = boxes
    elif part["op"] == "subtract":
        holes += boxes
        for h in boxes:
            pieces = [q for pc in pieces for q in subtract(pc, h)]
    else:
        pieces += boxes
pieces = [q for q in pieces if min(q[3] - q[0], q[4] - q[1], q[5] - q[2]) > 0.5]

shapes = []
def add(t, lo_hi, m, c=True):
    lo, hi = lo_hi[:3], lo_hi[3:]
    shapes.append({"t": t, "p": [(lo[i] + hi[i]) / 2 for i in range(3)], "x": [1, 0, 0], "z": [0, 0, 1],
                   "s": [hi[i] - lo[i] for i in range(3)], "m": m, "c": c})

for q in pieces:
    add("cube", q, "ground" if q[5] > -5 else "cinder_block")
# Floors and ceilings inside the tunnels get their own look (thin, no collision).
for h in holes:
    if h[5] < 50:  # underground holes only
        add("cube", [h[0], h[1], h[2], h[3], h[4], h[2] + 1.5], "concrete_floor", False)
        add("cube", [h[0], h[1], h[5] - 1.5, h[3], h[4], h[5]], "concrete_wall", False)

# 2. Everything else, plus the forest, as-is.
shapes += d["shapes"]
for part in d["trees"]:
    for item in part["items"]:
        shapes.append(dict(item, t=part["t"], m=part["m"], c=part["t"] == "cylinder"))

# 3. Doors: placed open (no puzzles in the no-code version).
for door in d["doors"]:
    yaw = math.radians(door["yaw"] + 100)
    hx, hy, hz = door["p"]
    cx = hx - math.sin(yaw) * 100; cy = hy + math.cos(yaw) * 100
    shapes.append({"t": "cube", "p": [cx, cy, hz + 150], "x": [math.cos(yaw), math.sin(yaw), 0], "z": [0, 0, 1],
                   "s": [12, 200, 300], "m": "rusty_metal", "c": True})

kit = {"shapes": shapes, "lights": d["lights"], "labels": d["labels"], "moon": d["moon"], "spawns": d["spawns"]}
os.makedirs(OUT + "/Textures", exist_ok=True)
json.dump(kit, open(OUT + "/level.json", "w"))
for f in os.listdir("assets/textures"):
    if f.endswith("_albedo.jpg") or f == "chainlink_albedo.png":
        shutil.copy("assets/textures/" + f, OUT + "/Textures/" + f)
print(f"rock pieces {len(pieces)}, holes {len(holes)}, total shapes {len(shapes)}")
