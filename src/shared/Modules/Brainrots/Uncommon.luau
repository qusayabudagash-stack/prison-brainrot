-- UNCOMMON Brainrots: two ideas mashed into one body, with a prop or costume detail on top.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Uncommon: { [string]: (Kit) -> BasePart } = {}

local SKIN = rgb(236, 190, 150)

---------------------------------------------------------------------------
-- Boneca Ambalabu: a frog riding in a car tire, on human legs
---------------------------------------------------------------------------

Uncommon.BonecaAmbalabu = function(k: Kit): BasePart
	local FROG = rgb(112, 198, 92)
	local FROG_LIGHT = rgb(214, 238, 168)
	local TIRE = rgb(42, 42, 50)
	local TREAD = rgb(62, 62, 72)
	local HUB = rgb(205, 210, 222)

	for _, side in { -1, 1 } do
		k:loft("Leg", {
			{ at = v3(side * 0.45, 1.5, 0), w = 0.3, h = 0.3 },
			{ at = v3(side * 0.5, 0.95, -0.06), w = 0.25, h = 0.25 },
			{ at = v3(side * 0.52, 0.48, 0), w = 0.22, h = 0.22 },
		}, SKIN, nil, "Legs", { density = 3, overlap = 7 })
		Parts.sneaker(k, v3(side * 0.52, 0, 0), 0.82, { upper = rgb(225, 60, 60) }, "Legs", side * 8)
	end

	-- The tire, hubcap facing forward
	local center = v3(0, 2.3, 0)
	local body = k:cylinder(
		"Tire",
		1.0,
		2.3,
		CFrame.new(center) * CFrame.Angles(math.pi / 2, 0, 0),
		TIRE,
		Enum.Material.Rubber,
		"Body"
	)
	for i = 0, 13 do
		local angle = i * math.pi * 2 / 14
		k:part(
			"Tread",
			v3(0.26, 0.14, 1.04),
			CFrame.new(center) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 1.13, 0),
			TREAD,
			Enum.Material.Rubber,
			"Body"
		)
	end
	local face = CFrame.new(center + v3(0, 0, -0.5)) * CFrame.Angles(0, math.pi, 0)
	k:disc("Rim", 1.5, 0.06, face, rgb(120, 124, 138), Enum.Material.Metal, "Body")
	k:disc("Hubcap", 1.12, 0.12, face * CFrame.new(0, 0, 0.04), HUB, Enum.Material.Metal, "Body")
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		k:ball(
			"Bolt",
			0.14,
			(face * CFrame.new(math.cos(angle) * 0.3, math.sin(angle) * 0.3, 0.12)).Position,
			rgb(90, 95, 110),
			Enum.Material.Metal,
			"Body"
		)
	end

	-- Frog head on top, hands gripping the tire
	local head: Kit.Shell = { center = v3(0, 3.72, -0.05), radii = v3(0.98, 0.64, 0.82) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), FROG, nil, "Body")
	k:ellipsoid("Chin", v3(1.7, 0.7, 1.4), CFrame.new(0, 3.55, -0.12), FROG_LIGHT, nil, "Body")
	for _, side in { -1, 1 } do
		local bump: Kit.Shell = { center = v3(side * 0.48, 4.22, -0.18), radii = v3(0.36, 0.34, 0.34) }
		k:ellipsoid("EyeBump", bump.radii * 2, CFrame.new(bump.center), FROG, nil, "Body")
		k:eye(
			Kit.on(bump, side * 8, 6, -0.06),
			{ width = 0.44, height = 0.46, iris = rgb(40, 34, 30), side = side },
			"Body"
		)
		k:ball("Nostril", 0.07, v3(side * 0.14, 3.86, -0.86), rgb(50, 90, 45), nil, "Body")
		k:blush(Kit.on(head, side * 48, -6, 0.02), 0.28, "Body")
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder, hand = v3(side * 0.78, 3.35, -0.2), v3(side * 1.18, 2.72, -0.52)
		k:limb("Arm", shoulder, hand, 0.2, FROG, nil, rig)
		for f = -1, 1 do
			k:ball("Finger", 0.16, hand + v3(side * 0.06, -0.08, f * 0.12 - 0.05), FROG, nil, rig)
		end
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	k:mouth(
		Kit.on(head, 0, -24, 0),
		{ width = 1.05, height = 0.2, skin = FROG_LIGHT, style = "Smile", radius = 0.9 },
		"Body"
	)
	return body
