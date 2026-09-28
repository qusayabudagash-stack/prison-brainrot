-- 🔄 REBIRTH: shows what you lose, what you keep, and the permanent luck you gain. Asks twice before rebirthing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Remote = require(script.Parent.Parent.Controllers.Remote)
local Sounds = require(script.Parent.Parent.Controllers.Sounds)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)

local RebirthUI = {}

local C = Theme.Colors

local panel: Theme.Panel
local countLabel: TextLabel
local rewardLabel: TextLabel
local costLabel: TextLabel
local progressFill: Frame
local rebirthButton: TextButton
local confirmUntil = 0

local function refresh()
	local data = State.data()
	if not data then
		return
	end
	local cost = Formulas.rebirthCost(data.rebirths)
	local coins = State.coins()
	local perRebirth = math.floor(GameConfig.REBIRTH.luckPerRebirth * 100 + 0.5)
	countLabel.Text = `REBIRTHS: {data.rebirths}`
	rewardLabel.Text = `NEXT REWARD: +{perRebirth}% Luck FOREVER  (total +{(data.rebirths + 1) * perRebirth}%)`
	costLabel.Text = `{Format.money(math.min(coins, cost))} / {Format.money(cost)}`
	progressFill.Size = UDim2.fromScale(math.clamp(coins / cost, 0, 1), 1)

	local ready = coins >= cost
	if os.clock() < confirmUntil then
		rebirthButton.Text = "⚠️ ARE YOU SURE? TAP AGAIN!"
		Theme.setEnabled(rebirthButton, true, C.Red)
	else
		rebirthButton.Text = if ready then "🔄 REBIRTH NOW!" else `🔄 NEED {Format.money(cost)}`
		Theme.setEnabled(rebirthButton, ready, C.Purple)
	end
end

local function listBox(parent: Instance, position: UDim2, title: string, lines: { string }, color: Color3)
	local box = Theme.frame({
		Position = position,
		Size = UDim2.new(0.5, -8, 0, 170),
		BackgroundColor3 = C.White,
		Parent = parent,
	})
	Theme.corner(box, 14)
	Theme.stroke(box, color, 3)
	Theme.padding(box, 10)
	Theme.list(box, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Left)
	Theme.label({
		Size = UDim2.new(1, 0, 0, 30),
		Text = title,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = box,
	})
	for index, line in lines do
		Theme.label({
			Size = UDim2.new(1, 0, 0, 24),
			Text = line,
			TextColor3 = C.Dark,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = index,
			Parent = box,
		})
	end
end

function RebirthUI.init()
	panel = Theme.panel("RebirthUI", "🔄 REBIRTH", Vector2.new(640, 520), C.Purple)
	local content = panel.content

	countLabel = Theme.label({ Size = UDim2.new(1, 0, 0, 40), TextColor3 = C.Dark, Parent = content })
	rewardLabel = Theme.label({
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 30),
		TextColor3 = Color3.fromRGB(40, 160, 60),
		Parent = content,
	})

	listBox(
		content,
		UDim2.fromOffset(0, 82),
		"❌ YOU LOSE",
		{ "💰 Coins", "⬆️ Upgrades", "🔓 Prison blocks", "Common & Uncommon Brainrots" },
		C.Red
	)
	listBox(
		content,
		UDim2.new(0.5, 8, 0, 82),
		"✅ YOU KEEP",
		{ "🧠 Rare+ Brainrots", "📖 Brainrot Book", "🍀 All luck bonuses", "🛋️ Cell items" },
		C.Green
	)

	local track = Theme.frame({
		Position = UDim2.fromOffset(0, 266),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(220, 210, 235),
		Parent = content,
	})
	Theme.corner(track, 12)
	progressFill = Theme.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Gold, Parent = track })
	Theme.corner(progressFill, 12)
	costLabel = Theme.label({ Size = UDim2.fromScale(1, 1), Parent = track })

	rebirthButton = Theme.button({
		text = "🔄 REBIRTH",
		color = C.Purple,
		size = UDim2.new(1, 0, 0, 80),
		position = UDim2.fromOffset(0, 320),
		parent = content,
	})
	rebirthButton.Activated:Connect(function()
		if not rebirthButton.Active then
			return
		end
		if os.clock() >= confirmUntil then
			confirmUntil = os.clock() + 4
			refresh()
			task.delay(4.1, refresh)
			return
		end
		confirmUntil = 0
		if Remote.call("Rebirth").ok then
			Sounds.play("Rebirth")
			panel.close()
		else
			refresh()
		end
	end)

	Theme.onOpen("Rebirth", function()
		panel.open()
		refresh()
	end)
	State.Changed:Connect(function()
		if panel.isOpen() then
			refresh()
		end
	end)
	State.CoinsChanged:Connect(function()
		if panel.isOpen() then
			refresh()
		end
	end)
end

return RebirthUI
