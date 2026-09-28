-- 🛒 SHOP with three tabs: ⬆️ UPGRADES, 🔓 BLOCKS (unlock prison blocks) and 🛋️ CELL ITEMS (cosmetics).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local CosmeticData = require(ReplicatedStorage.Modules.CosmeticData)
local Format = require(ReplicatedStorage.Modules.Format)
local Remote = require(script.Parent.Parent.Controllers.Remote)
local Sounds = require(script.Parent.Parent.Controllers.Sounds)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)
local UpgradeData = require(ReplicatedStorage.Modules.UpgradeData)

local ShopUI = {}

local C = Theme.Colors

type Row = {
	id: string,
	info: TextLabel,
	button: TextButton,
}

local panel: Theme.Panel
local pages: { [string]: GuiObject } = {}
local tabButtons: { [string]: TextButton } = {}
local upgradeRows: { Row } = {}
local areaRows: { Row } = {}
local cosmeticRows: { Row } = {}
local currentTab = "Upgrades"

local TABS = {
	{ id = "Upgrades", text = "⬆️ UPGRADES", color = C.Blue },
	{ id = "Blocks", text = "🔓 BLOCKS", color = C.Purple },
	{ id = "Cosmetics", text = "🛋️ CELL ITEMS", color = C.Green },
}

