-- EPIC Brainrots: taller, more layered costumes and props, each with a clear signature pose.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Epic: { [string]: (Kit) -> BasePart } = {}

local SKIN = rgb(236, 190, 150)
local BANANA = rgb(255, 222, 72)
local BANANA_IN = rgb(255, 246, 196)

-- Banana peel flaps curling open and down around a point, yellow outside and cream inside.
local function peel(k: Kit, center: Vector3, radius: number, length: number, count: number, rig: string)
	for i = 0, count - 1 do
		local angle = i * math.pi * 2 / count + math.pi / count
		local out = v3(math.sin(angle), 0, -math.cos(angle))
		local across = out:Cross(Vector3.yAxis)
		local base = center + out * radius * 0.85
		local mid = base + out * length * 0.42 + v3(0, -length * 0.3, 0)
		local tip = base + out * length * 0.62 + v3(0, -length, 0)
		local options: Kit.LoftOptions = { up = across, density = 0.45, overlap = 4, minSpacing = 0.14, maxSteps = 3 }
		k:loft("Peel", {
			{ at = base, w = 0.07, h = radius * 0.5 },
			{ at = mid, w = 0.07, h = radius * 0.52 },
			{ at = tip, w = 0.04, h = radius * 0.08 },
		}, BANANA, nil, rig, options)
		k:loft("PeelInside", {
			{ at = base - out * 0.06, w = 0.04, h = radius * 0.4 },
			{ at = mid - out * 0.07, w = 0.04, h = radius * 0.42 },
			{ at = tip - out * 0.06, w = 0.03, h = radius * 0.06 },
		}, BANANA_IN, nil, rig, options)
	end
end

-- A cartoon katana: slightly curved blade, gold guard and a wrapped grip. `grip` is where the hand is.
local function katana(k: Kit, grip: Vector3, direction: Vector3, rig: string)
	local dir = direction.Unit
	local bend = dir:Cross(Vector3.zAxis)
	bend = if bend.Magnitude > 0.1 then bend.Unit else Vector3.xAxis
	k:limb("Hilt", grip - dir * 0.35, grip + dir * 0.3, 0.14, rgb(40, 34, 40), Enum.Material.Fabric, rig)
	k:oval(
		"Guard",
		CFrame.lookAt(grip + dir * 0.34, grip + dir) * CFrame.Angles(math.pi / 2, 0, 0),
		0.38,
		0.38,
		0.06,
		rgb(230, 186, 70),
		Enum.Material.Metal,
		rig
	)
	local mid = grip + dir * 1.25 + bend * 0.06
	local tip = grip + dir * 2.2 + bend * 0.2
	for _, segment in { { grip + dir * 0.36, mid }, { mid, tip } } do
		local from, to = segment[1], segment[2]
		local blade = k:part(
			"Blade",
			v3(0.05, (to - from).Magnitude, 0.16),
			CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(math.pi / 2, 0, 0),
			rgb(222, 228, 238),
			Enum.Material.Metal,
			rig
		)
		blade.Reflectance = 0.3
	end
end

---------------------------------------------------------------------------
-- Chimpanzini Bananini: a chimp bursting out of a banana
---------------------------------------------------------------------------

