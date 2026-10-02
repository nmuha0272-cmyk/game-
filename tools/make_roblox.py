"""Builds the Roblox version's place file: roblox/SubjectZero_Chapter1.rbxlx.
Open it in Roblox Studio (File -> Open from File). Everyone plays as their
own Roblox avatar (that's Roblox's default), with a flashlight.

It uses the same level as the other versions (unreal_easy/.../level.json:
plain blocks, stairs as steps). Run after tools/make_unreal_easy.py:
    python3 tools/make_roblox.py
"""
import json, math
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import roblox_long_man as LM
import roblox_puzzles as PZ
import roblox_lab as LAB
import roblox_roles as ROLES
import roblox_outdoors as OD
from xml.sax.saxutils import escape

KIT = "unreal_easy/SubjectZero_Kit/level.json"
OUT = "roblox/SubjectZero_Chapter1.rbxlx"
S = 3.2  # studs per meter (a Roblox avatar is about 5 studs tall)

# Roblox Enum.Material values for our surfaces.
MATERIAL = {"ground": 1360, "terrain": 848, "cinder_block": 848, "concrete_wall": 816, "concrete_floor": 816,
            "rock": 896, "painted_wall": 816, "wood": 528, "dark_wood": 512, "rusty_metal": 1040,
            "asphalt": 1376, "lino_floor": 784, "chainlink": 1056}
COLOR = {"ground": (52, 45, 36), "terrain": (95, 97, 92), "cinder_block": (95, 97, 92), "concrete_wall": (115, 113, 106),
         "concrete_floor": (78, 77, 72), "rock": (64, 62, 55), "painted_wall": (70, 88, 74), "wood": (92, 64, 40),
         "dark_wood": (55, 38, 26), "rusty_metal": (68, 72, 64), "asphalt": (28, 28, 30), "lino_floor": (85, 84, 72),
         "chainlink": (60, 60, 58)}

d = json.load(open(KIT))
ref = [0]
def new_ref():
    ref[0] += 1
    return f"RBX{ref[0]}"


def to_godot(v):
    """Level file (Unreal: cm, Z up) -> meters, Y up (same axes as Roblox)."""
    return (v[1], v[2], -v[0])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def frame(e):
    X, Z = e["x"], e["z"]
    Y = cross(Z, X)
    right, up, back = to_godot(Y), to_godot(Z), tuple(-c for c in to_godot(X))
    pos = tuple(c / 100.0 * S for c in to_godot(e["p"]))
    size = (e["s"][1] / 100.0 * S, e["s"][2] / 100.0 * S, e["s"][0] / 100.0 * S)
    return pos, (right, up, back), size


def cframe(pos, axes):
    r, u, b = axes
    vals = [r[0], u[0], b[0], r[1], u[1], b[1], r[2], u[2], b[2]]
    names = ["R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"]
    return ('<CoordinateFrame name="CFrame">' + "".join(f"<{n}>{v:.4f}</{n}>" for n, v in zip("XYZ", pos)) +
            "".join(f"<{n}>{v:.5f}</{n}>" for n, v in zip(names, vals)) + "</CoordinateFrame>")


def color_of(m):
    if m.startswith("#") or m.startswith("!"):
        h = m[1:]
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    return COLOR.get(m, (128, 128, 128))


SPECIAL = {"fabric": 1312, "glass": 1568}  # "glass:#rrggbb" = that material in that color


def part(name, pos, axes, size, m, collide=True, shape=1, transparency=0.0, cls="Part", children="", extra="", anchored=True):
    special = None
    if ":" in m:
        special, m = m.split(":")
        if special == "glass":
            transparency = max(transparency, 0.55)
    c = color_of(m)
    mat = SPECIAL[special] if special else 288 if m.startswith("!") else MATERIAL.get(m, 272)
    if not collide:
        extra += '<bool name="CanQuery">false</bool>'  # decoration: rays and the Long Man's eyes pass through
    if m == "chainlink":
        transparency = 0.55
    rgb = 0xFF000000 | (c[0] << 16) | (c[1] << 8) | c[2]
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties>'
            f'<string name="Name">{escape(name)}</string><bool name="Anchored">{"true" if anchored else "false"}</bool>{cframe(pos, axes)}'
            f'<bool name="CanCollide">{"true" if collide else "false"}</bool>'
            f'<bool name="CastShadow">{"true" if transparency < 0.9 else "false"}</bool>'
            f'<Color3uint8 name="Color3uint8">{rgb}</Color3uint8><token name="Material">{mat}</token>'
            + (f'<token name="shape">{shape}</token>' if cls in ("Part", "SpawnLocation") else "") +
            f'<token name="TopSurface">0</token><token name="BottomSurface">0</token>'
            f'<Vector3 name="size"><X>{max(size[0], 0.05):.3f}</X><Y>{max(size[1], 0.05):.3f}</Y><Z>{max(size[2], 0.05):.3f}</Z></Vector3>'
            f'<float name="Transparency">{transparency}</float>{extra}</Properties>{children}</Item>')


