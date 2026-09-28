-- The always-on HUD:
--   top:    💰 coins   💵 +income/sec   🍀 luck, with LUCKY ROLLS progress and boost timer underneath
--   left:   🎁 daily free roll and 🍀 free luck (with countdowns), 📊 odds
--   bottom: 🧠 BOOK  🛒 SHOP  🎰 ROLL (with block picker)  ⬆️ UPGRADES  🔄 REBIRTH
--   right:  the odds panel for the selected block

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local Events = require(ReplicatedStorage.Modules.Events)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local RollSystem = require(ReplicatedStorage.Modules.RollSystem)
local Remote = require(script.Parent.Parent.Controllers.Remote)
local RollUI = require(script.Parent.RollUI)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)

local MainUI = {}

local C = Theme.Colors

type Pill = { frame: Frame, label: TextLabel }

local coinsPill: Pill
local incomePill: Pill
local luckPill: Pill
local pityLabel: TextLabel
local boostLabel: TextLabel
local dailyButton: TextButton
local freeLuckButton: TextButton
local rollButton: TextButton
local areaLabel: TextLabel
local rebirthButton: TextButton
local oddsPanel: Frame
local oddsTitle: TextLabel
local oddsLuck: TextLabel
local oddsRows: { TextLabel } = {}
local oddsVariants: TextLabel
local coinFloats: Frame

local shownCoins = 0
local shownIncome = 0

---------------------------------------------------------------------------
-- Building blocks
---------------------------------------------------------------------------

local function pill(parent: Instance, color: Color3, width: number, order: number): Pill
	local frame = Theme.frame({
		Size = UDim2.fromOffset(width, 58),
		BackgroundColor3 = color,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.corner(frame, 18)
	Theme.stroke(frame, C.Shadow, 3)
	Theme.gradient(frame, C.White)
	local label = Theme.label({
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
		Text = "...",
		Parent = frame,
	})
	return { frame = frame, label = label }
end

local function floatUp(parent: Instance, text: string, color: Color3, x: number)
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, x, 1, -10),
		Size = UDim2.fromOffset(220, 34),
		Text = text,
		TextColor3 = color,
		Parent = parent,
	})
	Theme.textStroke(label, 2)
	Theme.tween(label, 1.1, { Position = UDim2.new(0, x, 1, 40), TextTransparency = 1 })
	task.delay(1.2, function()
		label:Destroy()
	end)
end

---------------------------------------------------------------------------
-- Updates
---------------------------------------------------------------------------

local function updateCoins(coins: number)
	local gained = coins - shownCoins
	shownCoins = coins
	coinsPill.label.Text = `💰 {Format.money(coins)}`
	if gained > 0 and gained < math.huge then
		floatUp(coinFloats, `+{Format.money(gained)}`, C.Gold, 130)
	end
end

local function updateOdds()
	local data = State.data()
	if not data then
		return
	end
	local area = State.selectedArea()
	local luck = Formulas.rollLuck(data, State.now(), Events.luckMultiplier(), area)
	oddsTitle.Text = `📊 {area.emoji} {area.name}`
	oddsLuck.Text = `🍀 Roll luck here: {Format.multiplier(luck)}`
	for index, odds in RollSystem.getOdds(luck, area, data.pity) do
		local row = oddsRows[index]
		if row then
			local chanceText = if odds.chance > 0
				then `{Format.chance(odds.chance)}  <font size="16">({Format.oneIn(odds.chance)})</font>`
				else "—"
			row.Text = `<font color="#{odds.rarity.color:ToHex()}">{odds.rarity.name}</font>   {chanceText}`
		end
	end
	local golden, diamond = RollSystem.variantChances(luck)
	oddsVariants.Text = `⭐ Golden {Format.chance(golden)}   💎 Diamond {Format.chance(diamond)}`
end

local function updateRollButton()
	local data = State.data()
	if not data then
		return
	end
	local area = State.selectedArea()
	areaLabel.Text = `{area.emoji} {area.name}`
	if RollUI.isBusy() then
		rollButton.Text = "🎰 ROLLING..."
		rollButton.BackgroundColor3 = C.Gray
		return
	end
	local cost = Formulas.rollCost(data, area)
	rollButton.Text = `🎰 ROLL\n<font size="24">{Format.money(cost)}</font>`
	rollButton.BackgroundColor3 = if State.coins() >= cost then C.Red else Color3.fromRGB(170, 90, 100)
end

