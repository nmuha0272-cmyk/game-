"""Chapter 1's puzzles for the Roblox version, the same as the PC game but
anyone can do every job (Roblox has no character roles yet).
The puzzle pieces are parts in Workspace > Puzzles; one server script
("Puzzles") runs them, and a LocalScript ("PuzzleUI") shows the keypad,
notes and messages. Used by make_roblox.py."""
import math

S = 3.2
PUZZLE_DOORS = ("DirectorDoor", "StairDoor", "BoltedDoor")
TOOLS = [("Crowbar", (8, 0.3, 15.5), (0.09, 0.09, 0.8), "#4a4038", "Jams things open."),
         ("Welcome Tape", (-6.5, 0.3, -14.8), (0.28, 0.06, 0.28), "#2a2622", "Reel tape: 'Welcome, Volunteers'"),
         ("Green Keycard", (6, 1.05, -10), (0.25, 0.02, 0.16), "#2f8a3a", "SITE 12 - GREEN"),
         ("Fuse", (9.2, -8.75, -55), (0.08, 0.2, 0.08), "!c8d8ff", "An old glass fuse."),
         ("Fuse", (20.5, -8.75, -72), (0.08, 0.2, 0.08), "!c8d8ff", "An old glass fuse.")]
CRAWL = [((1.4, -9.5, -41.6), (5.8, -6.5, -40.4)), ((1.4, -9.5, -49.1), (2.6, -6.5, -40.4)),
         ((1.4, -9.5, -49.1), (8.6, -6.5, -47.9))]
ELEVATOR_BOX = ((35.8, -9.5, -59.2), (40.2, -5.5, -52.8))
# Checkpoints (same as the PC game): walk into the box, and from then on
# the team comes back there. (box center, box size, respawn point)
CHECKPOINTS = [("the yard", (0, 1.5, 17), (8, 3, 4), (0, 0.5, 17)),
               ("the tunnels", (9, -7.5, -38), (8, 3, 4), (9, -8.5, -38)),
               ("the elevator room", (18, -7.5, -68), (4, 3, 2), (18, -8.5, -68))]
ROOM_LIGHTS = [(34, -5.6, -64), (42, -5.6, -72)]
CONTAINMENT = ("Level B Containment Order",
               "BY ORDER OF THE DIRECTOR - EMERGENCY CONTAINMENT, LEVEL B\n\nAll lower doors are to be sealed "
               "immediately, REGARDLESS OF PERSONNEL INSIDE.\n\nELEVATOR OVERRIDE: two officers must turn their "
               "launch keys AT THE SAME TIME.")
TAPE = ("Reel Tape 1: Welcome, Volunteers",
        "DIRECTOR CALLOWAY: Good morning, volunteers, and welcome to Site 12.\nWhat you do here will make this "
        "nation stronger than any other.\nYou will receive a simple course of vitamins. Nothing more.\nReport "
        "any... changes to the medical staff at once.\n\n(The tape clicks. Someone breathes very close to the "
        "microphone.)\n\nThe terminal beeps: VOICE ACCEPTED.")


def g(p): return tuple(c * S for c in p)
def v3(p): return f"Vector3.new({p[0]:.3f}, {p[1]:.3f}, {p[2]:.3f})"
def lua_str(s): return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
def yaw_axes(deg):
    a = math.radians(deg)
    return ((math.cos(a), 0, -math.sin(a)), (0, 1, 0), (math.sin(a), 0, math.cos(a)))
def cf_lua(pos, axes):
    r, u, b = axes
    vals = [r[0], u[0], b[0], r[1], u[1], b[1], r[2], u[2], b[2]]
    return "CFrame.new(" + ", ".join(f"{v:.4f}" for v in list(pos) + vals) + ")"


