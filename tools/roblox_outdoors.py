"""A new look for the outside in the Roblox version: real Roblox terrain
(grass, a dirt yard, a cracked concrete path, an asphalt road with muddy
edges, rocks, rolling hills around the forest), drifting ground mist,
better pine trees, and a misty moonlit sky. Used by make_roblox.py.
The terrain is made by a script when the game starts (Roblox terrain
can't be written into the place file directly)."""
import math, random

S = 3.2
rng = random.Random(7)

# Areas (Godot meters, x1, x2, z1, z2) and their terrain material.
STATION = (-10.6, 10.6, -16.6, 0.4)
SHED = (8.3, 11.7, 10.3, 13.7)
YARD = (-15, 15, 0, 22)
PATH = (-1.3, 1.3, 0.3, 22.3)
ROAD = (-70, 70, 36, 42)
WORLD = (-70, 70, -45, 85)
STAIRS = (7.3, 10.7, -28, -15)        # the hidden stairwell runs just under the ground here
UNDERGROUND = (-8, 56, -98, -12)      # keep hills away from the tunnels below


def cut(r, c):
    """Rectangle r minus rectangle c."""
    x1, x2, z1, z2 = r
    a1, a2, b1, b2 = c
    if a2 <= x1 or a1 >= x2 or b2 <= z1 or b1 >= z2:
        return [r]
    out = []
    if a1 > x1: out.append((x1, a1, z1, z2))
    if a2 < x2: out.append((a2, x2, z1, z2))
    m1, m2 = max(x1, a1), min(x2, a2)
    if b1 > z1: out.append((m1, m2, z1, b1))
    if b2 < z2: out.append((m1, m2, b2, z2))
    return out


def minus(rects, holes):
    for h in holes:
        rects = [q for r in rects for q in cut(r, h)]
    return rects


def fills():
    """(material, x1, x2, z1, z2) blocks, laid on top of the ground."""
    out = []
    shoulders = [(ROAD[0], ROAD[1], ROAD[2] - 0.9, ROAD[2]), (ROAD[0], ROAD[1], ROAD[3], ROAD[3] + 0.9)]
    for r in minus([WORLD], [STATION, YARD, STAIRS, (ROAD[0], ROAD[1], ROAD[2] - 0.9, ROAD[3] + 0.9)]):
        out.append(("Grass",) + r)
    for r in minus([YARD], [STATION, SHED, PATH]):
        out.append(("Ground",) + r)
    out.append(("Pavement",) + PATH)
    out.append(("Asphalt",) + ROAD)
    for r in shoulders:
        out.append(("Mud",) + r)
    return out


def outside_walls(x, z):
    return abs(x) > 24 or z > 52 or z < -18


def blobs():
    """(material, x, y, z, radius) balls: dirt patches, rocks, hills."""
    out = []
    def free(x, z, pad=1.0):
        for a1, a2, b1, b2 in (STATION, SHED, PATH, (ROAD[0], ROAD[1], ROAD[2] - 1, ROAD[3] + 1), (-12, -6, 37, 41)):
            if a1 - pad < x < a2 + pad and b1 - pad < z < b2 + pad:
                return False
        return not (-1.6 < x < 1.6 and 20 < z < 24)  # the gate
    # Leafy, muddy patches in the forest and the yard.
    for _ in range(140):
        x, z = rng.uniform(-23, 23), rng.uniform(-1, 51)
        if free(x, z, 1.5):
            inside_yard = -15 < x < 15 and 0 < z < 22
            out.append((rng.choice(["Mud", "Ground"] if inside_yard else ["LeafyGrass", "LeafyGrass", "Ground", "Mud"]),
                        x, -0.35, z, rng.uniform(0.8, 2.0)))
    # Rocks in the forest (not in the yard).
    for _ in range(45):
        x, z = rng.uniform(-22, 22), rng.uniform(-1, 50)
        if free(x, z, 2.0) and not (-15.5 < x < 15.5 and -0.5 < z < 22.5):
            out.append(("Rock", x, -0.2, z, rng.uniform(0.35, 1.1)))
    # Rolling hills outside the walkable area (and behind the station).
    for _ in range(90):
        x, z = rng.uniform(-70, 70), rng.uniform(-45, 85)
        u = UNDERGROUND
        if outside_walls(x, z) and not (ROAD[2] - 3 < z < ROAD[3] + 3) and not (u[0] - 16 < x < u[1] + 16 and u[2] - 16 < z < u[3] + 16):
            out.append((rng.choice(["Grass", "Grass", "LeafyGrass", "Rock"]), x, rng.uniform(-9, -3), z, rng.uniform(8, 15)))
    return out


