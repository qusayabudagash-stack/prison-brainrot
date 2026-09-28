-- The prison's art direction: a stylized, colorful modern prison. Warm cream plaster walls over a
-- teal painted band with a yellow stripe, charcoal structure (pilasters, beams, frames), tiled
-- floors and dark ceilings that frame the rooms. The strong colors are saved for things you can use:
-- machines, stations, doors, signs, rewards and the rare blocks, so the Brainrots stay the stars.

local rgb = Color3.fromRGB
local M = Enum.Material

local Palette = {
	-- Structure
	Concrete = rgb(234, 224, 204), -- upper walls: warm cream plaster
	ConcreteDark = rgb(178, 168, 152),
	ConcreteWarm = rgb(240, 228, 206),
	Paint = rgb(52, 126, 138), -- lower wall band: prison teal
	PaintDark = rgb(40, 98, 110),
	Stripe = rgb(250, 190, 60), -- the painted stripe above the band
	Frame = rgb(56, 62, 78), -- charcoal structure: pilasters, beams, cornices, door frames
	FrameLight = rgb(88, 96, 114),
	Floor = rgb(178, 174, 166),
	FloorDark = rgb(118, 116, 112),
	FloorLight = rgb(212, 206, 194),
	Tile = rgb(222, 216, 204),
	Brick = rgb(168, 96, 72),
	BrickDark = rgb(124, 70, 56),
	Roof = rgb(66, 70, 84), -- ceilings stay dark so the walls and machines read

	-- Metal
	Steel = rgb(104, 110, 120),
	SteelDark = rgb(58, 62, 70),
	SteelLight = rgb(170, 176, 186),
	Bars = rgb(78, 84, 94),
	Chrome = rgb(210, 214, 222),

	-- Accents (used sparingly)
	Hazard = rgb(245, 196, 40),
	HazardDark = rgb(32, 32, 36),
	Orange = rgb(250, 125, 35),
	OrangeDark = rgb(205, 92, 25),
	Guard = rgb(42, 66, 140),
	Red = rgb(215, 50, 50),
	Green = rgb(60, 185, 90),
	Blue = rgb(60, 140, 235),
	Gold = rgb(255, 196, 45),

	-- Natural and furniture
	Wood = rgb(150, 106, 70),
	WoodDark = rgb(104, 72, 48),
	Grass = rgb(98, 150, 74),
	Dirt = rgb(150, 120, 90),
	Asphalt = rgb(72, 74, 80),
	Rubber = rgb(40, 40, 44),
	Fabric = rgb(90, 110, 140),

	-- Light and glass
	White = rgb(242, 242, 236),
	Ink = rgb(30, 30, 36),
	Glass = rgb(185, 220, 235),
	LightWarm = rgb(255, 232, 196),
	LightCool = rgb(214, 232, 255),
	Screen = rgb(24, 30, 40),
}

Palette.Materials = {
	Wall = M.Plaster,
	Floor = M.CeramicTiles,
	FloorPolished = M.Marble,
	Metal = M.Metal,
	Plate = M.DiamondPlate,
	Wood = M.WoodPlanks,
	Brick = M.Brick,
	Glass = M.Glass,
	Fabric = M.Fabric,
	Asphalt = M.Asphalt,
	Grass = M.Grass,
	Plastic = M.SmoothPlastic,
	Neon = M.Neon,
}

return Palette
