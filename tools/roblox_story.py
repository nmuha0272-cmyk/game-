"""The STORY for the Roblox version: each character says things (speech
bubbles over their head, and a subtitle) at the start and in each new
place, about why THEY came to Site 12. Used by make_roblox.py.

  ELI (the Son, 21) ... his dad served at Site 12 during the Cold War and
                        never came home. Eli wants to know what he went through.
  THE JOURNALIST ...... chasing the "weather station" cover-up story.
  THE ENGINEER ........ kept these machines running for 20 years. Guilty.
  FRANK (the Guard) ... was the guard on duty in 1999 when the doors were sealed.
"""
S = 3.2

# Places (Godot meters: center, size) where the team says something the
# first time anyone walks in.
ZONES = [
    ("Gate", (0, 1.5, 26), (14, 4, 6)),
    ("Office", (-4, 1.5, -8), (12, 3, 12)),
    ("Stairs", (9, -2.5, -24), (3, 4, 6)),
    ("Tunnels", (9, -7.5, -40), (9, 3, 8)),
    ("Chart", (9, -7.5, -52), (4, 3, 5)),
    ("ElevatorRoom", (36, -7.5, -66), (10, 3, 10)),
]

LINES = {
    "Start": {
        "Son": "Dad's letters stopped in 1999. Whatever he went through in the Cold War... it happened here.",
        "Journalist": "A 'weather station' with armed guards and no weather equipment. This is my story.",
        "Engineer": "I swore I'd never come back to Site 12. I kept these machines running for twenty years...",
        "Guard": "I locked those doors in '99. I still hear them knocking every night.",
    },
    "Gate": {
        "Son": "Dad drew this fence in his letters. He said the 'weather' here was top secret.",
        "Journalist": "Fresh tire tracks. Somebody still checks on this place.",
        "Engineer": "The gate motor's dead. We'll have to lift it by hand.",
        "Guard": "Same gate. Same rust. It's like it was waiting for me.",
    },
    "Office": {
        "Son": "Dad's desk could've been one of these. Is there anything with his name on it?",
        "Journalist": "Look at these files. They never even cleaned it out.",
        "Engineer": "The director's terminal. Voice-locked: he didn't trust anybody.",
        "Guard": "The director gave the order... and walked out before the doors closed.",
    },
    "Stairs": {
        "Son": "Tally marks... someone was counting the days down here.",
        "Journalist": "This stairwell isn't on any blueprint I found.",
        "Engineer": "The emergency stairs. We used them when the elevator broke. It broke a lot.",
        "Guard": "Stay close. Keep your flashlights on.",
    },
    "Tunnels": {
        "Son": "Dad... were you down here the whole time?",
        "Journalist": "It smells like rust... and something worse.",
        "Engineer": "These tunnels run under the whole base. Pipes, cables... and the cells.",
        "Guard": "This is where they kept the volunteers. Keep your voices down.",
    },
    "Chart": {
        "Son": "Nine feet two... That's not a person anymore. Was Dad one of them?",
        "Journalist": "A growth chart. Week 31: 'past the ceiling.' What did they DO to him?",
        "Engineer": "Program Zero. They told the volunteers it was vitamins.",
        "Guard": "Subject 7. I used to bring his food tray. He always said thank you.",
    },
    "Reveal": {
        "Son": "That thing... it was a soldier. Like Dad.",
        "Journalist": "Don't stop, don't look back... RUN!",
        "Engineer": "Subject 7... God forgive us.",
        "Guard": "RUN! I'll be right behind you!",
    },
    "ElevatorRoom": {
        "Son": "Level B. If Dad's anywhere... he's down there.",
        "Journalist": "Containment orders, launch keys... they planned to bury everyone.",
        "Engineer": "Two fuses and the old generator. I can get this working.",
        "Guard": "Two keys. One for me... and one for the officer who never showed up.",
    },
    "Tape": {
        "Son": "That voice... Dad wrote about a Director Calloway.",
        "Journalist": "'A simple course of vitamins.' I've heard that lie before.",
        "Engineer": "Calloway. He made that speech to every new group.",
        "Guard": "I heard that tape a hundred times. I still hate it.",
    },
    "Order": {
        "Son": "'Regardless of personnel inside.' They left him down there ON PURPOSE.",
        "Journalist": "This is it. Proof they sealed people in alive.",
        "Engineer": "Two officers, two keys, at the same time. Typical military.",
        "Guard": "My name should be on this order. I'm the one who sealed it.",
    },
    "Descend": {
        "Son": "Hold on, Dad. I'm coming.",
        "Journalist": "This goes all the way to the top...",
        "Engineer": "These cables are old. Too old...",
        "Guard": "Hang on to something!",
    },
}


def v3(p): return f"Vector3.new({p[0] * S:.2f}, {p[1] * S:.2f}, {p[2] * S:.2f})"
def lua_str(t): return '"' + t.replace("\\", "\\\\").replace('"', '\\"') + '"'


