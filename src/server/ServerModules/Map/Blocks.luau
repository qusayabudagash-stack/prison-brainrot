-- The prison blocks you unlock one after another (Cell Block 2 onward), each 100 x 80 studs.
-- They share the same shell (walls, roof, lights, a gate at the entrance) and get their identity
-- from paint, light, and set dressing:
--   Cell Block 2      two tiers of cells and catwalks, cool blue light
--   Maximum Security  steel plating, solitary doors, a caged machine, alarms and lasers
--   Death Row         flickering lights, the Electric Throne, tombstones, goo and chains
--   Alien Block       a crashed UFO, specimen tanks, consoles and a teleporter
--   Secret Block      a starfield floor, rainbow crystals and a portal to nowhere
--
-- Gate hooks (used by Controllers/World and AreaService): a Model named "Gate" with an AreaId
-- attribute, a "Collider" part holding the Unlock prompt, "Bar" parts, and a "Sign" part.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Build = require(script.Parent.Parent.Build)
local Format = require(ReplicatedStorage.Modules.Format)
local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)
local Structure = require(script.Parent.Structure)
local Themes = require(script.Parent.Themes)

local Blocks = {}

local M = Enum.Material
local v3 = Vector3.new
local v2 = Vector2.new
local rgb = Color3.fromRGB

local Y = MapLayout.FLOOR_Y
local H = MapLayout.BLOCK_HEIGHT
local DOOR_W, DOOR_H = 20, 14

export type Frame = {
	area: AreaData.Area,
	theme: Themes.Theme,
	zStart: number,
	zEnd: number,
	half: number,
	zc: number,
	machineZ: number,
	s: Shapes.Shapes,
	folder: Instance,
}

-- Where each block's machine stands (MapService builds it).
function Blocks.machineCFrame(area: AreaData.Area): CFrame
	local zStart, zEnd = MapLayout.blockBounds(area.order)
	return CFrame.new(0, Y, (zStart + zEnd) / 2 + 5) * CFrame.Angles(0, math.pi, 0)
end

---------------------------------------------------------------------------
-- Shell and gate
---------------------------------------------------------------------------

local function shell(f: Frame)
	local theme = f.theme
	local style: Structure.WallStyle = { wall = theme.wall, paint = theme.paint, paintHeight = 8, thickness = 2 }
	Structure.floor(f.folder, "Floor", -f.half, f.half, f.zEnd, f.zStart, Y, theme.floor, theme.floorMaterial)
	for _, side in { -1, 1 } do
		Structure.wall(f.folder, v2(side * (f.half + 1), f.zStart), v2(side * (f.half + 1), f.zEnd - 2), Y, H, style)
	end
	local hasNext = AreaData.Areas[f.area.order + 1] ~= nil
	Structure.wall(
		f.folder,
		v2(-f.half - 2, f.zEnd - 1),
		v2(f.half + 2, f.zEnd - 1),
		Y,
		H,
		style,
		if hasNext then { { at = f.half + 2, width = DOOR_W, height = DOOR_H } } else nil
	)
	Structure.roof(f.folder, -f.half - 2, f.half + 2, f.zEnd - 2, f.zStart, Y + H, {
		beamEvery = 16,
		skylights = { { -12, 12, f.machineZ - 12, f.machineZ + 12 } },
	})
	-- Name sign inside the entrance, readable when you look back
	Props.sign(
		f.folder,
		f.s:world(CFrame.new(0, DOOR_H + 4, f.zStart - 2.2) * CFrame.Angles(0, math.pi, 0)),
		v2(24, 3.4),
		`{f.area.emoji} {f.area.name}`,
		theme.accent:Lerp(Palette.Ink, 0.35),
		{ text = Palette.White }
	)
end

