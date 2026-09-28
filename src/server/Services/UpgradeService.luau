-- Coin upgrades: income, luck, roll discount, capacity and movement speed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local Guard = require(script.Parent.Parent.ServerModules.Guard)
local UpgradeData = require(ReplicatedStorage.Modules.UpgradeData)

local UpgradeService = {}

local function applySpeed(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		humanoid.WalkSpeed = Formulas.walkSpeed(data)
	end
end

function UpgradeService.init()
	Guard.invoke("BuyUpgrade", function(player, data, upgradeId)
		if not Guard.isKey(upgradeId, UpgradeData.ById) then
			return Guard.fail("That upgrade doesn't exist.")
		end
		local upgrade = UpgradeData.ById[upgradeId]
		local level = data.upgrades[upgradeId] or 0
		if level >= upgrade.maxLevel then
			return Guard.fail(`{upgrade.name} is already MAXED!`)
		end
		local cost = UpgradeData.cost(upgradeId, level)
		if not EconomyService.trySpend(player, cost) then
			return Guard.fail(`You need {Format.money(cost)}!`)
		end
		data.upgrades[upgradeId] = level + 1
		DataService.changed(player, "upgrade")
		return { ok = true, level = level + 1 }
	end)

	DataService.Loaded:Connect(applySpeed)
	DataService.Changed:Connect(applySpeed)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			applySpeed(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return UpgradeService
