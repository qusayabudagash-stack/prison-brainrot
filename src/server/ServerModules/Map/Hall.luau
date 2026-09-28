-- The main hall (Cell Block 1): where you spawn, get checked in and roll.
--
--   Intake (north)      front doors, spawn, benches, vending machines, the founder's statue,
--                       the commissary and the records office, leaderboards on the wall
--   Checkpoint (z 34)   metal detectors, an X-ray belt, the security desk, the big title sign
--   Roll hall (south)   the first roll machine under a skylight, the workshop, the parole office,
--                       the Luck-O-Mat and the mailroom beside the gate to Cell Block 2
-- Doorways lead west into the cell wing, east into the mess hall and out to the yard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Build = require(script.Parent.Parent.Build)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)
local Stations = require(script.Parent.Stations)
local Structure = require(script.Parent.Structure)
local Themes = require(script.Parent.Themes)

local Hall = {}

local M = Enum.Material
local v3 = Vector3.new
local v2 = Vector2.new
local rgb = Color3.fromRGB

local Y = MapLayout.FLOOR_Y
local BOX = MapLayout.Hall
local CHECK_Z = MapLayout.CHECKPOINT_Z
local THEME = Themes.CellBlock1
local MACHINE_Z = -16

-- Facing helpers for things placed against walls (front = the direction they face).
local FACE_EAST = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_WEST = CFrame.Angles(0, math.pi / 2, 0)
local FACE_NORTH = CFrame.Angles(0, math.pi, 0)

Hall.MACHINE_CFRAME = CFrame.new(0, Y, MACHINE_Z) * FACE_NORTH
Hall.SPAWN = v3(0, Y, 64)

local function shell(folder: Instance)
	local style: Structure.WallStyle = { wall = THEME.wall, paint = THEME.paint, paintHeight = 8, thickness = 2 }
	local h = BOX.height
	Structure.floor(folder, "Floor", BOX.x1, BOX.x2, BOX.z1, BOX.z2, Y, THEME.floor, THEME.floorMaterial)
	-- North wall: the front doors behind the spawn (leaderboards hang either side of them)
	Structure.wall(folder, v2(BOX.x1, BOX.z2 + 1), v2(BOX.x2, BOX.z2 + 1), Y, h, style, {
		{ at = 40, width = 14, height = 14 },
	})
	-- West wall: the cell wing archway, windows onto the grounds past the wing
	Structure.wall(folder, v2(BOX.x1 - 1, BOX.z1), v2(BOX.x1 - 1, BOX.z2 + 2), Y, h, style, {
		{ at = 60, width = 24, height = 16 },
		{ at = 128, width = 8, height = 9, sill = 6 },
	})
	-- East wall: mess hall doorway and the yard door
	Structure.wall(folder, v2(BOX.x2 + 1, BOX.z1), v2(BOX.x2 + 1, BOX.z2 + 2), Y, h, style, {
		{ at = 32, width = 12, height = 12 },
		{ at = 82, width = 16, height = 14 },
		{ at = 128, width = 8, height = 9, sill = 6 },
	})
	-- South wall: the gate to Cell Block 2 (the gate itself belongs to that block)
	Structure.wall(folder, v2(BOX.x1 - 2, BOX.z1 - 1), v2(BOX.x2 + 2, BOX.z1 - 1), Y, h, style, {
		{ at = 42, width = 20, height = 14 },
	})
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	-- Fake daylight in the side windows
	Structure.window(s, CFrame.new(BOX.x1 - 1, 0, BOX.z1 + 128) * CFrame.Angles(0, -math.pi / 2, 0), 8, 9, 6)
	Structure.window(s, CFrame.new(BOX.x2 + 1, 0, BOX.z1 + 128) * CFrame.Angles(0, math.pi / 2, 0), 8, 9, 6)

	-- Pillars and roof, with a skylight over the machine and one over the intake
	for _, z in { -44, -14, 16, 50 } do
		for _, x in { -26, 26 } do
			Structure.pillar(folder, v3(x, Y, z), 3, h, THEME.wall)
		end
	end
	Structure.roof(folder, BOX.x1 - 2, BOX.x2 + 2, BOX.z1 - 2, BOX.z2 + 2, Y + h, {
		beamEvery = 15,
		skylights = { { -12, 12, MACHINE_Z - 12, MACHINE_Z + 12 }, { -10, 10, 50, 66 } },
	})
	-- Rooftop machinery, seen from the yard
	for _, z in { -44, 30 } do
		Props.hvac(folder, CFrame.new(26, Y + h + 1.2, z))
	end
	for _, spot in { v3(-28, 0, 8), v3(30, 0, -12), v3(-24, 0, -40) } do
		Props.roofVent(folder, CFrame.new(spot.X, Y + h + 1.2, spot.Z), 4)
	end