def server():
    zones = ",\n\t".join(f'{{ name = "{n}", center = {v3(c)}, size = {v3(s)} }}' for n, c, s in ZONES)
    lines = ",\n\t".join(f'{k} = {{ ' + ", ".join(f'{r} = {lua_str(t)}' for r, t in v.items()) + " }" for k, v in LINES.items())
    return STORY_SERVER.replace("--ZONES--", zones).replace("--LINES--", lines)


STORY_SERVER = r'''-- THE STORY: the characters talk (speech bubbles + subtitles).
-- Why are they here?
--  ELI (the Son): his dad served at Site 12 during the Cold War and never
--                 came home. Eli wants to know what his dad went through.
--  THE JOURNALIST: chasing the "weather station" cover-up.
--  THE ENGINEER: kept these machines running for 20 years. Feels guilty.
--  FRANK (the Guard): the guard on duty in 1999 who sealed the doors.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sayEvent = ReplicatedStorage:WaitForChild("SayLine")
while not workspace:GetAttribute("Mode") do task.wait() end
if workspace:GetAttribute("Mode") ~= "Game" then return end

local ZONES = {
	--ZONES--
}
local LINES = {
	--LINES--
}
local done = {}

local function inGame()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("InGame") and p:GetAttribute("Character") and p.Character then table.insert(list, p) end
	end
	return list
end

-- One character says their line for this moment.
local function speak(player, moment)
	local role = player and player:GetAttribute("Character")
	local text = role and LINES[moment] and LINES[moment][role]
	if text then sayEvent:FireAllClients(player, role, text) end
end

-- A moment the whole team reacts to: the first person speaks, then a teammate answers.
local function moment(name, first)
	if done[name] then return end
	done[name] = true
	local team = inGame()
	if #team == 0 then return end
	first = first or team[math.random(1, #team)]
	speak(first, name)
	local others = {}
	for _, p in ipairs(team) do if p ~= first then table.insert(others, p) end end
	if #others > 0 then
		task.delay(3.5, function() speak(others[math.random(1, #others)], name) end)
	end
end

-- At the start: everyone says why they came, one after another.
task.spawn(function()
	while #inGame() == 0 do task.wait(1) end
	task.wait(16)  -- after the opening cutscene
	for i, p in ipairs(inGame()) do
		task.delay((i - 1) * 4.5, function() speak(p, "Start") end)
	end
end)

-- New places.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(inGame()) do
			local root = p.Character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, z in ipairs(ZONES) do
					if not done[z.name] then
						local d = root.Position - z.center
						if math.abs(d.X) < z.size.X / 2 and math.abs(d.Y) < z.size.Y / 2 + 2 and math.abs(d.Z) < z.size.Z / 2 then
							moment(z.name, p)
						end
					end
				end
			end
		end
	end
end)

-- Story events.
local longMan = workspace:WaitForChild("LongMan")
local root = longMan:WaitForChild("Root")
root:GetAttributeChangedSignal("State"):Connect(function()
	if root:GetAttribute("State") == "STARE" then moment("Reveal") end
end)
workspace:GetAttributeChangedSignal("TapePlayed"):Connect(function() moment("Tape") end)
workspace:GetAttributeChangedSignal("OrderReadBy"):Connect(function()
	moment("Order", Players:GetPlayerByUserId(workspace:GetAttribute("OrderReadBy") or 0))
end)
workspace:GetAttributeChangedSignal("Descending"):Connect(function()
	for i, p in ipairs(inGame()) do
		task.delay((i - 1) * 1.6, function() speak(p, "Descend") end)
	end
end)
'''

STORY_CLIENT = r'''-- Shows what the characters say: a speech bubble over their head, and
-- a subtitle at the bottom ("ELI: ...") so you never miss it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local NAMES = { Son = "ELI", Journalist = "THE JOURNALIST", Engineer = "THE ENGINEER", Guard = "FRANK" }
local COLORS = { Son = Color3.fromRGB(205, 150, 100), Journalist = Color3.fromRGB(225, 200, 150),
	Engineer = Color3.fromRGB(140, 170, 240), Guard = Color3.fromRGB(170, 195, 120) }

local gui = Instance.new("ScreenGui")
gui.Name = "Subtitles"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 0.78, 0)
label.Size = UDim2.new(0.75, 0, 0, 60)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SpecialElite
label.TextSize = 24
label.TextWrapped = true
label.RichText = true
label.TextStrokeTransparency = 0.25
label.TextColor3 = Color3.fromRGB(235, 228, 205)
label.TextTransparency = 1
label.Parent = gui
local count = 0

ReplicatedStorage:WaitForChild("SayLine").OnClientEvent:Connect(function(speaker, role, text)
	-- The bubble over their head (Roblox's own chat bubbles).
	local head = speaker and speaker.Character and speaker.Character:FindFirstChild("Head")
	if head then pcall(function() TextChatService:DisplayBubble(head, text) end) end
	-- The subtitle.
	count += 1
	local mine = count
	local c = COLORS[role] or Color3.new(1, 1, 1)
	local hex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
	label.Text = '<font color="' .. hex .. '">' .. (NAMES[role] or "?") .. ':</font> ' .. text
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.25
	task.delay(5.5, function()
		if mine == count then
			TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end)
'''