def build(part, frame, new_ref, kit):
    """Returns (workspace xml, server script source, ui script source, elevator part test)."""
    out = []
    W = ((1, 0, 0), (0, 1, 0), (0, 0, 1))

    def box(name, pos, size, color, yaw=0, collide=True, shape=1):
        out.append(part(name, g(pos), yaw_axes(yaw), g(size), color, collide, shape))

    box("Gate", (0, 1.3, 22), (3.1, 2.6, 0.08), "chainlink")
    box("GateLift", (-2.25, 1.0, 22.14), (0.12, 0.4, 0.12), "#6b6b60")
    box("GateJam", (2.25, 1.0, 21.86), (0.3, 0.4, 0.25), "#594d40")
    box("TapeMachine", (-8.5, 1.05, -9.4), (0.4, 0.3, 0.5), "#3a3630")
    for k, z in enumerate((-9.52, -9.28)):
        out.append(part(f"TapeReel{k}", g((-8.29, 1.12, z)), W, g((0.03, 0.2, 0.2)), "#1a1816", False, 2))
    box("Monitor", (-9.22, 1.28, -12), (0.05, 0.55, 0.75), "#0a0d0a")
    box("MonitorPower", (1.83, 1.3, -7.0), (0.06, 0.25, 0.12), "#7a2a20")
    box("OfficeKeypad", (1.83, 1.4, -8.0), (0.05, 0.3, 0.22), "#2f332c")
    box("FilingCabinet", (9.0, 0.75, -15.25), (0.9, 1.5, 0.6), "#525c4d")
    for k in range(3):
        box(f"CabinetDrawer{k}", (9.0, 0.35 + k * 0.45, -14.94), (0.8, 0.02, 0.02), "#a09a88", collide=False)
    box("VentCover", (4.05, -8.425, -41), (0.08, 1.15, 1.0), "#5a5c54")
    box("DoorBolt", (10.6, -7.7, -45.55), (0.35, 0.08, 0.08), "#6b6b60")
    box("FuseBoxEast", (45.95, -7.6, -70), (0.25, 0.6, 0.45), "#404d40")
    box("FuseBoxWest", (30.05, -7.6, -73), (0.25, 0.6, 0.45), "#404d40")
    box("Generator", (32.5, -8.5, -75.8), (1.4, 1.0, 0.8), "#4d5240")
    box("GeneratorLamp", (32.5, -7.92, -75.35), (0.12, 0.12, 0.12), "#330000", collide=False, shape=0)
    box("PowerLamp", (38, -5.4, -59.2), (0.2, 0.2, 0.2), "!ff2010", collide=False, shape=0)
    box("ContainmentOrder", (40, -8.09, -74), (0.3, 0.01, 0.4), "#ddd8c4", yaw=-10, collide=False)
    for side, x, z in (("West", 31.5, -61), ("East", 44.5, -75.5)):
        box("Console" + side, (x, -8.45, z), (0.5, 1.1, 0.7), "#474d40")
        box("Console" + side + "Key", (x, -7.88, z), (0.06, 0.06, 0.14), "#c9a640", collide=False)
    box("DescendButton", (39.84, -7.7, -57.5), (0.06, 0.15, 0.15), "!aa1a10")
    box("ElevatorGate", (41.8, -7.5, -58.95), (3.8, 3.0, 0.06), "chainlink")
    # The elevator room's ceiling lights: off until the power is back.
    for pos in ROOM_LIGHTS:
        pl = (f'<Item class="PointLight" referent="{new_ref()}"><Properties><float name="Brightness">2</float>'
              '<Color3 name="Color"><R>1</R><G>0.92</G><B>0.78</B></Color3><float name="Range">32</float>'
              '<bool name="Enabled">false</bool><bool name="Shadows">true</bool></Properties></Item>')
        out.append(part("RoomLight", g(pos), W, (1.2, 0.3, 3.5), "#8a8a80", False, 1, children=pl))

    # Closed doors (the level file only has them standing open).
    doors = []
    for dr in kit["doors"]:
        if dr["name"] not in PUZZLE_DOORS:
            continue
        frames = []
        for extra in (0, 100):
            yaw = math.radians(dr["yaw"] + extra)
            hx, hy, hz = dr["p"]
            e = {"p": [hx - math.sin(yaw) * 100, hy + math.cos(yaw) * 100, hz + 150],
                 "x": [math.cos(yaw), math.sin(yaw), 0], "z": [0, 0, 1], "s": [12, 200, 300]}
            frames.append(frame(e))
        (pos, axes, size), (_, open_axes, _) = frames
        out.append(part(dr["name"], pos, axes, size, "rusty_metal", True))
        r, ro = axes[0], open_axes[0]
        best = max((100, -100), key=lambda a: (r[0] * math.cos(math.radians(a)) + r[2] * math.sin(math.radians(a))) * ro[0]
                   + (-r[0] * math.sin(math.radians(a)) + r[2] * math.cos(math.radians(a))) * ro[2])
        hinge = (dr["p"][1] / 100 * S, (dr["p"][2] + 150) / 100 * S, -dr["p"][0] / 100 * S)
        doors.append(f'{dr["name"]} = {{ hinge = {v3(hinge)}, angle = math.rad({best}) }}')

    tools = []
    for name, pos, size, color, tip in TOOLS:
        handle = part("Handle", g(pos), W, g(size), color, True, 1, anchored=False)
        tools.append(f'<Item class="Tool" referent="{new_ref()}"><Properties><string name="Name">{name}</string>'
                     f'<string name="ToolTip">{tip}</string><bool name="CanBeDropped">true</bool>'
                     f'<bool name="RequiresHandle">true</bool></Properties>{handle}</Item>')

    # Signs (labels) from the level file.
    signs = []
    for lb in kit["labels"]:
        lines = lb["text"].split("\n")
        lh = lb["size"] / 100 * S
        w = max(len(l) for l in lines) * lh * 0.55 + lh * 0.4
        h = len(lines) * lh * 1.2
        x = (lb["x"][1], lb["x"][2], -lb["x"][0]); up = (lb["z"][1], lb["z"][2], -lb["z"][0])
        back = (x[1] * up[2] - x[2] * up[1], x[2] * up[0] - x[0] * up[2], x[0] * up[1] - x[1] * up[0])
        pos = (lb["p"][1] / 100 * S, lb["p"][2] / 100 * S, -lb["p"][0] / 100 * S)
        pos = tuple(pos[i] + back[i] * 0.03 for i in range(3))
        name = "ElevatorPanel" if lb["text"].startswith("LEVEL B") else "Sign"
        signs.append(f'{{ name = "{name}", cf = {cf_lua(pos, (x, up, back))}, size = Vector2.new({w:.2f}, {h:.2f}), '
                     f'text = {lua_str(lb["text"])}, color = Color3.fromHex("{lb["color"]}") }}')

    data = "\n".join([
        "local DOORS = { " + ", ".join(doors) + " }",
        "local CRAWL = { " + ", ".join(f"{{ {v3(g(a))}, {v3(g(b))} }}" for a, b in CRAWL) + " }",
        f"local ELEVATOR_BOX = {{ {v3(g(ELEVATOR_BOX[0]))}, {v3(g(ELEVATOR_BOX[1]))} }}",
        "local SIGNS = {\n\t" + ",\n\t".join(signs) + "\n}",
        f"local CONTAINMENT = {{ {lua_str(CONTAINMENT[0])}, {lua_str(CONTAINMENT[1])} }}",
        f"local TAPE = {{ {lua_str(TAPE[0])}, {lua_str(TAPE[1])} }}",
    ])
    ws = (f'<Item class="Model" referent="{new_ref()}"><Properties><string name="Name">Puzzles</string></Properties>'
          + "".join(out) + "</Item>"
          + f'<Item class="Folder" referent="{new_ref()}"><Properties><string name="Name">Items</string></Properties>'
          + "".join(tools) + "</Item>")

    def in_elevator(pos):
        q = tuple(c / S for c in pos)
        return all(ELEVATOR_BOX[0][i] <= q[i] <= ELEVATOR_BOX[1][i] for i in range(3))
    cps = "local CHECKPOINTS = {\n\t" + ",\n\t".join(
        f'{{ name = "{n}", center = {v3(g(c))}, size = {v3(g(sz))}, spawn = {v3(g(sp))} }}' for n, c, sz, sp in CHECKPOINTS) + "\n}"
    return ws, PUZZLE_SCRIPT.replace("--DATA--", data), UI_SCRIPT, in_elevator, TEAM_SCRIPT.replace("--DATA--", cps)