end

---------------------------------------------------------------------------
-- Bobrito Bandito: a beaver bandit with a fedora and a bag of loot
---------------------------------------------------------------------------

Uncommon.BobritoBandito = function(k: Kit): BasePart
	local BEAVER = rgb(152, 102, 66)
	local MUZZLE = rgb(214, 172, 128)
	local HAT = rgb(62, 56, 56)
	local MASK = rgb(30, 30, 38)
	local BANDANA = rgb(214, 54, 54)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.45, 0.7, 0), v3(side * 0.5, 0.25, 0), 0.4, BEAVER, nil, "Legs")
		k:ellipsoid("Foot", v3(0.62, 0.22, 0.9), CFrame.new(side * 0.55, 0.11, -0.22), rgb(70, 52, 48), nil, "Legs")
	end
	local shell: Kit.Shell = { center = v3(0, 1.55, 0), radii = v3(0.88, 1.0, 0.8) }
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), BEAVER, Enum.Material.Fabric, "Body")
	Parts.patch(k, "Belly", shell, 0, -12, 1.0, 1.25, MUZZLE, Enum.Material.Fabric, "Body")
	-- Flat paddle tail
	k:ellipsoid(
		"Tail",
		v3(1.0, 0.2, 1.6),
		CFrame.new(0, 0.55, 1.3) * CFrame.Angles(math.rad(-28), 0, 0),
		rgb(84, 64, 60),
		Enum.Material.Leather,
		"Body"
	)

	local head: Kit.Shell = { center = v3(0, 2.9, -0.05), radii = v3(0.78, 0.7, 0.72) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), BEAVER, Enum.Material.Fabric, "Body")
	k:ellipsoid("Muzzle", v3(0.95, 0.62, 0.6), CFrame.new(0, 2.66, -0.6), MUZZLE, nil, "Body")
	k:ellipsoid("Nose", v3(0.34, 0.22, 0.2), CFrame.new(0, 2.84, -0.9), rgb(50, 36, 36), nil, "Body")
	for _, side in { -1, 1 } do
		k:part("BuckTooth", v3(0.15, 0.26, 0.06), CFrame.new(side * 0.085, 2.38, -0.84), C.White, nil, "Body")
		k:ball("Ear", 0.32, v3(side * 0.6, 3.42, 0.05), BEAVER, nil, "Body")
	end
	k:mouth(
		CFrame.new(0, 2.54, -0.86),
		{ width = 0.4, height = 0.12, skin = MUZZLE, style = "Smirk", radius = 0.4 },
		"Body"
	)
	-- Bandit mask, sly eyes, fedora and bandana
	k:band("Mask", head, 3.06, 0.24, MASK, Enum.Material.Fabric, "Body")
	k:eyes(
		head,
		26,
		12,
		{ width = 0.34, height = 0.38, iris = rgb(60, 40, 30), lid = 0.35, lidTilt = 14, skin = MASK },
		"Body"
	)
	k:oval(
		"HatBrim",
		CFrame.new(0, 3.48, 0) * CFrame.Angles(math.rad(-6), 0, 0),
		2.0,
		1.9,
		0.1,
		HAT,
		Enum.Material.Fabric,
		"Body"
	)
	k:ellipsoid("HatCrown", v3(1.12, 0.78, 1.05), CFrame.new(0, 3.78, 0.02), HAT, Enum.Material.Fabric, "Body")
	k:oval("HatBand", CFrame.new(0, 3.58, 0.02), 1.14, 1.07, 0.16, rgb(190, 150, 90), Enum.Material.Fabric, "Body")
	k:band("Bandana", shell, 2.3, 0.26, BANDANA, Enum.Material.Fabric, "Body")
	Parts.leaf(
		k,
		"BandanaKnot",
		v3(0, 2.28, -0.55),
		v3(0.05, 1.8, -0.72),
		0.55,
		0.08,
		BANDANA,
		v3(0, 0.3, -1).Unit,
		Enum.Material.Fabric,
		"Body"
	)

	-- One arm swings a loot sack over the shoulder
	Parts.bareArm(k, "ArmL", v3(-0.8, 1.95, 0), v3(-1.25, 1.35, -0.3), 0.3, BEAVER, 0.38)
	Parts.bareArm(k, "ArmR", v3(0.8, 1.95, 0), v3(1.0, 2.75, 0.25), 0.3, BEAVER, 0.38)
	local sack = k:ellipsoid(
		"LootSack",
		v3(1.2, 1.3, 1.1),
		CFrame.new(1.05, 2.55, 0.95),
		rgb(206, 184, 140),
		Enum.Material.Fabric,
		"ArmR"
	)
	k:ellipsoid(
		"SackTie",
		v3(0.4, 0.2, 0.4),
		CFrame.new(1.02, 3.2, 0.62),
		rgb(150, 120, 80),
		Enum.Material.Fabric,
		"ArmR"
	)
	k:badge(CFrame.new(1.05, 2.5, 0.38) * CFrame.Angles(0, math.rad(-20), 0), "$", 0.5, "ArmR")
	local _ = sack
	return body