local function updateStats()
	local data = State.data()
	if not data then
		return
	end
	coinsPill.label.Text = `💰 {Format.money(State.coins())}`
	if not RollUI.isBusy() then
		local income = State.income()
		if income > shownIncome and shownIncome > 0 then
			Theme.pop(incomePill.frame, 1.2)
		end
		shownIncome = income
		incomePill.label.Text = `💵 +{Format.money(income)}/sec`
		luckPill.label.Text = `🍀 {Format.multiplier(State.luck())} Luck`
	end

	local pity = RollSystem.pityInfo(data.pity)
	if pity.guaranteed then
		pityLabel.Text = "🍀 NEXT ROLL: GUARANTEED LEGENDARY+!"
	else
		local bonus = if pity.multiplier > 1
			then `  <font color="#FFE066">(x{pity.multiplier} Legendary+)</font>`
			else ""
		pityLabel.Text = `🍀 LUCKY ROLLS: {pity.count}/{pity.target}{bonus}`
	end

	local rebirthCost = Formulas.rebirthCost(data.rebirths)
	rebirthButton.Text = if State.coins() >= rebirthCost
		then '🔄 REBIRTH\n<font size="18">READY!</font>'
		else "🔄 REBIRTH"
	updateRollButton()
	updateOdds()
end

local function updateTimers()
	local data = State.data()
	if not data then
		return
	end
	local now = State.now()

	local dailyIn = Formulas.dailyReadyAt(data) - now
	if dailyIn <= 0 then
		dailyButton.Text = '🎁 FREE ROLL\n<font size="20">READY!</font>'
		dailyButton.BackgroundColor3 = C.Orange
	else
		dailyButton.Text = `🎁 FREE ROLL\n<font size="20">{Format.time(dailyIn)}</font>`
		dailyButton.BackgroundColor3 = Color3.fromRGB(190, 150, 110)
	end

	local boostLeft = data.boostUntil - now
	local luckIn = data.freeBoostReadyAt - now
	if boostLeft > 0 then
		boostLabel.Visible = true
		boostLabel.Text = `🍀 LUCK BOOST x{GameConfig.FREE_BOOST.multiplier}  {Format.time(boostLeft)}`
	else
		boostLabel.Visible = false
	end
	if luckIn <= 0 then
		freeLuckButton.Text = '🍀 FREE LUCK\n<font size="20">CLAIM!</font>'
		freeLuckButton.BackgroundColor3 = C.Green
	else
		freeLuckButton.Text = `🍀 FREE LUCK\n<font size="20">{Format.time(luckIn)}</font>`
		freeLuckButton.BackgroundColor3 = Color3.fromRGB(120, 170, 120)
	end

	if not RollUI.isBusy() then
		luckPill.label.Text = `🍀 {Format.multiplier(State.luck())} Luck`
	end
end

local function roll()
	if RollUI.isBusy() then
		return
	end
	RollUI.requestRoll(State.selectedArea().id)
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

