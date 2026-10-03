"""Builds the Roblox LOBBY place: roblox/SubjectZero_Lobby.rbxlx.

A visitor hall where everyone arrives. Walk into one of the 4 elevators:
when 2-4 players are in it, it counts down and takes that group to their
own private game (the Chapter 1 place). The first person in an elevator can
make it FRIENDS ONLY. There's an "Invite friends" button too.

Roblox can only send players between places of a PUBLISHED game, so the
lobby and Chapter 1 must be two places in the same experience: see
roblox/HOW_TO_USE.txt ("THE LOBBY").
    python3 tools/make_roblox_lobby.py
"""
import math, os, random, sys
from xml.sax.saxutils import escape
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import roblox_lobby

OUT = "roblox/SubjectZero_Lobby.rbxlx"
S = 3.2
W = ((1, 0, 0), (0, 1, 0), (0, 0, 1))
HALL = (30, 6, 24)
ELEVATOR_X = (-10.5, -3.5, 3.5, 10.5)
ref = [0]


def new_ref():
    ref[0] += 1
    return f"LBY{ref[0]}"


def rgb(h):
    h = h.lstrip("#!")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def part(name, pos, axes, size, color, collide=True, shape=1, transparency=0.0, cls="Part", children="", extra="", material=None):
    r, u, b = axes
    vals = [r[0], u[0], b[0], r[1], u[1], b[1], r[2], u[2], b[2]]
    c = rgb(color)
    mat = material or (288 if color.startswith("!") else 272)
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties><string name="Name">{escape(name)}</string>'
            f'<bool name="Anchored">true</bool><CoordinateFrame name="CFrame">'
            + "".join(f"<{n}>{v:.4f}</{n}>" for n, v in zip("XYZ", pos))
            + "".join(f"<{n}>{v:.5f}</{n}>" for n, v in zip(["R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"], vals))
            + f'</CoordinateFrame><bool name="CanCollide">{"true" if collide else "false"}</bool>'
            f'<Color3uint8 name="Color3uint8">{0xFF000000 | (c[0] << 16) | (c[1] << 8) | c[2]}</Color3uint8>'
            f'<token name="Material">{mat}</token>' + (f'<token name="shape">{shape}</token>' if cls in ("Part", "SpawnLocation") else "")
            + f'<token name="TopSurface">0</token><token name="BottomSurface">0</token>'
            f'<Vector3 name="size"><X>{size[0]:.3f}</X><Y>{size[1]:.3f}</Y><Z>{size[2]:.3f}</Z></Vector3>'
            f'<float name="Transparency">{transparency}</float>{extra}</Properties>{children}</Item>')


def script(cls, name, source, children=""):
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties><string name="Name">{name}</string>'
            f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString></Properties>{children}</Item>')


def light(cls, brightness, rng, color=(1, 0.88, 0.7), extra=""):
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties><float name="Brightness">{brightness}</float>'
            f'<Color3 name="Color"><R>{color[0]}</R><G>{color[1]}</G><B>{color[2]}</B></Color3>'
            f'<float name="Range">{rng}</float><bool name="Shadows">true</bool>{extra}</Properties></Item>')


parts = []
def box(name, c, s, color, collide=True, shape=1, children="", transparency=0.0, material=None):
    parts.append(part(name, tuple(v * S for v in c), W, tuple(v * S for v in s), color, collide, shape, transparency,
                      children=children, material=material))


w, h, d = HALL
rng = random.Random(13)


def rot(yaw=0.0, pitch=0.0, roll=0.0):
    """Axes (right, up, back) for a part turned by yaw (Y), pitch (X), roll (Z), in degrees."""
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    cp, sp = math.cos(math.radians(pitch)), math.sin(math.radians(pitch))
    cr, sr = math.cos(math.radians(roll)), math.sin(math.radians(roll))
    Ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy)); Rx = ((1, 0, 0), (0, cp, -sp), (0, sp, cp)); Rz = ((cr, -sr, 0), (sr, cr, 0), (0, 0, 1))
    mul = lambda A, B: tuple(tuple(sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)) for i in range(3))
    R = mul(mul(Ry, Rx), Rz)
    return tuple(tuple(R[i][j] for i in range(3)) for j in range(3))


def rbox(name, c, s, color, axes, collide=False, transparency=0.0, material=None, children=""):
    parts.append(part(name, tuple(v * S for v in c), axes, tuple(v * S for v in s), color, collide, 1, transparency,
                      children=children, material=material))


# The hall: a checkered floor with broken tiles, grimy green-and-cream walls.
box("Floor", (0, -0.1, 0), (w, 0.2, d), "#1c1d1a")
for i in range(int(w / 2)):
    for k in range(int(d / 2)):
        if (i + k) % 2 == 0:
            x, z = -w / 2 + 1 + i * 2, -d / 2 + 1 + k * 2
            if rng.random() < 0.12:  # a broken tile: rubble instead
                for _ in range(3):
                    box("Rubble", (x + rng.uniform(-0.7, 0.7), 0.04, z + rng.uniform(-0.7, 0.7)), (0.25, 0.08, 0.2), "#b8b3a0", False)
                continue
            box("FloorTile", (x, 0.005, z), (2, 0.01, 2), rng.choice(["#cfcab5", "#c2bca6", "#b5ae96"]), False)
box("Ceiling", (0, h + 0.1, 0), (w, 0.2, d), "#5e5b51")
WIN = (-2.0, 4.0, 0.9, 3.0)   # the observation window in the east wall: z1, z2, y1, y2
def wall(name, c, s):
    box(name + "Low", (c[0], 0.55, c[2]), (s[0], 1.1, s[2]), "#34493a")
    box(name + "Stripe", (c[0], 1.13, c[2]), (s[0] + (0.04 if s[0] < 1 else 0), 0.06, s[2] + (0.04 if s[2] < 1 else 0)), "#16211b")
    box(name + "High", (c[0], 1.16 + (h - 1.16) / 2, c[2]), (s[0], h - 1.16, s[2]), "#a19c88")
