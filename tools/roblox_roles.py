"""The four characters for the Roblox version (like the PC game). Each
player picks one (no two the same) and keeps their own avatar, with the
character's name over their head. Used by make_roblox.py."""

ROLES_SERVER = r'''-- THE FOUR CHARACTERS. Each player picks one (no two players the same).
--  The Son (Ethan) ... SENSE (Q): see the Long Man and useful things
--                      through walls for 4 seconds.
--  The Journalist .... CAMERA FLASH (Q): blinds the Long Man for 3 seconds
--                      (he hates light). Point it at him!
--  The Engineer ...... FIXER: repairs the generator and puts in fuses
--                      about 3 times faster.
--  The Guard (Frank) . STRONG: moves the heavy cabinet alone. TOUGH: once
--                      per life he can shove the Long Man off. A bit slower.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local pickEvent = ReplicatedStorage:WaitForChild("PickCharacter")
local abilityEvent = ReplicatedStorage:WaitForChild("UseAbility")
local flashEvent = ReplicatedStorage:WaitForChild("CameraFlash")
local messageEvent = ReplicatedStorage:WaitForChild("PuzzleMessage")

local ROLES = {
	Son = { name = "Ethan (The Son)", color = Color3.fromRGB(150, 100, 60) },
	Journalist = { name = "The Journalist", color = Color3.fromRGB(205, 175, 125) },
	Engineer = { name = "The Engineer", color = Color3.fromRGB(90, 120, 200) },
	Guard = { name = "Frank (The Guard)", color = Color3.fromRGB(130, 150, 90) },
}

local function takenBy(id)
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Character") == id then return p end
	end
	return nil
end

local function dressUp(player, character)
	local id = player:GetAttribute("Character")
	local role = id and ROLES[id]
	local head = character:WaitForChild("Head", 10)
	if not role or not head then return end
	local old = head:FindFirstChild("RoleTag")
	if old then old:Destroy() end
	local tag = Instance.new("BillboardGui")
	tag.Name = "RoleTag"
	tag.Size = UDim2.fromOffset(200, 40)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.MaxDistance = 70
	tag.LightInfluence = 0
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SpecialElite
	label.TextScaled = true
	label.TextColor3 = role.color
	label.TextStrokeTransparency = 0.4
	label.Text = player.DisplayName .. "\n" .. role.name
	label.Parent = tag
	character:SetAttribute("Tough", id == "Guard")
end

pickEvent.OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "string" or not ROLES[id] or player:GetAttribute("InGame") then return end
	local other = takenBy(id)
	if other and other ~= player then return end
	player:SetAttribute("Character", id)
end)

-- Picked (at a stand in the waiting room): name tag on, and tell everyone.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character) dressUp(player, character) end)
	player:GetAttributeChangedSignal("Character"):Connect(function()
		local id = player:GetAttribute("Character")
		if player.Character then dressUp(player, player.Character) end
		if id then messageEvent:FireAllClients(player.DisplayName .. " picked " .. ROLES[id].name .. ".") end
	end)
end)

-- The Journalist's camera flash.
local lastFlash = {}
abilityEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Character") ~= "Journalist" then return end
	local now = os.clock()
	if lastFlash[player] and now - lastFlash[player] < 11.5 then return end
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then return end
	lastFlash[player] = now
	local burst = Instance.new("PointLight")
	burst.Brightness = 25
	burst.Range = 45
	burst.Color = Color3.fromRGB(235, 240, 255)
	burst.Parent = head
	task.delay(0.15, function() burst:Destroy() end)
	flashEvent:FireAllClients(head.Position, player)
	local longMan = workspace:FindFirstChild("LongMan")
	local root = longMan and longMan:FindFirstChild("Root")
	if not root then return end
	local skull = longMan:FindFirstChild("Head_Skull")
	local target = skull and skull.Position or root.Position
	local offset = target - head.Position
	local camLook = head.CFrame.LookVector
	if offset.Magnitude < 45 and camLook:Dot(offset.Unit) > 0.55 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { longMan, player.Character }
		if workspace:Raycast(head.Position, offset, params) == nil then
			longMan:SetAttribute("StunUntil", workspace:GetServerTimeNow() + 3)
			messageEvent:FireAllClients("The flash blinds him! RUN!")
		end
	end
end)
'''

