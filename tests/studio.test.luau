--!nocheck
-- In Studio without "Enable Studio Access to API Services", DataStores fail. The game should still be
-- playable on temporary data, warn once, and never try to save.
--
--   lune run tests/studio.test.luau build/test.rbxl

local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")

local Engine = require("./engine")
local T = require("./testing")

local engine = Engine.new(fs.readFile(process.args[1] or "build/test.rbxl"), { studio = true })
local game = engine.game
local Modules = engine.ReplicatedStorage.Modules
local Services = game:GetService("ServerScriptService").Services

local GameConfig = engine:require(Modules.GameConfig)
GameConfig.DATA.retries = 1
GameConfig.EVENTS.firstDelay = 100000
engine.dataStoreFailures = 1

T.run(function()
	engine:run(game:GetService("ServerScriptService").Main)
	task.wait(0.3)
	local DataService = engine:require(Services.DataService)

	local player = engine:addPlayer(4004, "StudioTester")
	Engine.waitUntil(function()
		return DataService.get(player) ~= nil
	end, 10, "temporary data")
	local data = DataService.get(player)

	T.check("not kicked in Studio", engine.kicks[4004] == nil)
	T.check("plays on fresh temporary data", data.coins == GameConfig.STARTING_COINS)
	local warned = false
	for _, warning in engine.warnings do
		warned = warned or string.find(warning, "will NOT be saved") ~= nil
	end
	T.check("warns that progress won't save, with the fix", warned)
	T.check("can still roll", engine:invoke(player, "Roll", "CellBlock1", false).ok == true)

	local callsBefore = engine.dataStoreCalls
	engine.dataStoreFailures = 0
	engine:removePlayer(player)
	task.wait(0.3)
	T.check("doesn't try to save temporary data", engine.dataStoreCalls == callsBefore)
	T.check("nothing written", engine.storage[GameConfig.DATA.storeName]["Player_4004"] == nil)
end)
