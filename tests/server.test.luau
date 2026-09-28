--!nocheck
-- End-to-end test of the server: loads the place Rojo built, runs Main.server.luau, then plays the game
-- through the same remotes a real client uses.
--
--   rojo build -o build/test.rbxl && lune run tests/server.test.luau build/test.rbxl

local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")

local Engine = require("./engine")
local T = require("./testing")

local engine = Engine.new(fs.readFile(process.args[1] or "build/test.rbxl"), { studio = false })
local game = engine.game
local workspace = engine.workspace
local Modules = engine.ReplicatedStorage.Modules
local Services = game:GetService("ServerScriptService").Services
local ServerModules = game:GetService("ServerScriptService").ServerModules

-- Make the game fast enough to test: no roll cooldowns, short events, quick lock waits.
local GameConfig = engine:require(Modules.GameConfig)
GameConfig.ROLL.minInterval = 0
GameConfig.RATE_LIMITS.default = { count = 100000, per = 1 }
GameConfig.RATE_LIMITS.Roll = { count = 100000, per = 1 }
GameConfig.EVENTS.firstDelay = 100000
for _, event in GameConfig.EVENTS.list do
	event.duration = 1.5
end
GameConfig.DATA.autosaveInterval = 100000
GameConfig.DATA.lockWaitAttempts = 2
GameConfig.DATA.lockWaitSeconds = 0.2
GameConfig.DATA.retries = 2
GameConfig.LEADERBOARD.refreshInterval = 0.5