end

local function frontDoors(s: Shapes.Shapes)
	local z = BOX.z2 + 0.4
	for _, side in { -1, 1 } do
		local door = s:box("FrontDoor", v3(6.6, 13.4, 0.6), CFrame.new(side * 3.35, 6.7, z), Palette.Steel, M.Metal)
		door.CanCollide = true
		s:deco("DoorWindow", v3(2.4, 3, 0.1), CFrame.new(side * 3.35, 9.5, z - 0.35), Palette.Glass, M.Glass)
		s:deco("PushBar", v3(4.6, 0.4, 0.4), CFrame.new(side * 3.35, 5, z - 0.5), Palette.Chrome, M.Metal)
	end
	local exitSign = s:glow("ExitSign", v3(4, 1.3, 0.3), CFrame.new(0, 15.2, z - 0.3), rgb(40, 200, 90))
	Build.surfaceText(
		exitSign,
		Enum.NormalId.Front,
		"NO EXIT",
		{ textColor = Palette.White, strokeColor = rgb(20, 90, 40), pixelsPerStud = 40 }
	)
	Props.clock(s.parent, s:world(CFrame.new(0, 18.5, z - 0.3)))
	-- Painted intake box on the floor where you spawn
	local pad =
		s:deco("IntakePad", v3(14, 0.06, 10), CFrame.new(0, 0.03, Hall.SPAWN.Z), Palette.Hazard, M.SmoothPlastic)
	pad.CastShadow = false
	local inner = s:deco("IntakePadInner", v3(13, 0.07, 9), CFrame.new(0, 0.035, Hall.SPAWN.Z), THEME.floor, M.Marble)
	inner.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 1
	gui.Parent = inner
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.5)
	label.Position = UDim2.fromScale(0, 0.25)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Palette.HazardDark
	label.TextTransparency = 0.2
	label.Text = "NEW INMATES"
	label.Rotation = 180
	label.Parent = gui
end