Epic.ChimpanziniBananini = function(k: Kit): BasePart
	local CHIMP = rgb(92, 64, 48)
	local FACE = rgb(228, 188, 150)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.42, 0.9, 0), v3(side * 0.5, 0.3, 0), 0.34, CHIMP, Enum.Material.Fabric, "Legs")
		k:ellipsoid("Foot", v3(0.56, 0.26, 0.9), CFrame.new(side * 0.55, 0.13, -0.2), FACE, nil, "Legs")
	end
	-- The banana: a fat curved body with a brown tip, peel opening around the chimp's chest
	local body = Parts.tube(
		k,
		"Banana",
		{ v3(0.62, 0.55, 0.05), v3(0.3, 1.25, 0), v3(0.02, 2.2, 0), v3(-0.05, 2.95, 0) },
		{ 0.22, 0.78, 0.92, 0.9 },
		BANANA,
		nil,
		"Body",
		{ density = 1, overlap = 6 }
	)
	k:ball("BananaTip", 0.3, v3(0.66, 0.45, 0.05), rgb(96, 72, 40), nil, "Body")
	for _, yaw in { -60, 0, 60, 180 } do
		local angle = math.rad(yaw)
		local at = v3(math.sin(angle) * 0.9, 1.9, -math.cos(angle) * 0.9)
		k:ellipsoid(
			"BananaRidge",
			v3(0.08, 1.9, 0.1),
			CFrame.lookAt(at, at + v3(math.sin(angle), 0, -math.cos(angle))),
			rgb(236, 196, 50),
			nil,
			"Body"
		)
	end
	peel(k, v3(-0.05, 3.0, 0), 0.9, 1.25, 4, "Body")

	-- The chimp on top
	local chest: Kit.Shell = { center = v3(0, 3.3, 0), radii = v3(0.8, 0.62, 0.72) }
	k:ellipsoid("Chest", chest.radii * 2, CFrame.new(chest.center), CHIMP, Enum.Material.Fabric, "Body")
	local head: Kit.Shell = { center = v3(0, 4.25, -0.05), radii = v3(0.76, 0.7, 0.7) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CHIMP, Enum.Material.Fabric, "Body")
	local face: Kit.Shell = { center = v3(0, 4.12, -0.38), radii = v3(0.58, 0.54, 0.42) }
	k:ellipsoid("Face", face.radii * 2, CFrame.new(face.center), FACE, nil, "Body")
	k:ellipsoid("Muzzle", v3(0.84, 0.52, 0.5), CFrame.new(0, 3.9, -0.66), FACE, nil, "Body")
	for _, side in { -1, 1 } do
		k:disc(
			"Ear",
			0.56,
			0.14,
			CFrame.new(side * 0.8, 4.25, 0) * CFrame.Angles(0, math.rad(side * 70), 0),
			FACE,
			nil,
			"Body"
		)
		k:ball("Nostril", 0.08, v3(side * 0.08, 4.02, -0.9), rgb(120, 80, 60), nil, "Body")
	end
	k:brow(Kit.on(face, 0, 38, -0.02), 0.9, 0, CHIMP, "Body")
	k:eyes(face, 24, 18, { width = 0.28, height = 0.34, iris = rgb(70, 40, 25) }, "Body")
	k:mouth(
		CFrame.new(0, 3.8, -0.9),
		{ width = 0.62, height = 0.26, skin = FACE, style = "Grin", radius = 0.5 },
		"Body"
	)
	-- Long arms: one waving, one scratching its head
	Parts.bareArm(k, "ArmL", v3(-0.72, 3.45, 0), v3(-1.45, 4.5, -0.2), 0.3, CHIMP, 0.38)
	Parts.bareArm(k, "ArmR", v3(0.72, 3.45, 0), v3(1.35, 2.5, -0.25), 0.3, CHIMP, 0.38)
	return body[2]
end

---------------------------------------------------------------------------
-- Cappuccino Assassino: a cappuccino cup ninja with two katanas
---------------------------------------------------------------------------

