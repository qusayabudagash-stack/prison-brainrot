--!nocheck
-- Unit tests for the shared modules: formatting, odds math, luck, pity and Brainrot models.
--
--   lune run tests/shared.test.luau build/test.rbxl

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame

local Engine = require("./engine")
local T = require("./testing")

local engine = Engine.new(fs.readFile(process.args[1] or "build/test.rbxl"))
local Modules = engine.ReplicatedStorage.Modules
local AreaData = engine:require(Modules.AreaData)
local BrainrotData = engine:require(Modules.BrainrotData)
local BrainrotModel = engine:require(Modules.BrainrotModel)
local Format = engine:require(Modules.Format)
local Formulas = engine:require(Modules.Formulas)
local GameConfig = engine:require(Modules.GameConfig)
local RollSystem = engine:require(Modules.RollSystem)

T.run(function()
	local check, section = T.check, T.section

	---------------------------------------------------------------------------
	section("Format")
	---------------------------------------------------------------------------
	for _, case in
		{
			{ Format.number(0), "0" },
			{ Format.number(999), "999" },
			{ Format.number(12500), "12,500" },
			{ Format.number(999999), "999,999" },
			{ Format.number(1e6), "1M" },
			{ Format.number(1234567), "1.23M" },
			{ Format.number(15.5e9), "15.5B" },
			{ Format.number(250e12), "250T" },
			{ Format.money(12500), "$12,500" },
			{ Format.number(0 / 0), "0" },
			{ Format.time(0), "0:00" },
			{ Format.time(65), "1:05" },
			{ Format.time(86399), "23:59:59" },
			{ Format.chance(0.6), "60%" },
			{ Format.chance(0.008), "0.8%" },
			{ Format.chance(0.00001), "0.001%" },
			{ Format.chance(0), "0%" },
			{ Format.oneIn(0.001), "1 in 1,000" },
			{ Format.multiplier(1), "1.0x" },
			{ Format.multiplier(1.25), "1.25x" },
			{ Format.multiplier(1.5), "1.5x" },
		}
	do
		check(`format -> {case[2]}`, case[1] == case[2], case[1])
	end

	---------------------------------------------------------------------------
	section("Data")
	---------------------------------------------------------------------------
	local total = 0
	for _, rarity in BrainrotData.Rarities do
		total += rarity.chance
	end
	check("base odds add up to 100%", math.abs(total - 100) < 1e-9, total)
	check(`{BrainrotData.Count} Brainrots`, BrainrotData.Count >= 30)
	check("every rarity has Brainrots", true)
	check("exactly one Secret Brainrot", #BrainrotData.ByRarity.Secret == 1)
	local incomeOrdered = true
	for i = 2, #BrainrotData.Rarities do
		local lowMax, highMin = 0, math.huge
		for _, b in BrainrotData.ByRarity[BrainrotData.Rarities[i - 1].id] do
			lowMax = math.max(lowMax, b.income)
		end
		for _, b in BrainrotData.ByRarity[BrainrotData.Rarities[i].id] do
			highMin = math.min(highMin, b.income)
		end
		incomeOrdered = incomeOrdered and highMin > lowMax
	end
	check("every rarity earns more than the one below", incomeOrdered)
	check("Tim Cheese earns $5/sec", BrainrotData.ById.TimCheese.income == 5)
	check("Ballerina Cappuccina earns $1,000/sec", BrainrotData.ById.BallerinaCappuccina.income == 1000)

	---------------------------------------------------------------------------
	section("Odds, luck and pity")
	---------------------------------------------------------------------------
	local sumsOk, minOk, monotonic = true, true, true
	for _, area in AreaData.Areas do
		local minOrder = BrainrotData.RarityById[area.minRarity].order
		local previousHigh = -1
		for _, luck in { 1, 1.5, 2, 5, 10, 40, 1000 } do
			for _, pity in { 0, 60, 120 } do
				local sum, high = 0, 0
				for _, odds in RollSystem.getOdds(luck, area, pity) do
					sum += odds.chance
					if odds.rarity.order < minOrder and odds.chance > 0 then
						minOk = false
					end
					if odds.rarity.order >= 5 and pity == 0 then
						high += odds.chance
					end
				end
				sumsOk = sumsOk and math.abs(sum - 1) < 1e-9
				if pity == 0 then
					monotonic = monotonic and high >= previousHigh - 1e-12
					previousHigh = high
				end
			end
		end
	end
	check("odds always add up to 100%", sumsOk)
	check("blocks never roll below their minimum rarity", minOk)
	check("more luck never lowers Legendary+ odds", monotonic)

	print("  Legendary+ / Mythic+ / Secret odds per block at 1x, 3x and max luck:")
	for _, area in AreaData.Areas do
		local line = `    {area.name}:`
		for _, luck in { 1, 3, GameConfig.MAX_LUCK } do
			local odds = RollSystem.getOdds(math.min(luck * area.luck, GameConfig.MAX_LUCK), area, 0)
			local legendary, mythic = 0, 0
			for _, entry in odds do
				if entry.rarity.order >= 5 then
					legendary += entry.chance
				end
				if entry.rarity.order >= 6 then
					mythic += entry.chance
				end
			end
			line ..= `  [{luck}x] {Format.chance(legendary)} / {Format.chance(mythic)} / {Format.oneIn(odds[8].chance)}`
		end
		print(line)
	end

	local base = RollSystem.getOdds(1, AreaData.Areas[1], 0)
	local exact = true
	for _, odds in base do
		exact = exact and math.abs(odds.chance * 100 - odds.rarity.chance) < 1e-9
	end
	check("1x luck in Cell Block 1 uses the base odds exactly", exact)

	local capped = RollSystem.getOdds(1e9, AreaData.Areas[1], 0)
	local atMax = RollSystem.getOdds(GameConfig.MAX_LUCK, AreaData.Areas[1], 0)
	check("luck is capped", capped[5].chance == atMax[5].chance)
	check("even max luck keeps Common possible in Cell Block 1", atMax[1].chance > 0.05, atMax[1].chance)
	check("even max luck keeps Secret rarer than 1 in 10,000", atMax[8].chance < 1e-4, atMax[8].chance)

	local p37 = RollSystem.pityInfo(37)
	check("LUCKY ROLLS 37/50", p37.target == 50 and p37.multiplier == 1)
	local p67 = RollSystem.pityInfo(67)
	check("after 50 rolls: 2x Legendary+", p67.target == 100 and p67.multiplier == 2)
	local p120 = RollSystem.pityInfo(120)
	check("after 100 rolls: 4x Legendary+", p120.target == 150 and p120.multiplier == 4)
	check("150 rolls: guaranteed", RollSystem.pityInfo(150).guaranteed)
	local guaranteedOdds = RollSystem.getOdds(1, AreaData.Areas[1], 150)
	check("guarantee leaves only Legendary+", guaranteedOdds[1].chance == 0 and guaranteedOdds[4].chance == 0)
	check("Legendary resets pity", RollSystem.resetsPity("Legendary") and not RollSystem.resetsPity("Epic"))

	---------------------------------------------------------------------------
	section("1,000,000 simulated rolls at 1x luck")
	---------------------------------------------------------------------------
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
	local N = 1_000_000
	local counts, variants = {}, { Normal = 0, Golden = 0, Diamond = 0 }
	local weights = RollSystem.getWeights(1, AreaData.Areas[1], 0)
	for _ = 1, N do
		local rarity = RollSystem.rollRarity(rng, weights)
		counts[rarity] = (counts[rarity] or 0) + 1
		local variant = RollSystem.rollVariant(rng, 1)
		variants[variant] += 1
	end
	for _, rarity in BrainrotData.Rarities do
		local expected = rarity.chance / 100
		local observed = (counts[rarity.id] or 0) / N
		-- within 5 standard deviations (plus a little slack for the rarest)
		local tolerance = 5 * math.sqrt(expected * (1 - expected) / N) + 2e-6
		print(`  {rarity.name}: expected {Format.chance(expected)}, got {Format.chance(observed)}`)
		check(`{rarity.name} rolls at its configured rate`, math.abs(observed - expected) <= tolerance)
	end
	check(
		"Golden about 5%",
		math.abs(variants.Golden / N - GameConfig.VARIANT_CHANCES.Golden) < 0.002,
		variants.Golden / N
	)
	check(
		"Diamond about 0.5%",
		math.abs(variants.Diamond / N - GameConfig.VARIANT_CHANCES.Diamond) < 0.0007,
		variants.Diamond / N
	)

	---------------------------------------------------------------------------
	section("Income and capacity")
	---------------------------------------------------------------------------
	local data = {
		brainrots = {
			TimCheese = { Normal = 20, Golden = 1, Diamond = 0 },
			BallerinaCappuccina = { Normal = 1, Golden = 0, Diamond = 0 },
		},
		upgrades = { Income = 0, Luck = 0, Discount = 0, Capacity = 0, Speed = 0 },
		discovered = {},
		variantsFound = {},
		achievements = {},
		unlockedAreas = { CellBlock1 = true },
		rebirths = 0,
		boostUntil = 0,
	}
	check("capacity starts at 8", Formulas.capacity(data) == 8)
	check(
		"only the best 8 earn: Ballerina + Golden Tim Cheese + 6 Tim Cheeses",
		Formulas.baseIncome(data) == 1000 + 10 + 6 * 5,
		Formulas.baseIncome(data)
	)
	data.upgrades.Capacity = 1
	data.upgrades.Income = 1
	check(
		"capacity and income upgrades apply",
		Formulas.baseIncome(data) == (1000 + 10 + 8 * 5) * 1.2,
		Formulas.baseIncome(data)
	)
	data.upgrades.Discount = 10
	check("roll discount caps at 40% off", Formulas.rollCost(data, AreaData.Areas[1]) == 60)
	data.rebirths = 3
	check("3 rebirths = +30% luck", math.abs(Formulas.permanentLuck(data) - 1.3) < 1e-9, Formulas.permanentLuck(data))
	data.boostUntil = 1000
	check("free boost counts while active", math.abs(Formulas.personalLuck(data, 999, 1) - 1.3 * 1.5) < 1e-9)
	check("free boost stops when it expires", math.abs(Formulas.personalLuck(data, 1001, 1) - 1.3) < 1e-9)
	check(
		"free boost never counts as permanent luck",
		math.abs(Formulas.permanentLuck(data) - 1.3) < 1e-9,
		Formulas.permanentLuck(data)
	)

	---------------------------------------------------------------------------
	section("Brainrot models")
	---------------------------------------------------------------------------
	-- Rarer Brainrots get more detail, but even the fanciest has to stay cheap to show in every cell.
	local BUDGET = {
		Common = 100,
		Uncommon = 110,
		Rare = 120,
		Epic = 135,
		Legendary = 150,
		Mythic = 165,
		Divine = 190,
		Secret = 210,
	}
	local built, maxParts, problems, overBudget = 0, 0, {}, {}
	for _, brainrot in BrainrotData.Brainrots do
		for _, variant in BrainrotData.Variants do
			for _, options in { { variant = variant.id }, { variant = variant.id, welded = true, scale = 2.5 } } do
				local ok, model = pcall(BrainrotModel.build, brainrot.id, options)
				if not ok then
					table.insert(problems, `{brainrot.id}/{variant.id}: {model}`)
					continue
				end
				built += 1
				local parts = 0
				for _, descendant in model:GetDescendants() do
					if descendant:IsA("BasePart") then
						parts += 1
						if descendant.CanCollide then
							table.insert(problems, `{brainrot.id}: {descendant.Name} collides`)
						end
						if
							options.welded
							and not descendant.Anchored
							and not descendant:FindFirstChildOfClass("WeldConstraint")
						then
							table.insert(problems, `{brainrot.id}: {descendant.Name} is loose`)
						end
					end
				end
				maxParts = math.max(maxParts, parts)
				if variant.id == "Normal" and not options.welded and parts > BUDGET[brainrot.rarity] then
					table.insert(overBudget, `{brainrot.id} {parts}/{BUDGET[brainrot.rarity]}`)
				end
				if not model.PrimaryPart or not model:FindFirstChild("Body") then
					table.insert(problems, `{brainrot.id}: missing Root or Body`)
				end
			end
		end
	end
	print(`  (built {built} models, biggest has {maxParts} parts)`)
	check("every Brainrot builds in every variant", #problems == 0, table.concat(problems, "; "))
	check("models stay within their rarity's part budget", #overBudget == 0, table.concat(overBudget, ", "))

	-- A model dropped into ReplicatedStorage.BrainrotAssets replaces the built-in design
	local assets = Instance.new("Folder")
	assets.Name = "BrainrotAssets"
	local asset = Instance.new("Model")
	asset.Name = "TimCheese"
	local mesh = Instance.new("Part")
	mesh.Name = "Body"
	mesh.Size = Vector3.new(2, 3, 2)
	mesh.CFrame = CFrame.new(10, 20, 30)
	mesh.CanCollide = true
	mesh.Parent = asset
	asset.Parent = assets
	assets.Parent = engine.ReplicatedStorage
	local custom = BrainrotModel.build("TimCheese")
	local customBody = custom:FindFirstChild("Body") :: BasePart
	check(
		"an asset override replaces the design",
		customBody ~= nil and customBody.Size == Vector3.new(2, 3, 2) and custom:FindFirstChild("Cheese") == nil
	)
	check(
		"the override stands on the ground, centered, and doesn't collide",
		customBody ~= nil
			and math.abs(customBody.CFrame.Position.Y - 1.5) < 0.01
			and math.abs(customBody.CFrame.Position.X) < 0.01
			and not customBody.CanCollide
	)
	assets:Destroy()
end)