local function checkpoint(s: Shapes.Shapes)
	local z = CHECK_Z
	-- Three metal detectors with glass barriers between them
	for _, x in { -12, 0, 12 } do
		Props.metalDetector(s.parent, s:world(CFrame.new(x, 0, z)))
	end
	for _, span in { { -38, -15 }, { -9, -3 }, { 3, 9 }, { 15, 38 } } do
		local a, b = span[1], span[2]
		local mid, length = (a + b) / 2, b - a
		s:box("Barrier", v3(length, 1, 0.8), CFrame.new(mid, 0.5, z), Palette.SteelDark, M.Metal)
		s:box("BarrierRail", v3(length, 0.4, 0.6), CFrame.new(mid, 4.2, z), Palette.Chrome, M.Metal)
		local glass = s:box("BarrierGlass", v3(length, 3, 0.2), CFrame.new(mid, 2.5, z), Palette.Glass, M.Glass)
		glass.Transparency = 0.7
		for x = a, b, 6 do
			s:deco("BarrierPost", v3(0.4, 4.4, 0.4), CFrame.new(x, 2.2, z), Palette.SteelDark, M.Metal)
		end
	end
	-- Security desk facing the new arrivals
	Props.securityDesk(s.parent, s:world(CFrame.new(26, 0, z + 5) * FACE_NORTH))
	-- X-ray belt: bags go in, Brainrots come out
	local belt = CFrame.new(-26, 0, z + 5)
	s:box("BeltBase", v3(14, 2.6, 3), belt * CFrame.new(0, 1.3, 0), Palette.SteelLight, M.Metal)
	s:deco("Belt", v3(14.2, 0.2, 2.6), belt * CFrame.new(0, 2.7, 0), Palette.Rubber, M.Fabric)
	s:box("XRayTunnel", v3(5, 4.4, 3.6), belt * CFrame.new(0, 4.9, 0), Palette.SteelLight, M.SmoothPlastic)
	for i = 0, 4 do
		s:deco("Curtain", v3(0.8, 2.2, 0.1), belt * CFrame.new(-2.6, 3.9, -1.2 + i * 0.6), rgb(60, 60, 60), M.Fabric)
	end
	s:deco("Suitcase", v3(2.4, 1.6, 1.4), belt * CFrame.new(-5, 3.6, 0), Palette.OrangeDark, M.Fabric)
	s:deco("Tray", v3(2, 0.4, 1.6), belt * CFrame.new(4.8, 3, 0), Palette.Rubber, M.SmoothPlastic)
	local monitorAt = belt * CFrame.new(0, 8.4, 0) * FACE_NORTH
	s:deco("XRayMonitor", v3(3.4, 2.4, 0.4), monitorAt, Palette.SteelDark, M.SmoothPlastic)
	s:deco("XRayMonitorArm", v3(0.4, 1.2, 0.4), belt * CFrame.new(0, 6.8, 0), Palette.SteelDark, M.Metal)
	local screen = s:glow("XRayScreen", v3(3, 2, 0.05), monitorAt * CFrame.new(0, 0, -0.23), rgb(70, 150, 200))
	Build.surfaceText(
		screen,
		Enum.NormalId.Front,
		"SCANNING...\n1 POTATO\n0 ESCAPE PLANS",
		{ textColor = Palette.White, strokeColor = rgb(20, 60, 90), pixelsPerStud = 40 }
	)

	-- The big title sign hanging over the checkpoint
	local signY = 24
	for _, x in { -16, 16 } do
		s:deco(
			"SignChain",
			v3(0.3, BOX.height - signY - 5, 0.3),
			CFrame.new(x, signY + 5 + (BOX.height - signY - 5) / 2, z),
			Palette.SteelDark,
			M.Metal
		)
	end
	s:deco("TitleFrame", v3(46, 10, 0.4), CFrame.new(0, signY, z), Palette.SteelDark, M.Metal)
	local board = s:deco("Title", v3(44, 8.4, 1), CFrame.new(0, signY, z), rgb(28, 30, 48), M.SmoothPlastic)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local label = Build.surfaceText(
			board,
			face,
			`🧠 {GameConfig.GAME_NAME} 🧠\n<font size="36">{GameConfig.TAGLINE}</font>`,
			{
				textColor = Palette.Gold,
				strokeColor = rgb(120, 50, 10),
				pixelsPerStud = 14,
			}
		)
		label.Font = Enum.Font.FredokaOne
	end
	for _, y in { -4.6, 4.6 } do
		s:glow("TitleTrim", v3(46, 0.4, 1.1), CFrame.new(0, signY + y, z), Palette.Orange)
	end
	local lampL = s:deco("TitleLamp", v3(1.2, 0.8, 1.2), CFrame.new(-12, signY + 7, z - 5), Palette.SteelDark, M.Metal)
	s:spot(lampL, Palette.LightWarm, 20, 1.5, 60, Enum.NormalId.Bottom)
	local lampR = s:deco("TitleLamp", v3(1.2, 0.8, 1.2), CFrame.new(12, signY + 7, z - 5), Palette.SteelDark, M.Metal)
	s:spot(lampR, Palette.LightWarm, 20, 1.5, 60, Enum.NormalId.Bottom)