wall("WallN", (0, 0, -d / 2 - 0.15), (w + 0.6, 0, 0.3))
wall("WallS", (0, 0, d / 2 + 0.15), (w + 0.6, 0, 0.3))
wall("WallW", (-w / 2 - 0.15, 0, 0), (0.3, 0, d))
ex = w / 2 + 0.15
wall("WallE_A", (ex, 0, (-d / 2 + WIN[0]) / 2), (0.3, 0, WIN[0] + d / 2))
wall("WallE_B", (ex, 0, (WIN[1] + d / 2) / 2), (0.3, 0, d / 2 - WIN[1]))
wz = (WIN[0] + WIN[1]) / 2; ww = WIN[1] - WIN[0]
box("WallE_UnderWindow", (ex, WIN[2] / 2, wz), (0.3, WIN[2], ww), "#34493a")
box("WallE_OverWindow", (ex, (WIN[3] + h) / 2, wz), (0.3, h - WIN[3], ww), "#a19c88")
# Grime and damp stains on the walls.
for _ in range(26):
    side = rng.choice(["N", "S", "W"])
    sw, sh = rng.uniform(0.6, 2.5), rng.uniform(0.4, 2.0)
    y = rng.uniform(0.3, h - 0.5)
    if side == "N":
        box("Grime", (rng.uniform(-14, 14), y, -d / 2 + 0.01), (sw, sh, 0.02), "#1a1712", False, transparency=0.55)
    elif side == "S":
        box("Grime", (rng.uniform(-14, 14), y, d / 2 - 0.01), (sw, sh, 0.02), "#1a1712", False, transparency=0.55)
    else:
        box("Grime", (-w / 2 + 0.01, y, rng.uniform(-11, 11)), (0.02, sh, sw), "#1a1712", False, transparency=0.55)
# Claw scratches (long, in sets of four) and bloody hand smears.
for (x, y, z, face) in ((-12.5, 2.0, -d / 2 + 0.02, "N"), (-15 + 0.02, 1.6, 7.5, "W"), (8.5, 1.4, d / 2 - 0.02, "S"), (-15 + 0.02, 1.2, -6, "W")):
    for k in range(4):
        if face == "W":
            rbox("Scratch", (x, y + k * 0.12, z + k * 0.12), (0.02, 0.035, 1.6), "#0c0a08", rot(0, 35, 0))
        else:
            rbox("Scratch", (x + k * 0.12, y + k * 0.12, z), (1.6, 0.035, 0.02), "#0c0a08", rot(0, 0, -35))
for (x, y, z) in ((-6, 0.9, -d / 2 + 0.02), (-5.6, 1.15, -d / 2 + 0.02), (12.2, 0.8, d / 2 - 0.02)):
    rbox("BloodSmear", (x, y, z), (0.25, 0.7, 0.02), "#4a0705", rot(0, 0, rng.uniform(-25, 25)))
# A blood trail dragged across the floor, from the window to the elevators.
for k in range(16):
    t = k / 15
    x, z = 14 - t * 9, 1 - t * 6.5
    box("BloodTrail", (x + rng.uniform(-0.2, 0.2), 0.012, z + rng.uniform(-0.2, 0.2)), (rng.uniform(0.3, 0.7), 0.01, rng.uniform(0.3, 0.6)),
        rng.choice(["#3d0604", "#4a0705", "#2e0403"]), False)
# Ceiling lamps: some dead, one hanging by a wire, all of them flickering.
for (x, z, kind) in ((-10, -3, "Lamp"), (0, -3, "DeadLamp"), (10, -3, "Lamp"), (-10, 6, "DeadLamp"), (0, 6, "Lamp"), (10, 6, "Hanging")):
    if kind == "DeadLamp":
        box("DeadLamp", (x, h - 0.05, z), (1.4, 0.08, 0.4), "#3a3a36", False)
    elif kind == "Hanging":
        rbox("Lamp", (x, h - 0.9, z), (1.4, 0.08, 0.4), "!ffe6b8", rot(20, 0, 28), children=light("PointLight", 1.0, 30))
        box("LampWire", (x - 0.45, h - 0.45, z), (0.02, 0.9, 0.02), "#111111", False)
    else:
        box("Lamp", (x, h - 0.05, z), (1.4, 0.08, 0.4), "!ffe6b8", False, children=light("PointLight", 1.0, 34))
# A red emergency light over the elevators.
box("EmergencyLight", (0, h - 0.3, -d / 2 + 0.3), (0.5, 0.3, 0.3), "!ff2010", False,
    children=light("PointLight", 1.6, 40, (1, 0.1, 0.05)))

