-- The lobby's interactable stations, each built as a real prison object instead of a booth:
--   Shop       the commissary window          Upgrades   the workshop bench
--   Book       the records lectern            Rebirth    the parole board door
--   FreeBoost  the Luck-O-Mat vending machine DailyRoll  the mailroom care package
-- Each is built facing -Z with its back against a wall at about z = +4. The prompt's Action
-- attribute is what the client and server look for; model names are just for Studio.

local Build = require(script.Parent.Parent.Build)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Shapes = require(script.Parent.Shapes)

local Stations = {}

local M = Enum.Material
local v3 = Vector3.new
local rgb = Color3.fromRGB

local function prompt(part: BasePart, action: string, actionText: string, objectText: string)
	local p = Build.prompt(part, action, actionText, objectText)
	p.MaxActivationDistance = 14
	return p
end

-- Station title sign with a spotlight so interactables pop out of the neutral room.
local function title(s: Shapes.Shapes, text: string, color: Color3, y: number, width: number?)
	local w = width or 10
	s:deco("TitleBacking", v3(w + 0.6, 2.6, 0.3), CFrame.new(0, y, 3.4), Palette.SteelDark, M.Metal)
	local plate = s:glow("Title", v3(w, 2.1, 0.2), CFrame.new(0, y, 3.2), color)
	Build.surfaceText(
		plate,
		Enum.NormalId.Front,
		text,
		{ textColor = Palette.White, strokeColor = color:Lerp(Palette.Ink, 0.55), pixelsPerStud = 30 }
	)
	local lamp = s:deco("Spot", v3(1, 0.6, 1), CFrame.new(0, y + 3, -3), Palette.SteelDark, M.Metal)
	s:spot(lamp, rgb(255, 245, 230), 18, 1.6, 55, Enum.NormalId.Bottom)
	return plate
end

---------------------------------------------------------------------------

