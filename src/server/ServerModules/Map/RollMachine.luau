-- The Brainrot Roller: each block's roll machine and the hero piece of every room. A big gacha
-- machine on a stepped stage ringed with the rarity colors: a rounded drum housing with a curved
-- price screen, a glass dome where the block's featured Brainrot turns among a pile of prize
-- capsules, a side crank, glowing feed pipes and tanks, a console with a coin slot and the big ROLL
-- button, and an arch marquee with the block's name.
--
-- Named parts the client animates (Controllers/Machines): Bulb (Index attribute, chase lights),
-- PipeCore and TankLiquid (pulse), Beacon (flash on a roll), Lever (the crank, Pivot attribute).
-- Gameplay hooks: the model's AreaId attribute, the Roll prompt on RollButton, and ScreenText.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Build = require(script.Parent.Parent.Build)
local Format = require(ReplicatedStorage.Modules.Format)
local Palette = require(script.Parent.Palette)
local Shapes = require(script.Parent.Shapes)

local RollMachine = {}

local M = Enum.Material
local v3 = Vector3.new
local rgb = Color3.fromRGB

export type Style = {
	body: Color3,
	trim: Color3,
	glow: Color3,
	featured: string?,
}

local SIZE = 1.25 -- the machine is modelled at 1x and scaled up by this when placed
local STAGE_Y = 1.3 -- top of the stage
local DRUM_D, DRUM_H = 12, 5.6
local DOME_D = 10.4
local DOME_Y = STAGE_Y + DRUM_H + 3.6 -- center of the glass dome

-- Stepped round stage with a ring of rarity lights around its edge
local function stage(s: Shapes.Shapes, style: Style)
	s:cyl("Stage", 0.65, 25, CFrame.new(0, 0.325, 0), Palette.Frame, M.Concrete)
	s:cyl("StageTrim", 0.22, 25.25, CFrame.new(0, 0.45, 0), Palette.Stripe, M.SmoothPlastic, false)
	s:cyl("StageTop", 0.65, 20, CFrame.new(0, 0.975, 0), Palette.FrameLight, M.DiamondPlate)
	s:cyl(
		"StageInlay",
		0.04,
		17,
		CFrame.new(0, STAGE_Y + 0.02, 0),
		style.body:Lerp(Palette.Frame, 0.55),
		M.SmoothPlastic,
		false
	)
	-- Rarity lights: one arc per rarity around the lower step, in order
	local rarities = BrainrotData.Rarities
	local count = #rarities
	for i = 0, count - 1 do
		local rarity = rarities[i + 1]
		local angle = (i + 0.5) * math.pi * 2 / count
		local lamp = s:deco(
			"RarityLight",
			v3(7.6, 0.28, 0.3),
			CFrame.Angles(0, -angle, 0) * CFrame.new(0, 0.42, -12.55),
			rarity.color,
			M.Neon
		)
		lamp.CastShadow = false
	end
end

-- The drum housing with chrome bands, a curved screen and side vents
local function drum(s: Shapes.Shapes, area: AreaData.Area, style: Style)
	local center = STAGE_Y + DRUM_H / 2
	s:cyl("Drum", DRUM_H, DRUM_D, CFrame.new(0, center, 0), style.body, M.SmoothPlastic)
	for _, y in { STAGE_Y + 0.3, STAGE_Y + DRUM_H - 0.2 } do
		local band = s:cyl("DrumBand", 0.55, DRUM_D + 0.4, CFrame.new(0, y, 0), style.trim, M.Metal)
		band.Reflectance = 0.15
	end
	s:cyl("DrumCollar", 0.9, DRUM_D - 1.4, CFrame.new(0, STAGE_Y + DRUM_H + 0.45, 0), Palette.Frame, M.Metal)
	-- Curved price screen on the front: a bezel and three screen slices that follow the drum
	local screenY = STAGE_Y + 3.2
	for i = -1, 1 do
		local angle = math.rad(i * 17)
		local at = CFrame.Angles(0, -angle, 0) * CFrame.new(0, screenY, -DRUM_D / 2 - 0.05)
		s:deco("ScreenBezel", v3(2.2, 2.9, 0.25), at, Palette.Frame, M.SmoothPlastic)
	end
	local screen = s:deco("Screen", v3(5.6, 2.3, 0.2), CFrame.new(0, screenY, -DRUM_D / 2 - 0.35), Palette.Screen)
	screen.CastShadow = false
	local screenText = Build.surfaceText(
		screen,
		Enum.NormalId.Front,
		`🎰 BRAINROT ROLL\nCost: {Format.money(area.rollCost)}\n🍀 Block Luck: {Format.multiplier(area.luck)}`,
		{ textColor = rgb(255, 236, 130), pixelsPerStud = 40 }
	)
	screenText.Name = "ScreenText"
	-- Mystery windows either side of the screen: what will you get?
	for _, side in { -1, 1 } do
		local at = CFrame.Angles(0, math.rad(side * 48), 0) * CFrame.new(0, screenY, -DRUM_D / 2 - 0.05)
		s:deco("MysteryRim", v3(0.2, 2.3, 2.3), at * CFrame.Angles(0, math.pi / 2, 0), Palette.Frame, M.Metal).Shape =
			Enum.PartType.Cylinder
		local window = s:deco(
			"MysteryWindow",
			v3(0.12, 1.9, 1.9),
			at * CFrame.new(0, 0, -0.1) * CFrame.Angles(0, math.pi / 2, 0),
			style.glow:Lerp(Palette.Ink, 0.6),
			M.Glass
		)
		window.Shape = Enum.PartType.Cylinder
		Build.surfaceText(window, Enum.NormalId.Right, "?", { textColor = style.glow, pixelsPerStud = 40 })
	end
	-- Side vents
	for _, side in { -1, 1 } do
		for i = 0, 1 do
			local at = CFrame.Angles(0, math.rad(side * 70), 0)
				* CFrame.new(0, STAGE_Y + 1.9 + i * 0.8, -DRUM_D / 2 - 0.02)
			s:deco("Vent", v3(2.6, 0.22, 0.1), at, Palette.Frame, M.Metal)
		end
	end