PUZZLE_SCRIPT = r'''-- CHAPTER 1 PUZZLES (Roblox version)
-- Every puzzle needs at least TWO players working together:
--  1. Gate: one lifts and holds the gate, another jams it with the crowbar
--     (crowbar is by the shed).
--  2. Office: play the welcome tape in the tape machine AND hold the
--     monitor power switch: the screen in the west office shows the door
--     code. Whoever is at the keypad (by the switch) can't see the screen,
--     so someone has to read it out!
--  3. The green keycard is in the director's office. A filing cabinet hides
--     the stairwell door: it takes two people to push it.
--  4. Tunnels: one holds the vent cover up, the others crawl through and
--     slide open the bolt on the other side.
--  5. Elevator room: two fuses (in the tunnels), repair the generator, read
--     the Containment Order, then turn both launch keys AT THE SAME TIME.
--  6. Everyone gets into the elevator and presses Descend.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local P = workspace:WaitForChild("Puzzles")
local messageEvent = ReplicatedStorage:WaitForChild("PuzzleMessage")
local keypadEvent = ReplicatedStorage:WaitForChild("PuzzleKeypad")
local readEvent = ReplicatedStorage:WaitForChild("PuzzleRead")
local endEvent = ReplicatedStorage:WaitForChild("ChapterEnd")

--DATA--

local CODE = string.format("%04d", math.random(0, 9999))

local function say(who, text)
	if who then messageEvent:FireClient(who, text) else messageEvent:FireAllClients(text) end
end

local function humanoidOf(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then return humanoid end
	return nil
end

local function findTool(player, name)
	local character = player.Character
	local tool = character and character:FindFirstChild(name)
	if tool and tool:IsA("Tool") then return tool end
	tool = player.Backpack:FindFirstChild(name)
	if tool and tool:IsA("Tool") then return tool end
	return nil
end

local function prompt(part, action, object, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object or ""
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p.Parent = part
	return p
end

local function slide(part, offset, seconds)
	TweenService:Create(part, TweenInfo.new(seconds or 0.8, Enum.EasingStyle.Quad), { CFrame = part.CFrame + offset }):Play()
end

local function openDoor(name)
	local door = P:FindFirstChild(name)
	local info = DOORS[name]
	if not door or not info or door:GetAttribute("Open") then return end
	door:SetAttribute("Open", true)
	local hinge = CFrame.new(info.hinge)
	local offset = hinge:ToObjectSpace(door.CFrame)
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(k)
		door.CFrame = hinge * CFrame.Angles(0, info.angle * k, 0) * offset
	end)
	TweenService:Create(value, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { Value = 1 }):Play()
end

-- Something one person holds (and has to stand still for).
-- Press E / X / Square to grab it, again (or walk away) to let go.
local function holdSwitch(part, action, onChange)
	local p = prompt(part, action, "")
	local holder = nil
	local function setHolder(player)
		local old = holder and humanoidOf(holder)
		if old then old:SetAttribute("Frozen", nil) end
		holder = player
		local humanoid = player and humanoidOf(player)
		if humanoid then humanoid:SetAttribute("Frozen", true) end
		p.ActionText = player and "Let go" or action
		onChange(player ~= nil)
	end
	p.Triggered:Connect(function(player)
		if holder == player then
			setHolder(nil)
		elseif holder == nil then
			setHolder(player)
			say(player, "Holding it. Stay still!  (Use it again to let go.)")
		else
			say(player, holder.DisplayName .. " is already holding it.")
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if holder then
				local humanoid = humanoidOf(holder)
				local root = holder.Character and holder.Character:FindFirstChild("HumanoidRootPart")
				if not humanoid or not root or (root.Position - part.Position).Magnitude > 12 or not holder.Parent then
					setHolder(nil)
				end
			end
		end
	end)
	return p
end

-- 1. THE GATE --------------------------------------------------------------
local gate = P.Gate
local gateDown = gate.CFrame
local gateLifted, gateJammed = false, false
holdSwitch(P.GateLift, "Lift the gate and hold it up", function(held)
	gateLifted = held
	if gateJammed then return end
	TweenService:Create(gate, TweenInfo.new(0.9), { CFrame = held and gateDown + Vector3.new(0, 6, 0) or gateDown }):Play()
end)
local jam = prompt(P.GateJam, "Jam the gate open", "Gate clamp", 2)
jam.Triggered:Connect(function(player)
	if not gateLifted then say(player, "Someone has to lift the gate first.") return end
	local crowbar = findTool(player, "Crowbar")
	if not crowbar then say(player, "It needs something to jam it with... a crowbar?") return end
	crowbar:Destroy()
	gateJammed = true
	gate.CFrame = gateDown + Vector3.new(0, 6, 0)
	jam:Destroy()
	say(nil, "The crowbar jams the gate open.")
end)

-- 2. THE DOOR CODE -----------------------------------------------------------
local tapePlayed, monitorOn, officeOpen = false, false, false
local screen = Instance.new("SurfaceGui")
screen.Face = Enum.NormalId.Right
screen.LightInfluence = 0
screen.Parent = P.Monitor
local screenText = Instance.new("TextLabel")
screenText.Size = UDim2.fromScale(1, 1)
screenText.BackgroundTransparency = 1
screenText.TextScaled = true
screenText.Font = Enum.Font.Code
screenText.TextColor3 = Color3.fromRGB(100, 255, 130)
screenText.Parent = screen
local function updateScreen()
	if tapePlayed and monitorOn then
		screenText.Text = "DIRECTOR'S TERMINAL\nDOOR CODE: " .. CODE
	elseif monitorOn then
		screenText.Text = "VOICE LOCKED"
	else
		screenText.Text = ""
	end
end
updateScreen()
local tape = prompt(P.TapeMachine, "Play a tape", "Tape machine", 1)
tape.Triggered:Connect(function(player)
	local reel = findTool(player, "Welcome Tape")
	if not reel then say(player, "There's no tape in it. A reel tape must be around here somewhere.") return end
	reel:Destroy()
	tapePlayed = true
	tape:Destroy()
	for _, other in ipairs(Players:GetPlayers()) do
		local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - P.TapeMachine.Position).Magnitude < 60 then
			readEvent:FireClient(other, TAPE[1], TAPE[2])
		end
	end
	updateScreen()
end)
holdSwitch(P.MonitorPower, "Hold the monitor power switch ON", function(held)
	monitorOn = held
	updateScreen()
end)
local keypad = prompt(P.OfficeKeypad, "Type the code", "Keypad")
-- A different button from the switch next to it, so whoever holds the
-- switch can still use the keypad.
keypad.KeyboardKeyCode = Enum.KeyCode.R
keypad.GamepadKeyCode = Enum.KeyCode.DPadUp
keypad.Triggered:Connect(function(player) keypadEvent:FireClient(player, "open") end)
keypadEvent.OnServerEvent:Connect(function(player, code)
	if officeOpen or typeof(code) ~= "string" then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - P.OfficeKeypad.Position).Magnitude > 15 then return end
	if code == CODE then
		officeOpen = true
		keypadEvent:FireClient(player, "right")
		keypad:Destroy()
		openDoor("DirectorDoor")
		say(nil, "The director's office unlocks.")
	else
		keypadEvent:FireClient(player, "wrong")
	end
end)

-- 3. THE CABINET AND THE STAIRWELL DOOR -------------------------------------
local pushers = {}
local cabinetMoved = false
local stairPrompt
local push = prompt(P.FilingCabinet, "Push the cabinet", "Heavy filing cabinet", 2.5)
push.PromptButtonHoldBegan:Connect(function(player) pushers[player] = true end)
push.PromptButtonHoldEnded:Connect(function(player) pushers[player] = nil end)
push.Triggered:Connect(function(player)
	local count = 1
	for other in pairs(pushers) do
		if other ~= player and other.Parent then count += 1 end
	end
	if count < 2 and player:GetAttribute("Character") ~= "Guard" then
		say(player, "It's too heavy for one person. Push it together at the same time (or Frank, the Guard, can move it alone)!")
		return
	end
	if cabinetMoved then return end
	cabinetMoved = true
	push:Destroy()
	local offset = Vector3.new(-2.1 * 3.2, 0, 0)
	for _, part in ipairs(P:GetChildren()) do
		if part.Name == "FilingCabinet" or string.sub(part.Name, 1, 13) == "CabinetDrawer" then slide(part, offset, 2) end
	end
	say(nil, "Behind the cabinet... a door.")
	stairPrompt.Enabled = true
end)
stairPrompt = prompt(P.StairDoor, "Open", "Stairwell door")
stairPrompt.Enabled = false
stairPrompt.Triggered:Connect(function(player)
	if not findTool(player, "Green Keycard") then say(player, "Locked. The reader blinks: GREEN KEYCARD.") return end
	stairPrompt:Destroy()
	openDoor("StairDoor")
	say(nil, "The keycard reader beeps. The stairwell door opens.")
end)

-- 4. THE VENT AND THE BOLT ---------------------------------------------------
local vent = P.VentCover
local ventDown = vent.CFrame
holdSwitch(vent, "Lift the vent cover and hold it", function(held)
	vent.CanCollide = not held
	TweenService:Create(vent, TweenInfo.new(0.5), { CFrame = held and ventDown + Vector3.new(0, 3.3, 0) or ventDown }):Play()
end)
local bolt = prompt(P.DoorBolt, "Slide the door bolt open", "Bolt", 1)
bolt.Triggered:Connect(function()
	bolt:Destroy()
	slide(P.DoorBolt, Vector3.new(-0.8, 0, 0), 0.4)
	openDoor("BoltedDoor")
	say(nil, "The bolted door swings open.")
end)
-- You shrink to crawl through the vent, and grow back when you get out.
local function inCrawl(pos)
	for _, b in ipairs(CRAWL) do
		local lo, hi = b[1], b[2]
		if pos.X >= lo.X and pos.X <= hi.X and pos.Y >= lo.Y and pos.Y <= hi.Y and pos.Z >= lo.Z and pos.Z <= hi.Z then
			return true
		end
	end
	return false
end
task.spawn(function()
	while true do
		task.wait(0.15)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local want = inCrawl(root.Position) and 0.55 or 1
				if math.abs(character:GetScale() - want) > 0.01 then
					character:ScaleTo(want)
				end
			end
		end
	end
end)

-- 5. POWER AND THE LAUNCH KEYS -----------------------------------------------
local fuses = { FuseBoxEast = false, FuseBoxWest = false }
local generatorFixed, powered, orderRead, overridden = false, false, false, false
local roomLights = {}
for _, part in ipairs(P:GetChildren()) do
	if part.Name == "RoomLight" then
		table.insert(roomLights, part:FindFirstChildOfClass("PointLight"))
	end
end
local panelText
local function checkPower()
	if powered or not generatorFixed or not fuses.FuseBoxEast or not fuses.FuseBoxWest then return end
	powered = true
	for _, light in ipairs(roomLights) do light.Enabled = true light.Parent.Material = Enum.Material.Neon end
	P.PowerLamp.Color = Color3.fromRGB(40, 255, 60)
	if panelText then panelText.Text = "LEVEL B - SEALED BY ORDER\nOVERRIDE: TWO KEYS" end
	say(nil, "Power restored. The elevator panel flickers on.")
end
for name in pairs(fuses) do
	local box = P[name]
	local p = prompt(box, "Put in a fuse", "Fuse box", 1.5)
	p:SetAttribute("EngineerHold", 0.4)  -- the Engineer is quicker
	p.Triggered:Connect(function(player)
		local fuse = findTool(player, "Fuse")
		if not fuse then say(player, "The fuse is missing. There must be spare fuses in the tunnels.") return end
		fuse:Destroy()
		p:Destroy()
		fuses[name] = true
		box.Color = Color3.fromRGB(70, 90, 70)
		say(player, "The fuse clicks in.")
		checkPower()
	end)
end
local generator = prompt(P.Generator, "Repair the generator", "Broken generator", 6)
generator:SetAttribute("EngineerHold", 2)  -- the Engineer is quicker
generator.Triggered:Connect(function()
	generator:Destroy()
	generatorFixed = true
	P.GeneratorLamp.Color = Color3.fromRGB(255, 200, 120)
	P.GeneratorLamp.Material = Enum.Material.Neon
	say(nil, "The generator coughs and starts humming.")
	checkPower()
end)
local order = prompt(P.ContainmentOrder, "Read", "Containment Order")
order.Triggered:Connect(function(player)
	orderRead = true
	readEvent:FireClient(player, CONTAINMENT[1], CONTAINMENT[2])
end)
local turned = {}
for _, side in ipairs({ "ConsoleWest", "ConsoleEast" }) do
	local p = prompt(P[side], "Turn the launch key", "Launch key")
	p.Triggered:Connect(function(player)
		if overridden then return end
		if not powered or not orderRead then
			say(player, "Dead. It needs power, and the override procedure (find the Containment Order).")
			return
		end
		turned[side] = os.clock()
		local key = P[side .. "Key"]
		key.CFrame = key.CFrame * CFrame.Angles(0, 0, math.rad(90))
		local other = side == "ConsoleWest" and "ConsoleEast" or "ConsoleWest"
		if turned[other] and os.clock() - turned[other] < 1 then
			overridden = true
			say(nil, "Override accepted. Everyone into the elevator!")
		else
			task.delay(0.6, function()
				if not overridden then
					key.CFrame = key.CFrame * CFrame.Angles(0, 0, math.rad(-90))
					say(player, "The key springs back. Both keys must turn at the SAME time. Count down: 3, 2, 1!")
				end
			end)
		end
	end)
end

-- 6. THE ELEVATOR (the end of chapter 1) -------------------------------------
local elevator = workspace:WaitForChild("Elevator")
local function inElevator(pos)
	local lo, hi = ELEVATOR_BOX[1], ELEVATOR_BOX[2]
	return pos.X >= lo.X and pos.X <= hi.X and pos.Y >= lo.Y - 2 and pos.Y <= hi.Y and pos.Z >= lo.Z and pos.Z <= hi.Z
end
local descend = prompt(P.DescendButton, "Descend", "Elevator")
local leaving = false
descend.Triggered:Connect(function(player)
	if leaving then return end
	if not overridden then say(player, "Nothing happens. The elevator is locked down: LEVEL B - SEALED BY ORDER.") return end
	for _, other in ipairs(Players:GetPlayers()) do
		local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if humanoidOf(other) and root and not inElevator(root.Position) then
			say(player, "Wait! " .. other.DisplayName .. " isn't in the elevator yet.")
			return
		end
	end
	leaving = true
	descend:Destroy()
	slide(P.ElevatorGate, Vector3.new(-3.8 * 3.2, 0, 0), 1.5)
	task.wait(1.6)
	endEvent:FireAllClients()
	-- Down slowly... then the cable snaps.
	local car = { P.ElevatorGate, P.DescendButton }
	for _, part in ipairs(elevator:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(car, part) end
	end
	local start = {}
	for i, part in ipairs(car) do start[i] = part.CFrame end
	local t = 0
	while t < 7 do
		t += RunService.Heartbeat:Wait()
		local drop = t < 5 and t * 2 or 10 + (t - 5) ^ 2 * 30
		for i, part in ipairs(car) do part.CFrame = start[i] - Vector3.new(0, drop, 0) end
	end
	task.wait(6)
	workspace:SetAttribute("ChapterDone", true)
	for _, other in ipairs(Players:GetPlayers()) do other:SetAttribute("InGame", false) end
	task.wait(0.5)
	for _, other in ipairs(Players:GetPlayers()) do other:LoadCharacter() end  -- back to the waiting room
end)

-- Signs and notes on the walls.
local signs = Instance.new("Folder")
signs.Name = "Signs"
signs.Parent = workspace
for _, s in ipairs(SIGNS) do
	local part = Instance.new("Part")
	part.Name = s.name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(s.size.X, s.size.Y, 0.05)
	part.CFrame = s.cf
	part.Parent = s.name == "ElevatorPanel" and elevator or signs
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0.4
	gui.PixelsPerStud = 60
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.SpecialElite
	label.TextColor3 = s.color
	label.Text = s.text
	label.Parent = gui
	if s.name == "ElevatorPanel" then panelText = label end
end

-- Holding a switch: stay still (the Sprint script reads "Frozen").
-- And a new player gets a reminder that this is a co-op game.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(3)
		if #Players:GetPlayers() < 2 then
			say(player, "Subject Zero is a co-op game: invite a friend (2-4 players). The puzzles need two people!")
		end
	end)
end)
'''

