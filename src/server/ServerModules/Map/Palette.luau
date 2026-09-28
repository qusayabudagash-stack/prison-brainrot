-- The prison's controlled palette. Environments stay neutral (concrete, steel, painted walls) so the
-- strong colors are saved for things you can use: machines, stations, signs, rewards and rare areas.

local rgb = Color3.fromRGB
local M = Enum.Material

local Palette = {
	-- Structure
	Concrete = rgb(200, 196, 188),
	ConcreteDark = rgb(152, 149, 143),
	ConcreteWarm = rgb(214, 205, 190),
	Paint = rgb(98, 124, 132), -- lower wall paint, institutional teal-gray
	PaintDark = rgb(72, 94, 102),
	Floor = rgb(160, 158, 152),
	FloorDark = rgb(112, 110, 106),
	FloorLight = rgb(196, 194, 188),
	Tile = rgb(214, 212, 204),
	Brick = rgb(150, 92, 72),
	BrickDark = rgb(112, 68, 56),
	Roof = rgb(120, 118, 114),

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
	Wall = M.Concrete,
	Floor = M.Concrete,
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
