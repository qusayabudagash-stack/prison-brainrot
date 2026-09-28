--!strict
-- Prepares Creator Store models for use as Brainrots: keeps only what they look like, and files
-- them in ReplicatedStorage.BrainrotAssets named after the Brainrot id, where BrainrotModel picks
-- them up instead of the built-in design. Shared by BrainrotAssetService (runtime loading) and
-- the Studio command-bar script (tools/studio/insert_brainrot_models.lua).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotAssetIds = require(script.Parent.BrainrotAssetIds)

local BrainrotAssets = {}

BrainrotAssets.FOLDER_NAME = "BrainrotAssets"

-- Anything that runs code, makes noise, or can be interacted with. Free models can hide
-- backdoors in scripts, so every script is removed, however harmless it looks.
local REMOVE = {
	"LuaSourceContainer", -- Script, LocalScript, ModuleScript
	"Sound",
	"ClickDetector",
	"ProximityPrompt",
	"DragDetector",
	"Humanoid",
	"AnimationController",
	"Tool",
	"BillboardGui",
	"ScreenGui",
	"RemoteEvent",
	"RemoteFunction",
	"BindableEvent",
	"BindableFunction",
	"ValueBase",
	"Configuration",
	"Camera",
	"ForceField",
	"Explosion",
}

-- The folder the game reads overrides from (created if missing).
function BrainrotAssets.folder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(BrainrotAssets.FOLDER_NAME)
	if not folder then
		local created = Instance.new("Folder")
		created.Name = BrainrotAssets.FOLDER_NAME
		created.Parent = ReplicatedStorage
		folder = created
	end
	return folder :: Folder
end

-- Removes everything in REMOVE from `root`'s descendants. Returns how many instances went.
function BrainrotAssets.sanitize(root: Instance): number
	local doomed = {}
	for _, descendant in root:GetDescendants() do
		for _, className in REMOVE do
			if descendant:IsA(className) then
				table.insert(doomed, descendant)
				break
			end
		end
	end
	local removed = 0
	for _, instance in doomed do
		-- A removed ancestor already took its children with it
		if instance.Parent then
			instance:Destroy()
			removed += 1
		end
	end
	return removed
end

-- Wraps loaded instances into a clean Model named after the Brainrot, ready for BrainrotModel.
-- `loaded` is what InsertService:LoadAsset or game:GetObjects returned.
function BrainrotAssets.prepare(brainrotId: string, loaded: { Instance }): Model?
	local model = Instance.new("Model")
	model.Name = brainrotId
	for _, instance in loaded do
		-- LoadAsset wraps the asset in a Model; unwrap one level so parts sit directly inside
		if instance:IsA("Model") and #loaded == 1 then
			for _, child in instance:GetChildren() do
				child.Parent = model
			end
			instance:Destroy()
		else
			(instance :: Instance).Parent = model
		end
	end
	BrainrotAssets.sanitize(model)
	local hasParts = false
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			hasParts = true
			descendant.Anchored = true
		end
	end
	if not hasParts then
		model:Destroy()
		return nil
	end
	local entry = BrainrotAssetIds[brainrotId]
	if entry then
		-- As text: asset ids are too long to survive every number conversion exactly
		model:SetAttribute("AssetId", string.format("%d", entry.assetId))
		model:SetAttribute("Creator", entry.creator)
		if entry.facing then
			model:SetAttribute("FacingYaw", entry.facing)
		end
	end
	return model
end

return BrainrotAssets
