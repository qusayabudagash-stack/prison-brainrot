-- The always-on HUD:
--   top:    one stat bar (💰 coins | 💵 income/sec | 🍀 luck) with the LUCKY ROLLS progress bar and
--           the luck boost timer under it
--   left:   🎁 daily free roll, 🍀 free luck and 📊 odds tiles (a red dot when something is ready)
--   bottom: 🧠 BOOK  🛒 SHOP  [block picker + big 🎰 ROLL key]  ⬆️ UPGRADES  🔄 REBIRTH
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

local coinsLabel: TextLabel
local incomeLabel: TextLabel
local luckLabel: TextLabel
local statBar: Frame
local pityBar: Theme.ProgressBar
local boostLabel: TextLabel
local dailyTile: Theme.Tile
local freeLuckTile: Theme.Tile
local rebirthTile: Theme.Tile
local dailyBadge: TextLabel
local luckBadge: TextLabel
local rebirthBadge: TextLabel
local rollButton: TextButton
local rollGlow: Frame
local areaLabel: TextLabel
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

-- One segment of the stat bar: a label that fills the segment, in the segment's color.
local function segment(parent: Instance, width: number, color: Color3, order: number): TextLabel
	local holder = Theme.frame({
		Size = UDim2.new(0, width, 1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local label = Theme.label({
		Size = UDim2.new(1, -16, 1, -18),
		Position = UDim2.fromOffset(8, 9),
		TextColor3 = color,
		Text = "...",
		Parent = holder,
	})
	Theme.textStroke(label, 2)
	return label
end

local function divider(parent: Instance, order: number)
	Theme.frame({
		Size = UDim2.new(0, 2, 1, -22),
		BackgroundColor3 = C.Muted,
		BackgroundTransparency = 0.5,
		LayoutOrder = order,
		Parent = parent,
	})
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
	coinsLabel.Text = `💰 {Format.money(coins)}`
	if gained > 0 and gained < math.huge then
		floatUp(coinFloats, `+{Format.money(gained)}`, C.Gold, 110)
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
				then `{Format.chance(odds.chance)}  <font color="#9692B8">{Format.oneIn(odds.chance)}</font>`
				else "—"
			local color = if odds.rarity.id == "Secret" then "FF78E6" else odds.rarity.color:ToHex()
			row.Text = `<font color="#{color}">{odds.rarity.name}</font>   {chanceText}`
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
		rollGlow.Visible = false
		return
	end
	local cost = Formulas.rollCost(data, area)
	local affordable = State.coins() >= cost
	rollButton.Text = `🎰 ROLL\n<font size="26">{Format.money(cost)}</font>`
	rollButton.BackgroundColor3 = if affordable then C.Red else Color3.fromRGB(150, 96, 110)
	rollGlow.Visible = affordable
end

local function updateStats()
	local data = State.data()
	if not data then
		return
	end
	coinsLabel.Text = `💰 {Format.money(State.coins())}`
	if not RollUI.isBusy() then
		local income = State.income()
		if income > shownIncome and shownIncome > 0 then
			Theme.pop(statBar, 1.08)
		end
		shownIncome = income
		incomeLabel.Text = `💵 +{Format.money(income)}/sec`
		luckLabel.Text = `🍀 {Format.multiplier(State.luck())} Luck`
	end

	local pity = RollSystem.pityInfo(data.pity)
	if pity.guaranteed then
		pityBar.fill.BackgroundColor3 = C.Gold
		pityBar.set(1, "🍀 NEXT ROLL: GUARANTEED LEGENDARY+!")
	else
		local bonus = if pity.multiplier > 1 then `  <font color="#FFE066">x{pity.multiplier} Legendary+</font>` else ""
		pityBar.fill.BackgroundColor3 = C.Lime
		pityBar.set(pity.count / pity.target, `🍀 LUCKY ROLLS: {pity.count}/{pity.target}{bonus}`)
	end

	local rebirthCost = Formulas.rebirthCost(data.rebirths)
	rebirthBadge.Visible = State.coins() >= rebirthCost
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
	dailyBadge.Visible = dailyIn <= 0
	dailyTile.caption.Text = if dailyIn <= 0 then "FREE ROLL" else Format.time(dailyIn)
	dailyTile.button.BackgroundColor3 = if dailyIn <= 0 then C.Orange else C.Gray

	local boostLeft = data.boostUntil - now
	local luckIn = data.freeBoostReadyAt - now
	if boostLeft > 0 then
		boostLabel.Visible = true
		boostLabel.Text = `🍀 LUCK BOOST x{GameConfig.FREE_BOOST.multiplier}  {Format.time(boostLeft)}`
	else
		boostLabel.Visible = false
	end
	luckBadge.Visible = luckIn <= 0
	freeLuckTile.caption.Text = if luckIn <= 0 then "FREE LUCK" else Format.time(luckIn)
	freeLuckTile.button.BackgroundColor3 = if luckIn <= 0 then C.Green else C.Gray

	if not RollUI.isBusy() then
		luckLabel.Text = `🍀 {Format.multiplier(State.luck())} Luck`
	end
	-- The ROLL key breathes while you can afford a roll
	if rollGlow.Visible then
		rollGlow.BackgroundTransparency = 0.45 + 0.25 * math.sin(os.clock() * 3)
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

	-- Top: one dark stat bar, the lucky rolls bar and the boost timer
	local top = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(640, 130),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(top)
	statBar = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(640, 62),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.08,
		Parent = top,
	})
	Theme.corner(statBar, 20)
	Theme.stroke(statBar, C.Shadow, 3)
	Theme.gradient(statBar, C.White)
	Theme.list(
		statBar,
		Enum.FillDirection.Horizontal,
		0,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)
	coinsLabel = segment(statBar, 250, C.Gold, 1)
	divider(statBar, 2)
	incomeLabel = segment(statBar, 220, Color3.fromRGB(110, 236, 130), 3)
	divider(statBar, 4)
	luckLabel = segment(statBar, 160, C.Lime, 5)
	coinFloats = Theme.frame({ Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Parent = top })

	pityBar = Theme.progressBar({
		size = UDim2.fromOffset(420, 30),
		position = UDim2.new(0.5, 0, 0, 70),
		anchor = Vector2.new(0.5, 0),
		color = C.Lime,
		parent = top,
	})
	boostLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 104),
		Size = UDim2.fromOffset(300, 24),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(40, 110, 50),
		TextColor3 = C.Lime,
		Visible = false,
		Parent = top,
	})
	Theme.corner(boostLabel, 12)
	Theme.textStroke(boostLabel, 2)

	-- Left column: free stuff and odds
	local left = Theme.frame({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(96, 340),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(left)
	Theme.list(left, Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	dailyTile = Theme.tile({
		icon = "🎁",
		caption = "FREE ROLL",
		color = C.Orange,
		size = 84,
		layoutOrder = 1,
		parent = left,
	})
	freeLuckTile =
		Theme.tile({ icon = "🍀", caption = "FREE LUCK", color = C.Green, size = 84, layoutOrder = 2, parent = left })
	local oddsTile =
		Theme.tile({ icon = "📊", caption = "ODDS", color = C.Blue, size = 84, layoutOrder = 3, parent = left })
	dailyBadge = Theme.badge(dailyTile.button)
	luckBadge = Theme.badge(freeLuckTile.button)

	dailyTile.button.Activated:Connect(function()
		local data = State.data()
		if data and Formulas.dailyReadyAt(data) <= State.now() then
			RollUI.requestDailyRoll()
		end
	end)
	freeLuckTile.button.Activated:Connect(function()
		Remote.call("ClaimFreeBoost")
	end)

	-- Bottom: menu tiles around the roll key
	local bottom = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(820, 150),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(bottom)
	Theme.list(
		bottom,
		Enum.FillDirection.Horizontal,
		14,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Bottom
	)

	local bookTile =
		Theme.tile({ icon = "🧠", caption = "BOOK", color = C.Pink, size = 86, layoutOrder = 1, parent = bottom })
	local shopTile =
		Theme.tile({ icon = "🛒", caption = "SHOP", color = C.Green, size = 86, layoutOrder = 2, parent = bottom })

	local rollGroup =
		Theme.frame({ Size = UDim2.fromOffset(300, 150), BackgroundTransparency = 1, LayoutOrder = 3, Parent = bottom })
	local picker = Theme.frame({ Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Panel, Parent = rollGroup })
	Theme.corner(picker, 14)
	Theme.stroke(picker, C.Shadow, 3)
	local prevButton = Theme.button({
		text = "◀",
		color = C.Blue,
		size = UDim2.fromOffset(44, 34),
		position = UDim2.fromOffset(3, 3),
		parent = picker,
	})
	local nextButton = Theme.button({
		text = "▶",
		color = C.Blue,
		size = UDim2.fromOffset(44, 34),
		position = UDim2.new(1, -47, 0, 3),
		parent = picker,
	})
	areaLabel = Theme.label({
		Position = UDim2.fromOffset(52, 5),
		Size = UDim2.new(1, -104, 1, -10),
		Text = "",
		Parent = picker,
	})
	rollGlow = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 98),
		Size = UDim2.new(1, 22, 0, 112),
		BackgroundColor3 = C.Gold,
		BackgroundTransparency = 0.5,
		Parent = rollGroup,
	})
	Theme.corner(rollGlow, 28)
	rollButton = Theme.button({
		text = "🎰 ROLL",
		color = C.Red,
		size = UDim2.new(1, 0, 0, 98),
		position = UDim2.fromOffset(0, 49),
		parent = rollGroup,
	})
	Theme.corner(rollButton, 22)

	local upgradeTile = Theme.tile({
		icon = "⬆️",
		caption = "UPGRADES",
		color = C.Blue,
		size = 86,
		layoutOrder = 4,
		parent = bottom,
	})
	rebirthTile = Theme.tile({
		icon = "🔄",
		caption = "REBIRTH",
		color = C.Purple,
		size = 86,
		layoutOrder = 5,
		parent = bottom,
	})
	rebirthBadge = Theme.badge(rebirthTile.button)

	bookTile.button.Activated:Connect(function()
		Theme.togglePanel("Collection")
	end)
	shopTile.button.Activated:Connect(function()
		Theme.togglePanel("Shop", "Cosmetics")
	end)
	upgradeTile.button.Activated:Connect(function()
		Theme.togglePanel("Shop", "Upgrades")
	end)
	rebirthTile.button.Activated:Connect(function()
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
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(340, 410),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = screen,
	})
	Theme.corner(oddsPanel, 20)
	Theme.stroke(oddsPanel, C.Shadow, 3)
	Theme.gradient(oddsPanel, C.White)
	Theme.padding(oddsPanel, 12)
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
	oddsTile.button.Activated:Connect(function()
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