local function commissary(s: Shapes.Shapes)
	local green = rgb(64, 180, 104)
	-- Storefront: counter below a barred service window, shelves of goods behind
	s:box("BackWall", v3(12, 12, 1), CFrame.new(0, 6, 4), Palette.ConcreteWarm, M.Concrete)
	for _, x in { -5.3, 5.3 } do
		s:box("Pillar", v3(1.4, 10.6, 1.8), CFrame.new(x, 5.3, 0.2), green, M.SmoothPlastic)
	end
	s:box("Header", v3(12, 1.6, 1.8), CFrame.new(0, 9.8, 0.2), green, M.SmoothPlastic)
	local counter =
		s:box("Counter", v3(9.2, 3.6, 1.8), CFrame.new(0, 1.8, 0.2), green:Lerp(Palette.Ink, 0.15), M.SmoothPlastic)
	s:box("CounterTop", v3(9.6, 0.3, 2.8), CFrame.new(0, 3.75, -0.2), Palette.Chrome, M.Metal)
	for i = 0, 6 do
		s:cyl("WindowBar", 5.2, 0.2, CFrame.new(-3.9 + i * 1.3, 6.5, -0.4), Palette.Bars, M.Metal, false)
	end
	for row = 0, 2 do
		local y = 4.6 + row * 1.6
		s:deco("Shelf", v3(8.6, 0.2, 1.4), CFrame.new(0, y, 2.8), Palette.Steel, M.Metal)
		for i = 0, 6 do
			local colors = { Palette.Red, Palette.Hazard, Palette.Blue, Palette.White, Palette.Orange }
			local color = colors[(row * 3 + i) % #colors + 1]
			if (row + i) % 2 == 0 then
				s:cyl("Can", 0.9, 0.6, CFrame.new(-3.6 + i * 1.2, y + 0.55, 2.7), color, M.Metal, false)
			else
				s:deco("Box", v3(0.9, 1.1, 0.7), CFrame.new(-3.6 + i * 1.2, y + 0.65, 2.7), color, M.SmoothPlastic)
			end
		end
	end
	local glow = s:glow("ShelfLight", v3(8.6, 0.15, 0.3), CFrame.new(0, 9.1, 2.2), Palette.LightWarm)
	s:light(glow, Palette.LightWarm, 10, 0.8)
	-- Bell and register on the counter
	s:cyl("BellBase", 0.15, 0.9, CFrame.new(-2.6, 3.98, -0.7), Palette.SteelDark, M.Metal, false)
	s:ball("Bell", 0.7, v3(-2.6, 4.15, -0.7), Palette.Gold, M.Metal, false)
	s:deco("Register", v3(1.8, 1, 1.2), CFrame.new(2.8, 4.4, -0.3), Palette.SteelDark, M.SmoothPlastic)
	s:glow(
		"RegisterScreen",
		v3(1.2, 0.4, 0.05),
		CFrame.new(2.8, 5.05, -0.5) * CFrame.Angles(math.rad(-20), 0, 0),
		rgb(120, 255, 150)
	)
	-- Striped awning
	for i = 0, 5 do
		s:deco(
			"Awning",
			v3(2.1, 0.3, 3.2),
			CFrame.new(-5.25 + i * 2.1, 11.2, -1) * CFrame.Angles(math.rad(-18), 0, 0),
			if i % 2 == 0 then green else Palette.White,
			M.Fabric
		)
	end
	title(s, "🛒 COMMISSARY", green, 13.4)
	Props.noticeBoard(
		s.parent,
		s:world(CFrame.new(-7.6, 5.5, 3.3) * CFrame.Angles(0, math.rad(-8), 0)),
		{ "SPEED\nSHOES", "LUCK\nPOTION", "COMFY\nBED" }
	)
	prompt(counter, "Shop", "Open Shop", "🛒 SHOP")
end

local function workshop(s: Shapes.Shapes)
	local blue = rgb(60, 136, 236)
	-- Pegboard wall with tool silhouettes
	s:box("Pegboard", v3(12, 9, 0.6), CFrame.new(0, 6, 4), rgb(198, 164, 116), M.Wood)
	s:deco("PegFrame", v3(12.4, 9.4, 0.4), CFrame.new(0, 6, 4.2), Palette.WoodDark, M.Wood)
	s:rod("Wrench", v3(-4, 5, 3.6), v3(-4, 8, 3.6), 0.35, Palette.Chrome, M.Metal, false)
	s:cyl(
		"WrenchHead",
		0.3,
		1,
		CFrame.new(-4, 8.3, 3.6) * CFrame.Angles(math.pi / 2, 0, 0),
		Palette.Chrome,
		M.Metal,
		false
	)
	s:rod("Hammer", v3(-2, 5, 3.6), v3(-2, 7.8, 3.6), 0.3, Palette.Wood, M.Wood, false)
	s:deco("HammerHead", v3(1.4, 0.6, 0.4), CFrame.new(-2, 8, 3.6), Palette.SteelDark, M.Metal)
	s:deco("Saw", v3(3, 1, 0.1), CFrame.new(1.4, 7.5, 3.65), Palette.Chrome, M.Metal)
	s:deco("SawHandle", v3(0.8, 1.1, 0.3), CFrame.new(3.2, 7.5, 3.6), Palette.Red, M.SmoothPlastic)
	s:rod("Screwdriver", v3(3.5, 4.6, 3.6), v3(3.5, 6.2, 3.6), 0.18, Palette.Chrome, M.Metal, false)
	s:rod("ScrewdriverGrip", v3(3.5, 6.2, 3.6), v3(3.5, 7, 3.6), 0.4, Palette.Hazard, M.SmoothPlastic, false)
	-- Workbench with a vise and a toolbox
	local bench = s:box("Workbench", v3(11, 0.6, 3.4), CFrame.new(0, 3.4, 1.4), Palette.Wood, M.WoodPlanks)
	for _, x in { -5, 5 } do
		for _, z in { 0, 2.8 } do
			s:deco("BenchLeg", v3(0.5, 3.1, 0.5), CFrame.new(x, 1.55, z), Palette.SteelDark, M.Metal)
		end
	end
	s:deco("BenchShelf", v3(10.4, 0.3, 3), CFrame.new(0, 1, 1.4), Palette.SteelDark, M.Metal)
	s:box("Vise", v3(1.4, 1, 1.4), CFrame.new(-3.8, 4.2, 0.4), blue, M.Metal)
	s:deco("ViseJaw", v3(1.6, 0.6, 0.3), CFrame.new(-3.8, 4.6, -0.3), Palette.SteelDark, M.Metal)
	s:box("Toolbox", v3(2.6, 1.3, 1.3), CFrame.new(3.4, 4.35, 1.4), Palette.Red, M.Metal)
	s:deco("ToolboxHandle", v3(1.4, 0.2, 0.2), CFrame.new(3.4, 5.15, 1.4), Palette.SteelDark, M.Metal)
	-- A glowing gear: the thing you're upgrading
	local gear = s:cyl("Gear", 0.5, 2, CFrame.new(0, 4.05, 1) * CFrame.Angles(0, 0, 0), blue, M.Neon, false)
	gear.CastShadow = false
	for i = 0, 7 do
		local angle = i * math.pi / 4
		s:deco(
			"GearTooth",
			v3(0.5, 0.5, 0.5),
			CFrame.new(math.cos(angle) * 1.1, 4.05, 1 + math.sin(angle) * 1.1) * CFrame.Angles(0, -angle, 0),
			blue,
			M.Neon
		).CastShadow =
			false
	end
	s:light(gear, blue, 10, 1)
	title(s, "⬆️ UPGRADES", blue, 12)
	prompt(bench, "Upgrades", "Upgrade", "⬆️ UPGRADES")
end

local function records(s: Shapes.Shapes)
	local pink = rgb(236, 104, 176)
	-- Filing cabinets along the back wall
	for i = 0, 3 do
		local x = -4.5 + i * 3
		s:box("Cabinet", v3(2.8, 5.4, 2.2), CFrame.new(x, 2.7, 3), Palette.Steel, M.Metal)
		for d = 0, 2 do
			local y = 1 + d * 1.7
			s:deco("Drawer", v3(2.5, 1.5, 0.1), CFrame.new(x, y + 0.2, 1.88), Palette.SteelLight, M.Metal)
			s:deco("DrawerHandle", v3(0.9, 0.18, 0.18), CFrame.new(x, y + 0.5, 1.8), Palette.Chrome, M.Metal)
			s:deco("DrawerLabel", v3(0.8, 0.35, 0.05), CFrame.new(x, y - 0.1, 1.82), Palette.White)
		end
	end
	s:deco("Folders", v3(2, 0.6, 1.4), CFrame.new(-3, 5.7, 3), rgb(240, 200, 120))
	-- The Brainrot Book on a lectern
	local lectern = CFrame.new(0, 0, -1)
	s:box("LecternBase", v3(2.2, 0.4, 2.2), lectern * CFrame.new(0, 0.2, 0), Palette.WoodDark, M.Wood)
	s:box("LecternPost", v3(1, 3.2, 1), lectern * CFrame.new(0, 2, 0), Palette.WoodDark, M.Wood)
	local desk = s:box(
		"Lectern",
		v3(4.2, 0.4, 3),
		lectern * CFrame.new(0, 3.8, 0) * CFrame.Angles(math.rad(-20), 0, 0),
		Palette.Wood,
		M.WoodPlanks
	)
	local book = lectern * CFrame.new(0, 4.25, 0) * CFrame.Angles(math.rad(-20), 0, 0)
	for _, side in { -1, 1 } do
		s:deco(
			"Cover",
			v3(2.1, 0.12, 2.8),
			book * CFrame.new(side * 1.05, -0.08, 0) * CFrame.Angles(0, 0, math.rad(-8 * side)),
			pink:Lerp(Palette.Ink, 0.35),
			M.Fabric
		)
		local page = s:deco(
			"Page",
			v3(1.9, 0.18, 2.6),
			book * CFrame.new(side * 1, 0.05, 0) * CFrame.Angles(0, 0, math.rad(-8 * side)),
			rgb(255, 246, 250),
			M.SmoothPlastic
		)
		page.CastShadow = false
	end
	local glow = s:glow("BookGlow", v3(0.3, 0.2, 2.4), book * CFrame.new(0, 0.12, 0), pink)
	s:light(glow, pink, 12, 1.4)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = pink
	sparkles.Parent = glow
	title(s, "🧠 BRAINROT BOOK", pink, 8.2, 11)
	prompt(desk, "Book", "Open Book", "🧠 BRAINROT BOOK")
end

local function parole(s: Shapes.Shapes)
	local purple = rgb(150, 92, 236)
	local lavender = rgb(214, 186, 255)
	-- The Freedom Gate: an arched portal on stepped half-round platforms, flanked by columns
	for i, step in
		{
			{ size = 15, color = Palette.Frame },
			{ size = 12, color = purple:Lerp(Palette.Ink, 0.35) },
			{ size = 9, color = Palette.Frame },
		}
	do
		s:cyl("GateStep", 0.35, step.size, CFrame.new(0, 0.175 + (i - 1) * 0.35, 3.2), step.color, M.Concrete)
	end
	s:cyl("GateStepTrim", 0.08, 15.2, CFrame.new(0, 0.36, 3.2), Palette.Gold, M.Foil, false)
	local base = 1.05
	for _, x in { -5.4, 5.4 } do
		s:box("GateColumn", v3(1.8, 13, 1.8), CFrame.new(x, base + 6.5, 2.6), Palette.ConcreteWarm, M.Plaster)
		s:box("GateColumnBase", v3(2.4, 1, 2.4), CFrame.new(x, base + 0.5, 2.6), Palette.Frame, M.Concrete)
		s:box("GateColumnCap", v3(2.4, 0.8, 2.4), CFrame.new(x, base + 13.2, 2.6), Palette.Gold, M.Foil)
	end
	s:box("GateLintel", v3(13.2, 1.4, 2), CFrame.new(0, base + 14.3, 2.6), Palette.Frame, M.Concrete)
	-- Arched opening: a charcoal arch backplate with the glowing portal inside it
	local arch = CFrame.new(0, base + 9.5, 3.3) * CFrame.Angles(0, math.pi / 2, 0)
	s:deco("GateArch", v3(0.4, 10, 10), arch, Palette.Frame, M.Concrete).Shape = Enum.PartType.Cylinder
	s:deco("GateArchFill", v3(9.6, 9.5, 0.4), CFrame.new(0, base + 4.75, 3.3), Palette.Frame, M.Concrete)
	local door = s:box("Door", v3(8, 9.2, 0.3), CFrame.new(0, base + 4.6, 2.9), purple, M.Neon)
	door.Transparency = 0.2
	door.CastShadow = false
	local top = s:deco(
		"DoorTop",
		v3(0.3, 8, 8),
		CFrame.new(0, base + 9.2, 2.9) * CFrame.Angles(0, math.pi / 2, 0),
		purple,
		M.Neon
	)
	top.Shape = Enum.PartType.Cylinder
	top.Transparency = 0.2
	top.CastShadow = false
	local swirl = s:deco(
		"Swirl",
		v3(0.2, 5.4, 5.4),
		CFrame.new(0, base + 7, 2.7) * CFrame.Angles(0, math.pi / 2, 0),
		lavender,
		M.Neon
	)
	swirl.Shape = Enum.PartType.Cylinder
	swirl.Transparency = 0.35
	swirl.CastShadow = false
	for i = 0, 5 do
		local angle = i * 1.05
		s:ball(
			"PortalStar",
			0.3,
			v3(math.cos(angle) * 3.2, base + 7 + math.sin(angle) * 3.6, 2.6),
			Palette.White,
			M.Neon,
			false
		).CastShadow =
			false
	end
	s:light(door, purple, 22, 1.6)
	local plaque = s:deco("Plaque", v3(5, 1.1, 0.1), CFrame.new(0, base + 14.3, 1.55), Palette.Gold, M.Foil)
	Build.surfaceText(
		plaque,
		Enum.NormalId.Front,
		"PAROLE BOARD",
		{ textColor = Palette.Ink, strokeColor = Palette.Gold, pixelsPerStud = 40 }
	)
	-- Clerk's desk with the REBIRTH stamp, off to one side
	s:box("Desk", v3(3.4, 3, 2.2), CFrame.new(-8.4, 1.5, -0.6), Palette.WoodDark, M.Wood)
	s:deco("DeskTop", v3(3.7, 0.2, 2.5), CFrame.new(-8.4, 3.1, -0.6), Palette.Wood, M.WoodPlanks)
	s:cyl("StampHandle", 0.9, 0.35, CFrame.new(-7.8, 3.8, -0.6), Palette.WoodDark, M.Wood, false)
	s:deco("Stamp", v3(0.9, 0.3, 0.6), CFrame.new(-7.8, 3.3, -0.6), purple, M.SmoothPlastic)
	title(s, "🔄 REBIRTH", purple, 15.9, 12)
	prompt(door, "Rebirth", "Rebirth", "🔄 REBIRTH")
end

local function luckOMat(s: Shapes.Shapes)
	local green = rgb(58, 196, 88)
	Props.vending(s.parent, s:world(CFrame.new(0, 0, 1.8)), green, "🍀 LUCK-O-MAT")
	-- A four-leaf clover on top
	local center = v3(0, 9.6, 1.8)
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		s:ball("CloverLeaf", 1.3, center + v3(math.cos(angle) * 0.6, math.sin(angle) * 0.6, 0), green, M.Neon, false).CastShadow =
			false
	end
	s:rod(
		"CloverStem",
		center + v3(0, -0.4, 0),
		center + v3(0.3, -1.5, 0),
		0.25,
		green:Lerp(Palette.Ink, 0.3),
		M.SmoothPlastic,
		false
	)
	local hitbox = s:box("Machine", v3(4.4, 7.6, 3), CFrame.new(0, 3.8, 1.8), green, M.SmoothPlastic)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	local glow = s:glow("Glow", v3(0.3, 0.3, 0.3), CFrame.new(0, 9.6, 1.4), green)
	s:light(glow, green, 14, 1.2)
	prompt(hitbox, "FreeBoost", "Claim", "🍀 FREE LUCK")
end

local function carePackage(s: Shapes.Shapes)
	local orange = rgb(255, 160, 40)
	-- Mailroom cubbies
	s:box("Cubbies", v3(10, 7.2, 2), CFrame.new(0, 3.6, 3.2), Palette.Wood, M.WoodPlanks)
	for row = 0, 2 do
		for col = 0, 3 do
			local x, y = -3.6 + col * 2.4, 1.6 + row * 2.2
			s:deco("Cubby", v3(2, 1.8, 0.2), CFrame.new(x, y, 2.15), Palette.WoodDark, M.Wood)
			if (row + col) % 3 == 0 then
				s:deco("Parcel", v3(1.4, 1, 0.8), CFrame.new(x, y - 0.35, 1.9), rgb(200, 160, 110), M.Fabric)
			elseif (row + col) % 3 == 1 then
				s:deco(
					"Letter",
					v3(1.2, 0.8, 0.1),
					CFrame.new(x, y - 0.3, 1.95) * CFrame.Angles(0, 0, math.rad(8)),
					Palette.White
				)
			end
		end
	end
	-- Pallet with a glowing present
	s:box("Pallet", v3(5, 0.6, 4), CFrame.new(0, 0.3, -1.2), Palette.Wood, M.WoodPlanks)
	local gift = s:box("GiftBox", v3(3.6, 3.2, 3.2), CFrame.new(0, 2.2, -1.2), orange, M.SmoothPlastic)
	s:deco("Ribbon", v3(3.7, 3.3, 0.6), CFrame.new(0, 2.2, -1.2), Palette.Gold, M.Foil)
	s:deco("Ribbon", v3(0.6, 3.3, 3.3), CFrame.new(0, 2.2, -1.2), Palette.Gold, M.Foil)
	for _, side in { -1, 1 } do
		s:ball("Bow", 1, v3(side * 0.5, 4.1, -1.2), Palette.Gold, M.Foil, false)
	end
	s:light(gift, orange, 12, 1.2)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Palette.Gold
	sparkles.Parent = gift
	title(s, "🎁 DAILY ROLL", orange, 9.4)
	prompt(gift, "DailyRoll", "Free Roll", "🎁 DAILY ROLL")
end

local BUILDERS: { [string]: (Shapes.Shapes) -> () } = {
	ShopStation = commissary,
	UpgradeStation = workshop,
	BookStation = records,
	RebirthStation = parole,
	FreeLuckStation = luckOMat,
	DailyRollStation = carePackage,
}

function Stations.build(parent: Instance, name: string, cframe: CFrame): Model
	local s = Shapes.model(parent, name, cframe)
	BUILDERS[name](s)
	return s.parent :: Model
end

return Stations
