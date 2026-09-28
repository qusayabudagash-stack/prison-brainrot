-- Every rarity, its roll odds, and every Brainrot in the game.
-- Edit `chance` to change the base odds (they are percentages and should add up to 100).

local BrainrotData = {}

export type Rarity = {
	id: string,
	name: string,
	order: number,
	-- Base chance in percent at 1x luck.
	chance: number,
	-- How strongly luck boosts this rarity: weight = chance * luck ^ luckPower. Rising powers mean luck
	-- always shifts weight toward rarer tiers, even in blocks that skip the low rarities.
	luckPower: number,
	color: Color3,
	-- Extra seconds of suspense added to the roll animation.
	revealExtra: number,
	-- Tell the whole server when someone rolls this rarity.
	announce: boolean,
}

export type Brainrot = {
	id: string,
	name: string,
	emoji: string,
	rarity: string,
	income: number,
	description: string,
}

export type Variant = {
	id: string,
	name: string,
	prefix: string,
	multiplier: number,
	color: Color3,
}

BrainrotData.Rarities = {
	{
		id = "Common",
		name = "COMMON",
		order = 1,
		chance = 60,
		luckPower = 0,
		color = Color3.fromRGB(200, 200, 205),
		revealExtra = 0,
		announce = false,
	},
	{
		id = "Uncommon",
		name = "UNCOMMON",
		order = 2,
		chance = 25,
		luckPower = 0.3,
		color = Color3.fromRGB(90, 225, 100),
		revealExtra = 0,
		announce = false,
	},
	{
		id = "Rare",
		name = "RARE",
		order = 3,
		chance = 10,
		luckPower = 0.6,
		color = Color3.fromRGB(60, 150, 255),
		revealExtra = 0.4,
		announce = false,
	},
	{
		id = "Epic",
		name = "EPIC",
		order = 4,
		chance = 4,
		luckPower = 0.85,
		color = Color3.fromRGB(175, 80, 255),
		revealExtra = 0.8,
		announce = false,
	},
	{
		id = "Legendary",
		name = "LEGENDARY",
		order = 5,
		chance = 0.8,
		luckPower = 1,
		color = Color3.fromRGB(255, 185, 30),
		revealExtra = 1.6,
		announce = false,
	},
	{
		id = "Mythic",
		name = "MYTHIC",
		order = 6,
		chance = 0.18,
		luckPower = 1.1,
		color = Color3.fromRGB(255, 60, 120),
		revealExtra = 2.4,
		announce = true,
	},
	{
		id = "Divine",
		name = "DIVINE",
		order = 7,
		chance = 0.019,
		luckPower = 1.2,
		color = Color3.fromRGB(110, 255, 235),
		revealExtra = 3,
		announce = true,
	},
	{
		id = "Secret",
		name = "SECRET",
		order = 8,
		chance = 0.001,
		luckPower = 0.9,
		color = Color3.fromRGB(40, 20, 60),
		revealExtra = 4,
		announce = true,
	},
} :: { Rarity }

BrainrotData.Variants = {
	{ id = "Normal", name = "", prefix = "", multiplier = 1, color = Color3.fromRGB(255, 255, 255) },
	{ id = "Golden", name = "Golden", prefix = "⭐ ", multiplier = 2, color = Color3.fromRGB(255, 205, 50) },
	{ id = "Diamond", name = "Diamond", prefix = "💎 ", multiplier = 5, color = Color3.fromRGB(140, 235, 255) },
} :: { Variant }