def rot_cyl(axes):
    """Roblox cylinders point along their X; ours point up. Turn them."""
    r, u, b = axes
    return (u, tuple(-c for c in r), b)


lab_parts, lab_labels = LAB.build(part)
d["labels"] += lab_labels
puzzle_xml, PUZZLE_SRC, PUZZLE_UI, in_elevator, TEAM_SRC = PZ.build(part, frame, new_ref, d)
parts, elevator = [], []
for i, s in enumerate(d["shapes"]):
    if s.get("door") in PZ.PUZZLE_DOORS:
        continue  # the puzzles put a closed door here instead
    pos, axes, size = frame(s)
    target = elevator if in_elevator(pos) else parts
    kind, m, col = s["t"], s["m"], s["c"]
    if kind == "cube":
        target.append(part("Block", pos, axes, size, m, col))
    elif kind == "sphere":
        target.append(part("Ball", pos, axes, size, m, col, shape=0))
    elif kind == "cylinder":
        target.append(part("Cylinder", pos, rot_cyl(axes), (size[1], size[0], size[2]), m, col, shape=2))
    elif kind == "cone":
        # No cones in Roblox: a pine crown out of wedges (see roblox_outdoors.py).
        h = size[1]
        base = (pos[0], pos[1] - h / 2, pos[2])
        target.extend(OD.pine(part, base, h, size[0] / 2, i))

lights = []
for L in d["lights"]:
    pos = tuple(c / 100.0 * S for c in to_godot(L["p"]))
    c = L["color"]
    rgb = tuple(int(c[i:i + 2], 16) / 255 for i in (0, 2, 4))
    name = f"FlickerLight_{L['flicker']:.2f}" if L["flicker"] >= 0 else ("PulseLight" if L["pulse"] else "Light")
    pl = (f'<Item class="PointLight" referent="{new_ref()}"><Properties>'
          f'<float name="Brightness">{L["energy"] * 1.6:.2f}</float>'
          f'<Color3 name="Color"><R>{rgb[0]:.3f}</R><G>{rgb[1]:.3f}</G><B>{rgb[2]:.3f}</B></Color3>'
          f'<float name="Range">{min(60.0, L["range"] / 100.0 * S):.1f}</float>'
          f'<bool name="Shadows">{"true" if L["shadow"] else "false"}</bool></Properties></Item>')
    lights.append(part(name, pos, ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (0.3, 0.3, 0.3), "!" + c, False, 0, 0.0, children=pl))

spawns = []
for sp in d["spawns"]:
    pos = tuple(c / 100.0 * S for c in to_godot(sp["p"]))
    pos = (pos[0], pos[1] + 0.5, pos[2])
    spawns.append(part("Spawn", pos, ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (6, 1, 6), "asphalt", False, 1, 1.0,
                       cls="SpawnLocation", extra='<bool name="Neutral">true</bool><bool name="AllowTeamChangeOnTouch">false</bool>'))


def script(cls, name, source):
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties><string name="Name">{name}</string>'
            f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString></Properties></Item>')


