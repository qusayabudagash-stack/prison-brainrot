-- Cell Block A: the players' cells, in two rows facing each other across a long corridor, with
-- a second tier of cells and a catwalk above them. Every cell is furnished (bunk, steel
-- toilet-sink, locker, shelf, lamp, window) and has three display pedestals at the front.
--
-- Cell space (used by CosmeticBuilder): origin on the floor at the middle of the cell, bars at
-- z = -8 (the front, facing the corridor), back wall at z = +8, side walls at x = -9 and +9.
-- Default furniture models are named "Bunk", "Toilet", "Locker" so cosmetics can replace them.
-- CellService relies on: CellIndex/OwnerId attributes, "Sign" (with OwnerText), Display1..3,
-- and the "Displays" and "Decor" folders.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Parent.Build)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)
local Structure = require(script.Parent.Structure)

local CellWing = {}

local M = Enum.Material
local v3 = Vector3.new
local v2 = Vector2.new
local rgb = Color3.fromRGB

local Y = MapLayout.FLOOR_Y
local BOX = MapLayout.CellWing
local CELL_HEIGHT = 12
local TIER = 13 -- floor of the upper tier
local DEPTH = 16
local WEST_BACK = BOX.x1 -- x of the west row's back wall
local EAST_BACK = BOX.x2 - 2 -- the hall's wall is 2 studs thick
local SLOTS = { -50, -30, -10, 10, 30, 50 }
local EAST_SLOTS = { -50, -30, 30, 50 }

-- Muted wall colors, one per cell, so neighbours are easy to tell apart without shouting.
local CELL_PAINT = {
	rgb(112, 138, 150),
	rgb(128, 146, 116),
	rgb(156, 132, 112),
	rgb(134, 120, 150),
	rgb(150, 142, 110),
	rgb(110, 134, 136),
}

local WALL_STYLE: Structure.WallStyle =
	{ wall = Palette.Concrete, paint = Palette.PaintDark, paintHeight = 8, thickness = 2 }

---------------------------------------------------------------------------
-- A player cell
---------------------------------------------------------------------------