end

---------------------------------------------------------------------------
-- Burbaloni Luliloli: a capybara wearing a coconut
---------------------------------------------------------------------------

Uncommon.BurbaloniLuliloli = function(k: Kit): BasePart
	local COCONUT = rgb(118, 78, 50)
	local FLESH = rgb(250, 247, 236)
	local CAPY = rgb(180, 130, 84)
	local CAPY_DARK = rgb(128, 88, 56)

	-- The coconut shell, worn like a turtle shell, cut open at the front
	local shell: Kit.Shell = { center = v3(0, 1.75, 0.3), radii = v3(1.28, 1.2, 1.3) }
	local body =
		k:ellipsoid("Coconut", shell.radii * 2, CFrame.new(shell.center), COCONUT, Enum.Material.Fabric, "Body")
	local opening = CFrame.new(0, 1.6, -0.82) * CFrame.Angles(math.pi / 2, 0, 0)
	Parts.ring(k, "CoconutFlesh", opening, 0.88, 0.26, FLESH, nil, "Body", 12)
	for _, spot in { { -0.3, 55 }, { 0.3, 55 }, { 0, 70 } } do
		k:ellipsoid(
			"CoconutEye",
			v3(0.22, 0.22, 0.1),
			Kit.on(shell, 180 + spot[1] * 60, spot[2] - 20, 0.01),
			rgb(64, 42, 30),
			nil,
			"Body"
		)
	end

	-- Capybara poking out of the front
	local head: Kit.Shell = { center = v3(0, 1.8, -1.2), radii = v3(0.64, 0.58, 0.72) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CAPY, Enum.Material.Fabric, "Body")
	k:ellipsoid("Muzzle", v3(1.0, 0.8, 0.7), CFrame.new(0, 1.62, -1.62), CAPY, Enum.Material.Fabric, "Body")
	k:ellipsoid("Nose", v3(0.62, 0.3, 0.2), CFrame.new(0, 1.8, -1.95), CAPY_DARK, nil, "Body")
	for _, side in { -1, 1 } do
		k:ball("Nostril", 0.1, v3(side * 0.14, 1.8, -2.04), rgb(60, 40, 30), nil, "Body")
		k:ball("Ear", 0.28, v3(side * 0.45, 2.34, -1.0), CAPY_DARK, nil, "Body")
		k:eye(
			Kit.on(head, side * 40, 18, -0.04),
			{ width = 0.24, height = 0.26, iris = rgb(40, 28, 22), lid = 0.45, skin = CAPY, side = side },
			"Body"
		)
		-- Paws on the rim and hind feet
		k:ellipsoid("Paw", v3(0.34, 0.24, 0.46), CFrame.new(side * 0.52, 0.95, -1.05), CAPY_DARK, nil, "ArmL")
		k:limb("Leg", v3(side * 0.52, 1.1, -0.9), v3(side * 0.52, 0.95, -1.05), 0.3, CAPY, nil, "ArmL")
		k:ellipsoid("HindFoot", v3(0.5, 0.26, 0.7), CFrame.new(side * 0.7, 0.13, 0.6), CAPY_DARK, nil, "Legs")
		k:limb("HindLeg", v3(side * 0.7, 0.7, 0.55), v3(side * 0.7, 0.2, 0.6), 0.4, CAPY, nil, "Legs")
	end
	k:mouth(
		CFrame.new(0, 1.42, -1.9),
		{ width = 0.3, height = 0.1, skin = CAPY, style = "Smile", radius = 0.4 },
		"Body"
	)
	-- The famous orange on its head, and a cocktail straw with a paper umbrella
	k:ball("Orange", 0.5, v3(0, 2.62, -1.15), rgb(255, 150, 40), nil, "Body")
	Parts.leaf(
		k,
		"OrangeLeaf",
		v3(0, 2.86, -1.15),
		v3(0.25, 3.02, -1.05),
		0.2,
		0.04,
		rgb(80, 170, 70),
		Vector3.yAxis,
		nil,
		"Body"
	)
	k:limb("Straw", v3(0.35, 2.7, 0.45), v3(0.62, 3.65, 0.62), 0.12, rgb(255, 110, 140), nil, "Body")
	local umbrella = CFrame.new(0.6, 3.58, 0.61) * CFrame.Angles(0, 0, math.rad(-18))
	k:ellipsoid("Umbrella", v3(1.05, 0.34, 1.05), umbrella, rgb(255, 120, 150), nil, "Body")
	k:ellipsoid(
		"UmbrellaStripe",
		v3(0.62, 0.3, 0.62),
		umbrella * CFrame.new(0, 0.05, 0),
		rgb(255, 222, 90),
		nil,
		"Body"
	)
	k:ball("UmbrellaTip", 0.1, (umbrella * CFrame.new(0, 0.2, 0)).Position, C.White, nil, "Body")
	return body