UI_SCRIPT = r'''-- What you see from the puzzles: messages, the keypad, notes and tapes,
-- and the end of the chapter. Runs on your own computer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

-- Xbox / PlayStation: when a panel opens, the controller selects its
-- buttons (move with the stick or D-pad, A / Cross to press, B / Circle
-- to close). Bigger text on a TV.
local function onConsole()
	return GuiService:IsTenFootInterface() or UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad"
end
local TEXT = GuiService:IsTenFootInterface() and 1.35 or 1

local gui = Instance.new("ScreenGui")
gui.Name = "PuzzleUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, props, parent)
	local thing = Instance.new(class)
	for k, v in pairs(props) do thing[k] = v end
	thing.Parent = parent
	return thing
end
local PAPER = Color3.fromRGB(222, 214, 190)
local INK = Color3.fromRGB(40, 34, 28)

-- Messages at the bottom of the screen.
local message = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.84, 0), Size = UDim2.new(0.8, 0, 0, 34 * TEXT),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235, 228, 205), TextStrokeTransparency = 0.3,
	Font = Enum.Font.SpecialElite, TextSize = 26 * TEXT, TextWrapped = true, Text = "", TextTransparency = 1,
}, gui)
local messageId = 0
ReplicatedStorage:WaitForChild("PuzzleMessage").OnClientEvent:Connect(function(text)
	messageId += 1
	local id = messageId
	message.Text = text
	message.TextTransparency = 0
	message.TextStrokeTransparency = 0.3
	task.delay(4.5, function()
		if id == messageId then
			TweenService:Create(message, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end)

-- Notes and tapes: a sheet of paper you can close.
local note = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.6),
	BackgroundColor3 = PAPER, Visible = false,
}, gui)
make("UISizeConstraint", { MinSize = Vector2.new(300, 260) }, note)
local noteTitle = make("TextLabel", {
	Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.1), BackgroundTransparency = 1,
	Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = INK,
}, note)
local noteText = make("TextLabel", {
	Position = UDim2.fromScale(0.06, 0.17), Size = UDim2.fromScale(0.88, 0.66), BackgroundTransparency = 1,
	Font = Enum.Font.SpecialElite, TextSize = 20 * TEXT, TextWrapped = true, TextColor3 = INK,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, note)
local close = make("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0.3, 0.1),
	BackgroundColor3 = INK, TextColor3 = PAPER, Font = Enum.Font.SpecialElite, TextScaled = true, Text = "Close",
}, note)
local function closeNote()
	note.Visible = false
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(note) then GuiService.SelectedObject = nil end
end
close.Activated:Connect(closeNote)
ReplicatedStorage:WaitForChild("PuzzleRead").OnClientEvent:Connect(function(title, text)
	noteTitle.Text = title
	noteText.Text = text
	note.Visible = true
	if onConsole() then GuiService.SelectedObject = close end
end)

-- The keypad.
local pad = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(260, 380),
	BackgroundColor3 = Color3.fromRGB(45, 50, 42), Visible = false,
}, gui)
local display = make("TextLabel", {
	Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(230, 55), BackgroundColor3 = Color3.fromRGB(10, 14, 10),
	Font = Enum.Font.Code, TextSize = 40, TextColor3 = Color3.fromRGB(100, 255, 130), Text = "",
}, pad)
local typed = ""
local function show() display.Text = typed .. string.rep("_", 4 - #typed) end
local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "0", "ENT" }
for i, key in ipairs(keys) do
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	local b = make("TextButton", {
		Position = UDim2.fromOffset(15 + col * 80, 85 + row * 70), Size = UDim2.fromOffset(70, 60),
		BackgroundColor3 = Color3.fromRGB(80, 84, 74), TextColor3 = Color3.fromRGB(230, 225, 205),
		Font = Enum.Font.Code, TextSize = 28, Text = key,
	}, pad)
	b.Activated:Connect(function()
		if key == "CLR" then
			typed = ""
		elseif key == "ENT" then
			ReplicatedStorage.PuzzleKeypad:FireServer(typed)
		elseif #typed < 4 then
			typed ..= key
		end
		show()
	end)
end
local leave = make("TextButton", {
	Position = UDim2.fromOffset(15, 356), Size = UDim2.fromOffset(230, 20),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200, 195, 175), Font = Enum.Font.SpecialElite,
	TextSize = 18, Text = "(walk away to close)",
}, pad)
local firstKey = pad:FindFirstChildWhichIsA("TextButton")
local function closePad()
	pad.Visible = false
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(pad) then GuiService.SelectedObject = nil end
end
leave.Activated:Connect(closePad)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB then
		if pad.Visible then closePad() end
		if note.Visible then closeNote() end
	end
end)
UserInputService.InputBegan:Connect(function(input, typing)
	if typing or not pad.Visible then return end
	local names = { Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9" }
	local name = string.gsub(input.KeyCode.Name, "^Keypad", "")
	local digit = names[name]
	if digit and #typed < 4 then typed ..= digit show() end
	if input.KeyCode == Enum.KeyCode.Return then ReplicatedStorage.PuzzleKeypad:FireServer(typed) end
	if input.KeyCode == Enum.KeyCode.Backspace then typed = string.sub(typed, 1, -2) show() end
end)
local keypadPart = workspace:WaitForChild("Puzzles"):WaitForChild("OfficeKeypad")
ReplicatedStorage:WaitForChild("PuzzleKeypad").OnClientEvent:Connect(function(what)
	if what == "open" then
		typed = ""
		show()
		pad.Visible = true
		leave.Text = onConsole() and "(B / Circle to close)" or "(walk away to close)"
		if onConsole() then GuiService.SelectedObject = firstKey end
	elseif what == "wrong" then
		display.Text = "WRONG"
		display.TextColor3 = Color3.fromRGB(255, 70, 50)
		task.delay(0.8, function()
			display.TextColor3 = Color3.fromRGB(100, 255, 130)
			typed = ""
			show()
		end)
	elseif what == "right" then
		display.Text = "OPEN"
		task.delay(0.8, closePad)
	end
end)
RunService.Heartbeat:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if pad.Visible and (not root or (root.Position - keypadPart.Position).Magnitude > 12) then closePad() end
	if note.Visible and root and root.AssemblyLinearVelocity.Magnitude > 20 then closeNote() end
end)

-- The end of chapter 1: the elevator goes down... and the cable snaps.
ReplicatedStorage:WaitForChild("ChapterEnd").OnClientEvent:Connect(function()
	local camera = workspace.CurrentCamera
	local t = 0
	local shake = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local amount = t < 5 and 0.03 or 0.25
		camera.CFrame = camera.CFrame * CFrame.Angles((math.random() - 0.5) * amount, (math.random() - 0.5) * amount, 0)
	end)
	task.wait(5)
	local black = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1 }, gui)
	TweenService:Create(black, TweenInfo.new(1.6), { BackgroundTransparency = 0 }):Play()
	task.wait(2)
	shake:Disconnect()
	local title = make("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.SpecialElite, TextSize = 44,
		TextColor3 = Color3.fromRGB(220, 210, 190), TextTransparency = 1,
		Text = "END OF CHAPTER 1\n\nThe cable snapped.\nSomething is waiting on Level B...",
	}, black)
	TweenService:Create(title, TweenInfo.new(1.5), { TextTransparency = 0 }):Play()
	task.wait(5)
	TweenService:Create(black, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(title, TweenInfo.new(1.5), { TextTransparency = 1 }):Play()
	task.wait(1.6)
	black:Destroy()
end)
'''


