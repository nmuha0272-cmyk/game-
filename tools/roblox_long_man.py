"""The Long Man for the Roblox version, built from Roblox parts (spheres and
cylinders) in his crawling pose, plus his scripts. Used by make_roblox.py."""
import math

S = 3.2
CELL = (9, -9, -82)  # where he waits (Godot meters)
PATROL = [(9, -9, -82), (9, -9, -72), (9, -9, -56), (5.5, -9, -65), (21, -9, -68), (38, -9, -68)]
TRIGGER = ((9, -7.5, -67), (4, 3, 4))
SKIN, DARK, GOWN, BLOOD, CLAW, EYE = "#a09b91", "#050202", "#6d7a6a", "#3a0606", "#141210", "!ffd98a"
PIVOTS = {"ArmL": (-0.27, 1.05, -0.55), "ArmR": (0.27, 1.05, -0.55), "LegL": (-0.14, 1.0, 0.45),
          "LegR": (0.14, 1.0, 0.45), "Head": (0, 1.1, -0.8)}


def sub(a, b): return tuple(a[i] - b[i] for i in range(3))
def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def build(part, script, new_ref):
    """part/script/new_ref: the make_roblox helpers. Returns the LongMan Model XML."""
    # The model faces -Z; in the cell he faces +Z (towards the door): turn 180 degrees.
    def world(p):
        return ((CELL[0] - p[0]) * S, (CELL[1] + p[1]) * S, (CELL[2] - p[2]) * S)
    turned = lambda axes: tuple((-a[0], a[1], -a[2]) for a in axes)
    items = []

    def ball(name, c, radii, color, neon=False):
        mesh = ('<Item class="SpecialMesh" referent="LMSM' + name + '"><Properties><token name="MeshType">3</token>'
                '<Vector3 name="Scale"><X>1</X><Y>1</Y><Z>1</Z></Vector3></Properties></Item>')
        items.append(part(name, world(c), turned(((1, 0, 0), (0, 1, 0), (0, 0, 1))),
                          tuple(2 * r * S for r in radii), color, False, 1, children=mesh))

    def bone(name, a, b, r, color):
        d = norm(sub(b, a))
        helper = (0, 1, 0) if abs(d[1]) < 0.9 else (1, 0, 0)
        z = norm(cross(d, helper)); y = cross(z, d)
        mid = tuple((a[i] + b[i]) / 2 for i in range(3))
        length = math.dist(a, b)
        items.append(part(name, world(mid), turned((d, y, z)), (length * S, 2 * r * S, 2 * r * S), color, False, 2))

    # Body
    ball("Body_Ribcage", (0, 1.12, -0.32), (0.17, 0.13, 0.27), SKIN)
    bone("Body_Spine", (0, 1.12, -0.1), (0, 1.02, 0.42), 0.1, SKIN)
    ball("Body_Hips", (0, 1.0, 0.45), (0.17, 0.11, 0.1), SKIN)
    bone("Body_Neck", (0, 1.12, -0.55), (0, 1.1, -0.8), 0.045, SKIN)
    for k in range(7):
        ball(f"Body_Knob{k}", (0, 1.24 - 0.01 * k, -0.48 + k * 0.13), (0.03, 0.03, 0.03), SKIN)
    for k in range(5):
        for x in (-1, 1):
            bone(f"Body_Rib{k}{x}", (0.16 * x, 1.12, -0.5 + k * 0.07), (0.03 * x, 0.99, -0.48 + k * 0.07), 0.017, SKIN)
    bone("Body_Gown", (0, 0.98, 0.18), (0, 0.98, 0.5), 0.2, GOWN)
    ball("Body_Guts", (0, 0.96, 0.05), (0.07, 0.05, 0.1), BLOOD)
    for x in (-1, 1):
        ball(f"Body_Shoulder{x}", (0.27 * x, 1.06, -0.55), (0.06, 0.06, 0.06), SKIN)
    # Head (pivots at the neck so it can twitch)
    ball("Head_Skull", (0, 1.15, -0.9), (0.11, 0.15, 0.17), SKIN)
    ball("Head_Jaw", (0, 1.0, -0.98), (0.07, 0.11, 0.07), SKIN)
    ball("Head_Mouth", (0, 1.0, -1.03), (0.045, 0.08, 0.035), DARK)
    for x in (-1, 1):
        ball(f"Head_Socket{x}", (0.05 * x, 1.19, -1.03), (0.032, 0.026, 0.02), DARK)
        ball(f"Head_Eye{x}", (0.05 * x, 1.19, -1.045), (0.009, 0.009, 0.009), EYE)
        bone(f"Head_Blood{x}", (0.04 * x, 0.97, -1.04), (0.045 * x, 0.88, -1.02), 0.005, BLOOD)
    for k in range(7):
        x = -0.03 + k * 0.01
        bone(f"Head_ToothTop{k}", (x, 1.05, -1.04), (x, 1.02, -1.05), 0.004, "#a8986a")
        bone(f"Head_ToothBot{k}", (x, 0.93, -1.04), (x, 0.96, -1.05), 0.004, "#a8986a")
    for k in range(8):
        a = -1.2 + k * 0.34
        bone(f"Head_Hair{k}", (math.sin(a) * 0.09, 1.28, -0.85 + math.cos(a) * 0.05), (math.sin(a) * 0.13, 0.95, -0.8 + math.cos(a) * 0.08), 0.004, "#1c1c1a")
    # Arms and legs (each in a group that swings at the shoulder / hip)
    for side, x in (("L", -1), ("R", 1)):
        sh = (0.27 * x, 1.05, -0.55); el = (0.5 * x, 0.95, -0.9); wr = (0.42 * x, 0.08, -1.2)
        g = "Arm" + side
        bone(g + "_Upper", sh, el, 0.05, SKIN); ball(g + "_Elbow", el, (0.045,) * 3, SKIN)
        bone(g + "_Fore", el, wr, 0.037, SKIN); ball(g + "_Hand", (0.42 * x, 0.04, -1.27), (0.045, 0.025, 0.085), SKIN)
        for f in range(4):
            fx = 0.42 * x + (f - 1.5) * 0.028
            tip = (fx + (f - 1.5) * 0.03, 0.015, -1.55 + abs(f - 1.5) * 0.04)
            bone(f"{g}_Finger{f}", (fx, 0.03, -1.32), tip, 0.01, SKIN)
            bone(f"{g}_Claw{f}", tip, (tip[0], 0.005, tip[2] - 0.05), 0.006, CLAW)
        hp = (0.14 * x, 1.0, 0.45); kn = (0.42 * x, 1.4, 0.75); an = (0.36 * x, 0.08, 0.95)
        g = "Leg" + side
        bone(g + "_Thigh", hp, kn, 0.072, SKIN); ball(g + "_Knee", kn, (0.06,) * 3, SKIN)
        bone(g + "_Shin", kn, an, 0.048, SKIN); ball(g + "_Foot", (0.36 * x, 0.035, 0.85), (0.05, 0.03, 0.16), SKIN)
    # The invisible root at his feet: the script moves this, everything follows.
    root = part("Root", world((0, 0, 0)), turned(((1, 0, 0), (0, 1, 0), (0, 0, 1))), (1, 1, 1), DARK, False, 1, 1.0)
    pivots = ", ".join(f'{k} = Vector3.new({v[0] * S:.3f}, {v[1] * S:.3f}, {v[2] * S:.3f})' for k, v in PIVOTS.items())
    patrol = ", ".join(f"Vector3.new({p[0] * S:.2f}, {p[1] * S:.2f}, {p[2] * S:.2f})" for p in PATROL)
    trig_c, trig_s = TRIGGER
    source = (LONG_MAN_SCRIPT.replace("--PIVOTS--", pivots).replace("--PATROL--", patrol)
              .replace("--TRIGGER_POS--", f"Vector3.new({trig_c[0] * S:.2f}, {trig_c[1] * S:.2f}, {trig_c[2] * S:.2f})")
              .replace("--TRIGGER_SIZE--", f"Vector3.new({trig_s[0] * S:.2f}, {trig_s[1] * S:.2f}, {trig_s[2] * S:.2f})"))
    brain = script("Script", "LongManBrain", source)
    return (f'<Item class="Model" referent="{new_ref()}"><Properties><string name="Name">LongMan</string></Properties>'
            + root + "".join(items) + brain + "</Item>")