T.run(function()
	engine:run(game:GetService("ServerScriptService").Main)
	task.wait(0.3)

	local AreaData = engine:require(Modules.AreaData)
	local BrainrotData = engine:require(Modules.BrainrotData)
	local CosmeticData = engine:require(Modules.CosmeticData)
	local Events = engine:require(Modules.Events)
	local Formulas = engine:require(Modules.Formulas)
	local UpgradeData = engine:require(Modules.UpgradeData)
	local BrainrotService = engine:require(Services.BrainrotService)
	local DataService = engine:require(Services.DataService)
	local EconomyService = engine:require(Services.EconomyService)
	local EventService = engine:require(Services.EventService)
	local RateLimiter = engine:require(ServerModules.RateLimiter)

	local STORE = GameConfig.DATA.storeName
	local check, section = T.check, T.section

	local function join(userId, name)
		local player = engine:addPlayer(userId, name)
		Engine.waitUntil(function()
			return DataService.get(player) ~= nil
		end, 10, `{name}'s data`)
		return player, DataService.get(player)
	end

	local function roll(player, areaId, free)
		return engine:invoke(player, "Roll", areaId, free)
	end

	local function cellOf(player)
		for _, cell in workspace.CellBlocks:GetChildren() do
			if cell:GetAttribute("OwnerId") == player.UserId then
				return cell
			end
		end
		return nil
	end

	---------------------------------------------------------------------------
	section("Map")
	---------------------------------------------------------------------------
	check("Lobby (Cell Block 1) built", workspace:FindFirstChild("Lobby") ~= nil)
	check("5 more prison blocks", #workspace.Prison:GetChildren() == 5, #workspace.Prison:GetChildren())
	check("6 roll machines", #workspace.RollMachines:GetChildren() == 6)
	check("10 player cells", #workspace.CellBlocks:GetChildren() == GameConfig.CELL_COUNT)
	local boards = 0
	for _, child in workspace.Leaderboards:GetChildren() do
		if string.sub(child.Name, 1, 6) == "Board_" then
			boards += 1
		end
	end
	check("4 physical leaderboards", boards == 4, boards)

	local parts, actions = 0, {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("BasePart") then
			parts += 1
		elseif descendant:IsA("ProximityPrompt") then
			local action = descendant:GetAttribute("Action")
			if action then
				actions[action] = (actions[action] or 0) + 1
			end
		end
	end
	print(`  (map has {parts} parts)`)
	-- A furnished prison (cells, props, six machines) is a few thousand anchored parts; keep it well under
	-- what mobile devices handle comfortably.
	check("map stays within its part budget (< 7000 parts)", parts < 7000, parts)
	check("a Roll prompt on every machine", actions.Roll == 6, actions.Roll)
	check("an Unlock prompt on every gate", actions.Unlock == 5, actions.Unlock)
	for _, action in { "Shop", "Upgrades", "Book", "Rebirth", "FreeBoost", "DailyRoll" } do
		check(`{action} station prompt`, actions[action] == 1, actions[action])
	end
	check(
		"remotes created",
		#engine.ReplicatedStorage.Remotes:GetChildren() == 15,
		#engine.ReplicatedStorage.Remotes:GetChildren()
	)

	---------------------------------------------------------------------------
	section("New player")
	---------------------------------------------------------------------------
	local alice, data = join(1001, "Alice")
	check("starts with $100", data.coins == 100, data.coins)
	check("starts with one Potato Prisoner", data.brainrots.PotatoPrisoner.Normal == 1)
	check("starts in Cell Block 1", data.unlockedAreas.CellBlock1 == true and Formulas.unlockedCount(data) == 1)
	check("tutorial not done yet", data.tutorialDone == false)
	task.wait(0.2)
	check("state snapshot sent to the client", #engine:eventsNamed("State", alice) > 0)
	local snapshot = engine:eventsNamed("State", alice)[1].args[1]
	check("snapshot has no server-only meta", snapshot.data.meta == nil)
	check("leaderstats created", alice:FindFirstChild("leaderstats") ~= nil)
	check("Coins attribute set", alice:GetAttribute("Coins") == 100, alice:GetAttribute("Coins"))
	check("income is +$5/sec from the Potato", alice:GetAttribute("Income") == 5, alice:GetAttribute("Income"))
	local cell = cellOf(alice)
	check("got a cell", cell ~= nil)
	if cell then
		local label = cell:FindFirstChild("OwnerText", true)
		check("cell shows the player's name", label and string.find(label.Text, "ALICE") ~= nil, label and label.Text)
		check("cell shows the Potato on a pedestal", #cell.Displays:GetChildren() == 1)
	end
	engine:fireServer(alice, "CompleteTutorial")
	task.wait(0.1)
	check("tutorial completion saved", data.tutorialDone == true)

	---------------------------------------------------------------------------
	section("Income")
	---------------------------------------------------------------------------
	local before = data.coins
	task.wait(2.1)
	check("earns coins every second", data.coins >= before + 10, data.coins - before)
	check("total earned tracked", data.totalEarned >= 10)

	---------------------------------------------------------------------------
	section("Rolling")
	---------------------------------------------------------------------------
	data.coins = 100
	local response = roll(alice, "CellBlock1", false)
	check("roll succeeds", response.ok == true, response.message)
	check("roll costs $100", data.coins == 0, data.coins)
	local result = response.result
	check("result is a real Brainrot", result and BrainrotData.ById[result.brainrotId] ~= nil)
	check("result rarity matches the Brainrot", result and BrainrotData.ById[result.brainrotId].rarity == result.rarity)
	check("result variant valid", result and BrainrotData.VariantById[result.variant] ~= nil)
	check("Brainrot added to inventory", Formulas.count(data, result.brainrotId, result.variant) >= 1)
	check("roll counted", data.totalRolls == 1)
	check("discovered in the book", data.discovered[result.brainrotId] == true)

	local broke = roll(alice, "CellBlock1", false)
	check(
		"can't roll without coins",
		broke.ok == false and string.find(broke.message, "You need") ~= nil,
		broke.message
	)
	check("failed roll takes nothing", data.coins < 100)

	---------------------------------------------------------------------------
	section("Request validation")
	---------------------------------------------------------------------------
	EconomyService.add(alice, 1e6)
	for label, args in
		{
			number = { 123 },
			missing = {},
			unknown = { "Nope" },
			table = { {} },
			["locked block"] = { "MaxSecurity" },
			["huge string"] = { string.rep("A", 5000) },
		}
	do
		local r = engine:invoke(alice, "Roll", table.unpack(args))
		check(`bad roll ({label}) rejected`, r.ok == false and type(r.message) == "string", r.message)
	end
	check("unknown upgrade rejected", engine:invoke(alice, "BuyUpgrade", "Hax").ok == false)
	check("nil upgrade rejected", engine:invoke(alice, "BuyUpgrade", nil).ok == false)
	check("combining Diamond rejected", engine:invoke(alice, "Combine", "PotatoPrisoner", "Diamond").ok == false)
	check("combining unknown Brainrot rejected", engine:invoke(alice, "Combine", "Nope", "Normal").ok == false)
	check("skipping a block rejected", engine:invoke(alice, "UnlockArea", "DeathRow").ok == false)
	check("unknown cosmetic rejected", engine:invoke(alice, "BuyCosmetic", "Hax").ok == false)
	check("toggling an unowned cosmetic rejected", engine:invoke(alice, "ToggleCosmetic", "Bed").ok == false)
	check("free roll with a non-boolean is a normal roll", roll(alice, "CellBlock1", "yes").ok == true)

	local limiter = RateLimiter.new(3, 2)
	check("rate limiter allows a burst", limiter:allow(alice) and limiter:allow(alice) and limiter:allow(alice))
	check("rate limiter blocks spam", limiter:allow(alice) == false)

	GameConfig.ROLL.minInterval = 60
	roll(alice, "CellBlock1", false)
	local tooSoon = roll(alice, "CellBlock1", false)
	check(
		"server enforces time between rolls",
		tooSoon.ok == false and string.find(tooSoon.message, "spinning") ~= nil,
		tooSoon.message
	)
	GameConfig.ROLL.minInterval = 0

	---------------------------------------------------------------------------
	section("Pity (LUCKY ROLLS)")
	---------------------------------------------------------------------------
	EconomyService.add(alice, 1e9)
	local maxPity, pityOk, counts = 0, true, {}
	for _ = 1, 2000 do
		local pityBefore = data.pity
		local r = roll(alice, "CellBlock1", false)
		if not r.ok then
			pityOk = false
			break
		end
		counts[r.result.rarity] = (counts[r.result.rarity] or 0) + 1
		local order = BrainrotData.RarityById[r.result.rarity].order
		if order >= 5 then
			pityOk = pityOk and data.pity == 0
		else
			pityOk = pityOk and data.pity == pityBefore + 1
		end
		maxPity = math.max(maxPity, data.pity)
	end
	check("pity +1 per roll, reset on Legendary+", pityOk)
	check("pity never passes the guarantee", maxPity <= GameConfig.PITY.guaranteeAt, maxPity)
	local common = (counts.Common or 0) / 2000
	print(`  (2000 rolls: {common * 100}% Common, {counts.Legendary or 0} Legendary, {counts.Mythic or 0} Mythic)`)
	check("commons are the most common", common > 0.3 and common < 0.7, common)
	local guaranteed = true
	for _ = 1, 25 do
		data.pity = GameConfig.PITY.guaranteeAt
		local r = roll(alice, "CellBlock1", false)
		guaranteed = guaranteed and BrainrotData.RarityById[r.result.rarity].order >= 5
	end
	check("150 lucky rolls guarantees Legendary+", guaranteed)
	check("found Legendary achievement", data.achievements.Legendary == true)

	---------------------------------------------------------------------------
	section("Duplicates, Golden and Diamond")
	---------------------------------------------------------------------------
	BrainrotService.grant(data, "ChickenThief", "Normal", 10)
	local chicken = data.brainrots.ChickenThief
	local normalBefore, goldenBefore = chicken.Normal, chicken.Golden
	local combined = engine:invoke(alice, "Combine", "ChickenThief", "Normal")
	check(
		"combine 3 into a Golden",
		combined.ok and chicken.Normal == normalBefore - 3 and chicken.Golden == goldenBefore + 1
	)
	check("Golden variant recorded", data.variantsFound.ChickenThief and data.variantsFound.ChickenThief.Golden == true)
	check(
		"Golden earns 2x",
		BrainrotData.income("ChickenThief", "Golden") == 2 * BrainrotData.income("ChickenThief", "Normal")
	)
	check(
		"Diamond earns 5x",
		BrainrotData.income("ChickenThief", "Diamond") == 5 * BrainrotData.income("ChickenThief", "Normal")
	)

	local worth = {}
	for id, c in data.brainrots do
		worth[id] = c.Normal + c.Golden * 3 + c.Diamond * 9
	end
	local all = engine:invoke(alice, "CombineAll")
	check("combine all works", all.ok == true, all.message)
	local conserved = true
	for id, c in data.brainrots do
		conserved = conserved
			and (c.Normal + c.Golden * 3 + c.Diamond * 9 == worth[id])
			and c.Normal < 3
			and c.Golden < 3
	end
	check("combine all converts every set of 3 and loses nothing", conserved)
	check("Diamond achievement", data.achievements.Diamond == true)

	---------------------------------------------------------------------------
	section("Upgrades")
	---------------------------------------------------------------------------
	data.coins = 1e15
	for _, upgrade in UpgradeData.Upgrades do
		local level = data.upgrades[upgrade.id]
		local coins = data.coins
		local r = engine:invoke(alice, "BuyUpgrade", upgrade.id)
		check(
			`buy {upgrade.name}`,
			r.ok
				and data.upgrades[upgrade.id] == level + 1
				and coins - data.coins == UpgradeData.cost(upgrade.id, level),
			r.message
		)
	end
	for _ = 1, 20 do
		engine:invoke(alice, "BuyUpgrade", "Speed")
	end
	check("upgrades stop at max level", data.upgrades.Speed == UpgradeData.ById.Speed.maxLevel)
	check("maxed upgrade says so", string.find(engine:invoke(alice, "BuyUpgrade", "Speed").message, "MAXED") ~= nil)
	check("capacity grows with the upgrade", Formulas.capacity(data) == GameConfig.BASE_CAPACITY + 2)
	task.wait(0.1)
	check(
		"server income matches the shared formula",
		math.abs(EconomyService.getIncome(alice) - Formulas.baseIncome(data)) < 1e-6
	)
	check("luck upgrade raises luck", Formulas.permanentLuck(data) > 1.1)

	---------------------------------------------------------------------------
	section("Prison blocks")
	---------------------------------------------------------------------------
	local bob, bobData = join(1002, "Bob")
	check("Bob gets his own cell", cellOf(bob) ~= nil and cellOf(bob) ~= cellOf(alice))
	check("must unlock in order", engine:invoke(bob, "UnlockArea", "MaxSecurity").ok == false)
	check("can't afford Cell Block 2 at start", engine:invoke(bob, "UnlockArea", "CellBlock2").ok == false)
	check("can't roll in a locked block", roll(bob, "CellBlock2", false).ok == false)
	local cellBlock2 = AreaData.ById.CellBlock2
	bobData.coins = cellBlock2.unlockCost
	check("unlock Cell Block 2", engine:invoke(bob, "UnlockArea", "CellBlock2").ok == true)
	check("unlocking takes the price", bobData.coins < 50, bobData.coins)
	check("already unlocked is rejected", engine:invoke(bob, "UnlockArea", "CellBlock2").ok == false)
	EconomyService.add(bob, cellBlock2.rollCost)
	local coinsBeforeRoll = bobData.coins
	check("roll in Cell Block 2", roll(bob, "CellBlock2", false).ok == true)
	check(
		"Cell Block 2 rolls cost their price",
		coinsBeforeRoll - bobData.coins == cellBlock2.rollCost,
		coinsBeforeRoll - bobData.coins
	)

	data.coins = 1e15
	for _, area in AreaData.Areas do
		if not data.unlockedAreas[area.id] then
			check(`unlock {area.name}`, engine:invoke(alice, "UnlockArea", area.id).ok == true)
		end
	end
	check("Prison Explorer achievement", data.achievements.AllBlocks == true)
	local secretOk, maxOk = true, true
	for _ = 1, 60 do
		secretOk = secretOk and BrainrotData.RarityById[roll(alice, "SecretBlock", false).result.rarity].order >= 4
		maxOk = maxOk and roll(alice, "MaxSecurity", false).result.rarity ~= "Common"
	end
	check("Secret Block only rolls Epic or better", secretOk)
	check("Maximum Security never rolls Common", maxOk)

	---------------------------------------------------------------------------
	section("Cell cosmetics")
	---------------------------------------------------------------------------
	check("buy a bed", engine:invoke(alice, "BuyCosmetic", "Bed").ok == true)
	check("can't buy it twice", engine:invoke(alice, "BuyCosmetic", "Bed").ok == false)
	task.wait(0.5)
	check("bed appears in the cell", cellOf(alice).Decor:FindFirstChild("Bed") ~= nil)
	local function hidden(name: string): boolean
		local furniture = cellOf(alice):FindFirstChild(name)
		local part = furniture and furniture:FindFirstChildWhichIsA("BasePart", true)
		return part ~= nil and part.Transparency == 1
	end
	check("the comfy bed replaces the steel bunk", hidden("Bunk"))
	check("hide the bed", engine:invoke(alice, "ToggleCosmetic", "Bed").ok == true and data.cosmetics.Bed == false)
	task.wait(0.5)
	check("bed disappears", cellOf(alice).Decor:FindFirstChild("Bed") == nil)
	check("the steel bunk comes back", not hidden("Bunk"))
	for _, cosmetic in CosmeticData.Cosmetics do
		if data.cosmetics[cosmetic.id] == nil then
			engine:invoke(alice, "BuyCosmetic", cosmetic.id)
		end
	end
	task.wait(0.5)
	check(
		"every other cosmetic builds in the cell (the golden toilet wins over the porcelain one)",
		#cellOf(alice).Decor:GetChildren() == #CosmeticData.Cosmetics - 2,
		#cellOf(alice).Decor:GetChildren()
	)
	check("the golden toilet replaces the steel one", hidden("Toilet"))
	check("cell shows the 3 best Brainrots", #cellOf(alice).Displays:GetChildren() == 3)

	---------------------------------------------------------------------------
	section("Free luck boost and daily free roll")
	---------------------------------------------------------------------------
	local luckBefore = Formulas.personalLuck(data, engine:now(), 1)
	check("claim free luck", engine:invoke(alice, "ClaimFreeBoost").ok == true)
	check(
		"boost multiplies luck",
		math.abs(Formulas.personalLuck(data, engine:now(), 1) - math.min(luckBefore * 1.5, GameConfig.MAX_LUCK)) < 1e-6
	)
	check("free luck has a cooldown", engine:invoke(alice, "ClaimFreeBoost").ok == false)
	engine.timeOffset += GameConfig.FREE_BOOST.cooldown + 1
	check("free luck ready again after the cooldown", engine:invoke(alice, "ClaimFreeBoost").ok == true)

	local coinsBeforeFree = bobData.coins
	local daily = roll(bob, "CellBlock2", true)
	check("daily free roll", daily.ok == true and daily.result.free == true, daily.message)
	check("daily free roll costs nothing", bobData.coins >= coinsBeforeFree)
	check("only one free roll per day", roll(bob, "CellBlock2", true).ok == false)
	engine.timeOffset += GameConfig.DAILY_ROLL_COOLDOWN
	check("free roll comes back after 24 hours", roll(bob, "CellBlock2", true).ok == true)

	---------------------------------------------------------------------------
	section("Server events")
	---------------------------------------------------------------------------
	check("unknown event rejected", EventService.trigger("Nope") == false)
	check("start DOUBLE INCOME", EventService.trigger("DoubleIncome") == true)
	task.wait(0.2)
	check("no second event while one runs", EventService.trigger("LuckyHour") == false)
	check(
		"income doubles",
		Events.incomeMultiplier() == 2
			and math.abs(EconomyService.getIncome(alice) - 2 * Formulas.baseIncome(data)) < 1e-6
	)
	check("event announced", #engine:eventsNamed("Announce") > 0)
	task.wait(1.6)
	check("income back to normal after", Events.incomeMultiplier() == 1)

	EventService.trigger("LuckyHour")
	task.wait(0.2)
	check("LUCKY HOUR doubles luck", Events.luckMultiplier() == 2)
	task.wait(1.6)

	EventService.trigger("CrazyRolls")
	task.wait(0.2)
	check("CRAZY ROLLS speeds up rolls", roll(alice, "CellBlock1", false).result.speed == 2)
	task.wait(1.6)

	EventService.trigger("PrisonKing")
	task.wait(0.2)
	local king = workspace.Events:FindFirstChild("EventPrisonKing")
	check("the Prison King appears", king ~= nil)
	if king then
		local prompt = king:FindFirstChildWhichIsA("ProximityPrompt", true)
		local serverRolls = #engine:eventsNamed("ServerRoll", bob)
		prompt.Triggered:Fire(bob)
		task.wait(0.1)
		check("the King gives a free roll", #engine:eventsNamed("ServerRoll", bob) == serverRolls + 1)
		prompt.Triggered:Fire(bob)
		task.wait(0.1)
		check("only one King's roll per player", #engine:eventsNamed("ServerRoll", bob) == serverRolls + 1)
	end
	task.wait(1.6)
	check("the King leaves after the event", workspace.Events:FindFirstChild("EventPrisonKing") == nil)

	EventService.trigger("EscapedBrainrots")
	task.wait(0.3)
	local escaped = workspace.Events:GetChildren()
	check("6 giant Brainrots escape", #escaped == GameConfig.EVENTS.escapedCount, #escaped)
	if escaped[1] then
		local coins = bobData.coins
		escaped[1]:FindFirstChildWhichIsA("ProximityPrompt", true).Triggered:Fire(bob)
		task.wait(0.1)
		check("catching one pays coins", bobData.coins >= coins + GameConfig.EVENTS.escapedMinReward)
		check("caught Brainrot disappears", #workspace.Events:GetChildren() == #escaped - 1)
	end
	task.wait(1.6)
	check("escaped Brainrots cleaned up", #workspace.Events:GetChildren() == 0)

	---------------------------------------------------------------------------
	section("Rebirth")
	---------------------------------------------------------------------------
	local cost = Formulas.rebirthCost(data.rebirths)
	local permanentBefore = Formulas.permanentLuck(data)
	data.coins = cost - 1
	check("rebirth needs enough coins", engine:invoke(alice, "Rebirth").ok == false)
	data.coins = cost
	local discoveredBefore = Formulas.discoveredCount(data)
	local rebirth = engine:invoke(alice, "Rebirth")
	check("rebirth succeeds", rebirth.ok == true, rebirth.message)
	check("coins reset", data.coins == GameConfig.STARTING_COINS)
	local upgradesReset = true
	for _, level in data.upgrades do
		upgradesReset = upgradesReset and level == 0
	end
	check("upgrades reset", upgradesReset)
	check("blocks reset", Formulas.unlockedCount(data) == 1)
	local lowGone = true
	for id in data.brainrots do
		lowGone = lowGone and BrainrotData.getRarity(id).order >= 3
	end
	check("Common and Uncommon Brainrots removed", lowGone)
	check("Rare+ Brainrots kept", Formulas.totalOwned(data) > 0)
	check("Brainrot Book kept", Formulas.discoveredCount(data) == discoveredBefore)
	check("rebirth counted", data.rebirths == 1)
	print(`  (permanent luck {permanentBefore} -> {Formulas.permanentLuck(data)} after losing upgrades)`)
	check("rebirth adds +10% luck", Formulas.luckBreakdown(data, 0, 1).rebirth == 0.1)
	task.wait(1.7)
	check("player respawns at the start", engine.respawns[1001] == 1)

	---------------------------------------------------------------------------
	section("Leaderboards")
	---------------------------------------------------------------------------
	task.wait(0.6)
	local rows = workspace.Leaderboards.Board_Rebirths:FindFirstChild("Row1", true)
	check("physical leaderboard shows players", rows and string.find(rows.Text, "Alice") ~= nil, rows and rows.Text)
	local stats = alice:FindFirstChild("leaderstats")
	check("leaderstats Rebirths", stats and stats.Rebirths.Value == 1)

	---------------------------------------------------------------------------
	section("Saving and loading")
	---------------------------------------------------------------------------
	local expected = {
		coins = data.coins,
		rebirths = data.rebirths,
		owned = Formulas.totalOwned(data),
		found = Formulas.discoveredCount(data),
	}
	engine:removePlayer(alice)
	Engine.waitUntil(function()
		local saved = engine.storage[STORE]["Player_1001"]
		return DataService.get(alice) == nil and saved ~= nil and saved.meta.lockJobId == nil
	end, 5, "Alice's save")
	local saved = engine.storage[STORE]["Player_1001"]
	check("saved on leave", saved.rebirths == 1 and saved.coins >= expected.coins)
	check("session lock released on leave", saved.meta.lockJobId == nil)
	check("leaderboard stats written", engine.storage["Ordered:PB_Rebirths_v1"]["Player_1001"] == 1)
	check("cell freed", cellOf(alice) == nil)

	local alice2, reloaded = join(1001, "Alice")
	check("coins restored", reloaded.coins >= expected.coins)
	check("rebirths restored", reloaded.rebirths == expected.rebirths)
	check("Brainrots restored", Formulas.totalOwned(reloaded) == expected.owned)
	check("book restored", Formulas.discoveredCount(reloaded) == expected.found)
	check("tutorial stays done", reloaded.tutorialDone == true)

	---------------------------------------------------------------------------
	section("Session locking")
	---------------------------------------------------------------------------
	local lockedRecord = DataService.template()
	lockedRecord.coins = 777
	lockedRecord.meta = { lockJobId = "another-server", lockTime = math.floor(engine:now()) }
	engine.storage[STORE]["Player_2002"] = lockedRecord
	local started = os.clock()
	local carol, carolData = join(2002, "Carol")
	check("waits for another server's lock before taking it", os.clock() - started >= 0.35, os.clock() - started)
	check("loads the locked save", carolData.coins == 777)
	check("lock now belongs to this server", engine.storage[STORE]["Player_2002"].meta.lockJobId == "test-server")

	engine.storage[STORE]["Player_2002"].meta.lockJobId = "thief-server"
	engine.storage[STORE]["Player_2002"].meta.lockTime = math.floor(engine:now())
	engine.storage[STORE]["Player_2002"].coins = 999
	local warningsBefore = #engine.warnings
	engine:removePlayer(carol)
	task.wait(0.3)
	check("won't overwrite a save another server took over", engine.storage[STORE]["Player_2002"].coins == 999)
	check("warns about it", #engine.warnings > warningsBefore)

	---------------------------------------------------------------------------
	section("Saves from the rolled-back roster")
	---------------------------------------------------------------------------
	local laterRecord = DataService.template() :: any
	laterRecord.brainrots = {
		TimCheese = { Normal = 2, Golden = 1, Diamond = 0 },
		PotatoPrisoner = { Normal = 1, Golden = 0, Diamond = 0 },
		TralaleroTralala = { Normal = 1, Golden = 1, Diamond = 0 },
	}
	laterRecord.discovered = { TimCheese = true, PotatoPrisoner = true, TralaleroTralala = true }
	laterRecord.variantsFound = { TimCheese = { Golden = true }, TralaleroTralala = { Golden = true } }
	engine.storage[STORE]["Player_2003"] = laterRecord
	local erin, erinData = join(2003, "Erin")
	check(
		"Brainrots from the later roster keep their counts",
		erinData.brainrots.PotatoPrisoner.Normal == 3 and erinData.brainrots.PotatoPrisoner.Golden == 1
	)
	check(
		"their ids are removed",
		erinData.brainrots.TimCheese == nil
			and erinData.discovered.TralaleroTralala == nil
			and erinData.variantsFound.TralaleroTralala == nil
	)
	check(
		"their discoveries are kept",
		erinData.discovered.GalaxyWarden == true and erinData.brainrots.GalaxyWarden.Golden == 1
	)
	check(
		"their variants are kept",
		erinData.variantsFound.PotatoPrisoner.Golden == true and erinData.variantsFound.GalaxyWarden.Golden == true
	)
	engine:removePlayer(erin)
	task.wait(0.2)

	---------------------------------------------------------------------------
	section("DataStore outage")
	---------------------------------------------------------------------------
	engine.dataStoreFailures = 1
	engine:addPlayer(3003, "Dave")
	Engine.waitUntil(function()
		return engine.kicks[3003] ~= nil
	end, 10, "Dave to be kicked")
	check(
		"live server kicks instead of risking a bad save",
		string.find(engine.kicks[3003], "couldn't load") ~= nil,
		engine.kicks[3003]
	)
	engine.dataStoreFailures = 0

	---------------------------------------------------------------------------
	section("Shutdown")
	---------------------------------------------------------------------------
	local bobCoins = bobData.coins
	engine:shutdown()
	check(
		"BindToClose saves everyone",
		engine.storage[STORE]["Player_1002"] ~= nil and engine.storage[STORE]["Player_1002"].coins >= bobCoins
	)
	check("and releases their locks", engine.storage[STORE]["Player_1002"].meta.lockJobId == nil)
	local _ = alice2
end)
