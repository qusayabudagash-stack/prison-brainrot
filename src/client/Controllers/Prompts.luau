-- Reacts to the E-prompts placed around the map (the server tags each with an "Action" attribute).

local ProximityPromptService = game:GetService("ProximityPromptService")

local Remote = require(script.Parent.Remote)
local RollUI = require(script.Parent.Parent.UI.RollUI)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local Prompts = {}

function Prompts.init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local action = prompt:GetAttribute("Action")
		local areaId = prompt:GetAttribute("AreaId")
		if action == "Roll" and typeof(areaId) == "string" then
			State.selectArea(areaId)
			RollUI.requestRoll(areaId)
		elseif action == "Unlock" and typeof(areaId) == "string" then
			Remote.call("UnlockArea", areaId)
		elseif action == "Shop" then
			Theme.openPanel("Shop", "Cosmetics")
		elseif action == "Upgrades" then
			Theme.openPanel("Shop", "Upgrades")
		elseif action == "Book" then
			Theme.openPanel("Collection")
		elseif action == "Rebirth" then
			Theme.openPanel("Rebirth")
		elseif action == "FreeBoost" then
			Remote.call("ClaimFreeBoost")
		elseif action == "DailyRoll" then
			RollUI.requestDailyRoll()
		end
	end)
end

return Prompts