# THE OBSERVATION ROOM, behind the window. Something is in there.
ox1, ox2 = w / 2 + 0.3, w / 2 + 5.5
box("ObsFloor", ((ox1 + ox2) / 2, -0.1, wz), (ox2 - ox1, 0.2, ww + 4), "#151513")
box("ObsCeiling", ((ox1 + ox2) / 2, 4.1, wz), (ox2 - ox1, 0.2, ww + 4), "#151513")
box("ObsBack", (ox2 + 0.15, 2, wz), (0.3, 4.2, ww + 4), "#22241f")
box("ObsSide1", ((ox1 + ox2) / 2, 2, WIN[0] - 2.15), (ox2 - ox1, 4.2, 0.3), "#22241f")
box("ObsSide2", ((ox1 + ox2) / 2, 2, WIN[1] + 2.15), (ox2 - ox1, 4.2, 0.3), "#22241f")
box("ObsRedLight", (ox2 - 0.3, 3.6, wz), (0.2, 0.2, 0.2), "!5a0a06", False, children=light("PointLight", 0.6, 22, (1, 0.12, 0.06)))
box("ObsGlass", (ex, (WIN[2] + WIN[3]) / 2, wz), (0.06, WIN[3] - WIN[2], ww), "#3a4a44", True, transparency=0.4, material=1568)
for k in range(5):
    rbox("GlassCrack", (ex - 0.05, 2.3 - k * 0.05, 2.4 + k * 0.05), (0.01, 0.02, rng.uniform(0.6, 1.4)), "#0a0a0a",
         rot(0, rng.uniform(-50, 50), 0))
for (y, z) in ((1.6, -0.6), (1.9, -0.2), (1.3, 2.9)):
    box("HandPrint", (ex - 0.05, y, z), (0.01, 0.22, 0.16), "#4a0705", False)
box("ObsSign", (ex - 0.05, 3.5, wz), (0.05, 0.5, 4), "#141412", False)
rbox("ObsChair", (ox1 + 2.5, 0.25, wz - 1.5), (0.6, 0.5, 0.6), "#3a3d34", rot(30, 0, 80), collide=True)
for k in range(3):
    box("ObsChain", (ox1 + 3.5, 3.2, WIN[0] + 1.2 + k * 2), (0.05, 1.6, 0.05), "#55554f", False)
# The watcher: tall, thin, and dark, with red eyes.
for name, c, s2, col in (("Torso", (0, 1.9, 0), (0.35, 1.3, 0.22), "#0b0b0a"), ("Head", (0, 2.75, -0.05), (0.26, 0.36, 0.28), "#0b0b0a"),
                        ("ArmL", (-0.3, 1.45, 0), (0.1, 1.9, 0.1), "#0b0b0a"), ("ArmR", (0.3, 1.45, 0), (0.1, 1.9, 0.1), "#0b0b0a"),
                        ("LegL", (-0.12, 0.65, 0), (0.12, 1.3, 0.12), "#0b0b0a"), ("LegR", (0.12, 0.65, 0), (0.12, 1.3, 0.12), "#0b0b0a"),
                        ("EyeL", (-0.06, 2.8, -0.2), (0.04, 0.025, 0.02), "!ff1a0a"), ("EyeR", (0.06, 2.8, -0.2), (0.04, 0.025, 0.02), "!ff1a0a")):
    # (turned to face the window: -x)
    rbox("Watcher_" + name, (ox2 - 1.2 + c[2], c[1], wz + 2.5 - c[0]), s2, col, rot(90, 0, 0))
# A gurney with a stained sheet, an overturned bench, papers everywhere.
box("Gurney", (11.5, 0.8, 7.5), (0.8, 0.08, 2.0), "#8a8c86", True)
box("GurneySheet", (11.5, 0.86, 7.6), (0.82, 0.05, 1.6), "#bdb6a2", False)
box("GurneyStain", (11.5, 0.89, 7.3), (0.4, 0.01, 0.5), "#3d0604", False)
for dx in (-0.33, 0.33):
    for dz in (-0.85, 0.85):
        box("GurneyLeg", (11.5 + dx, 0.38, 7.5 + dz), (0.04, 0.76, 0.04), "#5a5c56", False)
rbox("BenchFallen", (-4, 0.36, 3.3), (4, 0.1, 0.7), "#4a3420", rot(8, 0, 90), collide=True)
box("Bench", (4, 0.45, 3), (4, 0.1, 0.7), "#4a3420")
for _ in range(14):
    rbox("Paper", (rng.uniform(-12, 12), 0.015, rng.uniform(-6, 9)), (0.22, 0.01, 0.3), rng.choice(["#cfc8b0", "#bdb59a"]), rot(rng.uniform(0, 360)))

