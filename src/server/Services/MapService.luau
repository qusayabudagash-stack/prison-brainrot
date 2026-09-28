-- Builds the whole prison out of simple parts when the server starts:
--   Workspace.Lobby        Cell Block 1: spawn, first roll machine, shop / upgrade / rebirth / book stations
--   Workspace.Prison       the other blocks, each behind a gate that opens once you unlock it
--   Workspace.CellBlocks   one decoratable cell per player
--   Workspace.RollMachines one big roll machine per block
--   Workspace.Leaderboards four physical leaderboards
-- Cell Block 1 spans x -70..70, z -60..60. Each later block is 100 x 80 studs, continuing toward -Z.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Build = require(script.Parent.Parent.ServerModules.Build)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Format = require(ReplicatedStorage.Modules.Format)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

export type Board = {
	title: TextLabel,
	rows: { TextLabel },
}

local MapService = {}

MapService.cells = {} :: { Model }
MapService.boards = {} :: { [string]: Board }
MapService.kingCFrame = CFrame.new()
MapService.roamPoints = {} :: { Vector3 }
MapService.eventFolder = nil :: Folder?

local FLOOR_Y = 1
local WALL_HEIGHT = 20
local WALL_THICKNESS = 2
local DOOR_WIDTH = 20
local DOOR_HEIGHT = 14
local LOBBY_HALF_WIDTH = 70
local LOBBY_HALF_LENGTH = 60
local AREA_HALF_WIDTH = 50
local AREA_LENGTH = 80

local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(40, 40, 50)
local METAL = Color3.fromRGB(150, 155, 170)

-- Which Brainrot spins on top of each block's machine, to show off what you could win.
local FEATURED = {
	CellBlock1 = "PrisonKing",
	CellBlock2 = "ElectricInmate",
	MaxSecurity = "GoldenWarden",
	DeathRow = "SkullBoss",
	AlienBlock = "CosmicPrisoner",
	SecretBlock = "RainbowCriminal",
}

local CELL_COLORS = {
	Color3.fromRGB(255, 170, 170),
	Color3.fromRGB(170, 210, 255),
	Color3.fromRGB(190, 255, 170),
	Color3.fromRGB(255, 225, 150),
	Color3.fromRGB(220, 180, 255),
}

---------------------------------------------------------------------------
-- Geometry helpers
---------------------------------------------------------------------------

-- North-south extent of a block (entrance at zStart, far end at zEnd).
local function areaBounds(area: AreaData.Area): (number, number, number)
	if area.order == 1 then
		return LOBBY_HALF_LENGTH, -LOBBY_HALF_LENGTH, LOBBY_HALF_WIDTH
	end
	local zStart = -LOBBY_HALF_LENGTH - (area.order - 2) * AREA_LENGTH
	return zStart, zStart - AREA_LENGTH, AREA_HALF_WIDTH
end

local function areaCenterZ(area: AreaData.Area): number
	local zStart, zEnd = areaBounds(area)
	return (zStart + zEnd) / 2
end

-- Wall running along X at a fixed Z.
local function wallAlongX(parent: Instance, x1: number, x2: number, z: number, color: Color3, trim: Color3)
	local length = math.abs(x2 - x1)
	local x = (x1 + x2) / 2
	Build.part(
		parent,
		"Wall",
		Vector3.new(length, WALL_HEIGHT, WALL_THICKNESS),
		CFrame.new(x, FLOOR_Y + WALL_HEIGHT / 2, z),
		color
	)
	Build.deco(
		parent,
		"Baseboard",
		Vector3.new(length, 1.5, WALL_THICKNESS + 0.4),
		CFrame.new(x, FLOOR_Y + 0.75, z),
		WHITE
	)
	Build.deco(
		parent,
		"Trim",
		Vector3.new(length, 1, WALL_THICKNESS + 0.4),
		CFrame.new(x, FLOOR_Y + WALL_HEIGHT + 0.5, z),
		trim,
		Enum.Material.Neon
	)
end

-- Wall running along Z at a fixed X.
local function wallAlongZ(parent: Instance, z1: number, z2: number, x: number, color: Color3, trim: Color3)
	local length = math.abs(z2 - z1)
	local z = (z1 + z2) / 2
	Build.part(
		parent,
		"Wall",
		Vector3.new(WALL_THICKNESS, WALL_HEIGHT, length),
		CFrame.new(x, FLOOR_Y + WALL_HEIGHT / 2, z),
		color
	)
	Build.deco(
		parent,
		"Baseboard",
		Vector3.new(WALL_THICKNESS + 0.4, 1.5, length),
		CFrame.new(x, FLOOR_Y + 0.75, z),
		WHITE
	)
	Build.deco(
		parent,
		"Trim",
		Vector3.new(WALL_THICKNESS + 0.4, 1, length),
		CFrame.new(x, FLOOR_Y + WALL_HEIGHT + 0.5, z),
		trim,
		Enum.Material.Neon
	)
