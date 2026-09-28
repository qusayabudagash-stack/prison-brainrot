-- COMMON Brainrots: small, simple and cute. One strong idea each, readable from across the room.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Common: { [string]: (Kit) -> BasePart } = {}

local PINK = rgb(255, 160, 178)

-- Whiskers fanning out from both sides of a snout.
local function whiskers(k: Kit, from: Vector3, spread: number, color: Color3)
	for _, side in { -1, 1 } do
		for i = -1, 1 do
			local root = from + v3(side * 0.18, i * 0.07, 0)
			k:limb("Whisker", root, root + v3(side * spread, i * 0.14, 0.12), 0.035, color, nil, "Body")
		end
	end
end

---------------------------------------------------------------------------
-- Tim Cheese: a mouse in a wedge of cheese
---------------------------------------------------------------------------

Common.TimCheese = function(k: Kit): BasePart
	local CHEESE = rgb(255, 206, 72)
	local HOLE = rgb(226, 160, 36)
	local RIND = rgb(238, 146, 42)
	local MOUSE = rgb(168, 168, 186)
	local MOUSE_LIGHT = rgb(222, 222, 232)

	-- The cheese: two mirrored wedges make a slice standing on its rind, point up
	local bottom, height, half, thick = 0.5, 2.3, 1.3, 1.3
	local body: BasePart? = nil
	for _, side in { -1, 1 } do
		local wedge = k:part(
			"Cheese",
			v3(thick, height, half),
			CFrame.fromMatrix(v3(side * half / 2, bottom + height / 2, 0), v3(0, 0, side), Vector3.yAxis),
			CHEESE,
			nil,
			"Body"
		)
		wedge.Shape = Enum.PartType.Wedge
		body = body or wedge
	end
	k:part("Rind", v3(half * 2 + 0.06, 0.2, thick + 0.06), CFrame.new(0, bottom + 0.1, 0), RIND, nil, "Body")
	for _, side in { -1, 1 } do
		-- holes on the sloped sides too, so the slice reads as cheese from any angle
		local slope = CFrame.fromMatrix(v3(side * 0.62, 1.55, 0), v3(0, 0, side), Vector3.yAxis)
		local normal = (slope * CFrame.Angles(math.atan2(half, height), 0, 0)).UpVector
		k:disc(
			"CheeseHole",
			0.42,
			0.06,
			CFrame.lookAt(v3(side * 0.62, 1.55, 0.22) + normal * 0.02, v3(side * 0.62, 1.55, 0.22) + normal * 1.02),
			HOLE,
			nil,
			"Body"
		)
	end
	for _, hole in { { -0.52, 1.0, 0.5 }, { 0.42, 0.85, 0.36 }, { 0.05, 1.75, 0.34 }, { 0.72, 0.62, 0.2 } } do
		k:disc(
			"CheeseHole",
			hole[3],
			0.06,
			CFrame.new(hole[1], hole[2], -thick / 2 - 0.02) * CFrame.Angles(0, math.pi, 0),
			HOLE,
			nil,
			"Body"
		)
	end

	-- Mouse head on top
	local head: Kit.Shell = { center = v3(0, 3.18, -0.05), radii = v3(0.8, 0.72, 0.74) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), MOUSE, nil, "Body")
	k:ellipsoid("Snout", v3(0.82, 0.56, 0.62), CFrame.new(0, 2.98, -0.58), MOUSE_LIGHT, nil, "Body")
	k:ball("Nose", 0.26, v3(0, 3.06, -0.9), PINK, nil, "Body")
	k:eyes(head, 27, 16, { width = 0.36, height = 0.44, iris = rgb(40, 30, 45) }, "Body")
	k:mouth(
		CFrame.new(0, 2.84, -0.86),
		{ width = 0.36, height = 0.14, skin = MOUSE_LIGHT, style = "Smile", radius = 0.4 },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:part("BuckTooth", v3(0.1, 0.15, 0.05), CFrame.new(side * 0.055, 2.72, -0.86), C.White, nil, "Body")
		local ear = CFrame.new(side * 0.62, 3.78, 0.05) * CFrame.Angles(0, math.rad(side * 18), math.rad(side * -12))
		k:disc("Ear", 0.95, 0.12, ear, MOUSE, nil, "Body")
		k:disc("EarInner", 0.66, 0.06, ear * CFrame.new(0, 0, -0.07), PINK, nil, "Body")
		k:blush(Kit.on(head, side * 44, -8, 0.02), 0.26, "Body")
	end
	whiskers(k, v3(0, 3.0, -0.78), 0.7, rgb(80, 80, 95))

	-- Arms out of the cheese, feet below, tail curling behind
	for _, arm in
		{
			{ rig = "ArmL", shoulder = v3(-0.58, 1.65, 0), hand = v3(-1.22, 1.18, -0.3) },
			{ rig = "ArmR", shoulder = v3(0.58, 1.65, 0), hand = v3(1.2, 2.2, -0.24) },
		}
	do
		local rig, shoulder, hand = arm.rig, arm.shoulder, arm.hand
		k:limb("Arm", shoulder, hand, 0.32, MOUSE, nil, rig)
		k:ball("Hand", 0.42, hand, PINK, nil, rig)
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.45, 0.62, 0), v3(side * 0.5, 0.22, 0), 0.3, MOUSE, nil, "Legs")
		k:ellipsoid("Foot", v3(0.52, 0.24, 0.82), CFrame.new(side * 0.52, 0.12, -0.2), PINK, nil, "Legs")
	end
	Parts.tube(
		k,
		"Tail",
		{ v3(0, 0.75, 0.6), v3(0.55, 0.45, 1.25), v3(1.15, 0.95, 1.45), v3(1.3, 1.8, 1.2) },
		{ 0.08, 0.07, 0.06, 0.04 },
		PINK,
		nil,
		"Body",
		{ density = 2.5, overlap = 4 }
	)
	return body :: BasePart
