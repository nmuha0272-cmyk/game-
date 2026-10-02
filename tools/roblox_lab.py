"""Roblox version: the opening cutscene, the flashlight tool, and the
"old 1960s lab" look underground (tiled walls, checkered floors, lab
benches, specimen jars, growth tanks, reel-to-reel computers, a gurney,
warning signs). Used by make_roblox.py."""
import math, random

S = 3.2
random.seed(12)

# The rooms carved out of the rock (from tools/make_chapter1.py): center, size.
ROOMS = {
    "Junction": ((9, -7.65, -40), (10, 2.7, 9.0)), "TunnelT": ((9, -7.65, -60.25), (4, 2.7, 29.5)),
    "AlcoveA1": ((12.5, -7.65, -60), (3, 2.7, 4)), "AlcoveA2": ((5.5, -7.65, -65), (3, 2.7, 4)),
    "TunnelE": ((21, -7.65, -68), (20, 2.7, 2)), "AlcoveA3": ((20.5, -7.65, -71), (3, 2.7, 4)),
    "ElevatorRoom": ((38, -7, -68), (16, 4, 18)), "Cell": ((9, -7, -81), (10, 4, 10)),
}
OPENINGS = {  # other holes that cut through the walls (doorways, vents, stairs, shaft)
    "D1": ((9, -7.475, -45), (2, 3.05, 1.2)), "D2": ((12, -7.475, -68), (0.6, 3.05, 2)),
    "D3": ((30, -7.475, -68), (0.6, 3.05, 2)), "CellOpening": ((9, -7.65, -75.5), (2, 2.7, 1.2)),
    "C1": ((2.85, -8.375, -41), (2.7, 1.25, 1.0)), "C3": ((4.3, -8.375, -48.5), (5.6, 1.25, 1.0)),
    "Stairs": ((9, -7.65, -31.5), (2, 2.7, 11)), "Shaft": ((38, -25, -56), (4.4, 40, 6.4)),
}
LAB_ROOMS = ["Junction", "TunnelT", "AlcoveA1", "AlcoveA2", "TunnelE", "AlcoveA3", "ElevatorRoom"]

INTRO_SHOTS = [
    ((-14, 9, 62), (0, 2, -6), (-6, 6.5, 50), (0, 2, -8), 5.0, "1999. Site 12 was sealed... with people still inside."),
    ((-6.5, 1.8, 27), (-4, 1.7, 22), (-4.6, 1.7, 24.6), (-4, 1.7, 22), 3.5, "Officially, it was only ever a weather station."),
    ((7, 2.2, 15), (-5, 3.4, -9), (3, 2.8, 9), (-5, 3.4, -9), 4.0, "2015. You came looking for answers."),
    ((0.5, 1.7, 30), (0, 1.4, 22), (0.2, 1.65, 26), (0, 1.3, 22), 2.5, "CHAPTER 1  -  THE SURFACE"),
]

# Extra signs for the lab (Godot position, which way the sign faces, text, color, letter size in m).
LAB_SIGNS = [
    ((5.6, -7.0, -35.52), (0, 0, -1), "SITE 12\nLEVEL A - LABORATORIES", "c9c2a8", 0.16),
    ((12.4, -7.3, -35.52), (0, 0, -1), "PROJECT IRONWOOD\nAUTHORIZED PERSONNEL ONLY", "b33a2a", 0.09),
    ((10.5, -7.0, -74.98), (0, 0, 1), "BIOHAZARD\nSUBJECT 7 - DO NOT OPEN", "d4a017", 0.08),
    ((10.98, -7.2, -48.5), (-1, 0, 0), "DECONTAMINATION\nSHOWER BEFORE\nRETURNING TO SURFACE", "9fb39c", 0.08),
    ((38, -5.6, -76.98), (0, 0, 1), "PROJECT IRONWOOD - PROGRAM ZERO\nSTRONGER SOLDIERS. SAFER NATION.", "c9c2a8", 0.14),
    ((30.02, -7.0, -61.6), (1, 0, 0), "ROOM B-1\nGROWTH STUDIES", "c9c2a8", 0.12),
]


