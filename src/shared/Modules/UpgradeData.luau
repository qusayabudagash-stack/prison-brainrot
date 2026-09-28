-- Coin upgrades. Each one has a level that starts at 0; cost grows each level.

export type Upgrade = {
	id: string,
	name: string,
	emoji: string,
	description: string,
	maxLevel: number,
	baseCost: number,
	costGrowth: number,
	-- Explicit value per level (index 1 = level 0). Used instead of `perLevel` when present.
	values: { number }?,
	base: number,
	perLevel: number,
	-- How the value is shown in the shop.
	format: string,
}

local UpgradeData = {}

UpgradeData.Upgrades = {
	{
		id = "Income",
		name = "Income Multiplier",
		emoji = "💰",
		description = "Every Brainrot earns more Coins.",
		maxLevel = 25,
		baseCost = 1_000,
		costGrowth = 2.3,
		base = 1,
		perLevel = 0.2,
		format = "multiplier",
	},
	{
		id = "Luck",
		name = "Luck",
		emoji = "🍀",
		description = "Rare Brainrots show up more often.",
		maxLevel = 10,
		baseCost = 2_500,
		costGrowth = 3.5,
		values = { 1, 1.1, 1.2, 1.35, 1.5, 1.7, 1.9, 2.15, 2.4, 2.7, 3 },
		base = 1,
		perLevel = 0,
		format = "multiplier",
	},
	{
		id = "Discount",
		name = "Roll Discount",
		emoji = "🎰",
		description = "Rolls cost less at every machine.",
		maxLevel = 10,
		baseCost = 1_500,
		costGrowth = 2.6,
		base = 0,
		perLevel = 0.04,
		format = "percentOff",
	},
	{
		id = "Capacity",
		name = "Brainrot Capacity",
		emoji = "🧠",
		description = "More of your Brainrots earn Coins at once.",
		maxLevel = 12,
		baseCost = 2_000,
		costGrowth = 3.2,
		base = 0,
		perLevel = 2,
		format = "slots",
	},
	{
		id = "Speed",
		name = "Movement Speed",
		emoji = "🏃",
		description = "Run around the prison faster.",
		maxLevel = 8,
		baseCost = 200,
		costGrowth = 2.2,
		base = 16,
		perLevel = 2,
		format = "speed",
	},
} :: { Upgrade }

UpgradeData.ById = {} :: { [string]: Upgrade }
for _, upgrade in UpgradeData.Upgrades do
	UpgradeData.ById[upgrade.id] = upgrade
end

function UpgradeData.value(upgradeId: string, level: number): number
	local upgrade = UpgradeData.ById[upgradeId]
	level = math.clamp(level, 0, upgrade.maxLevel)
	if upgrade.values then
		return upgrade.values[level + 1]
	end
	return upgrade.base + upgrade.perLevel * level
end

-- Cost to go from `level` to `level + 1`.
function UpgradeData.cost(upgradeId: string, level: number): number
	local upgrade = UpgradeData.ById[upgradeId]
	return math.floor(upgrade.baseCost * upgrade.costGrowth ^ level)
end

function UpgradeData.formatValue(upgradeId: string, value: number): string
	local upgrade = UpgradeData.ById[upgradeId]
	if upgrade.format == "multiplier" then
		local text = string.format("%.2f", value)
		text = string.gsub(text, "0$", "")
		return text .. "x"
	elseif upgrade.format == "percentOff" then
		return `{math.floor(value * 100 + 0.5)}% off`
	elseif upgrade.format == "slots" then
		return `+{value} slots`
	elseif upgrade.format == "speed" then
		return `{value} speed`
	end
	return tostring(value)
end

return UpgradeData