# 4 elevators along the back wall: rusty old freight cages with bars,
# blood on the floor, a dying red bulb, and a shutter that SLAMS down.
RUST = 1040; PLATE = 1056
for i, x in enumerate(ELEVATOR_X, 1):
    z0, z1 = -d / 2, -d / 2 + 4.2
    zc = (z0 + z1) / 2
    box(f"ElevatorFloor{i}", (x, 0.06, zc), (4, 0.12, 4.2), "#2e2a24", material=PLATE)
    box(f"ElevatorPad{i}", (x, 1.5, zc), (3.8, 3, 4), "#000000", False, transparency=1.0)
    # Hazard stripes along the front edge.
    for k in range(8):
        box(f"ElevatorStripe{i}", (x - 1.75 + k * 0.5, 0.125, z1 - 0.12), (0.5, 0.01, 0.2), "#c9a017" if k % 2 == 0 else "#151515", False)
    # The back wall and frame: rusty.
    box(f"ElevatorBack{i}", (x, 1.75, z0 + 0.08), (4.0, 3.5, 0.12), "#4a3020", material=RUST)
    for side in (-1, 1):
        box(f"ElevatorPost{i}", (x + side * 2.05, 1.75, z1 - 0.05), (0.18, 3.5, 0.18), "#5a3a28", material=RUST)
        box(f"ElevatorPost{i}", (x + side * 2.05, 1.75, z0 + 0.1), (0.18, 3.5, 0.18), "#5a3a28", material=RUST)
        # Bars instead of walls.
        for k in range(7):
            box(f"ElevatorBar{i}", (x + side * 2.05, 1.75, z0 + 0.5 + k * 0.53), (0.06, 3.5, 0.06), "#3b2a1e", material=RUST)
        box(f"ElevatorRail{i}", (x + side * 2.05, 1.2, zc), (0.08, 0.08, 4.2), "#3b2a1e", material=RUST)
    box(f"ElevatorRoof{i}", (x, 3.55, zc), (4.3, 0.15, 4.3), "#3b2a1e", material=RUST)
    # A dying bulb in a cage (it flickers; see the Haunting script).
    box(f"ElevatorLamp{i}", (x, 3.3, zc), (0.22, 0.22, 0.22), "!ffb070", False, shape=0,
        children=light("PointLight", 0.9, 13, (1, 0.55, 0.3)))
    for k in range(4):
        box(f"ElevatorLampCage{i}", (x + (-0.15 if k % 2 else 0.15) * (k < 2), 3.3, zc + (-0.15 if k % 2 else 0.15) * (k >= 2)),
            (0.03, 0.35, 0.03), "#222222", False)
    # Old cables hanging from the roof, swaying in the dark.
    for k, (dx, dz, ln) in enumerate(((-1.2, -1.0, 1.4), (1.3, 0.6, 0.9), (0.4, -1.4, 1.8))):
        box(f"ElevatorCable{i}", (x + dx, 3.45 - ln / 2, zc + dz), (0.04, ln, 0.04), "#111111", False)
    # Blood on the floor, drag marks to the back, and claw scratches on the back wall.
    box(f"ElevatorBlood{i}", (x + rng.uniform(-0.8, 0.8), 0.125, zc + rng.uniform(-0.6, 0.6)), (rng.uniform(0.6, 1.1), 0.01, rng.uniform(0.5, 0.9)), "#3d0604", False)
    for k in range(3):
        box(f"ElevatorDrag{i}", (x - 0.3 + k * 0.25, 0.125, zc - 0.6), (0.08, 0.01, 1.6), "#2e0403", False)
    for k in range(4):
        rbox(f"ElevatorScratch{i}", (x - 0.8 + k * 0.13, 1.6 + k * 0.1, z0 + 0.15), (1.2, 0.03, 0.02), "#0c0a08", rot(0, 0, -40))
    # A broken button panel: one button still glowing red.
    box(f"ElevatorPanel{i}", (x + 1.9, 1.3, z1 - 0.5), (0.06, 0.6, 0.3), "#2a2a26", material=PLATE)
    for k in range(3):
        box(f"ElevatorButton{i}", (x + 1.86, 1.45 - k * 0.15, z1 - 0.5), (0.03, 0.08, 0.08), "!ff2010" if k == 2 else "#555550", False)
    # The shutter (it slams down when the elevator leaves) and the sign.
    box(f"ElevatorGate{i}", (x, 5.35, z1 + 0.05), (4, 3.4, 0.1), "#4a3020", False, material=RUST)
    for k in range(6):
        box(f"ElevatorGateRib{i}", (x, 3.85 + k * 0.5, z1 + 0.11), (4, 0.05, 0.03), "#2e1e14", False)
    box(f"ElevatorSign{i}", (x, 4.25, z1 + 0.13), (4.0, 1.2, 0.05), "#141412", False)
    box(f"ElevatorStatusLamp{i}", (x, 3.75, z1 + 0.16), (0.25, 0.25, 0.1), "!40ff60", False,
        children=light("PointLight", 1, 10, (0.3, 1, 0.4)))

# The four characters on show along the front wall (you pick yours in the game's waiting room).
for role, x, color in roblox_lobby.STANDS:
    box(f"Pedestal_{role}", (x * 1.2, 0.15, d / 2 - 2.2), (1.8, 0.3, 1.8), color)
    roblox_lobby.figure(lambda name, c, s, col, collide=False, shape=1: box(name, c, s, col, collide, shape),
                        role, x * 1.2, color, z=d / 2 - 2.2, face=-1)
    box(f"PedestalSign_{role}", (x * 1.2, 2.7, d / 2 - 0.02), (2.4, 0.7, 0.05), "#141412", False)
    box(f"PedestalLamp_{role}", (x * 1.2, h - 0.1, d / 2 - 2.2), (0.3, 0.1, 0.3), "#222220", False,
        children=light("SpotLight", 2.5, 18, (1, 0.9, 0.75), '<float name="Angle">35</float><token name="Face">4</token>'))
box("TitleBoard", (-w / 2 + 0.05, 3.4, 0), (0.06, 2.2, 10), "#10140f", False)
box("HowToBoard", (w / 2 - 0.05, 2.4, -8), (0.06, 3.4, 5.6), "#10140f", False)
box("Scrawl1", (-w / 2 + 0.05, 1.0, 8.5), (0.04, 0.9, 3.4), "#000000", False, transparency=1.0)
box("Scrawl2", (-1.5, 4.6, -d / 2 + 0.03), (5, 0.9, 0.04), "#000000", False, transparency=1.0)
parts.append(part("Spawn", (0, 0.3 * S, 1.0 * S), W, (10 * S, 1, 6 * S), "#262824", False, 1, 1.0, cls="SpawnLocation",
                  extra='<bool name="Neutral">true</bool>'))