LONG_MAN_SCRIPT = r'''-- SUBJECT 7, "THE LONG MAN" (Roblox version)
-- He waits in his cell. When someone walks past it, everyone sees him
-- (the reveal), then he hunts: crawling along his patrol route, finding his
-- way around walls. When he SEES you he stops and stares... then charges.
-- If he catches you: a jump scare, and you respawn at the start.
-- Players can sprint (Shift) to get away for a few seconds.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local model = script.Parent
local root = model:WaitForChild("Root")
local jumpScare = ReplicatedStorage:WaitForChild("LongManJumpScare")
local reveal = ReplicatedStorage:WaitForChild("LongManReveal")

-- Tuning
local PATROL_SPEED = 6
local CHASE_SPEED = 17      -- walking is 14, sprinting is 22
local SIGHT_RANGE = 70      -- studs (flashlight on: much further)
local CATCH_RANGE = 5
local STARE_TIME = 1.4
local LOSE_TIME = 4

local PIVOTS = { --PIVOTS-- }
local PATROL = { --PATROL-- }

-- Remember where every part sits relative to the root (so we can move him
-- as one piece, and swing the arms, legs and head).
local parts = {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= root then
		local group = string.match(p.Name, "^(%a+)_")
		table.insert(parts, { part = p, offset = root.CFrame:ToObjectSpace(p.CFrame), group = group })
	end
end

-- The chase trigger: an invisible box in front of his cell.
local trigger = Instance.new("Part")
trigger.Name = "LongManTrigger"
trigger.Anchored = true
trigger.CanCollide = false
trigger.Transparency = 1
trigger.Size = --TRIGGER_SIZE--
trigger.Position = --TRIGGER_POS--
trigger.Parent = workspace

local state = "DORMANT"
local target = nil
local timer = 0
local unseen = 0
local patrolIndex = 1
local waypoints = {}
local waypointIndex = 1
local repathTimer = 0
local ignorePlayers = 0
local phase = 0
local headRoll = 0.25
local twitchTimer = 2
local cf = root.CFrame

local function playerFromPart(part)
	local character = part:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function headOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character:FindFirstChild("Head")
	end
	return nil
end

local function eyePosition()
	return (cf * CFrame.new(0, 3.6, -3)).Position
end

local function canSee(player)
	local head = headOf(player)
	if not head then return false end
	local from = eyePosition()
	local offset = head.Position - from
	local range = SIGHT_RANGE
	local light = head:FindFirstChild("Flashlight")
	if light and light.Enabled then range = range * 1.6 end
	if offset.Magnitude > range then return false end
	if offset.Magnitude > 10 and cf.LookVector:Dot(offset.Unit) < 0.35 then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, trigger }
	local hit = workspace:Raycast(from, offset, params)
	return hit == nil or hit.Instance:IsDescendantOf(player.Character)
end

local function findVisiblePlayer()
	for _, player in ipairs(Players:GetPlayers()) do
		if canSee(player) then return player end
	end
	return nil
end

local function pathTo(goal)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
	local ok = pcall(function() path:ComputeAsync(cf.Position, goal) end)
	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
		waypointIndex = 2
	else
		waypoints = { { Position = Vector3.new(goal.X, cf.Position.Y, goal.Z) } }
		waypointIndex = 1
	end
end

local function startPatrol()
	state = "PATROL"
	target = nil
	pathTo(PATROL[patrolIndex])
end

local function startStare(player, seconds)
	state = "STARE"
	target = player
	timer = seconds or STARE_TIME
end

local function startChase(player)
	state = "CHASE"
	target = player
	unseen = 0
	repathTimer = 0
end

-- Someone walked past the cell: the reveal, then the hunt begins.
trigger.Touched:Connect(function(hit)
	local player = playerFromPart(hit)
	if player and state == "DORMANT" then
		reveal:FireAllClients()
		startStare(player, 3.6)
	end
end)

local function moveAlong(speed, dt)
	local wp = waypoints[waypointIndex]
	if not wp then return true end
	local goal = wp.Position
	local flat = Vector3.new(goal.X - cf.Position.X, 0, goal.Z - cf.Position.Z)
	if flat.Magnitude < 1.5 then
		waypointIndex += 1
		return waypointIndex > #waypoints
	end
	local step = math.min(speed * dt, flat.Magnitude)
	local pos = cf.Position + flat.Unit * step
	pos = Vector3.new(pos.X, pos.Y + (goal.Y - pos.Y) * math.min(1, dt * 8), pos.Z)
	local look = cf.LookVector:Lerp(flat.Unit, math.min(1, dt * 6))
	cf = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
	phase += step * 0.9
	return false
end

local function think(dt)
	timer -= dt
	ignorePlayers -= dt
	if state == "DORMANT" then
		return
	elseif state == "STARE" then
		local head = target and headOf(target)
		if not head then startPatrol() return end
		local to = Vector3.new(head.Position.X, cf.Position.Y, head.Position.Z)
		cf = cf:Lerp(CFrame.lookAt(cf.Position, to), math.min(1, dt * 4))
		if timer <= 0 then startChase(target) end
		return
	end

	if ignorePlayers <= 0 and state ~= "CHASE" then
		local seen = findVisiblePlayer()
		if seen then startStare(seen) return end
	end

	if state == "CHASE" then
		local head = target and headOf(target)
		if not head then startPatrol() return end
		if canSee(target) then unseen = 0 else unseen += dt end
		if unseen > LOSE_TIME then startPatrol() return end
		repathTimer -= dt
		if repathTimer <= 0 then
			repathTimer = 0.4
			pathTo(head.Position)
		end
		moveAlong(CHASE_SPEED, dt)
		if (head.Position - eyePosition()).Magnitude < CATCH_RANGE + 2 then
			-- Caught! A jump scare on their screen, then they respawn.
			jumpScare:FireClient(target)
			local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			task.delay(0.8, function() if humanoid then humanoid.Health = 0 end end)
			-- He crawls off to the far end of his route for a while.
			ignorePlayers = 6
			local far, best = 1, -1
			for i, p in ipairs(PATROL) do
				local d = (p - cf.Position).Magnitude
				if d > best then far, best = i, d end
			end
			patrolIndex = far
			startPatrol()
		end
	elseif state == "PATROL" then
		if moveAlong(PATROL_SPEED, dt) then
			patrolIndex = patrolIndex % #PATROL + 1
			pathTo(PATROL[patrolIndex])
		end
	end
end

-- Pose every part: crawl (arms and legs swing in diagonal pairs) and
-- head twitches. The head tips over sideways while he stares.
local function pose(dt)
	twitchTimer -= dt
	if state == "STARE" then
		headRoll += (1.3 - headRoll) * math.min(1, dt * 1.5)
	elseif twitchTimer <= 0 then
		twitchTimer = math.random() * (state == "CHASE" and 1.5 or 4) + 0.5
		headRoll = (math.random() * 1.2 - 0.6)
	end
	local swing = math.sin(phase) * 0.45
	local lift = math.max(0, math.cos(phase)) * 0.25
	local angles = {
		ArmL = CFrame.Angles(swing + lift, 0, 0), LegR = CFrame.Angles(swing - lift, 0, 0),
		ArmR = CFrame.Angles(-swing + lift, 0, 0), LegL = CFrame.Angles(-swing - lift, 0, 0),
		Head = CFrame.Angles(0, 0, headRoll),
	}
	local bob = CFrame.new(0, math.abs(math.sin(phase)) * 0.15, 0)
	root.CFrame = cf
	for _, info in ipairs(parts) do
		local offset = info.offset
		local turn = info.group and angles[info.group]
		if turn then
			local pivot = PIVOTS[info.group]
			offset = CFrame.new(pivot) * turn * CFrame.new(-pivot) * offset
		end
		info.part.CFrame = cf * bob * offset
	end
end

RunService.Heartbeat:Connect(function(dt)
	think(dt)
	pose(dt)
end)
'''