local function gate(f: Frame)
	local area = f.area
	local s = Shapes.model(f.folder, "Gate", CFrame.new(0, Y, f.zStart - 1))
	local model = s.parent :: Model
	model:SetAttribute("AreaId", area.id)
	local collider =
		s:box("Collider", v3(DOOR_W, DOOR_H, 1), CFrame.new(0, DOOR_H / 2, 0), area.accentColor, M.ForceField)
	collider.Transparency = 0.3
	collider.CanQuery = true
	for i = -4, 4 do
		local bar = s:cyl("Bar", DOOR_H - 0.6, 0.6, CFrame.new(i * 2.2, DOOR_H / 2, 0.2), Palette.Bars, M.Metal, false)
		bar.CanCollide = false
	end
	for _, y in { 1.2, DOOR_H / 2, DOOR_H - 1 } do
		s:box("Bar", v3(DOOR_W - 0.4, 0.6, 0.7), CFrame.new(0, y, 0.2), Palette.Bars, M.Metal, false)
	end
	-- Padlock (named Bar so it vanishes with the bars once you unlock the block)
	s:box("Bar", v3(3, 2.6, 1.2), CFrame.new(0, DOOR_H / 2 - 0.4, 1.1), Palette.Gold, M.Metal, false)
	s:box("Bar", v3(0.5, 2, 0.5), CFrame.new(-0.9, DOOR_H / 2 + 1.6, 1.1), Palette.Chrome, M.Metal, false)
	s:box("Bar", v3(0.5, 2, 0.5), CFrame.new(0.9, DOOR_H / 2 + 1.6, 1.1), Palette.Chrome, M.Metal, false)
	s:box("Bar", v3(2.3, 0.5, 0.5), CFrame.new(0, DOOR_H / 2 + 2.4, 1.1), Palette.Chrome, M.Metal, false)
	Build.prompt(
		collider,
		"Unlock",
		"Unlock",
		`{area.emoji} {area.name} - {Format.money(area.unlockCost)}`,
		{ AreaId = area.id }
	).MaxActivationDistance =
		16

	-- Heavy frame, warning lights and hazard stripes on the approach side
	for _, side in { -1, 1 } do
		s:deco(
			"GatePost",
			v3(1.8, DOOR_H + 1.8, 2.8),
			CFrame.new(side * (DOOR_W / 2 + 0.9), (DOOR_H + 1.8) / 2, 0.4),
			Palette.SteelDark,
			M.Metal
		)
		s:deco(
			"GatePostStripe",
			v3(1.85, 1.2, 2.85),
			CFrame.new(side * (DOOR_W / 2 + 0.9), 3, 0.4),
			Palette.Hazard,
			M.SmoothPlastic
		)
		local beacon =
			s:ball("WarningLight", 1.2, v3(side * (DOOR_W / 2 + 0.9), DOOR_H + 2.4, 1.2), Palette.Red, M.Neon, false)
		beacon.CastShadow = false
		beacon:SetAttribute("Blink", true)
	end
	s:deco("GateHeader", v3(DOOR_W + 3.6, 1.8, 2.8), CFrame.new(0, DOOR_H + 0.9, 0.4), Palette.SteelDark, M.Metal)
	for i = 0, 6 do
		local color = if i % 2 == 0 then Palette.Hazard else Palette.HazardDark
		s:deco("GateStripe", v3(DOOR_W / 7, 0.06, 3), CFrame.new(-DOOR_W / 2 + (i + 0.5) * DOOR_W / 7, 0.03, 3), color).CastShadow =
			false
	end
	local sign = s:deco(
		"Sign",
		v3(DOOR_W + 2, 5, 0.4),
		CFrame.new(0, DOOR_H + 4.6, 1.4),
		area.accentColor:Lerp(Palette.Ink, 0.3),
		M.SmoothPlastic
	)
	sign.CastShadow = false
	Build.surfaceText(
		sign,
		Enum.NormalId.Back,
		`{area.emoji} {area.name}\n🔒 {Format.money(area.unlockCost)}`,
		{ textColor = Palette.White }
	)
end

local function lights(f: Frame, flicker: boolean?)
	for _, x in { -24, 24 } do
		for z = f.zStart - 10, f.zEnd + 10, -15 do
			Props.ceilingLight(f.folder, f.s:world(CFrame.new(x, H - 5, z)), 8, f.theme.light, 4)
		end
	end
	if flicker then
		for _, lamp in f.folder:GetChildren() do
			if lamp.Name == "CeilingLight" then
				lamp:SetAttribute("Flicker", true)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Cell Block 2
---------------------------------------------------------------------------