MATCHMAKING = r'''-- THE LOBBY: elevators that take a group to their own game.
-- Walk into an elevator. When 2-4 players are in it, it counts down
-- and everyone in it goes to a private Chapter 1 game together.
-- The first person in an elevator can make it FRIENDS ONLY.
--
-- Which place is the game? This finds it by itself (the other place in
-- this experience). If you have more places, put the game's place ID in
-- the GamePlaceId value inside this script.
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hall = workspace:WaitForChild("Hall")
local messageEvent = ReplicatedStorage:WaitForChild("LobbyMessage")
local actionEvent = ReplicatedStorage:WaitForChild("ElevatorAction")

local MIN_PLAYERS = 2
local MAX_PLAYERS = 4
local WAIT_TIME = 15

local function say(player, text)
	if player then messageEvent:FireClient(player, text) else messageEvent:FireAllClients(text) end
end

local function sign(part, face, color, size)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0.2
	gui.PixelsPerStud = 40
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SpecialElite
	label.TextScaled = size == nil
	if size then label.TextSize = size end
	label.TextWrapped = true
	label.TextColor3 = color
	label.Parent = gui
	return label
end

local function gamePlaceId()
	local value = script:FindFirstChild("GamePlaceId")
	if value and value.Value ~= 0 then return value.Value end
	local ok, pages = pcall(function() return AssetService:GetGamePlacesAsync() end)
	if not ok then return nil end
	while true do
		for _, place in ipairs(pages:GetCurrentPage()) do
			if place.PlaceId ~= game.PlaceId then return place.PlaceId end
		end
		if pages.IsFinished then break end
		pages:AdvanceToNextPageAsync()
	end
	return nil
end

-- Signs.
local title = sign(hall:WaitForChild("TitleBoard"), Enum.NormalId.Right, Color3.fromRGB(220, 60, 40))
title.Text = "SUBJECT ZERO\nSITE 12 - VISITOR CENTER"
local howTo = sign(hall:WaitForChild("HowToBoard"), Enum.NormalId.Left, Color3.fromRGB(110, 255, 140))
howTo.Font = Enum.Font.Code
howTo.TextXAlignment = Enum.TextXAlignment.Left
howTo.TextYAlignment = Enum.TextYAlignment.Top
howTo.Text = "HOW TO PLAY\n\n0. Pick a character\n   (buttons at the bottom).\n\n1. Walk into an ELEVATOR\n   with your friends\n   (or with anyone!).\n\n2. 2-4 players: it leaves\n   in " .. WAIT_TIME .. " seconds.\n\n3. Pick your character,\n   then survive Chapter 1\n   TOGETHER.\n\nFRIENDS ONLY: the first\nperson in can lock it\nto their friends.\n\nInvite friends: button\non the left of your screen."
-- Writing on the walls.
local scrawl = sign(hall:WaitForChild("Scrawl1"), Enum.NormalId.Right, Color3.fromRGB(120, 10, 6))
scrawl.Text = "LET ME OUT"
scrawl.Font = Enum.Font.Creepster
local scrawl2 = sign(hall:WaitForChild("Scrawl2"), Enum.NormalId.Back, Color3.fromRGB(110, 12, 8))
scrawl2.Text = "IT CAN SEE YOU"
scrawl2.Font = Enum.Font.Creepster
sign(hall:WaitForChild("ObsSign"), Enum.NormalId.Left, Color3.fromRGB(200, 60, 40)).Text = "OBSERVATION  -  SUBJECT 7"
local NAMES = { Son = "THE SON (Ethan)", Journalist = "THE JOURNALIST", Engineer = "THE ENGINEER", Guard = "THE GUARD (Frank)" }
for id, name in pairs(NAMES) do
	local s = hall:FindFirstChild("PedestalSign_" .. id)
	if s then sign(s, Enum.NormalId.Front, Color3.fromRGB(230, 220, 195)).Text = name .. "\n(pick in the game - you keep your avatar)" end
end

-- The elevators.
local elevators = {}
for i = 1, 4 do
	local e = {
		index = i, pad = hall:WaitForChild("ElevatorPad" .. i), gate = hall:WaitForChild("ElevatorGate" .. i),
		lamp = hall:WaitForChild("ElevatorStatusLamp" .. i), members = {}, friendsOnly = false, countdown = nil, leaving = false,
	}
	e.gateUp = e.gate.CFrame
	e.ribs, e.ribsUp = {}, {}
	for _, rib in ipairs(hall:GetChildren()) do
		if rib.Name == "ElevatorGateRib" .. i then table.insert(e.ribs, rib) e.ribsUp[rib] = rib.CFrame end
	end
	e.label = sign(hall:WaitForChild("ElevatorSign" .. i), Enum.NormalId.Back, Color3.fromRGB(230, 220, 195))
	elevators[i] = e
end

local friendCache = {}
local function areFriends(a, b)
	local key = math.min(a.UserId, b.UserId) .. "-" .. math.max(a.UserId, b.UserId)
	if friendCache[key] == nil then
		local ok, result = pcall(function() return a:IsFriendsWith(b.UserId) end)
		friendCache[key] = ok and result or false
	end
	return friendCache[key]
end

local function inside(e, root)
	local p = e.pad.CFrame:PointToObjectSpace(root.Position)
	local s = e.pad.Size
	return math.abs(p.X) < s.X / 2 and math.abs(p.Z) < s.Z / 2 and p.Y > -s.Y and p.Y < s.Y
end

local function indexOf(list, item)
	for i, v in ipairs(list) do if v == item then return i end end
	return nil
end

local function eject(e, player, why)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(e.pad.Position + Vector3.new(0, 0, e.pad.Size.Z / 2 + 6)) end
	if why then say(player, why) end
end

local function setMembership(player, e)
	for _, other in ipairs(elevators) do
		local i = indexOf(other.members, player)
		if i and other ~= e then
			table.remove(other.members, i)
			if #other.members == 0 then other.friendsOnly = false end
		end
	end
	if e and not indexOf(e.members, player) then table.insert(e.members, player) end
	player:SetAttribute("Elevator", e and e.index or nil)
	player:SetAttribute("ElevatorOwner", e ~= nil and e.members[1] == player or nil)
end

local function launch(e)
	e.leaving = true
	local group = table.clone(e.members)
	-- The lights go crazy, then the shutter SLAMS down.
	local lamp = hall:FindFirstChild("ElevatorLamp" .. e.index)
	local bulb = lamp and lamp:FindFirstChildOfClass("PointLight")
	for _ = 1, 10 do
		if bulb then bulb.Enabled = not bulb.Enabled end
		task.wait(0.08)
	end
	if bulb then bulb.Enabled = true bulb.Color = Color3.fromRGB(255, 40, 20) end
	local drop = Vector3.new(0, 3.5 * 3.2, 0)
	TweenService:Create(e.gate, TweenInfo.new(0.35, Enum.EasingStyle.Bounce), { CFrame = e.gateUp - drop }):Play()
	for _, rib in ipairs(e.ribs) do
		TweenService:Create(rib, TweenInfo.new(0.35, Enum.EasingStyle.Bounce), { CFrame = e.ribsUp[rib] - drop }):Play()
	end
	e.label.Text = "ELEVATOR " .. e.index .. "\nGOING DOWN..."
	task.wait(1.5)
	local placeId = gamePlaceId()
	local ok, err = false, "the game place wasn't found"
	if placeId then
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true  -- a private game just for this group
		local roles = {}
		for _, p in ipairs(group) do roles[tostring(p.UserId)] = p:GetAttribute("Character") end
		options:SetTeleportData({ lobby = game.PlaceId, roles = roles })
		ok, err = pcall(function() TeleportService:TeleportAsync(placeId, group, options) end)
	end
	if not ok then
		for _, p in ipairs(group) do
			say(p, RunService:IsStudio() and "(In Studio the elevator can't go anywhere: it only works in the published game.)"
				or ("The elevator is stuck (" .. tostring(err) .. "). Try again in a moment."))
		end
		task.wait(3)
	else
		task.wait(8)
	end
	TweenService:Create(e.gate, TweenInfo.new(1.2), { CFrame = e.gateUp }):Play()
	for _, rib in ipairs(e.ribs) do TweenService:Create(rib, TweenInfo.new(1.2), { CFrame = e.ribsUp[rib] }):Play() end
	if bulb then bulb.Color = Color3.fromRGB(255, 140, 76) end
	e.leaving = false
	e.countdown = nil
end

-- Characters picked here in the lobby travel with you into the game.
local ROLE_IDS = { Son = true, Journalist = true, Engineer = true, Guard = true }
ReplicatedStorage:WaitForChild("PickCharacter").OnServerEvent:Connect(function(player, id)
	if typeof(id) == "string" and ROLE_IDS[id] then
		player:SetAttribute("Character", id)
		say(player, "You'll be " .. NAMES[id] .. ". (If a teammate picked it too, you choose again in the game.)")
	end
end)

actionEvent.OnServerEvent:Connect(function(player, action)
	local index = player:GetAttribute("Elevator")
	local e = index and elevators[index]
	if not e or e.leaving then return end
	if action == "leave" then
		setMembership(player, nil)
		eject(e, player, nil)
	elseif action == "friends" and e.members[1] == player then
		e.friendsOnly = not e.friendsOnly
		say(player, e.friendsOnly and "Friends only: only your friends can get in." or "Open: anyone can get in.")
		if e.friendsOnly then
			for _, other in ipairs(table.clone(e.members)) do
				if other ~= player and not areFriends(player, other) then
					setMembership(other, nil)
					eject(e, other, "That elevator is now friends only.")
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) setMembership(player, nil) end)

while true do
	task.wait(0.25)
	-- Who is standing in which elevator?
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local now = nil
		if root then
			for _, e in ipairs(elevators) do
				if inside(e, root) then now = e end
			end
		end
		local was = player:GetAttribute("Elevator") and elevators[player:GetAttribute("Elevator")]
		if now ~= was then
			if now and now.leaving then
				eject(now, player, "That elevator is leaving!")
				now = nil
			elseif now and #now.members >= MAX_PLAYERS then
				eject(now, player, "That elevator is full (4 players). Try another one!")
				now = nil
			elseif now and now.friendsOnly and now.members[1] and not areFriends(now.members[1], player) then
				eject(now, player, "That elevator is FRIENDS ONLY.")
				now = nil
			end
			setMembership(player, now)
			if now then say(player, "You're in elevator " .. now.index .. ". It leaves when " .. MIN_PLAYERS .. "-4 players are in.") end
		end
		if now then player:SetAttribute("ElevatorOwner", now.members[1] == player) end
	end
	-- Countdowns and signs.
	for _, e in ipairs(elevators) do
		if not e.leaving then
			local n = #e.members
			local kind = e.friendsOnly and "FRIENDS ONLY" or "OPEN TO ANYONE"
			if n >= MIN_PLAYERS then
				local left = (e.countdown or WAIT_TIME) - 0.25
				e.countdown = left
				e.label.Text = ("ELEVATOR %d  -  %s\n%d/4 PLAYERS\nLEAVING IN %d"):format(e.index, kind, n, math.ceil(left))
				e.lamp.Color = Color3.fromRGB(255, 200, 40)
				if left <= 0 then task.spawn(launch, e) end
			else
				e.countdown = nil
				e.label.Text = ("ELEVATOR %d  -  %s\n%d/4 PLAYERS\n%s"):format(e.index, kind, n,
					n == 0 and "WALK IN TO PLAY" or "WAITING FOR 1 MORE...")
				e.lamp.Color = n == 0 and Color3.fromRGB(64, 255, 96) or Color3.fromRGB(80, 160, 255)
			end
		end
	end
end
'''