end

-- Wall along X with a doorway in the middle.
local function doorWall(parent: Instance, z: number, halfWidth: number, color: Color3, trim: Color3)
	wallAlongX(parent, -halfWidth, -DOOR_WIDTH / 2, z, color, trim)
	wallAlongX(parent, DOOR_WIDTH / 2, halfWidth, z, color, trim)
	local lintelHeight = WALL_HEIGHT - DOOR_HEIGHT
	Build.part(
		parent,
		"Lintel",
		Vector3.new(DOOR_WIDTH, lintelHeight, WALL_THICKNESS),
		CFrame.new(0, FLOOR_Y + DOOR_HEIGHT + lintelHeight / 2, z),
		color
	)
	Build.deco(
		parent,
		"Trim",
		Vector3.new(DOOR_WIDTH, 1, WALL_THICKNESS + 0.4),
		CFrame.new(0, FLOOR_Y + WALL_HEIGHT + 0.5, z),
		trim,
		Enum.Material.Neon
	)
end

local function lamp(parent: Instance, position: Vector3, color: Color3)
	Build.cylinder(parent, "LampPost", 9, 0.8, CFrame.new(position + Vector3.new(0, 4.5, 0)), DARK)
	local bulb =
		Build.ball(parent, "LampBulb", 2.4, CFrame.new(position + Vector3.new(0, 9.5, 0)), color, Enum.Material.Neon)
	bulb.CanCollide = false
	Build.light(bulb, color, 24, 1.2)
end

-- Places a model built around the origin (facing +Z) at `cframe`.
local function place(model: Model, cframe: CFrame)
	model.WorldPivot = CFrame.new()
	model:PivotTo(cframe)
end

---------------------------------------------------------------------------
-- Stations (shop, upgrades, rebirth, book, free luck, daily roll)
---------------------------------------------------------------------------

local function station(
	parent: Instance,
	name: string,
	emoji: string,
	label: string,
	action: string,
	actionText: string,
	color: Color3,
	cframe: CFrame
)
	local model = Build.model(parent, name)
	Build.part(model, "Base", Vector3.new(11, 1, 9), CFrame.new(0, 0.5, 0), WHITE)
	local counter = Build.part(model, "Counter", Vector3.new(10, 4, 3), CFrame.new(0, 3, 2), color)
	Build.deco(model, "CounterTop", Vector3.new(10.6, 0.5, 3.6), CFrame.new(0, 5.25, 2), WHITE)
	Build.part(model, "Back", Vector3.new(10, 12, 1), CFrame.new(0, 7, -3.5), color:Lerp(WHITE, 0.35))
	for _, x in { -4.8, 4.8 } do
		Build.part(model, "Post", Vector3.new(0.8, 12, 0.8), CFrame.new(x, 7, 3.2), WHITE)
	end
	local roof = Build.part(model, "Roof", Vector3.new(12, 1, 9), CFrame.new(0, 13.5, -0.3), color)
	for i = -2, 2 do
		Build.deco(model, "RoofStripe", Vector3.new(1.2, 1.1, 9.1), CFrame.new(i * 2.4, 13.5, -0.3), WHITE)
	end
	local sign = Build.deco(model, "Sign", Vector3.new(9.5, 3.4, 0.4), CFrame.new(0, 10.4, -2.8), WHITE)
	Build.surfaceText(sign, Enum.NormalId.Back, `{emoji} {label}`, { textColor = color, strokeColor = DARK })
	Build.light(roof, color, 16, 1)
	local prompt = Build.prompt(counter, action, actionText, `{emoji} {label}`)
	prompt.MaxActivationDistance = 14
	place(model, cframe)
	return model
end

---------------------------------------------------------------------------
-- Roll machines
---------------------------------------------------------------------------

