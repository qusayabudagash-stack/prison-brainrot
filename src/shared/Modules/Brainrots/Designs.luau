-- Visual designs for every Brainrot, gathered from one module per rarity tier.
-- Each design builds one character with the Kit, facing -Z, feet on y = 0, and returns its main
-- body part. Gameplay data (rarity, income...) lives in BrainrotData; these modules are only looks.

local Kit = require(script.Parent.Kit)

local Designs: { [string]: (Kit.Kit) -> BasePart } = {}

for _, tier in
	{
		script.Parent.Common,
		script.Parent.Uncommon,
		script.Parent.Rare,
		script.Parent.Epic,
		script.Parent.Legendary,
		script.Parent.Mythic,
		script.Parent.Divine,
		script.Parent.Secret,
	}
do
	for id, design in require(tier) :: any do
		Designs[id] = design
	end
end

-- TEMPORARY while the roster is being rebuilt: a renamed Brainrot without its own design yet
-- borrows the design of the id it replaced.
local BrainrotData = require(script.Parent.Parent.BrainrotData)
for oldId, newId in BrainrotData.LegacyIds do
	if not Designs[newId] then
		Designs[newId] = Designs[oldId]
	end
end

return Designs