HAUNTING = r'''-- THE LOBBY IS NOT SAFE: flickering lamps, a pulsing red emergency
-- light, and something in the observation room that watches you... and
-- sometimes slams against the glass.
local hall = workspace:WaitForChild("Hall")

local function flicker(light, broken)
	local base = light.Brightness
	while true do
		if math.random() < broken then
			light.Brightness = 0
			task.wait(0.03 + math.random() * 0.15)
		else
			light.Brightness = base * (0.75 + math.random() * 0.25)
			task.wait(math.random() < 0.5 and (0.05 + math.random() * 0.3) or (0.6 + math.random() * 3))
		end
	end
end
for _, part in ipairs(hall:GetChildren()) do
	if part.Name == "Lamp" or string.sub(part.Name, 1, 12) == "ElevatorLamp" and not string.find(part.Name, "Cage") then
		local light = part:FindFirstChildOfClass("PointLight")
		if light then task.spawn(flicker, light, math.random() < 0.5 and 0.35 or 0.15) end
	end
end
local emergency = hall:WaitForChild("EmergencyLight"):FindFirstChildOfClass("PointLight")
task.spawn(function()
	local t = 0
	while true do
		t += task.wait(0.05)
		emergency.Brightness = 0.4 + 1.4 * math.max(0, math.sin(t * 2.2))
	end
end)

-- The watcher in the observation room.
local watcher = {}
for _, part in ipairs(hall:GetChildren()) do
	if string.sub(part.Name, 1, 8) == "Watcher_" then table.insert(watcher, part) end
end
local torso = hall:WaitForChild("Watcher_Torso")
local glass = hall:WaitForChild("ObsGlass")
local redLight = hall:WaitForChild("ObsRedLight"):FindFirstChildOfClass("PointLight")
local home = torso.Position
local function moveTo(target)
	local delta = target - torso.Position
	for _, part in ipairs(watcher) do part.CFrame = part.CFrame + delta end
end
local function show(visible)
	for _, part in ipairs(watcher) do part.LocalTransparencyModifier = 0 part.Transparency = visible and 0 or 1 end
end
local SPOTS = {}
for _, dz in ipairs({ -2.6, 0, 2.6 }) do
	for _, dx in ipairs({ 0, 1.2 }) do
		table.insert(SPOTS, home + Vector3.new(dx * 3.2 * 0.5, 0, dz * 3.2) - Vector3.new(0, 0, 2.5 * 3.2))
	end
end
while true do
	task.wait(6 + math.random() * 9)
	show(false)
	task.wait(0.4 + math.random())
	if math.random() < 0.25 then
		-- SLAM against the glass: lights die, red flash, then gone.
		local z = glass.Position.Z + (math.random() - 0.5) * glass.Size.Z * 0.6
		moveTo(Vector3.new(glass.Position.X + 1.4, home.Y, z))
		show(true)
		redLight.Brightness = 6
		for _, part in ipairs(hall:GetChildren()) do
			if part.Name == "Lamp" then
				local l = part:FindFirstChildOfClass("PointLight")
				if l then l.Enabled = false task.delay(0.6, function() l.Enabled = true end) end
			end
		end
		task.wait(1.2)
		redLight.Brightness = 0.6
		show(false)
		task.wait(1)
	end
	moveTo(SPOTS[math.random(1, #SPOTS)])
	show(true)
end
'''

