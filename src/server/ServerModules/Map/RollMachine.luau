-- The Brainrot Roller: each block's roll machine. A painted arcade cabinet with a sloped control
-- desk and a big ROLL button, a price screen, and a glass chamber on top where the block's featured
-- Brainrot spins on a turntable. Glowing pipes feed "brainrot juice" into the chamber.
--
-- Named parts the client animates (Controllers/Machines): Bulb (Index attribute, chase lights),
-- PipeCore and TankLiquid (pulse), Beacon (flash on a roll), Turntable, Lever.
-- Gameplay hooks: the model's AreaId attribute, the Roll prompt on RollButton, and ScreenText.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Build = require(script.Parent.Parent.Build)
local Format = require(ReplicatedStorage.Modules.Format)
local Palette = require(script.Parent.Palette)
local Shapes = require(script.Parent.Shapes)

local RollMachine = {}

local M = Enum.Material
local v3 = Vector3.new

export type Style = {
	body: Color3,
	trim: Color3,
	glow: Color3,
	featured: string?,
}

local CABINET_W, CABINET_H, CABINET_D = 10, 9, 8
local BASE_Y = 0.86 -- top of the dais
local CHAMBER_D, CHAMBER_H = 10, 11

local function dais(s: Shapes.Shapes, style: Style)
	s:cyl("Dais", 0.8, 22, CFrame.new(0, 0.4, 0), Palette.SteelDark, M.DiamondPlate)
	s:cyl("DaisHazard", 0.3, 22.4, CFrame.new(0, 0.6, 0), Palette.Hazard, M.SmoothPlastic, false)
	local ring = s:cyl("DaisGlow", 0.84, 20.4, CFrame.new(0, 0.42, 0), style.glow, M.Neon, false)
	ring.CastShadow = false
	s:cyl("DaisTop", 0.86, 19.8, CFrame.new(0, 0.43, 0), Palette.Steel, M.DiamondPlate)
end

local function cabinet(s: Shapes.Shapes, style: Style)
	local cz = 1
	local top = BASE_Y + CABINET_H
	s:box(
		"Cabinet",
		v3(CABINET_W, CABINET_H, CABINET_D),
		CFrame.new(0, BASE_Y + CABINET_H / 2, cz),
		style.body,
		M.SmoothPlastic
	)
	-- Dark inset front panel and chrome edges
	local front = cz - CABINET_D / 2
	s:deco(
		"FrontPanel",
		v3(CABINET_W - 1.2, CABINET_H - 1.2, 0.2),
		CFrame.new(0, BASE_Y + CABINET_H / 2, front - 0.05),
		Palette.SteelDark
	)
	for _, x in { -CABINET_W / 2, CABINET_W / 2 } do
		for _, z in { front, cz + CABINET_D / 2 } do
			s:cyl("ChromeEdge", CABINET_H, 0.5, CFrame.new(x, BASE_Y + CABINET_H / 2, z), style.trim, M.Metal, false)
		end
		-- Side light panels
		s:glow(
			"SidePanel",
			v3(0.15, CABINET_H - 2.4, CABINET_D - 2.2),
			CFrame.new(x * 1.016, BASE_Y + CABINET_H / 2, cz),
			style.glow
		)
	end
	s:box("CabinetTop", v3(CABINET_W + 0.6, 0.5, CABINET_D + 0.6), CFrame.new(0, top + 0.25, cz), style.trim, M.Metal)
	s:box(
		"CabinetFoot",
		v3(CABINET_W + 0.6, 0.5, CABINET_D + 0.6),
		CFrame.new(0, BASE_Y + 0.25, cz),
		Palette.SteelDark,
		M.Metal
	)
	return front
end

