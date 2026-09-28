-- The mess hall, east of the main hall: a serving line with a kitchen behind it, bolted tables,
-- a menu nobody trusts, barred windows onto the yard and the aftermath of a food fight.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Parent.Build)
local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)
local Structure = require(script.Parent.Structure)

local MessHall = {}

local M = Enum.Material
local v3 = Vector3.new
local v2 = Vector2.new
local rgb = Color3.fromRGB

local Y = MapLayout.FLOOR_Y
local BOX = MapLayout.MessHall
local X1 = BOX.x1 + 2 -- inside face of the hall's wall
-- A warm retro cafeteria: cream and terracotta checkerboard, orange walls with a teal stripe
local TILE_A = rgb(238, 228, 208)
local TILE_B = rgb(214, 128, 86)
local STYLE: Structure.WallStyle = {
	wall = Palette.Concrete,
	paint = rgb(222, 126, 62),
	stripe = Palette.Paint,
	paintHeight = 7,
	thickness = 2,
}

local function shell(folder: Instance)
	local h = BOX.height
	Structure.floor(folder, "Floor", X1, BOX.x2, BOX.z1, BOX.z2, Y, TILE_A, M.CeramicTiles)
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	-- Checkerboard tiles (every other one is a darker tile laid on the floor)
	local size = 7
	for ix = 0, math.floor((BOX.x2 - X1) / size) - 1 do
		for iz = 0, math.floor((BOX.z2 - BOX.z1) / size) - 1 do
			if (ix + iz) % 2 == 0 then
				local tile = s:deco(
					"Tile",
					v3(size, 0.04, size),
					CFrame.new(X1 + (ix + 0.5) * size, 0.02, BOX.z1 + (iz + 0.5) * size),
					TILE_B,
					M.CeramicTiles
				)
				tile.CastShadow = false
			end
		end
	end
	-- Walls: windows onto the yard on the east, a door to the yard on the south
	local windows = {}
	for _, z in { 6, 22, 38 } do
		table.insert(windows, { at = z - (BOX.z1 - 2), width = 8, height = 8, sill = 5 })
	end
	Structure.wall(folder, v2(BOX.x2 + 1, BOX.z1 - 2), v2(BOX.x2 + 1, BOX.z2 + 6), Y, h, STYLE, windows)
	Structure.wall(folder, v2(X1 - 2, BOX.z2 + 1), v2(BOX.x2 + 2, BOX.z2 + 1), Y, h, STYLE)
	Structure.wall(
		folder,
		v2(X1 - 2, BOX.z1 - 1),
		v2(BOX.x2 + 2, BOX.z1 - 1),
		Y,
		h,
		STYLE,
		{ { at = 28, width = 12, height = 12 } }
	)
	for _, z in { 6, 22, 38 } do
		Props.bars(
			folder,
			s:world(CFrame.new(BOX.x2 + 1, 5, z) * CFrame.Angles(0, math.pi / 2, 0)),
			8,
			8,
			1.1,
			"WindowBars"
		)
	end
	Structure.roof(folder, X1 - 2, BOX.x2 + 2, BOX.z1 - 2, BOX.z2 + 2, Y + h, { beamEvery = 14 })
	Props.hvac(folder, CFrame.new(80, Y + h + 1.2, 10))
	Props.roofVent(folder, CFrame.new(60, Y + h + 1.2, 56), 5)
	Props.roofVent(folder, CFrame.new(64, Y + h + 1.2, 56), 5)
end

