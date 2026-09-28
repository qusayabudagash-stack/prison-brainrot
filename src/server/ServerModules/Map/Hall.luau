-- The main hall (Cell Block 1): where you spawn, get checked in and roll.
--
--   Intake (north)      front doors, spawn, benches, vending machines, the founder's statue,
--                       the commissary and the records office, leaderboards on the wall
--   Checkpoint (z 34)   metal detectors, an X-ray belt, the security desk, the big title sign
--   Roll hall (south)   the hero roll machine on its stage under a skylight, reached along a tiled
--                       runner through a colonnade of rarity banners (rarer as you get closer),
--                       with balconies along both walls; the workshop, the parole office, the
--                       Luck-O-Mat and the mailroom sit in the alcoves under the balconies
-- Doorways lead west into the cell wing, east into the mess hall and out to the yard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
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
local BALCONY_Y = 18 -- balcony deck height above the floor
local BALCONY_DEPTH = 7
local RUNNER_WIDTH = 10

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
	-- Side walls: doorways below, a row of high clerestory windows above the balconies
	local clerestory: { Structure.Opening } = {}
	for z = BOX.z1 + 12, CHECK_Z - 6, 16 do
		table.insert(clerestory, { at = z - BOX.z1, width = 7, height = 6.5, sill = BALCONY_Y + 5 })
	end
	local west: { Structure.Opening } = table.clone(clerestory)
	table.insert(west, { at = 60, width = 24, height = 16 })
	table.insert(west, { at = 128, width = 8, height = 9, sill = 6 })
	Structure.wall(folder, v2(BOX.x1 - 1, BOX.z1), v2(BOX.x1 - 1, BOX.z2 + 2), Y, h, style, west)
	local east: { Structure.Opening } = table.clone(clerestory)
	table.insert(east, { at = 32, width = 12, height = 12 })
	table.insert(east, { at = 82, width = 16, height = 14 })
	table.insert(east, { at = 128, width = 8, height = 9, sill = 6 })
	Structure.wall(folder, v2(BOX.x2 + 1, BOX.z1), v2(BOX.x2 + 1, BOX.z2 + 2), Y, h, style, east)
	-- South wall: the gate to Cell Block 2 (the gate itself belongs to that block)
	Structure.wall(folder, v2(BOX.x1 - 2, BOX.z1 - 1), v2(BOX.x2 + 2, BOX.z1 - 1), Y, h, style, {
		{ at = 42, width = 20, height = 14 },
	})
	local s = Shapes.new(folder, CFrame.new(0, Y, 0))
	-- Daylight in every window
	for _, opening in clerestory do
		for _, side in { -1, 1 } do
			local x = if side < 0 then BOX.x1 - 1 else BOX.x2 + 1
			Structure.window(
				s,
				CFrame.new(x, 0, BOX.z1 + opening.at) * CFrame.Angles(0, side * math.pi / 2, 0),
				opening.width,
				opening.height,
				opening.sill :: number
			)
		end
	end
	Structure.window(s, CFrame.new(BOX.x1 - 1, 0, BOX.z1 + 128) * CFrame.Angles(0, -math.pi / 2, 0), 8, 9, 6)
	Structure.window(s, CFrame.new(BOX.x2 + 1, 0, BOX.z1 + 128) * CFrame.Angles(0, math.pi / 2, 0), 8, 9, 6)

	-- Roof with beams, a big skylight over the machine and one over the intake
	Structure.roof(folder, BOX.x1 - 2, BOX.x2 + 2, BOX.z1 - 2, BOX.z2 + 2, Y + h, {
		beamEvery = 12,
		skylights = { { -14, 14, MACHINE_Z - 14, MACHINE_Z + 14 }, { -10, 10, 50, 66 } },
	})
	-- Rooftop machinery, seen from the yard
	for _, z in { -44, 30 } do
		Props.hvac(folder, CFrame.new(26, Y + h + 1.2, z))
	end
	for _, spot in { v3(-28, 0, 8), v3(30, 0, -12), v3(-24, 0, -40) } do
		Props.roofVent(folder, CFrame.new(spot.X, Y + h + 1.2, spot.Z), 4)
	end
end