end

---------------------------------------------------------------------------
-- Lirilì Larilà: an elephant who is also a cactus, in sandals
---------------------------------------------------------------------------

Common.LiriliLarila = function(k: Kit): BasePart
	local CACTUS = rgb(92, 172, 92)
	local GROOVE = rgb(58, 128, 66)
	local ELEPHANT = rgb(164, 168, 186)
	local EAR = rgb(236, 172, 182)
	local SPINE = rgb(252, 246, 222)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.42, 1.0, 0), v3(side * 0.45, 0.28, 0), 0.54, ELEPHANT, nil, "Legs")
		Parts.sandal(k, v3(side * 0.45, 0, 0), 0.82, rgb(160, 104, 60), rgb(112, 70, 40), "Legs", side * 6)
	end

	-- The cactus: a ribbed column with two arms, spines and a flower
	local trunk: Kit.Shell = { center = v3(0, 1.95, 0), radii = v3(0.76, 1.18, 0.7) }
	local body = k:ellipsoid("Cactus", trunk.radii * 2, CFrame.new(trunk.center), CACTUS, nil, "Body")
	for _, yaw in { -150, -90, -30, 30, 90, 150 } do
		Parts.patch(k, "Groove", trunk, yaw, -4, 0.09, 1.95, GROOVE, nil, "Body")
	end
	for i = 1, 14 do
		local yaw = ((i * 137.5) % 360) - 180
		local pitch = -40 + (i * 53 % 70)
		k:ball("Spine", 0.1, (Kit.surface(trunk, yaw, pitch)), SPINE, nil, "Body")
	end
	Parts.tube(
		k,
		"CactusArm",
		{ v3(-0.55, 1.85, 0), v3(-1.1, 1.9, 0), v3(-1.25, 2.45, 0), v3(-1.22, 2.95, 0) },
		{ 0.24, 0.23, 0.22, 0.2 },
		CACTUS,
		nil,
		"ArmL",
		{ density = 1.4, overlap = 4 }
	)
	k.model:SetAttribute("ArmLJoint", v3(-0.55, 1.85, 0))
	Parts.tube(
		k,
		"CactusArm",
		{ v3(0.55, 1.5, 0), v3(1.05, 1.55, 0), v3(1.18, 2.05, 0), v3(1.16, 2.35, 0) },
		{ 0.22, 0.21, 0.2, 0.18 },
		CACTUS,
		nil,
		"ArmR",
		{ density = 1.4, overlap = 4 }
	)
	k.model:SetAttribute("ArmRJoint", v3(0.55, 1.5, 0))
	local flower = v3(-1.22, 3.12, 0)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		k:ellipsoid(
			"Petal",
			v3(0.2, 0.08, 0.3),
			CFrame.new(flower) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -0.14),
			rgb(255, 120, 170),
			nil,
			"ArmL"
		)
	end
	k:ball("FlowerHeart", 0.14, flower + v3(0, 0.04, 0), rgb(255, 214, 70), nil, "ArmL")

	-- Elephant head with big ears, a curled trunk and little tusks
	local head: Kit.Shell = { center = v3(0, 3.5, -0.05), radii = v3(0.84, 0.8, 0.8) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), ELEPHANT, nil, "Body")
	for _, side in { -1, 1 } do
		local ear = CFrame.new(side * 0.95, 3.55, 0.12) * CFrame.Angles(0, math.rad(side * -22), 0)
		k:ellipsoid("Ear", v3(1.25, 1.45, 0.16), ear, ELEPHANT, nil, "Body")
		k:ellipsoid("EarInner", v3(0.95, 1.12, 0.1), ear * CFrame.new(side * 0.02, -0.02, -0.07), EAR, nil, "Body")
		Parts.cone(k, "Tusk", v3(side * 0.3, 3.1, -0.62), v3(side * 0.42, 2.86, -1.02), 0.09, C.White, nil, "Body")
		k:blush(Kit.on(head, side * 42, -10, 0.02), 0.26, "Body")
	end
	k:eyes(head, 28, 14, { width = 0.34, height = 0.42, iris = rgb(45, 35, 40) }, "Body")
	Parts.tube(
		k,
		"Trunk",
		{ v3(0, 3.3, -0.72), v3(0, 2.9, -1.0), v3(0, 2.55, -0.98), v3(0, 2.48, -1.25), v3(0, 2.62, -1.42) },
		{ 0.3, 0.22, 0.18, 0.16, 0.15 },
		ELEPHANT,
		nil,
		"Body",
		{ density = 1.2, overlap = 4 }
	)
	return body
