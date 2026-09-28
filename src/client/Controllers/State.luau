-- Holds the latest snapshot of this player's data from the server, plus a few client-only choices
-- (like which block the ROLL button uses). UI scripts read from here and listen to State.Changed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Events = require(ReplicatedStorage.Modules.Events)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local Net = require(ReplicatedStorage.Modules.Net)
local Signal = require(ReplicatedStorage.Modules.Signal)
local Types = require(ReplicatedStorage.Modules.Types)

local State = {}

-- Fires with the new state whenever the server sends one (or the selected block changes).
State.Changed = Signal.new()
-- Fires every time the coins attribute ticks.
State.CoinsChanged = Signal.new()

State.current = nil :: Types.State?
State.selectedAreaId = AreaData.FirstAreaId

local player = Players.LocalPlayer

function State.data(): Types.PlayerData?
	return if State.current then State.current.data else nil
end

function State.now(): number
	return workspace:GetServerTimeNow()
end

function State.coins(): number
	local coins = player:GetAttribute("Coins")
	if typeof(coins) == "number" then
		return coins
	end
	local data = State.data()
	return if data then data.coins else 0
end

function State.income(): number
	local income = player:GetAttribute("Income")
	if typeof(income) == "number" then
		return income
	end
	return if State.current then State.current.income else 0
end

function State.luck(): number
	local data = State.data()
	return if data then Formulas.personalLuck(data, State.now(), Events.luckMultiplier()) else 1
end

function State.selectedArea(): AreaData.Area
	return AreaData.ById[State.selectedAreaId] or AreaData.Areas[1]
end

function State.selectArea(areaId: string)
	local data = State.data()
	if AreaData.ById[areaId] and data and data.unlockedAreas[areaId] then
		State.selectedAreaId = areaId
		State.Changed:Fire(State.current)
	end
end

-- Moves the selection to the next / previous unlocked block.
function State.cycleArea(step: number)
	local data = State.data()
	if not data then
		return
	end
	local order = State.selectedArea().order
	for _ = 1, #AreaData.Areas do
		order = (order - 1 + step) % #AreaData.Areas + 1
		local area = AreaData.Areas[order]
		if data.unlockedAreas[area.id] then
			State.selectArea(area.id)
			return
		end
	end
end

function State.init()
	local previousBest = 0
	Net.event("State").OnClientEvent:Connect(function(state: Types.State)
		State.current = state
		-- Keep the selection valid, and jump to a block the moment it's unlocked.
		local best = Formulas.bestArea(state.data)
		if previousBest == 0 or best.order > previousBest or not state.data.unlockedAreas[State.selectedAreaId] then
			State.selectedAreaId = best.id
		end
		previousBest = best.order
		State.Changed:Fire(state)
	end)
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		State.CoinsChanged:Fire(State.coins())
	end)
end

return State
