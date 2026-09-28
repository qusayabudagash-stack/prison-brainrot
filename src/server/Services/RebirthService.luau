-- Rebirth: trade your coins, upgrades, blocks and weaker Brainrots for permanent luck.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnnouncementService = require(script.Parent.AnnouncementService)
local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotService = require(script.Parent.BrainrotService)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Guard = require(script.Parent.Parent.ServerModules.Guard)

local RebirthService = {}

function RebirthService.init()
	Guard.invoke("Rebirth", function(player, data)
		local cost = Formulas.rebirthCost(data.rebirths)
		if data.coins < cost then
			return Guard.fail(`You need {Format.money(cost)} to rebirth!`)
		end

		data.coins = GameConfig.STARTING_COINS
		for upgradeId in data.upgrades do
			data.upgrades[upgradeId] = 0
		end
		data.unlockedAreas = { [AreaData.FirstAreaId] = true }

		local keepOrder = BrainrotData.RarityById[GameConfig.REBIRTH.keepMinRarity].order
		for brainrotId in data.brainrots do
			local brainrot = BrainrotData.ById[brainrotId]
			if brainrot and BrainrotData.RarityById[brainrot.rarity].order < keepOrder then
				data.brainrots[brainrotId] = nil
			end
		end
		if Formulas.totalOwned(data) == 0 then
			BrainrotService.grant(data, GameConfig.STARTER_BRAINROT, "Normal", 1)
		end
		data.rebirths += 1

		local bonus = math.floor(data.rebirths * GameConfig.REBIRTH.luckPerRebirth * 100 + 0.5)
		AnnouncementService.announce(
			`🔄 {player.DisplayName} reached REBIRTH {data.rebirths}! (+{bonus}% Luck forever)`,
			{ color = Color3.fromRGB(120, 200, 255), duration = 5, sound = "Rebirth", style = "big" }
		)
		DataService.changed(player, "rebirth")

		-- Blocks are locked again, so send the player back to the start.
		task.delay(1.5, function()
			if player.Parent then
				pcall(function()
					player:LoadCharacterAsync()
				end)
			end
		end)
		return { ok = true, rebirths = data.rebirths }
	end)
end

return RebirthService
