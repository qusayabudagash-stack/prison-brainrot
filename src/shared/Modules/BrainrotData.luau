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
		id = "TimCheese",
		name = "Tim Cheese",
		emoji = "🧀",
		rarity = "Common",
		income = 5,
		description = "A cheese mouse doing time for eating the evidence.",
	},
	{
		id = "LiriliLarila",
		name = "Lirilì Larilà",
		emoji = "🌵",
		rarity = "Common",
		income = 6,
		description = "Half elephant, half cactus. Nobody hugs him in the yard.",
	},
	{
		id = "TrippiTroppi",
		name = "Trippi Troppi",
		emoji = "🦐",
		rarity = "Common",
		income = 7,
		description = "A shrimp with a cat's face. Escaped the seafood counter, not the prison.",
	},
	{
		id = "SvininoBombondino",
		name = "Svinino Bombondino",
		emoji = "🐷",
		rarity = "Common",
		income = 8,
		description = "A pig-shaped bomb with a very short fuse. Handle with care.",
	},
	{
		id = "TalpaDiFerro",
		name = "Talpa di Ferro",
		emoji = "⛏️",
		rarity = "Common",
		income = 9,
		description = "An iron mole. Has tried to dig out 400 times.",
	},

	-- UNCOMMON
	{
		id = "BonecaAmbalabu",
		name = "Boneca Ambalabu",
		emoji = "🐸",
		rarity = "Uncommon",
		income = 15,
		description = "A frog in a tire, on human legs. Rolled straight into Cell Block 1.",
	},
	{
		id = "BobritoBandito",
		name = "Bobrito Bandito",
		emoji = "🦫",
		rarity = "Uncommon",
		income = 18,
		description = "A beaver bandit. Stole the warden's hat and never gave it back.",
	},
	{
		id = "BurbaloniLuliloli",
		name = "Burbaloni Luliloli",
		emoji = "🥥",
		rarity = "Uncommon",
		income = 22,
		description = "A capybara living in a coconut. Very chill about the sentence.",
	},
	{
		id = "CactoHipopotamo",
		name = "Il Cacto Hipopotamo",
		emoji = "🦛",
		rarity = "Uncommon",
		income = 25,
		description = "A cactus hippo. The guards stopped patting him down.",
	},
	{
		id = "OrangutiniAnanassini",
		name = "Orangutini Ananassini",
		emoji = "🍍",
		rarity = "Uncommon",
		income = 28,
		description = "An orangutan in a pineapple suit. Smells amazing.",
	},

	-- RARE
	{
		id = "RhinoToasterino",
		name = "Rhino Toasterino",
		emoji = "🍞",
		rarity = "Rare",
		income = 50,
		description = "Half rhino, half toaster. Makes breakfast for the whole block.",
	},
	{
		id = "BrrBrrPatapim",
		name = "Brr Brr Patapim",
		emoji = "🌳",
		rarity = "Rare",
		income = 65,
		description = "A forest monkey-tree with enormous feet. Brr brr patapim!",
	},
	{
		id = "GlorboFruttodrillo",
		name = "Glorbo Fruttodrillo",
		emoji = "🍉",
		rarity = "Rare",
		income = 80,
		description = "A crocodile in a watermelon. Smuggled in with the fruit delivery.",
	},
	{
		id = "BlueberriniOctopussini",
		name = "Blueberrini Octopussini",
		emoji = "🫐",
		rarity = "Rare",
		income = 90,
		description = "A blueberry octopus. Eight arms, zero alibis.",
	},
	{
		id = "SpioniroGolubiro",
		name = "Spioniro Golubiro",
		emoji = "🕵️",
		rarity = "Rare",
		income = 100,
		description = "A pigeon spy in a trench coat. Reports everything to the warden.",
	},

	-- EPIC
	{
		id = "ChimpanziniBananini",
		name = "Chimpanzini Bananini",
		emoji = "🍌",
		rarity = "Epic",
		income = 150,
		description = "A chimp in a banana. Wa-wa-wa!",
	},
	{
		id = "CappuccinoAssassino",
		name = "Cappuccino Assassino",
		emoji = "☕",
		rarity = "Epic",
		income = 200,
		description = "A coffee-cup ninja. Silent, fast and extra foamy.",
	},
	{
		id = "CocofantoElefanto",
		name = "Cocofanto Elefanto",
		emoji = "🐘",
		rarity = "Epic",
		income = 250,
		description = "A coconut elephant with a very long trunk and a longer rap sheet.",
	},
	{
		id = "TrulimeroTrulicina",
		name = "Trulimero Trulicina",
		emoji = "🐟",
		rarity = "Epic",
		income = 300,
		description = "A fish with a cat's head and four legs. Nobody knows how he got in.",
	},
	{
		id = "BananitaDolphinita",
		name = "Bananita Dolphinita",
		emoji = "🐬",
		rarity = "Epic",
		income = 350,
		description = "A dolphin dressed as a banana. Slippery escape artist.",
	},

	-- LEGENDARY
	{
		id = "BallerinaCappuccina",
		name = "Ballerina Cappuccina",
		emoji = "🩰",
		rarity = "Legendary",
		income = 1_000,
		description = "A cappuccino ballerina. Pirouettes past every guard.",
	},
	{
		id = "TungTungTungSahur",
		name = "Tung Tung Tung Sahur",
		emoji = "🥁",
		rarity = "Legendary",
		income = 1_250,
		description = "Wakes the whole prison at 3 a.m. with his bat. Tung tung tung!",
	},
	{
		id = "BombombiniGusini",
		name = "Bombombini Gusini",
		emoji = "🪿",
		rarity = "Legendary",
		income = 1_500,
		description = "A goose fighter jet. Bombardiro's little brother.",
	},
	{
		id = "GirafaCelestre",
		name = "Girafa Celestre",
		emoji = "🦒",
		rarity = "Legendary",
		income = 2_000,
		description = "A space giraffe. Arrested for parking on the moon.",
	},

	-- MYTHIC
	{
		id = "BombardiroCrocodilo",
		name = "Bombardiro Crocodilo",
		emoji = "🐊",
		rarity = "Mythic",
		income = 5_000,
		description = "A crocodile bomber plane. In here it only drops confetti.",
	},
	{
		id = "ChefCrabracadabra",
		name = "Chef Crabracadabra",
		emoji = "🦀",
		rarity = "Mythic",
		income = 7_000,
		description = "A magic crab chef. Cooks up spells in the mess hall.",
	},
	{
		id = "EspressonaSignora",
		name = "Espressona Signora",
		emoji = "☕",
		rarity = "Mythic",
		income = 9_000,
		description = "The espresso grandma. Everyone behaves when she's around.",
	},
	{
		id = "FrigoCamelo",
		name = "Frigo Camelo",
		emoji = "🐫",
		rarity = "Mythic",
		income = 11_000,
		description = "A camel in a fridge. Keeps the whole block cool.",
	},

	-- DIVINE
	{
		id = "TralaleroTralala",
		name = "Tralalero Tralala",
		emoji = "🦈",
		rarity = "Divine",
		income = 40_000,
		description = "The three-legged shark in sneakers. Tralalero tralala!",
	},
	{
		id = "DragonCannelloni",
		name = "Dragon Cannelloni",
		emoji = "🐉",
		rarity = "Divine",
		income = 50_000,
		description = "A dragon made of pasta. Breathes marinara.",
	},
	{
		id = "LosTralaleritos",
		name = "Los Tralaleritos",
		emoji = "🦈",
		rarity = "Divine",
		income = 60_000,
		description = "Three Tralaleros on one surfboard. The whole gang, in one cell.",
	},

	-- SECRET
	{
		id = "LaVacaSaturnoSaturnita",
		name = "La Vaca Saturno Saturnita",
		emoji = "🐄",
		rarity = "Secret",
		income = 500_000,
		description = "A cow that lives on Saturn. Nobody believed she was real... until now.",
	},
} :: { Brainrot }

