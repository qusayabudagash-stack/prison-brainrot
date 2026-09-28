--!strict
-- Free Roblox Creator Store models used instead of the built-in Brainrot designs.
--
-- Only models that look like their uploader's own work are listed. Re-uploads of other games'
-- models (for example the many copies of Steal a Brainrot's) are left out on purpose: using
-- those risks copyright takedowns. Brainrots without an entry keep their built-in design.
--
-- `reviewed = false` means Roblox had no preview image for the model, so nobody has seen it yet:
-- check it in Studio and delete the entry if it doesn't fit. `facing` turns a model (degrees
-- around the vertical axis) so its face points the same way as the built-in designs.
--
-- Loaded at server start by BrainrotAssetService (the game's owner must "Get" each model on its
-- Creator Store page), or inserted into the place in Studio with
-- tools/studio/insert_brainrot_models.lua.

export type Entry = {
	assetId: number,
	creator: string,
	reviewed: boolean,
	facing: number?,
}

local BrainrotAssetIds: { [string]: Entry } = {
	-- Reviewed: previews look like original work by the uploader
	TralaleroTralala = { assetId = 111854862176457, creator = "BeanGGTV", reviewed = true },
	TungTungTungSahur = { assetId = 138151705692565, creator = "ATMnou", reviewed = true },
	BombardiroCrocodilo = { assetId = 111138597903728, creator = "NoStart Studios", reviewed = true },
	LiriliLarila = { assetId = 77231614368559, creator = "giacomorixYT", reviewed = true },
	BrrBrrPatapim = { assetId = 100538198930997, creator = "Haxcyc_LDC", reviewed = true },
	FrigoCamelo = { assetId = 136392638607318, creator = "Thaiskiy", reviewed = true },
	LaVacaSaturnoSaturnita = { assetId = 76127116347738, creator = "jimmydonutnoob", reviewed = true },
	CappuccinoAssassino = { assetId = 128417631951950, creator = "rabiii3", reviewed = true },

	-- Not yet seen: one creator's matching set with no preview images on Roblox
	TimCheese = { assetId = 109885813071198, creator = "VLAD9090900", reviewed = false },
	TrippiTroppi = { assetId = 116011992685633, creator = "VLAD9090900", reviewed = false },
	SvininoBombondino = { assetId = 95447453767504, creator = "VLAD9090900", reviewed = false },
	TalpaDiFerro = { assetId = 110624907357617, creator = "VLAD9090900", reviewed = false },
	BobritoBandito = { assetId = 111797693528408, creator = "VLAD9090900", reviewed = false },
	BurbaloniLuliloli = { assetId = 117877258860665, creator = "VLAD9090900", reviewed = false },
	OrangutiniAnanassini = { assetId = 128360398522638, creator = "VLAD9090900", reviewed = false },
	BananitaDolphinita = { assetId = 113911811888783, creator = "VLAD9090900", reviewed = false },
	ChefCrabracadabra = { assetId = 98435646480489, creator = "VLAD9090900", reviewed = false },
	EspressonaSignora = { assetId = 97449230983933, creator = "VLAD9090900", reviewed = false },
	LosTralaleritos = { assetId = 82763274977738, creator = "VLAD9090900", reviewed = false },
}

return BrainrotAssetIds
