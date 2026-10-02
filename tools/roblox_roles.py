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
	if typeof(id) ~= "string" or not ROLES[id] then return end
	local other = takenBy(id)
	if other and other ~= player then return end
	player:SetAttribute("Character", id)
	if player.Character then dressUp(player, player.Character) end
	messageEvent:FireAllClients(player.DisplayName .. " is " .. ROLES[id].name .. ".")
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character) dressUp(player, character) end)
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

ROLES_UI = r'''-- The character pick screen, your ability button, and what the Son's
-- Sense and the Journalist's flash look like on your screen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local pickEvent = ReplicatedStorage:WaitForChild("PickCharacter")
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

-- THE PICK SCREEN ------------------------------------------------------------
local screen = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 7), BackgroundTransparency = 0, Visible = false }, gui)
make("TextLabel", { Size = UDim2.new(1, 0, 0.05, 0), Position = UDim2.fromScale(0, 0.93), BackgroundTransparency = 1,
	Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = Color3.fromRGB(140, 135, 120),
	Text = "SUBJECT ZERO  -  a co-op horror game for 2-4 players. Each player picks a different character." }, screen)
make("TextLabel", { Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, 0.05), BackgroundTransparency = 1,
	Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = Color3.fromRGB(225, 215, 195), Text = "CHOOSE YOUR CHARACTER" }, screen)
local row = make("Frame", { Size = UDim2.fromScale(0.94, 0.72), Position = UDim2.fromScale(0.03, 0.2), BackgroundTransparency = 1 }, screen)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.015, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center }, row)
local buttons = {}
for _, role in ipairs(ROLES) do
	local card = make("Frame", { Size = UDim2.fromScale(0.235, 1), BackgroundColor3 = Color3.fromRGB(28, 28, 26) }, row)
	make("Frame", { Size = UDim2.fromScale(1, 0.03), BackgroundColor3 = role.color, BorderSizePixel = 0 }, card)
	make("TextLabel", { Size = UDim2.fromScale(0.9, 0.1), Position = UDim2.fromScale(0.05, 0.06), BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = role.color, Text = role.name }, card)
	make("TextLabel", { Size = UDim2.fromScale(0.9, 0.06), Position = UDim2.fromScale(0.05, 0.16), BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = Color3.fromRGB(170, 165, 150), Text = role.who }, card)
	make("TextLabel", { Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.05, 0.25), BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite, TextScaled = true, TextWrapped = true, TextColor3 = Color3.fromRGB(210, 205, 190),
		Text = role.trait }, card)
	make("TextLabel", { Size = UDim2.fromScale(0.9, 0.36), Position = UDim2.fromScale(0.05, 0.4), BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite, TextScaled = true, TextWrapped = true, TextColor3 = Color3.fromRGB(235, 228, 205),
		TextYAlignment = Enum.TextYAlignment.Top, Text = role.ability }, card)
	local b = make("TextButton", { Size = UDim2.fromScale(0.8, 0.11), Position = UDim2.fromScale(0.1, 0.84),
		BackgroundColor3 = role.color, Font = Enum.Font.SpecialElite, TextScaled = true, TextColor3 = Color3.new(0, 0, 0), Text = "PICK" }, card)
	b.Activated:Connect(function() pickEvent:FireServer(role.id) end)
	buttons[role.id] = b
end

local function refresh()
	for _, role in ipairs(ROLES) do
		local owner = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("Character") == role.id then owner = p end
		end
		local b = buttons[role.id]
		if owner then
			b.Text = owner == player and "YOU" or ("TAKEN: " .. owner.DisplayName)
			b.AutoButtonColor = false
			b.BackgroundColor3 = Color3.fromRGB(70, 68, 62)
		else
			b.Text = "PICK"
			b.AutoButtonColor = true
			b.BackgroundColor3 = role.color
		end
	end
end
local function watch(p)
	p:GetAttributeChangedSignal("Character"):Connect(refresh)
end
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerAdded:Connect(function(p) watch(p) refresh() end)
Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
refresh()

-- Pick FIRST, before the game starts (the opening cutscene plays after).
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
if not player:GetAttribute("Character") then
	controls:Disable()
	screen.Visible = true
	if GuiService:IsTenFootInterface() or UserInputService.GamepadEnabled then GuiService.SelectedObject = buttons.Son end
	player:GetAttributeChangedSignal("Character"):Wait()
	task.wait(0.8)
	screen.Visible = false
	GuiService.SelectedObject = nil
	controls:Enable()
end

-- YOUR ABILITY -----------------------------------------------------------------
local myRole
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