def g(p): return tuple(c * S for c in p)
W = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def box_lohi(c, s):
    return [c[i] - s[i] / 2 for i in range(3)], [c[i] + s[i] / 2 for i in range(3)]


def subtract_rect(r, cut):
    """r, cut: (u0, u1, y0, y1). Returns the pieces of r outside cut."""
    u0, u1, y0, y1 = r
    c0, c1, d0, d1 = cut
    if c1 <= u0 or c0 >= u1 or d1 <= y0 or d0 >= y1:
        return [r]
    out = []
    if c0 > u0: out.append((u0, c0, y0, y1))
    if c1 < u1: out.append((c1, u1, y0, y1))
    m0, m1 = max(u0, c0), min(u1, c1)
    if d0 > y0: out.append((m0, m1, y0, d0))
    if d1 < y1: out.append((m0, m1, d1, y1))
    return out


def walls(name):
    """The 4 walls of a room, minus the doorways: (axis, plane, inward sign, rects)."""
    lo, hi = box_lohi(*ROOMS[name])
    others = [box_lohi(*v) for k, v in list(ROOMS.items()) + list(OPENINGS.items()) if k != name]
    res = []
    for axis, u_axis in ((0, 2), (2, 0)):
        for plane, inward in ((lo[axis], 1), (hi[axis], -1)):
            rects = [(lo[u_axis], hi[u_axis], lo[1], hi[1])]
            for olo, ohi in others:
                if olo[axis] - 0.05 <= plane <= ohi[axis] + 0.05:
                    cut = (olo[u_axis], ohi[u_axis], olo[1], ohi[1])
                    rects = [q for r in rects for q in subtract_rect(r, cut)]
            res.append((axis, u_axis, plane, inward, [r for r in rects if r[1] - r[0] > 0.05 and r[3] - r[2] > 0.05]))
    return res


