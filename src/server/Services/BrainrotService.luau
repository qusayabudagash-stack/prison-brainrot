-- Brainrot ownership: giving Brainrots and combining 3 duplicates into a Golden or Diamond one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementService = require(script.Parent.AchievementService)
local AnnouncementService = require(script.Parent.AnnouncementService)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local DataService = require(script.Parent.DataService)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Guard = require(script.Parent.Parent.ServerModules.Guard)
local Types = require(ReplicatedStorage.Modules.Types)

local BrainrotService = {}

-- Adds Brainrots to a player's inventory. Returns (first time finding this Brainrot, first time finding this variant).
function BrainrotService.grant(
	data: Types.PlayerData,
	brainrotId: string,
	variantId: string,
	amount: number
): (boolean, boolean)
	local counts = data.brainrots[brainrotId]
	if not counts then
		counts = { Normal = 0, Golden = 0, Diamond = 0 }
		data.brainrots[brainrotId] = counts
	end
	counts[variantId] = (counts[variantId] or 0) + amount

	local isNew = not data.discovered[brainrotId]
	data.discovered[brainrotId] = true

	local isNewVariant = false
	if variantId ~= "Normal" then
		local found = data.variantsFound[brainrotId]
		if not found then
			found = {}
			data.variantsFound[brainrotId] = found
		end
		isNewVariant = not found[variantId]
		found[variantId] = true
	end

	local order = BrainrotData.getRarity(brainrotId).order
	if order > data.bestRarity then
		data.bestRarity = order
	end
	return isNew, isNewVariant
end

-- Combines as many sets of 3 as possible for one Brainrot. Returns how many Golden and Diamond were made.
local function combineAllOf(data: Types.PlayerData, brainrotId: string): (number, number)
	local counts = data.brainrots[brainrotId]
	if not counts then
		return 0, 0
	end
	local cost = GameConfig.COMBINE_COST
	local golden = counts.Normal // cost
	if golden > 0 then
		counts.Normal -= golden * cost
		BrainrotService.grant(data, brainrotId, "Golden", golden)
	end
	local diamond = counts.Golden // cost
	if diamond > 0 then
		counts.Golden -= diamond * cost
		BrainrotService.grant(data, brainrotId, "Diamond", diamond)
	end
	return golden, diamond
end

function BrainrotService.init()
	Guard.invoke("Combine", function(player, data, brainrotId, variantId)
		if not Guard.isKey(brainrotId, BrainrotData.ById) or not Guard.isKey(variantId, BrainrotData.VariantById) then
			return Guard.fail("That Brainrot doesn't exist.")
		end
		local nextVariant = BrainrotData.nextVariant(variantId)
		if not nextVariant then
			return Guard.fail("Diamond is already the best!")
		end
		local counts = data.brainrots[brainrotId]
		local cost = GameConfig.COMBINE_COST
		if not counts or (counts[variantId] or 0) < cost then
			return Guard.fail(`You need {cost} of these to combine!`)
		end
		counts[variantId] -= cost
		local _, isNewVariant = BrainrotService.grant(data, brainrotId, nextVariant, 1)
		local name = BrainrotData.displayName(brainrotId, nextVariant)
		AnnouncementService.notify(player, `✨ You made a {name}!`, "success")
		DataService.changed(player, "brainrots")
		AchievementService.check(player)
		return { ok = true, brainrotId = brainrotId, variant = nextVariant, isNewVariant = isNewVariant }
	end)

	Guard.invoke("CombineAll", function(player, data)
		local totalGolden, totalDiamond = 0, 0
		for brainrotId in data.brainrots do
			if BrainrotData.ById[brainrotId] then
				local golden, diamond = combineAllOf(data, brainrotId)
				totalGolden += golden
				totalDiamond += diamond
			end
		end
		if totalGolden + totalDiamond == 0 then
			return Guard.fail(`Collect {GameConfig.COMBINE_COST} of the same Brainrot to combine!`)
		end
		AnnouncementService.notify(
			player,
			`✨ Combined into {totalGolden} Golden and {totalDiamond} Diamond Brainrots!`,
			"success"
		)
		DataService.changed(player, "brainrots")
		AchievementService.check(player)
		return { ok = true, golden = totalGolden, diamond = totalDiamond }
	end)
end

return BrainrotService