local function cellFacade(f: Frame, x: number, facing: number, z: number, y: number, label: string)
	local s = f.s
	local front = x + facing * 10
	Props.bars(f.folder, s:world(CFrame.new(front, y, z) * CFrame.Angles(0, math.pi / 2, 0)), 18, 11, 1.6, "CellBars")
	s:deco("Cot", v3(3, 0.8, 7), CFrame.new(x + facing * 2.2, y + 1.6, z - 4), rgb(210, 205, 190), M.Fabric)
	s:deco("CotFrame", v3(3.2, 1.2, 7.2), CFrame.new(x + facing * 2.2, y + 0.6, z - 4), Palette.Steel, M.Metal)
	s:deco("CellToilet", v3(2, 2.6, 2), CFrame.new(x + facing * 1.5, y + 1.3, z + 6), Palette.Chrome, M.Metal)
	local plate = s:deco("CellNumber", v3(0.1, 0.9, 2.6), CFrame.new(front + facing * 0.3, y + 10.2, z), Palette.White)
	Build.surfaceText(
		plate,
		if facing > 0 then Enum.NormalId.Right else Enum.NormalId.Left,
		label,
		{ textColor = Palette.Ink, strokeColor = Palette.White, pixelsPerStud = 40 }
	)
end

local function decorateCellBlock2(f: Frame)
	local s = f.s
	for _, side in { -1, 1 } do
		local back = side * f.half
		local facing = -side
		local count = 0
		for i = 0, 2 do
			local z = f.zStart - 20 - i * 20
			for tier = 0, 1 do
				count += 1
				cellFacade(f, back, facing, z, tier * 13, `B-{if side < 0 then "W" else "E"}{count}`)
			end
		end
		for i = 0, 3 do
			s:box(
				"Divider",
				v3(10, 25, 1),
				CFrame.new(back + facing * 5, 12.5, f.zStart - 10 - i * 20),
				Palette.Concrete,
				M.Concrete
			)
		end
		local front = back + facing * 10
		s:box(
			"UpperFloor",
			v3(10, 0.8, 60),
			CFrame.new(back + facing * 5, 12.6, f.zStart - 40),
			Palette.ConcreteDark,
			M.Concrete
		)
		s:box(
			"Catwalk",
			v3(5, 0.5, 64),
			CFrame.new(front + facing * 2.5, 12.75, f.zStart - 40),
			Palette.SteelDark,
			M.DiamondPlate
		)
		s:box(
			"Handrail",
			v3(0.3, 0.3, 64),
			CFrame.new(front + facing * 4.8, 16.4, f.zStart - 40),
			f.theme.accent,
			M.Metal
		)
		for z = f.zStart - 8, f.zStart - 72, -6 do
			s:deco("RailPost", v3(0.25, 3.4, 0.25), CFrame.new(front + facing * 4.8, 14.7, z), Palette.Steel, M.Metal)
		end
	end
	Props.directions(f.folder, s:world(CFrame.new(0, 20, f.zStart - 14)), { "CELL BLOCK 2", "⬇ ROLL MACHINE" }, 6)
	for _, x in { -14, 14 } do
		Props.bench(f.folder, s:world(CFrame.new(x, 0, f.machineZ + 16) * CFrame.Angles(0, math.pi, 0)), 8)
	end
	local bucket = CFrame.new(20, 0, f.zEnd + 12)
	s:cyl("MopBucket", 2, 2.4, bucket * CFrame.new(0, 1, 0), Palette.Hazard, M.SmoothPlastic)
	s:rod(
		"Mop",
		(bucket * CFrame.new(0, 1.5, 0)).Position,
		(bucket * CFrame.new(1, 7, 0.5)).Position,
		0.25,
		Palette.Wood,
		M.Wood,
		false
	)
	Props.cone(f.folder, s:world(CFrame.new(24, 0, f.zEnd + 14)))
	Props.camera(f.folder, s:world(CFrame.new(0, 22, f.zEnd + 1)))
end

---------------------------------------------------------------------------
-- Maximum Security
---------------------------------------------------------------------------