end

-- The glass dome with its turntable, capsules, chase bulbs and a beacon on top
local function dome(s: Shapes.Shapes, style: Style): number
	local glass = s:ball("Dome", DOME_D, v3(0, DOME_Y, 0), Palette.Glass, M.Glass, false)
	glass.Transparency = 0.78
	glass.CastShadow = false
	-- Floor of the dome: turntable and a heap of two-tone prize capsules
	local floorY = STAGE_Y + DRUM_H + 0.95
	s:cyl("DomeFloor", 0.3, DOME_D - 1.2, CFrame.new(0, floorY, 0), Palette.Frame, M.Metal, false)
	local turntable = Shapes.model(s.parent, "Turntable", s.origin)
	turntable:cyl("TurntableBase", 0.35, 4.6, CFrame.new(0, floorY + 0.3, 0), style.trim, M.Metal, false)
	local capsuleColors =
		{ rgb(255, 110, 110), rgb(110, 200, 255), rgb(255, 214, 80), rgb(150, 230, 120), rgb(200, 140, 255) }
	for i = 0, 9 do
		local angle = i * 2.4
		local radius = 3.1 + (i % 2) * 0.6
		local at = v3(math.cos(angle) * radius, floorY + 0.75 + (i % 3) * 0.15, math.sin(angle) * radius)
		local color = capsuleColors[i % #capsuleColors + 1]
		s:ball("Capsule", 1.1, at, color, M.SmoothPlastic, false)
	end
	-- Crown: a chrome ring, a cap and the beacon
	local top = DOME_Y + DOME_D / 2
	s:cyl("DomeCap", 0.9, 3.4, CFrame.new(0, top - 0.2, 0), style.trim, M.Metal)
	s:cyl("DomeCapRim", 0.4, 2.2, CFrame.new(0, top + 0.4, 0), Palette.Frame, M.Metal)
	local beacon = s:ball("Beacon", 1.6, v3(0, top + 1.3, 0), style.glow, M.Neon, false)
	beacon.CastShadow = false
	Build.light(beacon, style.glow, 16, 1)
	-- Chase bulbs around the dome's collar
	for i = 0, 15 do
		local angle = i * math.pi * 2 / 16
		local bulb = s:ball(
			"Bulb",
			0.46,
			v3(math.sin(angle) * (DRUM_D / 2 - 0.55), STAGE_Y + DRUM_H + 0.95, -math.cos(angle) * (DRUM_D / 2 - 0.55)),
			Palette.LightWarm,
			M.Neon,
			false
		)
		bulb.CastShadow = false
		bulb:SetAttribute("Index", i + 1)
	end
	-- A spotlight in the cap shining down on the featured Brainrot
	local lamp = s:deco("DomeLamp", v3(1, 0.3, 1), CFrame.new(0, top - 0.7, 0), Palette.LightWarm, M.Neon)
	s:spot(lamp, Palette.LightWarm, 12, 1.4, 50, Enum.NormalId.Bottom)
	return floorY + 0.5
end

-- Glass feed pipes up both sides, two tanks of glowing brainrot juice at the back
local function pipes(s: Shapes.Shapes, style: Style)
	for _, side in { -1, 1 } do
		local x = side * 7.4
		local points = {
			v3(x, STAGE_Y, 1.5),
			v3(x, DOME_Y + 0.5, 1.5),
			v3(side * 4.6, DOME_Y + 2.3, 1.2),
		}
		for i = 1, #points - 1 do
			local pipeGlass = s:rod("Pipe", points[i], points[i + 1], 1.2, Palette.Glass, M.Glass, false)
			pipeGlass.Transparency = 0.55
			pipeGlass.CastShadow = false
			s:rod("PipeCore", points[i], points[i + 1], 0.55, style.glow, M.Neon, false).CastShadow = false
		end
		s:ball("PipeElbow", 1.5, points[2], style.trim, M.Metal, false)
		for _, y in { STAGE_Y + 4 } do
			s:cyl("PipeClamp", 0.35, 1.5, CFrame.new(x, y, 1.5), Palette.Frame, M.Metal, false)
		end
		local tank = CFrame.new(side * 4.6, STAGE_Y + 2.6, 5.6)
		s:cyl("Tank", 5.2, 2.6, tank, Palette.Glass, M.Glass, false).Transparency = 0.5
		s:cyl("TankLiquid", 3.8, 2.2, tank * CFrame.new(0, -0.6, 0), style.glow, M.Neon, false).CastShadow = false
		s:cyl("TankCap", 0.45, 2.9, tank * CFrame.new(0, 2.7, 0), style.trim, M.Metal)
		s:cyl("TankFoot", 0.45, 2.9, tank * CFrame.new(0, -2.7, 0), Palette.Frame, M.Metal)
	end
end

-- The crank on the machine's right side (the client turns it on every roll)
local function crank(s: Shapes.Shapes, style: Style)
	local x = DRUM_D / 2 + 0.3
	local hub = v3(x + 0.4, STAGE_Y + 3.2, 0)
	s:cyl(
		"CrankMount",
		0.6,
		2.6,
		CFrame.new(hub - v3(0.2, 0, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Palette.Frame,
		M.Metal
	)
	local lever = Shapes.model(s.parent, "Lever", s.origin)
	lever.parent:SetAttribute("Pivot", s:world(CFrame.new(hub)).Position)
	lever:cyl(
		"CrankWheel",
		0.5,
		3.4,
		CFrame.new(hub + v3(0.3, 0, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		style.trim,
		M.Metal,
		false
	)
	for i = 0, 2 do
		local angle = i * math.pi * 2 / 3
		lever:rod(
			"CrankSpoke",
			hub + v3(0.55, 0, 0),
			hub + v3(0.55, math.cos(angle) * 1.5, math.sin(angle) * 1.5),
			0.3,
			Palette.Frame,
			M.Metal,
			false
		)
	end
	lever:rod("CrankArm", hub + v3(0.7, 0, 0), hub + v3(0.7, 2.6, -1.2), 0.45, style.trim, M.Metal, false)
	lever:ball("CrankKnob", 1.2, hub + v3(0.9, 2.9, -1.35), Palette.Red, M.SmoothPlastic, false)
end

-- The console in front: a coin slot, the big ROLL button and a few blinkenlights
local function console(s: Shapes.Shapes, area: AreaData.Area, style: Style)
	local z = -DRUM_D / 2 - 2.6
	s:box("Console", v3(6.4, 2.6, 2.4), CFrame.new(0, STAGE_Y + 1.3, z), style.body, M.SmoothPlastic)
	for _, side in { -1, 1 } do
		s:cyl("ConsoleEnd", 2.6, 2.4, CFrame.new(side * 3.2, STAGE_Y + 1.3, z), style.body, M.SmoothPlastic)
	end
	s:deco("ConsoleStripe", v3(6.5, 0.35, 2.5), CFrame.new(0, STAGE_Y + 0.6, z), Palette.Stripe)
	-- Sloped control top, tilted toward the player
	local tilt = math.rad(18)
	local top = CFrame.new(0, STAGE_Y + 2.75, z) * CFrame.Angles(-tilt, 0, 0)
	s:box("ConsoleTop", v3(8.6, 0.4, 2.6), top, Palette.Frame, M.Metal)
	s:cyl("ButtonRing", 0.3, 2.9, top * CFrame.new(0, 0.3, 0), style.trim, M.Metal, false)
	local button = s:cyl("RollButton", 0.7, 2.3, top * CFrame.new(0, 0.6, 0), Palette.Red, M.Neon)
	button.CastShadow = false
	Build.light(button, rgb(255, 90, 90), 10, 1)
	local prompt =
		Build.prompt(button, "Roll", "ROLL!", `🎰 {area.name} - {Format.money(area.rollCost)}`, { AreaId = area.id })
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- Coin slot with a gold coin halfway in
	s:box("CoinSlotPlate", v3(1.3, 0.2, 1.3), top * CFrame.new(-2.8, 0.3, 0), style.trim, M.Metal, false)
	s:box("CoinSlot", v3(0.8, 0.22, 0.18), top * CFrame.new(-2.8, 0.34, 0), Palette.Ink, M.SmoothPlastic, false)
	s:cyl(
		"Coin",
		0.12,
		0.7,
		top * CFrame.new(-2.8, 0.62, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Palette.Gold,
		M.Foil,
		false
	)
	for i, color in { Palette.Green, Palette.Blue, Palette.Stripe } do
		s:cyl("SmallButton", 0.3, 0.55, top * CFrame.new(2.3 + (i - 1) * 0.75, 0.3, 0.3), color, M.Neon, false).CastShadow =
			false
	end
	-- Name plate on the console's face
	local plate = s:deco("ConsolePlate", v3(4.8, 0.8, 0.12), CFrame.new(0, STAGE_Y + 1.45, z - 1.25), Palette.Ink)
	Build.surfaceText(plate, Enum.NormalId.Front, "INSERT COIN • PULL • PRAY", {
		textColor = Palette.Stripe,
		pixelsPerStud = 40,
	})
end

-- An arch over the machine carrying the block's name in a lit marquee
local function marquee(s: Shapes.Shapes, area: AreaData.Area, style: Style)
	local z = 3.6
	local top = DOME_Y + DOME_D / 2 + 3.4
	for _, side in { -1, 1 } do
		local x = side * 9.6
		s:box("ArchPost", v3(1.4, top, 1.4), CFrame.new(x, top / 2, z), Palette.Frame, M.Metal)
		s:box("ArchPostTrim", v3(1.5, 0.4, 1.5), CFrame.new(x, 7.2, z), Palette.Stripe, M.SmoothPlastic, false)
		s:box("ArchFoot", v3(2.4, 1.2, 2.4), CFrame.new(x, 0.6, z), Palette.Frame, M.Concrete)
	end
	s:box("ArchBeam", v3(20.6, 1.2, 1.4), CFrame.new(0, top, z), Palette.Frame, M.Metal)
	local sign = s:deco("Marquee", v3(15, 2.6, 0.5), CFrame.new(0, top + 1.9, z - 0.2), style.body, M.SmoothPlastic)
	Build.surfaceText(sign, Enum.NormalId.Front, `{area.emoji} {string.upper(area.name)}`, {
		textColor = Palette.White,
		strokeColor = Palette.Ink,
		pixelsPerStud = 30,
	})
	local edge = s:deco("MarqueeEdge", v3(15.6, 3.2, 0.3), CFrame.new(0, top + 1.9, z), Palette.Frame, M.Metal)
	edge.CastShadow = false
	for i = 0, 8 do
		local bulb = s:ball("Bulb", 0.4, v3(-7 + i * 1.75, top + 3.4, z - 0.35), Palette.LightWarm, M.Neon, false)
		bulb.CastShadow = false
		bulb:SetAttribute("Index", 30 + i)
	end
end

-- Builds a machine at `cframe` (the front of the machine faces the CFrame's LookVector).
function RollMachine.build(parent: Instance, area: AreaData.Area, cframe: CFrame, style: Style): Model
	local model = Instance.new("Model")
	model.Name = `{area.id}Machine`
	model:SetAttribute("AreaId", area.id)
	model.Parent = parent
	local s = Shapes.new(model, cframe)

	stage(s, style)
	drum(s, area, style)
	local floor = dome(s, style)
	pipes(s, style)
	crank(s, style)
	console(s, area, style)
	marquee(s, area, style)

	-- Built at a comfortable working size, then grown so it dominates its room like a centerpiece
	model.WorldPivot = cframe
	model:ScaleTo(SIZE)
	local lever = model:FindFirstChild("Lever")
	local pivot = lever and lever:GetAttribute("Pivot")
	if lever and typeof(pivot) == "Vector3" then
		lever:SetAttribute("Pivot", cframe.Position + (pivot - cframe.Position) * SIZE)
	end

	if style.featured then
		-- Fit the featured Brainrot inside the dome, whatever its size
		local bounds = BrainrotModel.bounds(style.featured)
		local scale = math.min(1.25, 7.4 / math.max(bounds.X, bounds.Y, 1)) * SIZE
		local featured = BrainrotModel.build(style.featured, { scale = scale })
		featured.Name = "Featured"
		featured:PivotTo(cframe * CFrame.new(0, floor * SIZE, 0))
		featured.Parent = model
		featured:AddTag("Spin")
	end
	return model
end

return RollMachine