-- Cantilevered balconies along both walls of the roll hall: they break the tall walls into two
-- levels and turn the station walls below into alcoves.
local function balconies(s: Shapes.Shapes)
	local z1, z2 = BOX.z1 + 1, CHECK_Z - 3
	local length = z2 - z1
	local zc = (z1 + z2) / 2
	for _, side in { -1, 1 } do
		local wallX = if side < 0 then BOX.x1 else BOX.x2
		local edge = wallX - side * BALCONY_DEPTH
		local center = (wallX + edge) / 2
		s:box(
			"Balcony",
			v3(BALCONY_DEPTH, 0.8, length),
			CFrame.new(center, BALCONY_Y - 0.4, zc),
			Palette.Frame,
			M.Concrete
		)
		s:deco(
			"BalconyFloor",
			v3(BALCONY_DEPTH - 0.4, 0.1, length),
			CFrame.new(center, BALCONY_Y + 0.05, zc),
			Palette.Tile,
			M.CeramicTiles
		)
		s:deco(
			"BalconyFascia",
			v3(0.5, 1.8, length),
			CFrame.new(edge, BALCONY_Y - 0.6, zc),
			THEME.paint,
			M.SmoothPlastic
		)
		s:deco(
			"FasciaStripe",
			v3(0.56, 0.4, length),
			CFrame.new(edge, BALCONY_Y - 0.2, zc),
			Palette.Stripe,
			M.SmoothPlastic
		).CastShadow =
			false
		-- Glass railing with a charcoal handrail
		local railX = edge + side * 0.3
		local glass =
			s:deco("RailGlass", v3(0.15, 2.8, length), CFrame.new(railX, BALCONY_Y + 1.5, zc), Palette.Glass, M.Glass)
		glass.Transparency = 0.65
		glass.CastShadow = false
		s:box("Handrail", v3(0.4, 0.3, length), CFrame.new(railX, BALCONY_Y + 3, zc), Palette.Frame, M.Metal)
		for z = z1, z2, 12 do
			s:deco("RailPost", v3(0.3, 3, 0.3), CFrame.new(railX, BALCONY_Y + 1.5, z), Palette.Frame, M.Metal)
		end
		-- Diagonal braces back to the wall, and downlights under the deck
		for z = z1 + 6, z2 - 2, 12 do
			local top = v3(edge + side * 0.6, BALCONY_Y - 0.8, z)
			local foot = v3(wallX - side * 0.2, BALCONY_Y - 6, z)
			s:rod("Brace", foot, top, 0.5, Palette.Frame, M.Metal, false)
			local downlight =
				s:cyl("Downlight", 0.1, 1, CFrame.new(center, BALCONY_Y - 0.85, z), Palette.LightWarm, M.Neon, false)
			downlight.CastShadow = false
			s:spot(downlight, Palette.LightWarm, 14, 0.9, 80, Enum.NormalId.Bottom)
		end
		-- A few planters up top
		for z = z1 + 18, z2 - 10, 30 do
			Props.plant(s.parent, s:world(CFrame.new(wallX - side * 1.8, BALCONY_Y, z)))
		end
	end
end

-- A colonnade either side of the runner. Each column carries a banner in a rarity color, rarest
-- nearest the machine, so the walk from the checkpoint builds up to it.
local function colonnade(s: Shapes.Shapes)
	local rows = { 26, 12, -2, -30, -44 }
	local banner = 1
	for _, z in rows do
		for _, side in { -1, 1 } do
			local x = side * 16
			Structure.pillar(s.parent, s:world(CFrame.new(x, 0, z)).Position, 2.6, BOX.height, THEME.wall)
			local rarity = BrainrotData.Rarities[banner]
			if rarity and z > MACHINE_Z - 20 then
				banner += 1
				local face = CFrame.new(x - side * 1.45, 17, z) * CFrame.Angles(0, side * math.pi / 2, 0)
				s:deco("BannerRod", v3(3.6, 0.25, 0.25), face * CFrame.new(0, 6.2, 0), Palette.Frame, M.Metal)
				local cloth = s:deco("Banner", v3(3.2, 12, 0.12), face, rarity.color, M.Fabric)
				cloth.CastShadow = false
				s:deco(
					"BannerHem",
					v3(3.2, 0.5, 0.14),
					face * CFrame.new(0, -5.8, 0),
					rarity.color:Lerp(Palette.Ink, 0.4),
					M.Fabric
				)
				Build.surfaceText(cloth, Enum.NormalId.Front, rarity.name, {
					textColor = Palette.White,
					strokeColor = rarity.color:Lerp(Palette.Ink, 0.6),
					pixelsPerStud = 20,
				}).Rotation =
					0
			end
		end
	end
end

-- Floor design: a tiled runner from the spawn to the stage, rings around the stage and a colored
-- pad in front of every station.
local function floorDesign(s: Shapes.Shapes)
	local function strip(name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material?)
		s:deco(name, size, at, color, material or M.SmoothPlastic).CastShadow = false
	end
	for _, span in { { Hall.SPAWN.Z - 6, CHECK_Z + 2 }, { CHECK_Z - 2, MACHINE_Z + 15 } } do
		local a, b = span[1], span[2]
		local zc, length = (a + b) / 2, a - b
		strip("Runner", v3(RUNNER_WIDTH, 0.06, length), CFrame.new(0, 0.03, zc), THEME.paint, M.CeramicTiles)
		for _, side in { -1, 1 } do
			strip(
				"RunnerEdge",
				v3(0.5, 0.07, length),
				CFrame.new(side * (RUNNER_WIDTH / 2 + 0.25), 0.035, zc),
				Palette.Stripe
			)
		end
	end
	for i, ring in
		{
			{ size = 36, color = Palette.Frame },
			{ size = 33, color = THEME.paint },
			{ size = 30, color = Palette.Stripe },
			{ size = 29.2, color = THEME.floor },
		}
	do
		local disc = s:cyl(
			"StageRing",
			0.04 + i * 0.005,
			ring.size,
			CFrame.new(0, 0.02 + i * 0.005, MACHINE_Z),
			ring.color,
			if i == 4 then M.CeramicTiles else M.SmoothPlastic,
			false
		)
		disc.CastShadow = false
	end