local function decorateMaxSecurity(f: Frame)
	local s = f.s
	-- Steel plating and hazard stripes along both walls
	for _, side in { -1, 1 } do
		local x = side * (f.half - 0.1)
		s:deco("Plating", v3(0.2, 8, f.zStart - f.zEnd - 4), CFrame.new(x, 4, f.zc), Palette.Steel, M.DiamondPlate)
		for i = 0, 18 do
			local color = if i % 2 == 0 then Palette.Hazard else Palette.HazardDark
			s:deco("Hazard", v3(3, 0.06, 4), CFrame.new(side * (f.half - 2), 0.03, f.zStart - 2 - i * 4 - 2), color).CastShadow =
				false
		end
		-- Solitary confinement doors
		for i = 0, 2 do
			local z = f.zStart - 18 - i * 22
			local door = CFrame.new(side * (f.half - 0.2), 0, z)
				* CFrame.Angles(0, if side < 0 then -math.pi / 2 else math.pi / 2, 0)
			s:deco("SolitaryFrame", v3(6, 10, 0.6), door * CFrame.new(0, 5, 0), Palette.SteelDark, M.Metal)
			s:deco("SolitaryDoor", v3(5, 9, 0.5), door * CFrame.new(0, 4.5, -0.2), Palette.Steel, M.DiamondPlate)
			s:glow("SolitaryWindow", v3(1.4, 0.6, 0.1), door * CFrame.new(0, 7, -0.48), rgb(255, 120, 90))
			s:deco("FoodHatch", v3(2, 0.8, 0.1), door * CFrame.new(0, 3.4, -0.48), Palette.SteelDark, M.Metal)
			local plate = s:deco("SolitaryPlate", v3(4, 0.8, 0.1), door * CFrame.new(0, 10.6, -0.35), Palette.Hazard)
			Build.surfaceText(
				plate,
				Enum.NormalId.Front,
				`SOLITARY 0{i + 1 + (if side > 0 then 3 else 0)}`,
				{ textColor = Palette.HazardDark, strokeColor = Palette.Hazard, pixelsPerStud = 40 }
			)
		end
	end
	-- The machine sits in a cage
	local mz = f.machineZ
	local r = 15
	for _, run in
		{
			{ v3(-r, 0, mz - r), v3(-r, 0, mz + r) },
			{ v3(r, 0, mz - r), v3(r, 0, mz + r) },
			{ v3(-r, 0, mz - r), v3(r, 0, mz - r) },
			{ v3(-r, 0, mz + r), v3(-6, 0, mz + r) },
			{ v3(6, 0, mz + r), v3(r, 0, mz + r) },
		}
	do
		Props.fence(f.folder, s:world(CFrame.new(run[1])).Position, s:world(CFrame.new(run[2])).Position, 9)
	end
	Props.warning(
		f.folder,
		s:world(CFrame.new(-10.5, 6, mz + r + 0.2) * CFrame.Angles(0, math.pi, 0)),
		"HIGH VOLTAGE (not really)",
		8
	)
	-- Alarm beacons
	for _, spot in
		{
			v3(-f.half + 0.8, 12, f.zStart - 8),
			v3(f.half - 0.8, 12, f.zStart - 8),
			v3(-f.half + 0.8, 12, f.zEnd + 8),
			v3(f.half - 0.8, 12, f.zEnd + 8),
		}
	do
		s:cyl("AlarmBase", 0.6, 1.4, CFrame.new(spot), Palette.SteelDark, M.Metal, false)
		local dome = s:ball("Alarm", 1.2, spot + v3(0, 0.6, 0), Palette.Red, M.Neon, false)
		dome:SetAttribute("Blink", true)
		dome.CastShadow = false
		s:light(dome, Palette.Red, 16, 1)
	end
	-- A laser grid guarding the far corner
	local laser = v3(34, 0, f.zEnd + 6)
	for _, dx in { -8, 8 } do
		s:box("LaserPost", v3(1, 7, 1), CFrame.new(laser + v3(dx, 3.5, 0)), Palette.SteelDark, M.Metal)
	end
	for i = 0, 4 do
		s:glow("Laser", v3(16, 0.12, 0.12), CFrame.new(laser + v3(0, 1 + i * 1.3, 0)), Palette.Red)
	end
	Props.watchTower(f.folder, s:world(CFrame.lookAt(v3(-40, 0, f.zEnd + 9), v3(0, 0, f.zc))), 12)
	for _, spot in { v3(-f.half + 1, 18, f.zc), v3(f.half - 1, 18, f.zc) } do
		Props.camera(f.folder, s:world(CFrame.lookAt(spot, v3(0, 5, f.zc))))
	end
	Props.sign(
		f.folder,
		s:world(CFrame.new(28, 12, f.zEnd + 0.2) * CFrame.Angles(0, math.pi, 0)),
		v2(22, 5),
		"⚠️ NO ESCAPING ⚠️\n(pretty please)",
		Palette.Hazard,
		{ text = Palette.HazardDark, stroke = Palette.Hazard }
	)
