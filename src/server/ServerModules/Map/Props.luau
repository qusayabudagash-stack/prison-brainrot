-- Reusable set dressing. Every prop is built in its own space (floor at y = 0, front facing -Z)
-- and placed with a CFrame, so the same bench or camera can go anywhere in the prison.

local Build = require(script.Parent.Parent.Build)
local Palette = require(script.Parent.Palette)
local Shapes = require(script.Parent.Shapes)

local Props = {}

local M = Enum.Material
local v3 = Vector3.new
local rgb = Color3.fromRGB

---------------------------------------------------------------------------
-- Lighting fixtures
---------------------------------------------------------------------------

-- Fluorescent ceiling fixture hanging at `cframe` (its underside), glowing downward.
function Props.ceilingLight(parent: Instance, cframe: CFrame, length: number, color: Color3?, hang: number?)
	local s = Shapes.model(parent, "CeilingLight", cframe)
	local glow = color or Palette.LightWarm
	local drop = hang or 0
	if drop > 0 then
		s:deco("Hanger", v3(0.1, drop, 0.1), CFrame.new(0, 0.4 + drop / 2, 0), Palette.Frame, M.Metal)
	end
	s:deco("Housing", v3(length, 0.4, 1.6), CFrame.new(0, 0.3, 0), Palette.SteelLight, M.Metal)
	local tube = s:glow("Tube", v3(length - 0.4, 0.14, 1.1), CFrame.new(0, 0.05, 0), glow)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Color = glow
	light.Range = 22
	light.Brightness = 1.4
	light.Angle = 110
	-- Dozens of these fill the prison; shadows stay on the few spotlights to keep Future lighting cheap
	light.Shadows = false
	light.Parent = tube
end

-- A pendant lamp: cable, enamel shade, bulb and a spotlight pointing down.
function Props.pendant(parent: Instance, cframe: CFrame, cable: number, shade: Color3?, glow: Color3?)
	local s = Shapes.model(parent, "Pendant", cframe)
	s:deco("Cable", v3(0.1, cable, 0.1), CFrame.new(0, cable / 2, 0), Palette.Ink)
	s:cyl("Shade", 0.8, 2.6, CFrame.new(0, 0.1, 0), shade or Palette.SteelDark, M.Metal, false)
	s:cyl("ShadeTop", 0.6, 1.2, CFrame.new(0, 0.7, 0), shade or Palette.SteelDark, M.Metal, false)
	local bulb = s:ball("Bulb", 0.9, v3(0, -0.25, 0), glow or Palette.LightWarm, M.Neon, false)
	bulb.CastShadow = false
	s:spot(bulb, glow or Palette.LightWarm, 30, 2, 70, Enum.NormalId.Bottom)
end

-- Rooftop air handler: a boxy unit with a fan grille, vents and a duct into the roof.
function Props.hvac(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "RoofHVAC", cframe)
	s:box("RoofUnit", v3(9, 4, 6), CFrame.new(0, 2, 0), Palette.SteelLight, M.Metal)
	s:deco("RoofUnitBase", v3(9.6, 0.5, 6.6), CFrame.new(0, 0.25, 0), Palette.SteelDark, M.Metal)
	for _, x in { -2.2, 2.2 } do
		s:cyl("RoofFan", 0.3, 3.4, CFrame.new(x, 4.15, 0), Palette.SteelDark, M.Metal, false)
		s:deco("RoofFanGrille", v3(3, 0.1, 0.3), CFrame.new(x, 4.35, 0), Palette.Steel, M.Metal)
	end
	for i = 0, 4 do
		s:deco("RoofVent", v3(0.1, 0.25, 5), CFrame.new(-4.55, 1 + i * 0.6, 0), Palette.SteelDark, M.Metal)
	end
	s:box("RoofDuct", v3(2, 2, 5), CFrame.new(0, 1, 5.3), Palette.SteelLight, M.Metal)
end

-- Rooftop exhaust pipe with a rain cap.
function Props.roofVent(parent: Instance, cframe: CFrame, height: number)
	local s = Shapes.model(parent, "RoofVent", cframe)
	s:cyl("RoofVentPipe", height, 1.2, CFrame.new(0, height / 2, 0), Palette.Steel, M.Metal)
	s:cyl("RoofVentCap", 0.4, 2.2, CFrame.new(0, height + 0.4, 0), Palette.SteelDark, M.Metal, false)
end

-- Wall-mounted cage lamp.
function Props.wallLamp(parent: Instance, cframe: CFrame, glow: Color3?)
	local s = Shapes.model(parent, "WallLamp", cframe)
	s:deco("Plate", v3(1.2, 1.6, 0.2), CFrame.new(0, 0, 0.1), Palette.SteelDark, M.Metal)
	local bulb = s:ball("Bulb", 0.9, v3(0, 0, -0.5), glow or Palette.LightWarm, M.Neon, false)
	bulb.CastShadow = false
	for _, x in { -0.45, 0.45 } do
		s:deco("Cage", v3(0.08, 1.2, 0.9), CFrame.new(x, 0, -0.5), Palette.Bars, M.Metal)
	end
	s:light(bulb, glow or Palette.LightWarm, 14, 0.9)
end

-- Tall outdoor floodlight with two heads.
function Props.floodlight(parent: Instance, cframe: CFrame, height: number)
	local s = Shapes.model(parent, "Floodlight", cframe)
	s:cyl("Pole", height, 0.8, CFrame.new(0, height / 2, 0), Palette.Steel, M.Metal)
	s:cyl("PoleFoot", 1, 1.8, CFrame.new(0, 0.5, 0), Palette.ConcreteDark, M.Concrete)
	s:deco("CrossBar", v3(5, 0.4, 0.4), CFrame.new(0, height - 0.5, 0), Palette.Steel, M.Metal)
	for _, x in { -2, 2 } do
		local aim = CFrame.new(x, height, -0.3) * CFrame.Angles(math.rad(-25), 0, 0)
		s:deco("LampHead", v3(1.8, 1.2, 1.2), aim, Palette.SteelDark, M.Metal)
		local lens = s:glow("Lens", v3(1.5, 0.9, 0.1), aim * CFrame.new(0, 0, -0.65), Palette.LightWarm)
		s:spot(lens, Palette.LightWarm, 60, 2.2, 60, Enum.NormalId.Front)
	end
end

---------------------------------------------------------------------------
-- Security
---------------------------------------------------------------------------