end

local function intake(s: Shapes.Shapes)
	local folder = s.parent
	for _, x in { -36.5, 36.5 } do
		local facing = if x < 0 then FACE_EAST else FACE_WEST
		for _, z in { 62, 70 } do
			Props.bench(folder, s:world(CFrame.new(x, 0, z) * facing), 7)
		end
		Props.plant(folder, s:world(CFrame.new(x, 0, 74.5)))
	end
	Props.vending(folder, s:world(CFrame.new(-37.6, 0, 42) * FACE_EAST), rgb(210, 50, 50), "🥤 SODA")
	Props.vending(folder, s:world(CFrame.new(37.6, 0, 42) * FACE_WEST), rgb(40, 110, 210), "🍫 SNACKS")
	Props.trashCan(folder, s:world(CFrame.new(-37.2, 0, 47)))
	Props.trashCan(folder, s:world(CFrame.new(37.2, 0, 47)))
	Props.noticeBoard(folder, s:world(CFrame.new(-38.8, 7, 67) * FACE_EAST), {
		"RULE #1\nNO\nESCAPING",
		"RULE #2\nROLL\nDAILY",
		"RULE #3\nFEED YOUR\nBRAINROT",
		"LOST:\nMY\nCOINS",
		"GYM\nCLOSED\n(FOREVER)",
		"WANTED:\n???",
	})
	Props.poster(
		folder,
		s:world(CFrame.new(38.9, 8, 67) * FACE_WEST),
		v2(4, 5.2),
		"EMPLOYEE\nOF THE\nMONTH\n\n🥇\nGOLDEN\nWARDEN",
		rgb(40, 66, 140)
	)

	-- The founder's statue: a golden Potato Prisoner on a plinth, off to the side so the view
	-- from the spawn runs straight through the checkpoint to the roll machine
	local plinth = CFrame.lookAt(v3(-15, 0, 50), v3(0, 0, Hall.SPAWN.Z))
	s:box("Plinth", v3(6, 3, 6), plinth * CFrame.new(0, 1.5, 0), Palette.ConcreteWarm, M.Marble)
	s:box("PlinthTop", v3(6.6, 0.5, 6.6), plinth * CFrame.new(0, 3.25, 0), Palette.SteelDark, M.Marble)
	s:box("PlinthFoot", v3(7, 0.6, 7), plinth * CFrame.new(0, 0.3, 0), Palette.SteelDark, M.Marble)
	local plaque = s:deco("Plaque", v3(4.4, 1.6, 0.1), plinth * CFrame.new(0, 1.7, -3.06), Palette.Gold, M.Foil)
	Build.surfaceText(
		plaque,
		Enum.NormalId.Front,
		"OUR FOUNDER\nPotato Prisoner, 1987",
		{ textColor = Palette.Ink, strokeColor = Palette.Gold, pixelsPerStud = 40 }
	)

	-- A trophy case on the other side, for balance (and bragging)
	local case = CFrame.lookAt(v3(15, 0, 50), v3(0, 0, Hall.SPAWN.Z))
	s:box("CaseCabinet", v3(7, 3, 3.4), case * CFrame.new(0, 1.5, 0), Palette.WoodDark, M.Wood)
	local glass = s:box("CaseGlass", v3(6.6, 4.6, 3), case * CFrame.new(0, 5.3, 0), Palette.Glass, M.Glass)
	glass.Transparency = 0.7
	s:deco("CaseTop", v3(7, 0.4, 3.4), case * CFrame.new(0, 7.8, 0), Palette.WoodDark, M.Wood)
	for i, height in { 2.6, 3.4, 2.2 } do
		local x = -2.2 + (i - 1) * 2.2
		s:cyl("TrophyBase", 0.5, 1.2, case * CFrame.new(x, 3.25, 0), Palette.Ink, M.Marble, false)
		s:cyl(
			"TrophyStem",
			height - 1.4,
			0.3,
			case * CFrame.new(x, 3.5 + (height - 1.4) / 2, 0),
			Palette.Gold,
			M.Foil,
			false
		)
		s:ball("TrophyCup", 1.2, (case * CFrame.new(x, 3.2 + height - 0.4, 0)).Position, Palette.Gold, M.Foil, false)
	end
	local caseLabel = s:deco("CaseLabel", v3(4.4, 0.9, 0.1), case * CFrame.new(0, 1.8, -1.75), Palette.Gold, M.Foil)
	Build.surfaceText(
		caseLabel,
		Enum.NormalId.Front,
		"BEST ROLLERS OF 1987",
		{ textColor = Palette.Ink, strokeColor = Palette.Gold, pixelsPerStud = 40 }
	)
	local statue = BrainrotModel.build("TralaleroTralala", { variant = "Golden", scale = 1.1 })
	statue.Name = "FounderStatue"
	statue:PivotTo(s:world(plinth * CFrame.new(0, 3.5, 0)))
	statue.Parent = folder

	-- Stations along the intake walls
	Stations.build(folder, "ShopStation", s:world(CFrame.new(BOX.x1 + 4.5, 0, 55) * FACE_EAST))
	Stations.build(folder, "BookStation", s:world(CFrame.new(BOX.x2 - 4.5, 0, 55) * FACE_WEST))