BrainrotData.Brainrots = {
	-- COMMON
	{
		id = "PotatoPrisoner",
		name = "Potato Prisoner",
		emoji = "🥔",
		rarity = "Common",
		income = 5,
		description = "Arrested for being a couch potato.",
	},
	{
		id = "ChickenThief",
		name = "Chicken Thief",
		emoji = "🐔",
		rarity = "Common",
		income = 6,
		description = "Stole 400 eggs. Says they were his.",
	},
	{
		id = "BananaJailbird",
		name = "Banana Jailbird",
		emoji = "🍌",
		rarity = "Common",
		income = 7,
		description = "Slipped out of three prisons.",
	},
	{
		id = "SockSnatcher",
		name = "Sock Snatcher",
		emoji = "🧦",
		rarity = "Common",
		income = 8,
		description = "Only ever steals the left sock.",
	},
	{
		id = "BreadBandit",
		name = "Bread Bandit",
		emoji = "🍞",
		rarity = "Common",
		income = 9,
		description = "A loaf on the run.",
	},

	-- UNCOMMON
	{
		id = "PrisonFrog",
		name = "Prison Frog",
		emoji = "🐸",
		rarity = "Uncommon",
		income = 15,
		description = "Hops over every fence. Ribbit.",
	},
	{
		id = "EscapeDuck",
		name = "Escape Duck",
		emoji = "🦆",
		rarity = "Uncommon",
		income = 18,
		description = "Swam out through the prison bathtub.",
	},
	{
		id = "PizzaCriminal",
		name = "Pizza Criminal",
		emoji = "🍕",
		rarity = "Uncommon",
		income = 22,
		description = "Wanted for extra cheese.",
	},
	{
		id = "DonutDetainee",
		name = "Donut Detainee",
		emoji = "🍩",
		rarity = "Uncommon",
		income = 25,
		description = "Serving a hole sentence.",
	},
	{
		id = "CactusCrook",
		name = "Cactus Crook",
		emoji = "🌵",
		rarity = "Uncommon",
		income = 28,
		description = "Nobody hugs him. Nobody.",
	},

	-- RARE
	{
		id = "CellBlockGoblin",
		name = "Cell Block Goblin",
		emoji = "🗿",
		rarity = "Rare",
		income = 50,
		description = "Has lived in Cell Block 1 since the stone age.",
	},
	{
		id = "RichPrisoner",
		name = "Rich Prisoner",
		emoji = "🐷",
		rarity = "Rare",
		income = 65,
		description = "Bribed the guards with chocolate coins.",
	},
	{
		id = "JuiceSmuggler",
		name = "Juice Smuggler",
		emoji = "🧃",
		rarity = "Rare",
		income = 80,
		description = "Smuggles apple juice in his pockets.",
	},
	{
		id = "RoboRascal",
		name = "Robo Rascal",
		emoji = "🤖",
		rarity = "Rare",
		income = 90,
		description = "Beep boop. Escape plan loading...",
	},
	{
		id = "CheeseEscapee",
		name = "Cheese Escapee",
		emoji = "🧀",
		rarity = "Rare",
		income = 100,
		description = "Too holey to stay in one cell.",
	},

	-- EPIC
	{
		id = "AlienPrisoner",
		name = "Alien Prisoner",
		emoji = "👽",
		rarity = "Epic",
		income = 150,
		description = "Arrested for parking a UFO in the yard.",
	},
	{
		id = "DiamondCriminal",
		name = "Diamond Criminal",
		emoji = "💎",
		rarity = "Epic",
		income = 200,
		description = "Stole a diamond. Then became one.",
	},
	{
		id = "ClownConvict",
		name = "Clown Convict",
		emoji = "🤡",
		rarity = "Epic",
		income = 250,
		description = "Escaped in a tiny car with 20 friends.",
	},
	{
		id = "NinjaNoodle",
		name = "Ninja Noodle",
		emoji = "🍜",
		rarity = "Epic",
		income = 300,
		description = "Slurps right through the prison bars.",
	},
	{
		id = "PirateParrot",
		name = "Pirate Parrot",
		emoji = "🦜",
		rarity = "Epic",
		income = 350,
		description = "Yells 'ESCAPE!' every five seconds.",
	},

	-- LEGENDARY
	{
		id = "PrisonKing",
		name = "Prison King",
		emoji = "🔥",
		rarity = "Legendary",
		income = 1000,
		description = "Rules the prison yard. Nobody voted.",
	},
	{
		id = "ElectricInmate",
		name = "Electric Inmate",
		emoji = "⚡",
		rarity = "Legendary",
		income = 1250,
		description = "Powered by nine volts of pure brainrot.",
	},
	{
		id = "GoldenWarden",
		name = "Golden Warden",
		emoji = "👑",
		rarity = "Legendary",
		income = 1500,
		description = "The warden... is ALSO a prisoner??",
	},
	{
		id = "DragonDropout",
		name = "Dragon Dropout",
		emoji = "🐉",
		rarity = "Legendary",
		income = 2000,
		description = "Dropped out of dragon school to do crimes.",
	},

	-- MYTHIC
	{
		id = "CosmicPrisoner",
		name = "Cosmic Prisoner",
		emoji = "🌌",
		rarity = "Mythic",
		income = 5000,
		description = "Contains an entire galaxy. And snacks.",
	},
	{
		id = "SkullBoss",
		name = "Skull Boss",
		emoji = "💀",
		rarity = "Mythic",
		income = 7000,
		description = "The coolest skull in prison. Wears shades at night.",
	},
	{
		id = "IQInmate",
		name = "9000 IQ Inmate",
		emoji = "🧠",
		rarity = "Mythic",
		income = 9000,
		description = "Solved the prison. Decided to stay anyway.",
	},
	{
		id = "VolcanoVillain",
		name = "Volcano Villain",
		emoji = "🌋",
		rarity = "Mythic",
		income = 11000,
		description = "Erupts every time he loses at cards.",
	},

	-- DIVINE
	{
		id = "GalaxyWarden",
		name = "Galaxy Warden",
		emoji = "☄️",
		rarity = "Divine",
		income = 40000,
		description = "Guards the biggest prison in the universe.",
	},
	{
		id = "RainbowCriminal",
		name = "Rainbow Criminal",
		emoji = "🌈",
		rarity = "Divine",
		income = 50000,
		description = "Stole every color. Gave none back.",
	},
	{
		id = "HaloHooligan",
		name = "Halo Hooligan",
		emoji = "😇",
		rarity = "Divine",
		income = 60000,
		description = "An angel. Allegedly.",
	},

	-- SECRET
	{
		id = "SecretBrainrot",
		name = "???",
		emoji = "❓",
		rarity = "Secret",
		income = 500000,
		description = "Nobody knows what it is. Not even it.",
	},
} :: { Brainrot }