EFFECTS_SCRIPT = r'''-- What each player sees from the Long Man: the reveal cutscene, and the
-- jump scare when he catches you. Runs on your own computer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function makeGui()
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

-- SUBJECT 7 reveal: black bars, two camera shots of him in his cell.
ReplicatedStorage:WaitForChild("LongManReveal").OnClientEvent:Connect(function()
	local gui = makeGui()
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
	caption.Size = UDim2.new(1, 0, 0.1, 0)
	caption.Position = UDim2.new(0, 0, 0.89, 0)
	caption.Text = "SUBJECT 7"
	caption.TextColor3 = Color3.fromRGB(220, 210, 190)
	caption.Font = Enum.Font.SpecialElite
	caption.TextScaled = true
	caption.Parent = gui
	camera.CameraType = Enum.CameraType.Scriptable
	local shots = { --SHOTS-- }
	for _, shot in ipairs(shots) do
		local t = 0
		while t < shot[5] do
			local k = t / shot[5]
			k = k * k * (3 - 2 * k)
			camera.CFrame = CFrame.lookAt(shot[1]:Lerp(shot[3], k), shot[2]:Lerp(shot[4], k))
			t += RunService.RenderStepped:Wait()
		end
	end
	camera.CameraType = Enum.CameraType.Custom
	gui:Destroy()
end)

-- Your flashlight stutters when he is close.
task.spawn(function()
	while true do
		task.wait(0.05 + math.random() * 0.15)
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local light = head and head:FindFirstChild("Flashlight")
		local longMan = workspace:FindFirstChild("LongMan")
		local root = longMan and longMan:FindFirstChild("Root")
		if light and root then
			local near = (root.Position - head.Position).Magnitude < 25
			light.Brightness = (near and math.random() < 0.35) and 0.3 or 4
		end
	end
end)

-- Jump scare: his head lunges at your face, red flash, shake.
ReplicatedStorage:WaitForChild("LongManJumpScare").OnClientEvent:Connect(function()
	local longMan = workspace:FindFirstChild("LongMan")
	if not longMan then return end
	local root = longMan:FindFirstChild("Root")
	local skull = longMan:FindFirstChild("Head_Skull")
	if not root or not skull then return end
	local center = skull.CFrame
	local clones = {}
	for _, p in ipairs(longMan:GetChildren()) do
		if p:IsA("BasePart") and string.sub(p.Name, 1, 5) == "Head_" then
			local c = p:Clone()
			c.Parent = camera
			table.insert(clones, { part = c, offset = center:ToObjectSpace(p.CFrame) })
		end
	end
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 8
	light.Color = Color3.fromRGB(220, 230, 255)
	light.Parent = clones[1] and clones[1].part
	local gui = makeGui()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	flash.BackgroundTransparency = 0.45
	flash.Parent = gui
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	local sound = Instance.new("Sound")
	sound.SoundId = script:GetAttribute("ScreamSoundId") or ""
	sound.Volume = 2
	sound.Parent = gui
	if sound.SoundId ~= "" then sound:Play() end
	local t = 0
	while t < 0.9 do
		local distance = math.max(2.4, 7 - t * 40)
		local shake = CFrame.new((math.random() - 0.5) * 0.25, (math.random() - 0.5) * 0.25, 0)
		local target = camera.CFrame * shake * CFrame.new(0, -0.4, -distance) * CFrame.Angles(0, math.pi, 0)
		for _, info in ipairs(clones) do
			info.part.CFrame = target * info.offset
		end
		t += RunService.RenderStepped:Wait()
	end
	for _, info in ipairs(clones) do info.part:Destroy() end
	gui:Destroy()
end)
'''

