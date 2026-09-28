-- The first-time tutorial: a welcome card and five quick steps. Skippable at any time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Net = require(ReplicatedStorage.Modules.Net)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)

local TutorialUI = {}

local C = Theme.Colors

local STEPS = {
	{ emoji = "🧠", title = "WELCOME TO PRISON BRAINROT!", body = GameConfig.TAGLINE, color = C.Pink },
	{
		emoji = "🎰",
		title = "STEP 1: Roll for a Brainrot!",
		body = "Press the big red ROLL button, or the red button on a roll machine.",
		color = C.Red,
	},
	{
		emoji = "💰",
		title = "STEP 2: Brainrots make you MONEY!",
		body = "Every Brainrot earns Coins every second - even while you chill.",
		color = C.Gold,
	},
	{
		emoji = "✨",
		title = "STEP 3: Get better Brainrots!",
		body = "Rarer Brainrots make WAY more money. 3 of the same combine into a Golden one!",
		color = C.Purple,
	},
	{
		emoji = "🔓",
		title = "STEP 4: Unlock new prison blocks!",
		body = "New blocks have luckier roll machines. Unlock them in the Shop or at the gates.",
		color = C.Blue,
	},
	{
		emoji = "👑",
		title = "STEP 5: Become the richest prisoner!",
		body = "Climb the leaderboards and REBIRTH for permanent luck.",
		color = C.Green,
	},
}

local shown = false

local function show()
	shown = true
	local screen = Theme.screen("TutorialUI", 40)
	Theme.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Active = true,
		Parent = screen,
	})

	local card = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 420),
		BackgroundColor3 = C.Cream,
		Parent = screen,
	})
	Theme.corner(card, 26)
	local stroke = Theme.stroke(card, C.Pink, 6)
	Theme.autoScale(card)

	local emoji = Theme.label({ Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 110), Parent = card })
	local title = Theme.label({ Position = UDim2.fromOffset(20, 130), Size = UDim2.new(1, -40, 0, 60), Parent = card })
	local body = Theme.label({
		Position = UDim2.fromOffset(30, 196),
		Size = UDim2.new(1, -60, 0, 90),
		TextColor3 = C.Dark,
		Parent = card,
	})
	local progress = Theme.label({
		Position = UDim2.fromOffset(0, 288),
		Size = UDim2.new(1, 0, 0, 24),
		TextColor3 = C.Gray,
		Parent = card,
	})

	local skip = Theme.button({
		text = "SKIP",
		color = C.Gray,
		size = UDim2.fromOffset(160, 64),
		position = UDim2.new(0, 30, 1, -88),
		parent = card,
	})
	local nextButton = Theme.button({
		text = "NEXT ▶",
		color = C.Green,
		size = UDim2.fromOffset(260, 64),
		position = UDim2.new(1, -290, 1, -88),
		parent = card,
	})

	local index = 1
	local function render()
		local step = STEPS[index]
		emoji.Text = step.emoji
		title.Text = step.title
		title.TextColor3 = step.color
		body.Text = step.body
		stroke.Color = step.color
		progress.Text = `{index} / {#STEPS}`
		nextButton.Text = if index == #STEPS then "LET'S GO! 🚀" else "NEXT ▶"
		Theme.pop(card, 0.9)
		Theme.pop(emoji, 1.4)
	end

	local function finish()
		Net.event("CompleteTutorial"):FireServer()
		screen:Destroy()
	end

	nextButton.Activated:Connect(function()
		if index >= #STEPS then
			finish()
		else
			index += 1
			render()
		end
	end)
	skip.Activated:Connect(finish)
	render()
end

function TutorialUI.init()
	State.Changed:Connect(function(state)
		if not shown and state and not state.data.tutorialDone then
			show()
		end
	end)
end

return TutorialUI
