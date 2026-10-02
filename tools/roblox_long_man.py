"""The Long Man for the Roblox version, built from Roblox parts (spheres and
cylinders) in his crawling pose, plus his scripts. Used by make_roblox.py."""
import math

S = 3.2
CELL = (9, -9, -82)  # where he waits (Godot meters)
PATROL = [(9, -9, -82), (9, -9, -72), (9, -9, -56), (5.5, -9, -65), (21, -9, -68), (38, -9, -68)]
TRIGGER = ((9, -7.5, -67), (4, 3, 4))
SKIN, DARK, GOWN, BLOOD, CLAW, EYE = "#8e8879", "#050202", "#5d6a5a", "#3a0606", "#141210", "!ff2414"
K = 1.1  # he's built a little bigger than the PC model, so standing up he's ~9 ft
PIVOTS = {"ArmL": (-0.27, 1.05, -0.55), "ArmR": (0.27, 1.05, -0.55), "LegL": (-0.14, 1.0, 0.45),
          "LegR": (0.14, 1.0, 0.45), "Head": (0, 1.1, -0.8),
          "Jaw": (0, 1.06, -0.92), "Hip": (0, 1.0, 0.45)}


def sub(a, b): return tuple(a[i] - b[i] for i in range(3))
def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def build(part, script, new_ref):
    """part/script/new_ref: the make_roblox helpers. Returns the LongMan Model XML."""
    # The model faces -Z; in the cell he faces +Z (towards the door): turn 180 degrees.
    def world(p):
        return ((CELL[0] - p[0] * K) * S, (CELL[1] + p[1] * K) * S, (CELL[2] - p[2] * K) * S)
    turned = lambda axes: tuple((-a[0], a[1], -a[2]) for a in axes)
    items = []

    def ball(name, c, radii, color, neon=False):
        mesh = ('<Item class="SpecialMesh" referent="LMSM' + name + '"><Properties><token name="MeshType">3</token>'
                '<Vector3 name="Scale"><X>1</X><Y>1</Y><Z>1</Z></Vector3></Properties></Item>')
        items.append(part(name, world(c), turned(((1, 0, 0), (0, 1, 0), (0, 0, 1))),
                          tuple(2 * r * S * K for r in radii), color, False, 1, children=mesh))

    def bone(name, a, b, r, color):
        d = norm(sub(b, a))
        helper = (0, 1, 0) if abs(d[1]) < 0.9 else (1, 0, 0)
        z = norm(cross(d, helper)); y = cross(z, d)
        mid = tuple((a[i] + b[i]) / 2 for i in range(3))
        length = math.dist(a, b)
        items.append(part(name, world(mid), turned((d, y, z)), (length * S * K, 2 * r * S * K, 2 * r * S * K), color, False, 2))

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
    ball("Head_Skull", (0, 1.17, -0.9), (0.09, 0.17, 0.15), SKIN)
    ball("Head_Brow", (0, 1.22, -0.99), (0.085, 0.03, 0.05), SKIN)
    for x in (-1, 1):
        ball(f"Head_Cheek{x}", (0.06 * x, 1.08, -1.0), (0.025, 0.05, 0.03), "#3b3630")
    ball("Jaw_Chin", (0, 0.97, -0.98), (0.07, 0.1, 0.07), SKIN)
    ball("Head_Mouth", (0, 1.035, -0.975), (0.034, 0.075, 0.03), DARK)
    ball("Jaw_Throat", (0, 0.99, -1.0), (0.045, 0.07, 0.04), "#2a0505")
    for x in (-1, 1):
        ball(f"Head_Socket{x}", (0.042 * x, 1.18, -1.02), (0.03, 0.03, 0.025), DARK)
        ball(f"Head_Eye{x}", (0.042 * x, 1.18, -1.04), (0.008, 0.006, 0.006), EYE)
        bone(f"Head_Blood{x}", (0.04 * x, 0.97, -1.04), (0.045 * x, 0.88, -1.02), 0.005, BLOOD)
    for k in range(7):
        x = -0.03 + k * 0.01
        bone(f"Head_ToothTop{k}", (x, 1.085, -1.012), (x, 1.05, -1.02), 0.004, "#a8986a")
        bone(f"Jaw_Tooth{k}", (x, 1.0, -1.04), (x, 1.035, -1.045), 0.004, "#a8986a")
    for k in range(8):
        a = -1.2 + k * 0.34
        bone(f"Head_Hair{k}", (math.sin(a) * 0.09, 1.28, -0.85 + math.cos(a) * 0.05), (math.sin(a) * 0.13, 0.95, -0.8 + math.cos(a) * 0.08), 0.004, "#1c1c1a")
    # A faint red glow from the eyes, so you see them in the dark first.
    glow = ('<Item class="PointLight" referent="LMEyeGlow"><Properties><float name="Brightness">1.2</float>'
            '<Color3 name="Color"><R>1</R><G>0.15</G><B>0.08</B></Color3><float name="Range">7</float>'
            '<bool name="Shadows">false</bool></Properties></Item>')
    items.append(part("Head_EyeGlow", world((0, 1.19, -1.07)), turned(((1, 0, 0), (0, 1, 0), (0, 0, 1))), (0.2, 0.2, 0.2),
                      EYE, False, 1, 1.0, children=glow))
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
    pivots = ", ".join(f'{k} = Vector3.new({v[0] * S * K:.3f}, {v[1] * S * K:.3f}, {v[2] * S * K:.3f})' for k, v in PIVOTS.items())
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
-- If he catches you: a jump scare... and the whole team dies.
-- Players can sprint (Shift) to get away for a few seconds.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local model = script.Parent
local root = model:WaitForChild("Root")
local jumpScare = ReplicatedStorage:WaitForChild("LongManJumpScare")
local reveal = ReplicatedStorage:WaitForChild("LongManReveal")
local soundIds = ReplicatedStorage:WaitForChild("LongManSounds")

