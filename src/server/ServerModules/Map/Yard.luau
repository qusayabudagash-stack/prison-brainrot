-- The yard: the only place under open sky. A paved exercise yard with expansion joints and
-- terracotta paths, curbed planters with trees along the walls, a painted basketball court with
-- bleachers, an outdoor gym, a picnic area under umbrellas, the inmates' garden, two watch towers
-- and brick-banded walls topped with wire. Events happen out here: the Prison King holds court on
-- the basketball court, and escaped Brainrots roam the open paving.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)
local Structure = require(script.Parent.Structure)

local Yard = {}

local M = Enum.Material
local v3 = Vector3.new
local v2 = Vector2.new
local rgb = Color3.fromRGB

local Y = MapLayout.FLOOR_Y
local BOX = MapLayout.Yard
local X1 = BOX.x1 + 2
local MESS = MapLayout.MessHall
local PAVING = rgb(204, 196, 182)
local JOINT = rgb(168, 160, 148)
local PAVER = rgb(196, 118, 84)
local COURT = { x1 = 124, x2 = 176, z1 = 12, z2 = 40 }
local WALL: Structure.WallStyle = {
	wall = Palette.Concrete,
	paint = Palette.Brick,
	paintMaterial = M.Brick,
	paintHeight = 6,
	stripe = false,
	pilasterEvery = 12,
	thickness = 2,
}

Yard.KING =
	CFrame.lookAt(v3((COURT.x1 + COURT.x2) / 2, Y, (COURT.z1 + COURT.z2) / 2), v3(X1, Y, (COURT.z1 + COURT.z2) / 2))

local function ground(folder: Instance, s: Shapes.Shapes)
	-- Paving over the whole yard, scored into big slabs
	Structure.floor(folder, "Paving", X1, BOX.x2, BOX.z1, MESS.z1 - 2, Y, PAVING, M.Pavement)
	Structure.floor(folder, "Paving", MESS.x2 + 2, BOX.x2, MESS.z1 - 2, BOX.z2, Y, PAVING, M.Pavement)
	local function joint(size: Vector3, at: CFrame)
		s:deco("Joint", size, at, JOINT, M.Concrete).CastShadow = false
	end
	for x = X1 + 12, BOX.x2 - 4, 12 do
		joint(v3(0.25, 0.04, MESS.z1 - 2 - BOX.z1), CFrame.new(x, 0.02, (BOX.z1 + MESS.z1 - 2) / 2))
		if x > MESS.x2 + 2 then
			joint(v3(0.25, 0.04, BOX.z2 - MESS.z1 + 2), CFrame.new(x, 0.02, (MESS.z1 - 2 + BOX.z2) / 2))
		end
	end
	for z = BOX.z1 + 12, BOX.z2 - 4, 12 do
		local from = if z < MESS.z1 - 2 then X1 else MESS.x2 + 2
		joint(v3(BOX.x2 - from, 0.04, 0.25), CFrame.new((from + BOX.x2) / 2, 0.02, z))
	end
	-- Terracotta paths from the doors to the court and the gym
	local function path(size: Vector3, at: CFrame)
		s:box("Path", size, at, PAVER, M.Brick)
	end
	path(v3(118 - X1, 0.12, 6), CFrame.new((X1 + 118) / 2, 0.06, -28))
	path(v3(6, 0.12, 16), CFrame.new(68, 0.06, -20))
	path(v3(6, 0.12, 37), CFrame.new(115, 0.06, -6.5))
	path(v3(26, 0.12, 6), CFrame.new(131, 0.06, 8))
	-- Curbed planters with trees along the walls, clear of the open middle where escapees roam
	Props.planter(folder, s:world(CFrame.new(X1 + 2.5, 0, -40) * CFrame.Angles(0, math.pi / 2, 0)), 30, 5, 3)
	Props.planter(folder, s:world(CFrame.new(108, 0, BOX.z1 + 3)), 24, 5, 2)
	Props.planter(folder, s:world(CFrame.new(148, 0, BOX.z2 - 2.5)), 90, 4.5, 5)
	Props.planter(folder, s:world(CFrame.new(BOX.x2 - 2.5, 0, 26) * CFrame.Angles(0, math.pi / 2, 0)), 40, 4.5, 3)
end