local function buildMachine(parent: Instance, area: AreaData.Area)
	local model = Build.model(parent, `{area.id}Machine`)
	model:SetAttribute("AreaId", area.id)

	Build.part(model, "Platform", Vector3.new(20, 0.6, 16), CFrame.new(0, 0.3, 0), area.accentColor)
	Build.part(model, "Cabinet", Vector3.new(12, 18, 6), CFrame.new(0, 9.6, -3), area.wallColor)
	Build.deco(model, "CabinetStripe", Vector3.new(12.3, 1, 6.3), CFrame.new(0, 4, -3), WHITE)
	Build.deco(model, "CabinetStripe", Vector3.new(12.3, 1, 6.3), CFrame.new(0, 18.1, -3), WHITE, Enum.Material.Neon)

	local screen = Build.deco(model, "Screen", Vector3.new(10, 7, 0.4), CFrame.new(0, 9, 0.2), DARK)
	local screenText = Build.surfaceText(
		screen,
		Enum.NormalId.Back,
		`🎰 BRAINROT ROLL\nCost: {Format.money(area.rollCost)}\n🍀 Block Luck: {Format.multiplier(area.luck)}`,
		{ textColor = Color3.fromRGB(255, 240, 120), pixelsPerStud = 40 }
	)
	screenText.Name = "ScreenText"

	local sign = Build.deco(
		model,
		"Sign",
		Vector3.new(11, 3.5, 0.4),
		CFrame.new(0, 15.5, 0.2),
		area.accentColor,
		Enum.Material.Neon
	)
	Build.surfaceText(sign, Enum.NormalId.Back, `{area.emoji} {area.name}`, { textColor = WHITE })

	for index, x in { -6.6, 6.6 } do
		local column = Build.cylinder(
			model,
			"LightColumn",
			16,
			1.1,
			CFrame.new(x, 9.6, 0),
			if index == 1 then Color3.fromRGB(255, 80, 200) else Color3.fromRGB(80, 220, 255),
			Enum.Material.Neon
		)
		column.CanCollide = false
	end

	Build.cylinder(model, "Pedestal", 3, 3.4, CFrame.new(0, 2.1, 5), METAL)
	local button = Build.cylinder(
		model,
		"RollButton",
		0.7,
		2.8,
		CFrame.new(0, 3.95, 5),
		Color3.fromRGB(255, 50, 60),
		Enum.Material.Neon
	)
	Build.light(button, Color3.fromRGB(255, 80, 80), 10, 1)
	local prompt =
		Build.prompt(button, "Roll", "ROLL!", `🎰 {area.name} - {Format.money(area.rollCost)}`, { AreaId = area.id })
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E

	-- A cartoon lever on the side
	Build.cylinder(model, "Lever", 6, 0.5, CFrame.new(7.6, 11, -3) * CFrame.Angles(0, 0, math.rad(-15)), METAL)
	Build.ball(model, "LeverKnob", 1.6, CFrame.new(8.4, 14.2, -3), Color3.fromRGB(255, 50, 60))

	local featuredId = FEATURED[area.id]
	if featuredId then
		local featured = BrainrotModel.build(featuredId, { scale = 1.5 })
		featured.Name = "Featured"
		featured:PivotTo(CFrame.new(0, 18.6, -3))
		featured.Parent = model
		featured:AddTag("Spin")
	end

	place(model, CFrame.new(0, FLOOR_Y, areaCenterZ(area) + if area.order == 1 then 0 else 5))
end

---------------------------------------------------------------------------
-- Gates between blocks
---------------------------------------------------------------------------

local function buildGate(parent: Instance, area: AreaData.Area)
	local zStart = areaBounds(area)
	local gate = Build.model(parent, "Gate")
	gate:SetAttribute("AreaId", area.id)

	local collider = Build.part(
		gate,
		"Collider",
		Vector3.new(DOOR_WIDTH, DOOR_HEIGHT, 1),
		CFrame.new(0, FLOOR_Y + DOOR_HEIGHT / 2, zStart),
		area.accentColor,
		Enum.Material.ForceField
	)
	collider.Transparency = 0.3
	for i = -3, 3 do
		local bar = Build.cylinder(
			gate,
			"Bar",
			DOOR_HEIGHT,
			0.6,
			CFrame.new(i * 2.8, FLOOR_Y + DOOR_HEIGHT / 2, zStart),
			METAL,
			Enum.Material.Metal
		)
		bar.CanCollide = false
	end
	Build.prompt(
		collider,
		"Unlock",
		"Unlock",
		`{area.emoji} {area.name} - {Format.money(area.unlockCost)}`,
		{ AreaId = area.id }
	).MaxActivationDistance =
		16

	local sign = Build.deco(
		gate,
		"Sign",
		Vector3.new(DOOR_WIDTH + 2, 5, 0.4),
		CFrame.new(0, FLOOR_Y + DOOR_HEIGHT + 3, zStart + WALL_THICKNESS / 2 + 0.3),
		area.accentColor
	)
	Build.surfaceText(
		sign,
		Enum.NormalId.Back,
		`{area.emoji} {area.name}\n🔒 {Format.money(area.unlockCost)}`,
		{ textColor = WHITE }
	)
