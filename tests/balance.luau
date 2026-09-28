--!nocheck
-- Plays the game with a simple bot, using the real formulas and odds, and reports how long progression takes.
-- Not a pass/fail test; run it after changing costs or odds:
--
--   lune run tests/balance.luau build/test.rbxl [hours]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Engine = require("./engine")

local engine = Engine.new(fs.readFile(process.args[1] or "build/test.rbxl"))
local Modules = engine.ReplicatedStorage.Modules
local AchievementData = engine:require(Modules.AchievementData)
local AreaData = engine:require(Modules.AreaData)
local BrainrotData = engine:require(Modules.BrainrotData)
local Format = engine:require(Modules.Format)
local Formulas = engine:require(Modules.Formulas)
local GameConfig = engine:require(Modules.GameConfig)
local RollSystem = engine:require(Modules.RollSystem)
local UpgradeData = engine:require(Modules.UpgradeData)

local HOURS = tonumber(process.args[2]) or 6
local ROLL_SECONDS = GameConfig.ROLL.spinTime + 1 -- animation plus a moment to tap "continue"

local rng = {
	NextNumber = function(_, a, b)
		a = a or 0
		b = b or 1
		return a + (b - a) * math.random()
	end,
	NextInteger = function(_, a, b)
		return math.random(a, b)
	end,
}

local data = {
	coins = GameConfig.STARTING_COINS,
	totalEarned = 0,
	brainrots = { TimCheese = { Normal = 1, Golden = 0, Diamond = 0 } },
	discovered = { TimCheese = true },
	variantsFound = {},
	upgrades = { Income = 0, Luck = 0, Discount = 0, Capacity = 0, Speed = 0 },
	unlockedAreas = { CellBlock1 = true },
	rebirths = 0,
	pity = 0,
	totalRolls = 0,
	bestRarity = 1,
	boostUntil = 0,
	freeBoostReadyAt = 0,
	lastDailyRoll = 0,
	achievements = {},
}

local milestones = {}
local function mark(name, t)
	if not milestones[name] then
		milestones[name] = t
		print(
			`  {Format.time(t)}  {name}  (income {Format.money(Formulas.baseIncome(data))}/s, luck {Format.multiplier(
				Formulas.permanentLuck(data)
			)})`
		)
	end
end

local function grant(id, variant, amount)
	local counts = data.brainrots[id] or { Normal = 0, Golden = 0, Diamond = 0 }
	data.brainrots[id] = counts
	counts[variant] += amount
	data.discovered[id] = true
	if variant ~= "Normal" then
		data.variantsFound[id] = data.variantsFound[id] or {}
		data.variantsFound[id][variant] = true
	end
	data.bestRarity = math.max(data.bestRarity, BrainrotData.getRarity(id).order)
end

local function checkAchievements()
	for _, achievement in AchievementData.Achievements do
		if
			not data.achievements[achievement.id]
			and Formulas.achievementStat(data, achievement.stat) >= achievement.goal
		then
			data.achievements[achievement.id] = true
		end
	end
end

local function combineAll()
	for id, counts in data.brainrots do
		local golden = counts.Normal // 3
		counts.Normal -= golden * 3
		if golden > 0 then
			grant(id, "Golden", golden)
		end
		local diamond = counts.Golden // 3
		counts.Golden -= diamond * 3
		if diamond > 0 then
			grant(id, "Diamond", diamond)
		end
	end
end

print(`Simulating {HOURS} hours of play...`)
local nextRoll = 0
for t = 1, HOURS * 3600 do
	data.coins += Formulas.baseIncome(data)

	if t >= data.freeBoostReadyAt then
		data.boostUntil = t + GameConfig.FREE_BOOST.duration
		data.freeBoostReadyAt = t + GameConfig.FREE_BOOST.cooldown
	end

	local nextArea = nil
	for _, area in AreaData.Areas do
		if not data.unlockedAreas[area.id] then
			nextArea = area
			break
		end
	end
	if nextArea and data.coins >= nextArea.unlockCost then
		data.coins -= nextArea.unlockCost
		data.unlockedAreas[nextArea.id] = true
		mark(`unlocked {nextArea.name}`, t)
	end

	if t % 10 == 0 then
		local savingFor = if nextArea then nextArea.unlockCost else Formulas.rebirthCost(data.rebirths)
		for _, id in { "Capacity", "Income", "Luck", "Discount" } do
			local level = data.upgrades[id]
			if level < UpgradeData.ById[id].maxLevel then
				local cost = UpgradeData.cost(id, level)
				if cost <= data.coins * 0.25 and cost < savingFor * 0.25 then
					data.coins -= cost
					data.upgrades[id] = level + 1
				end
			end
		end
	end
	if t % 60 == 0 then
		combineAll()
	end

	if t >= nextRoll then
		-- Roll at the best block we can afford.
		local chosen = nil
		for i = #AreaData.Areas, 1, -1 do
			local area = AreaData.Areas[i]
			if data.unlockedAreas[area.id] and data.coins >= Formulas.rollCost(data, area) then
				chosen = area
				break
			end
		end
		if chosen then
			data.coins -= Formulas.rollCost(data, chosen)
			local outcome = RollSystem.roll(rng, Formulas.rollLuck(data, t, 1, chosen), chosen, data.pity)
			data.pity = if RollSystem.resetsPity(outcome.rarity) then 0 else data.pity + 1
			data.totalRolls += 1
			grant(outcome.brainrotId, outcome.variant, 1)
			checkAchievements()
			if outcome.rarity ~= "Common" and outcome.rarity ~= "Uncommon" and outcome.rarity ~= "Rare" then
				mark(`first {outcome.rarity}`, t)
			end
			nextRoll = t + ROLL_SECONDS
		end
	end

	if data.coins >= Formulas.rebirthCost(data.rebirths) then
		mark("can afford Rebirth 1", t)
	end
end

print(
	`\nAfter {HOURS} hours: {data.totalRolls} rolls, {Formulas.discoveredCount(data)}/{BrainrotData.Count} discovered, income {Format.money(
		Formulas.baseIncome(data)
	)}/s, coins {Format.money(data.coins)}`
)
process.exit(0)