end

---------------------------------------------------------------------------
-- Il Cacto Hipopotamo: a hippo that grew into a cactus
---------------------------------------------------------------------------

Uncommon.CactoHipopotamo = function(k: Kit): BasePart
	local CACTUS = rgb(98, 176, 96)
	local GROOVE = rgb(62, 132, 70)
	local SNOUT = rgb(150, 206, 130)
	local SPINE = rgb(252, 246, 222)

	for _, x in { -0.7, 0.7 } do
		for _, z in { -0.55, 0.65 } do
			k:limb("Leg", v3(x, 0.95, z), v3(x * 1.04, 0.28, z), 0.58, CACTUS, nil, "Legs")
			k:oval("Toe", CFrame.new(x * 1.04, 0.1, z - 0.05), 0.6, 0.6, 0.2, SNOUT, nil, "Legs")
		end
	end
	local shell: Kit.Shell = { center = v3(0, 1.6, 0.25), radii = v3(1.15, 0.95, 1.3) }
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), CACTUS, nil, "Body")
	for _, yaw in { -140, -100, -60, 60, 100, 140, 180 } do
		Parts.patch(k, "Groove", shell, yaw, 8, 0.14, 1.7, GROOVE, nil, "Body")
	end

	-- Big hippo head with a wide snout
	local head: Kit.Shell = { center = v3(0, 2.55, -0.75), radii = v3(0.85, 0.72, 0.72) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CACTUS, nil, "Body")
	local snout: Kit.Shell = { center = v3(0, 2.05, -1.2), radii = v3(0.98, 0.56, 0.62) }
	k:ellipsoid("Snout", snout.radii * 2, CFrame.new(snout.center), SNOUT, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid("Nostril", v3(0.16, 0.1, 0.14), Kit.on(snout, side * 22, 42, -0.02), GROOVE, nil, "Body")
		k:ball("Ear", 0.32, v3(side * 0.6, 3.18, -0.55), CACTUS, nil, "Body")
		k:tooth(Kit.on(snout, side * 26, -22, 0.02), 0.16, -0.26, nil, "Body")
		k:blush(Kit.on(snout, side * 55, 10, 0.02), 0.3, "Body")
	end
	k:eyes(head, 30, 26, { width = 0.36, height = 0.42, iris = rgb(45, 35, 40) }, "Body")
	k:mouth(
		Kit.on(snout, 0, -12, 0),
		{ width = 1.1, height = 0.18, skin = SNOUT, style = "Smile", radius = 0.8 },
		"Body"
	)
	-- Spines and a desert flower on top
	for i = 1, 22 do
		local yaw = ((i * 137.5) % 260) - 130 + 180
		local pitch = -25 + (i * 47 % 85)
		k:ball("Spine", 0.13, (Kit.surface(shell, yaw, pitch)), SPINE, nil, "Body")
	end
	for i = 1, 8 do
		local yaw = (i * 97) % 120 - 60
		local pitch = 10 + (i * 31) % 50
		k:ball("Spine", 0.1, (Kit.surface(head, yaw + (if yaw >= 0 then 45 else -45), pitch)), SPINE, nil, "Body")
	end
	local flower = v3(0.2, 3.3, -0.65)
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		k:ellipsoid(
			"Petal",
			v3(0.24, 0.1, 0.4),
			CFrame.new(flower)
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, 0, -0.18)
				* CFrame.Angles(math.rad(20), 0, 0),
			rgb(255, 110, 160),
			nil,
			"Body"
		)
	end
	k:ball("FlowerHeart", 0.2, flower + v3(0, 0.05, 0), rgb(255, 214, 70), nil, "Body")
	return body