end

local function rollHall(s: Shapes.Shapes)
	local folder = s.parent
	-- A painted ring around the machine and a guide line from the checkpoint
	local ring = s:cyl("MachineRing", 0.06, 32, CFrame.new(0, 0.03, MACHINE_Z), Palette.Hazard, M.SmoothPlastic, false)
	ring.CastShadow = false
	local inner = s:cyl("MachineRingInner", 0.07, 30.6, CFrame.new(0, 0.035, MACHINE_Z), THEME.floor, M.Marble, false)
	inner.CastShadow = false
	for i = 0, 5 do
		s:deco("GuideArrow", v3(1.2, 0.07, 3), CFrame.new(0, 0.04, CHECK_Z - 5 - i * 4.4), Palette.Hazard).CastShadow =
			false
	end
	-- Queue ropes either side of the approach
	for _, x in { -5.5, 5.5 } do
		Props.ropeLine(folder, {
			s:world(CFrame.new(x, 0, 16)).Position,
			s:world(CFrame.new(x, 0, 8)).Position,
			s:world(CFrame.new(x, 0, 1)).Position,
		}, Palette.Red)
	end
	-- Stage lights on stands, aimed at the machine
	for _, x in { -18, 18 } do
		local base = CFrame.new(x, 0, MACHINE_Z + 6)
		s:cyl("StandFoot", 0.3, 2.4, base * CFrame.new(0, 0.15, 0), Palette.SteelDark, M.Metal, false)
		s:cyl("Stand", 3, 0.3, base * CFrame.new(0, 1.6, 0), Palette.SteelDark, M.Metal, false)
		local aim = CFrame.lookAt((base * CFrame.new(0, 3.4, 0)).Position, v3(0, 8, MACHINE_Z))
		s:deco("StageLight", v3(1.4, 1.4, 2.2), aim, Palette.SteelDark, M.Metal)
		local lens = s:glow("StageLightLens", v3(1.1, 1.1, 0.1), aim * CFrame.new(0, 0, -1.12), THEME.machine.glow)
		s:spot(lens, THEME.machine.glow, 28, 2, 40, Enum.NormalId.Front)
	end

	-- Stations around the roll hall
	Stations.build(folder, "UpgradeStation", s:world(CFrame.new(BOX.x1 + 4.5, 0, -44) * FACE_EAST))
	Stations.build(folder, "RebirthStation", s:world(CFrame.new(BOX.x2 - 4.5, 0, -46) * FACE_WEST))
	Stations.build(folder, "FreeLuckStation", s:world(CFrame.new(-22, 0, BOX.z1 + 4.5) * FACE_NORTH))
	Stations.build(folder, "DailyRollStation", s:world(CFrame.new(22, 0, BOX.z1 + 4.5) * FACE_NORTH))

	-- Doorway signs
	Props.directions(folder, s:world(CFrame.new(-33, 17.5, 0) * FACE_EAST), { "◀ CELL BLOCK A", "YOUR CELL" }, 6)
	Props.directions(folder, s:world(CFrame.new(33, 16.5, 22) * FACE_WEST), { "MESS HALL ▶" }, 6)
	Props.directions(folder, s:world(CFrame.new(33, 15.5, -28) * FACE_WEST), { "THE YARD ▶" }, 6)
	Props.warning(folder, s:world(CFrame.new(0, 17.6, BOX.z1 + 1.2) * FACE_NORTH), "AUTHORIZED INMATES ONLY", 12)