LOBBY_UI = r'''-- Lobby buttons: Invite friends (always), and Leave / Friends only when
-- you're in an elevator. Plus messages.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local actionEvent = ReplicatedStorage:WaitForChild("ElevatorAction")

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local function button(text, pos, color)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0, 1)
	b.Position = pos
	b.Size = UDim2.fromOffset(200, 50)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(240, 235, 220)
	b.Font = Enum.Font.SpecialElite
	b.TextSize = 22
	b.Text = text
	b.Parent = gui
	return b
end
local invite = button("Invite friends", UDim2.new(0, 20, 1, -150), Color3.fromRGB(60, 90, 70))
local leave = button("Leave elevator", UDim2.new(0, 20, 1, -90), Color3.fromRGB(110, 50, 40))
local friends = button("Make it friends only", UDim2.new(0, 20, 1, -30), Color3.fromRGB(50, 70, 110))
invite.Activated:Connect(function()
	pcall(function()
		if SocialService:CanSendGameInviteAsync(player) then SocialService:PromptGameInvite(player) end
	end)
end)
leave.Activated:Connect(function() actionEvent:FireServer("leave") end)
friends.Activated:Connect(function() actionEvent:FireServer("friends") end)
local function refresh()
	local inLift = player:GetAttribute("Elevator") ~= nil
	leave.Visible = inLift
	friends.Visible = inLift and player:GetAttribute("ElevatorOwner") == true
end
player:GetAttributeChangedSignal("Elevator"):Connect(refresh)
player:GetAttributeChangedSignal("ElevatorOwner"):Connect(refresh)
refresh()

-- PICK YOUR CHARACTER: big buttons at the bottom (you keep your own avatar).
local pickEvent = ReplicatedStorage:WaitForChild("PickCharacter")
local ROLES = {
	{ id = "Son", name = "THE SON", power = "Sees the monster through walls", color = Color3.fromRGB(150, 100, 60) },
	{ id = "Journalist", name = "THE JOURNALIST", power = "Camera flash blinds him", color = Color3.fromRGB(205, 175, 125) },
	{ id = "Engineer", name = "THE ENGINEER", power = "Fixes things 3x faster", color = Color3.fromRGB(90, 120, 200) },
	{ id = "Guard", name = "THE GUARD", power = "Strong + survives one catch", color = Color3.fromRGB(130, 150, 90) },
}
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -95)
panel.Size = UDim2.new(0.6, 0, 0, 130)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
panel.BackgroundTransparency = 0.25
panel.Parent = gui
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(900, 130)
sizeLimit.MinSize = Vector2.new(420, 130)
sizeLimit.Parent = panel
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundTransparency = 1
header.Font = Enum.Font.SpecialElite
header.TextSize = 20
header.TextColor3 = Color3.fromRGB(230, 220, 195)
header.Text = "PICK YOUR CHARACTER  (you keep your own avatar)"
header.Parent = panel
local row = Instance.new("Frame")
row.Position = UDim2.new(0, 8, 0, 32)
row.Size = UDim2.new(1, -16, 1, -40)
row.BackgroundTransparency = 1
row.Parent = panel
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.Parent = row
local pickButtons = {}
for _, role in ipairs(ROLES) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.25, -6, 1, 0)
	b.BackgroundColor3 = role.color
	b.Font = Enum.Font.SpecialElite
	b.TextSize = 17
	b.TextWrapped = true
	b.TextColor3 = Color3.new(0, 0, 0)
	b.Text = role.name .. "\n" .. role.power
	b.Parent = row
	b.Activated:Connect(function() pickEvent:FireServer(role.id) end)
	pickButtons[role.id] = b
end
local function refreshPick()
	local mine = player:GetAttribute("Character")
	for _, role in ipairs(ROLES) do
		local b = pickButtons[role.id]
		b.Text = (mine == role.id and "YOU: " or "") .. role.name .. "\n" .. role.power
		b.BackgroundColor3 = mine == role.id and role.color:Lerp(Color3.new(1, 1, 1), 0.4) or role.color
	end
	header.Text = mine and "Picked! Now walk into an elevator." or "PICK YOUR CHARACTER  (you keep your own avatar)"
end
player:GetAttributeChangedSignal("Character"):Connect(refreshPick)
refreshPick()

local message = Instance.new("TextLabel")
message.AnchorPoint = Vector2.new(0.5, 1)
message.Position = UDim2.new(0.5, 0, 0.85, 0)
message.Size = UDim2.new(0.8, 0, 0, 34)
message.BackgroundTransparency = 1
message.Font = Enum.Font.SpecialElite
message.TextSize = 26
message.TextColor3 = Color3.fromRGB(235, 228, 205)
message.TextStrokeTransparency = 0.3
message.TextTransparency = 1
message.Parent = gui
local id = 0
ReplicatedStorage:WaitForChild("LobbyMessage").OnClientEvent:Connect(function(text)
	id += 1
	local mine = id
	message.Text = text
	message.TextTransparency = 0
	message.TextStrokeTransparency = 0.3
	task.delay(4, function()
		if mine == id then TweenService:Create(message, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end
	end)
end)
'''