local function servingLine(s: Shapes.Shapes)
	local folder = s.parent
	local z = BOX.z2 - 11
	local cx = (X1 + BOX.x2) / 2
	Props.counter(folder, s:world(CFrame.new(cx, 0, z)), 34)
	-- Sneeze guard and trays of food under it
	for x = cx - 16, cx + 16, 8 do
		s:deco("GuardPost", v3(0.3, 3, 0.3), CFrame.new(x, 5.1, z - 0.8), Palette.Chrome, M.Metal)
	end
	local glass = s:deco(
		"SneezeGuard",
		v3(33, 0.15, 2.4),
		CFrame.new(cx, 6.6, z - 0.3) * CFrame.Angles(math.rad(12), 0, 0),
		Palette.Glass,
		M.Glass
	)
	glass.Transparency = 0.65
	local foods = {
		rgb(160, 110, 80),
		rgb(120, 170, 70),
		rgb(236, 220, 150),
		rgb(200, 90, 80),
		rgb(150, 150, 150),
		rgb(240, 200, 90),
	}
	for i, color in foods do
		local x = cx - 13.75 + (i - 1) * 5.5
		s:deco("Pan", v3(4.4, 0.6, 2), CFrame.new(x, 3.9, z + 0.2), Palette.SteelLight, M.Metal)
		s:deco("Food", v3(4, 0.3, 1.6), CFrame.new(x, 4.2, z + 0.2), color, M.SmoothPlastic)
		s:deco(
			"Ladle",
			v3(0.15, 0.15, 2.4),
			CFrame.new(x + 1.5, 4.6, z) * CFrame.Angles(math.rad(30), 0, 0),
			Palette.Chrome,
			M.Metal
		)
	end
	s:deco("TrayRail", v3(34, 0.2, 1.4), CFrame.new(cx, 3.4, z - 2.2), Palette.Chrome, M.Metal)
	for _, x in { cx - 17, cx + 17 } do
		s:deco("TrayRailArm", v3(0.3, 3.3, 1.2), CFrame.new(x, 1.7, z - 2.1), Palette.SteelDark, M.Metal)
	end
	-- Stack of trays at the start of the line
	for i = 0, 5 do
		s:deco(
			"TrayStack",
			v3(2.2, 0.12, 1.5),
			CFrame.new(cx - 19.5, 3.1 + i * 0.14, z - 1),
			rgb(120, 150, 140),
			M.SmoothPlastic
		)
	end
	s:box("TrayStand", v3(2.6, 3, 2), CFrame.new(cx - 19.5, 1.5, z - 1), Palette.Steel, M.Metal)

	-- Menu board over the kitchen pass
	local menu = s:deco("MenuBoard", v3(22, 7, 0.4), CFrame.new(cx, 15, BOX.z2 - 0.3), rgb(34, 44, 40), M.Slate)
	Build.surfaceText(
		menu,
		Enum.NormalId.Front,
		"TODAY'S MENU\n🍖 MYSTERY MEAT\n🥣 BRAINROT SOUP\n🍮 GRAY PUDDING",
		{
			textColor = rgb(240, 240, 220),
			strokeColor = rgb(34, 44, 40),
			pixelsPerStud = 20,
		}
	)
	s:deco("MenuFrame", v3(22.8, 7.8, 0.3), CFrame.new(cx, 15, BOX.z2 - 0.15), Palette.WoodDark, M.Wood)
end

local function kitchen(s: Shapes.Shapes)
	local folder = s.parent
	local z = BOX.z2 - 4
	-- White tiles on the kitchen wall
	s:deco(
		"KitchenTiles",
		v3(BOX.x2 - X1, 8, 0.1),
		CFrame.new((X1 + BOX.x2) / 2, 4, BOX.z2 - 0.05),
		Palette.White,
		M.Slate
	)
	for _, x in { 56, 64 } do
		Props.stove(folder, s:world(CFrame.new(x, 0, z + 1.8)))
	end
	s:box("Hood", v3(18, 2.4, 4), CFrame.new(60, 11, z + 2), Palette.SteelLight, M.Metal)
	s:rod("HoodDuct", v3(60, 12, z + 2), v3(60, 24, z + 2), 2, Palette.SteelLight, M.Metal, false)
	Props.fridge(folder, s:world(CFrame.new(84, 0, z + 2)))
	s:box("PrepTable", v3(10, 0.4, 3), CFrame.new(74, 3.4, z + 2), Palette.Chrome, M.Metal)
	for _, x in { 69.5, 78.5 } do
		s:deco("PrepLeg", v3(0.4, 3.2, 2.6), CFrame.new(x, 1.6, z + 2), Palette.Steel, M.Metal)
	end
	s:deco("CuttingBoard", v3(3, 0.2, 2), CFrame.new(72, 3.7, z + 2), Palette.Wood, M.WoodPlanks)
	s:deco("Cleaver", v3(1.2, 0.08, 0.7), CFrame.new(72.4, 3.85, z + 1.8), Palette.Chrome, M.Metal)
	-- Pot rack
	s:deco("PotRack", v3(8, 0.3, 0.3), CFrame.new(74, 10, z + 2), Palette.SteelDark, M.Metal)
	for i = 0, 3 do
		local x = 71 + i * 2
		s:deco("PotHook", v3(0.1, 1, 0.1), CFrame.new(x, 9.4, z + 2), Palette.SteelDark, M.Metal)
		s:cyl("HangingPot", 1.2, 1.4 - i * 0.1, CFrame.new(x, 8.2, z + 2), Palette.Chrome, M.Metal, false)
	end