FLASHLIGHT = '''-- Every player starts with a FLASHLIGHT in their inventory (the hotbar).
-- Take it out (press 1, click it, or press F / Y / Triangle) and it turns
-- on. Click (or R2) to switch it off and on. Put it away and it goes off.
-- The light shines from your head, so it points where you look.
local character = script.Parent
local head = character:WaitForChild("Head")
local humanoid = character:WaitForChild("Humanoid")
local player = game.Players:GetPlayerFromCharacter(character)

local light = Instance.new("SpotLight")
light.Name = "Flashlight"
light.Face = Enum.NormalId.Front
light.Angle = 50
light.Range = 45
light.Brightness = 4
light.Shadows = true
light.Enabled = false
light.Parent = head

local connected = {}
local function holding()
	local tool = character:FindFirstChild("Flashlight")
	return tool and tool:IsA("Tool")
end
character.ChildAdded:Connect(function(thing)
	if thing:IsA("Tool") and thing.Name == "Flashlight" then
		light.Enabled = true
		if not connected[thing] then
			connected[thing] = true
			thing.Activated:Connect(function()
				if holding() then light.Enabled = not light.Enabled end
			end)
		end
	end
end)
character.ChildRemoved:Connect(function(thing)
	if thing:IsA("Tool") and thing.Name == "Flashlight" then light.Enabled = false end
end)

local toggle = Instance.new("RemoteEvent")
toggle.Name = "ToggleFlashlight"
toggle.Parent = character
toggle.OnServerEvent:Connect(function(who)
	if who ~= player then return end
	if holding() then
		light.Enabled = not light.Enabled
	else
		local tool = player.Backpack:FindFirstChild("Flashlight")
		if tool then humanoid:EquipTool(tool) end
	end
end)
'''
FLASHLIGHT_KEY = '''-- Sends "switch my flashlight" to the server when you press the button.
local UserInputService = game:GetService("UserInputService")
local toggle = script.Parent:WaitForChild("ToggleFlashlight")

UserInputService.InputBegan:Connect(function(input, typing)
	if typing then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY then
		toggle:FireServer()
	end
end)
'''
FLICKER = '''-- Makes the station's broken lights flicker and the warning lights pulse.
-- (A light's holder part is named FlickerLight_<how broken 0-1> or PulseLight.)
-- Lights go crazy when the Long Man is near (any light, broken or not).
-- (Right next to him they go out completely.)
local function longManDistance(light)
	local longMan = workspace:FindFirstChild("LongMan")
	local root = longMan and longMan:FindFirstChild("Root")
	return (root and light.Parent) and (root.Position - light.Parent.Position).Magnitude or math.huge
end
local function longManNear(light)
	return longManDistance(light) < 30
end

local function flicker(light, brokenness)
	local base = light.Brightness
	local normal = brokenness
	while light.Parent do
		brokenness = longManNear(light) and 0.85 or normal
		if longManDistance(light) < 14 then
			light.Brightness = 0
			task.wait(0.2)
		elseif math.random() < brokenness then
			light.Brightness = 0
			task.wait(0.03 + math.random() * 0.1 + math.random() * brokenness * 1.5)
		else
			light.Brightness = base * (0.85 + math.random() * 0.15)
			if math.random() < 0.5 then
				task.wait(0.05 + math.random() * 0.35)
			else
				task.wait(0.5 + math.random() * (4 * (1 - brokenness)))
			end
		end
	end
end

local function pulse(light)
	local base = light.Brightness
	local t = 0
	while light.Parent do
		t += task.wait(0.05)
		light.Brightness = base * (0.55 + 0.45 * math.sin(t * 3))
	end
end

for _, thing in ipairs(workspace:GetDescendants()) do
	if thing:IsA("PointLight") then
		local brokenness = tonumber(string.match(thing.Parent.Name, "^FlickerLight_([%d%.]+)$"))
		if brokenness then
			task.spawn(flicker, thing, brokenness)
		elseif thing.Parent.Name == "Light" then
			task.spawn(flicker, thing, 0)
		elseif thing.Parent.Name == "PulseLight" then
			task.spawn(pulse, thing)
		end
	end
end
'''

model = lambda name, items: (f'<Item class="Model" referent="{new_ref()}"><Properties><string name="Name">{name}</string></Properties>'
                             + "".join(items) + "</Item>")