end

local function fixtures(s: Shapes.Shapes)
	local folder = s.parent
	-- Hanging fluorescent rows
	for _, x in { -14, 14 } do
		for z = -50, 70, 15 do
			Props.ceilingLight(folder, s:world(CFrame.new(x, BOX.height - 6, z)), 8, THEME.light, 5)
		end
	end
	-- Pipes running along the top of the walls
	for _, x in { BOX.x1 + 0.9, BOX.x2 - 0.9 } do
		Props.pipe(folder, {
			s:world(CFrame.new(x, BOX.height - 3, BOX.z1 + 1)).Position,
			s:world(CFrame.new(x, BOX.height - 3, BOX.z2 - 1)).Position,
		}, 1.2, Palette.Steel)
		Props.pipe(folder, {
			s:world(CFrame.new(x, BOX.height - 4.6, BOX.z1 + 1)).Position,
			s:world(CFrame.new(x, BOX.height - 4.6, BOX.z2 - 1)).Position,
		}, 0.7, rgb(160, 60, 50))
	end
	-- Cameras watching every corner
	for _, spot in
		{
			CFrame.new(BOX.x1 + 1.2, 16, BOX.z2 - 1.2) * CFrame.Angles(0, math.rad(-135), 0),
			CFrame.new(BOX.x2 - 1.2, 16, BOX.z2 - 1.2) * CFrame.Angles(0, math.rad(135), 0),
			CFrame.new(BOX.x1 + 1.2, 16, BOX.z1 + 1.2) * CFrame.Angles(0, math.rad(-45), 0),
			CFrame.new(BOX.x2 - 1.2, 16, BOX.z1 + 1.2) * CFrame.Angles(0, math.rad(45), 0),
		}
	do
		Props.camera(folder, s:world(spot))
	end
	-- Posters in the roll hall
	Props.poster(
		folder,
		s:world(CFrame.new(BOX.x1 + 1.1, 8, -26) * FACE_EAST),
		v2(4, 5.4),
		"ROLL\nRESPONSIBLY\n\n🎰\n(or don't)",
		rgb(200, 70, 50)
	)
	Props.poster(
		folder,
		s:world(CFrame.new(BOX.x2 - 1.1, 8, -10) * FACE_WEST),
		v2(4, 5.4),
		"WANTED\n\n❓\n\nTHE SECRET\nBRAINROT",
		rgb(60, 50, 90)
	)
end

-- Builds the hall into `folder`. The machine is built separately (MapService puts every
-- machine in Workspace.RollMachines).
function Hall.build(folder: Instance)
	shell(folder)
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	frontDoors(s)
	checkpoint(s)
	intake(s)
	rollHall(s)
	fixtures(s)
end

return Hall