end

---------------------------------------------------------------------------
-- Orangutini Ananassini: an orangutan in a pineapple suit
---------------------------------------------------------------------------

Uncommon.OrangutiniAnanassini = function(k: Kit): BasePart
	local PINEAPPLE = rgb(246, 184, 58)
	local SCALE = rgb(206, 132, 40)
	local LEAF = rgb(70, 160, 80)
	local FUR = rgb(214, 104, 46)
	local FACE = rgb(236, 196, 152)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.45, 0.62, 0), v3(side * 0.5, 0.22, 0), 0.38, FUR, Enum.Material.Fabric, "Legs")
		k:ellipsoid("Foot", v3(0.54, 0.24, 0.8), CFrame.new(side * 0.52, 0.12, -0.18), FACE, nil, "Legs")
	end
	local shell: Kit.Shell = { center = v3(0, 1.95, 0), radii = v3(0.98, 1.35, 0.92) }
	local body = k:ellipsoid("Pineapple", shell.radii * 2, CFrame.new(shell.center), PINEAPPLE, nil, "Body")
	-- Diamond scales, skipping the face opening
	for row = 0, 4 do
		for col = 0, 6 do
			local yaw = col * 51.4 + (row % 2) * 25.7 - 180
			local pitch = -50 + row * 22
			if not (math.abs(yaw) < 45 and pitch > -10) then
				k:ellipsoid(
					"Scale",
					v3(0.16, 0.16, 0.08),
					Kit.on(shell, yaw, pitch, 0.01) * CFrame.Angles(0, 0, math.rad(45)),
					SCALE,
					nil,
					"Body"
				)
			end
		end
	end
	for i = 0, 6 do
		local angle = i * math.pi * 2 / 7
		local out = v3(math.cos(angle), 0, math.sin(angle))
		local base = v3(0, 3.1, 0) + out * 0.2
		Parts.leaf(
			k,
			"Crown",
			base,
			base + out * 0.55 + v3(0, 1.0 + (i % 2) * 0.35, 0),
			0.34,
			0.08,
			LEAF,
			out:Cross(Vector3.yAxis),
			nil,
			"Body"
		)
	end

	-- The orangutan's face in the pineapple's opening: cheek pads, small eyes, a wide grin
	local face = Kit.on(shell, 0, 22, -0.08)
	k:ellipsoid("FurRim", v3(1.5, 1.3, 0.4), face, FUR, Enum.Material.Fabric, "Body")
	local faceShell: Kit.Shell = { center = (face * CFrame.new(0, 0, -0.08)).Position, radii = v3(0.62, 0.55, 0.3) }
	k:ellipsoid("Face", faceShell.radii * 2, CFrame.new(faceShell.center), FACE, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"CheekPad",
			v3(0.36, 0.7, 0.26),
			CFrame.new(faceShell.center + v3(side * 0.62, 0, 0.02)),
			rgb(170, 90, 50),
			nil,
			"Body"
		)
		k:ball("Nostril", 0.08, faceShell.center + v3(side * 0.08, -0.02, -0.3), rgb(110, 70, 50), nil, "Body")
	end
	k:eyes(faceShell, 28, 24, { width = 0.24, height = 0.28, iris = rgb(70, 40, 25) }, "Body")
	k:mouth(
		Kit.on(faceShell, 0, -30, 0),
		{ width = 0.56, height = 0.24, skin = FACE, style = "Grin", radius = 0.6 },
		"Body"
	)
	-- Long orangutan arms reaching almost to the floor
	Parts.bareArm(k, "ArmL", v3(-0.88, 2.2, 0), v3(-1.3, 0.75, -0.2), 0.3, FUR, 0.42)
	Parts.bareArm(k, "ArmR", v3(0.88, 2.2, 0), v3(1.45, 2.95, -0.1), 0.3, FUR, 0.42)
	return body
end

return Uncommon
