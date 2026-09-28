-- Sends each player a snapshot of their data whenever it changes (batched to once per frame).
-- Coins tick every second, so they travel as the "Coins" player attribute instead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Events = require(ReplicatedStorage.Modules.Events)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local Net = require(ReplicatedStorage.Modules.Net)
local RateLimiter = require(script.Parent.Parent.ServerModules.RateLimiter)

local StateService = {}

local pending: { [Player]: boolean } = {}

function StateService.push(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		local data = DataService.get(player)
		if not data or not player.Parent then
			return
		end
		data.luck = Formulas.permanentLuck(data)
		local copy = table.clone(data) :: any
		copy.meta = nil
		local baseIncome = Formulas.baseIncome(data)
		Net.event("State"):FireClient(player, {
			data = copy,
			income = baseIncome * Events.incomeMultiplier(),
			baseIncome = baseIncome,
			capacity = Formulas.capacity(data),
			permanentLuck = data.luck,
			serverTime = workspace:GetServerTimeNow(),
		})
	end)
end

function StateService.init()
	DataService.Loaded:Connect(StateService.push)
	DataService.Changed:Connect(StateService.push)

	-- Income and luck on the HUD change when an event starts or ends.
	ReplicatedStorage:GetAttributeChangedSignal("EventId"):Connect(function()
		for _, player in Players:GetPlayers() do
			StateService.push(player)
		end
	end)

	local limiter = RateLimiter.new(2, 5)
	Net.event("CompleteTutorial").OnServerEvent:Connect(function(player)
		local data = DataService.get(player)
		if data and not data.tutorialDone and limiter:allow(player) then
			data.tutorialDone = true
			DataService.changed(player, "tutorial")
		end
	end)
end

return StateService