local function walls(folder: Instance, s: Shapes.Shapes)
	local h = 18
	Structure.wall(folder, v2(BOX.x1, BOX.z1 - 1), v2(BOX.x2 + 2, BOX.z1 - 1), Y, h, WALL)
	Structure.wall(folder, v2(BOX.x2 + 1, BOX.z1 - 2), v2(BOX.x2 + 1, BOX.z2 + 2), Y, h, WALL)
	Structure.wall(folder, v2(MESS.x2, BOX.z2 + 1), v2(BOX.x2 + 2, BOX.z2 + 1), Y, h, WALL)
	-- Barbed wire along the top of every outside wall
	local corners = {
		v3(X1, h, BOX.z1 - 1),
		v3(BOX.x2 + 1, h, BOX.z1 - 1),
		v3(BOX.x2 + 1, h, BOX.z2 + 1),
		v3(MESS.x2 + 1, h, BOX.z2 + 1),
	}
	for i = 1, #corners - 1 do
		for _, lift in { 0.8, 1.6 } do
			s:rod(
				"BarbedWire",
				corners[i] + v3(0, lift, 0),
				corners[i + 1] + v3(0, lift, 0),
				0.45,
				Palette.SteelLight,
				M.Metal,
				false
			)
		end
		local a, b = corners[i], corners[i + 1]
		local steps = math.floor((b - a).Magnitude / 12)
		for step = 0, steps do
			local p = a:Lerp(b, step / steps)
			s:deco("WirePost", v3(0.3, 2.4, 0.3), CFrame.new(p + v3(0, 1.2, 0)), Palette.Steel, M.Metal)
		end
	end
end

local function court(folder: Instance, s: Shapes.Shapes)
	local cx, cz = (COURT.x1 + COURT.x2) / 2, (COURT.z1 + COURT.z2) / 2
	local w, d = COURT.x2 - COURT.x1, COURT.z2 - COURT.z1
	s:box("Court", v3(w + 4, 0.2, d + 4), CFrame.new(cx, 0.1, cz), rgb(46, 118, 150), M.Asphalt)
	s:deco("CourtApron", v3(w + 8, 0.16, d + 8), CFrame.new(cx, 0.08, cz), rgb(60, 66, 80), M.Asphalt)
	local line = Palette.White
	local function paint(name: string, size: Vector3, at: CFrame, color: Color3)
		s:deco(name, size, at, color, M.SmoothPlastic).CastShadow = false
	end
	for _, z in { COURT.z1, COURT.z2 } do
		paint("CourtLine", v3(w, 0.03, 0.4), CFrame.new(cx, 0.215, z), line)
	end
	for _, x in { COURT.x1, COURT.x2, cx } do
		paint("CourtLine", v3(0.4, 0.03, d), CFrame.new(x, 0.215, cz), line)
	end
	local ring = s:cyl("CenterCircle", 0.03, 9, CFrame.new(cx, 0.215, cz), line, M.SmoothPlastic, false)
	ring.CastShadow = false
	s:cyl("CenterCircleInner", 0.035, 8.2, CFrame.new(cx, 0.217, cz), Palette.Orange, M.SmoothPlastic, false).CastShadow =
		false
	for _, side in { -1, 1 } do
		local x = if side < 0 then COURT.x1 + 6 else COURT.x2 - 6
		paint("Key", v3(12, 0.03, 10), CFrame.new(x, 0.21, cz), rgb(236, 120, 60))
		paint("KeyLine", v3(0.4, 0.035, 10), CFrame.new(x + side * -6, 0.216, cz), line)
		Props.hoop(
			folder,
			s:world(
				CFrame.new(if side < 0 then COURT.x1 - 1 else COURT.x2 + 1, 0, cz)
					* CFrame.Angles(0, if side < 0 then -math.pi / 2 else math.pi / 2, 0)
			)
		)
	end
	s:ball("Basketball", 1.3, v3(cx - 8, 0.85, cz + 5), Palette.Orange, M.SmoothPlastic)
	s:ball("Basketball", 1.3, v3(COURT.x2 - 4, 0.85, COURT.z1 + 3), Palette.Orange, M.SmoothPlastic)

	-- Bleachers along the north side
	for tier = 0, 2 do
		local z = COURT.z2 + 5 + tier * 2.4
		local y = 1.2 + tier * 1.6
		s:box("BleacherSeat", v3(40, 0.35, 2), CFrame.new(cx, y, z), Palette.Wood, M.WoodPlanks)
		s:deco("BleacherRiser", v3(40, y, 0.3), CFrame.new(cx, y / 2, z + 1), Palette.Steel, M.Metal)
	end
	for x = cx - 19, cx + 19, 9.5 do
		s:deco("BleacherFrame", v3(0.4, 4.6, 8), CFrame.new(x, 2.3, COURT.z2 + 7.5), Palette.SteelDark, M.Metal)
	end
	-- Floodlights at the corners
	for _, x in { COURT.x1 - 5, COURT.x2 + 5 } do
		for _, z in { COURT.z1 - 3, COURT.z2 + 3 } do
			local toCenter = CFrame.lookAt(v3(x, 0, z), v3(cx, 0, cz))
			Props.floodlight(folder, s:world(toCenter), 24)
		end
	end
