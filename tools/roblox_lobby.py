"""The WAITING ROOM (lobby) for the Roblox version. You spawn here when
you join. Walk up to a character's stand and press E to pick them. When
everyone has picked (at least 2 players), a countdown starts and the
whole team goes into the game together. Used by make_roblox.py."""
import math, random
S = 3.2
L = (300, 0, 0)          # the room's center (Godot meters), far away from the map
ROOM = (24, 4.5, 16)     # width (x), height, depth (z)
STANDS = [("Son", -9, "#96643c"), ("Journalist", -3, "#cdaf7d"), ("Engineer", 3, "#5a78c8"), ("Guard", 9, "#82965a")]
ROAD_START = [(-1.5, 0.2, 45), (1.5, 0.2, 45), (-1.5, 0.2, 46.5), (1.5, 0.2, 46.5)]
W = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def g(p): return tuple(c * S for c in p)
def at(p): return (L[0] + p[0], L[1] + p[1], L[2] + p[2])
def v3(p): return f"Vector3.new({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})"


def build(part, new_ref):
    out = []
    def box(name, c, s, color, collide=True, shape=1, children="", transparency=0.0, axes=W):
        out.append(part(name, g(at(c)), axes, g(s), color, collide, shape, transparency, children=children))
    def tilt(deg_roll=0, deg_yaw=0):
        cr, sr = math.cos(math.radians(deg_roll)), math.sin(math.radians(deg_roll))
        cy, sy = math.cos(math.radians(deg_yaw)), math.sin(math.radians(deg_yaw))
        right = (cr * cy, sr, -cr * sy); up = (-sr * cy, cr, sr * sy); back = (sy, 0, cy)
        return (right, up, back)
    rng = random.Random(21)
    w, h, d = ROOM
    # A dirty checkered floor with broken tiles, a dark ceiling, grimy walls.
    box("LobbyFloor", (0, -0.1, 0), (w, 0.2, d), "#1c1d1a")
    for i in range(int(w / 2)):
        for k in range(int(d / 2)):
            if (i + k) % 2 == 0:
                x, z = -w / 2 + 1 + i * 2, -d / 2 + 1 + k * 2
                if rng.random() < 0.12:
                    for _ in range(3):
                        box("Rubble", (x + rng.uniform(-0.7, 0.7), 0.04, z + rng.uniform(-0.7, 0.7)), (0.25, 0.08, 0.2), "#b8b3a0", False)
                    continue
                box("FloorTile", (x, 0.005, z), (2, 0.01, 2), rng.choice(["#cfcab5", "#c2bca6", "#b5ae96"]), False)
    box("LobbyCeiling", (0, h + 0.1, 0), (w, 0.2, d), "#5e5b51")
    for name, c, s in (("WallN", (0, 0, -d / 2 - 0.15), (w + 0.6, 0, 0.3)), ("WallS", (0, 0, d / 2 + 0.15), (w + 0.6, 0, 0.3)),
                       ("WallW", (-w / 2 - 0.15, 0, 0), (0.3, 0, d)), ("WallE", (w / 2 + 0.15, 0, 0), (0.3, 0, d))):
        box(name + "Low", (c[0], 0.55, c[2]), (s[0], 1.1, s[2]), "#34493a")
        box(name + "Stripe", (c[0], 1.13, c[2]), (s[0] + (0.04 if s[0] < 1 else 0), 0.06, s[2] + (0.04 if s[2] < 1 else 0)), "#16211b")
        box(name + "High", (c[0], 1.16 + (h - 1.16) / 2, c[2]), (s[0], h - 1.16, s[2]), "#a19c88")
    # Grime, claw marks, bloody smears, and a blood trail from the door to the stands.
    for _ in range(18):
        sw, sh, y = rng.uniform(0.6, 2.2), rng.uniform(0.4, 1.8), rng.uniform(0.3, h - 0.5)
        if rng.random() < 0.5:
            box("Grime", (rng.uniform(-11, 11), y, d / 2 - 0.01), (sw, sh, 0.02), "#1a1712", False, transparency=0.55)
        else:
            box("Grime", (-w / 2 + 0.01, y, rng.uniform(-7, 7)), (0.02, sh, sw), "#1a1712", False, transparency=0.55)
    for (x, y) in ((-10.5, 1.9), (9.5, 1.5)):
        for k in range(4):
            box("Scratch", (x + k * 0.12, y + k * 0.1, d / 2 - 0.02), (1.4, 0.035, 0.02), "#0c0a08", False, axes=tilt(-38))
    for (x, y) in ((4.6, 1.0), (4.9, 1.25)):
        box("BloodSmear", (x, y, d / 2 - 0.02), (0.25, 0.7, 0.02), "#4a0705", False, axes=tilt(rng.uniform(-25, 25)))
    for k in range(14):
        t = k / 13
        box("BloodTrail", (w / 2 - 1.5 - t * 9 + rng.uniform(-0.2, 0.2), 0.012, 0.3 - t * 3.5 + rng.uniform(-0.2, 0.2)),
            (rng.uniform(0.3, 0.7), 0.01, rng.uniform(0.3, 0.6)), rng.choice(["#3d0604", "#4a0705", "#2e0403"]), False)
    box("Scrawl1", (-w / 2 + 0.04, 1.3, -5), (0.04, 1.0, 4), "#000000", False, transparency=1.0)
    box("Scrawl2", (3, 3.6, d / 2 - 0.04), (5, 0.8, 0.04), "#000000", False, transparency=1.0)
    # Ceiling lamps: two dead, the rest flicker badly (named FlickerLight_<how broken>).
    for (x, z) in ((-7, -3), (0, -3), (7, -3), (-7, 4), (0, 4), (7, 4)):
        if (x, z) in ((0, -3), (-7, 4)):
            box("DeadLamp", (x, h - 0.05, z), (1.2, 0.08, 0.35), "#3a3a36", False)
            continue
        pl = ('<Item class="PointLight" referent="%s"><Properties><float name="Brightness">1.0</float>'
              '<Color3 name="Color"><R>1</R><G>0.85</G><B>0.65</B></Color3><float name="Range">30</float>'
              '<bool name="Shadows">true</bool></Properties></Item>' % new_ref())
        box("FlickerLight_%.2f" % rng.choice([0.25, 0.4, 0.55]), (x, h - 0.05, z), (1.2, 0.08, 0.35), "!ffe6b8", False, children=pl)
    # A red warning light that pulses (named PulseLight for the light script).
    box("PulseLight", (0, h - 0.3, d / 2 - 0.3), (0.5, 0.3, 0.3), "!ff2010", False,
        children='<Item class="PointLight" referent="%s"><Properties><float name="Brightness">1.4</float>'
                 '<Color3 name="Color"><R>1</R><G>0.1</G><B>0.05</B></Color3><float name="Range">36</float></Properties></Item>' % new_ref())
    # A body bag on a gurney by the door.
    box("Gurney", (w / 2 - 1.6, 0.8, 4.8), (0.8, 0.08, 2.0), "#8a8c86")
    box("BodyBag", (w / 2 - 1.6, 0.98, 4.8), (0.6, 0.3, 1.75), "#1f2a22", False, shape=1)
    box("BodyBagHead", (w / 2 - 1.6, 1.02, 5.55), (0.32, 0.28, 0.3), "#1f2a22", False, shape=0)
    box("BodyBagZip", (w / 2 - 1.6, 1.14, 4.8), (0.03, 0.01, 1.7), "#8a8a80", False)
    for dx in (-0.33, 0.33):
        for dz in (-0.85, 0.85):
            box("GurneyLeg", (w / 2 - 1.6 + dx, 0.38, 4.8 + dz), (0.04, 0.76, 0.04), "#5a5c56", False)
    # The 4 character stands along the back wall, each with a figure on it.
    for role, x, color in STANDS:
        box("Stand_" + role, (x, 0.15, -5.6), (2.2, 0.3, 2.2), color)
        sl = ('<Item class="SpotLight" referent="%s"><Properties><float name="Brightness">4</float>'
              '<Color3 name="Color"><R>1</R><G>0.95</G><B>0.85</B></Color3><float name="Range">20</float>'
              '<float name="Angle">40</float><token name="Face">4</token><bool name="Shadows">true</bool></Properties></Item>' % new_ref())
        box("StandLamp_" + role, (x, h - 0.15, -5.6), (0.4, 0.2, 0.4), "#2a2a28", False, children=sl)
        figure(box, role, x, color)
        box("StandSign_" + role, (x, 3.1, -7.95), (2.6, 0.9, 0.05), "#141412", False)
    # Benches, a table with old papers, and the door to Site 12.
    box("Bench", (5, 0.45, 3.5), (4, 0.1, 0.7), "#4a3420")
    for dx in (-1.7, 1.7):
        box("BenchLeg", (5 + dx, 0.2, 3.5), (0.1, 0.4, 0.6), "#2e2e2a")
    box("BenchFallen", (-5, 0.36, 3.8), (4, 0.1, 0.7), "#4a3420", True, axes=tilt(90, 8))
    box("BriefingTable", (0, 0.8, 0.5), (3, 0.08, 1.4), "#4a3a2a")
    box("TableBase", (0, 0.4, 0.5), (2.6, 0.75, 1.0), "#3a3d34")
    for dx, dz in ((-0.8, 0.2), (0.3, 0.5), (0.9, 0.1)):
        box("Papers", (dx, 0.845, 0.5 + dz - 0.3), (0.3, 0.01, 0.4), "#d8d0b4", False)
    box("Door", (w / 2 - 0.02, 1.25, 0), (0.1, 2.5, 1.6), "rusty_metal", True)
    box("DoorLight", (w / 2 - 0.1, 2.8, 0), (0.15, 0.15, 0.15), "!ff2a14", False,
        children='<Item class="PointLight" referent="%s"><Properties><float name="Brightness">1.5</float>'
                 '<Color3 name="Color"><R>1</R><G>0.1</G><B>0.05</B></Color3><float name="Range">14</float></Properties></Item>' % new_ref())
    box("DoorSign", (w / 2 - 0.05, 3.3, 0), (0.05, 0.6, 2.2), "#141412", False)
    box("Board", (-w / 2 + 0.05, 2.4, 0), (0.06, 2.6, 6), "#10140f", False)
    # Where you appear when you join.
    out.append(part("LobbySpawn", g(at((0, 0.3, 4.8))), W, (8, 1, 6), "#262824", False, 1, 1.0, cls="SpawnLocation",
                    extra='<bool name="Neutral">true</bool><bool name="AllowTeamChangeOnTouch">false</bool>'))
    return (f'<Item class="Model" referent="{new_ref()}"><Properties><string name="Name">Lobby</string></Properties>'
            + "".join(out) + "</Item>")