end

---------------------------------------------------------------------------
-- Trippi Troppi: a shrimp with a cat's face
---------------------------------------------------------------------------

Common.TrippiTroppi = function(k: Kit): BasePart
	local SHRIMP = rgb(250, 128, 96)
	local SHELL = rgb(232, 96, 78)
	local CAT = rgb(247, 176, 92)
	local STRIPE = rgb(214, 128, 58)

	-- The shrimp: a C-shaped body curling down and forward into a fan tail
	local spine = {
		v3(0, 2.5, 0),
		v3(-0.42, 2.02, 0.12),
		v3(-0.62, 1.4, 0.16),
		v3(-0.42, 0.82, 0.08),
		v3(0.12, 0.6, 0),
		v3(0.66, 0.72, -0.05),
	}
	local radii = { 0.7, 0.72, 0.64, 0.5, 0.38, 0.26 }
	local body = Parts.tube(k, "Shrimp", spine, radii, SHRIMP, nil, "Body", { density = 1, overlap = 5 })
	-- A paler underside along the inside of the curl
	local inside: { Vector3 } = {}
	local insideRadii: { number } = {}
	for i, point in spine do
		table.insert(inside, point + (v3(0.1, 1.45, -0.05) - point).Unit * radii[i] * 0.24)
		table.insert(insideRadii, radii[i] * 0.84)
	end
	Parts.tube(k, "ShrimpBelly", inside, insideRadii, rgb(255, 204, 176), nil, "Body", { density = 1.4, overlap = 5 })
	local tail = spine[6]
	for _, tip in { v3(1.32, 1.05, -0.05), v3(1.42, 0.62, -0.05), v3(1.28, 0.25, -0.05) } do
		local length = (tip - tail).Magnitude
		k:ellipsoid(
			"TailFan",
			v3(0.44, length * 1.25, 0.1),
			CFrame.fromMatrix((tail + tip) / 2, (tip - tail).Unit:Cross(Vector3.zAxis), (tip - tail).Unit),
			SHELL,
			nil,
			"Body"
		)
	end
	for i = 0, 2 do
		local root = spine[3 + i]
		local inward = (v3(0, 1.3, 0) - root).Unit
		k:limb(
			"ShrimpLeg",
			root + inward * radii[3 + i] * 0.8,
			root + inward * (radii[3 + i] + 0.35) + v3(0, -0.12, -0.25),
			0.08,
			SHELL,
			nil,
			"Body"
		)
	end

	-- Cat head
	local head: Kit.Shell = { center = v3(0, 3.2, -0.32), radii = v3(0.82, 0.72, 0.72) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CAT, nil, "Body")
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.44, 3.72, -0.3),
			v3(side * 0.66, 4.3, -0.26),
			0.56,
			0.16,
			CAT,
			-Vector3.zAxis,
			nil,
			"Body"
		)
		Parts.leaf(
			k,
			"EarInner",
			v3(side * 0.45, 3.76, -0.4),
			v3(side * 0.62, 4.16, -0.36),
			0.34,
			0.06,
			PINK,
			-Vector3.zAxis,
			nil,
			"Body"
		)
		k:blush(Kit.on(head, side * 40, -12, 0.02), 0.24, "Body")
	end
	for _, yaw in { -22, 0, 22 } do
		Parts.patch(k, "CatStripe", head, yaw, 58, 0.14, 0.4, STRIPE, nil, "Body")
	end
	k:eyes(head, 27, 10, { width = 0.4, height = 0.5, iris = rgb(96, 190, 90) }, "Body")
	k:ellipsoid("Nose", v3(0.18, 0.12, 0.1), Kit.on(head, 0, -8, 0.02), PINK, nil, "Body")
	k:mouth(
		Kit.on(head, 0, -20, 0),
		{ width = 0.34, height = 0.14, skin = CAT, style = "Smile", radius = 0.72 },
		"Body"
	)
	whiskers(k, v3(0, 3.02, -0.98), 0.62, C.White)
	Parts.bareArm(k, "ArmL", v3(-0.5, 2.3, -0.55), v3(-0.72, 1.85, -1.02), 0.2, CAT, 0.28)
	Parts.bareArm(k, "ArmR", v3(0.5, 2.3, -0.55), v3(0.74, 2.0, -1.05), 0.2, CAT, 0.28)
	for _, side in { -1, 1 } do
		Parts.tube(
			k,
			"Antenna",
			{ v3(side * 0.2, 3.85, -0.62), v3(side * 0.45, 4.55, -0.95), v3(side * 0.85, 4.85, -0.3) },
			{ 0.045, 0.035, 0.025 },
			SHELL,
			nil,
			"Body",
			{ density = 3, overlap = 4, maxSteps = 2 }
		)
	end
	return body[2]
