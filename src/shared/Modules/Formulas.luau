-- Derived player numbers: income, capacity, luck, costs. Shared so the HUD shows exactly what the server uses.

local AchievementData = require(script.Parent.AchievementData)
local AreaData = require(script.Parent.AreaData)
local BrainrotData = require(script.Parent.BrainrotData)
local GameConfig = require(script.Parent.GameConfig)
local Types = require(script.Parent.Types)
local UpgradeData = require(script.Parent.UpgradeData)

type PlayerData = Types.PlayerData

export type Stack = {
	id: string,
	variant: string,
	income: number,
	count: number,
}

export type LuckBreakdown = {
	upgrade: number,
	rebirth: number,
	achievements: number,
	variants: number,
	boost: number,
	event: number,
	total: number,
}

-- Each Golden / Diamond variant you've ever found adds this much permanent luck.
local GOLDEN_FOUND_LUCK = 0.01
local DIAMOND_FOUND_LUCK = 0.03

local Formulas = {}

function Formulas.level(data: PlayerData, upgradeId: string): number
	return data.upgrades[upgradeId] or 0
end

function Formulas.upgradeValue(data: PlayerData, upgradeId: string): number
	return UpgradeData.value(upgradeId, Formulas.level(data, upgradeId))
end

function Formulas.capacity(data: PlayerData): number
	return GameConfig.BASE_CAPACITY + Formulas.upgradeValue(data, "Capacity")
end

function Formulas.walkSpeed(data: PlayerData): number
	return Formulas.upgradeValue(data, "Speed")
end

function Formulas.count(data: PlayerData, brainrotId: string, variantId: string): number
	local counts = data.brainrots[brainrotId]
	return if counts then counts[variantId] or 0 else 0
end

-- Every owned Brainrot stack, best income first.
function Formulas.stacks(data: PlayerData): { Stack }
	local list = {}
	for id, counts in data.brainrots do
		if BrainrotData.ById[id] then
			for _, variant in BrainrotData.Variants do
				local count = counts[variant.id] or 0
				if count > 0 then
					table.insert(list, {
						id = id,
						variant = variant.id,
						income = BrainrotData.income(id, variant.id),
						count = count,
					})
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.income ~= b.income then
			return a.income > b.income
		elseif a.id ~= b.id then
			return a.id < b.id
		end
		return a.variant < b.variant
	end)
	return list
end

-- The Brainrots currently earning coins: your best ones, up to your capacity.
function Formulas.working(data: PlayerData): { Stack }
	local slots = Formulas.capacity(data)
	local result = {}
	for _, stack in Formulas.stacks(data) do
		if slots <= 0 then
			break
		end
		local count = math.min(stack.count, slots)
		table.insert(result, { id = stack.id, variant = stack.variant, income = stack.income, count = count })
		slots -= count
	end
	return result
end

function Formulas.totalOwned(data: PlayerData): number
	local total = 0
	for id, counts in data.brainrots do
		if BrainrotData.ById[id] then
			for _, count in counts do
				total += count
			end
		end
	end
	return total
end

-- Coins per second before server events.
function Formulas.baseIncome(data: PlayerData): number
	local sum = 0
	for _, stack in Formulas.working(data) do
		sum += stack.income * stack.count
	end
	return sum * Formulas.upgradeValue(data, "Income")
end

function Formulas.discoveredCount(data: PlayerData): number
	local count = 0
	for id, found in data.discovered do
		if found and BrainrotData.ById[id] then
			count += 1
		end
	end
	return count
end

function Formulas.variantFoundCount(data: PlayerData, variantId: string): number
	local count = 0
	for id, variants in data.variantsFound do
		if BrainrotData.ById[id] and variants[variantId] then
			count += 1
		end
	end
	return count
end

function Formulas.unlockedCount(data: PlayerData): number
	local count = 0
	for id, unlocked in data.unlockedAreas do
		if unlocked and AreaData.ById[id] then
			count += 1
		end
	end
	return count