end

local function frontDoors(s: Shapes.Shapes)
	local z = BOX.z2 + 0.4
	for _, side in { -1, 1 } do
		local door = s:box("FrontDoor", v3(6.6, 13.4, 0.6), CFrame.new(side * 3.35, 6.7, z), Palette.Orange, M.Metal)
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
		"SCANNING...\n3 SNEAKERS\n0 ESCAPE PLANS",
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
	s:deco("TitleFrame", v3(47, 11, 0.6), CFrame.new(0, signY, z), Palette.Frame, M.Metal)
	local board = s:deco("Title", v3(45, 9.2, 1), CFrame.new(0, signY, z), rgb(30, 40, 72), M.SmoothPlastic)
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
	for _, y in { -5.1, 5.1 } do
		s:deco("TitleTrim", v3(47, 0.5, 1.2), CFrame.new(0, signY + y, z), Palette.Stripe, M.SmoothPlastic)
	end
	for _, x in { -23.2, 23.2 } do
		s:deco("TitleEnd", v3(1.2, 10.2, 1.2), CFrame.new(x, signY, z), THEME.paint, M.SmoothPlastic)
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

	-- The founder's statue: a golden Tralalero Tralala on a plinth, off to the side so the view
	-- from the spawn runs straight through the checkpoint to the roll machine
	local plinth = CFrame.lookAt(v3(-15, 0, 50), v3(0, 0, Hall.SPAWN.Z))
	s:cyl("Plinth", 3, 8, plinth * CFrame.new(0, 1.5, 0), Palette.ConcreteWarm, M.Marble)
	s:cyl("PlinthTop", 0.5, 8.8, plinth * CFrame.new(0, 3.25, 0), Palette.Frame, M.Marble)
	s:cyl("PlinthFoot", 0.6, 9.4, plinth * CFrame.new(0, 0.3, 0), Palette.Frame, M.Marble)
	local plaque = s:deco("Plaque", v3(4.4, 1.6, 0.1), plinth * CFrame.new(0, 1.7, -4.03), Palette.Gold, M.Foil)
	Build.surfaceText(
		plaque,
		Enum.NormalId.Front,
		"OUR FOUNDER\nTralalero Tralala, 1987",
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
	-- Stage lights on the balcony rails, aimed at the machine
	for _, x in { -30, 30 } do
		for _, z in { MACHINE_Z - 10, MACHINE_Z + 10 } do
			local at = CFrame.lookAt(v3(x, BALCONY_Y + 3.6, z), v3(0, 8, MACHINE_Z))
			s:deco("StageLight", v3(1.4, 1.4, 2.2), at, Palette.Frame, M.Metal)
			local lens = s:glow("StageLightLens", v3(1.1, 1.1, 0.1), at * CFrame.new(0, 0, -1.12), THEME.machine.glow)
			s:spot(lens, THEME.machine.glow:Lerp(Palette.White, 0.5), 40, 1.4, 30, Enum.NormalId.Front)
		end
	end
	-- Colored pads in front of the stations
	for _, pad in
		{
			{ x = BOX.x1 + 9.5, z = -44, color = Palette.Orange },
			{ x = BOX.x2 - 9.5, z = -46, color = rgb(150, 90, 220) },
			{ x = -22, z = BOX.z1 + 9.5, color = Palette.Green },
			{ x = 22, z = BOX.z1 + 9.5, color = Palette.Blue },
		}
	do
		s:deco("StationPad", v3(9, 0.06, 7), CFrame.new(pad.x, 0.03, pad.z), pad.color:Lerp(THEME.floor, 0.35)).CastShadow =
			false
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
	-- Industrial pendants over the runner and the intake
	for _, x in { -8, 8 } do
		for z = 0, 70, 14 do
			if z < CHECK_Z - 4 or z > CHECK_Z + 4 then
				Props.pendant(folder, s:world(CFrame.new(x, BOX.height - 12, z)), 11, Palette.Frame, THEME.light)
			end
		end
	end
	for _, x in { -24, 24 } do
		for z = 44, 72, 14 do
			Props.pendant(folder, s:world(CFrame.new(x, 16, z)), BOX.height - 16, Palette.Frame, THEME.light)
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
	balconies(s)
	colonnade(s)
	floorDesign(s)
	frontDoors(s)
	checkpoint(s)
	intake(s)
	rollHall(s)
	fixtures(s)
end

return Hall