Epic.CappuccinoAssassino = function(k: Kit): BasePart
	local CUP = rgb(246, 242, 236)
	local NINJA = rgb(34, 32, 40)
	local SASH = rgb(206, 42, 52)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.42, 1.55, 0), v3(side * 0.62, 0.9, -0.1), 0.3, NINJA, Enum.Material.Fabric, "Legs")
		k:limb("Leg", v3(side * 0.62, 0.9, -0.1), v3(side * 0.7, 0.3, 0), 0.26, NINJA, Enum.Material.Fabric, "Legs")
		k:ellipsoid(
			"Tabi",
			v3(0.42, 0.3, 0.72),
			CFrame.new(side * 0.7, 0.15, -0.14),
			NINJA,
			Enum.Material.Fabric,
			"Legs"
		)
		k:ellipsoid(
			"TabiWrap",
			v3(0.46, 0.14, 0.46),
			CFrame.new(side * 0.7, 0.34, 0),
			rgb(90, 90, 100),
			Enum.Material.Fabric,
			"Legs"
		)
	end

	local cup = Parts.cup(k, v3(0, 2.0, 0), 1.9, 1.08, { color = CUP, heart = true })
	local body = k.model:FindFirstChild("Cup") :: BasePart
	Parts.handle(k, "CupHandle", v3(1.02, 3.45, 0), v3(1.02, 2.45, 0), v3(0.32, 0, 0), 0.2, CUP, nil, "Body")
	-- Ninja mask across the cup with a narrow eye slit, and flowing headband tails
	k:oval("Mask", CFrame.new(0, 3.28, 0), 2.24, 2.24, 0.62, NINJA, Enum.Material.Fabric, "Body")
	k:oval("EyeSlit", CFrame.new(0, 3.3, -0.02), 2.26, 2.2, 0.3, rgb(244, 214, 176), nil, "Body")
	k:oval("Headband", CFrame.new(0, 3.72, 0), 2.24, 2.24, 0.2, SASH, Enum.Material.Fabric, "Body")
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"BandTail",
			v3(side * 0.15, 3.72, 1.1),
			v3(side * 0.6, 3.25, 2.1),
			0.3,
			0.06,
			SASH,
			v3(side, 0.4, 0).Unit,
			Enum.Material.Fabric,
			"Body"
		)
		k:eye(Parts.onCup(cup, side * 24, 3.3, -0.02), {
			width = 0.36,
			height = 0.3,
			iris = rgb(40, 30, 30),
			lid = 0.35,
			lidTilt = 22,
			skin = rgb(244, 214, 176),
			side = side,
		}, "Body")
	end
	k:band("Sash", { center = cup.center, radii = v3(1.1, 5, 1.1) }, 2.25, 0.28, SASH, Enum.Material.Fabric, "Body")
	Parts.leaf(
		k,
		"SashKnot",
		v3(0.35, 2.25, -1.08),
		v3(0.62, 1.7, -1.2),
		0.34,
		0.08,
		SASH,
		v3(0, 0, -1),
		Enum.Material.Fabric,
		"Body"
	)

	-- Arms holding two katanas, one raised high
	Parts.bareArm(k, "ArmL", v3(-1.0, 2.9, 0), v3(-1.55, 2.3, -0.4), 0.26, NINJA, 0.34)
	Parts.bareArm(k, "ArmR", v3(1.0, 2.9, 0), v3(1.45, 3.9, -0.3), 0.26, NINJA, 0.34)
	katana(k, v3(-1.55, 2.3, -0.4), v3(-0.35, -0.2, -1), "ArmL")
	katana(k, v3(1.45, 3.9, -0.3), v3(-0.25, 1, -0.2), "ArmR")
	return body
end

---------------------------------------------------------------------------
-- Cocofanto Elefanto: an elephant who is mostly coconut
---------------------------------------------------------------------------