ROLES_UI = r'''-- Your ability button, and what the Son's Sense and the Journalist's
-- flash look like on your screen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local abilityEvent = ReplicatedStorage:WaitForChild("UseAbility")

local ROLES = {
	{ id = "Son", name = "THE SON", who = "Ethan, 21", color = Color3.fromRGB(150, 100, 60),
		trait = "Hood up, always jumpy.", ability = "SENSE  [Q]\nSee the Long Man and useful things through walls for 4 seconds.", cooldown = 15 },
	{ id = "Journalist", name = "THE JOURNALIST", who = "35, tan trench coat", color = Color3.fromRGB(205, 175, 125),
		trait = "Here for the story.", ability = "CAMERA FLASH  [Q]\nBlinds the Long Man for 3 seconds. Point it at him!", cooldown = 12 },
	{ id = "Engineer", name = "THE ENGINEER", who = "60, navy coveralls", color = Color3.fromRGB(90, 120, 200),
		trait = "Knows these old machines.", ability = "FIXER  (always on)\nRepairs the generator and puts in fuses 3x faster." },
	{ id = "Guard", name = "THE GUARD", who = "Frank, 35, olive jacket", color = Color3.fromRGB(130, 150, 90),
		trait = "Big and strong, a bit slower.", ability = "STRONG + TOUGH  (always on)\nMoves the heavy cabinet alone. Once per life, shoves the Long Man off." },
}

local gui = Instance.new("ScreenGui")
gui.Name = "Characters"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, props, parent)
	local thing = Instance.new(class)
	for k, v in pairs(props) do thing[k] = v end
	thing.Parent = parent
	return thing
end

-- PICK BUTTONS (in the waiting room) ---------------------------------------
-- Big buttons at the bottom of the screen: click one to pick that character.
-- (You can also walk onto a stand, or press E at it.) You keep your avatar.
local pickEvent = ReplicatedStorage:WaitForChild("PickCharacter")
local picker = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -95),
	Size = UDim2.new(0.92, 0, 0, 150), BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.25 }, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(980, 150) }, picker)
local header = make("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.SpecialElite,
	TextSize = 22, TextColor3 = Color3.fromRGB(230, 220, 195), Text = "PICK YOUR CHARACTER  (you keep your own avatar)" }, picker)
local row = make("Frame", { Position = UDim2.new(0, 8, 0, 34), Size = UDim2.new(1, -16, 1, -42), BackgroundTransparency = 1 }, picker)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center }, row)
local pickButtons = {}
local SHORT = { Son = "Sees the monster through walls", Journalist = "Camera flash blinds him",
	Engineer = "Fixes things 3x faster", Guard = "Strong + survives one catch" }
for _, role in ipairs(ROLES) do
	local b = make("TextButton", { Size = UDim2.new(0.25, -6, 1, 0), BackgroundColor3 = role.color, AutoButtonColor = true,
		Font = Enum.Font.SpecialElite, TextSize = 20, TextWrapped = true, TextColor3 = Color3.new(0, 0, 0),
		Text = role.name .. "\n" .. SHORT[role.id] }, row)
	b.Activated:Connect(function() pickEvent:FireServer(role.id) end)
	pickButtons[role.id] = b
end
local function refreshPicker()
	picker.Visible = not player:GetAttribute("InGame")
	local mine = player:GetAttribute("Character")
	header.Text = mine and ("You are " .. mine:upper() .. "  -  click another one to change") or "PICK YOUR CHARACTER  (you keep your own avatar)"
	for _, role in ipairs(ROLES) do
		local owner
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("Character") == role.id then owner = p end
		end
		local b = pickButtons[role.id]
		if owner == player then
			b.Text = "YOU: " .. role.name .. "\n" .. SHORT[role.id]
			b.BackgroundColor3 = role.color:Lerp(Color3.new(1, 1, 1), 0.35)
		elseif owner then
			b.Text = role.name .. "\nTAKEN by " .. owner.DisplayName
			b.BackgroundColor3 = Color3.fromRGB(70, 68, 62)
		else
			b.Text = role.name .. "\n" .. SHORT[role.id]
			b.BackgroundColor3 = role.color
		end
	end
end
local function watchPicks(p)
	p:GetAttributeChangedSignal("Character"):Connect(refreshPicker)
	p:GetAttributeChangedSignal("InGame"):Connect(refreshPicker)
end
for _, p in ipairs(Players:GetPlayers()) do watchPicks(p) end
Players.PlayerAdded:Connect(function(p) watchPicks(p) refreshPicker() end)
Players.PlayerRemoving:Connect(function() task.defer(refreshPicker) end)
refreshPicker()

-- YOUR ABILITY -----------------------------------------------------------------
-- (You pick your character at the stands in the waiting room. Your
-- ability button shows up when you go into the game.)
local myRole
while not (player:GetAttribute("InGame") and player:GetAttribute("Character")) do task.wait(0.2) end
for _, role in ipairs(ROLES) do
	if role.id == player:GetAttribute("Character") then myRole = role end
end
local abilityButton = make("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -110),
	Size = UDim2.fromOffset(190, 54), BackgroundColor3 = Color3.fromRGB(25, 25, 23), BackgroundTransparency = 0.25,
	Font = Enum.Font.SpecialElite, TextSize = 20, TextWrapped = true, TextColor3 = myRole.color }, gui)
local ACTIVE = { Son = "SENSE", Journalist = "FLASH" }
local readyAt = 0
local function label()
	if not ACTIVE[myRole.id] then
		abilityButton.Text = myRole.id == "Engineer" and "FIXER (always on)" or "STRONG + TOUGH"
		return
	end
	local left = math.ceil(readyAt - os.clock())
	local key = UserInputService.GamepadEnabled and "[B]" or "[Q]"
	abilityButton.Text = left > 0 and (ACTIVE[myRole.id] .. "  " .. left .. "s") or (key .. " " .. ACTIVE[myRole.id])
end
task.spawn(function() while true do label() task.wait(0.25) end end)

local function sense()
	-- The Long Man glows red, useful things glow yellow, through walls.
	local glows = {}
	local function glow(thing, color)
		local h = Instance.new("Highlight")
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = 0.6
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Adornee = thing
		h.Parent = gui
		table.insert(glows, h)
	end
	local longMan = workspace:FindFirstChild("LongMan")
	if longMan then glow(longMan, Color3.fromRGB(255, 30, 20)) end
	local items = workspace:FindFirstChild("Items")
	if items then
		for _, tool in ipairs(items:GetChildren()) do glow(tool, Color3.fromRGB(255, 220, 80)) end
	end
	local puzzles = workspace:FindFirstChild("Puzzles")
	if puzzles then
		for _, part in ipairs(puzzles:GetChildren()) do
			if part:FindFirstChildOfClass("ProximityPrompt") then glow(part, Color3.fromRGB(120, 200, 255)) end
		end
	end
	task.delay(4, function() for _, h in ipairs(glows) do h:Destroy() end end)
end

local function useAbility()
	if not ACTIVE[myRole.id] or os.clock() < readyAt then return end
	readyAt = os.clock() + myRole.cooldown
	if myRole.id == "Son" then sense() else abilityEvent:FireServer() end
	label()
end
abilityButton.Activated:Connect(useAbility)
UserInputService.InputBegan:Connect(function(input, typing)
	if typing then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then useAbility() end
end)

-- The Engineer: repair prompts are quicker for you.
if myRole.id == "Engineer" then
	local function faster(prompt)
		local quick = prompt:GetAttribute("EngineerHold")
		if quick then prompt.HoldDuration = quick end
	end
	ProximityPromptService.PromptShown:Connect(faster)
end

-- A camera flash near you: the screen goes white for a moment.
ReplicatedStorage:WaitForChild("CameraFlash").OnClientEvent:Connect(function(position, who)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then return end
	local d = (head.Position - position).Magnitude
	if d > 50 then return end
	local white = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = who == player and 0.1 or math.clamp(0.3 + d / 60, 0.3, 0.95), BorderSizePixel = 0 }, gui)
	TweenService:Create(white, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
	task.delay(0.8, function() white:Destroy() end)
end)
'''
