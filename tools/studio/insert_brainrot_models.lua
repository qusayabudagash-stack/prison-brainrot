-- Inserts the Creator Store models listed in ReplicatedStorage.Modules.BrainrotAssetIds into
-- ReplicatedStorage.BrainrotAssets, with every script removed, so they are saved with your place.
--
-- How to use: open the place in Roblox Studio with Rojo connected, open View > Command Bar, paste
-- this whole file into it and press Enter. Then save the place (File > Save). Run it again any time
-- you add entries; Brainrots that already have a model are skipped. To drop a model, delete it from
-- ReplicatedStorage.BrainrotAssets and remove its entry from BrainrotAssetIds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ids = require(ReplicatedStorage.Modules.BrainrotAssetIds)
local assets = require(ReplicatedStorage.Modules.BrainrotAssets)

local folder = assets.folder()
local added, skipped, failed, unreviewed = 0, 0, {}, {}
for brainrotId, entry in pairs(ids) do
	if folder:FindFirstChild(brainrotId) then
		skipped += 1
	else
		local ok, objects = pcall(function()
			return game:GetObjects("rbxassetid://" .. string.format("%d", entry.assetId))
		end)
		local model = if ok then assets.prepare(brainrotId, objects) else nil
		if model then
			model.Parent = folder
			added += 1
			if not entry.reviewed then
				table.insert(unreviewed, brainrotId)
			end
		else
			table.insert(failed, `{brainrotId} ({entry.assetId})`)
		end
	end
end
print(`Brainrot models: {added} added, {skipped} already there, {#failed} failed`)
if #unreviewed > 0 then
	print("Please look at these (no preview existed, nobody has checked them yet): " .. table.concat(unreviewed, ", "))
end
if #failed > 0 then
	warn("Could not insert: " .. table.concat(failed, ", "))
end