TEAM_SCRIPT = r"""-- THE TEAM LIVES OR DIES TOGETHER.
-- If ONE player dies (the Long Man catches them, they fall...), EVERYONE
-- dies, and the whole team comes back at the last checkpoint.
-- (Puzzles you already solved stay solved.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local messageEvent = ReplicatedStorage:WaitForChild("PuzzleMessage")

--DATA--

local checkpoint = nil   -- nil = the start (the road)
local wiping = false
local ROAD = Vector3.new(0, 1, 45 * 3.2)

local function onDied(player)
	if wiping or not player:GetAttribute("InGame") then return end
	wiping = true
	messageEvent:FireAllClients(player.DisplayName .. " died... so EVERYONE dies. Back to " .. (checkpoint and checkpoint.name or "the start") .. "!")
	task.wait(0.6)
	for _, other in ipairs(Players:GetPlayers()) do
		local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if other:GetAttribute("InGame") and humanoid and humanoid.Health > 0 then humanoid.Health = 0 end
	end
	-- Everyone comes back together.
	task.wait(Players.RespawnTime + 0.5)
	for _, other in ipairs(Players:GetPlayers()) do
		local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if other:GetAttribute("InGame") and (not humanoid or humanoid.Health <= 0) then other:LoadCharacter() end
	end
	task.wait(1)
	wiping = false
end

local function onCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function() onDied(player) end)
	-- In the game: come back at the checkpoint (or the road). Not in the game
	-- yet: you appear in the waiting room.
	if player:GetAttribute("InGame") then
		local root = character:WaitForChild("HumanoidRootPart")
		task.wait()
		local spread = Vector3.new((math.random() - 0.5) * 6, 3, (math.random() - 0.5) * 6)
		character:PivotTo(CFrame.new((checkpoint and checkpoint.spawn or ROAD) + spread) * root.CFrame.Rotation)
	end
end

-- After the ending, start again from the road.
workspace:GetAttributeChangedSignal("ChapterDone"):Connect(function()
	checkpoint = nil
	workspace:SetAttribute("RespawnPoint", nil)
end)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
	if player.Character then onCharacter(player, player.Character) end
end

-- Checkpoint boxes (invisible).
for i, cp in ipairs(CHECKPOINTS) do
	local box = Instance.new("Part")
	box.Name = "Checkpoint" .. i
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.Transparency = 1
	box.Size = cp.size
	box.Position = cp.center
	box.Parent = workspace
	box.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
		if player and not wiping and (checkpoint == nil or table.find(CHECKPOINTS, checkpoint) < i) then
			checkpoint = cp
			workspace:SetAttribute("RespawnPoint", cp.spawn)  -- late joiners come in here
			messageEvent:FireAllClients("Checkpoint: " .. cp.name)
		end
	end)
end
"""