def build(part):
    out = []

    def bx(name, lo, hi, color, collide=True, shape=1):
        c = [(lo[i] + hi[i]) / 2 for i in range(3)]
        s = [abs(hi[i] - lo[i]) for i in range(3)]
        if shape == 2:  # cylinder standing up
            out.append(part(name, g(c), ((0, 1, 0), (-1, 0, 0), (0, 0, 1)), g((s[1], s[0], s[2])), color, collide, 2))
        else:
            out.append(part(name, g(c), W, g(s), color, collide, shape))

    def at(name, c, s, color, collide=True, shape=1):
        bx(name, [c[i] - s[i] / 2 for i in range(3)], [c[i] + s[i] / 2 for i in range(3)], color, collide, shape)

    # 1. Tiled walls: green lower half, a dark stripe, cream upper half.
    for room in LAB_ROOMS:
        floor = box_lohi(*ROOMS[room])[0][1]
        for axis, u_axis, plane, inward, rects in walls(room):
            for u0, u1, y0, y1 in rects:
                for (b0, b1, color) in ((floor, floor + 1.05, "#3f5a47"), (floor + 1.05, floor + 1.11, "#1d2a22"),
                                        (floor + 1.11, y1, "#b9b49f")):
                    a0, a1 = max(b0, y0), min(b1, y1)
                    if a1 - a0 < 0.02:
                        continue
                    lo = [0, a0, 0]; hi = [0, a1, 0]
                    lo[axis] = plane + inward * 0.012; hi[axis] = plane + inward * 0.03
                    lo[u_axis] = u0; hi[u_axis] = u1
                    bx("LabWall", lo, hi, color, False)
    # The cell: dirty padded walls.
    for axis, u_axis, plane, inward, rects in walls("Cell"):
        for u0, u1, y0, y1 in rects:
            for k in range(int((u1 - u0) / 1.0) + 1):
                a, b = u0 + k * 1.0, min(u1, u0 + (k + 1) * 1.0)
                if b - a < 0.05:
                    continue
                lo = [0, y0, 0]; hi = [0, y1, 0]
                lo[axis] = plane + inward * 0.012; hi[axis] = plane + inward * 0.09
                lo[u_axis] = a + 0.02; hi[u_axis] = b - 0.02
                shade = random.choice(["#cbc4ae", "#c2bba3", "#b8ae94", "#a99e83"])
                bx("PaddedWall", lo, hi, "fabric:" + shade, False)

    # 2. Checkered floors (black and white tiles) in the junction and elevator room.
    for room, tile in (("Junction", 0.9), ("ElevatorRoom", 1.0)):
        lo, hi = box_lohi(*ROOMS[room])
        nx, nz = int((hi[0] - lo[0]) / tile), int((hi[2] - lo[2]) / tile)
        for i in range(nx):
            for k in range(nz):
                x0 = lo[0] + i * tile; z0 = lo[2] + k * tile
                col = "#d6d1bd" if (i + k) % 2 == 0 else "#262824"
                bx("FloorTile", (x0, lo[1] + 0.018, z0), (x0 + tile, lo[1] + 0.03, z0 + tile), col, False)

    # 3. Pipes along the tunnel ceilings.
    for x in (7.35, 7.6):
        bx("Pipe", (x - 0.07, -6.62, -74.8), (x + 0.07, -6.48, -45.7), "#5c5f55", False)
    for z in (-67.35, -67.6):
        bx("Pipe", (12.4, -6.62, z - 0.07), (29.6, -6.48, z + 0.07), "#5c5f55", False)
    for z in range(-73, -46, 4):
        bx("PipeClamp", (7.2, -6.66, z - 0.04), (7.75, -6.44, z + 0.04), "#3a3a34", False)

    def bench(name, lo_x, hi_x, lo_z, hi_z, floor):
        bx(name + "Top", (lo_x, floor + 0.86, lo_z), (hi_x, floor + 0.92, hi_z), "#2d2b26")
        bx(name + "Base", (lo_x + 0.05, floor, lo_z + 0.05), (hi_x - 0.05, floor + 0.86, hi_z - 0.05), "#4b5a4c")
        # Specimen jars with glowing green stuff inside.
        n = int(max(hi_x - lo_x, hi_z - lo_z) / 0.45)
        for k in range(n):
            t = (k + 0.5) / n
            cx = lo_x + (hi_x - lo_x) * (t if hi_x - lo_x > hi_z - lo_z else 0.5)
            cz = lo_z + (hi_z - lo_z) * (t if hi_z - lo_z >= hi_x - lo_x else 0.5)
            if random.random() < 0.3:
                at(name + "Papers", (cx, floor + 0.925, cz), (0.22, 0.01, 0.3), "#cfc8b0", False)
                continue
            h = random.uniform(0.18, 0.32)
            bx("JarGlass", (cx - 0.07, floor + 0.92, cz - 0.07), (cx + 0.07, floor + 0.92 + h, cz + 0.07), "glass:#9fb8a8", False, 2)
            liquid = random.choice(["!4f8a3a", "!7a8f2a", "#6b5a2a", "!3f7a5a"])
            bx("JarLiquid", (cx - 0.055, floor + 0.93, cz - 0.055), (cx + 0.055, floor + 0.92 + h * 0.75, cz + 0.055), liquid, False, 2)
            if random.random() < 0.6:
                at("JarThing", (cx, floor + 0.92 + h * 0.4, cz), (0.05, 0.07, 0.05), "#b8a48a", False, 0)

    def computer(name, x, z, face, floor):
        """An old reel-to-reel computer cabinet against a wall; face = +1 / -1: it faces +x / -x."""
        bx(name, (x - 0.25, floor, z - 0.9), (x + 0.25, floor + 1.95, z + 0.9), "#8a8d80")
        f = x + face * 0.255
        for off in (-0.22, 0.22):
            out.append(part("Reel", g((f, floor + 1.45, z + off)), W, g((0.02, 0.3, 0.3)), "#1c1c1a", False, 2))
            out.append(part("ReelHub", g((f + face * 0.01, floor + 1.45, z + off)), W, g((0.02, 0.08, 0.08)), "#9a9a90", False, 2))
        for k in range(6):
            lamp = random.choice(["!ff3b1f", "!ffd04a", "!5aff5a", "#3a1010"])
            at("Blinker", (f, floor + 1.05, z - 0.3 + k * 0.12), (0.02, 0.04, 0.04), lamp, False)
        at("Panel", (f, floor + 0.7, z), (0.02, 0.4, 0.75), "#2f322c", False)

    # 4. Junction: lab bench with jars, an old computer, a gurney, an IV stand.
    F = -9.0
    bench("BenchJ", 12.9, 13.9, -43.6, -38.4, F)
    computer("ComputerJ", 13.65, -37.0, -1, F)
    at("GurneyBed", (5.0, F + 0.8, -37.4), (0.75, 0.08, 1.9), "#9a9c94")
    at("GurneySheet", (5.0, F + 0.86, -37.25), (0.78, 0.05, 1.5), "fabric:#c9c2ae", False)
    at("GurneyStain", (5.0, F + 0.89, -37.5), (0.35, 0.01, 0.4), "#4a1a12", False)
    for dx in (-0.33, 0.33):
        for dz in (-0.85, 0.85):
            at("GurneyLeg", (5.0 + dx, F + 0.38, -37.4 + dz), (0.04, 0.76, 0.04), "#6b6d66", False)
    at("IVPole", (5.75, F + 0.95, -38.6), (0.03, 1.9, 0.03), "#8a8c86", False)
    at("IVBag", (5.75, F + 1.75, -38.48), (0.14, 0.22, 0.05), "glass:#c7a98f", False)
    # Alcove A1: a shelf of jars.
    bench("ShelfA1", 13.45, 13.95, -59.6, -58.3, F)
    # 5. The cell: a rusty restraint bed with straps.
    at("RestraintBed", (12.6, F + 0.55, -83.5), (0.95, 0.1, 2.0), "#5e5a4e")
    for dz in (-0.6, 0.0, 0.6):
        at("Strap", (12.6, F + 0.61, -83.5 + dz), (1.0, 0.03, 0.08), "#3b2a1c", False)
    for dx in (-0.42, 0.42):
        for dz in (-0.9, 0.9):
            at("BedLeg", (12.6 + dx, F + 0.25, -83.5 + dz), (0.05, 0.5, 0.05), "#4a463c", False)
    # 6. The elevator room: two glowing growth tanks, computer banks, a lab bench.
    for k, (x, z) in enumerate(((33.2, -60.4), (43.0, -60.4))):
        bx(f"TankBase{k}", (x - 0.65, F, z - 0.65), (x + 0.65, F + 0.35, z + 0.65), "#4a4d44", True, 2)
        bx(f"TankGlass{k}", (x - 0.55, F + 0.35, z - 0.55), (x + 0.55, F + 2.6, z + 0.55), "glass:#a8c8b0", True, 2)
        bx(f"TankLiquid{k}", (x - 0.5, F + 0.36, z - 0.5), (x + 0.5, F + 2.3, z + 0.5), "!2f6a3a", False, 2)
        bx(f"TankTop{k}", (x - 0.65, F + 2.6, z - 0.65), (x + 0.65, F + 2.9, z + 0.65), "#4a4d44", True, 2)
        at(f"TankShape{k}", (x, F + 1.35, z), (0.35, 1.4, 0.25), "#1d2a1c", False, 0)
        bx(f"TankPipe{k}", (x - 0.06, F + 2.9, z - 0.06), (x + 0.06, -5.0, z + 0.06), "#5c5f55", False, 2)
    for k, z in enumerate((-65.9, -64.6, -63.3)):
        computer(f"ComputerW{k}", 30.3, z, 1, F)
    for k, z in enumerate((-66.8, -65.5)):
        computer(f"ComputerE{k}", 45.7, z, -1, F)
    bench("BenchE", 34.0, 37.0, -76.95, -76.25, F)

    # The lab's own signs, in the level file's label format.
    labels = []
    for pos, n, text, color, size in LAB_SIGNS:
        right = (n[2], 0, -n[0])  # up x normal
        labels.append({"p": [-pos[2] * 100, pos[0] * 100, pos[1] * 100], "x": [-right[2], right[0], right[1]],
                       "z": [0, 0, 1], "text": text, "color": color, "size": size * 100})
    return out, labels


