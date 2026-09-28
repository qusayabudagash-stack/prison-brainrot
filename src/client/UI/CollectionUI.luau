-- 🧠 BRAINROT BOOK: every Brainrot in the game. Unknown ones show as a black silhouette and "???".
-- Known ones show name, rarity, income, how many you own of each variant, and combine buttons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Remote = require(script.Parent.Parent.Controllers.Remote)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)
local Viewport = require(script.Parent.Viewport)

local CollectionUI = {}

local C = Theme.Colors
local COMBINE = GameConfig.COMBINE_COST

type Card = {
	brainrot: BrainrotData.Brainrot,
	frame: Frame,
	viewport: ViewportFrame,
	nameLabel: TextLabel,
	incomeLabel: TextLabel,
	countLabel: TextLabel,
	workingLabel: TextLabel,
	goldenButton: TextButton,
	diamondButton: TextButton,
	shown: string?,
}

local panel: Theme.Panel
local cards: { Card } = {}
local totalLabel: TextLabel
local progressFill: Frame
local rarityChips: { [string]: TextLabel } = {}
local infoLabel: TextLabel
local built = false

local function bestVariant(counts: { [string]: number }?): string
	if counts then
		if (counts.Diamond or 0) > 0 then
			return "Diamond"
		elseif (counts.Golden or 0) > 0 then
			return "Golden"
		end
	end
	return "Normal"
end

local function buildCard(parent: Instance, brainrot: BrainrotData.Brainrot, order: number): Card
	local rarity = BrainrotData.RarityById[brainrot.rarity]
	local frame = Theme.frame({ BackgroundColor3 = C.White, LayoutOrder = order, Parent = parent })
	Theme.corner(frame, 16)
	Theme.stroke(frame, rarity.color, 4)

	local bar = Theme.label({
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 0,
		BackgroundColor3 = if rarity.id == "Secret" then C.Purple else rarity.color,
		Text = rarity.name,
		Parent = frame,
	})
	Theme.corner(bar, 14)

	local viewport =
		Viewport.new({ Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 110), Parent = frame })
	local nameLabel = Theme.label({
		Position = UDim2.fromOffset(6, 142),
		Size = UDim2.new(1, -12, 0, 26),
		TextColor3 = C.Dark,
		Parent = frame,
	})
	local incomeLabel = Theme.label({
		Position = UDim2.fromOffset(6, 168),
		Size = UDim2.new(1, -12, 0, 20),
		TextColor3 = Color3.fromRGB(40, 160, 60),
		Parent = frame,
	})
	local countLabel = Theme.label({
		Position = UDim2.fromOffset(6, 190),
		Size = UDim2.new(1, -12, 0, 20),
		TextColor3 = C.Dark,
		Parent = frame,
	})
	local workingLabel = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 30),
		Size = UDim2.fromOffset(70, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Green,
		Text = "💼",
		Visible = false,
		Parent = frame,
	})
	Theme.corner(workingLabel, 8)

	local goldenButton = Theme.button({
		text = "⭐ x3",
		color = C.Gold,
		size = UDim2.new(0.5, -9, 0, 30),
		position = UDim2.new(0, 6, 1, -36),
		parent = frame,
	})
	local diamondButton = Theme.button({
		text = "💎 x3",
		color = Color3.fromRGB(90, 200, 240),
		size = UDim2.new(0.5, -9, 0, 30),
		position = UDim2.new(0.5, 3, 1, -36),
		parent = frame,
	})
	goldenButton.Activated:Connect(function()
		if goldenButton.Active then
			Remote.call("Combine", brainrot.id, "Normal")
		end
	end)
	diamondButton.Activated:Connect(function()
		if diamondButton.Active then
			Remote.call("Combine", brainrot.id, "Golden")
		end
	end)

	return {
		brainrot = brainrot,
		frame = frame,
		viewport = viewport,
		nameLabel = nameLabel,
		incomeLabel = incomeLabel,
		countLabel = countLabel,
		workingLabel = workingLabel,
		goldenButton = goldenButton,
		diamondButton = diamondButton,
		shown = nil,
	}
end

local function refreshCard(card: Card, known: boolean, counts: { [string]: number }?, working: number)
	local brainrot = card.brainrot
	if not known then
		if card.shown ~= "hidden" then
			card.shown = "hidden"
			Viewport.show(card.viewport, brainrot.id, "Normal", true)
		end
		card.frame.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
		card.nameLabel.Text = "???"
		card.nameLabel.TextColor3 = C.White
		card.incomeLabel.Text = "Not found yet"
		card.incomeLabel.TextColor3 = C.Gray
		card.countLabel.Text = ""
		card.workingLabel.Visible = false
		card.goldenButton.Visible = false
		card.diamondButton.Visible = false
		return
	end

	local variant = bestVariant(counts)
	if card.shown ~= variant then
		card.shown = variant
		Viewport.show(card.viewport, brainrot.id, variant)
	end
	local normal = if counts then counts.Normal or 0 else 0
	local golden = if counts then counts.Golden or 0 else 0
	local diamond = if counts then counts.Diamond or 0 else 0

	card.frame.BackgroundColor3 = C.White
	card.nameLabel.Text = `{brainrot.emoji} {brainrot.name}`
	card.nameLabel.TextColor3 = C.Dark
	card.incomeLabel.Text = `+{Format.money(brainrot.income)}/sec`
	card.incomeLabel.TextColor3 = Color3.fromRGB(40, 160, 60)
	card.countLabel.Text = `OWNED: {normal}   ⭐{golden}   💎{diamond}`
	card.workingLabel.Visible = working > 0
	card.workingLabel.Text = `💼 x{working}`

	card.goldenButton.Visible = true
	card.diamondButton.Visible = true
	Theme.setEnabled(card.goldenButton, normal >= COMBINE, C.Gold)
	Theme.setEnabled(card.diamondButton, golden >= COMBINE, Color3.fromRGB(90, 200, 240))