-- Ids used by earlier versions of the game, mapped to the Brainrot that took over their slot
-- (same rarity and income). DataService renames them when an old save is loaded.
BrainrotData.LegacyIds = {
	PotatoPrisoner = "TimCheese",
	ChickenThief = "LiriliLarila",
	BananaJailbird = "TrippiTroppi",
	SockSnatcher = "SvininoBombondino",
	BreadBandit = "TalpaDiFerro",
	PrisonFrog = "BonecaAmbalabu",
	EscapeDuck = "BobritoBandito",
	PizzaCriminal = "BurbaloniLuliloli",
	DonutDetainee = "CactoHipopotamo",
	CactusCrook = "OrangutiniAnanassini",
	CellBlockGoblin = "RhinoToasterino",
	RichPrisoner = "BrrBrrPatapim",
	JuiceSmuggler = "GlorboFruttodrillo",
	RoboRascal = "BlueberriniOctopussini",
	CheeseEscapee = "SpioniroGolubiro",
	AlienPrisoner = "ChimpanziniBananini",
	DiamondCriminal = "CappuccinoAssassino",
	ClownConvict = "CocofantoElefanto",
	NinjaNoodle = "TrulimeroTrulicina",
	PirateParrot = "BananitaDolphinita",
	PrisonKing = "BallerinaCappuccina",
	ElectricInmate = "TungTungTungSahur",
	GoldenWarden = "BombombiniGusini",
	DragonDropout = "GirafaCelestre",
	CosmicPrisoner = "BombardiroCrocodilo",
	SkullBoss = "ChefCrabracadabra",
	IQInmate = "EspressonaSignora",
	VolcanoVillain = "FrigoCamelo",
	GalaxyWarden = "TralaleroTralala",
	RainbowCriminal = "DragonCannelloni",
	HaloHooligan = "LosTralaleritos",
	SecretBrainrot = "LaVacaSaturnoSaturnita",
} :: { [string]: string }

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
