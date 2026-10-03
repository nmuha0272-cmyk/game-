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
import os, sys
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
# The hall: checkered floor, green-and-cream walls, ceiling lamps.
box("Floor", (0, -0.1, 0), (w, 0.2, d), "#262824")
for i in range(int(w / 2)):
    for k in range(int(d / 2)):
        if (i + k) % 2 == 0:
            box("FloorTile", (-w / 2 + 1 + i * 2, 0.005, -d / 2 + 1 + k * 2), (2, 0.01, 2), "#d6d1bd", False)
box("Ceiling", (0, h + 0.1, 0), (w, 0.2, d), "#8f8b7c")
for name, c, s in (("WallN", (0, 0, -d / 2 - 0.15), (w + 0.6, 0, 0.3)), ("WallS", (0, 0, d / 2 + 0.15), (w + 0.6, 0, 0.3)),
                   ("WallW", (-w / 2 - 0.15, 0, 0), (0.3, 0, d)), ("WallE", (w / 2 + 0.15, 0, 0), (0.3, 0, d))):
    box(name + "Low", (c[0], 0.55, c[2]), (s[0], 1.1, s[2]), "#3f5a47")
    box(name + "Stripe", (c[0], 1.13, c[2]), (s[0] + (0.04 if s[0] < 1 else 0), 0.06, s[2] + (0.04 if s[2] < 1 else 0)), "#1d2a22")
    box(name + "High", (c[0], 1.16 + (h - 1.16) / 2, c[2]), (s[0], h - 1.16, s[2]), "#b9b49f")
for x in (-10, 0, 10):
    for z in (-3, 6):
        box("Lamp", (x, h - 0.05, z), (1.4, 0.08, 0.4), "!ffe6b8", False, children=light("PointLight", 1.4, 44))

# 4 elevators (cages) along the back wall.
for i, x in enumerate(ELEVATOR_X, 1):
    z0, z1 = -d / 2, -d / 2 + 4.2
    zc = (z0 + z1) / 2
    box(f"ElevatorFloor{i}", (x, 0.06, zc), (4, 0.12, 4.2), "#4a4d44", material=1056)
    box(f"ElevatorPad{i}", (x, 1.5, zc), (3.8, 3, 4), "#000000", False, transparency=1.0)
    for side in (-1, 1):
        box(f"ElevatorSide{i}", (x + side * 2.05, 1.75, zc), (0.1, 3.5, 4.2), "#3c3f38", transparency=0.45, material=1056)
    box(f"ElevatorRoof{i}", (x, 3.55, zc), (4.2, 0.12, 4.2), "#3c3f38", material=1056)
    box(f"ElevatorLamp{i}", (x, 3.42, zc), (0.8, 0.06, 0.8), "!fff0c8", False, children=light("PointLight", 1.2, 14))
    box(f"ElevatorGate{i}", (x, 5.35, z1 + 0.05), (4, 3.4, 0.08), "#2e302a", False, transparency=0.4, material=1056)
    box(f"ElevatorSign{i}", (x, 4.25, z1 + 0.06), (4.0, 1.2, 0.05), "#141412", False)
    box(f"ElevatorStatusLamp{i}", (x, 3.75, z1 + 0.1), (0.25, 0.25, 0.1), "!40ff60", False,
        children=light("PointLight", 1, 10, (0.3, 1, 0.4)))

# The four characters on show along the front wall (you pick yours in the game's waiting room).
for role, x, color in roblox_lobby.STANDS:
    box(f"Pedestal_{role}", (x * 1.2, 0.15, d / 2 - 2.2), (1.8, 0.3, 1.8), color)
    roblox_lobby.figure(lambda name, c, s, col, collide=False, shape=1: box(name, c, s, col, collide, shape),
                        role, x * 1.2, color, z=d / 2 - 2.2, face=-1)
    box(f"PedestalSign_{role}", (x * 1.2, 2.7, d / 2 - 0.02), (2.4, 0.7, 0.05), "#141412", False)