end

---------------------------------------------------------------------------
-- Svinino Bombondino: a pig who is also a bomb
---------------------------------------------------------------------------

Common.SvininoBombondino = function(k: Kit): BasePart
	local PIG = rgb(255, 168, 188)
	local PIG_DARK = rgb(236, 120, 150)
	local METAL = rgb(92, 96, 112)

	for _, x in { -0.62, 0.62 } do
		for _, z in { -0.45, 0.5 } do
			k:limb("Leg", v3(x, 0.8, z), v3(x * 1.05, 0.22, z), 0.36, PIG, nil, "Legs")
			k:oval("Hoof", CFrame.new(x * 1.05, 0.1, z), 0.38, 0.38, 0.2, rgb(90, 60, 70), nil, "Legs")
		end
	end
	local shell: Kit.Shell = { center = v3(0, 1.7, 0), radii = v3(1.25, 1.2, 1.25) }
	local body = k:ellipsoid("Bomb", shell.radii * 2, CFrame.new(shell.center), PIG, nil, "Body")

	-- Fuse cap and a lit fuse on top
	k:oval("FuseCap", CFrame.new(0, 2.88, 0.1), 0.72, 0.72, 0.28, METAL, Enum.Material.Metal, "Body")
	Parts.tube(
		k,
		"Fuse",
		{ v3(0, 3.0, 0.1), v3(0.12, 3.32, 0.2), v3(0.34, 3.48, 0.12) },
		{ 0.06, 0.055, 0.05 },
		rgb(150, 110, 70),
		Enum.Material.Fabric,
		"Body",
		{ density = 3 }
	)
	k:ball("Spark", 0.22, v3(0.38, 3.52, 0.1), rgb(255, 220, 90), Enum.Material.Neon, "Body")
	for i = 0, 1 do
		k:ellipsoid(
			"Spark",
			v3(0.5, 0.08, 0.08),
			CFrame.new(0.38, 3.52, 0.1) * CFrame.Angles(0, 0, math.rad(45 + i * 90)),
			rgb(255, 150, 50),
			Enum.Material.Neon,
			"Body"
		)
	end

	-- A riveted casing band round the middle, like a real bomb
	k:band("Casing", shell, 1.08, 0.3, METAL, Enum.Material.Metal, "Body")
	for i = 0, 7 do
		local yaw = -157.5 + i * 45
		k:ball("Rivet", 0.12, (Kit.surface(shell, yaw, -31)), rgb(150, 155, 170), Enum.Material.Metal, "Body")
	end

	-- Bomb tail fins at the back
	k:cylinder(
		"FinHub",
		0.8,
		0.62,
		CFrame.new(0, 1.7, 1.45) * CFrame.Angles(math.pi / 2, 0, 0),
		METAL,
		Enum.Material.Metal,
		"Body"
	)
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		local out = v3(math.cos(angle), math.sin(angle), 0)
		Parts.leaf(
			k,
			"TailFin",
			v3(0, 1.7, 1.15) + out * 0.2,
			v3(0, 1.7, 2.0) + out * 1.05,
			0.62,
			0.06,
			METAL,
			out:Cross(Vector3.zAxis),
			Enum.Material.Metal,
			"Body"
		)
	end

	-- Pig face
	k:eyes(shell, 24, 20, { width = 0.36, height = 0.44, iris = rgb(45, 30, 40) }, "Body")
	local snout = Kit.on(shell, 0, -2, 0.04)
	k:ellipsoid("Snout", v3(0.8, 0.58, 0.32), snout, PIG_DARK, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Nostril",
			v3(0.14, 0.2, 0.08),
			snout * CFrame.new(side * 0.16, 0, -0.14),
			rgb(120, 50, 70),
			nil,
			"Body"
		)
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.62, 2.62, -0.35),
			v3(side * 1.02, 3.02, -0.62),
			0.56,
			0.12,
			PIG_DARK,
			v3(side * 0.3, 0.5, -1).Unit,
			nil,
			"Body"
		)
		k:blush(Kit.on(shell, side * 38, -10, 0.02), 0.34, "Body")
	end
	k:mouth(
		Kit.on(shell, 0, -22, 0),
		{ width = 0.46, height = 0.18, skin = PIG, style = "Smile", radius = 1.2 },
		"Body"
	)
	return body
