-- Brainrot rolling. The server alone decides results: it checks the block, takes the coins (or the daily
-- free roll), rolls with the player's luck and pity, grants the Brainrot and announces rare finds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementService = require(script.Parent.AchievementService)
local AnnouncementService = require(script.Parent.AnnouncementService)
local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotService = require(script.Parent.BrainrotService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local Events = require(ReplicatedStorage.Modules.Events)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Guard = require(script.Parent.Parent.ServerModules.Guard)
local Net = require(ReplicatedStorage.Modules.Net)
local RollSystem = require(ReplicatedStorage.Modules.RollSystem)
local Types = require(ReplicatedStorage.Modules.Types)

local RollService = {}

local rng = Random.new()
local lastRollAt: { [Player]: number } = {}

-- Seconds until the client's roll animation reveals this rarity (used to time announcements).
function RollService.revealDelay(rarityId: string, speed: number): number
	local rarity = BrainrotData.RarityById[rarityId]
	return (GameConfig.ROLL.spinTime + rarity.revealExtra) / speed + 0.5
end

local function announceFind(player: Player, result: Types.RollResult)
	local rarity = BrainrotData.RarityById[result.rarity]
	local name = BrainrotData.displayName(result.brainrotId, result.variant)
	if result.rarity == "Secret" then
		AnnouncementService.announce(
			`🚨 SERVER ANNOUNCEMENT 🚨\n{string.upper(player.DisplayName)} FOUND THE SECRET BRAINROT!`,
			{ color = Color3.fromRGB(255, 80, 255), duration = 10, style = "secret" }
		)
	elseif rarity.announce then
		AnnouncementService.announce(
			`🌟 {player.DisplayName} rolled a {rarity.name} {name}! 🌟`,
			{ color = rarity.color, duration = 6, style = "big" }
		)
	elseif result.variant == "Diamond" and rarity.order >= 4 then
		AnnouncementService.announce(
			`💎 {player.DisplayName} rolled a {name}!`,
			{ color = rarity.color, duration = 4 }
		)
	end
end

-- Rolls once for a player who has already paid. Updates pity, inventory and achievements.
local function performRoll(
	player: Player,
	data: Types.PlayerData,
	area: AreaData.Area,
	free: boolean,
	luckExtra: number?,
	source: string
): Types.RollResult
	local now = os.time()
	local luck = Formulas.rollLuck(data, now, Events.luckMultiplier(), area, luckExtra)
	local outcome = RollSystem.roll(rng, luck, area, data.pity)

	if RollSystem.resetsPity(outcome.rarity) then
		data.pity = 0
	else
		data.pity += 1
	end
	data.totalRolls += 1

	local isNew, isNewVariant = BrainrotService.grant(data, outcome.brainrotId, outcome.variant, 1)
	local speed = Events.rollSpeed()
	local result: Types.RollResult = {
		brainrotId = outcome.brainrotId,
		variant = outcome.variant,
		rarity = outcome.rarity,
		isNew = isNew,
		isNewVariant = isNewVariant,
		pity = data.pity,
		areaId = area.id,
		free = free,
		speed = speed,
		source = source,
	}

	task.delay(RollService.revealDelay(outcome.rarity, speed), function()
		if player.Parent then
			announceFind(player, result)
		end
	end)

	DataService.changed(player, "roll")
	AchievementService.check(player)
	return result
end

-- A free roll the server hands out (e.g. the Prison King event), at the player's best block.
function RollService.grantFreeRoll(player: Player, luckExtra: number, source: string): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local result = performRoll(player, data, Formulas.bestArea(data), true, luckExtra, source)
	Net.event("ServerRoll"):FireClient(player, result)
	return true
end

function RollService.init()
	Players.PlayerRemoving:Connect(function(player)
		lastRollAt[player] = nil
	end)

	Guard.invoke("Roll", function(player, data, areaId, useFreeRoll)
		if not Guard.isKey(areaId, AreaData.ById) then
			return Guard.fail("That machine doesn't exist.")
		end
		local area = AreaData.ById[areaId]
		if not data.unlockedAreas[area.id] then
			return Guard.fail(`Unlock {area.name} first!`)
		end

		local minInterval = GameConfig.ROLL.minInterval / Events.rollSpeed()
		local last = lastRollAt[player]
		if last and os.clock() - last < minInterval then
			return Guard.fail("The machine is still spinning!")
		end

		local free = useFreeRoll == true
		if free then
			local readyAt = Formulas.dailyReadyAt(data)
			if os.time() < readyAt then
				return Guard.fail(`Your free roll is ready in {Format.time(readyAt - os.time())}`)
			end
			data.lastDailyRoll = os.time()
		else
			local cost = Formulas.rollCost(data, area)
			if not EconomyService.trySpend(player, cost) then
				return Guard.fail(`You need {Format.money(cost)} to roll here!`)
			end
		end

		lastRollAt[player] = os.clock()
		return { ok = true, result = performRoll(player, data, area, free, nil, if free then "Daily" else "Machine") }
	end)
end

return RollService
