-- Awards achievements (each gives permanent luck) whenever a player's stats cross a goal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementData = require(ReplicatedStorage.Modules.AchievementData)
local AnnouncementService = require(script.Parent.AnnouncementService)
local DataService = require(script.Parent.DataService)
local Formulas = require(ReplicatedStorage.Modules.Formulas)

local AchievementService = {}

function AchievementService.check(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local earned = {}
	for _, achievement in AchievementData.Achievements do
		if
			not data.achievements[achievement.id]
			and Formulas.achievementStat(data, achievement.stat) >= achievement.goal
		then
			data.achievements[achievement.id] = true
			table.insert(earned, achievement)
		end
	end
	if #earned == 0 then
		return
	end
	for _, achievement in earned do
		local percent = math.floor(achievement.luck * 100 + 0.5)
		AnnouncementService.notify(
			player,
			`🏆 {achievement.emoji} {achievement.name}! +{percent}% Luck forever`,
			"achievement"
		)
	end
	DataService.changed(player, "achievements")
end

function AchievementService.init()
	DataService.Loaded:Connect(function(player)
		AchievementService.check(player)
	end)
end

return AchievementService
