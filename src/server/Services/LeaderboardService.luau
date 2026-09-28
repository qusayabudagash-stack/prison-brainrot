-- leaderstats in the player list, plus the four physical leaderboards in Cell Block 1.
-- Board data comes from OrderedDataStores; if those are unavailable (e.g. Studio without API access)
-- the boards show the players in the current server instead.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapService = require(script.Parent.MapService)
local Types = require(ReplicatedStorage.Modules.Types)

local LeaderboardService = {}

type Entry = { userId: number, name: string, value: number }

local CONFIG = GameConfig.LEADERBOARD
-- OrderedDataStores only hold integers, so fractional stats are stored multiplied by this.
local LUCK_SCALE = 100
local MAX_STORED = 2 ^ 53

local stores: { [string]: OrderedDataStore } = {}
local nameCache: { [number]: string } = {}

local function statValue(boardId: string, data: Types.PlayerData): number
	if boardId == "Rebirths" then
		return data.rebirths
	elseif boardId == "Discovered" then
		return Formulas.discoveredCount(data)
	elseif boardId == "TotalCoins" then
		return math.floor(data.totalEarned)
	elseif boardId == "Luck" then
		return math.floor(Formulas.permanentLuck(data) * LUCK_SCALE)
	end
	return 0
end

local function formatValue(boardId: string, value: number): string
	if boardId == "TotalCoins" then
		return Format.money(value)
	elseif boardId == "Luck" then
		return Format.multiplier(value / LUCK_SCALE)
	end
	return Format.number(value)
end

local function getName(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		nameCache[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local result = if ok and typeof(name) == "string" then name else "Prisoner"
	nameCache[userId] = result
	return result
end

---------------------------------------------------------------------------
-- leaderstats
---------------------------------------------------------------------------

local function newValue(className: string, name: string, parent: Instance): ValueBase
	local value = Instance.new(className) :: ValueBase
	value.Name = name
	value.Parent = parent
	return value
end

local function updateLeaderstats(player: Player, data: Types.PlayerData)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local coins = stats:FindFirstChild("Coins")
	local rebirths = stats:FindFirstChild("Rebirths")
	local found = stats:FindFirstChild("Brainrots")
	local luck = stats:FindFirstChild("Luck")
	if coins and coins:IsA("StringValue") then
		coins.Value = Format.money(data.coins)
	end
	if rebirths and rebirths:IsA("IntValue") then
		rebirths.Value = data.rebirths
	end
	if found and found:IsA("IntValue") then
		found.Value = Formulas.discoveredCount(data)
	end
	if luck and luck:IsA("StringValue") then
		luck.Value = Format.multiplier(Formulas.permanentLuck(data))
	end
end

local function createLeaderstats(player: Player, data: Types.PlayerData)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	newValue("StringValue", "Coins", stats)
	newValue("IntValue", "Rebirths", stats)
	newValue("IntValue", "Brainrots", stats)
	newValue("StringValue", "Luck", stats)
	updateLeaderstats(player, data)
	stats.Parent = player

	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local current = DataService.get(player)
		local coins = stats:FindFirstChild("Coins")
		if current and coins and coins:IsA("StringValue") then
			coins.Value = Format.money(current.coins)
		end
	end)
end

---------------------------------------------------------------------------
-- Physical boards
---------------------------------------------------------------------------

local function writeStats(player: Player, data: Types.PlayerData)
	if not DataService.isSaving() then
		return
	end
	for boardId, store in stores do
		local value = math.clamp(statValue(boardId, data), 0, MAX_STORED)
		local ok, err = pcall(function()
			store:SetAsync(`Player_{player.UserId}`, value)
		end)
		if not ok then
			warn(`[Leaderboard] Couldn't save {boardId} for {player.Name}: {err}`)
		end
	end
end

local function topFromStore(boardId: string): { Entry }?
	local store = stores[boardId]
	if not store or not DataService.isSaving() then
		return nil
	end
	local ok, result = pcall(function()
		return store:GetSortedAsync(false, CONFIG.size):GetCurrentPage()
	end)
	if not ok then
		return nil
	end
	local entries = {}
	for _, item in result do
		local userId = tonumber(string.match(item.key, "%d+"))
		if userId then
			table.insert(entries, { userId = userId, name = getName(userId), value = item.value })
		end
	end
	return entries
end

local function topFromServer(boardId: string): { Entry }
	local entries = {}
	for player, data in DataService.getPlayers() do
		table.insert(entries, { userId = player.UserId, name = player.DisplayName, value = statValue(boardId, data) })
	end
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)
	return entries
end

local MEDALS = { "🥇", "🥈", "🥉" }

-- Global top scores merged with the live stats of everyone in this server, best first.
local function topEntries(boardId: string): { Entry }
	local byUser: { [number]: Entry } = {}
	local stored: { Entry } = topFromStore(boardId) or {}
	for _, entry in stored do
		byUser[entry.userId] = entry
	end
	for _, entry in topFromServer(boardId) do
		local existing = byUser[entry.userId]
		if not existing or entry.value > existing.value then
			byUser[entry.userId] = entry
		end
	end
	local entries = {}
	for _, entry in byUser do
		table.insert(entries, entry)
	end
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)
	return entries
end

local function refreshBoards()
	for boardId, board in MapService.boards do
		local entries = topEntries(boardId)
		for rank, row in board.rows do
			local entry = entries[rank]
			local medal = MEDALS[rank] or `#{rank}`
			if entry then
				row.Text = `{medal}  {entry.name}  <font color="#FFE066">{formatValue(boardId, entry.value)}</font>`
			else
				row.Text = `{medal}  ...`
			end
		end
	end
end

function LeaderboardService.init()
	DataService.Loaded:Connect(createLeaderstats)
	DataService.Changed:Connect(updateLeaderstats)
	DataService.Releasing:Connect(function(player, data)
		writeStats(player, data)
	end)

	if DataService.isSaving() then
		for _, board in CONFIG.boards do
			local ok, store = pcall(function()
				return DataStoreService:GetOrderedDataStore(board.store)
			end)
			if ok then
				stores[board.id] = store
			end
		end
	end
end

function LeaderboardService.start()
	task.spawn(function()
		while true do
			refreshBoards()
			task.wait(CONFIG.refreshInterval)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CONFIG.writeInterval)
			for player, data in DataService.getPlayers() do
				writeStats(player, data)
			end
		end
	end)
end

return LeaderboardService
