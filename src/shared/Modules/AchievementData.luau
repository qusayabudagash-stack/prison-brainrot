-- Gameplay achievements. Each one earned adds permanent luck.

local BrainrotData = require(script.Parent.BrainrotData)

export type Achievement = {
	id: string,
	name: string,
	emoji: string,
	description: string,
	-- Which player stat is checked: rolls, discovered, bestRarity, golden, diamond or areas.
	stat: string,
	goal: number,
	luck: number,
}

local AchievementData = {}

AchievementData.Achievements = {
	{
		id = "Rolls10",
		name = "Rookie Roller",
		emoji = "🎰",
		description = "Roll 10 times",
		stat = "rolls",
		goal = 10,
		luck = 0.02,
	},
	{
		id = "Rolls100",
		name = "Roll Addict",
		emoji = "🎰",
		description = "Roll 100 times",
		stat = "rolls",
		goal = 100,
		luck = 0.05,
	},
	{
		id = "Rolls1000",
		name = "Roll Legend",
		emoji = "🎰",
		description = "Roll 1,000 times",
		stat = "rolls",
		goal = 1000,
		luck = 0.1,
	},
	{
		id = "Found5",
		name = "Collector",
		emoji = "🧠",
		description = "Discover 5 Brainrots",
		stat = "discovered",
		goal = 5,
		luck = 0.03,
	},
	{
		id = "Found15",
		name = "Brainrot Expert",
		emoji = "🧠",
		description = "Discover 15 Brainrots",
		stat = "discovered",
		goal = 15,
		luck = 0.05,
	},
	{
		id = "Found25",
		name = "Brainrot Master",
		emoji = "🧠",
		description = "Discover 25 Brainrots",
		stat = "discovered",
		goal = 25,
		luck = 0.08,
	},
	{
		id = "FoundAll",
		name = "Complete Book",
		emoji = "📖",
		description = "Discover every Brainrot",
		stat = "discovered",
		goal = BrainrotData.Count,
		luck = 0.25,
	},
	{
		id = "Legendary",
		name = "Legendary Luck",
		emoji = "🔥",
		description = "Find a Legendary Brainrot",
		stat = "bestRarity",
		goal = 5,
		luck = 0.05,
	},
	{
		id = "Mythic",
		name = "Mythic Moment",
		emoji = "🌌",
		description = "Find a Mythic Brainrot",
		stat = "bestRarity",
		goal = 6,
		luck = 0.08,
	},
	{
		id = "Divine",
		name = "Divine Intervention",
		emoji = "☄️",
		description = "Find a Divine Brainrot",
		stat = "bestRarity",
		goal = 7,
		luck = 0.1,
	},
	{
		id = "Golden",
		name = "Shiny!",
		emoji = "⭐",
		description = "Get a Golden Brainrot",
		stat = "golden",
		goal = 1,
		luck = 0.03,
	},
	{
		id = "Diamond",
		name = "Diamond Hands",
		emoji = "💎",
		description = "Get a Diamond Brainrot",
		stat = "diamond",
		goal = 1,
		luck = 0.05,
	},
	{
		id = "AllBlocks",
		name = "Prison Explorer",
		emoji = "🗺️",
		description = "Unlock every prison block",
		stat = "areas",
		goal = 6,
		luck = 0.1,
	},
} :: { Achievement }

AchievementData.ById = {} :: { [string]: Achievement }
for _, achievement in AchievementData.Achievements do
	AchievementData.ById[achievement.id] = achievement
end

return AchievementData
