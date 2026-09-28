-- Cell cosmetics (bought with coins) and the free temporary luck boost.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnnouncementService = require(script.Parent.AnnouncementService)
local CosmeticData = require(ReplicatedStorage.Modules.CosmeticData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local Format = require(ReplicatedStorage.Modules.Format)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Guard = require(script.Parent.Parent.ServerModules.Guard)

local ShopService = {}

function ShopService.init()
	Guard.invoke("BuyCosmetic", function(player, data, cosmeticId)
		if not Guard.isKey(cosmeticId, CosmeticData.ById) then
			return Guard.fail("That item doesn't exist.")
		end
		local cosmetic = CosmeticData.ById[cosmeticId]
		if data.cosmetics[cosmeticId] ~= nil then
			return Guard.fail(`You already own the {cosmetic.name}!`)
		end
		if not EconomyService.trySpend(player, cosmetic.price) then
			return Guard.fail(`You need {Format.money(cosmetic.price)}!`)
		end
		data.cosmetics[cosmeticId] = true
		AnnouncementService.notify(player, `{cosmetic.emoji} {cosmetic.name} added to your cell!`, "success")
		DataService.changed(player, "cosmetics")
		return { ok = true }
	end)

	Guard.invoke("ToggleCosmetic", function(player, data, cosmeticId)
		if not Guard.isKey(cosmeticId, CosmeticData.ById) or data.cosmetics[cosmeticId] == nil then
			return Guard.fail("You don't own that item.")
		end
		data.cosmetics[cosmeticId] = not data.cosmetics[cosmeticId]
		DataService.changed(player, "cosmetics")
		return { ok = true, shown = data.cosmetics[cosmeticId] }
	end)

	Guard.invoke("ClaimFreeBoost", function(player, data)
		local now = os.time()
		if now < data.freeBoostReadyAt then
			return Guard.fail(`Free luck is ready in {Format.time(data.freeBoostReadyAt - now)}`)
		end
		local boost = GameConfig.FREE_BOOST
		data.boostUntil = now + boost.duration
		data.freeBoostReadyAt = now + boost.cooldown
		AnnouncementService.notify(
			player,
			`🍀 LUCK BOOST! {boost.multiplier}x Luck for {Format.time(boost.duration)}`,
			"success"
		)
		DataService.changed(player, "boost")
		return { ok = true }
	end)
end

return ShopService