-- A sound's ID: either typed into the value with that name, or a Sound you
-- dragged into the LongManSounds folder whose name has that word in it
-- (like "LongMan_Scream").
local function findSoundId(name)
	local value = soundIds:FindFirstChild(name)
	if value and value:IsA("StringValue") and value.Value ~= "" then return value.Value end
	for _, thing in ipairs(soundIds:GetDescendants()) do
		if thing:IsA("Sound") and string.find(string.lower(thing.Name), string.lower(name), 1, true) then
			return thing.SoundId
		end
	end
	return ""
end

-- His sounds (they play once you've uploaded them: see HOW_TO_USE.txt).
local function makeSound(name, looped, volume)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = findSoundId(name)
	sound.Looped = looped
	sound.Volume = volume
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 90
	sound.Parent = root
	return sound
end
local breath = makeSound("Breath", true, 1.2)
local skitter = makeSound("Skitter", true, 1.4)
local crack = makeSound("NeckCrack", false, 1.6)
local shriek = makeSound("Shriek", false, 2.5)
local click = makeSound("Click", false, 1.2)
local function play(sound)
	if sound.SoundId ~= "" then sound:Play() end
end

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
	return (cf * CFrame.new(0, 3.9, -3.3)).Position
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
	if state ~= "CHASE" then play(shriek) end
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
	end
	-- Blinded by the Journalist's camera flash: he stops, screams, shakes his head.
	local stunUntil = model:GetAttribute("StunUntil")
	if stunUntil and workspace:GetServerTimeNow() < stunUntil then
		state = "STUNNED"
		return
	elseif state == "STUNNED" then
		ignorePlayers = 1.5
		startPatrol()
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
		-- He comes in bursts: a sudden lunge, then a jerky slow-down.
		local burst = 0.75 + 0.55 * math.max(0, math.sin(os.clock() * 2.7))
		moveAlong(CHASE_SPEED * burst, dt)
		if (head.Position - eyePosition()).Magnitude < CATCH_RANGE + 2 then
			-- Caught! A jump scare on their screen... and they die (so the team dies).
			-- Except Frank the Guard: once per life he shoves him off.
			local character = target.Character
			if character and character:GetAttribute("Tough") then
				character:SetAttribute("Tough", false)
				ReplicatedStorage.PuzzleMessage:FireAllClients(target.DisplayName .. " (Frank) SHOVES the Long Man off! He can only do that once...")
				model:SetAttribute("StunUntil", workspace:GetServerTimeNow() + 1.5)
			else
				jumpScare:FireClient(target)
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				task.delay(0.8, function() if humanoid then humanoid.Health = 0 end end)
			end
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
local rear = 0       -- 0 = on all fours, 1 = rising up to his full height
local jaw = 0.1
local lastState = nil
local function pivotTurn(group, turn)
	local pivot = PIVOTS[group]
	return CFrame.new(pivot) * turn * CFrame.new(-pivot)
end
local function pose(dt)
	twitchTimer -= dt
	if state ~= lastState then
		lastState = state
		root:SetAttribute("State", state)
	end
	-- While he stares he slowly RISES UP to his full height, head tipping over.
	local wantRear = state == "STARE" and 1 or state == "STUNNED" and 0.35 or 0
	rear += (wantRear - rear) * math.min(1, dt * (wantRear > rear and 1.6 or 4))
	local wantJaw = state == "STUNNED" and 0.9 or (state == "STARE" or state == "CHASE") and 0.65 or 0.12 + math.random() * 0.05
	jaw += (wantJaw - jaw) * math.min(1, dt * 6)
	if state == "STUNNED" then
		headRoll = math.sin(os.clock() * 28) * 0.5  -- shaking his head, blinded
	elseif state == "STARE" then
		headRoll += (1.05 - headRoll) * math.min(1, dt * 1.5)
	elseif twitchTimer <= 0 then
		twitchTimer = math.random() * (state == "CHASE" and 1.5 or 4) + 0.5
		headRoll = (math.random() * 1.2 - 0.6)
		if state ~= "DORMANT" and math.random() < 0.6 then play(crack) end
		if math.random() < 0.3 then play(click) end
	end
	-- Breathing always; skittering while he moves.
	if state ~= "DORMANT" and not breath.IsPlaying then play(breath) end
	local moving = state == "PATROL" or state == "CHASE"
	if moving and not skitter.IsPlaying then play(skitter) elseif not moving and skitter.IsPlaying then skitter:Stop() end
	skitter.PlaybackSpeed = state == "CHASE" and 1.5 or 0.9
	local swing = math.sin(phase) * 0.45
	local lift = math.max(0, math.cos(phase)) * 0.25
	local angles = {
		ArmL = CFrame.Angles(swing + lift, 0, 0), LegR = CFrame.Angles(swing - lift, 0, 0),
		ArmR = CFrame.Angles(-swing + lift, 0, 0), LegL = CFrame.Angles(-swing - lift, 0, 0),
		Head = CFrame.Angles(-rear * 0.75, 0, headRoll),
	}
	-- Rising up: the arms hang down instead of reaching for the floor.
	angles.ArmL = angles.ArmL * CFrame.Angles(-rear * 1.0, 0, -rear * 0.15)
	angles.ArmR = angles.ArmR * CFrame.Angles(-rear * 1.0, 0, rear * 0.15)
	local rearTurn = pivotTurn("Hip", CFrame.Angles(rear * 1.15, 0, 0))
	local bob = CFrame.new(0, math.abs(math.sin(phase)) * 0.15, 0)
	root.CFrame = cf
	for _, info in ipairs(parts) do
		local offset = info.offset
		local group = info.group
		if group == "Jaw" then
			offset = pivotTurn("Head", angles.Head) * pivotTurn("Jaw", CFrame.Angles(-jaw, 0, 0)) * offset
		elseif group and angles[group] then
			offset = pivotTurn(group, angles[group]) * offset
		end
		if group ~= "LegL" and group ~= "LegR" then
			offset = rearTurn * offset
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

-- FEAR: when he's close (and worse when he's hunting YOU): the screen
-- darkens at the edges, goes a little red, the view tightens and shakes,
-- and you hear your heartbeat getting faster.
local soundIds = ReplicatedStorage:WaitForChild("LongManSounds")
-- A sound's ID: either typed into the value with that name, or a Sound you
-- dragged into the LongManSounds folder whose name has that word in it
-- (like "LongMan_Scream").
local function findSoundId(name)
	local value = soundIds:FindFirstChild(name)
	if value and value:IsA("StringValue") and value.Value ~= "" then return value.Value end
	for _, thing in ipairs(soundIds:GetDescendants()) do
		if thing:IsA("Sound") and string.find(string.lower(thing.Name), string.lower(name), 1, true) then
			return thing.SoundId
		end
	end
	return ""