local function screenAndMarquee(s: Shapes.Shapes, area: AreaData.Area, front: number, style: Style)
	-- Price screen in a chrome bezel
	s:deco("ScreenBezel", v3(8.4, 3.6, 0.3), CFrame.new(0, BASE_Y + 5.75, front - 0.2), style.trim, M.Metal)
	local screen = s:deco("Screen", v3(7.8, 3.1, 0.2), CFrame.new(0, BASE_Y + 5.75, front - 0.32), Palette.Screen)
	screen.CastShadow = false
	local screenText = Build.surfaceText(
		screen,
		Enum.NormalId.Front,
		`🎰 BRAINROT ROLL\nCost: {Format.money(area.rollCost)}\n🍀 Block Luck: {Format.multiplier(area.luck)}`,
		{ textColor = Color3.fromRGB(255, 236, 130), pixelsPerStud = 40 }
	)
	screenText.Name = "ScreenText"

	-- Lit marquee with the block's name
	local marquee = s:deco("Marquee", v3(9.2, 1.3, 0.4), CFrame.new(0, BASE_Y + 8.3, front - 0.25), style.glow, M.Neon)
	marquee.CastShadow = false
	Build.surfaceText(
		marquee,
		Enum.NormalId.Front,
		`{area.emoji} {area.name}`,
		{ textColor = Palette.White, strokeColor = Palette.Ink, pixelsPerStud = 40 }
	)

	-- Chase bulbs around the front edge
	local index = 0
	local function bulb(x: number, y: number)
		index += 1
		local part = s:ball("Bulb", 0.42, v3(x, y, front - 0.3), Palette.LightWarm, M.Neon, false)
		part.CastShadow = false
		part:SetAttribute("Index", index)
	end
	for i = 0, 6 do
		bulb(-CABINET_W / 2 + 0.2, BASE_Y + 1.2 + i * 1.12)
	end
	for i = 0, 8 do
		bulb(-3.6 + i * 0.9, BASE_Y + CABINET_H - 0.35)
	end
	for i = 6, 0, -1 do
		bulb(CABINET_W / 2 - 0.2, BASE_Y + 1.2 + i * 1.12)
	end
end

local function controlDesk(s: Shapes.Shapes, area: AreaData.Area, front: number, style: Style)
	-- A desk in front of the cabinet with a sloped top facing the player
	local deskZ = front - 1.3
	s:box("Desk", v3(9, 2.4, 2.6), CFrame.new(0, BASE_Y + 1.2, deskZ), style.body, M.SmoothPlastic)
	s:deco("DeskStripe", v3(9.05, 0.35, 2.65), CFrame.new(0, BASE_Y + 0.7, deskZ), Palette.Hazard)
	local slope = CFrame.new(0, BASE_Y + 2.4 + 0.5, deskZ)
	s:wedge("DeskTop", v3(9, 1, 2.6), slope, Palette.SteelDark, M.Metal)
	-- Buttons sit on the slope: tilt them to match it
	local tilt = math.atan2(1, 2.6)
	local surface = CFrame.new(0, BASE_Y + 2.92, deskZ) * CFrame.Angles(-tilt, 0, 0)
	s:cyl("ButtonRing", 0.3, 3.1, surface * CFrame.new(0, 0.05, 0), style.trim, M.Metal, false)
	local button = s:cyl("RollButton", 0.7, 2.5, surface * CFrame.new(0, 0.35, 0), Palette.Red, M.Neon)
	button.CastShadow = false
	Build.light(button, Color3.fromRGB(255, 90, 90), 10, 1)
	local prompt =
		Build.prompt(button, "Roll", "ROLL!", `🎰 {area.name} - {Format.money(area.rollCost)}`, { AreaId = area.id })
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	for i, color in { Palette.Green, Palette.Blue, Palette.Hazard } do
		local x = -3.3 + (i - 1) * 0.9
		s:cyl("SmallButton", 0.35, 0.6, surface * CFrame.new(x, 0.2, 0.1), color, M.Neon, false).CastShadow = false
	end
	for i = 0, 1 do
		s:cyl("Dial", 0.3, 0.8, surface * CFrame.new(3.0 + i * 0.95, 0.15, 0.1), Palette.Chrome, M.Metal, false)
	end
	-- Name plate on the desk front
	local plate = s:deco("DeskPlate", v3(5.5, 0.9, 0.15), CFrame.new(0, BASE_Y + 1.55, deskZ - 1.35), Palette.Ink)
	Build.surfaceText(
		plate,
		Enum.NormalId.Front,
		"BRAINROT ROLLER 3000",
		{ textColor = Palette.Gold, pixelsPerStud = 40 }
	)
end

local function chamber(s: Shapes.Shapes, style: Style)
	local cz = 1
	local bottom = BASE_Y + CABINET_H + 0.5
	local center = CFrame.new(0, bottom + CHAMBER_H / 2, cz)
	local glass = s:cyl("ChamberGlass", CHAMBER_H, CHAMBER_D, center, Palette.Glass, M.Glass, false)
	glass.Transparency = 0.72
	glass.CastShadow = false
	for _, y in { bottom + 0.3, bottom + CHAMBER_H - 0.3 } do
		s:cyl("ChamberRing", 0.6, CHAMBER_D + 0.6, CFrame.new(0, y, cz), style.trim, M.Metal)
	end
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		local x, z = math.sin(angle) * (CHAMBER_D / 2 + 0.1), cz - math.cos(angle) * (CHAMBER_D / 2 + 0.1)
		s:cyl("ChamberRib", CHAMBER_H, 0.35, CFrame.new(x, bottom + CHAMBER_H / 2, z), style.trim, M.Metal, false)
	end
	local dome = s:ball("ChamberDome", CHAMBER_D, v3(0, bottom + CHAMBER_H, cz), Palette.Glass, M.Glass, false)
	dome.Transparency = 0.72
	dome.CastShadow = false
	local capY = bottom + CHAMBER_H + CHAMBER_D / 2
	s:cyl("DomeCap", 0.8, 2.2, CFrame.new(0, capY, cz), style.trim, M.Metal)
	local beacon = s:ball("Beacon", 1.4, v3(0, capY + 1, cz), style.glow, M.Neon, false)
	beacon.CastShadow = false
	Build.light(beacon, style.glow, 18, 1.2)

	-- Turntable
	local turntable = Shapes.model(s.parent, "Turntable", s.origin)
	turntable:cyl("TurntableBase", 0.5, 7.6, CFrame.new(0, bottom + 0.25, cz), Palette.SteelDark, M.Metal, false)
	local glowRing =
		turntable:cyl("TurntableGlow", 0.52, 8, CFrame.new(0, bottom + 0.24, cz), style.glow, M.Neon, false)
	glowRing.CastShadow = false
	return bottom + 0.5
