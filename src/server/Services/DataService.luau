-- Loads and saves player data with DataStoreService.
--
-- * Session locking stops two servers from saving the same player at once (no duping by server hopping).
-- * Every DataStore call is retried with backoff; if loading still fails in a live game the player is
--   kicked with a friendly message rather than playing on data that would overwrite their save.
-- * In Studio without API access, the game runs on temporary in-memory data and never saves.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Signal = require(ReplicatedStorage.Modules.Signal)
local Types = require(ReplicatedStorage.Modules.Types)
local UpgradeData = require(ReplicatedStorage.Modules.UpgradeData)

type PlayerData = Types.PlayerData

type Profile = {
	data: PlayerData,
	canSave: boolean,
	releasing: boolean,
}

local DataService = {}

-- (player, data) once a player's data is ready.
DataService.Loaded = Signal.new()
-- (player, data, reason) after any service changes a player's data.
DataService.Changed = Signal.new()
-- (player, data) right before a leaving player's final save.
DataService.Releasing = Signal.new()

local CONFIG = GameConfig.DATA
local profiles: { [Player]: Profile } = {}
local store: DataStore? = nil
local memoryMode = false

function DataService.template(): PlayerData
	local upgrades = {}
	for _, upgrade in UpgradeData.Upgrades do
		upgrades[upgrade.id] = 0
	end
	return {
		version = 1,
		coins = GameConfig.STARTING_COINS,
		totalEarned = 0,
		brainrots = { [GameConfig.STARTER_BRAINROT] = { Normal = 1, Golden = 0, Diamond = 0 } },
		discovered = { [GameConfig.STARTER_BRAINROT] = true },
		variantsFound = {},
		upgrades = upgrades,
		unlockedAreas = { [AreaData.FirstAreaId] = true },
		rebirths = 0,
		pity = 0,
		totalRolls = 0,
		bestRarity = 1,
		lastDailyRoll = 0,
		boostUntil = 0,
		freeBoostReadyAt = 0,
		achievements = {},
		cosmetics = {},
		tutorialDone = false,
		luck = 1,
		meta = {},
	}
end

-- Fills in anything missing or of the wrong type, so older saves keep working after updates.
local function reconcile(saved: any): PlayerData
	local template = DataService.template() :: any
	local data = if type(saved) == "table" then saved else {}
	for key, default in template do
		if typeof(data[key]) ~= typeof(default) then
			data[key] = default
		end
	end
	for _, upgrade in UpgradeData.Upgrades do
		if type(data.upgrades[upgrade.id]) ~= "number" then
			data.upgrades[upgrade.id] = 0
		end
	end
	for id, counts in data.brainrots do
		if type(counts) ~= "table" then
			data.brainrots[id] = nil
		else
			for _, variant in { "Normal", "Golden", "Diamond" } do
				if type(counts[variant]) ~= "number" then
					counts[variant] = 0
				end
			end
		end
	end
	-- Brainrots saved under ids from the rolled-back roster keep their counts and discoveries here
	for legacyId, id in BrainrotData.LegacyIds do
		local counts = data.brainrots[legacyId]
		if counts then
			local merged = data.brainrots[id] or { Normal = 0, Golden = 0, Diamond = 0 }
			for variant, amount in counts do
				merged[variant] = (merged[variant] or 0) + amount
			end
			data.brainrots[id] = merged
			data.brainrots[legacyId] = nil
		end
		if data.discovered[legacyId] then
			data.discovered[id] = true
			data.discovered[legacyId] = nil
		end
		local found = data.variantsFound[legacyId]
		if type(found) == "table" then
			local merged = data.variantsFound[id]
			if type(merged) ~= "table" then
				merged = {}
				data.variantsFound[id] = merged
			end
			for variant, value in found do
				merged[variant] = merged[variant] or value
			end
		end
		data.variantsFound[legacyId] = nil
	end
	data.unlockedAreas[AreaData.FirstAreaId] = true
	return data :: PlayerData
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

local function isLockedByOtherServer(saved: any, now: number): boolean
	if type(saved) ~= "table" or type(saved.meta) ~= "table" then
		return false
	end
	local meta = saved.meta
	return type(meta.lockJobId) == "string"
		and meta.lockJobId ~= game.JobId
		and type(meta.lockTime) == "number"
		and now - meta.lockTime < CONFIG.lockTimeout
end