end

---------------------------------------------------------------------------
-- Player cells
---------------------------------------------------------------------------

local function buildCell(parent: Instance, index: number, cframe: CFrame): Model
	local model = Build.model(parent, `Cell{index}`)
	model:SetAttribute("CellIndex", index)
	model:SetAttribute("OwnerId", 0)
	local color = CELL_COLORS[(index - 1) % #CELL_COLORS + 1]

	Build.part(model, "CellFloor", Vector3.new(18, 0.3, 15), CFrame.new(0, 0.15, -0.5), color:Lerp(WHITE, 0.5))
	Build.part(model, "BackWall", Vector3.new(18, 12, 1), CFrame.new(0, 6, -7.5), color)
	for _, y in { 3, 9 } do
		Build.deco(model, "WallStripe", Vector3.new(18, 1, 1.1), CFrame.new(0, y, -7.5), WHITE)
	end
	for _, side in { -1, 1 } do
		Build.part(model, "SideWall", Vector3.new(1, 12, 15), CFrame.new(side * 9.5, 6, -0.5), color)
		for i = 0, 4 do
			local x = side * (8.5 - i * 1.25)
			Build.cylinder(model, "Bar", 12, 0.35, CFrame.new(x, 6, 7), METAL, Enum.Material.Metal)
		end
	end
	Build.part(model, "TopBeam", Vector3.new(20, 1, 1), CFrame.new(0, 12.5, 7), METAL, Enum.Material.Metal)

	local sign =
		Build.deco(model, "Sign", Vector3.new(15, 2.6, 0.4), CFrame.new(0, 14.4, 7.3), color, Enum.Material.Neon)
	local label =
		Build.surfaceText(sign, Enum.NormalId.Back, "🔓 EMPTY CELL", { textColor = DARK, strokeColor = WHITE })
	label.Name = "OwnerText"

	for i, x in { -5.5, 0, 5.5 } do
		Build.cylinder(model, "Pedestal", 1.2, 3.4, CFrame.new(x, 0.6, -4.5), WHITE)
		local anchor = Build.deco(model, `Display{i}`, Vector3.new(1, 1, 1), CFrame.new(x, 1.2, -4.5), WHITE)
		anchor.Transparency = 1
	end
	Build.folder(model, "Displays")
	Build.folder(model, "Decor")

	place(model, cframe)
	return model
end

---------------------------------------------------------------------------
-- Leaderboards
---------------------------------------------------------------------------

local function buildBoard(parent: Instance, id: string, titleText: string, x: number): Board
	local z = LOBBY_HALF_LENGTH - 0.5
	local board = Build.part(
		parent,
		`Board_{id}`,
		Vector3.new(22, 17, 1),
		CFrame.new(x, FLOOR_Y + 11.5, z),
		Color3.fromRGB(35, 30, 60)
	)
	for _, edge in { { 0, 8.7, 22.8, 0.8 }, { 0, -8.7, 22.8, 0.8 }, { -11.2, 0, 0.8, 17.4 }, { 11.2, 0, 0.8, 17.4 } } do
		Build.deco(
			parent,
			"BoardFrame",
			Vector3.new(edge[3], edge[4], 1.2),
			CFrame.new(x + edge[1], FLOOR_Y + 11.5 + edge[2], z),
			Color3.fromRGB(255, 200, 60),
			Enum.Material.Neon
		)
	end

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.MaxDistance = 200
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 80)
	title.TextStrokeTransparency = 0
	title.Text = titleText
	title.Parent = gui

	local list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.04, 0.16)
	list.Size = UDim2.fromScale(0.92, 0.82)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local rows = {}
	for rank = 1, GameConfig.LEADERBOARD.size do
		local row = Instance.new("TextLabel")
		row.Name = `Row{rank}`
		row.LayoutOrder = rank
		row.Size = UDim2.fromScale(1, 1 / GameConfig.LEADERBOARD.size)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.RichText = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = WHITE
		row.TextStrokeTransparency = 0.3
		row.Text = `#{rank}  ...`
		row.Parent = list
		table.insert(rows, row)
	end
	return { title = title, rows = rows }
end

---------------------------------------------------------------------------
-- Block decorations
---------------------------------------------------------------------------