end

function Formulas.bestArea(data: PlayerData): AreaData.Area
	local best = AreaData.Areas[1]
	for _, area in AreaData.Areas do
		if data.unlockedAreas[area.id] and area.order > best.order then
			best = area
		end
	end
	return best
end

function Formulas.achievementStat(data: PlayerData, stat: string): number
	if stat == "rolls" then
		return data.totalRolls
	elseif stat == "discovered" then
		return Formulas.discoveredCount(data)
	elseif stat == "bestRarity" then
		return data.bestRarity
	elseif stat == "golden" then
		return Formulas.variantFoundCount(data, "Golden")
	elseif stat == "diamond" then
		return Formulas.variantFoundCount(data, "Diamond")
	elseif stat == "areas" then
		return Formulas.unlockedCount(data)
	end
	return 0
end

function Formulas.achievementLuck(data: PlayerData): number
	local sum = 0
	for id, earned in data.achievements do
		local achievement = AchievementData.ById[id]
		if earned and achievement then
			sum += achievement.luck
		end
	end
	return sum
end

function Formulas.variantLuck(data: PlayerData): number
	return Formulas.variantFoundCount(data, "Golden") * GOLDEN_FOUND_LUCK
		+ Formulas.variantFoundCount(data, "Diamond") * DIAMOND_FOUND_LUCK
end

function Formulas.boostActive(data: PlayerData, now: number): boolean
	return data.boostUntil > now
end

function Formulas.luckBreakdown(data: PlayerData, now: number, eventLuck: number): LuckBreakdown
	local upgrade = Formulas.upgradeValue(data, "Luck")
	local rebirth = data.rebirths * GameConfig.REBIRTH.luckPerRebirth
	local achievements = Formulas.achievementLuck(data)
	local variants = Formulas.variantLuck(data)
	local boost = if Formulas.boostActive(data, now) then GameConfig.FREE_BOOST.multiplier else 1
	local total = upgrade * (1 + rebirth + achievements + variants) * boost * eventLuck
	return {
		upgrade = upgrade,
		rebirth = rebirth,
		achievements = achievements,
		variants = variants,
		boost = boost,
		event = eventLuck,
		total = math.min(total, GameConfig.MAX_LUCK),
	}
end

-- Luck that never expires: upgrades, rebirths, achievements and variants found (no boosts or events).
function Formulas.permanentLuck(data: PlayerData): number
	local breakdown = Formulas.luckBreakdown(data, 0, 1)
	local permanent = breakdown.upgrade * (1 + breakdown.rebirth + breakdown.achievements + breakdown.variants)
	return math.min(permanent, GameConfig.MAX_LUCK)
end

-- The luck shown on the HUD: permanent luck with temporary boosts and events.
function Formulas.personalLuck(data: PlayerData, now: number, eventLuck: number): number
	return Formulas.luckBreakdown(data, now, eventLuck).total
end

-- The luck used for a roll at a specific block's machine.
function Formulas.rollLuck(
	data: PlayerData,
	now: number,
	eventLuck: number,
	area: AreaData.Area,
	extra: number?
): number
	local luck = Formulas.personalLuck(data, now, eventLuck) * area.luck * (extra or 1)
	return math.min(luck, GameConfig.MAX_LUCK)
end

function Formulas.rollCost(data: PlayerData, area: AreaData.Area): number
	return math.floor(area.rollCost * (1 - Formulas.upgradeValue(data, "Discount")))
end

function Formulas.rebirthCost(rebirths: number): number
	return math.floor(GameConfig.REBIRTH.baseCost * GameConfig.REBIRTH.costGrowth ^ rebirths)
end

function Formulas.dailyReadyAt(data: PlayerData): number
	return data.lastDailyRoll + GameConfig.DAILY_ROLL_COOLDOWN
end

return Formulas