-- One attempt to load and lock. Returns "ok", "locked" or "error".
local function tryLoad(key: string, force: boolean): (string, any)
	local status = "ok"
	local ok, result = pcall(function()
		return (store :: DataStore):UpdateAsync(key, function(saved)
			if not force and isLockedByOtherServer(saved, os.time()) then
				status = "locked"
				return nil
			end
			local data = if type(saved) == "table" then saved else DataService.template()
			data.meta = if type(data.meta) == "table" then data.meta else {}
			data.meta.lockJobId = game.JobId
			data.meta.lockTime = os.time()
			status = "ok"
			return data
		end)
	end)
	if not ok then
		return "error", result
	end
	return status, result
end

local function loadFromStore(player: Player): (boolean, any)
	local key = keyFor(player)
	local lockWaits = 0
	local errors = 0
	while player.Parent do
		local status, result = tryLoad(key, lockWaits >= CONFIG.lockWaitAttempts)
		if status == "ok" then
			return true, result
		elseif status == "locked" then
			lockWaits += 1
			task.wait(CONFIG.lockWaitSeconds)
		else
			errors += 1
			warn(`[DataService] Load attempt {errors} failed for {player.Name}: {result}`)
			if errors >= CONFIG.retries then
				return false, result
			end
			task.wait(2 ^ errors)
		end
	end
	return false, "player left"
end

local function save(player: Player, profile: Profile, release: boolean): boolean
	if not profile.canSave or not store then
		return false
	end
	local key = keyFor(player)
	for attempt = 1, CONFIG.retries do
		local stolen = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key, function(saved)
				if isLockedByOtherServer(saved, os.time()) then
					stolen = true
					return nil
				end
				profile.data.meta.lockJobId = if release then nil else game.JobId
				profile.data.meta.lockTime = os.time()
				return profile.data
			end)
		end)
		if ok then
			if stolen then
				warn(`[DataService] {player.Name}'s data is now owned by another server; not overwriting it.`)
				profile.canSave = false
				return false
			end
			return true
		end
		warn(`[DataService] Save attempt {attempt} failed for {player.Name}: {err}`)
		if attempt < CONFIG.retries then
			task.wait(2 ^ attempt)
		end
	end
	return false
end

local function enterMemoryMode(reason: any)
	if memoryMode then
		return
	end
	memoryMode = true
	warn(
		"[DataService] DataStores are unavailable, so progress will NOT be saved this session. "
			.. "In Studio: publish the place and turn on Game Settings > Security > "
			.. `"Enable Studio Access to API Services". ({reason})`
	)
end

local function onPlayerAdded(player: Player)
	local saved: any = nil
	local canSave = false

	if store and not memoryMode then
		local ok, result = loadFromStore(player)
		if ok then
			saved = result
			canSave = true
		elseif RunService:IsStudio() then
			enterMemoryMode(result)
		else
			if player.Parent then
				player:Kick(
					"We couldn't load your Prison Brainrot save. Your progress is safe - please rejoin in a moment!"
				)
			end
			return
		end
	end

	local profile: Profile = {
		data = reconcile(saved),
		canSave = canSave,
		releasing = false,
	}

	if not player.Parent then
		-- Left while loading: hand the session lock straight back.
		save(player, profile, true)
		return
	end

	profiles[player] = profile
	DataService.Loaded:Fire(player, profile.data)
end

local function release(player: Player, profile: Profile)
	if profile.releasing then
		return
	end
	profile.releasing = true
	DataService.Releasing:Fire(player, profile.data)
	save(player, profile, true)
	profiles[player] = nil
end

function DataService.get(player: Player): PlayerData?
	local profile = profiles[player]
	if profile and not profile.releasing then
		return profile.data
	end
	return nil
end

function DataService.getPlayers(): { [Player]: PlayerData }
	local result = {}
	for player, profile in profiles do
		if not profile.releasing then
			result[player] = profile.data
		end
	end
	return result
end

function DataService.changed(player: Player, reason: string)
	local data = DataService.get(player)
	if data then
		DataService.Changed:Fire(player, data, reason)
	end
end

function DataService.isSaving(): boolean
	return store ~= nil and not memoryMode
end

function DataService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(CONFIG.storeName)
	end)
	if ok then
		store = result
	else
		enterMemoryMode(result)
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			release(player, profile)
		end
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(CONFIG.autosaveInterval)
			for player, profile in profiles do
				if not profile.releasing then
					task.spawn(save, player, profile, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player, profile in profiles do
			task.spawn(release, player, profile)
		end
		local started = os.clock()
		while next(profiles) ~= nil and os.clock() - started < 25 do
			task.wait(0.25)
		end
	end)
end

return DataService