xml = ['<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
       'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
       f'<Item class="Workspace" referent="{new_ref()}"><Properties><string name="Name">Workspace</string></Properties>',
       model("Chapter1_Level", parts), model("Chapter1_Lights", lights), model("Spawns", spawns),
       model("Elevator", elevator), model("Lab", lab_parts), puzzle_xml, LM.build(part, script, new_ref), "</Item>",
       f'<Item class="ReplicatedStorage" referent="{new_ref()}"><Properties><string name="Name">ReplicatedStorage</string></Properties>'
       f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">LongManJumpScare</string></Properties></Item>'
       f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">LongManReveal</string></Properties></Item>'
       + "".join(f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">{n}</string></Properties></Item>'
                 for n in ("PuzzleMessage", "PuzzleKeypad", "PuzzleRead", "ChapterEnd", "PickCharacter", "UseAbility", "CameraFlash"))
       + f'<Item class="Folder" referent="{new_ref()}"><Properties><string name="Name">LongManSounds</string></Properties>'
       + "".join(f'<Item class="StringValue" referent="{new_ref()}"><Properties><string name="Name">{n}</string>'
                 '<string name="Value"></string></Properties></Item>'
                 for n in ("Scream", "Shriek", "NeckCrack", "Skitter", "Breath", "Click", "Heartbeat"))
       + '</Item></Item>',
       f'<Item class="Lighting" referent="{new_ref()}"><Properties><string name="Name">Lighting</string>'
       '<float name="ClockTime">0</float><float name="Brightness">0.6</float><token name="Technology">4</token>'
       '<Color3 name="Ambient"><R>0.05</R><G>0.05</G><B>0.07</B></Color3>'
       '<Color3 name="OutdoorAmbient"><R>0.16</R><G>0.18</G><B>0.25</B></Color3>'
       '<float name="FogEnd">220</float><float name="FogStart">10</float>'
       '<Color3 name="FogColor"><R>0.03</R><G>0.035</G><B>0.05</B></Color3>'
       '<bool name="GlobalShadows">true</bool></Properties>'
       # A misty, cold, moonlit night.
       f'<Item class="Atmosphere" referent="{new_ref()}"><Properties><string name="Name">Atmosphere</string>'
       '<float name="Density">0.42</float><float name="Offset">0.15</float><float name="Glare">0</float><float name="Haze">2.2</float>'
       '<Color3 name="Color"><R>0.3</R><G>0.34</G><B>0.43</B></Color3><Color3 name="Decay"><R>0.08</R><G>0.1</G><B>0.15</B></Color3>'
       '</Properties></Item>'
       f'<Item class="Sky" referent="{new_ref()}"><Properties><string name="Name">Sky</string>'
       '<int name="StarCount">4000</int><bool name="CelestialBodiesShown">true</bool><float name="MoonAngularSize">16</float>'
       '</Properties></Item>'
       f'<Item class="ColorCorrectionEffect" referent="{new_ref()}"><Properties><string name="Name">ColdNight</string>'
       '<float name="Brightness">0.02</float><float name="Contrast">0.12</float><float name="Saturation">-0.3</float>'
       '<Color3 name="TintColor"><R>0.88</R><G>0.93</G><B>1</B></Color3></Properties></Item>'
       f'<Item class="BloomEffect" referent="{new_ref()}"><Properties><string name="Name">Glow</string>'
       '<float name="Intensity">0.6</float><float name="Size">24</float><float name="Threshold">1.4</float></Properties></Item>'
       '</Item>',
       f'<Item class="StarterPlayer" referent="{new_ref()}"><Properties><string name="Name">StarterPlayer</string>'
       '<token name="CameraMode">1</token><float name="CameraMaxZoomDistance">0.5</float>'
       '<float name="CharacterWalkSpeed">14</float></Properties>',
       f'<Item class="StarterCharacterScripts" referent="{new_ref()}"><Properties><string name="Name">StarterCharacterScripts</string></Properties>',
       script("Script", "Flashlight", FLASHLIGHT), script("LocalScript", "FlashlightKey", FLASHLIGHT_KEY),
       script("LocalScript", "Sprint", LM.SPRINT_SCRIPT), "</Item>",
       f'<Item class="StarterPlayerScripts" referent="{new_ref()}"><Properties><string name="Name">StarterPlayerScripts</string></Properties>',
       script("LocalScript", "LongManEffects", LM.EFFECTS_SCRIPT.replace("--SHOTS--", LM.reveal_shots())),
       script("LocalScript", "PuzzleUI", PUZZLE_UI), script("LocalScript", "CharacterPick", ROLES.ROLES_UI),
       script("LocalScript", "OpeningCutscene", LAB.INTRO_SCRIPT.replace("--SHOTS--", LAB.intro_shots())), "</Item></Item>",
       f'<Item class="StarterPack" referent="{new_ref()}"><Properties><string name="Name">StarterPack</string></Properties>'
       f'<Item class="Tool" referent="{new_ref()}"><Properties><string name="Name">Flashlight</string>'
       '<string name="ToolTip">Flashlight (click to switch off and on)</string><bool name="CanBeDropped">false</bool>'
       '<bool name="RequiresHandle">true</bool></Properties>'
       + part("Handle", (0, 0, 0), ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (0.35, 0.35, 1.3), "#1f1f1d", False, 1, anchored=False)
       + "</Item></Item>",
       f'<Item class="ServerScriptService" referent="{new_ref()}"><Properties><string name="Name">ServerScriptService</string></Properties>',
       script("Script", "FlickeringLights", FLICKER), script("Script", "Puzzles", PUZZLE_SRC), script("Script", "TeamLivesOrDies", TEAM_SRC),
       script("Script", "Characters", ROLES.ROLES_SERVER),
       script("Script", "Outdoors", OD.script()), "</Item>",
       "</roblox>"]
open(OUT, "w").write("\n".join(xml))
print(f"wrote {OUT}: {len(lab_parts)} lab parts, {len(parts)} parts, {len(elevator)} elevator parts, {len(lights)} lights, {len(spawns)} spawns")