end

local function gym(folder: Instance, s: Shapes.Shapes)
	local center = v3(146, 0, -38)
	s:box("GymMat", v3(44, 0.2, 26), CFrame.new(center + v3(0, 0.1, 0)), Palette.Rubber, M.Rubber)
	Props.benchPress(folder, s:world(CFrame.new(center + v3(-14, 0.2, 4))))
	Props.benchPress(folder, s:world(CFrame.new(center + v3(-6, 0.2, 4))))
	Props.pullUpBar(folder, s:world(CFrame.new(center + v3(6, 0.2, -6))))
	Props.weightRack(folder, s:world(CFrame.new(center + v3(4, 0.2, 8)) * CFrame.Angles(0, math.pi, 0)))
	-- Punching bag on a frame
	local bag = center + v3(16, 0.2, 2)
	for _, dx in { -2.5, 2.5 } do
		s:box("BagPost", v3(0.5, 10, 0.5), CFrame.new(bag + v3(dx, 5, 0)), Palette.Steel, M.Metal)
	end
	s:deco("BagBeam", v3(5.6, 0.5, 0.5), CFrame.new(bag + v3(0, 10, 0)), Palette.Steel, M.Metal)
	s:deco("BagChain", v3(0.15, 2, 0.15), CFrame.new(bag + v3(0, 9, 0)), Palette.SteelDark, M.Metal)
	s:cyl("PunchingBag", 4, 1.8, CFrame.new(bag + v3(0, 6, 0)), Palette.Red, M.Fabric)
	Props.sign(
		folder,
		s:world(CFrame.new(center + v3(0, 10, 13.2)) * CFrame.Angles(0, math.pi, 0)),
		v2(12, 2.4),
		"💪 IRON YARD GYM",
		rgb(40, 40, 46),
		{ text = Palette.Hazard }
	)
	for _, dx in { -5, 5 } do
		s:deco("SignPost", v3(0.4, 10, 0.4), CFrame.new(center + v3(dx, 5, 13.5)), Palette.SteelDark, M.Metal)
	end
end