local function decorateLobby(folder: Instance, area: AreaData.Area)
	-- Colorful floor bands
	for i = -3, 3, 2 do
		Build.deco(
			folder,
			"FloorBand",
			Vector3.new(20, 0.1, 120),
			CFrame.new(i * 20, FLOOR_Y + 0.05, 0),
			area.floorColor:Lerp(WHITE, 0.45)
		)
	end
	Build.cylinder(folder, "MachineRug", 0.12, 34, CFrame.new(0, FLOOR_Y + 0.06, 0), area.accentColor:Lerp(WHITE, 0.3)).CanCollide =
		false
	Build.deco(
		folder,
		"Path",
		Vector3.new(10, 0.12, 36),
		CFrame.new(0, FLOOR_Y + 0.06, 28),
		Color3.fromRGB(255, 240, 120)
	)

	for _, position in
		{
			Vector3.new(-48, FLOOR_Y, -48),
			Vector3.new(48, FLOOR_Y, -48),
			Vector3.new(-48, FLOOR_Y, 48),
			Vector3.new(48, FLOOR_Y, 48),
		}
	do
		lamp(folder, position, Color3.fromRGB(255, 230, 150))
	end

	-- Title board above the Cell Block 2 gate
	local titleBoard = Build.part(
		folder,
		"TitleBoard",
		Vector3.new(76, 14, 1),
		CFrame.new(0, FLOOR_Y + WALL_HEIGHT + 8, -LOBBY_HALF_LENGTH + 0.5),
		Color3.fromRGB(255, 90, 170)
	)
	Build.surfaceText(
		titleBoard,
		Enum.NormalId.Back,
		`🧠 {GameConfig.GAME_NAME} 🧠\n<font size="40">{GameConfig.TAGLINE}</font>`,
		{ textColor = Color3.fromRGB(255, 240, 90), strokeColor = DARK, pixelsPerStud = 12 }
	)
	Build.light(titleBoard, Color3.fromRGB(255, 160, 220), 30, 1)
end

local function bunkBed(parent: Instance, cframe: CFrame, color: Color3)
	for _, x in { -2, 2 } do
		for _, z in { -4, 4 } do
			Build.part(parent, "BunkPost", Vector3.new(0.5, 8, 0.5), cframe * CFrame.new(x, 4, z), METAL)
		end
	end
	for _, y in { 2, 6 } do
		Build.part(parent, "Bunk", Vector3.new(4.5, 0.6, 9), cframe * CFrame.new(0, y, 0), WHITE)
		Build.deco(parent, "Blanket", Vector3.new(4.6, 0.3, 5.5), cframe * CFrame.new(0, y + 0.4, 1.5), color)
		Build.deco(parent, "Pillow", Vector3.new(3, 0.5, 1.5), cframe * CFrame.new(0, y + 0.5, -3.5), WHITE)
	end
end

local function decorateCellBlock2(folder: Instance, area: AreaData.Area)
	local zc = areaCenterZ(area)
	for i, z in { zc - 25, zc, zc + 25 } do
		bunkBed(
			folder,
			CFrame.new(-44, FLOOR_Y, z),
			if i % 2 == 0 then area.accentColor else Color3.fromRGB(255, 120, 120)
		)
		bunkBed(
			folder,
			CFrame.new(44, FLOOR_Y, z),
			if i % 2 == 0 then Color3.fromRGB(120, 220, 120) else area.accentColor
		)
	end
	for _, x in { -20, 20 } do
		Build.part(
			folder,
			"Bench",
			Vector3.new(10, 1, 3),
			CFrame.new(x, FLOOR_Y + 2, zc + 22),
			Color3.fromRGB(200, 140, 80)
		)
		for _, dx in { -4, 4 } do
			Build.part(folder, "BenchLeg", Vector3.new(0.8, 2, 2.4), CFrame.new(x + dx, FLOOR_Y + 1, zc + 22), DARK)
		end
	end
	for _, x in { -30, 30 } do
		lamp(folder, Vector3.new(x, FLOOR_Y, zc - 30), Color3.fromRGB(120, 180, 255))
	end
end

