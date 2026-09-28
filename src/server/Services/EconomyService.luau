-- Coins: passive income every second, spending, and rewards. The only code that changes coins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Events = require(ReplicatedStorage.Modules.Events)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Types = require(ReplicatedStorage.Modules.Types)

local EconomyService = {}

-- Income per second before events, recalculated whenever a player's data changes.
local baseIncome: { [Player]: number } = {}

local function publish(player: Player, data: Types.PlayerData)
	player:SetAttribute("Coins", data.coins)
	player:SetAttribute("Income", EconomyService.getIncome(player))
	player:SetAttribute("TotalEarned", data.totalEarned)
end

function EconomyService.getIncome(player: Player): number
	return (baseIncome[player] or 0) * Events.incomeMultiplier()
end

function EconomyService.add(player: Player, amount: number)
	local data = DataService.get(player)
	if not data or amount ~= amount or amount <= 0 then
		return
	end
	data.coins += amount
	data.totalEarned += amount
	publish(player, data)
end

-- Takes coins if the player can afford it. Returns false (and takes nothing) otherwise.
function EconomyService.trySpend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or amount ~= amount or amount < 0 or data.coins < amount then
		return false
	end
	data.coins -= amount
	publish(player, data)
	return true
end

local function refresh(player: Player, data: Types.PlayerData)
	baseIncome[player] = Formulas.baseIncome(data)
	publish(player, data)
end

function EconomyService.init()
	DataService.Loaded:Connect(refresh)
	DataService.Changed:Connect(refresh)
	Players.PlayerRemoving:Connect(function(player)
		baseIncome[player] = nil
	end)
	ReplicatedStorage:GetAttributeChangedSignal("EventId"):Connect(function()
		for player, data in DataService.getPlayers() do
			publish(player, data)
		end
	end)
end

function EconomyService.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.INCOME_INTERVAL)
			local multiplier = Events.incomeMultiplier()
			for player, data in DataService.getPlayers() do
				local income = (baseIncome[player] or 0) * multiplier * GameConfig.INCOME_INTERVAL
				if income > 0 then
					data.coins += income
					data.totalEarned += income
				end
				publish(player, data)
			end
		end
	end)
end

return EconomyService
