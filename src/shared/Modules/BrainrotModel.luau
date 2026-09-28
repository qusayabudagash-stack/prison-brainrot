-- Builds a Brainrot character out of plain Roblox parts (no uploaded assets needed).
-- Models face -Z, stand on y = 0 at their pivot, and can be scaled with the `scale` option.
-- Used by the server for cell displays and events, and by the client for viewport cards.

local BrainrotData = require(script.Parent.BrainrotData)

local BrainrotModel = {}

export type Options = {
	variant: string?,
	scale: number?,
	-- Weld every part to an anchored root so the whole model can be moved by moving the root.
	welded: boolean?,
}

type Builder = {
	model: Model,
	look: BrainrotData.Look,
	shape: string,
	size: Vector3,
	center: Vector3,
	color: Color3,
	accent: Color3,
	body: BasePart,
}

local BLACK = Color3.fromRGB(30, 30, 35)
local WHITE = Color3.fromRGB(255, 255, 255)
local SHOE = Color3.fromRGB(45, 45, 55)
local GOLD = Color3.fromRGB(255, 200, 50)
local LEG_HEIGHT = 0.8

local BODIES: { [string]: { size: Vector3, shape: string } } = {
	Egg = { size = Vector3.new(3.4, 4.2, 3.2), shape = "Ellipsoid" },
	Round = { size = Vector3.new(3.8, 3.8, 3.6), shape = "Ellipsoid" },
	Tall = { size = Vector3.new(2.6, 5, 2.6), shape = "Ellipsoid" },
	Wide = { size = Vector3.new(4.6, 3.2, 3.8), shape = "Ellipsoid" },
	Box = { size = Vector3.new(3.4, 3.6, 3), shape = "Box" },
}

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(170, 90, 255),
}

---------------------------------------------------------------------------
-- Part helpers
---------------------------------------------------------------------------