def figure(box, role, x, color, z=-5.6, face=1):
    """A simple standing figure of the character (Roblox parts).
    face = 1: it faces +z, face = -1: it faces -z."""
    big = 1.15 if role == "Guard" else 0.92 if role == "Engineer" else 1.0
    def P(name, c, s, col, shape=1):
        box(f"Figure_{role}_{name}", (x - c[0] * big * face, 0.3 + c[1] * big, z - c[2] * big * face), tuple(v * big for v in s), col, False, shape)
    skin = "#c9a58a" if role != "Guard" else "#b98f74"
    pants = {"Son": "#3d4a63", "Journalist": "#22201e", "Engineer": "#2a3350", "Guard": "#4b4a3a"}[role]
    P("LegL", (-0.13, 0.42, 0), (0.2, 0.84, 0.24), pants); P("LegR", (0.13, 0.42, 0), (0.2, 0.84, 0.24), pants)
    coat_len = 0.95 if role == "Journalist" else 0.62
    P("Body", (0, 0.84 + 0.31, 0), (0.56, 0.62, 0.3), color)
    if role == "Journalist":
        P("Coat", (0, 0.84 + 0.31 - 0.2, 0.0), (0.6, coat_len, 0.34), color)
    P("ArmL", (-0.36, 1.12, 0), (0.16, 0.62, 0.2), color); P("ArmR", (0.36, 1.12, 0), (0.16, 0.62, 0.2), color)
    P("Head", (0, 1.62, 0), (0.3, 0.34, 0.3), skin, 0)
    if role == "Son":
        P("Hood", (0, 1.66, 0.03), (0.38, 0.4, 0.38), "#5b5f63", 0)
        P("Backpack", (0, 1.15, 0.24), (0.4, 0.45, 0.18), "#3a2c20")
    elif role == "Journalist":
        P("Hair", (0, 1.7, 0.06), (0.32, 0.26, 0.3), "#2a1a12", 0)
        P("Camera", (0.15, 1.2, -0.2), (0.24, 0.15, 0.12), "#111111")
        P("Flash", (0.15, 1.33, -0.2), (0.1, 0.1, 0.08), "#dddddd")
    elif role == "Engineer":
        P("Glasses", (0, 1.64, -0.16), (0.26, 0.06, 0.02), "#111111")
        P("Hair", (0, 1.76, 0.02), (0.31, 0.12, 0.3), "#9a9a96", 0)
        P("ToolBelt", (0, 0.86, 0), (0.6, 0.1, 0.34), "#4a3018")
        P("Wrench", (0.42, 0.78, -0.05), (0.06, 0.4, 0.04), "#8a8c90")
    elif role == "Guard":
        P("BuzzCut", (0, 1.73, 0.02), (0.3, 0.12, 0.3), "#222018", 0)
        P("Flashlight", (-0.42, 0.85, -0.05), (0.09, 0.4, 0.09), "#222222")