end
local soundId = findSoundId
local fearGui = makeGui()
fearGui.DisplayOrder = -1
local edges = {}
for _, side in ipairs({ { 0, 0, 1, 0.35, 90 }, { 0, 0.65, 1, 0.35, -90 }, { 0, 0, 0.3, 1, 0 }, { 0.7, 0, 0.3, 1, 180 } }) do
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.Position = UDim2.fromScale(side[1], side[2])
	f.Size = UDim2.fromScale(side[3], side[4])
	f.BackgroundTransparency = 1
	local grad = Instance.new("UIGradient")
	grad.Rotation = side[5]
	grad.Transparency = NumberSequence.new(0, 1)
	grad.Parent = f
	f.Parent = fearGui
	table.insert(edges, f)
end
local tint = Instance.new("Frame")
tint.BorderSizePixel = 0
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
tint.BackgroundTransparency = 1
tint.Parent = fearGui
local heartbeat = Instance.new("Sound")
heartbeat.SoundId = soundId("Heartbeat")
heartbeat.Volume = 1.5
heartbeat.Parent = fearGui
local fear, beatTimer, baseFov = 0, 0, camera.FieldOfView
local scaring = false
RunService:BindToRenderStep("LongManFear", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local longMan = workspace:FindFirstChild("LongMan")
	local root = longMan and longMan:FindFirstChild("Root")
	local head = player.Character and player.Character:FindFirstChild("Head")
	local want = 0
	if root and head then
		local state = root:GetAttribute("State")
		local d = (root.Position - head.Position).Magnitude
		local hunting = state == "CHASE" or state == "STARE"
		want = math.clamp(1 - d / (hunting and 70 or 30), 0, 1) * (hunting and 1 or 0.45)
	end
	fear += (want - fear) * math.min(1, dt * 2)
	for _, f in ipairs(edges) do f.BackgroundTransparency = 1 - fear * 0.85 end
	tint.BackgroundTransparency = 1 - fear * 0.18
	if camera.CameraType ~= Enum.CameraType.Scriptable and not scaring then
		camera.FieldOfView = baseFov - fear * 10
		if fear > 0.05 then
			local k = fear * fear * 0.012
			camera.CFrame = camera.CFrame * CFrame.Angles((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
		end
	end
	beatTimer -= dt
	if fear > 0.08 and beatTimer <= 0 then
		beatTimer = 60 / (70 + fear * 100)
		if heartbeat.SoundId ~= "" then
			heartbeat.Volume = 0.4 + fear * 1.6
			heartbeat:Play()
		end
	end
end)

-- Jump scare: his head lunges at your face, mouth wide open, the screen
-- flashes red and black, the view punches in and shakes, and he SCREAMS.
ReplicatedStorage:WaitForChild("LongManJumpScare").OnClientEvent:Connect(function()
	local longMan = workspace:FindFirstChild("LongMan")
	if not longMan then return end
	local skull = longMan:FindFirstChild("Head_Skull")
	if not skull then return end
	local center = skull.CFrame
	local clones = {}
	for _, p in ipairs(longMan:GetChildren()) do
		local prefix = string.sub(p.Name, 1, 5)
		if p:IsA("BasePart") and (prefix == "Head_" or string.sub(p.Name, 1, 4) == "Jaw_") then
			local c = p:Clone()
			c.Parent = camera
			table.insert(clones, { part = c, offset = center:ToObjectSpace(p.CFrame) })
		end
	end
	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range = 8
	light.Color = Color3.fromRGB(230, 225, 255)
	light.Parent = clones[1] and clones[1].part
	local gui = makeGui()
	gui.DisplayOrder = 20
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BorderSizePixel = 0
	flash.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	flash.BackgroundTransparency = 0.25
	flash.Parent = gui
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	local scream = Instance.new("Sound")
	scream.SoundId = soundId("Scream")
	scream.Volume = 3
	scream.Parent = gui
	if scream.SoundId ~= "" then scream:Play() end
	local fov = baseFov
	scaring = true
	local t = 0
	while t < 1.1 do
		local distance = math.max(1.9, 7 - t * 45)
		local amount = t < 0.9 and 0.35 or 0.6
		local shake = CFrame.new((math.random() - 0.5) * amount, (math.random() - 0.5) * amount, 0)
		local target = camera.CFrame * shake * CFrame.new(0, -0.35, -distance) * CFrame.Angles(0, math.pi, 0)
			* CFrame.Angles(0, 0, math.sin(t * 40) * 0.12)
		for _, info in ipairs(clones) do
			info.part.CFrame = target * info.offset
		end
		camera.FieldOfView = fov - math.min(1, t * 6) * 25
		-- Black flicker frames, like the picture is breaking up.
		flash.BackgroundColor3 = (t > 0.5 and math.random() < 0.25) and Color3.new(0, 0, 0) or Color3.fromRGB(170, 0, 0)
		if t > 0.5 then flash.BackgroundTransparency = math.random() < 0.3 and 0.05 or 0.7 end
		t += RunService.RenderStepped:Wait()
	end
	for _, info in ipairs(clones) do info.part:Destroy() end
	flash.BackgroundColor3 = Color3.new(0, 0, 0)
	flash.BackgroundTransparency = 0
	camera.FieldOfView = fov
	scaring = false
	task.wait(0.6)
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

local player = game:GetService("Players"):GetPlayerFromCharacter(script.Parent)
RunService.Heartbeat:Connect(function(dt)
	-- Frank the Guard is big: a bit slower.
	local big = player and player:GetAttribute("Character") == "Guard"
	WALK, RUN = big and 12.5 or 14, big and 19.5 or 22
	if humanoid:GetAttribute("Frozen") then
		humanoid.WalkSpeed = 0  -- holding something up: stay still
		return
	end
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
