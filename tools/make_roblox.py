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


def part(name, pos, axes, size, m, collide=True, shape=1, transparency=0.0, cls="Part", children="", extra=""):
    c = color_of(m)
    mat = 288 if m.startswith("!") else MATERIAL.get(m, 272)
    if m == "chainlink":
        transparency = 0.55
    rgb = 0xFF000000 | (c[0] << 16) | (c[1] << 8) | c[2]
    return (f'<Item class="{cls}" referent="{new_ref()}"><Properties>'
            f'<string name="Name">{escape(name)}</string><bool name="Anchored">true</bool>{cframe(pos, axes)}'
            f'<bool name="CanCollide">{"true" if collide else "false"}</bool>'
            f'<bool name="CastShadow">{"true" if transparency < 0.9 else "false"}</bool>'
            f'<Color3uint8 name="Color3uint8">{rgb}</Color3uint8><token name="Material">{mat}</token>'
            f'<token name="shape">{shape}</token><token name="TopSurface">0</token><token name="BottomSurface">0</token>'
            f'<Vector3 name="size"><X>{max(size[0], 0.05):.3f}</X><Y>{max(size[1], 0.05):.3f}</Y><Z>{max(size[2], 0.05):.3f}</Z></Vector3>'
            f'<float name="Transparency">{transparency}</float>{extra}</Properties>{children}</Item>')


def rot_cyl(axes):
    """Roblox cylinders point along their X; ours point up. Turn them."""
    r, u, b = axes
    return (u, tuple(-c for c in r), b)


parts = []
for i, s in enumerate(d["shapes"]):
    pos, axes, size = frame(s)
    kind, m, col = s["t"], s["m"], s["c"]
    if kind == "cube":
        parts.append(part("Block", pos, axes, size, m, col))
    elif kind == "sphere":
        parts.append(part("Ball", pos, axes, size, m, col, shape=0))
    elif kind == "cylinder":
        parts.append(part("Cylinder", pos, rot_cyl(axes), (size[1], size[0], size[2]), m, col, shape=2))
    elif kind == "cone":
        # No cones in Roblox: stack three shrinking discs (pine tree tiers).
        h, rad = size[1], size[0]
        up = axes[1]
        for k in range(3):
            t = (k + 0.5) / 3
            p = tuple(pos[j] + up[j] * (t - 0.5) * h for j in range(3))
            r_k = rad * (1 - t * 0.85)
            parts.append(part("Needles", p, rot_cyl(axes), (h / 3, r_k, r_k), m, False, shape=2))

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


FLASHLIGHT = '''-- Every player's avatar gets a flashlight on its head.
-- Press F (keyboard), Y (Xbox) or Triangle (PlayStation) to switch it.
local character = script.Parent
local head = character:WaitForChild("Head")
local player = game.Players:GetPlayerFromCharacter(character)

local light = Instance.new("SpotLight")
light.Name = "Flashlight"
light.Face = Enum.NormalId.Front
light.Angle = 50
light.Range = 45
light.Brightness = 4
light.Shadows = true
light.Parent = head

local toggle = Instance.new("RemoteEvent")
toggle.Name = "ToggleFlashlight"
toggle.Parent = character
toggle.OnServerEvent:Connect(function(who)
	if who == player then
		light.Enabled = not light.Enabled
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
local function longManNear(light)
	local longMan = workspace:FindFirstChild("LongMan")
	local root = longMan and longMan:FindFirstChild("Root")
	return root and light.Parent and (root.Position - light.Parent.Position).Magnitude < 30
end

local function flicker(light, brokenness)
	local base = light.Brightness
	local normal = brokenness
	while light.Parent do
		brokenness = longManNear(light) and 0.85 or normal
		if math.random() < brokenness then
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
       LM.build(part, script, new_ref), "</Item>",
       f'<Item class="ReplicatedStorage" referent="{new_ref()}"><Properties><string name="Name">ReplicatedStorage</string></Properties>'
       f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">LongManJumpScare</string></Properties></Item>'
       f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">LongManReveal</string></Properties></Item></Item>',
       f'<Item class="Lighting" referent="{new_ref()}"><Properties><string name="Name">Lighting</string>'
       '<float name="ClockTime">0</float><float name="Brightness">0.6</float><token name="Technology">4</token>'
       '<Color3 name="Ambient"><R>0.05</R><G>0.05</G><B>0.07</B></Color3>'
       '<Color3 name="OutdoorAmbient"><R>0.12</R><G>0.13</G><B>0.18</B></Color3>'
       '<float name="FogEnd">220</float><float name="FogStart">10</float>'
       '<Color3 name="FogColor"><R>0.03</R><G>0.035</G><B>0.05</B></Color3>'
       '<bool name="GlobalShadows">true</bool></Properties></Item>',
       f'<Item class="StarterPlayer" referent="{new_ref()}"><Properties><string name="Name">StarterPlayer</string>'
       '<token name="CameraMode">0</token><float name="CameraMaxZoomDistance">14</float>'
       '<float name="CharacterWalkSpeed">14</float></Properties>',
       f'<Item class="StarterCharacterScripts" referent="{new_ref()}"><Properties><string name="Name">StarterCharacterScripts</string></Properties>',
       script("Script", "Flashlight", FLASHLIGHT), script("LocalScript", "FlashlightKey", FLASHLIGHT_KEY),
       script("LocalScript", "Sprint", LM.SPRINT_SCRIPT), "</Item>",
       f'<Item class="StarterPlayerScripts" referent="{new_ref()}"><Properties><string name="Name">StarterPlayerScripts</string></Properties>',
       script("LocalScript", "LongManEffects", LM.EFFECTS_SCRIPT.replace("--SHOTS--", LM.reveal_shots())), "</Item></Item>",
       f'<Item class="ServerScriptService" referent="{new_ref()}"><Properties><string name="Name">ServerScriptService</string></Properties>',
       script("Script", "FlickeringLights", FLICKER), "</Item>",
       "</roblox>"]
open(OUT, "w").write("\n".join(xml))
print(f"wrote {OUT}: {len(parts)} parts, {len(lights)} lights, {len(spawns)} spawns")