end

local function dining(s: Shapes.Shapes)
	local folder = s.parent
	local seed = 0
	for _, x in { 58, 80 } do
		for _, z in { 34, 20, 6 } do
			seed += 1
			Props.messTable(folder, s:world(CFrame.new(x, 0, z)), seed)
			Props.pendant(folder, s:world(CFrame.new(x, BOX.height - 9, z)), 8, Palette.Orange, Palette.LightWarm)
		end
	end
	-- Vending machines by the door from the hall
	Props.vending(
		folder,
		s:world(CFrame.new(X1 + 1.6, 0, 42) * CFrame.Angles(0, -math.pi / 2, 0)),
		rgb(210, 50, 50),
		"🥤 SODA"
	)
	Props.vending(
		folder,
		s:world(CFrame.new(X1 + 1.6, 0, 47) * CFrame.Angles(0, -math.pi / 2, 0)),
		rgb(236, 150, 40),
		"🍟 CHIPS"
	)
	-- Tray return and bins by the yard door
	s:box("TrayReturn", v3(8, 3.6, 2.4), CFrame.new(84, 1.8, BOX.z1 + 1.4), Palette.SteelLight, M.Metal)
	s:deco("ReturnSlot", v3(6, 1.4, 0.1), CFrame.new(84, 2.6, BOX.z1 + 2.62), Palette.Ink)
	for i, x in { 52, 55.5 } do
		Props.trashCan(
			folder,
			s:world(CFrame.new(x, 0, BOX.z1 + 1.6)),
			if i == 1 then rgb(60, 120, 70) else Palette.Steel
		)
	end
	-- The food fight that nobody talks about
	for i, spot in { v3(95.95, 9, 14), v3(95.95, 11, 30), v3(95.95, 7.5, 46), v3(95.95, 12.5, 2) } do
		local color = ({ rgb(120, 170, 70), rgb(200, 90, 80), rgb(236, 220, 150), rgb(160, 110, 80) })[i]
		s:deco(
			"Splat",
			v3(0.06, 1.6 + (i % 2) * 0.8, 2.2 - (i % 3) * 0.4),
			CFrame.new(spot) * CFrame.Angles(math.rad(i * 25), 0, 0),
			color
		).CastShadow =
			false
	end
	Props.tray(folder, s:world(CFrame.new(70, 0.5, 27) * CFrame.Angles(math.pi, math.rad(30), 0)), 2)
	Props.poster(
		folder,
		s:world(CFrame.new(BOX.x2 - 0.1, 8, 14) * CFrame.Angles(0, math.pi / 2, 0)),
		v2(4.6, 3.6),
		"NO FOOD\nFIGHTS\n(AGAIN)",
		rgb(190, 60, 50)
	)
	Props.clock(folder, s:world(CFrame.new(76, 16, BOX.z1 + 0.2) * CFrame.Angles(0, math.pi, 0)))
	Props.camera(folder, s:world(CFrame.new(BOX.x2 - 1.2, 16, BOX.z2 - 1.2) * CFrame.Angles(0, math.rad(135), 0)))
	-- Sign over the doorway from the hall
	Props.sign(
		folder,
		s:world(CFrame.new(X1 + 0.3, 16.5, 22) * CFrame.Angles(0, -math.pi / 2, 0)),
		v2(14, 2.4),
		"🍽️ MESS HALL",
		rgb(150, 90, 40),
		{ text = Palette.White }
	)
	Props.sign(
		folder,
		s:world(CFrame.new(X1 - 2.3, 16.5, 22) * CFrame.Angles(0, math.pi / 2, 0)),
		v2(14, 2.4),
		"🍽️ MESS HALL",
		rgb(150, 90, 40),
		{ text = Palette.White }
	)
end

function MessHall.build(folder: Instance)
	shell(folder)
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	servingLine(s)
	kitchen(s)
	dining(s)
end

return MessHall