local function decorateMaxSecurity(folder: Instance, area: AreaData.Area)
	local zStart, zEnd = areaBounds(area)
	local zc = areaCenterZ(area)
	for i = -9, 9 do
		if i % 2 == 0 then
			for _, z in { zStart - 3, zEnd + 3 } do
				Build.deco(folder, "HazardStripe", Vector3.new(5, 0.12, 3), CFrame.new(i * 5, FLOOR_Y + 0.06, z), DARK)
			end
		end
	end
	for _, corner in
		{
			Vector3.new(-42, 0, zStart - 10),
			Vector3.new(42, 0, zStart - 10),
			Vector3.new(-42, 0, zEnd + 10),
			Vector3.new(42, 0, zEnd + 10),
		}
	do
		Build.cylinder(folder, "Tower", 14, 2, CFrame.new(corner.X, FLOOR_Y + 7, corner.Z), METAL)
		local light = Build.ball(
			folder,
			"Searchlight",
			3.4,
			CFrame.new(corner.X, FLOOR_Y + 15, corner.Z),
			Color3.fromRGB(255, 240, 120),
			Enum.Material.Neon
		)
		Build.light(light, Color3.fromRGB(255, 240, 150), 30, 1.5)
	end
	for _, x in { -AREA_HALF_WIDTH + 1.5, AREA_HALF_WIDTH - 1.5 } do
		local camera = Build.part(folder, "Camera", Vector3.new(1.6, 1.6, 3), CFrame.new(x, FLOOR_Y + 15, zc), DARK)
		Build.ball(
			folder,
			"CameraLight",
			0.6,
			camera.CFrame * CFrame.new(0, 0.6, -1.6),
			Color3.fromRGB(255, 40, 40),
			Enum.Material.Neon
		)
	end
	local sign = Build.deco(
		folder,
		"Sign",
		Vector3.new(30, 6, 0.4),
		CFrame.new(0, FLOOR_Y + 13, zEnd + WALL_THICKNESS / 2 + 0.3),
		area.wallColor
	)
	Build.surfaceText(
		sign,
		Enum.NormalId.Back,
		"⚠️ NO ESCAPING ⚠️\n(pretty please)",
		{ textColor = DARK, strokeColor = WHITE }
	)
end

local TOMBSTONE_JOKES =
	{ "RIP\nmy coins", "RIP\nWi-Fi", "RIP\nhomework", "RIP\nescape plan", "RIP\nbad luck", "RIP\nmy 1st roll" }

local function decorateDeathRow(folder: Instance, area: AreaData.Area)
	local zc = areaCenterZ(area)
	for i, joke in TOMBSTONE_JOKES do
		local side = if i % 2 == 0 then 1 else -1
		local z = zc - 28 + math.ceil(i / 2) * 16
		local stone = Build.part(
			folder,
			"Tombstone",
			Vector3.new(5, 6, 1.5),
			CFrame.new(side * 38, FLOOR_Y + 3, z),
			Color3.fromRGB(190, 190, 210)
		)
		Build.cylinder(
			folder,
			"TombTop",
			1.5,
			5,
			CFrame.new(side * 38, FLOOR_Y + 6, z) * CFrame.Angles(math.pi / 2, 0, 0),
			Color3.fromRGB(190, 190, 210)
		)
		Build.surfaceText(stone, Enum.NormalId.Back, joke, { textColor = Color3.fromRGB(90, 60, 140) })
	end
	for _, spot in { { -22, -20 }, { 20, 18 }, { -18, 24 }, { 24, -26 }, { 0, -32 } } do
		Build.cylinder(
			folder,
			"Goo",
			0.15,
			7,
			CFrame.new(spot[1], FLOOR_Y + 0.08, zc + spot[2]),
			area.accentColor,
			Enum.Material.Neon
		).CanCollide =
			false
	end
	for _, x in { -30, 30 } do
		for _, dz in { -30, 30 } do
			lamp(folder, Vector3.new(x, FLOOR_Y, zc + dz), Color3.fromRGB(200, 120, 255))
		end
	end
end

local function decorateAlienBlock(folder: Instance, area: AreaData.Area)
	local zc = areaCenterZ(area)
	local ufoCenter = CFrame.new(0, FLOOR_Y + 30, zc - 20)
	local disc = Build.cylinder(folder, "UFO", 2.5, 28, ufoCenter, METAL, Enum.Material.Metal)
	disc.CanCollide = false
	local dome = Build.ball(
		folder,
		"UFODome",
		11,
		ufoCenter * CFrame.new(0, 2, 0),
		Color3.fromRGB(150, 255, 240),
		Enum.Material.Glass
	)
	dome.Transparency = 0.3
	dome.CanCollide = false
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		local light = Build.ball(
			folder,
			"UFOLight",
			1.4,
			ufoCenter * CFrame.new(math.cos(angle) * 13, -0.8, math.sin(angle) * 13),
			if i % 2 == 0 then area.accentColor else Color3.fromRGB(120, 255, 120),
			Enum.Material.Neon
		)
		light.CanCollide = false
	end
	local beam = Build.cylinder(
		folder,
		"TractorBeam",
		28,
		9,
		CFrame.new(0, FLOOR_Y + 15, zc - 20),
		Color3.fromRGB(160, 255, 200),
		Enum.Material.Neon
	)
	beam.Transparency = 0.75
	beam.CanCollide = false
	beam.CastShadow = false
	for i = 0, 5 do
		local x = if i % 2 == 0 then -38 else 38
		local z = zc - 30 + (i // 2) * 28
		Build.cylinder(folder, "AlienStalk", 7, 0.7, CFrame.new(x, FLOOR_Y + 3.5, z), Color3.fromRGB(90, 220, 110))
		local bulb =
			Build.ball(folder, "AlienBulb", 2.6, CFrame.new(x, FLOOR_Y + 7.5, z), area.accentColor, Enum.Material.Neon)
		Build.light(bulb, area.accentColor, 14, 1)
	end
	for _, spot in { { -20, 25 }, { 22, 28 }, { -26, -10 } } do
		Build.cylinder(
			folder,
			"Crater",
			0.15,
			8,
			CFrame.new(spot[1], FLOOR_Y + 0.08, zc + spot[2]),
			Color3.fromRGB(110, 190, 100)
		).CanCollide =
			false
	end
end

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(170, 90, 255),
}

