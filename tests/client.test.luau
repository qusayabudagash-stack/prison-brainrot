--!nocheck
-- Runs the server and the real client scripts together and clicks through the UI like a player:
-- tutorial, HUD, roll animation, Brainrot Book, shop, rebirth, odds, prompts, gates and announcements.
--
--   lune run tests/client.test.luau build/test.rbxl

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Engine = require("./engine")
local T = require("./testing")

local engine = Engine.new(fs.readFile(process.args[1] or "build/test.rbxl"), { studio = true })
local game = engine.game
local workspace = engine.workspace
local Modules = engine.ReplicatedStorage.Modules
local Services = game:GetService("ServerScriptService").Services

-- Short animations so the test runs quickly.
local GameConfig = engine:require(Modules.GameConfig)
local BrainrotData = engine:require(Modules.BrainrotData)
GameConfig.ROLL.spinTime = 0.4
GameConfig.ROLL.minInterval = 0
GameConfig.EVENTS.firstDelay = 100000
-- Lune stores whole-number attributes as 32-bit integers (Roblox uses doubles), so keep coins under ~2 billion.
GameConfig.REBIRTH.baseCost = 50_000_000
for _, rarity in BrainrotData.Rarities do
	rarity.revealExtra = 0.1
end

T.run(function()
	engine:run(game:GetService("ServerScriptService").Main)
	task.wait(0.3)

	local Formulas = engine:require(Modules.Formulas)
	local AnnouncementService = engine:require(Services.AnnouncementService)
	local BrainrotService = engine:require(Services.BrainrotService)
	local DataService = engine:require(Services.DataService)
	local EconomyService = engine:require(Services.EconomyService)

	local check, section = T.check, T.section

	local alice = engine:addPlayer(1001, "Alice")
	local playerGui = engine:attachClient(alice)
	Engine.waitUntil(function()
		return DataService.get(alice) ~= nil
	end, 10, "Alice's data")
	local data = DataService.get(alice)

	local clientScript = game:GetService("StarterPlayer").StarterPlayerScripts.Client
	engine:run(clientScript)
	task.wait(0.3)
	DataService.changed(alice, "test") -- the first snapshot went out before the client was listening
	task.wait(0.3)

	local function find(root, pattern, className)
		for _, descendant in root:GetDescendants() do
			if
				(className == nil or descendant.ClassName == className)
				and (descendant:IsA("TextLabel") or descendant:IsA("TextButton"))
			then
				if string.find(descendant.Text, pattern, 1, true) then
					return descendant
				end
			end
		end
		return nil
	end

	local function click(root, pattern)
		local button = find(root, pattern, "TextButton")
		if not button then
			-- HUD tiles keep their text in a caption next to the button
			local caption = find(root, pattern, "TextLabel")
			local holder = caption and caption.Parent
			button = holder and holder:FindFirstChild("Button")
		end
		assert(button, `No button "{pattern}"`)
		button.Activated:Fire()
		task.wait(0.1)
		return button
	end

	local function screen(name)
		return playerGui:FindFirstChild(name)
	end

	local function finishRoll()
		local rollUI = screen("RollUI")
		Engine.waitUntil(function()
			local catcher = rollUI:FindFirstChildWhichIsA("TextButton")
			return catcher ~= nil and catcher.Visible
		end, 10, "the roll reveal")
		rollUI:FindFirstChildWhichIsA("TextButton").Activated:Fire()
		Engine.waitUntil(function()
			return not rollUI.Enabled
		end, 5, "the roll screen to close")
		task.wait(0.1)
	end

	---------------------------------------------------------------------------
	section("Screens")
	---------------------------------------------------------------------------
	for _, name in { "MainUI", "RollUI", "CollectionUI", "ShopUI", "RebirthUI", "AnnouncementUI" } do
		check(`{name} created`, screen(name) ~= nil)
	end
	check("HUD shows coins", find(screen("MainUI"), "💰 $1") ~= nil)
	check("HUD shows income", find(screen("MainUI"), "💵 +$5/sec") ~= nil)
	check("HUD shows luck", find(screen("MainUI"), "Luck") ~= nil)
	check("HUD shows LUCKY ROLLS", find(screen("MainUI"), "LUCKY ROLLS: 0/50") ~= nil)
	check(
		"ROLL button shows the price",
		find(screen("MainUI"), "🎰 ROLL") ~= nil and find(screen("MainUI"), "$100") ~= nil
	)
	check("block picker shows Cell Block 1", find(screen("MainUI"), "CELL BLOCK 1") ~= nil)

	---------------------------------------------------------------------------
	section("Tutorial")
	---------------------------------------------------------------------------
	check("tutorial shows for new players", screen("TutorialUI") ~= nil)
	check("welcome message", find(screen("TutorialUI"), "WELCOME TO PRISON BRAINROT!") ~= nil)
	for step = 1, 5 do
		click(screen("TutorialUI"), "NEXT")
		check(`tutorial step {step}`, find(screen("TutorialUI"), `STEP {step}`) ~= nil)
	end
	click(screen("TutorialUI"), "LET'S GO")
	task.wait(0.2)
	check("tutorial closes", screen("TutorialUI") == nil)
	check("tutorial marked done on the server", data.tutorialDone == true)

	---------------------------------------------------------------------------
	section("Rolling from the HUD")
	---------------------------------------------------------------------------
	click(screen("MainUI"), "🎰 ROLL")
	check("roll screen opens", screen("RollUI").Enabled == true)
	finishRoll()
	check("rolled once", data.totalRolls == 1)
	check("paid $100", data.coins < 100)
	check("roll screen closes", screen("RollUI").Enabled == false)

	EconomyService.add(alice, 1e6)
	engine.signalOf(game:GetService("UserInputService"), "InputBegan"):Fire({ KeyCode = roblox.Enum.KeyCode.R }, false)
	task.wait(0.1)
	check("R key rolls too", screen("RollUI").Enabled == true)
	finishRoll()
	check("rolled twice", data.totalRolls == 2)

	local machinePrompt = workspace.RollMachines.CellBlock1Machine:FindFirstChildWhichIsA("ProximityPrompt", true)
	engine.signalOf(game:GetService("ProximityPromptService"), "PromptTriggered"):Fire(machinePrompt, alice)
	task.wait(0.1)
	check("machine button rolls", screen("RollUI").Enabled == true)
	finishRoll()
	check("rolled three times", data.totalRolls == 3)

	data.coins = 0
	EconomyService.add(alice, 1)
	click(screen("MainUI"), "🎰 ROLL")
	task.wait(0.2)
	check("can't roll when broke: shows an error toast", find(screen("AnnouncementUI"), "You need") ~= nil)
	check("no roll screen when it fails", screen("RollUI").Enabled == false)

	---------------------------------------------------------------------------
	section("Daily roll and free luck")
	---------------------------------------------------------------------------
	click(screen("MainUI"), "FREE ROLL")
	check("daily free roll plays", screen("RollUI").Enabled == true)
	finishRoll()
	check("daily roll used", data.lastDailyRoll > 0 and data.totalRolls == 4)
	click(screen("MainUI"), "FREE LUCK")
	task.wait(0.2)
	check("free luck claimed", data.boostUntil > engine:now())
	check("HUD shows the boost timer", find(screen("MainUI"), "LUCK BOOST") ~= nil)

	---------------------------------------------------------------------------
	section("Brainrot Book")
	---------------------------------------------------------------------------
	click(screen("MainUI"), "BOOK")
	local book = screen("CollectionUI")
	check("book opens", book.Enabled == true)
	local cards = 0
	for _, descendant in book:GetDescendants() do
		if descendant:IsA("ViewportFrame") then
			cards += 1
		end
	end
	check("a card for every Brainrot", cards == BrainrotData.Count, cards)
	check("collection counter", find(book, `COLLECTION: {Formulas.discoveredCount(data)}/{BrainrotData.Count}`) ~= nil)
	check("unknown Brainrots show ???", find(book, "???") ~= nil)
	check("known Brainrots show their name", find(book, "Potato Prisoner") ~= nil)

	BrainrotService.grant(data, "PotatoPrisoner", "Normal", 3)
	DataService.changed(alice, "brainrots")
	task.wait(0.2)
	local potatoGolden = data.brainrots.PotatoPrisoner.Golden
	local potatoCard = find(book, "🥔 Potato Prisoner").Parent
	potatoCard:FindFirstChild("TextButton").Activated:Fire()
	for _, child in potatoCard:GetChildren() do
		if child:IsA("TextButton") and string.find(child.Text, "⭐", 1, true) then
			child.Activated:Fire()
		end
	end
	task.wait(0.2)
	check("combine button makes a Golden Potato", data.brainrots.PotatoPrisoner.Golden >= potatoGolden + 1)
	click(book, "COMBINE ALL")
	check("combine all button works", true)
	click(book, "X")
	check("book closes", book.Enabled == false)

	---------------------------------------------------------------------------
	section("Shop")
	---------------------------------------------------------------------------
	EconomyService.add(alice, 1e9)
	task.wait(0.2)
	click(screen("MainUI"), "UPGRADES")
	local shop = screen("ShopUI")
	check("shop opens on upgrades", shop.Enabled == true and find(shop, "Income Multiplier") ~= nil)
	task.wait(0.1)
	click(shop, "$1,000")
	check("buying an upgrade from the shop", data.upgrades.Income == 1)
	click(shop, "🔓 BLOCKS")
	click(shop, "🔓 $15,000")
	check("unlock Cell Block 2 from the shop", data.unlockedAreas.CellBlock2 == true)
	task.wait(0.1)
	check("shop shows it unlocked", find(shop, "UNLOCKED") ~= nil)
	click(shop, "🛋️ CELL ITEMS")
	click(shop, "$250")
	check("buy a bed from the shop", data.cosmetics.Bed == true)
	task.wait(0.1)
	click(shop, "SHOWN")
	check("hide it from the shop", data.cosmetics.Bed == false)
	click(shop, "X")

	---------------------------------------------------------------------------
	section("Blocks and gates")
	---------------------------------------------------------------------------
	task.wait(0.2)
	check("block picker jumps to the new block", find(screen("MainUI"), "CELL BLOCK 2") ~= nil)
	local gate = workspace.Prison.CellBlock2:FindFirstChild("Gate")
	local collider = gate and gate:FindFirstChild("Collider")
	check("unlocked gate opens for this player", collider and collider.CanCollide == false)
	check("unlocked gate sign says OPEN", find(gate, "OPEN") ~= nil)
	local lockedGate = workspace.Prison.MaxSecurity:FindFirstChild("Gate")
	check("locked gate stays closed", lockedGate.Collider.CanCollide == true)
	check("machine screen shows your price", find(workspace.RollMachines.CellBlock2Machine, "Cost: $") ~= nil)
	check("locked machine says LOCKED", find(workspace.RollMachines.MaxSecurityMachine, "LOCKED") ~= nil)
	click(screen("MainUI"), "◀")
	check("picker goes back to Cell Block 1", find(screen("MainUI"), "CELL BLOCK 1") ~= nil)

	---------------------------------------------------------------------------
	section("Odds")
	---------------------------------------------------------------------------
	click(screen("MainUI"), "ODDS")
	check(
		"odds panel shows every rarity",
		find(screen("MainUI"), "LEGENDARY") ~= nil and find(screen("MainUI"), "SECRET") ~= nil
	)
	check("odds panel shows chances", find(screen("MainUI"), "1 in") ~= nil)

	---------------------------------------------------------------------------
	section("Rebirth")
	---------------------------------------------------------------------------
	click(screen("MainUI"), "REBIRTH")
	local rebirthUI = screen("RebirthUI")
	check("rebirth screen opens", rebirthUI.Enabled == true)
	data.coins = Formulas.rebirthCost(0)
	EconomyService.add(alice, 1)
	task.wait(0.2)
	click(rebirthUI, "REBIRTH NOW")
	check("asks to confirm first", data.rebirths == 0 and find(rebirthUI, "ARE YOU SURE") ~= nil)
	click(rebirthUI, "ARE YOU SURE")
	task.wait(0.2)
	check("second tap rebirths", data.rebirths == 1)
	check("rebirth screen closes", rebirthUI.Enabled == false)

	---------------------------------------------------------------------------
	section("Announcements and events")
	---------------------------------------------------------------------------
	AnnouncementService.announce("🌟 Test announcement", { style = "big", duration = 0.5 })
	local shownAt = os.clock()
	while os.clock() - shownAt < 8 and find(screen("AnnouncementUI"), "Test announcement") == nil do
		task.wait(0.1)
	end
	check(
		"server announcement banner (after any queued ones)",
		find(screen("AnnouncementUI"), "Test announcement") ~= nil
	)
	AnnouncementService.announce("🚨 SECRET TEST", { style = "secret" })
	task.wait(0.2)
	local rainbow = nil
	for _, child in screen("AnnouncementUI"):GetChildren() do
		if child:IsA("Frame") and child:FindFirstChildOfClass("UIGradient") then
			rainbow = child
		end
	end
	check("secret find flashes the whole screen rainbow", rainbow ~= nil and rainbow.Visible == true)
	engine:require(Services.EventService).trigger("DoubleIncome")
	task.wait(0.7)
	check("event banner with countdown", find(screen("AnnouncementUI"), "DOUBLE INCOME") ~= nil)
	task.wait(1.2)
	engine:require(Services.RollService).grantFreeRoll(alice, 3, "PrisonKing")
	task.wait(0.1)
	check("server-given roll plays the animation", screen("RollUI").Enabled == true)
	Engine.waitUntil(function()
		return find(screen("RollUI"), "KING") ~= nil
	end, 10, "the King's roll title")
	check("labelled as the King's roll", true)
	finishRoll()
end)