SPRINT_SCRIPT = r'''-- Sprint: hold Shift (keyboard) or press the left stick (controller).
-- About 4 seconds of running, then you have to catch your breath.
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local humanoid = script.Parent:WaitForChild("Humanoid")
local WALK, RUN = 14, 22
local stamina = 4
local wantRun = false

UserInputService.InputBegan:Connect(function(input, typing)
	if typing then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then wantRun = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then wantRun = false end
end)

RunService.Heartbeat:Connect(function(dt)
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	if wantRun and moving and stamina > 0 then
		stamina = math.max(0, stamina - dt)
		humanoid.WalkSpeed = RUN
	else
		stamina = math.min(4, stamina + dt * 0.6)
		humanoid.WalkSpeed = WALK
		if stamina <= 0 then wantRun = false end
	end
end)
'''


def reveal_shots():
    def v(p): return f"Vector3.new({p[0] * S:.2f}, {p[1] * S:.2f}, {p[2] * S:.2f})"
    shots = [((9.4, -7.6, -73.2), (9, -8.0, -82), (9.15, -7.7, -76.5), (9, -7.9, -82), 1.8),
             ((9.2, -7.75, -79.4), (9, -7.85, -81.1), (9.1, -7.8, -79.95), (9, -7.85, -81.1), 1.6)]
    return ", ".join("{" + f"{v(a)}, {v(la)}, {v(b)}, {v(lb)}, {t}" + "}" for a, la, b, lb, t in shots)
