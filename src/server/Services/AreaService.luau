-- Unlocking prison blocks with coins, in order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementService = require(script.Parent.AchievementService)
local AnnouncementService = require(script.Parent.AnnouncementService)
local AreaData = require(ReplicatedStorage.Modules.AreaData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local Format = require(ReplicatedStorage.Modules.Format)
local Guard = require(script.Parent.Parent.ServerModules.Guard)

local AreaService = {}

function AreaService.init()
	Guard.invoke("UnlockArea", function(player, data, areaId)
		if not Guard.isKey(areaId, AreaData.ById) then
			return Guard.fail("That block doesn't exist.")
		end
		local area = AreaData.ById[areaId]
		if data.unlockedAreas[area.id] then
			return Guard.fail(`{area.name} is already open!`)
		end
		local previous = AreaData.Areas[area.order - 1]
		if previous and not data.unlockedAreas[previous.id] then
			return Guard.fail(`Unlock {previous.name} first!`)
		end
		if not EconomyService.trySpend(player, area.unlockCost) then
			return Guard.fail(`You need {Format.money(area.unlockCost)} to unlock {area.name}!`)
		end
		data.unlockedAreas[area.id] = true
		AnnouncementService.notify(player, `🔓 {area.emoji} {area.name} UNLOCKED! Better rolls await!`, "unlock")
		if area.order >= 4 then
			AnnouncementService.announce(
				`🔓 {player.DisplayName} unlocked {area.emoji} {area.name}!`,
				{ duration = 4 }
			)
		end
		DataService.changed(player, "area")
		AchievementService.check(player)
		return { ok = true, areaId = area.id }
	end)
end

return AreaService