end

local function pipes(s: Shapes.Shapes, style: Style)
	local cz = 1
	for _, side in { -1, 1 } do
		local x = side * (CABINET_W / 2 + 1.4)
		local points = {
			v3(x, 0.8, cz + 2),
			v3(x, BASE_Y + CABINET_H + 3.5, cz + 2),
			v3(side * (CHAMBER_D / 2 - 0.3), BASE_Y + CABINET_H + 3.5, cz + 1),
		}
		for i = 1, #points - 1 do
			local pipeGlass = s:rod("Pipe", points[i], points[i + 1], 1.3, Palette.Glass, M.Glass, false)
			pipeGlass.Transparency = 0.55
			pipeGlass.CastShadow = false
			local core = s:rod("PipeCore", points[i], points[i + 1], 0.6, style.glow, M.Neon, false)
			core.CastShadow = false
		end
		s:ball("PipeElbow", 1.6, points[2], style.trim, M.Metal, false)
		s:cyl("PipeCollar", 0.6, 1.8, CFrame.new(points[1] + v3(0, 0.3, 0)), style.trim, M.Metal, false)
	end
	-- Juice tank behind the cabinet
	local tank = CFrame.new(0, BASE_Y + 3, cz + CABINET_D / 2 + 1.6)
	s:cyl("Tank", 6, 3, tank, Palette.Glass, M.Glass, false).Transparency = 0.5
	local liquid = s:cyl("TankLiquid", 4.2, 2.6, tank * CFrame.new(0, -0.8, 0), style.glow, M.Neon, false)
	liquid.CastShadow = false
	s:cyl("TankCap", 0.5, 3.3, tank * CFrame.new(0, 3.1, 0), style.trim, M.Metal)
	s:cyl("TankFoot", 0.5, 3.3, tank * CFrame.new(0, -3.1, 0), Palette.SteelDark, M.Metal)
end

local function lever(s: Shapes.Shapes, style: Style)
	local cz = 1
	local x = CABINET_W / 2 + 0.3
	s:box("LeverPlate", v3(0.6, 2.4, 2.4), CFrame.new(x, BASE_Y + 5.5, cz - 1), style.trim, M.Metal)
	local pivot = CFrame.new(x + 0.6, BASE_Y + 5.5, cz - 1)
	local leverModel = Shapes.model(s.parent, "Lever", s.origin)
	leverModel.parent:SetAttribute("Pivot", pivot.Position)
	leverModel:rod(
		"LeverArm",
		pivot.Position,
		pivot.Position + v3(0.4, 4.2, -0.6),
		0.45,
		Palette.Chrome,
		M.Metal,
		false
	)
	leverModel:ball("LeverKnob", 1.4, pivot.Position + v3(0.45, 4.6, -0.66), Palette.Red, M.SmoothPlastic, false)
end

-- Builds a machine at `cframe` (the front of the machine faces the CFrame's LookVector).
function RollMachine.build(parent: Instance, area: AreaData.Area, cframe: CFrame, style: Style): Model
	local model = Instance.new("Model")
	model.Name = `{area.id}Machine`
	model:SetAttribute("AreaId", area.id)
	model.Parent = parent
	local s = Shapes.new(model, cframe)

	dais(s, style)
	local front = cabinet(s, style)
	screenAndMarquee(s, area, front, style)
	controlDesk(s, area, front, style)
	local floor = chamber(s, style)
	pipes(s, style)
	lever(s, style)

	if style.featured then
		local featured = BrainrotModel.build(style.featured, { scale = 1.25 })
		featured.Name = "Featured"
		featured:PivotTo(cframe * CFrame.new(0, floor, 1))
		featured.Parent = model
		featured:AddTag("Spin")
	end
	return model
end

return RollMachine
