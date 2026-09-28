-- Chat commands for testing in Roblox Studio only. They never load in a live game.
--   /coins 1000000      add coins
--   /event LuckyHour    start an event (DoubleIncome, LuckyHour, CrazyRolls, PrisonKing, EscapedBrainrots)
--   /give PrisonKing Golden   give a Brainrot (variant optional)
--   /pity 149           set the pity counter
--   /resetdaily         make the daily free roll ready again

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local AnnouncementService = require(script.Parent.AnnouncementService)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotService = require(script.Parent.BrainrotService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local EventService = require(script.Parent.EventService)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local DevCommandService = {}

type Command = (player: Player, args: { string }) -> string

local COMMANDS: { [string]: Command } = {
	coins = function(player, args)
		local amount = tonumber(args[1]) or 1_000_000
		EconomyService.add(player, amount)
		return `Added {amount} coins`
	end,
	event = function(_player, args)
		local id = args[1] or "LuckyHour"
		return if EventService.trigger(id)
			then `Started {id}`
			else `Couldn't start {id} (unknown, or an event is running)`
	end,
	give = function(player, args)
		local id = args[1] or ""
		local variant = args[2] or "Normal"
		local data = DataService.get(player)
		if not data or not BrainrotData.ById[id] or not BrainrotData.VariantById[variant] then
			return "Usage: /give <BrainrotId> [Normal|Golden|Diamond]"
		end
		BrainrotService.grant(data, id, variant, 1)
		DataService.changed(player, "brainrots")
		return `Gave {BrainrotData.displayName(id, variant)}`
	end,
	pity = function(player, args)
		local data = DataService.get(player)
		if not data then
			return "No data"
		end
		data.pity = tonumber(args[1]) or 0
		DataService.changed(player, "pity")
		return `Pity set to {data.pity}`
	end,
	resetdaily = function(player)
		local data = DataService.get(player)
		if not data then
			return "No data"
		end
		data.lastDailyRoll = 0
		data.freeBoostReadyAt = 0
		DataService.changed(player, "daily")
		return "Daily roll and free luck are ready"
	end,
}

function DevCommandService.init()
	if not (RunService:IsStudio() and GameConfig.DEV_COMMANDS_IN_STUDIO) then
		return
	end
	for name, run in COMMANDS do
		local command = Instance.new("TextChatCommand")
		command.Name = `Dev_{name}`
		command.PrimaryAlias = `/{name}`
		command.Triggered:Connect(function(source, text)
			local player = Players:GetPlayerByUserId(source.UserId)
			if not player then
				return
			end
			local args = string.split(text, " ")
			table.remove(args, 1)
			AnnouncementService.notify(player, `[DEV] {run(player, args)}`, "info")
		end)
		command.Parent = TextChatService
	end
	print("[DevCommands] Studio test commands: /coins /event /give /pity /resetdaily")
end

return DevCommandService
