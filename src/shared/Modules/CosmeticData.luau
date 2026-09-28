-- Optional decorations for your cell. Buying one places it in your cell; you can hide it again.

export type Cosmetic = {
	id: string,
	name: string,
	emoji: string,
	price: number,
	description: string,
}

local CosmeticData = {}

CosmeticData.Cosmetics = {
	{ id = "Bed", name = "Comfy Bed", emoji = "🛏️", price = 250, description = "Nap between rolls." },
	{ id = "Toilet", name = "Toilet", emoji = "🚽", price = 500, description = "Every cell needs one." },
	{
		id = "Poster",
		name = "Brainrot Posters",
		emoji = "🖼️",
		price = 1_500,
		description = "Posters of famous Brainrots.",
	},
	{ id = "TV", name = "Prison TV", emoji = "📺", price = 5_000, description = "Only shows roll replays." },
	{ id = "Plant", name = "Potted Plant", emoji = "🪴", price = 12_000, description = "It's plotting an escape." },
	{ id = "NeonLights", name = "Neon Lights", emoji = "💡", price = 40_000, description = "Party cell!" },
	{
		id = "Statue",
		name = "Brainrot Statue",
		emoji = "🗿",
		price = 150_000,
		description = "A golden statue of your best Brainrot.",
	},
	{
		id = "DiscoBall",
		name = "Disco Ball",
		emoji = "🪩",
		price = 750_000,
		description = "Nobody can stop the prison party.",
	},
	{
		id = "GoldToilet",
		name = "Golden Toilet",
		emoji = "✨",
		price = 5_000_000,
		description = "The richest prisoner's throne.",
	},
	{
		id = "RainbowCarpet",
		name = "Rainbow Carpet",
		emoji = "🌈",
		price = 25_000_000,
		description = "Walk on rainbows.",
	},
} :: { Cosmetic }

CosmeticData.ById = {} :: { [string]: Cosmetic }
for _, cosmetic in CosmeticData.Cosmetics do
	CosmeticData.ById[cosmetic.id] = cosmetic
end

return CosmeticData
