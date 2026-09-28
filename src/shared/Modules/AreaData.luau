-- The prison blocks, in unlock order. Later blocks cost more but roll with more luck,
-- and the best ones skip the lowest rarities entirely.

export type Area = {
	id: string,
	order: number,
	name: string,
	emoji: string,
	unlockCost: number,
	rollCost: number,
	-- Multiplies the player's luck for rolls at this block's machine.
	luck: number,
	-- Rarities below this can't be rolled here.
	minRarity: string,
	floorColor: Color3,
	wallColor: Color3,
	accentColor: Color3,
}

local C = Color3.fromRGB

local AreaData = {}

AreaData.Areas = {
	{
		id = "CellBlock1",
		order = 1,
		name = "CELL BLOCK 1",
		emoji = "🏠",
		unlockCost = 0,
		rollCost = 100,
		luck = 1,
		minRarity = "Common",
		floorColor = C(255, 214, 150),
		wallColor = C(255, 150, 90),
		accentColor = C(255, 90, 60),
	},
	{
		id = "CellBlock2",
		order = 2,
		name = "CELL BLOCK 2",
		emoji = "🔒",
		unlockCost = 15_000,
		rollCost = 1_000,
		luck = 1.5,
		minRarity = "Common",
		floorColor = C(170, 215, 255),
		wallColor = C(90, 150, 255),
		accentColor = C(40, 90, 230),
	},
	{
		id = "MaxSecurity",
		order = 3,
		name = "MAXIMUM SECURITY",
		emoji = "⚠️",
		unlockCost = 500_000,
		rollCost = 15_000,
		luck = 2.5,
		minRarity = "Uncommon",
		floorColor = C(255, 240, 120),
		wallColor = C(255, 200, 40),
		accentColor = C(40, 40, 40),
	},
	{
		id = "DeathRow",
		order = 4,
		name = "DEATH ROW",
		emoji = "💀",
		unlockCost = 25_000_000,
		rollCost = 400_000,
		luck = 4,
		minRarity = "Rare",
		floorColor = C(200, 160, 255),
		wallColor = C(140, 80, 230),
		accentColor = C(120, 255, 120),
	},
	{
		id = "AlienBlock",
		order = 5,
		name = "ALIEN BLOCK",
		emoji = "👽",
		unlockCost = 1_000_000_000,
		rollCost = 10_000_000,
		luck = 7,
		minRarity = "Rare",
		floorColor = C(170, 255, 150),
		wallColor = C(60, 210, 110),
		accentColor = C(255, 90, 230),
	},
	{
		id = "SecretBlock",
		order = 6,
		name = "SECRET BLOCK",
		emoji = "🌌",
		unlockCost = 15_000_000_000,
		rollCost = 150_000_000,
		luck = 12,
		minRarity = "Epic",
		floorColor = C(70, 60, 140),
		wallColor = C(40, 30, 100),
		accentColor = C(255, 120, 255),
	},
} :: { Area }

AreaData.ById = {} :: { [string]: Area }
for _, area in AreaData.Areas do
	AreaData.ById[area.id] = area
end

AreaData.FirstAreaId = AreaData.Areas[1].id

return AreaData