def script():
    road = ", ".join(v3(g(p)) for p in ROAD_START)
    return LOBBY_SCRIPT.replace("--ROAD--", road)


LOBBY_SCRIPT = r'''-- THE WAITING ROOM.
-- Everyone spawns here when they join. Walk up to a character's stand and
-- press E to pick them (no two players the same; press E on another free
-- stand to change your mind). When EVERYONE has picked and there are at
-- least 2 players, a 10 second countdown starts, then the whole team goes
-- into the game together. (In Studio you can test alone.)
-- Someone who joins later picks a free character and goes straight in.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local messageEvent = ReplicatedStorage:WaitForChild("PuzzleMessage")
local lobby = workspace:WaitForChild("Lobby")
-- Only in the GAME (not in the lobby hall: see the Mode script).
while not workspace:GetAttribute("Mode") do task.wait() end
if workspace:GetAttribute("Mode") ~= "Game" then return end

local ROAD = { --ROAD-- }
local NAMES = { Son = "THE SON (Ethan)", Journalist = "THE JOURNALIST", Engineer = "THE ENGINEER", Guard = "THE GUARD (Frank)" }
local ORDER = { "Son", "Journalist", "Engineer", "Guard" }
local COUNTDOWN = 10
local MIN_PLAYERS = RunService:IsStudio() and 1 or 2

workspace:SetAttribute("GameStarted", false)

local function sign(part, face, text, color, size)
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
	label.Text = text
	label.Parent = gui
	return label
end

local function takenBy(id)
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Character") == id then return p end
	end
	return nil
end

-- Came from the LOBBY place (the elevators)? Remember it, so we can go back.
local function rememberLobby(player)
	local ok, data = pcall(function() return player:GetJoinData().TeleportData end)
	if ok and type(data) == "table" and data.lobby then workspace:SetAttribute("LobbyPlaceId", data.lobby) end
	-- The character they picked in the lobby (if nobody here has it yet).
	local want = ok and type(data) == "table" and type(data.roles) == "table" and data.roles[tostring(player.UserId)]
	if want and NAMES[want] and not takenBy(want) and not player:GetAttribute("Character") then
		player:SetAttribute("Character", want)
	end
end
Players.PlayerAdded:Connect(rememberLobby)
for _, p in ipairs(Players:GetPlayers()) do rememberLobby(p) end
local function backToLobby(players)
	local lobbyId = workspace:GetAttribute("LobbyPlaceId")
	if not lobbyId then return false end
	return pcall(function() TeleportService:TeleportAsync(lobbyId, players) end)
end

-- Signs and prompts on the stands.
local standLabels = {}
for _, id in ipairs(ORDER) do
	local stand = lobby:WaitForChild("Stand_" .. id)
	standLabels[id] = sign(lobby:WaitForChild("StandSign_" .. id), Enum.NormalId.Back, NAMES[id], Color3.fromRGB(230, 220, 195))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick"
	prompt.ObjectText = NAMES[id]
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stand
	-- Step onto a stand to pick it (or press E, or use the buttons on screen).
	stand.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
		if player and not player:GetAttribute("InGame") and player:GetAttribute("Character") ~= id and not takenBy(id) then
			player:SetAttribute("Character", id)
		end
	end)
	prompt.Triggered:Connect(function(player)
		local other = takenBy(id)
		if other and other ~= player then
			messageEvent:FireClient(player, other.DisplayName .. " already picked " .. NAMES[id] .. ".")
			return
		end
		if player:GetAttribute("InGame") then
			messageEvent:FireClient(player, "You're already in the game!")
			return
		end
		player:SetAttribute("Character", id)
	end)
end
sign(lobby:WaitForChild("DoorSign"), Enum.NormalId.Left, "TO SITE 12", Color3.fromRGB(220, 60, 40))
local s1 = sign(lobby:WaitForChild("Scrawl1"), Enum.NormalId.Right, "DON'T GO DOWN THERE", Color3.fromRGB(120, 10, 6))
s1.Font = Enum.Font.Creepster
local s2 = sign(lobby:WaitForChild("Scrawl2"), Enum.NormalId.Front, "HE IS STILL DOWN THERE", Color3.fromRGB(110, 12, 8))
s2.Font = Enum.Font.Creepster
-- The door: back to the lobby (if you came from there).
local doorPrompt = Instance.new("ProximityPrompt")
doorPrompt.ActionText = "Back to the lobby"
doorPrompt.ObjectText = "Door"
doorPrompt.HoldDuration = 1
doorPrompt.RequiresLineOfSight = false
doorPrompt.Parent = lobby:WaitForChild("Door")
doorPrompt.Triggered:Connect(function(player)
	if not backToLobby({ player }) then
		messageEvent:FireClient(player, "There's no lobby to go back to (this game was started on its own).")
	end
end)
local board = sign(lobby:WaitForChild("Board"), Enum.NormalId.Right, "", Color3.fromRGB(110, 255, 140), 34)
board.Font = Enum.Font.Code
board.TextXAlignment = Enum.TextXAlignment.Left
board.TextYAlignment = Enum.TextYAlignment.Top

local function updateSigns()
	for _, id in ipairs(ORDER) do
		local owner = takenBy(id)
		standLabels[id].Text = NAMES[id] .. "\n" .. (owner and ("- " .. owner.DisplayName .. " -") or "[E] to pick\n(you keep your own avatar)")
	end
end

-- Send a player into the game, at the road (or the team's checkpoint).
local function sendIn(player, index)
	player:SetAttribute("InGame", true)
	local character = player.Character
	if not character then return end
	local point = workspace:GetAttribute("RespawnPoint") or ROAD[(index - 1) % #ROAD + 1]
	character:PivotTo(CFrame.new(point + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, 0))
end

local status = "Waiting for players..."
local function boardText()
	local lines = { "WAITING ROOM", "", "PLAYERS (" .. #Players:GetPlayers() .. "/4):" }
	for _, p in ipairs(Players:GetPlayers()) do
		local id = p:GetAttribute("Character")
		table.insert(lines, "  " .. p.DisplayName .. "  -  " .. (id and NAMES[id] or "(not picked yet)"))
	end
	table.insert(lines, "")
	table.insert(lines, status)
	board.Text = table.concat(lines, "\n")
	updateSigns()
end

-- Late joiners: as soon as they pick, they go in.
local function watch(player)
	player:GetAttributeChangedSignal("Character"):Connect(function()
		boardText()
		if workspace:GetAttribute("GameStarted") and not player:GetAttribute("InGame") and not workspace:GetAttribute("ChapterDone") then
			task.wait(1)
			sendIn(player, 1)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function() task.defer(boardText) end)

local function everyoneReady()
	local list = Players:GetPlayers()
	if #list < MIN_PLAYERS then return false, "Waiting for friends to join... (2-4 players)" end
	for _, p in ipairs(list) do
		if not p:GetAttribute("Character") then return false, "Everyone: pick a character at the stands!" end
	end
	return true, ""
end

while not workspace:GetAttribute("GameStarted") do
	local ready, why = everyoneReady()
	if ready then
		local left = COUNTDOWN
		while left > 0 do
			status = "EVERYONE'S READY!\nSTARTING IN " .. left .. "..."
			boardText()
			messageEvent:FireAllClients("Starting in " .. left .. "...")
			task.wait(1)
			left -= 1
			if not everyoneReady() then break end
		end
		if left == 0 then
			status = "GAME IN PROGRESS.\nJoined late? Pick a free character to go in."
			boardText()
			workspace:SetAttribute("GameStarted", true)
			for i, p in ipairs(Players:GetPlayers()) do sendIn(p, i) end
		end
	else
		status = why
		boardText()
		task.wait(0.5)
	end
end
workspace:GetAttributeChangedSignal("ChapterDone"):Connect(function()
	status = "CHAPTER 1 COMPLETE!\nThanks for playing."
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("InGame", false) end
	boardText()
	-- Everyone goes back to the lobby together.
	task.wait(6)
	if workspace:GetAttribute("LobbyPlaceId") then
		messageEvent:FireAllClients("Going back to the lobby...")
		backToLobby(Players:GetPlayers())
	else
		status = "CHAPTER 1 COMPLETE!\nThanks for playing. Rejoin to play again."
		boardText()
	end
end)
'''