local function grounds(folder: Instance, s: Shapes.Shapes)
	-- Picnic tables near the doors
	for i, spot in { v3(62, 0, -42), v3(82, 0, -50), v3(96, 0, -40) } do
		Props.picnicTable(folder, s:world(CFrame.new(spot) * CFrame.Angles(0, math.rad(i * 25 - 30), 0)))
		-- A striped umbrella over each table
		s:deco("UmbrellaPole", v3(0.25, 7.4, 0.25), CFrame.new(spot + v3(0, 3.7, 0)), Palette.Frame, M.Metal)
		for segment = 0, 7 do
			local angle = segment * math.pi / 4
			s:deco(
				"Umbrella",
				v3(2.6, 0.2, 3.4),
				CFrame.new(spot + v3(0, 7.2, 0))
					* CFrame.Angles(0, angle, 0)
					* CFrame.new(0, 0, -1.6)
					* CFrame.Angles(math.rad(-16), 0, 0),
				if segment % 2 == 0 then Palette.Orange else Palette.White,
				M.Fabric
			)
		end
	end
	for _, x in { 60, 82 } do
		Props.bench(folder, s:world(CFrame.new(x, 0, MESS.z1 - 4)), 8)
	end
	-- The inmates' potato garden
	local garden = v3(186, 0, -28)
	s:deco("GardenBorder", v3(20, 0.8, 22), CFrame.new(garden + v3(0, 0.3, 0)), Palette.WoodDark, M.WoodPlanks)
	s:deco("GardenSoil", v3(19, 0.85, 21), CFrame.new(garden + v3(0, 0.32, 0)), Palette.Dirt, M.Ground)
	for row = 0, 3 do
		local x = garden.X - 7 + row * 4.6
		s:deco("Furrow", v3(2.4, 0.9, 19), CFrame.new(x, 0.5, garden.Z), rgb(120, 92, 66), M.Ground)
		for i = 0, 4 do
			local z = garden.Z - 8 + i * 4
			s:ball("Sprout", 0.9, v3(x, 1.4, z), rgb(90, 170, 70), M.Grass, false)
			s:deco(
				"Leaf",
				v3(1.2, 0.1, 0.5),
				CFrame.new(x, 1.8, z) * CFrame.Angles(0, i, math.rad(20)),
				rgb(110, 190, 80)
			)
		end
	end
	Props.sign(
		folder,
		s:world(CFrame.new(garden + v3(0, 4.5, -11.6))),
		v2(9, 2),
		"🌱 INMATE GARDEN",
		rgb(80, 120, 60),
		{ text = Palette.White }
	)
	s:deco("SignStake", v3(0.4, 4, 0.4), CFrame.new(garden + v3(0, 2, -11.4)), Palette.WoodDark, M.Wood)
	s:cyl("WateringCan", 1.2, 1.2, CFrame.new(garden + v3(-11, 0.6, -9)), rgb(80, 140, 90), M.Metal, false)

	-- Nothing to see here: a spoon, a dirt pile and a suspicious poster on the wall
	local tunnel = v3(BOX.x2 - 0.1, 0, -4)
	Props.poster(
		folder,
		s:world(CFrame.new(tunnel + v3(0, 3, 0)) * CFrame.Angles(0, math.pi / 2, 0)),
		v2(4.4, 5),
		"NOT A\nTUNNEL\n\n(keep\nwalking)",
		rgb(230, 200, 90),
		Palette.Ink
	)
	s:ball("DirtPile", 3.6, v3(BOX.x2 - 4, -0.6, -1), Palette.Dirt, M.Ground, false)
	s:ball("DirtPile", 2.4, v3(BOX.x2 - 5.5, -0.4, 1.4), Palette.Dirt, M.Ground, false)
	s:deco(
		"Spoon",
		v3(0.3, 0.12, 1.6),
		CFrame.new(BOX.x2 - 3.2, 1.1, 0.8) * CFrame.Angles(math.rad(-25), math.rad(40), 0),
		Palette.Chrome,
		M.Metal
	)

	-- Watch towers in the far corners, cameras on the walls
	Props.watchTower(folder, s:world(CFrame.lookAt(v3(BOX.x2 - 7, 0, BOX.z2 - 7), v3(140, 0, 0))), 20)
	Props.watchTower(folder, s:world(CFrame.lookAt(v3(BOX.x2 - 7, 0, BOX.z1 + 7), v3(140, 0, 0))), 20)
	for _, spot in
		{ v3(X1 + 0.8, 14, -45), v3(MESS.x2 + 2.8, 14, 50), v3(150, 14, BOX.z1 + 0.8), v3(120, 14, BOX.z2 - 0.8) }
	do
		Props.camera(folder, s:world(CFrame.lookAt(spot, v3(140, 6, 0))))
	end
	local yardSign = Props.sign(
		folder,
		s:world(CFrame.new(X1 + 0.3, 14, -28) * CFrame.Angles(0, -math.pi / 2, 0)),
		v2(12, 2.4),
		"☀️ THE YARD",
		rgb(60, 110, 70),
		{ text = Palette.White }
	)
	yardSign.Name = "YardSign"

	-- Trees beyond the walls
	for i = 0, 5 do
		Props.tree(folder, s:world(CFrame.new(BOX.x2 + 14 + (i % 2) * 6, 0, BOX.z1 + 6 + i * 22)), 1.5)
	end
	for i = 0, 3 do
		Props.tree(folder, s:world(CFrame.new(70 + i * 38, 0, BOX.z1 - 16 - (i % 2) * 6)), 1.5)
	end
end

-- Builds the yard. Returns spots where escaped Brainrots may roam (open lawn only, so they can
-- walk between any two of them in a straight line).
function Yard.build(folder: Instance): { Vector3 }
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	ground(folder, s)
	walls(folder, s)
	court(folder, s)
	gym(folder, s)
	grounds(folder, s)
	local roam = {}
	for _, x in { 104, 116, 136, 164, 184 } do
		for _, z in { -8, 2, 57 } do
			table.insert(roam, v3(x, Y, z))
		end
	end
	return roam
end

return Yard