-- Lookup tables built from the lists above.
BrainrotData.RarityById = {} :: { [string]: Rarity }
BrainrotData.VariantById = {} :: { [string]: Variant }
BrainrotData.ById = {} :: { [string]: Brainrot }
BrainrotData.ByRarity = {} :: { [string]: { Brainrot } }

for _, rarity in BrainrotData.Rarities do
	BrainrotData.RarityById[rarity.id] = rarity
	BrainrotData.ByRarity[rarity.id] = {}
end
for _, variant in BrainrotData.Variants do
	BrainrotData.VariantById[variant.id] = variant
end
for _, brainrot in BrainrotData.Brainrots do
	assert(BrainrotData.RarityById[brainrot.rarity], `{brainrot.id} has unknown rarity {brainrot.rarity}`)
	assert(not BrainrotData.ById[brainrot.id], `Duplicate Brainrot id {brainrot.id}`)
	BrainrotData.ById[brainrot.id] = brainrot
	table.insert(BrainrotData.ByRarity[brainrot.rarity], brainrot)
end
for _, rarity in BrainrotData.Rarities do
	assert(#BrainrotData.ByRarity[rarity.id] > 0, `Rarity {rarity.id} has no Brainrots`)
end

BrainrotData.Count = #BrainrotData.Brainrots

function BrainrotData.getRarity(brainrotId: string): Rarity
	return BrainrotData.RarityById[BrainrotData.ById[brainrotId].rarity]
end

function BrainrotData.displayName(brainrotId: string, variantId: string?): string
	local brainrot = BrainrotData.ById[brainrotId]
	local variant = BrainrotData.VariantById[variantId or "Normal"] or BrainrotData.Variants[1]
	if variant.id == "Normal" then
		return brainrot.name
	end
	return `{variant.prefix}{variant.name} {brainrot.name}`
end

function BrainrotData.income(brainrotId: string, variantId: string?): number
	local brainrot = BrainrotData.ById[brainrotId]
	local variant = BrainrotData.VariantById[variantId or "Normal"] or BrainrotData.Variants[1]
	return brainrot.income * variant.multiplier
end

-- The variant you get by combining COMBINE_COST of `variantId`, or nil if it can't be combined further.
function BrainrotData.nextVariant(variantId: string): string?
	if variantId == "Normal" then
		return "Golden"
	elseif variantId == "Golden" then
		return "Diamond"
	end
	return nil
end

return BrainrotData