local function decorateSecretBlock(folder: Instance, area: AreaData.Area)
	local zStart, zEnd = areaBounds(area)
	local zc = areaCenterZ(area)
	local rng = Random.new(1234)
	for i, color in RAINBOW do
		local side = if i % 2 == 0 then 1 else -1
		local z = zc - 30 + math.ceil(i / 2) * 18
		local pillar = Build.cylinder(
			folder,
			"RainbowPillar",
			18,
			3,
			CFrame.new(side * 40, FLOOR_Y + 9, z),
			color,
			Enum.Material.Neon
		)
		Build.light(pillar, color, 18, 1)
	end
	for _ = 1, 40 do
		local onLeft = rng:NextNumber() < 0.5
		local x = if onLeft then -AREA_HALF_WIDTH + 1.2 else AREA_HALF_WIDTH - 1.2
		local star = Build.ball(
			folder,
			"Star",
			rng:NextNumber(0.4, 1),
			CFrame.new(x, FLOOR_Y + rng:NextNumber(3, 19), rng:NextNumber(zEnd + 2, zStart - 2)),
			Color3.fromRGB(255, 250, 200),
			Enum.Material.Neon
		)
		star.CanCollide = false
	end
	for i = 1, 5 do
		local orb = Build.ball(
			folder,
			"Orb",
			3,
			CFrame.new(rng:NextNumber(-30, 30), FLOOR_Y + rng:NextNumber(14, 24), zc + rng:NextNumber(-30, 30)),
			RAINBOW[i],
			Enum.Material.Neon
		)
		orb.CanCollide = false
		Build.light(orb, RAINBOW[i], 20, 1)
	end
	local sign = Build.deco(
		folder,
		"Sign",
		Vector3.new(26, 7, 0.4),
		CFrame.new(0, FLOOR_Y + 13, zEnd + WALL_THICKNESS / 2 + 0.3),
		Color3.fromRGB(30, 20, 60),
		Enum.Material.Neon
	)
	Build.surfaceText(
		sign,
		Enum.NormalId.Back,
		"❓ THE SECRET BLOCK ❓\nsomething is hiding here...",
		{ textColor = Color3.fromRGB(255, 150, 255) }
	)
end

local DECORATORS: { [string]: (Instance, AreaData.Area) -> () } = {
	CellBlock1 = decorateLobby,
	CellBlock2 = decorateCellBlock2,
	MaxSecurity = decorateMaxSecurity,
	DeathRow = decorateDeathRow,
	AlienBlock = decorateAlienBlock,
	SecretBlock = decorateSecretBlock,
}

---------------------------------------------------------------------------
-- Blocks
---------------------------------------------------------------------------