local function buildCell(parent: Instance, index: number, origin: CFrame, label: string, hasWindow: boolean): Model
	local s = Shapes.model(parent, `Cell{index}`, origin)
	local model = s.parent :: Model
	model:SetAttribute("CellIndex", index)
	model:SetAttribute("OwnerId", 0)
	local paint = CELL_PAINT[(index - 1) % #CELL_PAINT + 1]

	-- Floor tiles and painted walls
	s:box("CellFloor", v3(18, 0.1, 16), CFrame.new(0, 0.05, 0), rgb(186, 182, 172), M.Concrete)
	s:deco("BackPaint", v3(18, 7, 0.1), CFrame.new(0, 3.5, 7.95), paint, M.SmoothPlastic)
	for _, side in { -1, 1 } do
		s:deco("SidePaint", v3(0.1, 7, 16), CFrame.new(side * 8.95, 3.5, 0), paint, M.SmoothPlastic)
	end
	s:deco("CellCeiling", v3(18, 0.4, 16), CFrame.new(0, CELL_HEIGHT - 0.2, 0), Palette.ConcreteDark, M.Concrete)

	-- Bars across the front with the sliding door pulled open
	Props.bars(model, s:world(CFrame.new(-6, 0, -8)), 6, CELL_HEIGHT - 1, 1.1, "BarsLeft")
	Props.bars(model, s:world(CFrame.new(6, 0, -8)), 6, CELL_HEIGHT - 1, 1.1, "BarsRight")
	Props.bars(model, s:world(CFrame.new(-5.6, 0, -8.6)), 6, CELL_HEIGHT - 1.4, 1.1, "SlidingDoor")
	s:box("Header", v3(18.4, 1.2, 1), CFrame.new(0, CELL_HEIGHT - 0.6, -8), Palette.Bars, M.Metal)
	s:deco("DoorTrack", v3(18, 0.3, 0.6), CFrame.new(0, CELL_HEIGHT - 1.4, -8.6), Palette.SteelDark, M.Metal)
	local plate = s:deco("CellNumber", v3(2.6, 0.9, 0.1), CFrame.new(0, CELL_HEIGHT - 0.6, -8.55), Palette.White)
	Build.surfaceText(
		plate,
		Enum.NormalId.Front,
		label,
		{ textColor = Palette.Ink, strokeColor = Palette.White, pixelsPerStud = 40 }
	)

	-- Default furniture
	Props.bunk(
		model,
		s:world(CFrame.new(-4.4, 0, 5.8) * CFrame.Angles(0, math.pi / 2, 0)),
		paint:Lerp(Palette.Fabric, 0.4),
		"Bunk"
	)
	Props.toiletSink(model, s:world(CFrame.new(6.6, 0, 6.2)), "Toilet")
	Props.locker(
		model,
		s:world(CFrame.new(7.9, 0, 1.6) * CFrame.Angles(0, math.pi / 2, 0)),
		paint:Lerp(Palette.Steel, 0.5),
		"Locker"
	)
	Props.shelf(model, s:world(CFrame.new(6.2, 7.2, 7.9)), "Shelf")
	Props.wallLamp(model, s:world(CFrame.new(1.8, 9.2, 7.9)), Palette.LightWarm)
	if hasWindow then
		-- A barred window high on the outside wall, with daylight behind it
		Structure.window(s, CFrame.new(-2.5, 0, 7.5), 3.8, 2.4, 8.2)
		s:deco("WindowSill", v3(4.4, 0.3, 0.8), CFrame.new(-2.5, 8.2, 7.6), Palette.SteelDark, M.Metal)
		s:deco("WindowHead", v3(4.4, 0.3, 0.8), CFrame.new(-2.5, 10.6, 7.6), Palette.SteelDark, M.Metal)
	else
		s:deco("Vent", v3(3, 1.2, 0.2), CFrame.new(-2.5, 9.6, 7.85), Palette.Steel, M.Metal)
	end

	-- Display pedestals at the front of the cell
	for i, x in { -5.5, 0, 5.5 } do
		s:cyl("Pedestal", 1.2, 3.2, CFrame.new(x, 0.6, -3.6), Palette.SteelLight, M.Metal)
		local glow = s:cyl("PedestalGlow", 1.22, 2.6, CFrame.new(x, 0.6, -3.6), Palette.LightWarm, M.Neon, false)
		glow.Transparency = 0.6
		glow.CastShadow = false
		s:cyl("PedestalTop", 0.2, 3.4, CFrame.new(x, 1.3, -3.6), Palette.SteelDark, M.Metal)
		local anchor = s:deco(`Display{i}`, v3(1, 1, 1), CFrame.new(x, 1.4, -3.6), Palette.White)
		anchor.Transparency = 1
	end
	Build.folder(model, "Displays")
	Build.folder(model, "Decor")

	-- Owner sign, mounted on the catwalk fascia above the bars
	local sign = s:deco("Sign", v3(13, 1.5, 0.3), CFrame.new(0, TIER - 0.8, -13.4), rgb(26, 28, 36), M.SmoothPlastic)
	sign.CastShadow = false
	local owner = Build.surfaceText(
		sign,
		Enum.NormalId.Front,
		"🔓 EMPTY CELL",
		{ textColor = Palette.Gold, strokeColor = Palette.Ink, pixelsPerStud = 40 }
	)
	owner.Name = "OwnerText"
	s:light(sign, Palette.LightWarm, 8, 0.5)

	model.WorldPivot = origin
	return model
end

---------------------------------------------------------------------------
-- The wing
---------------------------------------------------------------------------

-- Upper-tier cell facade: bars, a cot and a dim light behind them.
local function upperCell(s: Shapes.Shapes, label: string)
	Props.bars(s.parent, s:world(CFrame.new(0, TIER, -8)), 18, CELL_HEIGHT - 2, 1.1, "UpperBars")
	s:deco("UpperFloor", v3(18, 0.4, 16), CFrame.new(0, TIER - 0.2, 0), Palette.ConcreteDark, M.Concrete)
	s:deco("Cot", v3(7, 0.8, 3), CFrame.new(-3, TIER + 1.6, 5.8), rgb(210, 205, 190), M.Fabric)
	s:deco("CotFrame", v3(7.2, 1.2, 3.2), CFrame.new(-3, TIER + 0.6, 5.8), Palette.Steel, M.Metal)
	s:deco("UpperToilet", v3(2, 2.6, 2), CFrame.new(6, TIER + 1.3, 6.5), Palette.Chrome, M.Metal)
	local plate = s:deco("CellNumber", v3(2.6, 0.9, 0.1), CFrame.new(0, TIER + CELL_HEIGHT - 2.6, -8.35), Palette.White)
	Build.surfaceText(
		plate,
		Enum.NormalId.Front,
		label,
		{ textColor = Palette.Ink, strokeColor = Palette.White, pixelsPerStud = 40 }
	)
end

local function catwalk(s: Shapes.Shapes, x: number, direction: number, z1: number, z2: number)
	-- `x` is the cell front line; the walkway sticks out toward the corridor by 5 studs
	local center = x + direction * 2.5
	local length = z2 - z1
	local zc = (z1 + z2) / 2
	s:box("Catwalk", v3(5, 0.5, length), CFrame.new(center, TIER - 0.25, zc), Palette.SteelDark, M.DiamondPlate)
	s:deco("CatwalkFascia", v3(0.4, 1.6, length), CFrame.new(x + direction * 5, TIER - 0.6, zc), Palette.Steel, M.Metal)
	local railX = x + direction * 4.8
	s:box("Handrail", v3(0.3, 0.3, length), CFrame.new(railX, TIER + 3.4, zc), Palette.Hazard, M.Metal)
	s:deco("MidRail", v3(0.2, 0.2, length), CFrame.new(railX, TIER + 1.8, zc), Palette.Steel, M.Metal)
	for z = z1, z2, 4 do
		s:deco("RailPost", v3(0.25, 3.4, 0.25), CFrame.new(railX, TIER + 1.7, z), Palette.Steel, M.Metal)
	end
	for z = z1 + 10, z2 - 10, 20 do
		s:deco("Bracket", v3(4.6, 0.6, 0.6), CFrame.new(center, TIER - 1.2, z), Palette.Steel, M.Metal)
	end
end

function CellWing.build(folder: Instance): { Model }
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	local h = BOX.height
	local zMid = (BOX.z1 + BOX.z2) / 2

	-- Floor with a painted walkway
	Structure.floor(folder, "Floor", BOX.x1, BOX.x2, BOX.z1, BOX.z2, Y, Palette.Floor, M.Concrete)
	local corridor = (WEST_BACK + DEPTH + EAST_BACK - DEPTH) / 2
	for _, x in { corridor - 6, corridor + 6 } do
		s:deco("WalkLine", v3(0.5, 0.06, BOX.z2 - BOX.z1 - 4), CFrame.new(x, 0.03, zMid), Palette.Hazard).CastShadow =
			false
	end
	for z = BOX.z1 + 6, BOX.z2 - 6, 12 do
		s:deco("Drain", v3(1.6, 0.07, 1.6), CFrame.new(corridor, 0.035, z), Palette.SteelDark, M.DiamondPlate).CastShadow =
			false
	end

	-- Outer walls (the east side is the hall's wall)
	Structure.wall(folder, v2(BOX.x1 - 1, BOX.z1 - 2), v2(BOX.x1 - 1, BOX.z2 + 2), Y, h, WALL_STYLE)
	Structure.wall(folder, v2(BOX.x1 - 2, BOX.z2 + 1), v2(BOX.x2 - 2, BOX.z2 + 1), Y, h, WALL_STYLE)
	Structure.wall(folder, v2(BOX.x1 - 2, BOX.z1 - 1), v2(BOX.x2 - 2, BOX.z1 - 1), Y, h, WALL_STYLE)
	Structure.roof(
		folder,
		BOX.x1 - 2,
		BOX.x2 - 2,
		BOX.z1 - 2,
		BOX.z2 + 2,
		Y + h,
		{ beamEvery = 12, skylights = { { corridor - 6, corridor + 6, -40, 40 } } }
	)

	-- Cells: west row faces east, east row faces west. Dividers and upper tiers around them.
	local cells = {}
	local count = 0
	local function row(xBack: number, facing: number, slots: { number }, letter: string, windows: boolean)
		for _, z in slots do
			count += 1
			if count > GameConfig.CELL_COUNT then
				return
			end
			local cellCenter = xBack + facing * DEPTH / 2
			local origin = CFrame.new(cellCenter, Y, z)
				* CFrame.Angles(0, if facing > 0 then -math.pi / 2 else math.pi / 2, 0)
			local label = `{letter}-{string.format("%02d", count)}`
			table.insert(cells, buildCell(folder, count, origin, label, windows))
			upperCell(Shapes.new(folder, origin), `{letter}-{string.format("%02d", count + 10)}`)
		end
	end
	row(WEST_BACK, 1, SLOTS, "A", true)
	row(EAST_BACK, -1, EAST_SLOTS, "A", false)

	for _, spec in
		{ { back = WEST_BACK, facing = 1, slots = SLOTS }, { back = EAST_BACK, facing = -1, slots = EAST_SLOTS } }
	do
		local xBack, facing, slots = spec.back, spec.facing, spec.slots
		local xFront = xBack + facing * DEPTH
		local mid = (xBack + xFront) / 2
		-- Dividers on both sides of every cell, full height (both tiers)
		local edges = {}
		for _, z in slots do
			edges[z - 10] = true
			edges[z + 10] = true
		end
		for z in edges do
			s:box("Divider", v3(DEPTH, h, 1), CFrame.new(mid, h / 2, z), Palette.Concrete, M.Concrete)
		end
		-- Catwalks in front of the upper tier, over each run of cells
		local runs: { { number } } = if facing > 0 then { { BOX.z1, BOX.z2 } } else { { BOX.z1, -20 }, { 20, BOX.z2 } }
		for _, run in runs do
			catwalk(s, xFront, facing, run[1], run[2])
		end
		-- Hanging lights along the cell fronts
		for _, z in slots do
			Props.ceilingLight(folder, s:world(CFrame.new(xFront + facing * 9, h - 5, z)), 8, Palette.LightCool, 4)
		end
	end
	-- A bridge across the corridor between the two catwalks
	local westFront, eastFront = WEST_BACK + DEPTH, EAST_BACK - DEPTH
	s:box(
		"Bridge",
		v3(eastFront - westFront, 0.5, 5),
		CFrame.new(corridor, TIER - 0.25, zMid + 40),
		Palette.SteelDark,
		M.DiamondPlate
	)
	for _, z in { zMid + 42.3, zMid + 37.7 } do
		s:box(
			"BridgeRail",
			v3(eastFront - westFront, 0.3, 0.3),
			CFrame.new(corridor, TIER + 3.4, z),
			Palette.Hazard,
			M.Metal
		)
	end

	-- The archway into the hall: an open cell-block gate and a sign
	local arch = CFrame.new(BOX.x2 - 1, 0, 0)
	s:deco("ArchSign", v3(0.4, 3, 20), arch * CFrame.new(-1.4, 18.5, 0), rgb(26, 28, 36), M.SmoothPlastic)
	local signText = s:glow("ArchSignText", v3(0.2, 2.4, 19), arch * CFrame.new(-1.65, 18.5, 0), rgb(255, 150, 60))
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Build.surfaceText(
			signText,
			face,
			"CELL BLOCK A",
			{ textColor = Palette.White, strokeColor = rgb(140, 60, 10), pixelsPerStud = 30 }
		)
	end
	Props.bars(
		folder,
		s:world(arch * CFrame.new(-1.4, 0, -9.5) * CFrame.Angles(0, math.pi / 2, 0)),
		5,
		16,
		1.1,
		"OpenGate"
	)

	-- Guard post at the south end, cameras, a laundry cart and a wet floor
	Props.securityDesk(
		folder,
		s:world(CFrame.new(corridor, 0, BOX.z1 + 5) * CFrame.Angles(0, math.pi, 0)),
		{ "CELL A-03\nSNORING", "CELL A-07\nROLLING", "CELL A-10\n???" }
	)
	for _, z in { BOX.z1 + 2, BOX.z2 - 2 } do
		local facing = if z < 0 then CFrame.Angles(0, 0, 0) else CFrame.Angles(0, math.pi, 0)
		Props.camera(folder, s:world(CFrame.new(corridor, 17, z) * facing))
	end
	local cart = CFrame.new(corridor - 8, 0, BOX.z2 - 10)
	s:box("LaundryCart", v3(4, 3, 6), cart * CFrame.new(0, 2.2, 0), rgb(90, 110, 160), M.Fabric)
	s:deco("CartFrame", v3(4.2, 0.3, 6.2), cart * CFrame.new(0, 0.7, 0), Palette.SteelDark, M.Metal)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -2.6, 2.6 } do
			s:cyl(
				"Wheel",
				0.4,
				0.6,
				cart * CFrame.new(x, 0.3, z) * CFrame.Angles(0, 0, math.pi / 2),
				Palette.Rubber,
				M.SmoothPlastic,
				false
			)
		end
	end
	for i = 0, 2 do
		s:deco(
			"Laundry",
			v3(1.6, 0.8, 1.8),
			cart * CFrame.new(-0.8 + i * 0.8, 3.9, -1.5 + i * 1.4) * CFrame.Angles(0, i * 0.7, 0.2),
			Palette.Orange,
			M.Fabric
		)
	end
	local puddle = s:cyl("Puddle", 0.05, 5, CFrame.new(corridor + 5, 0.03, 12), rgb(150, 190, 210), M.Glass, false)
	puddle.Transparency = 0.4
	Props.cone(folder, s:world(CFrame.new(corridor + 7, 0, 15)))
	Props.warning(
		folder,
		s:world(CFrame.new(corridor, 15.5, BOX.z2 - 0.1) * CFrame.Angles(0, math.pi, 0)),
		"LIGHTS OUT AT 10PM",
		8
	)
	return cells
end

return CellWing
