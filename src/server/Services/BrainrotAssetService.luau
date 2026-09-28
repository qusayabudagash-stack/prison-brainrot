--!strict
-- Loads the Creator Store models listed in BrainrotAssetIds into ReplicatedStorage.BrainrotAssets
-- at server start, so every Brainrot built afterwards (cells, the roll machine, viewports) uses
-- them. Runs first, before the map is built. Models already in the folder (inserted in Studio)
-- are left alone. Any model that fails to load keeps its built-in design.
--
-- InsertService can only load models the game's owner has: "Get" each free model on its Creator
-- Store page with the account or group that owns the game.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotAssetIds = require(ReplicatedStorage.Modules.BrainrotAssetIds)
local BrainrotAssets = require(ReplicatedStorage.Modules.BrainrotAssets)

local BrainrotAssetService = {}

-- Seconds to wait for the models before building the map anyway.
local TIMEOUT = 10

-- Loads every listed model that isn't in the folder yet. Returns how many loaded and which failed.
function BrainrotAssetService.loadAll(timeout: number?): (number, { string })
	local folder = BrainrotAssets.folder()
	local pending, loaded, failed = 0, 0, {}
	for brainrotId, entry in BrainrotAssetIds do
		if folder:FindFirstChild(brainrotId) then
			continue
		end
		pending += 1
		task.spawn(function()
			local ok, result = pcall(InsertService.LoadAsset, InsertService, entry.assetId)
			local model = if ok then BrainrotAssets.prepare(brainrotId, { result :: Instance }) else nil
			if model then
				model.Parent = folder
				loaded += 1
			else
				table.insert(failed, `{brainrotId} ({entry.assetId})`)
			end
			pending -= 1
		end)
	end
	local deadline = os.clock() + (timeout or TIMEOUT)
	while pending > 0 and os.clock() < deadline do
		task.wait(0.05)
	end
	return loaded, failed
end

function BrainrotAssetService.init()
	local loaded, failed = BrainrotAssetService.loadAll()
	if #failed > 0 then
		table.sort(failed)
		warn(
			`BrainrotAssetService: {#failed} model(s) could not load and use the built-in design instead: `
				.. table.concat(failed, ", ")
				.. ". Make sure the game's owner has each free model (Get it on its Creator Store page)."
		)
	end
	if loaded > 0 then
		print(`BrainrotAssetService: loaded {loaded} Creator Store model(s)`)
	end
end

return BrainrotAssetService