end

local function refresh()
	local data = State.data()
	if not data or not built then
		return
	end

	local workingById: { [string]: number } = {}
	for _, stack in Formulas.working(data) do
		workingById[stack.id] = (workingById[stack.id] or 0) + stack.count
	end

	local perRarity: { [string]: { found: number, total: number } } = {}
	for _, rarity in BrainrotData.Rarities do
		perRarity[rarity.id] = { found = 0, total = #BrainrotData.ByRarity[rarity.id] }
	end

	for _, card in cards do
		local known = data.discovered[card.brainrot.id] == true
		if known then
			perRarity[card.brainrot.rarity].found += 1
		end
		refreshCard(card, known, data.brainrots[card.brainrot.id], workingById[card.brainrot.id] or 0)
	end

	local found = Formulas.discoveredCount(data)
	local percent = math.floor(found / BrainrotData.Count * 100)
	totalLabel.Text = `COLLECTION: {found}/{BrainrotData.Count}  ({percent}%)`
	progressFill.Size = UDim2.fromScale(found / BrainrotData.Count, 1)
	for rarityId, counts in perRarity do
		local chip = rarityChips[rarityId]
		if chip then
			local done = if counts.found == counts.total then " ✅" else ""
			chip.Text = `{counts.found}/{counts.total}{done}`
		end
	end
	infoLabel.Text =
		`💼 Your best {State.current and State.current.capacity or GameConfig.BASE_CAPACITY} Brainrots earn Coins.  3 of the same = ⭐ Golden (2x).  3 Golden = 💎 Diamond (5x)!`
end

local function build()
	built = true
	local content = panel.content

	local header = Theme.frame({ Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = content })
	totalLabel = Theme.label({
		Size = UDim2.new(0.62, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Dark,
		Parent = header,
	})
	local track = Theme.frame({
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(0.62, 0, 0, 16),
		BackgroundColor3 = Color3.fromRGB(220, 210, 230),
		Parent = header,
	})
	Theme.corner(track, 8)
	progressFill = Theme.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Pink, Parent = track })
	Theme.corner(progressFill, 8)

	local combineAll = Theme.button({
		text = "✨ COMBINE ALL",
		color = C.Gold,
		size = UDim2.new(0.34, 0, 0, 52),
		position = UDim2.fromScale(0.66, 0),
		parent = header,
	})
	combineAll.Activated:Connect(function()
		Remote.call("CombineAll")
	end)

	local chips = Theme.frame({
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = content,
	})
	Theme.list(chips, Enum.FillDirection.Horizontal, 6)
	for index, rarity in BrainrotData.Rarities do
		local chip = Theme.frame({
			Size = UDim2.new(1 / #BrainrotData.Rarities, -6, 1, 0),
			BackgroundColor3 = if rarity.id == "Secret" then C.Purple else rarity.color,
			LayoutOrder = index,
			Parent = chips,
		})
		Theme.corner(chip, 10)
		Theme.label({ Size = UDim2.new(1, 0, 0.45, 0), Text = rarity.name, Parent = chip })
		rarityChips[rarity.id] = Theme.label({
			Position = UDim2.fromScale(0, 0.45),
			Size = UDim2.new(1, 0, 0.55, 0),
			Text = "",
			Parent = chip,
		})
	end

	infoLabel = Theme.label({
		Position = UDim2.fromOffset(0, 96),
		Size = UDim2.new(1, 0, 0, 22),
		TextColor3 = C.Dark,
		Parent = content,
	})

	local scroller = Theme.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 124),
		Size = UDim2.new(1, 0, 1, -124),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		ScrollBarImageColor3 = C.Dark,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	})
	Theme.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(186, 250),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = scroller,
	})
	Theme.padding(scroller, 6)

	for index, brainrot in BrainrotData.Brainrots do
		table.insert(cards, buildCard(scroller, brainrot, index))
	end
end

function CollectionUI.init()
	panel = Theme.panel("CollectionUI", "🧠 BRAINROT BOOK", Vector2.new(900, 600), C.Pink)
	Theme.onOpen("Collection", function()
		if not built then
			build()
		end
		refresh()
		panel.open()
	end)
	State.Changed:Connect(function()
		if panel.isOpen() then
			refresh()
		end
	end)
end

return CollectionUI