box("TitleBoard", (-w / 2 + 0.05, 3.4, 0), (0.06, 2.2, 10), "#10140f", False)
box("HowToBoard", (w / 2 - 0.05, 2.6, 0), (0.06, 3.2, 8), "#10140f", False)
box("Bench", (-4, 0.45, 3), (4, 0.1, 0.7), "#5c4128"); box("Bench", (4, 0.45, 3), (4, 0.1, 0.7), "#5c4128")
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
local howTo = sign(hall:WaitForChild("HowToBoard"), Enum.NormalId.Left, Color3.fromRGB(110, 255, 140), 30)
howTo.Font = Enum.Font.Code
howTo.TextXAlignment = Enum.TextXAlignment.Left
howTo.TextYAlignment = Enum.TextYAlignment.Top
howTo.Text = "HOW TO PLAY\n\n1. Walk into an ELEVATOR\n   with your friends\n   (or with anyone!).\n\n2. 2-4 players: it leaves\n   in " .. WAIT_TIME .. " seconds.\n\n3. Pick your character,\n   then survive Chapter 1\n   TOGETHER.\n\nFRIENDS ONLY: the first\nperson in can lock it\nto their friends.\n\nInvite friends: button\non the left of your screen."
local NAMES = { Son = "THE SON (Ethan)", Journalist = "THE JOURNALIST", Engineer = "THE ENGINEER", Guard = "THE GUARD (Frank)" }
for id, name in pairs(NAMES) do
	local s = hall:FindFirstChild("PedestalSign_" .. id)
	if s then sign(s, Enum.NormalId.Front, Color3.fromRGB(230, 220, 195)).Text = name end
end

-- The elevators.
local elevators = {}
for i = 1, 4 do
	local e = {
		index = i, pad = hall:WaitForChild("ElevatorPad" .. i), gate = hall:WaitForChild("ElevatorGate" .. i),
		lamp = hall:WaitForChild("ElevatorStatusLamp" .. i), members = {}, friendsOnly = false, countdown = nil, leaving = false,
	}
	e.gateUp = e.gate.CFrame
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
	TweenService:Create(e.gate, TweenInfo.new(1.2), { CFrame = e.gateUp - Vector3.new(0, 3.5 * 3.2, 0) }):Play()
	e.label.Text = "ELEVATOR " .. e.index .. "\nGOING DOWN..."
	task.wait(1.5)
	local placeId = gamePlaceId()
	local ok, err = false, "the game place wasn't found"
	if placeId then
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true  -- a private game just for this group
		options:SetTeleportData({ lobby = game.PlaceId })
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
	e.leaving = false
	e.countdown = nil
end

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
       '<float name="ClockTime">0</float><float name="Brightness">0.5</float><token name="Technology">4</token>'
       '<Color3 name="Ambient"><R>0.12</R><G>0.12</G><B>0.13</B></Color3>'
       '<Color3 name="OutdoorAmbient"><R>0.12</R><G>0.13</G><B>0.18</B></Color3></Properties>'
       f'<Item class="ColorCorrectionEffect" referent="{new_ref()}"><Properties><string name="Name">Cold</string>'
       '<float name="Contrast">0.1</float><float name="Saturation">-0.2</float>'
       '<Color3 name="TintColor"><R>0.94</R><G>0.96</G><B>1</B></Color3></Properties></Item></Item>',
       f'<Item class="ReplicatedStorage" referent="{new_ref()}"><Properties><string name="Name">ReplicatedStorage</string></Properties>'
       + "".join(f'<Item class="RemoteEvent" referent="{new_ref()}"><Properties><string name="Name">{n}</string></Properties></Item>'
                 for n in ("LobbyMessage", "ElevatorAction")) + "</Item>",
       f'<Item class="StarterPlayer" referent="{new_ref()}"><Properties><string name="Name">StarterPlayer</string>'
       '<token name="CameraMode">0</token><float name="CameraMaxZoomDistance">16</float></Properties>'
       f'<Item class="StarterPlayerScripts" referent="{new_ref()}"><Properties><string name="Name">StarterPlayerScripts</string></Properties>'
       + script("LocalScript", "LobbyButtons", LOBBY_UI) + "</Item></Item>",
       f'<Item class="ServerScriptService" referent="{new_ref()}"><Properties><string name="Name">ServerScriptService</string></Properties>'
       + script("Script", "Elevators", MATCHMAKING,
                f'<Item class="IntValue" referent="{new_ref()}"><Properties><string name="Name">GamePlaceId</string>'
                '<int64 name="Value">0</int64></Properties></Item>') + "</Item>",
       "</roblox>"]
open(OUT, "w").write("\n".join(xml))
print(f"wrote {OUT}: {len(parts)} parts")