xml = ['<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
       'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
       f'<Item class="Workspace" referent="{new_ref()}"><Properties><string name="Name">Workspace</string></Properties>',
       f'<Item class="Model" referent="{new_ref()}"><Properties><string name="Name">Hall</string></Properties>' + "".join(parts) + "</Item>",
       "</Item>",
       f'<Item class="Lighting" referent="{new_ref()}"><Properties><string name="Name">Lighting</string>'
       '<float name="ClockTime">0</float><float name="Brightness">0</float><token name="Technology">4</token>'
       '<Color3 name="Ambient"><R>0.03</R><G>0.03</G><B>0.035</B></Color3>'
       '<Color3 name="OutdoorAmbient"><R>0.12</R><G>0.13</G><B>0.18</B></Color3></Properties>'
       f'<Item class="ColorCorrectionEffect" referent="{new_ref()}"><Properties><string name="Name">Cold</string>'
       '<float name="Contrast">0.2</float><float name="Saturation">-0.35</float>'
       '<Color3 name="TintColor"><R>0.92</R><G>0.95</G><B>1</B></Color3></Properties></Item>'
       f'<Item class="Atmosphere" referent="{new_ref()}"><Properties><string name="Name">Haze</string>'
       '<float name="Density">0.35</float><float name="Haze">1.5</float>'
       '<Color3 name="Color"><R>0.12</R><G>0.12</G><B>0.11</B></Color3><Color3 name="Decay"><R>0.05</R><G>0.05</G><B>0.05</B></Color3>'
       '</Properties></Item></Item>',
       f'<Item class="ReplicatedStorage" referent="{new_ref()}"><Properties><string name="Name">ReplicatedStorage</string></Properties>'
       + "".join(f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">{n}</string></Properties></Item>'
                 for n in ("LobbyMessage", "ElevatorAction", "PickCharacter")) + "</Item>",
       f'<Item class="StarterPlayer" referent="{new_ref()}"><Properties><string name="Name">StarterPlayer</string>'
       '<token name="CameraMode">0</token><float name="CameraMaxZoomDistance">16</float></Properties>'
       f'<Item class="StarterPlayerScripts" referent="{new_ref()}"><Properties><string name="Name">StarterPlayerScripts</string></Properties>'
       + script("LocalScript", "LobbyButtons", LOBBY_UI) + "</Item></Item>",
       f'<Item class="ServerScriptService" referent="{new_ref()}"><Properties><string name="Name">ServerScriptService</string></Properties>'
       + script("Script", "Haunting", HAUNTING) + script("Script", "Elevators", MATCHMAKING,
                f'<Item class="IntValue" referent="{new_ref()}"><Properties><string name="Name">GamePlaceId</string>'
                '<int64 name="Value">0</int64></Properties></Item>') + "</Item>",
       "</roblox>"]
open(OUT, "w").write("\n".join(xml))
print(f"wrote {OUT}: {len(parts)} parts")