def intro_shots():
    def v(p): return f"Vector3.new({p[0] * S:.2f}, {p[1] * S:.2f}, {p[2] * S:.2f})"
    def q(t): return '"' + t.replace('"', '\\"') + '"'
    return ", ".join("{" + f"{v(a)}, {v(la)}, {v(b)}, {v(lb)}, {t}, {q(txt)}" + "}" for a, la, b, lb, t, txt in INTRO_SHOTS)


INTRO_SCRIPT = r'''-- THE OPENING CUTSCENE: plays once when you join, right after you pick
-- your character.
-- Skip it: Space, A / Cross, or click "Skip".
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SHOTS = { --SHOTS-- }

if not player.Character then player.CharacterAdded:Wait() end
-- First everyone picks a character (CharacterPick script), THEN the opening plays.
if not player:GetAttribute("Character") then player:GetAttributeChangedSignal("Character"):Wait() end
task.wait(1)
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
controls:Disable()

local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")
for _, top in ipairs({ true, false }) do
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.new(0, 0, 0)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0.12, 0)
	bar.Position = UDim2.new(0, 0, top and 0 or 0.88, 0)
	bar.Parent = gui
end
local caption = Instance.new("TextLabel")
caption.BackgroundTransparency = 1
caption.Size = UDim2.new(0.9, 0, 0.08, 0)
caption.Position = UDim2.new(0.05, 0, 0.9, 0)
caption.TextColor3 = Color3.fromRGB(220, 210, 190)
caption.Font = Enum.Font.SpecialElite
caption.TextScaled = true
caption.Parent = gui
local skipButton = Instance.new("TextButton")
skipButton.BackgroundTransparency = 1
skipButton.AnchorPoint = Vector2.new(1, 0)
skipButton.Position = UDim2.new(0.97, 0, 0.025, 0)
skipButton.Size = UDim2.new(0.18, 0, 0.06, 0)
skipButton.Font = Enum.Font.SpecialElite
skipButton.TextScaled = true
skipButton.TextColor3 = Color3.fromRGB(160, 155, 140)
skipButton.Text = UserInputService.GamepadEnabled and "[A] Skip" or "[Space] Skip"
skipButton.Parent = gui

local skipped = false
skipButton.Activated:Connect(function() skipped = true end)
local skipKey = UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then skipped = true end
end)

camera.CameraType = Enum.CameraType.Scriptable
for _, shot in ipairs(SHOTS) do
	if skipped then break end
	caption.Text = shot[6]
	caption.TextTransparency = 1
	TweenService:Create(caption, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()
	local t = 0
	while t < shot[5] and not skipped do
		local k = t / shot[5]
		k = k * k * (3 - 2 * k)
		camera.CFrame = CFrame.lookAt(shot[1]:Lerp(shot[3], k), shot[2]:Lerp(shot[4], k))
		t += RunService.RenderStepped:Wait()
	end
end
skipKey:Disconnect()
camera.CameraType = Enum.CameraType.Custom
controls:Enable()
gui:Destroy()
task.wait(1)

-- A reminder about the flashlight.
local hint = Instance.new("ScreenGui")
hint.ResetOnSpawn = false
hint.Parent = player.PlayerGui
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0.12, 0)
label.Size = UDim2.new(0.8, 0, 0, 34)
label.Font = Enum.Font.SpecialElite
label.TextSize = 26
label.TextColor3 = Color3.fromRGB(235, 228, 205)
label.TextStrokeTransparency = 0.3
label.Text = UserInputService.GamepadEnabled and "Your flashlight is in your inventory: press Y / Triangle to take it out."
	or "Your flashlight is in your inventory: press 1 (or F) to take it out. Click to switch it off and on."
label.Parent = hint
task.wait(7)
TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
task.wait(1)
hint:Destroy()
'''