end

---------------------------------------------------------------------------
-- Death Row
---------------------------------------------------------------------------

local TOMBSTONE_JOKES =
	{ "RIP\nmy coins", "RIP\nWi-Fi", "RIP\nhomework", "RIP\nescape plan", "RIP\nbad luck", "RIP\nmy 1st roll" }

local function decorateDeathRow(f: Frame)
	local s = f.s
	local stone = rgb(150, 146, 160)
	-- Death row cells along the west wall
	for i = 0, 2 do
		cellFacade(f, -f.half, 1, f.zStart - 20 - i * 20, 0, `DR-{i + 1}`)
	end
	for i = 0, 3 do
		s:box("Divider", v3(10, 12, 1), CFrame.new(-f.half + 5, 6, f.zStart - 10 - i * 20), f.theme.wall, M.Concrete)
	end
	-- The Electric Throne, out of order
	local throne = CFrame.new(34, 0, f.zStart - 26) * CFrame.Angles(0, math.pi / 2, 0)
	s:box("Stage", v3(12, 1.2, 10), throne * CFrame.new(0, 0.6, 0), Palette.SteelDark, M.DiamondPlate)
	s:box("ThroneSeat", v3(4, 0.8, 4), throne * CFrame.new(0, 3.4, 0), Palette.WoodDark, M.Wood)
	s:box("ThroneBack", v3(4, 7, 0.8), throne * CFrame.new(0, 6.9, 1.8), Palette.WoodDark, M.Wood)
	for _, x in { -1.8, 1.8 } do
		s:deco("ThroneLeg", v3(0.6, 2.4, 0.6), throne * CFrame.new(x, 2.2, -1.6), Palette.WoodDark, M.Wood)
		s:deco("ThroneArm", v3(0.6, 0.5, 4), throne * CFrame.new(x, 5, 0), Palette.WoodDark, M.Wood)
		s:deco("Strap", v3(0.7, 0.3, 0.9), throne * CFrame.new(x, 5.3, -0.8), Palette.Ink, M.Fabric)
	end
	s:cyl("Helmet", 1.4, 2.4, throne * CFrame.new(0, 10.6, 1.2), Palette.Chrome, M.Metal, false)
	for i = 0, 2 do
		s:rod(
			"Cable",
			(throne * CFrame.new(-0.6 + i * 0.6, 11.3, 1.2)).Position,
			(throne * CFrame.new(-3 + i * 3, H - 0.5, 4)).Position,
			0.2,
			Palette.Ink,
			M.Rubber,
			false
		)
	end
	local sparkLamp =
		s:deco("ThroneSpot", v3(1.4, 1, 1.4), throne * CFrame.new(0, H - 3, -6), Palette.SteelDark, M.Metal)
	s:spot(sparkLamp, rgb(200, 255, 200), 30, 2, 30, Enum.NormalId.Bottom)
	Props.sign(
		f.folder,
		s:world(throne * CFrame.new(0, 2.2, -5.2)),
		v2(6, 1.6),
		"OUT OF ORDER",
		Palette.White,
		{ text = Palette.Red, stroke = Palette.White }
	)
	-- Tombstones with jokes
	for i, joke in TOMBSTONE_JOKES do
		local z = f.zc - 18 + (i - 1) * 7
		local at = CFrame.new(20 + (i % 2) * 4, 0, z) * CFrame.Angles(0, math.pi / 2, 0)
		local slab = s:box("Tombstone", v3(4, 5, 1.2), at * CFrame.new(0, 2.5, 0), stone, M.Slate)
		s:cyl("TombTop", 1.2, 4, at * CFrame.new(0, 5, 0) * CFrame.Angles(math.pi / 2, 0, 0), stone, M.Slate, false)
		s:cyl("TombDirt", 0.35, 3.6, at * CFrame.new(0, 0.15, -2.4), rgb(92, 76, 60), M.Ground, false)
		Build.surfaceText(slab, Enum.NormalId.Front, joke, { textColor = rgb(70, 60, 90), strokeColor = stone })
	end
	-- Goo, chains, cracks, cobwebs and bones
	for _, spot in { v3(-22, 0, -20), v3(18, 0, 18), v3(-14, 0, 24), v3(8, 0, -30), v3(-30, 0, 4) } do
		local goo =
			s:cyl("Goo", 0.08, 5 + (spot.X % 3), CFrame.new(spot + v3(0, 0.04, f.zc)), f.theme.accent, M.Neon, false)
		goo.Transparency = 0.2
		goo.CastShadow = false
	end
	for i = 0, 7 do
		local x, z = -30 + i * 9, f.zc + ((i % 3) - 1) * 18
		s:rod("Chain", v3(x, H, z), v3(x, H - 6 - (i % 3) * 2, z), 0.35, Palette.SteelDark, M.Metal, false)
	end
	for _, crack in
		{
			{ at = v3(f.half - 0.1, 14, f.zStart - 12), along = v3(0, 0, 1) },
			{ at = v3(-f.half + 0.1, 16, f.zc + 10), along = v3(0, 0, 1) },
			{ at = v3(12, 12, f.zEnd + 0.1), along = v3(1, 0, 0) },
		}
	do
		local p, dir = crack.at, crack.along
		local a, b, c = p, p + dir * 2 + v3(0, -3, 0), p + dir * -1 + v3(0, -6, 0)
		s:rod("Crack", a, b, 0.25, Palette.Ink, M.Slate, false)
		s:rod("Crack", b, c, 0.2, Palette.Ink, M.Slate, false)
	end
	for _, corner in { v3(-f.half, H - 1, f.zEnd), v3(f.half, H - 1, f.zEnd) } do
		local web = s:wedge(
			"Cobweb",
			v3(0.1, 5, 5),
			CFrame.new(corner + v3(if corner.X < 0 then 0.2 else -0.2, -2.5, 2.5))
				* CFrame.Angles(0, 0, 0)
				* CFrame.Angles(math.pi, 0, 0),
			rgb(235, 235, 235),
			M.SmoothPlastic,
			false
		)
		web.Transparency = 0.5
	end
	s:ball("Skull", 1.3, v3(-6, 0.65, f.zEnd + 6), rgb(235, 230, 210), M.SmoothPlastic, false)
	for i = 0, 3 do
		s:rod(
			"Bone",
			v3(-8 + i, 0.3, f.zEnd + 4 + (i % 2)),
			v3(-6 + i * 0.6, 0.3, f.zEnd + 7 - (i % 2)),
			0.35,
			rgb(235, 230, 210),
			M.SmoothPlastic,
			false
		)
	end