Epic.CocofantoElefanto = function(k: Kit): BasePart
	local COCONUT = rgb(122, 80, 50)
	local HUSK = rgb(96, 62, 40)
	local ELEPHANT = rgb(156, 164, 188)
	local EAR = rgb(236, 176, 186)
	local PALM = rgb(84, 170, 76)

	for _, x in { -0.72, 0.72 } do
		for _, z in { -0.5, 0.6 } do
			k:limb("Leg", v3(x, 1.2, z), v3(x * 1.02, 0.35, z), 0.62, ELEPHANT, nil, "Legs")
			k:oval("Foot", CFrame.new(x * 1.02, 0.14, z), 0.72, 0.72, 0.28, rgb(134, 142, 166), nil, "Legs")
			for _, toe in { -0.2, 0, 0.2 } do
				k:ball("Toenail", 0.16, v3(x * 1.02 + toe, 0.16, z - 0.34), rgb(240, 232, 216), nil, "Legs")
			end
		end
	end
	-- One big coconut is both body and head
	local shell: Kit.Shell = { center = v3(0, 2.45, 0), radii = v3(1.45, 1.38, 1.4) }
	local body =
		k:ellipsoid("Coconut", shell.radii * 2, CFrame.new(shell.center), COCONUT, Enum.Material.Fabric, "Body")
	for i = 0, 5 do
		Parts.patch(
			k,
			"Husk",
			shell,
			110 + i * 28,
			20 - (i % 2) * 30,
			0.14,
			1.4,
			HUSK,
			Enum.Material.Fabric,
			"Body",
			20
		)
		Parts.patch(
			k,
			"Husk",
			shell,
			-110 - i * 28,
			20 - (i % 2) * 30,
			0.14,
			1.4,
			HUSK,
			Enum.Material.Fabric,
			"Body",
			-20
		)
	end
	for _, side in { -1, 1 } do
		local ear = CFrame.new(side * 1.45, 2.75, 0.1) * CFrame.Angles(0, math.rad(side * -18), math.rad(side * 8))
		k:ellipsoid("Ear", v3(1.5, 1.75, 0.18), ear, ELEPHANT, nil, "Body")
		k:ellipsoid("EarInner", v3(1.15, 1.4, 0.1), ear * CFrame.new(0, -0.02, -0.08), EAR, nil, "Body")
		Parts.cone(
			k,
			"Tusk",
			v3(side * 0.36, 2.05, -1.18),
			v3(side * 0.55, 1.75, -1.75),
			0.13,
			rgb(248, 242, 226),
			nil,
			"Body"
		)
		k:blush(Kit.on(shell, side * 36, -8, 0.02), 0.36, "Body")
	end
	k:eyes(shell, 24, 18, { width = 0.4, height = 0.5, iris = rgb(50, 34, 26) }, "Body")
	Parts.tube(
		k,
		"Trunk",
		{ v3(0, 2.3, -1.2), v3(0, 1.8, -1.6), v3(0, 1.1, -1.65), v3(0, 0.8, -1.95), v3(0, 0.95, -2.25) },
		{ 0.36, 0.3, 0.24, 0.2, 0.18 },
		ELEPHANT,
		nil,
		"Body",
		{ density = 1.1, overlap = 5 }
	)
	for i = 0, 3 do
		k:ellipsoid(
			"TrunkRing",
			v3(0.52 - i * 0.06, 0.08, 0.52 - i * 0.06),
			CFrame.new(0, 1.95 - i * 0.28, -1.58 - i * 0.02),
			rgb(134, 142, 166),
			nil,
			"Body"
		)
	end
	-- Palm fronds sprouting from the top
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		local out = v3(math.cos(angle), 0, math.sin(angle))
		local base = v3(0, 3.75, 0.05)
		Parts.leaf(
			k,
			"Frond",
			base,
			base + out * 1.25 + v3(0, 0.55 - (i % 2) * 0.35, 0),
			0.5,
			0.06,
			PALM,
			v3(0, 1, 0),
			nil,
			"Body"
		)
	end
	k:ball("FrondRoot", 0.4, v3(0, 3.78, 0.05), HUSK, Enum.Material.Fabric, "Body")
	return body
end

---------------------------------------------------------------------------
-- Trulimero Trulicina: a fish with a cat's head, standing on two legs
---------------------------------------------------------------------------