local function newPart(
	b: Builder,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	keepColor: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Anchored = true
	part.Massless = true
	if keepColor then
		part:SetAttribute("KeepColor", true)
	end
	part.Parent = b.model
	return part
end

local function ellipsoid(
	b: Builder,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	keepColor: boolean?
): Part
	local part = newPart(b, name, size, cframe, color, keepColor)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- A cylinder standing upright.
local function cylinder(
	b: Builder,
	name: string,
	height: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	keepColor: boolean?
): Part
	local part = newPart(
		b,
		name,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.pi / 2),
		color,
		keepColor
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A flat disk facing the camera (-Z).
local function disk(
	b: Builder,
	name: string,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	keepColor: boolean?
): Part
	local part = newPart(
		b,
		name,
		Vector3.new(0.12, diameter, diameter),
		cframe * CFrame.Angles(0, math.pi / 2, 0),
		color,
		keepColor
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function neon(part: BasePart): BasePart
	part.Material = Enum.Material.Neon
	return part
end

---------------------------------------------------------------------------
-- Body geometry: positions on the body's surface, relative to its center
---------------------------------------------------------------------------

local function halfSize(b: Builder): Vector3
	return b.size / 2
end

-- z of the front surface at offset (x, y) from the center. Front is -Z.
local function frontZ(b: Builder, x: number, y: number): number
	local h = halfSize(b)
	if b.shape == "Box" then
		return -h.Z
	end
	local t = 1 - (x / h.X) ^ 2 - (y / h.Y) ^ 2
	return -h.Z * math.sqrt(math.max(t, 0))
end

-- y of the top surface at offset (x, z) from the center.
local function topY(b: Builder, x: number, z: number): number
	local h = halfSize(b)
	if b.shape == "Box" then
		return h.Y
	end
	local t = 1 - (x / h.X) ^ 2 - (z / h.Z) ^ 2
	return h.Y * math.sqrt(math.max(t, 0))
end

-- Horizontal half-widths (x, z) of the body at height offset y.
local function widthAt(b: Builder, y: number): (number, number)
	local h = halfSize(b)
	if b.shape == "Box" then
		return h.X, h.Z
	end
	local t = math.sqrt(math.max(1 - (y / h.Y) ^ 2, 0))
	return h.X * t, h.Z * t
end

-- A point on the face; positive `out` pushes it further out of the body.
local function face(b: Builder, x: number, y: number, out: number?): CFrame
	return CFrame.new(b.center + Vector3.new(x, y, frontZ(b, x, y) - (out or 0)))
end

local function onTop(b: Builder, x: number, z: number, up: number?): CFrame
	return CFrame.new(b.center + Vector3.new(x, topY(b, x, z) + (up or 0), z))
end

local function at(b: Builder, x: number, y: number, z: number): CFrame
	return CFrame.new(b.center + Vector3.new(x, y, z))
end

-- A flat band wrapped around the body at height y.
local function ring(b: Builder, name: string, y: number, thickness: number, color: Color3, keepColor: boolean?): Part
	local rx, rz = widthAt(b, y)
	local size = Vector3.new(rx * 2 + 0.14, thickness, rz * 2 + 0.14)
	if b.shape == "Box" then
		return newPart(b, name, size, at(b, 0, y, 0), color, keepColor)
	end
	return ellipsoid(b, name, size, at(b, 0, y, 0), color, keepColor)
end

---------------------------------------------------------------------------
-- Faces
---------------------------------------------------------------------------

local EYES: { [string]: (Builder) -> () } = {}

function EYES.Normal(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(b, "EyeWhite", Vector3.new(0.9, 0.95, 0.5), face(b, side * 0.62, 0.45, -0.1), WHITE, true)
		ellipsoid(b, "Pupil", Vector3.new(0.42, 0.48, 0.3), face(b, side * 0.58, 0.4, 0.14), BLACK, true)
	end
end

function EYES.Big(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(b, "EyeWhite", Vector3.new(1.25, 1.3, 0.6), face(b, side * 0.7, 0.45, -0.1), WHITE, true)
		ellipsoid(b, "Pupil", Vector3.new(0.7, 0.75, 0.35), face(b, side * 0.66, 0.4, 0.18), BLACK, true)
		ellipsoid(b, "Shine", Vector3.new(0.22, 0.22, 0.2), face(b, side * 0.5, 0.6, 0.3), WHITE, true)
	end
end

function EYES.Angry(b: Builder)
	EYES.Normal(b)
	for _, side in { -1, 1 } do
		newPart(
			b,
			"Brow",
			Vector3.new(0.85, 0.2, 0.2),
			face(b, side * 0.62, 1, 0.05) * CFrame.Angles(0, 0, side * math.rad(-22)),
			BLACK,
			true
		)
	end
end

function EYES.Top(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		local x = side * h.X * 0.45
		local base = onTop(b, x, -h.Z * 0.35, -0.2)
		ellipsoid(b, "EyeBump", Vector3.new(1.3, 1.2, 1.3), base, b.color)
		ellipsoid(b, "EyeWhite", Vector3.new(0.95, 0.95, 0.5), base * CFrame.new(0, 0.1, -0.5), WHITE, true)
		ellipsoid(b, "Pupil", Vector3.new(0.45, 0.5, 0.3), base * CFrame.new(0, 0.05, -0.72), BLACK, true)
	end
end

function EYES.Alien(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"AlienEye",
			Vector3.new(1.1, 1.5, 0.5),
			face(b, side * 0.7, 0.45, 0) * CFrame.Angles(0, 0, side * math.rad(-25)),
			BLACK,
			true
		)
		ellipsoid(b, "Shine", Vector3.new(0.25, 0.3, 0.2), face(b, side * 0.55, 0.75, 0.2), WHITE, true)
	end
end

function EYES.Hollow(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(b, "Socket", Vector3.new(1.05, 1.2, 0.5), face(b, side * 0.65, 0.4, 0), BLACK, true)
	end
	ellipsoid(b, "NoseHole", Vector3.new(0.4, 0.5, 0.3), face(b, 0, -0.2, 0), BLACK, true)
end

function EYES.Glow(b: Builder)
	for _, side in { -1, 1 } do
		local eye = neon(
			ellipsoid(
				b,
				"GlowEye",
				Vector3.new(0.8, 0.5, 0.4),
				face(b, side * 0.62, 0.4, 0),
				Color3.fromRGB(190, 120, 255),
				true
			)
		)
		local light = Instance.new("PointLight")
		light.Color = eye.Color
		light.Range = 6
		light.Brightness = 2
		light.Parent = eye
	end
end

local MOUTHS: { [string]: (Builder) -> () } = {}

function MOUTHS.Smile(b: Builder)
	newPart(b, "Mouth", Vector3.new(0.6, 0.18, 0.2), face(b, 0, -0.55, 0.02), BLACK, true)
	for _, side in { -1, 1 } do
		newPart(
			b,
			"MouthCorner",
			Vector3.new(0.35, 0.18, 0.2),
			face(b, side * 0.42, -0.47, 0.02) * CFrame.Angles(0, 0, side * math.rad(30)),
			BLACK,
			true
		)
	end
end

function MOUTHS.Wide(b: Builder)
	newPart(b, "Mouth", Vector3.new(1.6, 0.2, 0.2), face(b, 0, -0.45, 0.02), BLACK, true)
	for _, side in { -1, 1 } do
		newPart(
			b,
			"MouthCorner",
			Vector3.new(0.45, 0.2, 0.2),
			face(b, side * 0.95, -0.33, 0.02) * CFrame.Angles(0, 0, side * math.rad(35)),
			BLACK,
			true
		)
	end
end

function MOUTHS.Teeth(b: Builder)
	newPart(b, "Teeth", Vector3.new(1.5, 0.55, 0.2), face(b, 0, -0.85, 0.02), WHITE, true)
	for i = -1, 1 do
		newPart(b, "ToothGap", Vector3.new(0.06, 0.55, 0.22), face(b, i * 0.38, -0.85, 0.03), BLACK, true)
	end
end

function MOUTHS.None(_b: Builder) end

---------------------------------------------------------------------------
-- Hats
---------------------------------------------------------------------------

local HATS: { [string]: (Builder) -> () } = {}

function HATS.PrisonCap(b: Builder)
	cylinder(b, "Cap", 0.75, 2, onTop(b, 0, 0, 0.2), WHITE, true)
	cylinder(b, "CapStripe", 0.25, 2.05, onTop(b, 0, 0, 0.2), BLACK, true)
end

function HATS.Beanie(b: Builder)
	ellipsoid(b, "Beanie", Vector3.new(2.5, 1.5, 2.5), onTop(b, 0, 0, -0.15), b.accent)
	ellipsoid(b, "Pom", Vector3.new(0.7, 0.7, 0.7), onTop(b, 0, 0, 0.6), WHITE, true)
end

function HATS.Chef(b: Builder)
	cylinder(b, "ChefBand", 0.9, 1.8, onTop(b, 0, 0, 0.3), WHITE, true)
	ellipsoid(b, "ChefPuff", Vector3.new(2.5, 1.3, 2.5), onTop(b, 0, 0, 1.1), WHITE, true)
end

function HATS.Flower(b: Builder)
	local base = onTop(b, 0.4, 0, 0.1)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		ellipsoid(
			b,
			"Petal",
			Vector3.new(0.55, 0.3, 0.55),
			base * CFrame.new(math.cos(angle) * 0.4, 0, math.sin(angle) * 0.4),
			Color3.fromRGB(255, 120, 190),
			true
		)
	end
	ellipsoid(
		b,
		"FlowerCenter",
		Vector3.new(0.4, 0.35, 0.4),
		base * CFrame.new(0, 0.08, 0),
		Color3.fromRGB(255, 225, 60),
		true
	)
end

function HATS.TopHat(b: Builder)
	cylinder(b, "Brim", 0.15, 2.8, onTop(b, 0, 0, 0), BLACK, true)
	cylinder(b, "Hat", 1.8, 1.7, onTop(b, 0, 0, 0.9), BLACK, true)
	cylinder(b, "HatBand", 0.3, 1.75, onTop(b, 0, 0, 0.3), Color3.fromRGB(200, 40, 50), true)
end

function HATS.Antenna(b: Builder)
	for _, side in { -1, 1 } do
		local base = onTop(b, side * 0.5, 0, 0) * CFrame.Angles(0, 0, side * math.rad(-25))
		cylinder(b, "Antenna", 1.5, 0.14, base * CFrame.new(0, 0.7, 0), Color3.fromRGB(90, 90, 100), true)
		neon(ellipsoid(b, "AntennaTip", Vector3.new(0.5, 0.5, 0.5), base * CFrame.new(0, 1.5, 0), b.accent, true))
	end
end

function HATS.Clown(b: Builder)
	local colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 140, 255), Color3.fromRGB(255, 220, 50) }
	for i, x in { -1.1, 0, 1.1 } do
		ellipsoid(b, "ClownHair", Vector3.new(1.3, 1.2, 1.3), onTop(b, x * 0.9, 0.2, -0.3), colors[i], true)
	end
end

function HATS.Pirate(b: Builder)
	ellipsoid(b, "PirateHat", Vector3.new(3.2, 1.1, 1.8), onTop(b, 0, 0, 0.1), BLACK, true)
	ellipsoid(
		b,
		"PirateSkull",
		Vector3.new(0.45, 0.45, 0.2),
		onTop(b, 0, 0, 0.15) * CFrame.new(0, 0, -0.85),
		WHITE,
		true
	)
end

function HATS.Crown(b: Builder)
	local base = onTop(b, 0, 0, 0.1)
	local band = cylinder(b, "Crown", 0.8, 2.1, base, GOLD, true)
	band.Material = Enum.Material.Foil
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		ellipsoid(
			b,
			"CrownPoint",
			Vector3.new(0.4, 0.55, 0.4),
			base * CFrame.new(math.cos(angle) * 0.95, 0.55, math.sin(angle) * 0.95),
			GOLD,
			true
		)
	end
	neon(
		ellipsoid(
			b,
			"CrownGem",
			Vector3.new(0.45, 0.45, 0.25),
			base * CFrame.new(0, 0, -1.05),
			Color3.fromRGB(255, 40, 80),
			true
		)
	)
end

function HATS.Mohawk(b: Builder)
	for i = -2, 1 do
		neon(newPart(b, "Mohawk", Vector3.new(0.3, 1.1, 0.55), onTop(b, 0, i * 0.5 + 0.25, 0.25), b.accent, true))
	end
end

function HATS.WardenHat(b: Builder)
	local navy = Color3.fromRGB(40, 60, 140)
	cylinder(b, "WardenHat", 0.8, 2.3, onTop(b, 0, 0, 0.2), navy, true)
	ellipsoid(b, "WardenTop", Vector3.new(2.6, 0.6, 2.6), onTop(b, 0, 0, 0.6), navy, true)
	ellipsoid(b, "Visor", Vector3.new(1.8, 0.18, 1.1), onTop(b, 0, 0, -0.05) * CFrame.new(0, 0, -1), BLACK, true)
	neon(
		ellipsoid(
			b,
			"HatBadge",
			Vector3.new(0.45, 0.45, 0.2),
			onTop(b, 0, 0, 0.3) * CFrame.new(0, 0, -1.15),
			GOLD,
			true
		)
	)
end

function HATS.GradCap(b: Builder)
	cylinder(b, "CapBase", 0.5, 1.7, onTop(b, 0, 0, 0.1), BLACK, true)
	newPart(
		b,
		"CapBoard",
		Vector3.new(2.8, 0.18, 2.8),
		onTop(b, 0, 0, 0.4) * CFrame.Angles(0, math.rad(45), 0),
		BLACK,
		true
	)
	cylinder(b, "Tassel", 0.9, 0.12, onTop(b, 0, 0, 0.4) * CFrame.new(1.1, -0.45, -1.1), GOLD, true)
	ellipsoid(
		b,
		"TasselEnd",
		Vector3.new(0.3, 0.4, 0.3),
		onTop(b, 0, 0, 0.4) * CFrame.new(1.1, -0.95, -1.1),
		GOLD,
		true
	)
end

function HATS.Halo(b: Builder)
	local base = onTop(b, 0, 0, 1)
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		neon(
			ellipsoid(
				b,
				"Halo",
				Vector3.new(0.35, 0.25, 0.35),
				base * CFrame.new(math.cos(angle) * 1, 0, math.sin(angle) * 1),
				Color3.fromRGB(255, 240, 120),
				true
			)
		)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 240, 150)
	light.Range = 8
	light.Parent = b.body
end

---------------------------------------------------------------------------
-- Extras
---------------------------------------------------------------------------

local EXTRAS: { [string]: (Builder) -> () } = {}

function EXTRAS.Sprout(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Sprout",
			Vector3.new(0.3, 0.9, 0.5),
			onTop(b, side * 0.2, 0.3, 1) * CFrame.Angles(0, 0, side * math.rad(-30)),
			Color3.fromRGB(90, 200, 80),
			true
		)
	end
end

function EXTRAS.Beak(b: Builder)
	ellipsoid(b, "Beak", Vector3.new(0.7, 0.45, 1), face(b, 0, -0.05, 0.3), Color3.fromRGB(255, 160, 40), true)
end

function EXTRAS.DuckBill(b: Builder)
	ellipsoid(b, "Bill", Vector3.new(1.4, 0.35, 1.1), face(b, 0, -0.15, 0.35), Color3.fromRGB(255, 150, 40), true)
end

function EXTRAS.Comb(b: Builder)
	for i = -1, 1 do
		ellipsoid(
			b,
			"Comb",
			Vector3.new(0.45, 0.7, 0.55),
			onTop(b, 0, i * 0.4 - 0.2, 0.15),
			Color3.fromRGB(235, 40, 50),
			true
		)
	end
end

function EXTRAS.Mask(b: Builder)
	ring(b, "Mask", 0.45, 0.6, BLACK, true)
end

function EXTRAS.Wings(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Wing",
			Vector3.new(0.4, 1.7, 1.3),
			at(b, side * (h.X + 0.05), -0.2, 0.2) * CFrame.Angles(0, 0, side * math.rad(20)),
			b.color:Lerp(BLACK, 0.12)
		)
	end
end

function EXTRAS.AngelWings(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"AngelWing",
			Vector3.new(0.35, 2.6, 1.8),
			at(b, side * (h.X * 0.8), 0.6, h.Z * 0.7)
				* CFrame.Angles(math.rad(-15), side * math.rad(35), side * math.rad(-30)),
			WHITE,
			true
		)
	end
end

function EXTRAS.Stem(b: Builder)
	cylinder(
		b,
		"Stem",
		0.7,
		0.35,
		onTop(b, 0, 0, 0.25) * CFrame.Angles(0, 0, math.rad(15)),
		Color3.fromRGB(110, 80, 40),
		true
	)
end

function EXTRAS.Pepperoni(b: Builder)
	for _, spot in { { -0.8, 0.9 }, { 0.9, 0.7 }, { -0.9, -0.6 }, { 0.8, -0.8 }, { 0, -1.1 } } do
		disk(b, "Pepperoni", 0.65, face(b, spot[1], spot[2], 0.02), Color3.fromRGB(210, 50, 45), true)
	end
end

function EXTRAS.Sprinkles(b: Builder)
	for i = 0, 11 do
		local angle = i * math.pi * 2 / 12
		local h = halfSize(b)
		local x, z = math.cos(angle) * h.X * 0.55, math.sin(angle) * h.Z * 0.55
		newPart(
			b,
			"Sprinkle",
			Vector3.new(0.14, 0.14, 0.45),
			onTop(b, x, z, 0) * CFrame.Angles(0, angle * 2.3, 0),
			RAINBOW[i % #RAINBOW + 1],
			true
		)
	end
end

function EXTRAS.Spikes(b: Builder)
	local h = halfSize(b)
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		local y = (i % 3 - 1) * h.Y * 0.4
		local rx, rz = widthAt(b, y)
		ellipsoid(
			b,
			"Spike",
			Vector3.new(0.22, 0.22, 0.22),
			at(b, math.cos(angle) * rx, y, math.sin(angle) * rz),
			Color3.fromRGB(240, 240, 200),
			true
		)
	end
end

function EXTRAS.BigNose(b: Builder)
	ellipsoid(b, "Nose", Vector3.new(0.8, 1.1, 0.8), face(b, 0, -0.05, 0.3), b.color:Lerp(BLACK, 0.15))
end

function EXTRAS.Unibrow(b: Builder)
	newPart(b, "Unibrow", Vector3.new(1.9, 0.28, 0.25), face(b, 0, 1.02, 0.02), BLACK, true)
end

function EXTRAS.PigNose(b: Builder)
	disk(b, "Snout", 1, face(b, 0, -0.05, 0.05), b.color:Lerp(Color3.fromRGB(255, 90, 130), 0.4))
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Nostril",
			Vector3.new(0.18, 0.3, 0.15),
			face(b, side * 0.18, -0.05, 0.12),
			Color3.fromRGB(150, 60, 80),
			true
		)
	end
end

function EXTRAS.PigEars(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Ear",
			Vector3.new(0.9, 1, 0.3),
			onTop(b, side * h.X * 0.55, -0.2, -0.1) * CFrame.Angles(0, 0, side * math.rad(-35)),
			b.color:Lerp(Color3.fromRGB(255, 90, 130), 0.3)
		)
	end
end

function EXTRAS.MoneyBag(b: Builder)
	local h = halfSize(b)
	local base = at(b, h.X + 0.55, -h.Y * 0.45, -0.4)
	ellipsoid(b, "MoneyBag", Vector3.new(1.3, 1.4, 1.3), base, Color3.fromRGB(215, 185, 120), true)
	cylinder(b, "BagTie", 0.25, 0.7, base * CFrame.new(0, 0.7, 0), Color3.fromRGB(80, 170, 70), true)
end

function EXTRAS.Monocle(b: Builder)
	disk(b, "Monocle", 0.95, face(b, 0.62, 0.45, 0.25), GOLD, true)
	disk(b, "MonocleGlass", 0.75, face(b, 0.62, 0.45, 0.3), Color3.fromRGB(200, 240, 255), true)
end

function EXTRAS.Straw(b: Builder)
	cylinder(b, "Straw", 1.8, 0.22, onTop(b, 0.7, 0.3, 0.8) * CFrame.Angles(0, 0, math.rad(-15)), WHITE, true)
end

function EXTRAS.Label(b: Builder)
	local h = halfSize(b)
	newPart(b, "Label", Vector3.new(h.X * 1.5, 1.2, 0.12), face(b, 0, -0.75, 0.05), b.accent)
end

function EXTRAS.Visor(b: Builder)
	local h = halfSize(b)
	neon(
		newPart(
			b,
			"Visor",
			Vector3.new(h.X * 1.6, 0.6, 0.2),
			face(b, 0, 0.45, 0.15),
			Color3.fromRGB(80, 230, 255),
			true
		)
	)
end

function EXTRAS.Holes(b: Builder)
	for _, spot in { { -0.9, 0.8 }, { 0.8, 0.4 }, { -0.4, -0.9 }, { 1, -0.9 } } do
		disk(b, "Hole", 0.6, face(b, spot[1], spot[2], 0.01), b.accent)
	end
end

function EXTRAS.Glow(b: Builder)
	local light = Instance.new("PointLight")
	light.Color = b.color
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = b.body
end

function EXTRAS.Sunglasses(b: Builder)
	for _, side in { -1, 1 } do
		newPart(b, "Shades", Vector3.new(0.95, 0.6, 0.18), face(b, side * 0.6, 0.45, 0.28), BLACK, true)
	end
	newPart(b, "ShadesBridge", Vector3.new(0.5, 0.14, 0.15), face(b, 0, 0.55, 0.3), BLACK, true)
end

function EXTRAS.Glasses(b: Builder)
	for _, side in { -1, 1 } do
		newPart(b, "GlassesFrame", Vector3.new(0.95, 0.75, 0.12), face(b, side * 0.6, 0.45, 0.28), BLACK, true)
		local glass = newPart(
			b,
			"GlassesLens",
			Vector3.new(0.75, 0.55, 0.14),
			face(b, side * 0.6, 0.45, 0.3),
			Color3.fromRGB(200, 240, 255),
			true
		)
		glass.Transparency = 0.35
	end
	newPart(b, "GlassesBridge", Vector3.new(0.45, 0.12, 0.12), face(b, 0, 0.55, 0.3), BLACK, true)
end

function EXTRAS.EyePatch(b: Builder)
	ellipsoid(b, "EyePatch", Vector3.new(0.95, 0.95, 0.25), face(b, -0.62, 0.45, 0.25), BLACK, true)
	ring(b, "PatchStrap", 0.7, 0.14, BLACK, true)
end

function EXTRAS.Gem(b: Builder)
	neon(ellipsoid(b, "Gem", Vector3.new(0.6, 0.6, 0.35), face(b, 0, 1.05, 0.1), Color3.fromRGB(255, 70, 150), true))
end

function EXTRAS.Sparkles(b: Builder)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = b.color:Lerp(WHITE, 0.5)
	sparkles.Parent = b.body
end

function EXTRAS.ClownNose(b: Builder)
	neon(
		ellipsoid(
			b,
			"ClownNose",
			Vector3.new(0.75, 0.75, 0.75),
			face(b, 0, -0.05, 0.2),
			Color3.fromRGB(255, 40, 40),
			true
		)
	)
end

function EXTRAS.Bowtie(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Bowtie",
			Vector3.new(0.8, 0.6, 0.3),
			face(b, side * 0.4, -h.Y * 0.62, 0.15),
			Color3.fromRGB(255, 60, 150),
			true
		)
	end
end

function EXTRAS.NinjaBand(b: Builder)
	ring(b, "NinjaBand", 1, 0.45, BLACK, true)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		newPart(
			b,
			"BandTail",
			Vector3.new(0.3, 0.2, 1.4),
			at(b, side * 0.3, 0.9, h.Z + 0.5) * CFrame.Angles(math.rad(-25), side * math.rad(20), 0),
			BLACK,
			true
		)
	end
end

function EXTRAS.Noodles(b: Builder)
	for i = -2, 2 do
		newPart(
			b,
			"Noodle",
			Vector3.new(0.15, 1.2, 0.15),
			onTop(b, i * 0.35, -0.2, 0.3) * CFrame.Angles(0, 0, math.rad(i * 18)),
			Color3.fromRGB(255, 225, 120),
			true
		)
	end
end

function EXTRAS.Cape(b: Builder)
	local h = halfSize(b)
	newPart(
		b,
		"Cape",
		Vector3.new(h.X * 1.9, b.size.Y * 0.95, 0.15),
		at(b, 0, -0.3, h.Z + 0.1) * CFrame.Angles(math.rad(8), 0, 0),
		Color3.fromRGB(200, 30, 50),
		true
	)
end

function EXTRAS.Fire(b: Builder)
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Color = Color3.fromRGB(255, 140, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fire.Parent = b.body
end

function EXTRAS.Smoke(b: Builder)
	local smoke = Instance.new("Smoke")
	smoke.Size = 3
	smoke.Opacity = 0.15
	smoke.RiseVelocity = 3
	smoke.Color = Color3.fromRGB(120, 120, 120)
	smoke.Parent = b.body
end

function EXTRAS.Bolts(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		for i = 0, 2 do
			neon(
				newPart(
					b,
					"Bolt",
					Vector3.new(0.25, 0.8, 0.25),
					at(b, side * (h.X + 0.25 + (i % 2) * 0.25), 0.9 - i * 0.65, 0)
						* CFrame.Angles(0, 0, side * math.rad(i % 2 == 0 and 30 or -30)),
					b.accent,
					true
				)
			)
		end
	end
end

function EXTRAS.Mustache(b: Builder)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Mustache",
			Vector3.new(0.85, 0.35, 0.3),
			face(b, side * 0.38, -0.2, 0.12) * CFrame.Angles(0, 0, side * math.rad(-15)),
			Color3.fromRGB(90, 55, 30),
			true
		)
	end
end

function EXTRAS.Badge(b: Builder)
	local h = halfSize(b)
	neon(disk(b, "Badge", 0.6, face(b, -0.7, -h.Y * 0.45, 0.05), GOLD, true))
end

function EXTRAS.Horns(b: Builder)
	local h = halfSize(b)
	for _, side in { -1, 1 } do
		ellipsoid(
			b,
			"Horn",
			Vector3.new(0.45, 1.3, 0.45),
			onTop(b, side * h.X * 0.4, 0, 0.3) * CFrame.Angles(0, 0, side * math.rad(-25)),
			Color3.fromRGB(250, 240, 210),
			true
		)
	end
end

function EXTRAS.Tail(b: Builder)
	local h = halfSize(b)
	ellipsoid(
		b,
		"Tail",
		Vector3.new(0.7, 0.7, 2.2),
		at(b, 0, -h.Y * 0.5, h.Z + 0.6) * CFrame.Angles(math.rad(20), 0, 0),
		b.color:Lerp(BLACK, 0.1)
	)
end

function EXTRAS.Stars(b: Builder)
	for i = 0, 7 do
		local angle = i * math.pi * 2 / 8
		local y = math.sin(i * 1.7) * halfSize(b).Y * 0.6
		local rx, rz = widthAt(b, y)
		neon(
			ellipsoid(
				b,
				"Star",
				Vector3.new(0.28, 0.28, 0.28),
				at(b, math.cos(angle) * rx, y, math.sin(angle) * rz),
				Color3.fromRGB(255, 250, 200),
				true
			)
		)
	end
end

function EXTRAS.GoldChain(b: Builder)
	local h = halfSize(b)
	ring(b, "GoldChain", -h.Y * 0.5, 0.2, GOLD, true).Material = Enum.Material.Foil
	neon(disk(b, "Medallion", 0.7, face(b, 0, -h.Y * 0.62, 0.1), GOLD, true))
end

function EXTRAS.BrainBumps(b: Builder)
	local h = halfSize(b)
	local dark = b.color:Lerp(Color3.fromRGB(200, 60, 110), 0.35)
	for i = 0, 6 do
		local angle = i * math.pi * 2 / 7
		ellipsoid(
			b,
			"BrainBump",
			Vector3.new(1.1, 0.7, 1.1),
			onTop(b, math.cos(angle) * h.X * 0.45, math.sin(angle) * h.Z * 0.45, -0.25),
			if i % 2 == 0 then dark else b.color
		)
	end
	ellipsoid(b, "BrainBump", Vector3.new(1.2, 0.8, 1.2), onTop(b, 0, 0, -0.2), dark)
end

function EXTRAS.Lava(b: Builder)
	local h = halfSize(b)
	local orange = Color3.fromRGB(255, 120, 30)
	neon(ellipsoid(b, "Lava", Vector3.new(h.X * 1.3, 0.7, h.Z * 1.3), onTop(b, 0, 0, -0.2), orange, true))
	for i = 0, 3 do
		local angle = i * math.pi / 2 + 0.4
		local y = h.Y * 0.55
		local rx, rz = widthAt(b, y)
		neon(
			ellipsoid(
				b,
				"LavaDrip",
				Vector3.new(0.35, 0.8, 0.35),
				at(b, math.cos(angle) * rx, y, math.sin(angle) * rz),
				orange,
				true
			)
		)
	end
end

function EXTRAS.Halo(b: Builder)
	local base = onTop(b, 0, 0, 1.8)
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		neon(
			ellipsoid(
				b,
				"Halo",
				Vector3.new(0.35, 0.25, 0.35),
				base * CFrame.new(math.cos(angle) * 1.1, 0, math.sin(angle) * 1.1),
				Color3.fromRGB(255, 240, 120),
				true
			)
		)
	end
end

function EXTRAS.Rainbow(b: Builder)
	local h = halfSize(b)
	for i, color in RAINBOW do
		local y = h.Y * 0.75 - (i - 1) * (h.Y * 1.5 / (#RAINBOW - 1))
		ring(b, "RainbowStripe", y, 0.4, color, true)
	end
end

function EXTRAS.RainbowAura(b: Builder)
	local emitter = Instance.new("ParticleEmitter")
	local keys = {}
	for i, color in RAINBOW do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#RAINBOW - 1), color))
	end
	emitter.Color = ColorSequence.new(keys)
	emitter.LightEmission = 1
	emitter.Rate = 25
	emitter.Lifetime = NumberRange.new(1, 1.6)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.4, 0)
	emitter.Parent = b.body
end

function EXTRAS.QuestionMarks(b: Builder)
	for i = 0, 2 do
		local angle = i * math.pi * 2 / 3
		neon(
			ellipsoid(
				b,
				"Mystery",
				Vector3.new(0.5, 0.5, 0.5),
				onTop(b, 0, 0, 1.2) * CFrame.new(math.cos(angle) * 1.4, i * 0.3, math.sin(angle) * 1.4),
				Color3.fromRGB(190, 120, 255),
				true
			)
		)
	end
end

---------------------------------------------------------------------------
-- Variants
---------------------------------------------------------------------------

local function addVariantEffects(model: Model, body: BasePart, variantId: string)
	if variantId == "Normal" then
		return
	end
	local isGolden = variantId == "Golden"
	local color = if isGolden then GOLD else Color3.fromRGB(150, 240, 255)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 and not descendant:GetAttribute("KeepColor") then
			descendant.Color = if isGolden
				then descendant.Color:Lerp(color, 0.85)
				else descendant.Color:Lerp(color, 0.8)
			descendant.Material = if isGolden then Enum.Material.Foil else Enum.Material.Glass
			if not isGolden then
				descendant.Transparency = 0.12
			end
		end
	end

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 2
	light.Parent = body

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "VariantSparkle"
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	emitter.LightEmission = 1
	emitter.Rate = if isGolden then 8 else 16
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(if isGolden then 0.35 else 0.5, 0)
	emitter.Parent = body
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

function BrainrotModel.build(brainrotId: string, options: Options?): Model
	local brainrot = BrainrotData.ById[brainrotId]
	assert(brainrot, `Unknown Brainrot {brainrotId}`)
	local opts: Options = options or {}
	local look = brainrot.look
	local bodyInfo = BODIES[look.body] or BODIES.Round

	local model = Instance.new("Model")
	model.Name = brainrot.id

	local b: Builder = {
		model = model,
		look = look,
		shape = bodyInfo.shape,
		size = bodyInfo.size,
		center = Vector3.new(0, LEG_HEIGHT + bodyInfo.size.Y / 2 - 0.2, 0),
		color = look.color,
		accent = look.accent or BLACK,
		body = nil :: any,
	}

	-- Root: invisible, at the feet, holds the model's pivot.
	local root = newPart(b, "Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), WHITE, true)
	root.Transparency = 1
	root.PivotOffset = CFrame.new(0, -0.5, 0)
	model.PrimaryPart = root

	-- Body
	local body
	if b.shape == "Box" then
		body = newPart(b, "Body", b.size, CFrame.new(b.center), b.color)
	else
		body = ellipsoid(b, "Body", b.size, CFrame.new(b.center), b.color)
	end
	body.Material = look.material or Enum.Material.SmoothPlastic
	b.body = body

	-- Legs, shoes and hands
	for _, side in { -1, 1 } do
		cylinder(b, "Leg", LEG_HEIGHT + 0.2, 0.55, CFrame.new(side * 0.7, (LEG_HEIGHT + 0.2) / 2, 0), SHOE, true)
		ellipsoid(b, "Shoe", Vector3.new(0.9, 0.45, 1.2), CFrame.new(side * 0.7, 0.22, -0.2), SHOE, true)
		local rx = widthAt(b, -0.3)
		ellipsoid(
			b,
			"Hand",
			Vector3.new(0.75, 0.75, 0.75),
			at(b, side * (rx + 0.15), -0.3, -0.2),
			b.color:Lerp(BLACK, 0.1)
		)
	end

	if look.stripes then
		local h = halfSize(b)
		for i = 1, 2 do
			ring(b, "Stripe", -h.Y * (0.18 + i * 0.22), 0.3, b.accent, true)
		end
	end

	local eyes = EYES[look.eyes or "Normal"] or EYES.Normal
	eyes(b)
	local mouth = MOUTHS[look.mouth or "Smile"] or MOUTHS.Smile
	mouth(b)
	if look.hat and HATS[look.hat] then
		HATS[look.hat](b)
	end
	local extras: { string } = look.extras or {}
	for _, extra in extras do
		local builder = EXTRAS[extra]
		if builder then
			builder(b)
		end
	end

	addVariantEffects(model, body, opts.variant or "Normal")

	if opts.welded then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant ~= root then
				descendant.Anchored = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end

	if opts.scale and opts.scale ~= 1 then
		model:ScaleTo(opts.scale)
	end

	return model
end

-- Height of an unscaled model, for placing labels above it.
function BrainrotModel.height(brainrotId: string): number
	local brainrot = BrainrotData.ById[brainrotId]
	local bodyInfo = BODIES[brainrot.look.body] or BODIES.Round
	return LEG_HEIGHT + bodyInfo.size.Y + 1
end

return BrainrotModel