end

---------------------------------------------------------------------------
-- Alien Block
---------------------------------------------------------------------------

local function decorateAlienBlock(f: Frame)
	local s = f.s
	local glow = f.theme.accent
	local pink = f.theme.machine.glow
	-- A UFO crashed through the corner of the roof
	local ufo = CFrame.new(-30, 22, f.zEnd + 16) * CFrame.Angles(math.rad(18), 0, math.rad(-14))
	s:cyl("UFO", 2.6, 26, ufo, Palette.SteelLight, M.Metal)
	s:cyl("UFORim", 1, 27.5, ufo * CFrame.new(0, -0.6, 0), Palette.Steel, M.Metal, false)
	local dome = s:ball("UFODome", 11, (ufo * CFrame.new(0, 2, 0)).Position, rgb(150, 255, 230), M.Glass, false)
	dome.Transparency = 0.35
	for i = 0, 7 do
		local angle = i * math.pi / 4
		local light = s:ball(
			"UFOLight",
			1.4,
			(ufo * CFrame.new(math.cos(angle) * 12.4, -0.8, math.sin(angle) * 12.4)).Position,
			if i % 2 == 0 then glow else pink,
			M.Neon,
			false
		)
		light.CastShadow = false
	end
	for i, spot in { v3(-20, 0, f.zEnd + 10), v3(-36, 0, f.zEnd + 26), v3(-24, 0, f.zEnd + 30) } do
		s:deco(
			"Debris",
			v3(3 + i, 1.2, 2 + i * 0.5),
			CFrame.new(spot + v3(0, 0.6, 0)) * CFrame.Angles(0, i, math.rad(10 * i)),
			Palette.Steel,
			M.Metal
		)
	end
	s:cyl("Scorch", 0.06, 20, CFrame.new(-28, 0.03, f.zEnd + 18), rgb(40, 40, 40), M.SmoothPlastic, false).CastShadow =
		false
	-- Specimen tanks along the east wall
	for i = 0, 3 do
		local at = CFrame.new(f.half - 5, 0, f.zStart - 14 - i * 15)
		s:cyl("TankBase", 1.2, 5.6, at * CFrame.new(0, 0.6, 0), Palette.SteelDark, M.Metal)
		local glass = s:cyl("TankGlass", 9, 4.6, at * CFrame.new(0, 5.7, 0), Palette.Glass, M.Glass)
		glass.Transparency = 0.6
		local liquid = s:cyl("TankLiquid", 8.4, 4.2, at * CFrame.new(0, 5.4, 0), glow, M.Neon, false)
		liquid.Transparency = 0.55
		liquid.CastShadow = false
		s:cyl("TankCap", 1, 5.4, at * CFrame.new(0, 10.6, 0), Palette.SteelDark, M.Metal)
		s:ball("Specimen", 2.4, (at * CFrame.new(0, 5.6, 0)).Position, rgb(40, 70, 60), M.SmoothPlastic, false)
		for b = 0, 2 do
			s:ball(
				"Bubble",
				0.4,
				(at * CFrame.new(0.8 - b * 0.6, 7 + b * 1.2, -0.6)).Position,
				Palette.White,
				M.Glass,
				false
			).Transparency =
				0.3
		end
		local label = s:deco("TankLabel", v3(0.1, 0.8, 3), at * CFrame.new(-2.5, 2, 0), Palette.White)
		Build.surfaceText(
			label,
			Enum.NormalId.Left,
			`SPECIMEN #{i + 1}`,
			{ textColor = Palette.Ink, strokeColor = Palette.White, pixelsPerStud = 40 }
		)
	end
	-- Consoles and a teleporter pad
	for i = 0, 1 do
		local at = CFrame.new(-f.half + 4, 0, f.zStart - 12 - i * 14) * CFrame.Angles(0, -math.pi / 2, 0)
		s:box("Console", v3(8, 3.4, 3), at * CFrame.new(0, 1.7, 0), Palette.SteelDark, M.Metal)
		s:wedge("ConsoleTop", v3(8, 1, 3), at * CFrame.new(0, 3.9, 0), Palette.Steel, M.Metal)
		for k = 0, 1 do
			local screen = s:glow(
				"ConsoleScreen",
				v3(3.2, 2.2, 0.1),
				at * CFrame.new(-1.8 + k * 3.6, 6, 1.4),
				if k == 0 then glow else pink
			)
			Build.surfaceText(
				screen,
				Enum.NormalId.Front,
				if k == 0 then "👽 SIGNAL\nDETECTED" else "BRAINROT\nLEVELS: 9000",
				{ textColor = Palette.Ink, strokeColor = Palette.White, pixelsPerStud = 40 }
			)
		end
	end
	local pad = CFrame.new(28, 0, f.zEnd + 12)
	s:cyl("TeleporterPad", 0.8, 10, pad * CFrame.new(0, 0.4, 0), Palette.SteelLight, M.Metal)
	s:cyl("TeleporterGlow", 0.84, 8.4, pad * CFrame.new(0, 0.42, 0), glow, M.Neon, false).CastShadow = false
	local beam = s:cyl("TeleporterBeam", 16, 7, pad * CFrame.new(0, 8.8, 0), glow, M.Neon, false)
	beam.Transparency = 0.8
	beam.CastShadow = false
	-- Glowing floor lines and alien plants
	for _, x in { -18, 18 } do
		s:glow("FloorLine", v3(0.5, 0.06, f.zStart - f.zEnd - 8), CFrame.new(x, 0.03, f.zc), glow)
	end
	for i = 0, 3 do
		local at = v3(if i % 2 == 0 then -14 else 14, 0, f.zEnd + 30 - (i // 2) * 42)
		s:cyl("AlienStalk", 7, 0.7, CFrame.new(at + v3(0, 3.5, 0)), rgb(90, 220, 110), M.SmoothPlastic, false)
		local bulb = s:ball("AlienBulb", 2.6, at + v3(0, 7.5, 0), pink, M.Neon, false)
		s:light(bulb, pink, 14, 1)
	end
end

---------------------------------------------------------------------------
-- Secret Block
---------------------------------------------------------------------------

local RAINBOW = {
	rgb(255, 70, 90),
	rgb(255, 160, 40),
	rgb(255, 230, 60),
	rgb(80, 225, 110),
	rgb(60, 170, 255),
	rgb(170, 90, 255),
}

local function decorateSecretBlock(f: Frame)
	local s = f.s
	-- Stars under the glass floor
	local floor = f.folder:FindFirstChild("Floor") :: BasePart
	floor.Transparency = 0.35
	s:box("Void", v3(f.half * 2, 1, f.zStart - f.zEnd), CFrame.new(0, -1.1, f.zc), rgb(10, 8, 20), M.SmoothPlastic)
	for i = 1, 48 do
		local x = ((i * 37) % 96) - 48
		local z = f.zEnd + 2 + ((i * 53) % 76)
		local star = s:ball(
			"FloorStar",
			0.3 + (i % 3) * 0.15,
			v3(x, -0.5, z),
			if i % 5 == 0 then rgb(255, 200, 255) else Palette.White,
			M.Neon,
			false
		)
		star.CastShadow = false
	end
	-- Rainbow crystal pillars
	for i, color in RAINBOW do
		local side = if i % 2 == 0 then 1 else -1
		local at = CFrame.new(side * 38, 0, f.zStart - 12 - math.ceil(i / 2) * 18)
		local crystal = s:wedge(
			"Crystal",
			v3(3, 16, 3),
			at * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(45), 0),
			color,
			M.Neon,
			false
		)
		crystal.CastShadow = false
		s:wedge(
			"Crystal",
			v3(3, 16, 3),
			at * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(225), 0),
			color:Lerp(Palette.White, 0.3),
			M.Neon,
			false
		).CastShadow =
			false
		s:light(crystal, color, 18, 1)
	end
	-- A portal to nowhere on the far wall
	local portal = CFrame.new(0, 12, f.zEnd + 0.8)
	for i = 0, 15 do
		local a0, a1 = i * math.pi * 2 / 16, (i + 1) * math.pi * 2 / 16
		local p0 = (portal * CFrame.new(math.cos(a0) * 8, math.sin(a0) * 8, 0)).Position
		local p1 = (portal * CFrame.new(math.cos(a1) * 8, math.sin(a1) * 8, 0)).Position
		s:rod("PortalRing", p0, p1, 1, RAINBOW[i % #RAINBOW + 1], M.Neon, false).CastShadow = false
	end
	local swirl =
		s:cyl("PortalSwirl", 0.2, 15, portal * CFrame.Angles(math.pi / 2, 0, 0), rgb(120, 60, 200), M.Neon, false)
	swirl.Transparency = 0.3
	swirl:SetAttribute("Spin", true)
	-- Floating glitch cubes and question marks
	for i = 1, 8 do
		local at = v3(((i * 29) % 70) - 35, 10 + (i % 4) * 3, f.zStart - 10 - ((i * 17) % 60))
		local cube = s:box(
			"GlitchCube",
			v3(1.6, 1.6, 1.6),
			CFrame.new(at) * CFrame.Angles(i, i * 2, 0),
			RAINBOW[i % #RAINBOW + 1],
			M.Neon,
			false
		)
		cube.Transparency = 0.2
		cube:SetAttribute("Float", true)
	end
	for _, x in { -30, 30 } do
		Props.sign(
			f.folder,
			s:world(CFrame.new(x, 16, f.zEnd + 0.3) * CFrame.Angles(0, math.pi, 0)),
			v2(8, 5),
			"❓",
			rgb(30, 20, 60),
			{ text = rgb(255, 150, 255), glow = false }
		)
	end
end

local DECORATORS: { [string]: (Frame) -> () } = {
	CellBlock2 = decorateCellBlock2,
	MaxSecurity = decorateMaxSecurity,
	DeathRow = decorateDeathRow,
	AlienBlock = decorateAlienBlock,
	SecretBlock = decorateSecretBlock,
}

function Blocks.build(prison: Instance, area: AreaData.Area)
	local folder = Build.folder(prison, area.id)
	local zStart, zEnd, half = MapLayout.blockBounds(area.order)
	local zc = (zStart + zEnd) / 2
	local frame: Frame = {
		area = area,
		theme = Themes[area.id],
		zStart = zStart,
		zEnd = zEnd,
		half = half,
		zc = zc,
		machineZ = zc + 5,
		s = Shapes.new(folder, CFrame.new(0, Y, 0)),
		folder = folder,
	}
	shell(frame)
	gate(frame)
	lights(frame, area.id == "DeathRow")
	local decorate = DECORATORS[area.id]
	if decorate then
		decorate(frame)
	end
end

return Blocks