local function row(
	parent: Instance,
	order: number,
	emoji: string,
	title: string,
	buttonColor: Color3
): (Frame, TextLabel, TextButton)
	local frame = Theme.frame({
		Size = UDim2.new(1, -12, 0, 76),
		BackgroundColor3 = C.White,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.corner(frame, 14)
	Theme.stroke(frame, Color3.fromRGB(220, 210, 235), 2)
	Theme.label({ Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(60, 60), Text = emoji, Parent = frame })
	Theme.label({
		Position = UDim2.fromOffset(76, 6),
		Size = UDim2.new(1, -290, 0, 32),
		Text = title,
		TextColor3 = C.Dark,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local info = Theme.label({
		Position = UDim2.fromOffset(76, 40),
		Size = UDim2.new(1, -290, 0, 26),
		TextColor3 = Color3.fromRGB(110, 100, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local button = Theme.button({
		text = "BUY",
		color = buttonColor,
		size = UDim2.fromOffset(200, 58),
		position = UDim2.new(1, -208, 0.5, -29),
		parent = frame,
	})
	return frame, info, button
end

local function scroller(parent: Instance): ScrollingFrame
	local frame = Theme.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 1, -66),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		ScrollBarImageColor3 = C.Dark,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = parent,
	})
	Theme.list(frame, Enum.FillDirection.Vertical, 8)
	Theme.padding(frame, 4)
	return frame
end

local function refresh()
	local data = State.data()
	if not data then
		return
	end
	local coins = State.coins()

	for _, upgradeRow in upgradeRows do
		local upgrade = UpgradeData.ById[upgradeRow.id]
		local level = data.upgrades[upgrade.id] or 0
		local current = UpgradeData.formatValue(upgrade.id, UpgradeData.value(upgrade.id, level))
		if level >= upgrade.maxLevel then
			upgradeRow.info.Text = `Lv {level}/{upgrade.maxLevel} • {current}`
			upgradeRow.button.Text = "MAXED ✅"
			Theme.setEnabled(upgradeRow.button, false, C.Blue)
		else
			local nextValue = UpgradeData.formatValue(upgrade.id, UpgradeData.value(upgrade.id, level + 1))
			local cost = UpgradeData.cost(upgrade.id, level)
			upgradeRow.info.Text =
				`Lv {level}/{upgrade.maxLevel} • {current} → <font color="#2FA84F">{nextValue}</font>`
			upgradeRow.button.Text = Format.money(cost)
			Theme.setEnabled(upgradeRow.button, coins >= cost, C.Blue)
		end
	end

	for _, areaRow in areaRows do
		local area = AreaData.ById[areaRow.id]
		local previous = AreaData.Areas[area.order - 1]
		local minRarity = BrainrotData.RarityById[area.minRarity]
		local details = `Roll {Format.money(area.rollCost)} • 🍀 {Format.multiplier(area.luck)} luck`
		if minRarity.order > 1 then
			details ..= ` • {minRarity.name}+ only`
		end
		areaRow.info.Text = details
		if data.unlockedAreas[area.id] then
			areaRow.button.Text = "UNLOCKED ✅"
			Theme.setEnabled(areaRow.button, false, C.Purple)
		elseif previous and not data.unlockedAreas[previous.id] then
			areaRow.button.Text = "🔒 LOCKED"
			Theme.setEnabled(areaRow.button, false, C.Purple)
		else
			areaRow.button.Text = `🔓 {Format.money(area.unlockCost)}`
			Theme.setEnabled(areaRow.button, coins >= area.unlockCost, C.Purple)
		end
	end

	for _, cosmeticRow in cosmeticRows do
		local cosmetic = CosmeticData.ById[cosmeticRow.id]
		local owned = data.cosmetics[cosmetic.id]
		if owned == nil then
			cosmeticRow.button.Text = Format.money(cosmetic.price)
			Theme.setEnabled(cosmeticRow.button, coins >= cosmetic.price, C.Green)
		else
			cosmeticRow.button.Text = if owned then "👁️ SHOWN" else "🙈 HIDDEN"
			Theme.setEnabled(cosmeticRow.button, true, if owned then C.Green else C.Gray)
		end
	end
end

local function showTab(tabId: string)
	currentTab = tabId
	for id, page in pages do
		page.Visible = id == tabId
	end
	for id, button in tabButtons do
		local tab
		for _, candidate in TABS do
			if candidate.id == id then
				tab = candidate
			end
		end
		if tab then
			button.BackgroundColor3 = if id == tabId then tab.color else C.Gray
		end
	end
	refresh()
end

function ShopUI.init()
	panel = Theme.panel("ShopUI", "🛒 PRISON SHOP", Vector2.new(820, 580), C.Green)
	local content = panel.content

	local tabBar = Theme.frame({ Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = content })
	Theme.list(tabBar, Enum.FillDirection.Horizontal, 10)
	for index, tab in TABS do
		local button = Theme.button({
			text = tab.text,
			color = tab.color,
			size = UDim2.new(1 / #TABS, -10, 1, 0),
			layoutOrder = index,
			parent = tabBar,
		})
		tabButtons[tab.id] = button
		button.Activated:Connect(function()
			showTab(tab.id)
		end)
	end

	local upgradesPage = scroller(content)
	pages.Upgrades = upgradesPage
	for index, upgrade in UpgradeData.Upgrades do
		local _, info, button = row(
			upgradesPage,
			index,
			upgrade.emoji,
			`{upgrade.name}  <font size="18" color="#8C82A8">{upgrade.description}</font>`,
			C.Blue
		)
		table.insert(upgradeRows, { id = upgrade.id, info = info, button = button })
		button.Activated:Connect(function()
			if button.Active and Remote.call("BuyUpgrade", upgrade.id).ok then
				Sounds.play("CoinReward")
				Theme.pop(button, 1.2)
			end
		end)
	end

	local blocksPage = scroller(content)
	pages.Blocks = blocksPage
	for index, area in AreaData.Areas do
		local _, info, button = row(blocksPage, index, area.emoji, area.name, C.Purple)
		table.insert(areaRows, { id = area.id, info = info, button = button })
		button.Activated:Connect(function()
			if button.Active and Remote.call("UnlockArea", area.id).ok then
				Theme.pop(button, 1.3)
			end
		end)
	end

	local cosmeticsPage = scroller(content)
	pages.Cosmetics = cosmeticsPage
	for index, cosmetic in CosmeticData.Cosmetics do
		local _, info, button = row(cosmeticsPage, index, cosmetic.emoji, cosmetic.name, C.Green)
		info.Text = cosmetic.description
		table.insert(cosmeticRows, { id = cosmetic.id, info = info, button = button })
		button.Activated:Connect(function()
			local data = State.data()
			if not data or not button.Active then
				return
			end
			if data.cosmetics[cosmetic.id] == nil then
				Remote.call("BuyCosmetic", cosmetic.id)
			else
				Remote.call("ToggleCosmetic", cosmetic.id)
			end
		end)
	end

	Theme.onOpen("Shop", function(tabId: string?)
		panel.open()
		showTab(tabId or currentTab)
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

return ShopUI