function MainUI.init()
	local screen = Theme.screen("MainUI", 1)

	-- Top stats
	local top = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(700, 110),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(top)
	local stats = Theme.frame({ Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = top })
	Theme.list(stats, Enum.FillDirection.Horizontal, 10)
	coinsPill = pill(stats, C.Gold, 270, 1)
	incomePill = pill(stats, C.Green, 230, 2)
	luckPill = pill(stats, C.Lime, 170, 3)
	coinFloats = Theme.frame({ Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = top })

	pityLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(520, 26),
		Text = "",
		Parent = top,
	})
	boostLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(360, 22),
		TextColor3 = C.Lime,
		Visible = false,
		Parent = top,
	})
	Theme.textStroke(boostLabel, 2)

	-- Left column
	local left = Theme.frame({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(180, 270),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(left)
	Theme.list(left, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left)
	dailyButton = Theme.button({
		text = "🎁 FREE ROLL",
		color = C.Orange,
		size = UDim2.fromOffset(180, 80),
		layoutOrder = 1,
		parent = left,
	})
	freeLuckButton = Theme.button({
		text = "🍀 FREE LUCK",
		color = C.Green,
		size = UDim2.fromOffset(180, 80),
		layoutOrder = 2,
		parent = left,
	})
	local oddsButton = Theme.button({
		text = "📊 ODDS",
		color = C.Blue,
		size = UDim2.fromOffset(180, 60),
		layoutOrder = 3,
		parent = left,
	})

	dailyButton.Activated:Connect(function()
		local data = State.data()
		if data and Formulas.dailyReadyAt(data) <= State.now() then
			RollUI.requestDailyRoll()
		end
	end)
	freeLuckButton.Activated:Connect(function()
		Remote.call("ClaimFreeBoost")
	end)

	-- Bottom buttons
	local bottom = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(900, 136),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(bottom)
	Theme.list(
		bottom,
		Enum.FillDirection.Horizontal,
		12,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Bottom
	)

	local bookButton = Theme.button({
		text = "🧠 BOOK",
		color = C.Pink,
		size = UDim2.fromOffset(130, 86),
		layoutOrder = 1,
		parent = bottom,
	})
	local shopButton = Theme.button({
		text = "🛒 SHOP",
		color = C.Green,
		size = UDim2.fromOffset(130, 86),
		layoutOrder = 2,
		parent = bottom,
	})

	local rollGroup =
		Theme.frame({ Size = UDim2.fromOffset(300, 136), BackgroundTransparency = 1, LayoutOrder = 3, Parent = bottom })
	local picker = Theme.frame({ Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Dark, Parent = rollGroup })
	Theme.corner(picker, 12)
	Theme.stroke(picker, C.Shadow, 2)
	local prevButton = Theme.button({
		text = "◀",
		color = C.Blue,
		size = UDim2.fromOffset(44, 36),
		position = UDim2.fromOffset(2, 2),
		parent = picker,
	})
	local nextButton = Theme.button({
		text = "▶",
		color = C.Blue,
		size = UDim2.fromOffset(44, 36),
		position = UDim2.new(1, -46, 0, 2),
		parent = picker,
	})
	areaLabel = Theme.label({
		Position = UDim2.fromOffset(50, 4),
		Size = UDim2.new(1, -100, 1, -8),
		Text = "",
		Parent = picker,
	})
	rollButton = Theme.button({
		text = "🎰 ROLL",
		color = C.Red,
		size = UDim2.new(1, 0, 0, 90),
		position = UDim2.fromOffset(0, 46),
		parent = rollGroup,
	})

	local upgradeButton = Theme.button({
		text = "⬆️ UPGRADES",
		color = C.Blue,
		size = UDim2.fromOffset(130, 86),
		layoutOrder = 4,
		parent = bottom,
	})
	rebirthButton = Theme.button({
		text = "🔄 REBIRTH",
		color = C.Purple,
		size = UDim2.fromOffset(130, 86),
		layoutOrder = 5,
		parent = bottom,
	})

	bookButton.Activated:Connect(function()
		Theme.togglePanel("Collection")
	end)
	shopButton.Activated:Connect(function()
		Theme.togglePanel("Shop", "Cosmetics")
	end)
	upgradeButton.Activated:Connect(function()
		Theme.togglePanel("Shop", "Upgrades")
	end)
	rebirthButton.Activated:Connect(function()
		Theme.togglePanel("Rebirth")
	end)
	rollButton.Activated:Connect(roll)
	prevButton.Activated:Connect(function()
		State.cycleArea(-1)
	end)
	nextButton.Activated:Connect(function()
		State.cycleArea(1)
	end)

	-- Odds panel
	oddsPanel = Theme.frame({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(330, 400),
		BackgroundColor3 = C.Dark,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = screen,
	})
	Theme.corner(oddsPanel, 18)
	Theme.stroke(oddsPanel, C.Shadow, 3)
	Theme.padding(oddsPanel, 10)
	Theme.autoScale(oddsPanel)
	Theme.list(oddsPanel, Enum.FillDirection.Vertical, 4)
	oddsTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, Parent = oddsPanel })
	oddsLuck = Theme.label({ Size = UDim2.new(1, 0, 0, 24), TextColor3 = C.Lime, LayoutOrder = 2, Parent = oddsPanel })
	Theme.textStroke(oddsLuck, 2)
	for index = 1, #BrainrotData.Rarities do
		table.insert(
			oddsRows,
			Theme.label({
				Size = UDim2.new(1, 0, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2 + index,
				Parent = oddsPanel,
			})
		)
	end
	oddsVariants = Theme.label({ Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 20, Parent = oddsPanel })
	Theme.label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Better blocks = better odds!",
		TextColor3 = C.Gold,
		LayoutOrder = 21,
		Parent = oddsPanel,
	})
	oddsButton.Activated:Connect(function()
		oddsPanel.Visible = not oddsPanel.Visible
		if oddsPanel.Visible then
			Theme.pop(oddsPanel, 0.9)
			updateOdds()
		end
	end)

	-- Wiring
	State.Changed:Connect(updateStats)
	State.CoinsChanged:Connect(function(coins)
		updateCoins(coins)
		updateRollButton()
	end)
	RollUI.BusyChanged:Connect(function()
		updateStats()
	end)
	RollUI.Finished:Connect(function(result)
		local income = BrainrotData.income(result.brainrotId, result.variant)
		floatUp(coinFloats, `+{Format.money(income)}/sec`, C.Lime, 390)
	end)
	ReplicatedStorage:GetAttributeChangedSignal("EventId"):Connect(updateStats)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			roll()
		end
	end)

	task.spawn(function()
		while true do
			updateTimers()
			task.wait(0.25)
		end
	end)

	shownCoins = State.coins()
end

return MainUI
