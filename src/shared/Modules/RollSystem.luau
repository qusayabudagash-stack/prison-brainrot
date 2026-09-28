-- The chance math behind every roll. The server uses it to roll; the client uses it to show odds.
--
-- weight(rarity) = baseChance * luck ^ luckPower
--   * pity multiplier for Legendary and better
--   then only rarities at or above the block's minimum rarity are kept.
-- Luck is capped at GameConfig.MAX_LUCK, and each rarity's luckPower keeps luck from flattening the odds.

local AreaData = require(script.Parent.AreaData)
local BrainrotData = require(script.Parent.BrainrotData)
local GameConfig = require(script.Parent.GameConfig)

local RollSystem = {}

export type PityInfo = {
	count: number,
	-- Rolls needed for the next pity stage (or the guarantee).
	target: number,
	multiplier: number,
	guaranteed: boolean,
}

export type Odds = {
	rarity: BrainrotData.Rarity,
	chance: number,
}

export type Outcome = {
	rarity: string,
	brainrotId: string,
	variant: string,
}

function RollSystem.pityInfo(pity: number): PityInfo
	local config = GameConfig.PITY
	if pity >= config.guaranteeAt then
		return { count = pity, target = config.guaranteeAt, multiplier = 1, guaranteed = true }
	end
	local multiplier = 1
	local target = config.guaranteeAt
	for _, stage in config.stages do
		if pity >= stage.rolls then
			multiplier = stage.multiplier
		else
			target = stage.rolls
			break
		end
	end
	return { count = pity, target = target, multiplier = multiplier, guaranteed = false }
end

-- True when rolling this rarity resets the pity counter.
function RollSystem.resetsPity(rarityId: string): boolean
	local pityOrder = BrainrotData.RarityById[GameConfig.PITY.minRarity].order
	return BrainrotData.RarityById[rarityId].order >= pityOrder
end

function RollSystem.getWeights(luck: number, area: AreaData.Area, pity: number): { [string]: number }
	luck = math.clamp(luck, 1, GameConfig.MAX_LUCK)
	local minOrder = BrainrotData.RarityById[area.minRarity].order
	local pityOrder = BrainrotData.RarityById[GameConfig.PITY.minRarity].order
	local info = RollSystem.pityInfo(pity)

	local weights = {}
	for _, rarity in BrainrotData.Rarities do
		local weight = 0
		if rarity.order >= minOrder then
			weight = rarity.chance * luck ^ rarity.luckPower
			if rarity.order >= pityOrder then
				weight *= info.multiplier
			elseif info.guaranteed then
				weight = 0
			end
		end
		weights[rarity.id] = weight
	end
	return weights
end

-- Chance of each rarity (0 to 1), in rarity order, for display.
function RollSystem.getOdds(luck: number, area: AreaData.Area, pity: number): { Odds }
	local weights = RollSystem.getWeights(luck, area, pity)
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local odds = {}
	for _, rarity in BrainrotData.Rarities do
		table.insert(odds, { rarity = rarity, chance = if total > 0 then weights[rarity.id] / total else 0 })
	end
	return odds
end

function RollSystem.rollRarity(rng: Random, weights: { [string]: number }): string
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local pick = rng:NextNumber() * total
	local fallback: string? = nil
	for _, rarity in BrainrotData.Rarities do
		local weight = weights[rarity.id] or 0
		if weight > 0 then
			fallback = fallback or rarity.id
			if pick < weight then
				return rarity.id
			end
			pick -= weight
		end
	end
	-- Only reached through floating point rounding; fall back to the most common allowed rarity.
	return fallback or BrainrotData.Rarities[1].id
end

function RollSystem.pickBrainrot(rng: Random, rarityId: string): string
	local pool = BrainrotData.ByRarity[rarityId]
	return pool[rng:NextInteger(1, #pool)].id
end

function RollSystem.variantChances(luck: number): (number, number)
	local boost = math.clamp(luck, 1, GameConfig.MAX_LUCK) ^ GameConfig.VARIANT_LUCK_POWER
	return GameConfig.VARIANT_CHANCES.Golden * boost, GameConfig.VARIANT_CHANCES.Diamond * boost
end

function RollSystem.rollVariant(rng: Random, luck: number): string
	local golden, diamond = RollSystem.variantChances(luck)
	local pick = rng:NextNumber()
	if pick < diamond then
		return "Diamond"
	elseif pick < diamond + golden then
		return "Golden"
	end
	return "Normal"
end

function RollSystem.roll(rng: Random, luck: number, area: AreaData.Area, pity: number): Outcome
	local rarity = RollSystem.rollRarity(rng, RollSystem.getWeights(luck, area, pity))
	return {
		rarity = rarity,
		brainrotId = RollSystem.pickBrainrot(rng, rarity),
		variant = RollSystem.rollVariant(rng, luck),
	}
end

return RollSystem