Epic.TrulimeroTrulicina = function(k: Kit): BasePart
	local FISH = rgb(255, 146, 52)
	local FISH_LIGHT = rgb(255, 214, 150)
	local STRIPE = rgb(255, 250, 244)
	local FIN = rgb(255, 118, 60)
	local CAT = rgb(150, 150, 164)
	local CAT_DARK = rgb(96, 96, 110)

	for _, z in { -0.45, 0.55 } do
		k:loft("Leg", {
			{ at = v3(0, 2.0, z), w = 0.28, h = 0.28 },
			{ at = v3(0, 1.1, z - 0.08), w = 0.24, h = 0.24 },
			{ at = v3(0, 0.36, z), w = 0.2, h = 0.2 },
		}, SKIN, nil, "Legs", { density = 3, overlap = 7 })
		Parts.sandal(k, v3(0, 0, z), 0.8, rgb(255, 90, 120), rgb(255, 230, 90), "Legs", 0)
	end

	-- A tall, round goldfish body seen side-on, with white stripes and flowing fins
	local shell: Kit.Shell = { center = v3(0, 2.9, 0.35), radii = v3(0.72, 1.12, 1.35) }
	local body = k:ellipsoid("Fish", shell.radii * 2, CFrame.new(shell.center), FISH, nil, "Body")
	k:ellipsoid("FishBelly", v3(1.46, 1.3, 2.3), CFrame.new(0, 2.55, 0.3), FISH_LIGHT, nil, "Body")
	for _, z in { -0.1, 0.75 } do
		k:ellipsoid("FishStripe", v3(1.5, 2.1, 0.26), CFrame.new(0, 2.92, z), STRIPE, nil, "Body")
	end
	local tail = v3(0, 3.0, 1.6)
	for _, spec in { { 0.95, 0.9 }, { -0.75, 0.7 } } do
		k:loft("TailFin", {
			{ at = tail, w = 0.08, h = 0.28 },
			{ at = tail + v3(0, spec[1] * 0.55, 0.62), w = 0.07, h = 0.4 },
			{ at = tail + v3(0, spec[1], 1.2), w = 0.03, h = 0.12 },
		}, FIN, nil, "Body", { up = v3(0, 0, 1), density = 0.45, overlap = 4, minSpacing = 0.14 })
	end
	k:loft("DorsalFin", {
		{ at = v3(0, 3.95, 0.0), w = 0.07, h = 0.3 },
		{ at = v3(0, 4.35, 0.5), w = 0.06, h = 0.34 },
		{ at = v3(0, 4.2, 1.1), w = 0.03, h = 0.1 },
	}, FIN, nil, "Body", { up = v3(0, 0.2, 1).Unit, density = 0.45, overlap = 4, minSpacing = 0.14 })
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local root = v3(side * 0.6, 2.6, -0.2)
		Parts.leaf(
			k,
			"PectoralFin",
			root,
			root + v3(side * 0.7, -0.35, 0.35),
			0.5,
			0.08,
			FIN,
			v3(side, 0.3, 0).Unit,
			nil,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", root)
	end

	-- The cat's head where the fish's head should be
	local head: Kit.Shell = { center = v3(0, 3.35, -1.0), radii = v3(0.8, 0.72, 0.72) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CAT, nil, "Body")
	for _, yaw in { -24, 0, 24 } do
		Parts.patch(k, "CatStripe", head, yaw, 55, 0.13, 0.42, CAT_DARK, nil, "Body")
	end
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.44, 3.86, -0.98),
			v3(side * 0.62, 4.42, -0.94),
			0.54,
			0.16,
			CAT,
			-Vector3.zAxis,
			nil,
			"Body"
		)
		Parts.leaf(
			k,
			"EarInner",
			v3(side * 0.45, 3.9, -1.08),
			v3(side * 0.59, 4.28, -1.04),
			0.32,
			0.06,
			rgb(255, 170, 185),
			-Vector3.zAxis,
			nil,
			"Body"
		)
		for i = -1, 1 do
			local root = v3(side * 0.22, 3.18 + i * 0.07, -1.66)
			k:limb("Whisker", root, root + v3(side * 0.6, i * 0.14, 0.12), 0.035, C.White, nil, "Body")
		end
		k:blush(Kit.on(head, side * 42, -12, 0.02), 0.24, "Body")
	end
	k:eyes(head, 27, 12, { width = 0.4, height = 0.48, iris = rgb(120, 200, 90), lid = 0.2, skin = CAT }, "Body")
	k:ellipsoid("Nose", v3(0.18, 0.12, 0.1), Kit.on(head, 0, -6, 0.02), rgb(255, 160, 178), nil, "Body")
	k:mouth(Kit.on(head, 0, -20, 0), { width = 0.36, height = 0.16, skin = CAT, style = "Open", radius = 0.72 }, "Body")
	k:turn(-32)
	return body