function Props.camera(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "SecurityCamera", cframe)
	s:deco("Mount", v3(0.8, 0.8, 0.3), CFrame.new(0, 0, 0.15), Palette.SteelDark, M.Metal)
	s:deco("Arm", v3(0.25, 0.25, 1.2), CFrame.new(0, 0, -0.5), Palette.SteelDark, M.Metal)
	local aim = CFrame.new(0, -0.3, -1.4) * CFrame.Angles(math.rad(-20), 0, 0)
	s:deco("CameraBody", v3(0.9, 0.9, 2.2), aim, Palette.White, M.SmoothPlastic)
	s:deco("Hood", v3(1.1, 0.12, 2.4), aim * CFrame.new(0, 0.5, 0), Palette.SteelLight, M.SmoothPlastic)
	s:cyl(
		"Lens",
		0.2,
		0.55,
		CFrame.new(0, -0.7, -2.45) * CFrame.Angles(math.rad(70), 0, 0),
		Palette.Ink,
		M.Glass,
		false
	)
	local led = s:ball("RecordLight", 0.18, v3(0.3, 0.05, -2.2), Palette.Red, M.Neon, false)
	led.CastShadow = false
	led:SetAttribute("Blink", true)
end

function Props.metalDetector(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "MetalDetector", cframe)
	for _, x in { -2.2, 2.2 } do
		s:box("Pillar", v3(0.9, 8, 1.6), CFrame.new(x, 4, 0), Palette.SteelLight, M.SmoothPlastic)
		s:deco("PillarStripe", v3(0.95, 5, 0.3), CFrame.new(x, 4.5, -0.7), Palette.SteelDark, M.SmoothPlastic)
	end
	s:box("Header", v3(5.3, 1.2, 1.6), CFrame.new(0, 8.6, 0), Palette.SteelLight, M.SmoothPlastic)
	local green = s:ball("StatusLight", 0.45, v3(-0.6, 8.6, -0.82), Palette.Green, M.Neon, false)
	green.CastShadow = false
	local red = s:ball("StatusLight", 0.45, v3(0.6, 8.6, -0.82), rgb(90, 30, 30), M.SmoothPlastic, false)
	red.CastShadow = false
	s:glow("ScanStripe", v3(3.5, 0.08, 0.08), CFrame.new(0, 7.95, -0.4), Palette.LightCool)
end

-- A guard's security desk with monitors, a chair and a coffee mug.
function Props.securityDesk(parent: Instance, cframe: CFrame, screens: { string }?)
	local s = Shapes.model(parent, "SecurityDesk", cframe)
	s:box("Counter", v3(10, 3.6, 3), CFrame.new(0, 1.8, 0), Palette.Guard, M.SmoothPlastic)
	s:box("CounterTop", v3(10.4, 0.3, 3.4), CFrame.new(0, 3.75, 0), Palette.SteelLight, M.Metal)
	s:deco("CounterStripe", v3(10.05, 0.4, 3.05), CFrame.new(0, 3.1, 0), Palette.White, M.SmoothPlastic)
	local badge = s:deco("CounterBadge", v3(3.6, 1.6, 0.1), CFrame.new(0, 1.8, -1.55), Palette.Gold, M.Foil)
	Build.surfaceText(
		badge,
		Enum.NormalId.Front,
		"SECURITY",
		{ textColor = Palette.Guard, strokeColor = Palette.Gold, pixelsPerStud = 30 }
	)
	local texts: { string } = screens or { "CAM 01\nINTAKE", "CAM 07\nCELLS", "CAM 12\nYARD" }
	for i, text in texts do
		local x = -3 + (i - 1) * 3
		local screen = CFrame.new(x, 5.1, 0.6) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.rad(-8), 0, 0)
		s:deco("Monitor", v3(2.6, 1.9, 0.4), screen, Palette.SteelDark, M.SmoothPlastic)
		local glass =
			s:deco("MonitorScreen", v3(2.3, 1.6, 0.05), screen * CFrame.new(0, 0, -0.22), rgb(40, 90, 70), M.Neon)
		glass.CastShadow = false
		Build.surfaceText(glass, Enum.NormalId.Front, text, { textColor = rgb(150, 255, 170), pixelsPerStud = 30 })
		s:deco("MonitorStand", v3(0.4, 0.8, 0.4), CFrame.new(x, 4.3, 0.7), Palette.SteelDark, M.Metal)
	end
	-- Chair behind the desk
	s:cyl("ChairBase", 0.3, 1.8, CFrame.new(0, 0.15, 2.6), Palette.SteelDark, M.Metal, false)
	s:cyl("ChairStem", 1.6, 0.3, CFrame.new(0, 1, 2.6), Palette.SteelDark, M.Metal, false)
	s:deco("ChairSeat", v3(2, 0.4, 2), CFrame.new(0, 1.9, 2.6), Palette.Ink, M.Fabric)
	s:deco("ChairBack", v3(2, 2.4, 0.4), CFrame.new(0, 3.3, 3.5), Palette.Ink, M.Fabric)
	-- Coffee mug and a donut, obviously
	s:cyl("Mug", 0.5, 0.45, CFrame.new(3.9, 4.15, -0.6), Palette.White, M.SmoothPlastic, false)
	s:cyl("Donut", 0.22, 0.7, CFrame.new(-4, 4.02, -0.7), rgb(240, 130, 180), M.SmoothPlastic, false)
end

---------------------------------------------------------------------------
-- Furniture
---------------------------------------------------------------------------

-- Bolted-down steel bench with wooden slats.
function Props.bench(parent: Instance, cframe: CFrame, length: number, back: boolean?)
	local s = Shapes.model(parent, "Bench", cframe)
	for i = 0, 2 do
		s:box("Slat", v3(length, 0.25, 0.55), CFrame.new(0, 1.9, -0.65 + i * 0.65), Palette.Wood, M.WoodPlanks)
	end
	for _, x in { -length / 2 + 0.6, length / 2 - 0.6 } do
		s:deco("Leg", v3(0.3, 1.8, 1.8), CFrame.new(x, 0.9, 0), Palette.SteelDark, M.Metal)
		if back ~= false then
			s:deco("BackPost", v3(0.3, 2.4, 0.3), CFrame.new(x, 3, 0.9), Palette.SteelDark, M.Metal)
		end
	end
	if back ~= false then
		for i = 0, 1 do
			s:deco("BackSlat", v3(length, 0.5, 0.2), CFrame.new(0, 2.8 + i * 0.8, 1), Palette.Wood, M.WoodPlanks)
		end
	end
