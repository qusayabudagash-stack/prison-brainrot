-- The look of each prison block: its roll machine's paint job and the colors of its rooms.
-- Every block keeps the same neutral structure; its identity comes from wall paint, light color,
-- one accent and its set dressing (see Blocks.luau).

local Palette = require(script.Parent.Palette)

local rgb = Color3.fromRGB

export type Theme = {
	machine: { body: Color3, trim: Color3, glow: Color3, featured: string? },
	wall: Color3, -- upper walls
	paint: Color3, -- lower wall paint band
	floor: Color3,
	floorMaterial: Enum.Material,
	light: Color3, -- ceiling light color
	accent: Color3,
}

local Themes: { [string]: Theme } = {
	CellBlock1 = {
		machine = {
			body = rgb(236, 96, 44),
			trim = Palette.Chrome,
			glow = rgb(255, 196, 70),
			featured = "TungTungTungSahur",
		},
		wall = Palette.Concrete,
		paint = Palette.Paint,
		floor = Palette.FloorLight,
		floorMaterial = Enum.Material.Marble,
		light = Palette.LightWarm,
		accent = Palette.Orange,
	},
	CellBlock2 = {
		machine = {
			body = rgb(48, 112, 222),
			trim = Palette.Chrome,
			glow = rgb(90, 214, 255),
			featured = "BallerinaCappuccina",
		},
		wall = rgb(206, 208, 206),
		paint = rgb(74, 104, 150),
		floor = Palette.Floor,
		floorMaterial = Enum.Material.Concrete,
		light = Palette.LightCool,
		accent = rgb(60, 130, 235),
	},
	MaxSecurity = {
		machine = {
			body = rgb(36, 36, 42),
			trim = Palette.Hazard,
			glow = rgb(255, 64, 52),
			featured = "BombombiniGusini",
		},
		wall = rgb(150, 152, 156),
		paint = rgb(62, 64, 70),
		floor = rgb(96, 98, 104),
		floorMaterial = Enum.Material.DiamondPlate,
		light = rgb(236, 240, 255),
		accent = Palette.Hazard,
	},
	DeathRow = {
		machine = {
			body = rgb(104, 58, 166),
			trim = rgb(170, 176, 186),
			glow = rgb(130, 255, 110),
			featured = "BombardiroCrocodilo",
		},
		wall = rgb(126, 120, 132),
		paint = rgb(66, 54, 84),
		floor = rgb(86, 82, 92),
		floorMaterial = Enum.Material.Slate,
		light = rgb(190, 255, 190),
		accent = rgb(130, 255, 110),
	},
	AlienBlock = {
		machine = {
			body = rgb(196, 204, 214),
			trim = Palette.Chrome,
			glow = rgb(255, 90, 230),
			featured = "TralaleroTralala",
		},
		wall = rgb(150, 170, 172),
		paint = rgb(54, 92, 96),
		floor = rgb(80, 96, 100),
		floorMaterial = Enum.Material.DiamondPlate,
		light = rgb(180, 255, 230),
		accent = rgb(90, 255, 170),
	},
	SecretBlock = {
		machine = {
			body = rgb(58, 30, 118),
			trim = Palette.Gold,
			glow = rgb(255, 130, 255),
			featured = "DragonCannelloni",
		},
		wall = rgb(44, 36, 72),
		paint = rgb(28, 22, 50),
		floor = rgb(26, 22, 40),
		floorMaterial = Enum.Material.Glass,
		light = rgb(220, 170, 255),
		accent = rgb(255, 130, 255),
	},
}

return Themes