end

---------------------------------------------------------------------------
-- Bananita Dolphinita: a dolphin in a banana costume
---------------------------------------------------------------------------

Epic.BananitaDolphinita = function(k: Kit): BasePart
	local DOLPHIN = rgb(116, 164, 214)
	local BELLY = rgb(222, 236, 248)

	-- Tail flukes for feet
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"Fluke",
			v3(0, 0.35, 0.2),
			v3(side * 0.95, 0.12, -0.35),
			0.62,
			0.14,
			DOLPHIN,
			Vector3.yAxis,
			nil,
			"Legs"
		)
	end
	k:limb("TailStock", v3(0, 0.3, 0.2), v3(0, 1.2, 0.1), 0.6, DOLPHIN, nil, "Legs")

	-- The banana costume covering the body, peel open at the top
	local suit = Parts.tube(
		k,
		"BananaSuit",
		{ v3(0, 0.95, 0.1), v3(0.08, 1.9, 0.05), v3(0, 2.9, 0) },
		{ 0.62, 0.98, 0.96 },
		BANANA,
		nil,
		"Body",
		{ density = 1, overlap = 6 }
	)
	for _, yaw in { -60, 0, 60, 180 } do
		local angle = math.rad(yaw)
		local at = v3(math.sin(angle) * 0.95, 2.0, -math.cos(angle) * 0.95)
		k:ellipsoid(
			"BananaRidge",
			v3(0.08, 1.8, 0.1),
			CFrame.lookAt(at, at + v3(math.sin(angle), 0, -math.cos(angle))),
			rgb(236, 196, 50),
			nil,
			"Body"
		)
	end
	peel(k, v3(0, 2.95, 0), 0.92, 1.2, 4, "Body")

	-- Dolphin head with its bottle nose, blowhole and dorsal fin poking out
	local head: Kit.Shell = { center = v3(0, 3.65, -0.05), radii = v3(0.86, 0.9, 0.86) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), DOLPHIN, nil, "Body")
	Parts.patch(k, "Belly", head, 0, -30, 1.1, 0.9, BELLY, nil, "Body")
	k:loft("Beak", {
		{ at = v3(0, 3.3, -0.6), w = 0.42, h = 0.3 },
		{ at = v3(0, 3.22, -1.25), w = 0.3, h = 0.2 },
	}, DOLPHIN, nil, "Body", { density = 1, overlap = 5 })
	k:loft("BeakUnder", {
		{ at = v3(0, 3.15, -0.6), w = 0.38, h = 0.2 },
		{ at = v3(0, 3.12, -1.2), w = 0.24, h = 0.12 },
	}, BELLY, nil, "Body", { density = 1, overlap = 5 })
	k:ball("Blowhole", 0.16, v3(0, 4.52, 0.05), rgb(70, 100, 140), nil, "Body")
	Parts.leaf(k, "DorsalFin", v3(0, 4.2, 0.55), v3(0, 4.75, 1.05), 0.55, 0.12, DOLPHIN, Vector3.xAxis, nil, "Body")
	k:eyes(head, 34, 18, { width = 0.34, height = 0.42, iris = rgb(30, 40, 60) }, "Body")
	k:mouth(
		CFrame.new(0, 3.18, -1.0) * CFrame.Angles(math.rad(-20), 0, 0),
		{ width = 0.5, height = 0.14, skin = BELLY, style = "Smile", radius = 0.5 },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:blush(Kit.on(head, side * 50, -8, 0.02), 0.28, "Body")
		local rig = if side < 0 then "ArmL" else "ArmR"
		local root = v3(side * 0.9, 2.55, -0.05)
		Parts.leaf(
			k,
			"Flipper",
			root,
			root + v3(side * 0.7, if side < 0 then -0.6 else 0.5, -0.25),
			0.5,
			0.14,
			DOLPHIN,
			v3(0, 0, -1),
			nil,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", root)
	end
	return suit[2]
end

return Epic