local function buildArea(folder: Instance, area: AreaData.Area)
	local zStart, zEnd, halfWidth = areaBounds(area)
	local length = zStart - zEnd
	local zc = (zStart + zEnd) / 2
	Build.part(
		folder,
		"Floor",
		Vector3.new(halfWidth * 2, 1, length),
		CFrame.new(0, FLOOR_Y - 0.5, zc),
		area.floorColor
	)

	wallAlongZ(folder, zStart, zEnd, -halfWidth - WALL_THICKNESS / 2, area.wallColor, area.accentColor)
	wallAlongZ(folder, zStart, zEnd, halfWidth + WALL_THICKNESS / 2, area.wallColor, area.accentColor)

	if area.order == 1 then
		wallAlongX(folder, -halfWidth, halfWidth, zStart + WALL_THICKNESS / 2, area.wallColor, area.accentColor)
	end

	-- The far wall is the next block's gate, or a solid wall at the end of the prison.
	local nextArea = AreaData.Areas[area.order + 1]
	if nextArea then
		doorWall(folder, zEnd, halfWidth, area.wallColor, area.accentColor)
	else
		wallAlongX(folder, -halfWidth, halfWidth, zEnd - WALL_THICKNESS / 2, area.wallColor, area.accentColor)
	end

	if area.order > 1 then
		-- Name sign on the inside of the entrance, readable when you look back.
		local sign = Build.deco(
			folder,
			"AreaSign",
			Vector3.new(24, 4, 0.4),
			CFrame.new(0, FLOOR_Y + DOOR_HEIGHT + 3, zStart - WALL_THICKNESS / 2 - 0.3),
			area.accentColor
		)
		Build.surfaceText(sign, Enum.NormalId.Front, `{area.emoji} {area.name}`, { textColor = WHITE })
		buildGate(folder, area)
	end

	local decorate = DECORATORS[area.id]
	if decorate then
		decorate(folder, area)
	end
end

function MapService.init()
	local lobby = Build.folder(workspace, "Lobby")
	local prison = Build.folder(workspace, "Prison")
	local cellFolder = Build.folder(workspace, "CellBlocks")
	local machines = Build.folder(workspace, "RollMachines")
	local boards = Build.folder(workspace, "Leaderboards")
	MapService.eventFolder = Build.folder(workspace, "Events")

	for _, area in AreaData.Areas do
		local folder = if area.order == 1 then lobby else Build.folder(prison, area.id)
		buildArea(folder, area)
		buildMachine(machines, area)
	end

	-- Stations around the first roll machine
	local left = CFrame.Angles(0, math.rad(90), 0)
	local right = CFrame.Angles(0, math.rad(-90), 0)
	station(
		lobby,
		"ShopStation",
		"🛒",
		"SHOP",
		"Shop",
		"Open Shop",
		Color3.fromRGB(80, 200, 120),
		CFrame.new(-34, FLOOR_Y, 26) * left
	)
	station(
		lobby,
		"UpgradeStation",
		"⬆️",
		"UPGRADES",
		"Upgrades",
		"Upgrade",
		Color3.fromRGB(80, 150, 255),
		CFrame.new(-34, FLOOR_Y, 0) * left
	)
	station(
		lobby,
		"BookStation",
		"🧠",
		"BRAINROT BOOK",
		"Book",
		"Open Book",
		Color3.fromRGB(255, 120, 190),
		CFrame.new(34, FLOOR_Y, 26) * right
	)
	station(
		lobby,
		"RebirthStation",
		"🔄",
		"REBIRTH",
		"Rebirth",
		"Rebirth",
		Color3.fromRGB(170, 100, 255),
		CFrame.new(34, FLOOR_Y, 0) * right
	)
	station(
		lobby,
		"FreeLuckStation",
		"🍀",
		"FREE LUCK",
		"FreeBoost",
		"Claim",
		Color3.fromRGB(70, 210, 90),
		CFrame.new(-22, FLOOR_Y, -40)
	)
	station(
		lobby,
		"DailyRollStation",
		"🎁",
		"DAILY ROLL",
		"DailyRoll",
		"Free Roll",
		Color3.fromRGB(255, 170, 40),
		CFrame.new(22, FLOOR_Y, -40)
	)

	-- Player cells along the west and east walls of Cell Block 1, facing the middle
	local cellZ = { 44, 22, 0, -22, -44 }
	for i = 1, GameConfig.CELL_COUNT do
		local onWest = i <= #cellZ
		local z = cellZ[(i - 1) % #cellZ + 1]
		local cframe = if onWest
			then CFrame.new(-62, FLOOR_Y, z) * CFrame.Angles(0, math.rad(90), 0)
			else CFrame.new(62, FLOOR_Y, z) * CFrame.Angles(0, math.rad(-90), 0)
		table.insert(MapService.cells, buildCell(cellFolder, i, cframe))
	end

	-- Leaderboards on the wall behind the spawn
	for i, board in GameConfig.LEADERBOARD.boards do
		MapService.boards[board.id] = buildBoard(boards, board.id, board.title, -39 + (i - 1) * 26)
	end

	MapService.kingCFrame = CFrame.lookAt(Vector3.new(-16, FLOOR_Y, 18), Vector3.new(0, FLOOR_Y, 40))
	for _, x in { -44, -24, 0, 24, 44 } do
		for _, z in { -46, -22, 18, 44 } do
			table.insert(MapService.roamPoints, Vector3.new(x, FLOOR_Y, z))
		end
	end
end

return MapService