def mist_points():
    pts = []
    while len(pts) < 16:
        x, z = rng.uniform(-21, 21), rng.uniform(1, 49)
        if not (-11 < x < 11 and z < 1):
            pts.append((x, z))
    return pts


def v3(p): return f"Vector3.new({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})"


def script():
    f = ",\n\t".join(f'{{ Enum.Material.{m}, {x1 * S:.1f}, {x2 * S:.1f}, {z1 * S:.1f}, {z2 * S:.1f} }}' for m, x1, x2, z1, z2 in fills())
    b = ",\n\t".join(f'{{ Enum.Material.{m}, {v3((x * S, y * S, z * S))}, {r * S:.2f} }}' for m, x, y, z, r in blobs())
    mp = ", ".join(v3((x * S, 1.2, z * S)) for x, z in mist_points())
    return OUTDOORS.replace("--FILLS--", f).replace("--BLOBS--", b).replace("--MIST--", mp)


def pine(part, base, height, radius, seed):
    """A pine tree crown out of wedges. Trees near where you walk: 3 tiers,
    each 4 wedges back to back (looks like a cone from every side). Far
    trees: 2 tiers of 2 wedges (cheaper, so it runs well on Xbox/phones)."""
    r = random.Random(seed)
    yaw = r.uniform(0, math.pi / 2)
    out = []
    shades = ["#1f3322", "#24392a", "#1b2d1f", "#2a3f2c"]
    gx, gz = base[0] / S, base[2] / S
    near = abs(gx) < 30 and -5 < gz < 58
    tiers, sides = (3, 4) if near else (2, 2)
    for k in range(tiers):
        h = height * ((0.5 - k * 0.06) if near else (0.62 - k * 0.1))
        rad = radius * (1.0 - k * (0.28 if near else 0.4))
        y0 = base[1] + height * k * (0.27 if near else 0.38)
        color = r.choice(shades)
        for q in range(sides):
            a = yaw + q * (2 * math.pi / sides) + (k * math.pi / 2 if not near else 0) + r.uniform(-0.1, 0.1)
            right = (math.cos(a), 0, -math.sin(a)); back = (math.sin(a), 0, math.cos(a))
            c = (base[0] - back[0] * rad / 2, y0 + h / 2, base[2] - back[2] * rad / 2)
            out.append(part("Needles", c, (right, (0, 1, 0), back), (rad * 2 * 0.9, h, rad), color, False, 1, cls="WedgePart"))
    return out


OUTDOORS = r'''-- THE OUTSIDE: real Roblox terrain, made when the game starts.
-- Grass, a dirt yard, a cracked concrete path, an asphalt road with muddy
-- edges, mossy patches, rocks, rolling hills around the forest, and
-- drifting ground mist.
local terrain = workspace.Terrain
local THICK = 3     -- studs of terrain: from 1.8 below the flat ground to 1.2 above it

local FILLS = {
	--FILLS--
}
local BLOBS = {
	--BLOBS--
}
local MIST = { --MIST-- }

for _, f in ipairs(FILLS) do
	local x1, x2, z1, z2 = f[2], f[3], f[4], f[5]
	local size = Vector3.new(x2 - x1, THICK, z2 - z1)
	terrain:FillBlock(CFrame.new((x1 + x2) / 2, 1.2 - THICK / 2, (z1 + z2) / 2), size, f[1])
end
for _, b in ipairs(BLOBS) do
	terrain:FillBall(b[2], b[3], b[1])
end
-- Terrain colors: dark, wet, cold.
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(52, 66, 44))
terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(60, 62, 40))
terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(66, 56, 44))
terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(48, 40, 32))
terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(78, 78, 74))
terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(96, 94, 88))
terrain:SetMaterialColor(Enum.Material.Asphalt, Color3.fromRGB(38, 38, 40))

-- Ground mist: slow, low clouds drifting between the trees.
local mist = Instance.new("Folder")
mist.Name = "Mist"
mist.Parent = workspace
for _, p in ipairs(MIST) do
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(40, 1, 40)
	holder.Position = p
	holder.Parent = mist
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(150, 160, 180))
	e.LightInfluence = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86),
		NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(12, 18)
	e.Rate = 1.2
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 5)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-6, 6)
	e.Acceleration = Vector3.new(0.4, 0, 0.2)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = holder
end
'''