end

-- Vending machine with a lit front, shelves of goods and a logo.
function Props.vending(parent: Instance, cframe: CFrame, body: Color3, logo: string)
	local s = Shapes.model(parent, "VendingMachine", cframe)
	s:box("Body", v3(4.4, 7.6, 3), CFrame.new(0, 3.8, 0), body, M.SmoothPlastic)
	s:deco("Window", v3(2.8, 5, 0.1), CFrame.new(-0.55, 4.4, -1.52), rgb(210, 235, 255), M.Glass).Transparency = 0.3
	local back = s:glow("WindowLight", v3(2.7, 4.9, 0.05), CFrame.new(-0.55, 4.4, -1.1), rgb(255, 250, 235))
	back.Transparency = 0.2
	local goods = { Palette.Red, Palette.Blue, Palette.Hazard, Palette.Green, Palette.Orange }
	for row = 0, 3 do
		s:deco("Shelf", v3(2.7, 0.08, 0.8), CFrame.new(-0.55, 2.3 + row * 1.2, -1.25), Palette.SteelLight, M.Metal)
		for col = 0, 1 do
			local color = goods[(row * 2 + col) % #goods + 1]
			s:deco(
				"Snack",
				v3(1.1, 0.75, 0.45),
				CFrame.new(-1.4 + col * 1.4, 2.72 + row * 1.2, -1.3),
				color,
				M.SmoothPlastic
			)
		end
	end
	s:deco("Keypad", v3(1.1, 1.8, 0.1), CFrame.new(1.45, 4.8, -1.52), Palette.SteelDark, M.Metal)
	s:deco("CoinSlot", v3(0.5, 0.18, 0.1), CFrame.new(1.45, 3.6, -1.53), Palette.Chrome, M.Metal)
	s:deco("Tray", v3(3, 0.8, 0.2), CFrame.new(-0.55, 1.2, -1.55), Palette.Ink, M.SmoothPlastic)
	local header = s:deco("Logo", v3(4.2, 1.1, 0.1), CFrame.new(0, 7.3, -1.52), body:Lerp(Palette.White, 0.25), M.Neon)
	header.CastShadow = false
	Build.surfaceText(
		header,
		Enum.NormalId.Front,
		logo,
		{ textColor = Palette.White, strokeColor = body:Lerp(Palette.Ink, 0.5), pixelsPerStud = 40 }
	)
	s:light(back, rgb(255, 245, 225), 9, 0.7)
end

function Props.trashCan(parent: Instance, cframe: CFrame, color: Color3?)
	local s = Shapes.model(parent, "TrashCan", cframe)
	s:cyl("Can", 3, 2, CFrame.new(0, 1.5, 0), color or Palette.Steel, M.Metal)
	s:cyl("Lid", 0.3, 2.2, CFrame.new(0, 3.1, 0), (color or Palette.Steel):Lerp(Palette.Ink, 0.3), M.Metal, false)
	for _, y in { 0.8, 2.2 } do
		s:cyl("Rib", 0.12, 2.06, CFrame.new(0, y, 0), (color or Palette.Steel):Lerp(Palette.Ink, 0.2), M.Metal, false)
	end
end

-- A potted fake plant (the only green thing the warden allows indoors).
function Props.plant(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Plant", cframe)
	local pot = rgb(200, 112, 72)
	s:cyl("Pot", 1.8, 2, CFrame.new(0, 0.9, 0), pot, M.SmoothPlastic)
	s:cyl("PotRim", 0.35, 2.3, CFrame.new(0, 1.75, 0), pot:Lerp(Palette.Ink, 0.15), M.SmoothPlastic)
	s:cyl("Soil", 0.1, 1.8, CFrame.new(0, 1.9, 0), Palette.Dirt, M.Ground, false)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		s:ball(
			"Leaves",
			1.5 - (i % 2) * 0.3,
			v3(math.cos(angle) * 0.5, 2.6 + (i % 3) * 0.5, math.sin(angle) * 0.5),
			if i % 2 == 0 then rgb(76, 160, 84) else rgb(98, 182, 96),
			M.SmoothPlastic,
			false
		)
	end
	s:ball("Leaves", 1.6, v3(0, 3.5, 0), rgb(110, 192, 104), M.SmoothPlastic, false)
end

-- A stylized tree: a slightly leaning trunk and a cluster of round canopies in two greens.
function Props.tree(parent: Instance, cframe: CFrame, size: number?)
	local k = size or 1
	local s = Shapes.model(parent, "Tree", cframe)
	s:cyl(
		"Trunk",
		7 * k,
		1.1 * k,
		CFrame.new(0, 3.5 * k, 0) * CFrame.Angles(0, 0, math.rad(4)),
		rgb(120, 84, 58),
		M.Wood
	)
	for i, blob in
		{
			{ 0, 8.2, 0, 5.6 },
			{ 1.9, 7.4, 1.0, 3.9 },
			{ -1.2, 9.6, -0.6, 3.8 },
		}
	do
		s:ball(
			"Canopy",
			blob[4] * k,
			v3(blob[1] * k, blob[2] * k, blob[3] * k),
			if i % 2 == 0 then rgb(88, 168, 86) else rgb(70, 146, 76),
			M.SmoothPlastic,
			false
		)
	end
end

-- A curbed planter bed with grass, low bushes and optional trees.
function Props.planter(parent: Instance, cframe: CFrame, width: number, depth: number, trees: number?)
	local s = Shapes.model(parent, "Planter", cframe)
	s:box("Curb", v3(width, 1, depth), CFrame.new(0, 0.5, 0), Palette.ConcreteDark, M.Concrete)
	s:deco("Bed", v3(width - 0.8, 0.1, depth - 0.8), CFrame.new(0, 1.02, 0), rgb(92, 150, 72), M.Grass)
	local count = math.max(1, math.floor(width / 5))
	for i = 1, count do
		local x = -width / 2 + (i - 0.5) * width / count
		s:ball(
			"Bush",
			1.8 + (i % 2) * 0.5,
			v3(x, 1.4, (i % 2 - 0.5) * (depth - 2.4) * 0.5),
			rgb(82, 160, 84),
			M.SmoothPlastic,
			false
		)
	end
	for i = 1, trees or 0 do
		local x = -width / 2 + (i - 0.5) * width / (trees or 1)
		Props.tree(s.parent, s:world(CFrame.new(x, 1, 0)), 0.9 + (i % 2) * 0.15)
	end
end

-- A round wall clock.
function Props.clock(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Clock", cframe)
	s:cyl("Rim", 0.3, 2.6, CFrame.Angles(math.pi / 2, 0, 0), Palette.SteelDark, M.Metal, false)
	s:cyl(
		"Face",
		0.32,
		2.3,
		CFrame.new(0, 0, -0.02) * CFrame.Angles(math.pi / 2, 0, 0),
		Palette.White,
		M.SmoothPlastic,
		false
	)
	s:deco(
		"HourHand",
		v3(0.12, 0.6, 0.05),
		CFrame.new(0.15, 0.2, -0.2) * CFrame.Angles(0, 0, math.rad(-40)),
		Palette.Ink
	)
	s:deco(
		"MinuteHand",
		v3(0.08, 0.9, 0.05),
		CFrame.new(-0.05, -0.4, -0.22) * CFrame.Angles(0, 0, math.rad(170)),
		Palette.Ink
	)
end

-- A wall notice board with pinned papers.
function Props.noticeBoard(parent: Instance, cframe: CFrame, notes: { string })
	local s = Shapes.model(parent, "NoticeBoard", cframe)
	s:deco("Frame", v3(8.4, 5.4, 0.3), CFrame.new(0, 0, 0.1), Palette.WoodDark, M.Wood)
	s:deco("Cork", v3(8, 5, 0.1), CFrame.new(0, 0, -0.05), rgb(196, 160, 110), M.Fabric)
	local paper = { Palette.White, rgb(255, 245, 170), rgb(200, 230, 255), rgb(255, 210, 220) }
	for i, note in notes do
		local x = -2.8 + ((i - 1) % 3) * 2.8
		local y = 1.1 - ((i - 1) // 3) * 2.4
		local sheet = s:deco(
			"Note",
			v3(2.3, 2, 0.05),
			CFrame.new(x, y, -0.13) * CFrame.Angles(0, 0, math.rad((i % 3 - 1) * 4)),
			paper[i % #paper + 1]
		)
		Build.surfaceText(
			sheet,
			Enum.NormalId.Front,
			note,
			{ textColor = Palette.Ink, strokeColor = paper[i % #paper + 1], pixelsPerStud = 50 }
		)
		s:ball("Pin", 0.2, v3(x, y + 0.85, -0.2), Palette.Red, M.SmoothPlastic, false)
	end
end

---------------------------------------------------------------------------
-- Signs
---------------------------------------------------------------------------

export type SignOptions = {
	text: Color3?,
	stroke: Color3?,
	glow: boolean?,
	bolts: boolean?,
	pixelsPerStud: number?,
}

-- A flat sign plate mounted on a wall at `cframe` (text faces -Z).
function Props.sign(
	parent: Instance,
	cframe: CFrame,
	size: Vector2,
	text: string,
	background: Color3,
	options: SignOptions?
): Part
	local opts: SignOptions = options or {}
	local s = Shapes.model(parent, "Sign", cframe)
	local plate = s:deco(
		"Plate",
		v3(size.X, size.Y, 0.25),
		CFrame.new(),
		background,
		if opts.glow then M.Neon else M.SmoothPlastic
	)
	plate.CastShadow = false
	Build.surfaceText(plate, Enum.NormalId.Front, text, {
		textColor = opts.text or Palette.White,
		strokeColor = opts.stroke or Palette.Ink,
		pixelsPerStud = opts.pixelsPerStud or 30,
	})
	if opts.bolts ~= false then
		for _, x in { -size.X / 2 + 0.35, size.X / 2 - 0.35 } do
			for _, y in { -size.Y / 2 + 0.35, size.Y / 2 - 0.35 } do
				s:ball("Bolt", 0.18, v3(x, y, -0.14), Palette.Chrome, M.Metal, false)
			end
		end
	end
	return plate
end

-- Yellow-and-black warning sign.
function Props.warning(parent: Instance, cframe: CFrame, text: string, width: number?)
	local w = width or 5
	local s = Shapes.model(parent, "WarningSign", cframe)
	s:deco("Border", v3(w + 0.4, 2.8, 0.2), CFrame.new(0, 0, 0.05), Palette.HazardDark)
	local plate = s:deco("Plate", v3(w, 2.4, 0.25), CFrame.new(), Palette.Hazard)
	plate.CastShadow = false
	Build.surfaceText(
		plate,
		Enum.NormalId.Front,
		`⚠ {text}`,
		{ textColor = Palette.HazardDark, strokeColor = Palette.Hazard, pixelsPerStud = 30 }
	)
end

-- A hanging direction sign with an arrow, e.g. "CELLS →".
function Props.directions(parent: Instance, cframe: CFrame, lines: { string }, hang: number?)
	local s = Shapes.model(parent, "DirectionSign", cframe)
	local height = #lines * 1.5 + 0.4
	local drop = hang or 0
	if drop > 0 then
		for _, x in { -2.5, 2.5 } do
			s:deco("Chain", v3(0.12, drop, 0.12), CFrame.new(x, height / 2 + drop / 2, 0), Palette.SteelDark, M.Metal)
		end
	end
	s:deco("Backing", v3(8.4, height + 0.3, 0.3), CFrame.new(0, 0, 0.05), Palette.SteelDark, M.Metal)
	for i, line in lines do
		local y = height / 2 - 0.2 - (i - 0.5) * 1.5
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local panel = s:deco("Panel", v3(8, 1.3, 0.35), CFrame.new(0, y, 0), rgb(24, 92, 70))
			panel.CastShadow = false
			Build.surfaceText(
				panel,
				face,
				line,
				{ textColor = Palette.White, strokeColor = rgb(24, 92, 70), pixelsPerStud = 40 }
			)
		end
	end
end

-- A poster on the wall.
function Props.poster(
	parent: Instance,
	cframe: CFrame,
	size: Vector2,
	text: string,
	background: Color3,
	textColor: Color3?
)
	local s = Shapes.model(parent, "Poster", cframe)
	local paper = s:deco("Paper", v3(size.X, size.Y, 0.05), CFrame.new(), background)
	paper.CastShadow = false
	Build.surfaceText(
		paper,
		Enum.NormalId.Front,
		text,
		{ textColor = textColor or Palette.White, strokeColor = background:Lerp(Palette.Ink, 0.6), pixelsPerStud = 30 }
	)
	for _, x in { -size.X / 2 + 0.3, size.X / 2 - 0.3 } do
		s:deco(
			"Tape",
			v3(0.7, 0.25, 0.06),
			CFrame.new(x, size.Y / 2 - 0.1, -0.03) * CFrame.Angles(0, 0, math.rad(if x > 0 then -30 else 30)),
			rgb(240, 235, 210)
		)
	end
end

---------------------------------------------------------------------------
-- Pipes and barriers
---------------------------------------------------------------------------

-- A pipe along a list of points, with elbows at the corners and brackets along the way.
function Props.pipe(parent: Instance, points: { Vector3 }, diameter: number, color: Color3?)
	local s = Shapes.model(parent, "Pipe")
	local c = color or Palette.Steel
	for i = 1, #points - 1 do
		s:rod("PipeRun", points[i], points[i + 1], diameter, c, M.Metal, false)
		if i > 1 then
			s:ball("PipeElbow", diameter * 1.25, points[i], c, M.Metal, false)
		end
		local length = (points[i + 1] - points[i]).Magnitude
		local steps = math.floor(length / 10)
		for step = 1, steps do
			local at = points[i]:Lerp(points[i + 1], step / (steps + 1))
			s:rod(
				"PipeClamp",
				at - (points[i + 1] - points[i]).Unit * 0.2,
				at + (points[i + 1] - points[i]).Unit * 0.2,
				diameter * 1.3,
				Palette.SteelDark,
				M.Metal,
				false
			)
		end
	end
end

-- Stanchions with a rope between them (queue barriers).
function Props.ropeLine(parent: Instance, points: { Vector3 }, rope: Color3?)
	local s = Shapes.model(parent, "RopeLine")
	for i, point in points do
		s:cyl("Post", 3, 0.3, CFrame.new(point + v3(0, 1.5, 0)), Palette.Chrome, M.Metal)
		s:cyl("PostBase", 0.3, 1.2, CFrame.new(point + v3(0, 0.15, 0)), Palette.Chrome, M.Metal, false)
		s:ball("PostTop", 0.5, point + v3(0, 3.1, 0), Palette.Chrome, M.Metal, false)
		local nextPoint = points[i + 1]
		if nextPoint then
			local a, b = point + v3(0, 2.8, 0), nextPoint + v3(0, 2.8, 0)
			local mid = (a + b) / 2 - v3(0, 0.5, 0)
			s:rod("Rope", a, mid, 0.22, rope or Palette.Red, M.Fabric, false)
			s:rod("Rope", mid, b, 0.22, rope or Palette.Red, M.Fabric, false)
		end
	end
end

-- Vertical bars with cross rails, spanning `width` centered on the CFrame (floor at y = 0).
function Props.bars(parent: Instance, cframe: CFrame, width: number, height: number, spacing: number?, name: string?)
	local s = Shapes.model(parent, name or "Bars", cframe)
	local gap = spacing or 1.1
	local count = math.floor(width / gap)
	for i = 0, count do
		local x = -width / 2 + i * width / count
		s:cyl("Bar", height, 0.28, CFrame.new(x, height / 2, 0), Palette.Bars, M.Metal)
	end
	for _, y in { 0.4, height * 0.45, height - 0.3 } do
		s:deco("Rail", v3(width + 0.3, 0.35, 0.45), CFrame.new(0, y, 0), Palette.Bars, M.Metal)
	end
	return s
end

-- Chain-link fence from a to b (floor points) with posts, rails and barbed wire on top.
function Props.fence(parent: Instance, a: Vector3, b: Vector3, height: number)
	local s = Shapes.model(parent, "Fence")
	local length = (b - a).Magnitude
	local posts = math.max(1, math.floor(length / 10))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		s:cyl("FencePost", height + 1, 0.45, CFrame.new(p + v3(0, (height + 1) / 2, 0)), Palette.Steel, M.Metal)
	end
	s:rod("FenceRail", a + v3(0, height, 0), b + v3(0, height, 0), 0.3, Palette.Steel, M.Metal)
	local mid = (a + b) / 2
	local angle = math.atan2(-(b - a).Z, (b - a).X)
	local mesh = s:box(
		"FenceMesh",
		v3(length, height - 0.4, 0.15),
		CFrame.new(mid + v3(0, height / 2 + 0.2, 0)) * CFrame.Angles(0, angle, 0),
		Palette.SteelLight,
		M.DiamondPlate
	)
	mesh.Transparency = 0.55
	mesh.CastShadow = false
	for _, offset in { 0.9, 1.6 } do
		s:rod(
			"BarbedWire",
			a + v3(0, height + offset, 0),
			b + v3(0, height + offset, 0),
			0.4,
			Palette.SteelLight,
			M.Metal,
			false
		)
	end
end

---------------------------------------------------------------------------
-- Outdoors
---------------------------------------------------------------------------

-- A guard tower: four legs, a cabin with windows, a roof and a sweeping searchlight.
function Props.watchTower(parent: Instance, cframe: CFrame, height: number)
	local s = Shapes.model(parent, "WatchTower", cframe)
	local deck = height
	for _, x in { -3.5, 3.5 } do
		for _, z in { -3.5, 3.5 } do
			s:box("Leg", v3(0.9, deck, 0.9), CFrame.new(x, deck / 2, z), Palette.Steel, M.Metal)
		end
	end
	for i = 1, 3 do
		local y = deck * i / 4
		for _, z in { -3.5, 3.5 } do
			s:deco("Brace", v3(7, 0.4, 0.4), CFrame.new(0, y, z), Palette.SteelDark, M.Metal)
		end
	end
	s:box("Deck", v3(10, 0.8, 10), CFrame.new(0, deck + 0.4, 0), Palette.SteelDark, M.DiamondPlate)
	for _, x in { -4.7, 4.7 } do
		s:box("CabinWall", v3(0.6, 3, 10), CFrame.new(x, deck + 2.3, 0), Palette.ConcreteWarm, M.Concrete)
	end
	for _, z in { -4.7, 4.7 } do
		s:box("CabinWall", v3(10, 3, 0.6), CFrame.new(0, deck + 2.3, z), Palette.ConcreteWarm, M.Concrete)
	end
	for _, x in { -4.6, 4.6 } do
		for _, z in { -4.6, 4.6 } do
			s:deco("CabinPost", v3(0.5, 4, 0.5), CFrame.new(x, deck + 5.8, z), Palette.SteelDark, M.Metal)
		end
	end
	local glass = s:deco("CabinGlass", v3(9.4, 3.6, 9.4), CFrame.new(0, deck + 5.6, 0), Palette.Glass, M.Glass)
	glass.Transparency = 0.7
	s:box("Roof", v3(12, 0.8, 12), CFrame.new(0, deck + 8, 0), Palette.Guard, M.Metal)
	s:wedge("RoofPeak", v3(12, 1.6, 6), CFrame.new(0, deck + 9.2, -3), Palette.Guard, M.Metal)
	s:wedge(
		"RoofPeak",
		v3(12, 1.6, 6),
		CFrame.new(0, deck + 9.2, 3) * CFrame.Angles(0, math.pi, 0),
		Palette.Guard,
		M.Metal
	)
	-- Searchlight on the rail
	local head = s:deco(
		"Searchlight",
		v3(1.8, 1.8, 2.4),
		CFrame.new(3.2, deck + 4.5, -5.3) * CFrame.Angles(math.rad(-35), 0, 0),
		Palette.SteelDark,
		M.Metal
	)
	local lens = s:glow(
		"SearchlightLens",
		v3(1.5, 1.5, 0.1),
		CFrame.new(3.2, deck + 3.8, -6.3) * CFrame.Angles(math.rad(-35), 0, 0),
		Palette.LightWarm
	)
	s:spot(lens, Palette.LightWarm, 60, 3, 25, Enum.NormalId.Front)
	head:SetAttribute("Sweep", true)
	-- Ladder
	for _, x in { -0.8, 0.8 } do
		s:deco("LadderRail", v3(0.2, deck, 0.2), CFrame.new(x, deck / 2, 4.3), Palette.SteelDark, M.Metal)
	end
	for i = 1, math.floor(deck / 1.2) do
		s:deco("LadderRung", v3(1.6, 0.15, 0.15), CFrame.new(0, i * 1.2, 4.3), Palette.SteelDark, M.Metal)
	end
end

-- Basketball hoop on a padded pole.
function Props.hoop(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Hoop", cframe)
	s:cyl("Pole", 11, 0.8, CFrame.new(0, 5.5, 2.5), Palette.Steel, M.Metal)
	s:deco("Pad", v3(1.4, 4, 1.4), CFrame.new(0, 2, 2.5), Palette.Guard, M.Fabric)
	s:deco("Arm", v3(0.5, 0.5, 2.6), CFrame.new(0, 10.6, 1.3), Palette.Steel, M.Metal)
	s:box("Backboard", v3(6, 3.6, 0.3), CFrame.new(0, 11.5, 0), Palette.White, M.SmoothPlastic)
	s:deco("BoardBorder", v3(6.1, 3.7, 0.2), CFrame.new(0, 11.5, 0.1), Palette.Red)
	s:deco("TargetBox", v3(2, 1.4, 0.05), CFrame.new(0, 11, -0.18), Palette.Red)
	s:deco("TargetInner", v3(1.7, 1.1, 0.06), CFrame.new(0, 11, -0.19), Palette.White)
	for i = 0, 9 do
		local a0, a1 = i * math.pi * 2 / 10, (i + 1) * math.pi * 2 / 10
		local center = v3(0, 10, -1.3)
		s:rod(
			"Rim",
			center + v3(math.cos(a0) * 0.9, 0, math.sin(a0) * 0.9),
			center + v3(math.cos(a1) * 0.9, 0, math.sin(a1) * 0.9),
			0.12,
			Palette.Orange,
			M.Metal,
			false
		)
	end
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		local top = v3(math.cos(angle) * 0.85, 10, -1.3 + math.sin(angle) * 0.85)
		local bottom = v3(math.cos(angle) * 0.5, 8.7, -1.3 + math.sin(angle) * 0.5)
		s:rod("Net", top, bottom, 0.05, Palette.White, M.Fabric, false)
	end
end

-- A flat bench press with a loaded barbell.
function Props.benchPress(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "BenchPress", cframe)
	s:box("Pad", v3(1.6, 0.5, 5), CFrame.new(0, 1.8, 0), Palette.Ink, M.Fabric)
	for _, z in { -2, 2 } do
		s:deco("Leg", v3(1.4, 1.6, 0.3), CFrame.new(0, 0.8, z), Palette.SteelDark, M.Metal)
	end
	for _, x in { -2, 2 } do
		s:deco("Upright", v3(0.3, 4, 0.3), CFrame.new(x, 2, -2), Palette.SteelDark, M.Metal)
	end
	s:rod("Barbell", v3(-3.6, 3.8, -2), v3(3.6, 3.8, -2), 0.18, Palette.Chrome, M.Metal, false)
	for _, x in { -3, 3 } do
		s:cyl(
			"Plate",
			0.35,
			2.2,
			CFrame.new(x, 3.8, -2) * CFrame.Angles(0, 0, math.pi / 2),
			Palette.Ink,
			M.Metal,
			false
		)
	end
end

function Props.pullUpBar(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "PullUpBar", cframe)
	for _, x in { -3, 3 } do
		s:box("Post", v3(0.5, 9, 0.5), CFrame.new(x, 4.5, 0), Palette.Steel, M.Metal)
	end
	s:rod("Bar", v3(-3, 8.6, 0), v3(3, 8.6, 0), 0.25, Palette.Chrome, M.Metal, false)
	s:rod("LowBar", v3(-3, 5, 0), v3(3, 5, 0), 0.25, Palette.Chrome, M.Metal, false)
end

function Props.weightRack(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "WeightRack", cframe)
	s:box("Frame", v3(6, 0.3, 1.4), CFrame.new(0, 1.2, 0), Palette.SteelDark, M.Metal)
	s:box("Frame", v3(6, 0.3, 1.4), CFrame.new(0, 2.6, 0.3), Palette.SteelDark, M.Metal)
	for _, x in { -2.8, 2.8 } do
		s:deco("Side", v3(0.3, 3, 1.6), CFrame.new(x, 1.5, 0.15), Palette.SteelDark, M.Metal)
	end
	for i = 0, 4 do
		local x = -2.2 + i * 1.1
		for _, row in { { 1.6, 0 }, { 3, 0.3 } } do
			s:rod(
				"Dumbbell",
				v3(x, row[1], row[2] - 0.5),
				v3(x, row[1], row[2] + 0.5),
				0.15,
				Palette.Chrome,
				M.Metal,
				false
			)
			for _, z in { -0.5, 0.5 } do
				s:ball("DumbbellHead", 0.5 - i * 0.03, v3(x, row[1], row[2] + z), Palette.Ink, M.Metal, false)
			end
		end
	end
end

-- Picnic table with attached benches.
function Props.picnicTable(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "PicnicTable", cframe)
	s:box("Top", v3(8, 0.4, 3), CFrame.new(0, 3, 0), Palette.Wood, M.WoodPlanks)
	for _, z in { -2.6, 2.6 } do
		s:box("Seat", v3(8, 0.35, 1.2), CFrame.new(0, 1.8, z), Palette.Wood, M.WoodPlanks)
	end
	for _, x in { -3, 3 } do
		s:deco("Frame", v3(0.4, 0.4, 6.4), CFrame.new(x, 1.5, 0), Palette.SteelDark, M.Metal)
		s:deco("Leg", v3(0.4, 3, 0.4), CFrame.new(x, 1.5, 0), Palette.SteelDark, M.Metal)
	end
end

function Props.cone(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Cone", cframe)
	s:deco("ConeBase", v3(1.6, 0.2, 1.6), CFrame.new(0, 0.1, 0), Palette.Orange)
	s:cyl("ConeLow", 0.8, 1.1, CFrame.new(0, 0.6, 0), Palette.Orange, M.SmoothPlastic, false)
	s:cyl("ConeStripe", 0.4, 0.85, CFrame.new(0, 1.2, 0), Palette.White, M.SmoothPlastic, false)
	s:cyl("ConeTip", 0.7, 0.6, CFrame.new(0, 1.75, 0), Palette.Orange, M.SmoothPlastic, false)
end

---------------------------------------------------------------------------
-- Kitchen and cafeteria
---------------------------------------------------------------------------

-- A food tray with compartments of questionable food.
function Props.tray(parent: Instance, cframe: CFrame, seed: number)
	local s = Shapes.model(parent, "Tray", cframe)
	s:deco("Tray", v3(2.2, 0.12, 1.5), CFrame.new(0, 0.06, 0), rgb(120, 150, 140), M.SmoothPlastic)
	local foods = { rgb(230, 220, 170), rgb(120, 170, 70), rgb(170, 110, 70), rgb(240, 200, 90), rgb(200, 90, 80) }
	for i, spot in { v3(-0.55, 0, -0.3), v3(0.55, 0, -0.3), v3(0, 0, 0.35) } do
		local color = foods[(seed + i) % #foods + 1]
		s:deco("Food", v3(0.8, 0.28, 0.55), CFrame.new(spot + v3(0, 0.2, 0)), color, M.SmoothPlastic)
	end
	s:deco("Spork", v3(0.1, 0.05, 0.9), CFrame.new(0.95, 0.15, 0.2), Palette.White)
end

-- Bolted cafeteria table with round stools.
function Props.messTable(parent: Instance, cframe: CFrame, seed: number)
	local s = Shapes.model(parent, "MessTable", cframe)
	s:box("TableTop", v3(12, 0.4, 4), CFrame.new(0, 3, 0), Palette.SteelLight, M.Metal)
	s:deco("TableEdge", v3(12.1, 0.2, 4.1), CFrame.new(0, 2.75, 0), Palette.SteelDark, M.Metal)
	for _, x in { -4.5, 4.5 } do
		s:deco("Pedestal", v3(0.8, 2.8, 0.8), CFrame.new(x, 1.4, 0), Palette.SteelDark, M.Metal)
		s:deco("Foot", v3(0.8, 0.3, 7.4), CFrame.new(x, 0.15, 0), Palette.SteelDark, M.Metal)
	end
	for i = 0, 3 do
		local x = -4.5 + i * 3
		for _, z in { -3.3, 3.3 } do
			s:cyl("Stool", 0.4, 1.7, CFrame.new(x, 1.9, z), Palette.Orange, M.SmoothPlastic)
			s:deco("StoolArm", v3(0.3, 0.3, 3.3), CFrame.new(x, 1.5, z / 2), Palette.SteelDark, M.Metal)
		end
	end
	for i = 0, 2 do
		if (seed + i) % 3 ~= 0 then
			local side = if i % 2 == 0 then -1 else 1
			Props.tray(
				parent,
				s:world(CFrame.new(-4 + i * 4, 3.2, side * 1) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0)),
				seed + i
			)
		end
	end
end

-- A long steel counter with cabinets underneath.
function Props.counter(parent: Instance, cframe: CFrame, length: number, top: Color3?)
	local s = Shapes.model(parent, "Counter", cframe)
	s:box("Cabinet", v3(length, 3.4, 3), CFrame.new(0, 1.7, 0), Palette.SteelLight, M.Metal)
	s:box("Top", v3(length + 0.3, 0.3, 3.3), CFrame.new(0, 3.55, 0), top or Palette.Chrome, M.Metal)
	local doors = math.floor(length / 3)
	for i = 0, doors - 1 do
		local x = -length / 2 + (i + 0.5) * length / doors
		s:deco("Door", v3(length / doors - 0.3, 2.8, 0.1), CFrame.new(x, 1.7, -1.52), Palette.Steel, M.Metal)
		s:deco("Handle", v3(0.8, 0.15, 0.15), CFrame.new(x, 2.7, -1.62), Palette.Chrome, M.Metal)
	end
end

function Props.stove(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Stove", cframe)
	s:box("Body", v3(5, 3.4, 3.4), CFrame.new(0, 1.7, 0), Palette.Steel, M.Metal)
	s:deco("OvenDoor", v3(4, 2, 0.1), CFrame.new(0, 1.5, -1.72), Palette.SteelDark, M.Metal)
	s:deco("OvenWindow", v3(2.6, 0.9, 0.05), CFrame.new(0, 1.6, -1.78), rgb(255, 140, 60), M.Neon).CastShadow = false
	for _, x in { -1.2, 1.2 } do
		for _, z in { -0.8, 0.8 } do
			s:cyl("Burner", 0.1, 1.2, CFrame.new(x, 3.45, z), Palette.Ink, M.Metal, false)
		end
	end
	s:cyl("Pot", 1.4, 1.8, CFrame.new(-1.2, 4.2, -0.8), Palette.Chrome, M.Metal, false)
	local stew = s:cyl("Stew", 0.1, 1.6, CFrame.new(-1.2, 4.85, -0.8), rgb(160, 200, 90), M.SmoothPlastic, false)
	stew.CastShadow = false
	local steam = Instance.new("Smoke")
	steam.Color = Color3.fromRGB(240, 240, 240)
	steam.Opacity = 0.08
	steam.RiseVelocity = 3
	steam.Size = 0.8
	steam.Parent = stew
	s:cyl("Pan", 0.3, 1.8, CFrame.new(1.2, 3.65, 0.8), Palette.Ink, M.Metal, false)
end

function Props.fridge(parent: Instance, cframe: CFrame)
	local s = Shapes.model(parent, "Fridge", cframe)
	s:box("Body", v3(4, 8, 3), CFrame.new(0, 4, 0), Palette.Chrome, M.Metal)
	s:deco("Seam", v3(0.1, 7.6, 0.1), CFrame.new(0, 4, -1.52), Palette.SteelDark, M.Metal)
	for _, x in { -0.4, 0.4 } do
		s:deco("Handle", v3(0.2, 2.4, 0.3), CFrame.new(x, 4.6, -1.65), Palette.SteelDark, M.Metal)
	end
	local note = s:deco("Note", v3(1.2, 1.2, 0.05), CFrame.new(-1.2, 5.6, -1.53), rgb(255, 245, 170))
	Build.surfaceText(
		note,
		Enum.NormalId.Front,
		"DO NOT\nEAT MY\nPUDDING\n-Warden",
		{ textColor = Palette.Ink, strokeColor = rgb(255, 245, 170), pixelsPerStud = 60 }
	)
end

---------------------------------------------------------------------------
-- Cell furniture
---------------------------------------------------------------------------

-- A steel bunk bed, two mattresses, pillows and blankets.
function Props.bunk(parent: Instance, cframe: CFrame, blanket: Color3?, name: string?)
	local s = Shapes.model(parent, name or "Bunk", cframe)
	for _, x in { -1.7, 1.7 } do
		for _, z in { -3.6, 3.6 } do
			s:box("Post", v3(0.3, 7.6, 0.3), CFrame.new(x, 3.8, z), Palette.Steel, M.Metal)
		end
	end
	for _, y in { 1.6, 5.2 } do
		s:box("Frame", v3(3.8, 0.35, 7.6), CFrame.new(0, y, 0), Palette.Steel, M.Metal)
		s:deco("Mattress", v3(3.4, 0.5, 7.2), CFrame.new(0, y + 0.42, 0), rgb(226, 222, 206), M.Fabric)
		s:deco("Blanket", v3(3.5, 0.3, 4.4), CFrame.new(0, y + 0.62, 1.3), blanket or Palette.Fabric, M.Fabric)
		s:deco("Pillow", v3(2.4, 0.5, 1.2), CFrame.new(0, y + 0.85, -2.8), Palette.White, M.Fabric)
	end
	s:deco("Ladder", v3(0.2, 3.8, 0.2), CFrame.new(1.9, 3.4, 2), Palette.Steel, M.Metal)
end

-- A stainless steel toilet-sink combo, the classic prison fixture.
function Props.toiletSink(parent: Instance, cframe: CFrame, name: string?)
	local s = Shapes.model(parent, name or "Toilet", cframe)
	s:box("Unit", v3(3, 4.4, 1.8), CFrame.new(0, 2.2, 0.6), Palette.Chrome, M.Metal)
	s:deco("Basin", v3(2.2, 0.3, 1.2), CFrame.new(0, 4.3, 0.2), Palette.SteelLight, M.Metal)
	s:deco("Tap", v3(0.2, 0.5, 0.4), CFrame.new(0, 4.6, 0.8), Palette.Steel, M.Metal)
	s:cyl("Bowl", 1.6, 2, CFrame.new(0, 0.8, -0.8), Palette.Chrome, M.Metal)
	s:cyl("Rim", 0.2, 2.1, CFrame.new(0, 1.65, -0.8), Palette.SteelLight, M.Metal, false)
	s:cyl("Water", 0.1, 1.5, CFrame.new(0, 1.7, -0.8), rgb(150, 200, 220), M.Glass, false)
	s:deco("TPHolder", v3(0.15, 0.15, 0.8), CFrame.new(1.8, 2.4, 0.6), Palette.Steel, M.Metal)
	s:cyl("TP", 0.7, 0.5, CFrame.new(1.8, 2.4, 0.6) * CFrame.Angles(math.pi / 2, 0, 0), Palette.White, M.Fabric, false)
end

-- A narrow locker with vents and a padlock.
function Props.locker(parent: Instance, cframe: CFrame, color: Color3?, name: string?)
	local s = Shapes.model(parent, name or "Locker", cframe)
	local c = color or rgb(80, 110, 150)
	s:box("Body", v3(2.4, 7, 2), CFrame.new(0, 3.5, 0), c, M.Metal)
	s:deco("Door", v3(2.1, 6.6, 0.1), CFrame.new(0, 3.5, -1.02), c:Lerp(Palette.White, 0.08), M.Metal)
	for i = 0, 3 do
		s:deco("Vent", v3(1.2, 0.12, 0.05), CFrame.new(0, 6.2 - i * 0.3, -1.08), c:Lerp(Palette.Ink, 0.5), M.Metal)
	end
	s:deco("Latch", v3(0.2, 0.9, 0.15), CFrame.new(0.75, 3.6, -1.1), Palette.Chrome, M.Metal)
	s:deco("Padlock", v3(0.4, 0.45, 0.2), CFrame.new(0.75, 3.1, -1.18), Palette.Gold, M.Metal)
end

-- A small wall shelf with a few belongings.
function Props.shelf(parent: Instance, cframe: CFrame, name: string?)
	local s = Shapes.model(parent, name or "Shelf", cframe)
	s:deco("Board", v3(4, 0.25, 1.2), CFrame.new(0, 0, -0.6), Palette.Steel, M.Metal)
	s:deco("Book", v3(0.35, 1.2, 0.9), CFrame.new(-1.4, 0.72, -0.6), Palette.Red)
	s:deco("Book", v3(0.3, 1.0, 0.9), CFrame.new(-1.05, 0.62, -0.6), Palette.Blue)
	s:deco("Book", v3(0.4, 1.1, 0.9), CFrame.new(-0.7, 0.67, -0.6) * CFrame.Angles(0, 0, math.rad(-12)), Palette.Hazard)
	s:cyl("Cup", 0.6, 0.5, CFrame.new(0.6, 0.42, -0.6), Palette.Orange, M.SmoothPlastic, false)
	s:deco("Photo", v3(0.9, 0.7, 0.1), CFrame.new(1.4, 0.5, -0.4) * CFrame.Angles(math.rad(-10), 0, 0), Palette.White)
end

return Props