end

---------------------------------------------------------------------------
-- Talpa di Ferro: an iron mole with drill hands
---------------------------------------------------------------------------

Common.TalpaDiFerro = function(k: Kit): BasePart
	local FUR = rgb(104, 86, 104)
	local FUR_LIGHT = rgb(150, 128, 146)
	local IRON = rgb(128, 134, 146)
	local BRASS = rgb(214, 164, 72)
	local HELMET = rgb(255, 196, 52)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.5, 0.7, 0), v3(side * 0.55, 0.24, 0), 0.4, FUR, nil, "Legs")
		k:ellipsoid("Foot", v3(0.6, 0.26, 0.86), CFrame.new(side * 0.58, 0.13, -0.18), PINK, nil, "Legs")
	end
	local shell: Kit.Shell = { center = v3(0, 1.62, 0), radii = v3(1.0, 1.15, 0.92) }
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), FUR, Enum.Material.Fabric, "Body")
	Parts.patch(k, "Belly", shell, 0, -14, 1.1, 1.3, FUR_LIGHT, Enum.Material.Fabric, "Body")
	-- Iron chest plate with rivets
	local plate = Kit.on(shell, 0, 12, 0.02)
	k:ellipsoid("ChestPlate", v3(0.95, 0.72, 0.16), plate, IRON, Enum.Material.Metal, "Body")
	for _, offset in { v3(-0.32, 0.2, 0), v3(0.32, 0.2, 0), v3(-0.32, -0.2, 0), v3(0.32, -0.2, 0) } do
		k:ball(
			"Rivet",
			0.1,
			(plate * CFrame.new(offset.X, offset.Y, -0.06)).Position,
			rgb(90, 95, 105),
			Enum.Material.Metal,
			"Body"
		)
	end

	local head: Kit.Shell = { center = v3(0, 2.72, -0.1), radii = v3(0.8, 0.7, 0.8) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), FUR, Enum.Material.Fabric, "Body")
	Parts.tube(
		k,
		"Snout",
		{ v3(0, 2.6, -0.62), v3(0, 2.5, -1.12) },
		{ 0.3, 0.2 },
		FUR_LIGHT,
		nil,
		"Body",
		{ density = 1 }
	)
	local nose = v3(0, 2.49, -1.28)
	k:ball("Nose", 0.34, nose, PINK, nil, "Body")
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		k:ball("NoseStar", 0.13, nose + v3(math.cos(angle) * 0.2, math.sin(angle) * 0.2, 0.04), PINK, nil, "Body")
	end
	k:mouth(
		CFrame.new(0, 2.28, -1.02),
		{ width = 0.3, height = 0.12, skin = FUR_LIGHT, style = "Smile", radius = 0.3 },
		"Body"
	)

	-- Goggles and a mining helmet with a lamp
	k:band("GoggleStrap", head, 2.84, 0.14, rgb(60, 45, 40), Enum.Material.Leather, "Body")
	for _, side in { -1, 1 } do
		local at = Kit.on(head, side * 26, 12, 0.02)
		k:disc("GoggleRim", 0.5, 0.14, at, BRASS, Enum.Material.Metal, "Body")
		local lens = k:disc(
			"GoggleLens",
			0.38,
			0.06,
			at * CFrame.new(0, 0, -0.06),
			rgb(150, 210, 230),
			Enum.Material.Glass,
			"Body"
		)
		lens:SetAttribute("KeepColor", true)
		k:ball("Highlight", 0.1, (at * CFrame.new(-0.08, 0.08, -0.1)).Position, C.White, nil, "Body")
	end
	k:ellipsoid("Helmet", v3(1.5, 1.0, 1.5), CFrame.new(0, 3.25, -0.08), HELMET, nil, "Body")
	k:oval("HelmetBrim", CFrame.new(0, 3.2, -0.12), 1.8, 1.8, 0.1, HELMET, nil, "Body")
	k:cylinder(
		"Lamp",
		0.3,
		0.36,
		CFrame.new(0, 3.42, -0.72) * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(70, 70, 80),
		Enum.Material.Metal,
		"Body"
	)
	k:disc(
		"LampGlass",
		0.28,
		0.04,
		CFrame.new(0, 3.42, -0.88) * CFrame.Angles(0, math.pi, 0),
		rgb(255, 245, 190),
		Enum.Material.Neon,
		"Body"
	)

	-- Stubby arms ending in drills
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder, hand = v3(side * 0.85, 1.85, -0.15), v3(side * 1.22, 1.5, -0.55)
		k:limb("Arm", shoulder, hand, 0.34, FUR, Enum.Material.Fabric, rig)
		k:oval(
			"DrillCollar",
			CFrame.lookAt(hand, hand + v3(side * 0.2, -0.25, -1)) * CFrame.Angles(math.pi / 2, 0, 0),
			0.46,
			0.46,
			0.16,
			BRASS,
			Enum.Material.Metal,
			rig
		)
		Parts.cone(
			k,
			"Drill",
			hand + v3(side * 0.04, -0.04, -0.08),
			hand + v3(side * 0.22, -0.3, -0.95),
			0.24,
			IRON,
			Enum.Material.Metal,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	return body
end

return Common
