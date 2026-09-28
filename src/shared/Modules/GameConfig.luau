-- Every tuning number for the game in one place. Change values here to rebalance.

local GameConfig = {}

GameConfig.GAME_NAME = "PRISON BRAINROT"
GameConfig.TAGLINE = "ROLL FOR BRAINROTS, MAKE MONEY, AND UNLOCK THE PRISON!"

-- New players
GameConfig.STARTING_COINS = 100
GameConfig.STARTER_BRAINROT = "PotatoPrisoner"

-- Income: only your best Brainrots (up to your capacity) earn coins.
GameConfig.BASE_CAPACITY = 8
GameConfig.INCOME_INTERVAL = 1

-- Luck never goes above this, even with every bonus stacked, so rarities stay rare.
GameConfig.MAX_LUCK = 40

-- 3 identical Brainrots combine into 1 of the next variant.
GameConfig.COMBINE_COST = 3

GameConfig.ROLL = {
	-- Seconds the server waits between two rolls from the same player.
	minInterval = 1.2,
	-- Base length of the roll animation in seconds, before each rarity adds its own suspense.
	spinTime = 3.2,
}

-- Chance per roll at 1x luck for the rolled Brainrot to be Golden or Diamond.
GameConfig.VARIANT_CHANCES = {
	Golden = 0.05,
	Diamond = 0.005,
}
-- How strongly luck boosts the variant chance (luck ^ this).
GameConfig.VARIANT_LUCK_POWER = 0.3

-- Pity ("LUCKY ROLLS"): rolls without a Legendary or better raise the Legendary+ chance.
GameConfig.PITY = {
	minRarity = "Legendary",
	stages = {
		{ rolls = 50, multiplier = 2 },
		{ rolls = 100, multiplier = 4 },
	},
	-- At this many rolls the next roll is a guaranteed Legendary or better.
	guaranteeAt = 150,
}

GameConfig.DAILY_ROLL_COOLDOWN = 24 * 60 * 60

-- Free temporary luck boost anyone can claim from the HUD or the lobby pad.
GameConfig.FREE_BOOST = {
	multiplier = 1.5,
	duration = 5 * 60,
	cooldown = 15 * 60,
}

GameConfig.REBIRTH = {
	baseCost = 10_000_000_000,
	costGrowth = 3,
	luckPerRebirth = 0.10,
	-- Brainrots of this rarity and better survive a rebirth.
	keepMinRarity = "Rare",
}

GameConfig.EVENTS = {
	firstDelay = 90,
	minGap = 240,
	maxGap = 420,
	doubleIncomeMultiplier = 2,
	luckyHourMultiplier = 2,
	crazyRollSpeed = 2,
	prisonKingLuck = 3,
	escapedCount = 6,
	-- A caught escaped Brainrot pays this many seconds of your income (at least escapedMinReward).
	escapedRewardSeconds = 20,
	escapedMinReward = 250,
	list = {
		{
			id = "DoubleIncome",
			name = "🔥 DOUBLE INCOME 🔥",
			description = "Everyone earns 2x Coins!",
			duration = 60,
			weight = 3,
			color = Color3.fromRGB(255, 120, 40),
		},
		{
			id = "LuckyHour",
			name = "🍀 LUCKY HOUR 🍀",
			description = "Everyone gets 2x Luck!",
			duration = 120,
			weight = 3,
			color = Color3.fromRGB(70, 210, 90),
		},
		{
			id = "CrazyRolls",
			name = "🎰 CRAZY ROLLS 🎰",
			description = "Rolls are twice as fast!",
			duration = 90,
			weight = 2,
			color = Color3.fromRGB(255, 70, 200),
		},
		{
			id = "PrisonKing",
			name = "👑 THE PRISON KING APPEARS 👑",
			description = "Visit the King in Cell Block 1 for a free 3x lucky roll!",
			duration = 60,
			weight = 2,
			color = Color3.fromRGB(255, 200, 40),
		},
		{
			id = "EscapedBrainrots",
			name = "💀 ESCAPED BRAINROTS 💀",
			description = "Giant Brainrots escaped! Catch them for Coins!",
			duration = 60,
			weight = 2,
			color = Color3.fromRGB(140, 90, 255),
		},
	},
}

GameConfig.DATA = {
	storeName = "PrisonBrainrot_PlayerData_v1",
	autosaveInterval = 120,
	retries = 4,
	-- A session lock older than this belongs to a crashed server and can be taken over.
	lockTimeout = 5 * 60,
	lockWaitAttempts = 5,
	lockWaitSeconds = 4,
}

GameConfig.LEADERBOARD = {
	refreshInterval = 60,
	writeInterval = 120,
	size = 10,
	boards = {
		{ id = "Rebirths", title = "🏆 TOP REBIRTHS", store = "PB_Rebirths_v1" },
		{ id = "Discovered", title = "🧠 BRAINROTS FOUND", store = "PB_Discovered_v1" },
		{ id = "TotalCoins", title = "💰 TOTAL COINS", store = "PB_TotalCoins_v1" },
		{ id = "Luck", title = "🍀 LUCKIEST", store = "PB_Luck_v1" },
	},
}

GameConfig.CELL_COUNT = 10
GameConfig.CELL_DISPLAY_COUNT = 3

-- Remote rate limits: at most `count` calls per `per` seconds for each player.
GameConfig.RATE_LIMITS = {
	default = { count = 6, per = 2 },
	Roll = { count = 3, per = 2 },
}

-- Chat commands like /coins 1000000 for testing. They only ever work in Roblox Studio.
GameConfig.DEV_COMMANDS_IN_STUDIO = true

return GameConfig
