-- RARE Brainrots: bigger and more detailed than the Commons, with richer materials (chrome, bark,
-- glossy fruit) and a signature prop.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Rare: { [string]: (Kit) -> BasePart } = {}

---------------------------------------------------------------------------
-- Rhino Toasterino: a rhino built into a chrome toaster
---------------------------------------------------------------------------

Rare.RhinoToasterino = function(k: Kit): BasePart
	local CHROME = rgb(208, 214, 226)
	local TRIM = rgb(60, 62, 72)
	local RHINO = rgb(150, 152, 168)
	local HORN = rgb(238, 228, 206)
	local TOAST = rgb(232, 178, 100)
	local CRUST = rgb(168, 104, 50)

	for _, x in { -0.75, 0.75 } do
		for _, z in { -0.45, 0.45 } do
			k:limb("Leg", v3(x, 1.0, z), v3(x, 0.3, z), 0.56, RHINO, nil, "Legs")
			k:oval("Foot", CFrame.new(x, 0.12, z - 0.04), 0.62, 0.62, 0.24, rgb(118, 120, 136), nil, "Legs")
			for _, toe in { -0.16, 0, 0.16 } do
				k:ball("Toenail", 0.14, v3(x + toe, 0.14, z - 0.33), HORN, nil, "Legs")
			end
		end
	end

	-- The toaster: a chrome loaf with a black base, dial and lever, toast popping out of the top
	local toaster = CFrame.new(0, 2.0, 0.1)
	local body = Parts.roundedBox(k, "Toaster", toaster, v3(2.3, 1.7, 1.5), 0.4, CHROME, Enum.Material.Metal, "Body")
	for _, part in k.model:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Toaster" then
			part.Reflectance = 0.2
		end
	end
	k:part("ToasterBase", v3(2.36, 0.26, 1.56), toaster * CFrame.new(0, -0.78, 0), TRIM, nil, "Body")
	for _, x in { -0.5, 0.5 } do
		k:part("Slot", v3(0.9, 0.06, 0.26), toaster * CFrame.new(x, 0.86, 0), rgb(35, 35, 40), nil, "Body")
		local slice = toaster * CFrame.new(x, 1.12, 0)
		k:part("Toast", v3(0.8, 0.62, 0.14), slice, CRUST, nil, "Body")
		k:part("Toast", v3(0.68, 0.52, 0.16), slice * CFrame.new(0, 0.02, 0), TOAST, nil, "Body")
		k:cylinder(
			"Toast",
			0.14,
			0.52,
			slice * CFrame.new(-0.2, 0.3, 0) * CFrame.Angles(math.pi / 2, 0, 0),
			CRUST,
			nil,
			"Body"
		)
		k:cylinder(
			"Toast",
			0.14,
			0.52,
			slice * CFrame.new(0.2, 0.3, 0) * CFrame.Angles(math.pi / 2, 0, 0),
			CRUST,
			nil,
			"Body"
		)
	end
	k:part("Lever", v3(0.2, 0.16, 0.36), toaster * CFrame.new(1.22, 0.2, 0), TRIM, nil, "Body")
	k:ball("LeverKnob", 0.28, (toaster * CFrame.new(1.32, 0.2, 0)).Position, rgb(230, 60, 60), nil, "Body")
	k:disc("Dial", 0.34, 0.1, toaster * CFrame.new(0.72, -0.4, -0.76), TRIM, nil, "Body")
	-- Power cord for a tail, ending in a plug
	Parts.tube(
		k,
		"Cord",
		{ v3(0, 1.4, 0.85), v3(0.2, 1.05, 1.35), v3(0.5, 0.35, 1.5), v3(0.9, 0.2, 1.2) },
		{ 0.07, 0.07, 0.07, 0.07 },
		TRIM,
		nil,
		"Body",
		{ density = 3, overlap = 4 }
	)
	k:part(
		"Plug",
		v3(0.3, 0.22, 0.34),
		CFrame.new(1.02, 0.2, 1.1) * CFrame.Angles(0, math.rad(40), 0),
		rgb(240, 240, 240),
		nil,
		"Body"
	)

	-- The rhino head coming out of the front
	local head: Kit.Shell = { center = v3(0, 2.05, -0.95), radii = v3(0.8, 0.72, 0.7) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), RHINO, nil, "Body")
	local snout: Kit.Shell = { center = v3(0, 1.8, -1.45), radii = v3(0.6, 0.52, 0.55) }
	k:ellipsoid("Snout", snout.radii * 2, CFrame.new(snout.center), RHINO, nil, "Body")
	Parts.cone(k, "Horn", v3(0, 2.1, -1.7), v3(0, 2.9, -1.98), 0.27, HORN, nil, "Body")
	Parts.cone(k, "Horn", v3(0, 2.42, -1.32), v3(0, 2.86, -1.45), 0.17, HORN, nil, "Body")
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.5, 2.6, -0.85),
			v3(side * 0.78, 3.05, -0.8),
			0.34,
			0.1,
			RHINO,
			v3(side * 0.3, 0, -1).Unit,
			nil,
			"Body"
		)
		k:ellipsoid("Nostril", v3(0.14, 0.1, 0.1), Kit.on(snout, side * 24, 10, -0.02), rgb(80, 80, 95), nil, "Body")
		k:blush(Kit.on(snout, side * 50, -10, 0.02), 0.26, "Body")
	end
	k:eyes(head, 42, 16, { width = 0.3, height = 0.36, iris = rgb(50, 40, 40), lid = 0.25, skin = RHINO }, "Body")
	k:mouth(
		Kit.on(snout, 0, -28, 0),
		{ width = 0.6, height = 0.18, skin = RHINO, style = "Smile", radius = 0.55 },
		"Body"
	)
	return body
end

---------------------------------------------------------------------------
-- Brr Brr Patapim: a forest spirit, half tree and half monkey, with enormous feet
---------------------------------------------------------------------------

Rare.BrrBrrPatapim = function(k: Kit): BasePart
	local BARK = rgb(132, 90, 58)
	local BARK_DARK = rgb(96, 64, 42)
	local FACE = rgb(222, 176, 128)
	local LEAF = rgb(96, 176, 74)
	local LEAF_DARK = rgb(64, 138, 58)
	local FOOT = rgb(236, 184, 140)

	-- Huge bare feet: the thing everybody remembers
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.42, 1.5, 0.05), v3(side * 0.52, 0.45, 0.05), 0.36, BARK, Enum.Material.Wood, "Legs")
		local foot = CFrame.new(side * 0.62, 0.3, -0.4)
		k:ellipsoid("Foot", v3(1.05, 0.6, 1.8), foot, FOOT, nil, "Legs")
		for toe = 0, 4 do
			-- the big toe on the inside of each foot
			local x = side * (-0.36 + toe * 0.18)
			local size = if toe == 0 then 0.34 else 0.25 - toe * 0.012
			k:ball("Toe", size, (foot * CFrame.new(x, 0.06, -0.86 + toe * 0.03)).Position, FOOT, nil, "Legs")
		end
	end

	-- A trunk for a body, with bark grooves
	local trunk: Kit.Shell = { center = v3(0, 2.35, 0), radii = v3(0.78, 1.15, 0.72) }
	local body = k:ellipsoid("Trunk", trunk.radii * 2, CFrame.new(trunk.center), BARK, Enum.Material.Wood, "Body")
	for i, yaw in { -150, -110, -70, 70, 110, 150, 180 } do
		Parts.patch(k, "Bark", trunk, yaw, -8 + (i % 3) * 8, 0.1, 1.4, BARK_DARK, Enum.Material.Wood, "Body")
	end
	-- Twig arms with leaves for hands
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder = v3(side * 0.68, 2.7, 0)
		local elbow = v3(side * 1.25, 2.3, -0.2)
		local hand = v3(side * 1.55, if side < 0 then 1.85 else 3.0, -0.35)
		k:limb("Branch", shoulder, elbow, 0.22, BARK, Enum.Material.Wood, rig)
		k:limb("Branch", elbow, hand, 0.18, BARK, Enum.Material.Wood, rig)
		for i = -1, 1 do
			local out = (hand - elbow).Unit
			Parts.leaf(
				k,
				"Leaf",
				hand,
				hand + out * 0.45 + v3(0, i * 0.25, i * 0.12),
				0.26,
				0.05,
				LEAF,
				v3(0, 0, -1),
				nil,
				rig
			)
		end
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end

	-- Monkey face with a long drooping nose
	local head: Kit.Shell = { center = v3(0, 3.55, -0.12), radii = v3(0.78, 0.72, 0.7) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), BARK, Enum.Material.Wood, "Body")
	local face: Kit.Shell = { center = v3(0, 3.45, -0.42), radii = v3(0.6, 0.55, 0.45) }
	k:ellipsoid("Face", face.radii * 2, CFrame.new(face.center), FACE, nil, "Body")
	k:eyes(face, 26, 22, { width = 0.28, height = 0.34, iris = rgb(60, 40, 25), lid = 0.2, skin = FACE }, "Body")
	Parts.tube(
		k,
		"Nose",
		{ v3(0, 3.5, -0.82), v3(0, 3.25, -1.05), v3(0, 2.95, -1.06) },
		{ 0.16, 0.22, 0.26 },
		rgb(214, 140, 110),
		nil,
		"Body",
		{ density = 1, overlap = 4 }
	)
	k:mouth(
		Kit.on(face, 0, -40, 0),
		{ width = 0.46, height = 0.14, skin = FACE, style = "Smile", radius = 0.5 },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ball("Ear", 0.34, v3(side * 0.74, 3.55, -0.05), FACE, nil, "Body")
	end
	-- Leafy canopy for hair
	for i = 0, 8 do
		local angle = i * math.pi * 2 / 9
		local ring = if i % 2 == 0 then 0.55 else 0.35
		k:ball(
			"Canopy",
			0.62 + (i % 3) * 0.08,
			v3(math.cos(angle) * ring, 4.2 + (i % 3) * 0.12, math.sin(angle) * ring + 0.05),
			if i % 3 == 0 then LEAF_DARK else LEAF,
			Enum.Material.Grass,
			"Body"
		)
	end
	k:ball("Canopy", 0.8, v3(0, 4.45, 0.05), LEAF, Enum.Material.Grass, "Body")
	return body
end

---------------------------------------------------------------------------
-- Glorbo Fruttodrillo: a crocodile living in a watermelon
---------------------------------------------------------------------------

Rare.GlorboFruttodrillo = function(k: Kit): BasePart
	local RIND = rgb(132, 204, 104)
	local STRIPE = rgb(36, 104, 48)
	local FLESH = rgb(246, 84, 96)
	local CROC = rgb(96, 164, 84)
	local CROC_BELLY = rgb(206, 226, 150)

	local shell: Kit.Shell = { center = v3(0, 1.75, 0.3), radii = v3(1.3, 1.22, 1.4) }
	local body = k:ellipsoid("Watermelon", shell.radii * 2, CFrame.new(shell.center), RIND, nil, "Body")
	for i = 0, 7 do
		local yaw = i * 45 + 22.5
		if math.abs(((yaw + 180) % 360) - 180) > 40 then
			Parts.patch(k, "MelonStripe", shell, yaw, 0, 0.5, 2.55, STRIPE, nil, "Body")
		end
	end
	-- A slice missing from the top: red flesh with seeds where the croc's back pokes out
	local top = CFrame.new(shell.center + v3(0, 1.12, 0.2))
	k:oval("MelonRindCut", top, 1.5, 1.6, 0.12, rgb(240, 250, 220), nil, "Body")
	k:oval("MelonFlesh", top * CFrame.new(0, 0.03, 0), 1.3, 1.4, 0.14, FLESH, nil, "Body")
	for s = 0, 5 do
		local angle = s * math.pi * 2 / 6 + 0.3
		k:ellipsoid(
			"Seed",
			v3(0.09, 0.06, 0.15),
			top * CFrame.new(math.cos(angle) * 0.42, 0.1, math.sin(angle) * 0.45),
			rgb(30, 25, 25),
			nil,
			"Body"
		)
	end

	-- The crocodile: long toothy snout out the front, eyes on top, legs and a ridged tail
	local head: Kit.Shell = { center = v3(0, 2.1, -1.0), radii = v3(0.72, 0.6, 0.62) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CROC, nil, "Body")
	k:loft("Snout", {
		{ at = v3(0, 2.0, -1.2), w = 0.66, h = 0.42 },
		{ at = v3(0, 1.92, -1.9), w = 0.5, h = 0.3 },
		{ at = v3(0, 1.9, -2.3), w = 0.42, h = 0.26 },
	}, CROC, nil, "Body", { density = 1, overlap = 5 })
	k:loft("Jaw", {
		{ at = v3(0, 1.72, -1.2), w = 0.6, h = 0.26 },
		{ at = v3(0, 1.66, -2.2), w = 0.38, h = 0.16 },
	}, CROC_BELLY, nil, "Body", { density = 1, overlap = 5 })
	for _, side in { -1, 1 } do
		for i = 0, 4 do
			local z = -1.45 - i * 0.2
			local x = side * (0.5 - i * 0.03)
			k:tooth(CFrame.lookAt(v3(x, 1.8, z), v3(x * 3, 1.8, z)), 0.14, 0.2, nil, "Body")
		end
		k:ball("Nostril", 0.12, v3(side * 0.13, 2.14, -2.4), rgb(60, 110, 60), nil, "Body")
		local bump: Kit.Shell = { center = v3(side * 0.34, 2.62, -1.12), radii = v3(0.26, 0.24, 0.26) }
		k:ellipsoid("EyeBump", bump.radii * 2, CFrame.new(bump.center), CROC, nil, "Body")
		k:eye(
			Kit.on(bump, side * 10, 8, -0.05),
			{ width = 0.3, height = 0.32, iris = rgb(230, 190, 40), lid = 0.2, skin = CROC, side = side },
			"Body"
		)
		for _, z in { -0.6, 0.9 } do
			k:limb("Leg", v3(side * 0.95, 1.0, z), v3(side * 1.25, 0.2, z - 0.1), 0.4, CROC, nil, "Legs")
			for toe = -1, 1 do
				k:ball("Claw", 0.16, v3(side * 1.27 + toe * 0.12, 0.08, z - 0.36), CROC_BELLY, nil, "Legs")
			end
		end
	end
	Parts.tube(
		k,
		"Tail",
		{ v3(0, 1.25, 1.4), v3(0.3, 0.7, 2.1), v3(0.8, 0.35, 2.6), v3(1.3, 0.25, 2.8) },
		{ 0.42, 0.32, 0.2, 0.08 },
		CROC,
		nil,
		"Body",
		{ density = 1.2, overlap = 5 }
	)
	return body
end

---------------------------------------------------------------------------
-- Blueberrini Octopussini: a blueberry octopus
---------------------------------------------------------------------------

Rare.BlueberriniOctopussini = function(k: Kit): BasePart
	local BERRY = rgb(76, 92, 196)
	local BLOOM = rgb(128, 146, 226)
	local CALYX = rgb(46, 56, 128)
	local SUCKER = rgb(186, 196, 250)

	local shell: Kit.Shell = { center = v3(0, 2.55, 0), radii = v3(1.18, 1.12, 1.12) }
	local body = k:ellipsoid("Berry", shell.radii * 2, CFrame.new(shell.center), BERRY, nil, "Body")
	for i = 1, 10 do
		local yaw = ((i * 137.5) % 360) - 180
		local pitch = 10 + (i * 29) % 60
		if not (math.abs(yaw) < 45 and pitch < 40) then
			Parts.patch(k, "Bloom", shell, yaw, pitch, 0.4, 0.3, BLOOM, nil, "Body", i * 30)
		end
	end
	-- The blueberry's star-shaped crown on top
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		local out = v3(math.cos(angle), 0, math.sin(angle))
		local base = v3(0, 3.7, 0) + out * 0.38
		k:ellipsoid(
			"Calyx",
			v3(0.4, 0.1, 0.7),
			CFrame.lookAt(base, base + out) * CFrame.Angles(math.rad(-20), 0, 0),
			CALYX,
			nil,
			"Body"
		)
	end
	k:oval("CalyxCenter", CFrame.new(0, 3.66, 0), 0.5, 0.5, 0.2, CALYX, nil, "Body")
	k:ellipsoid(
		"Leaf",
		v3(0.9, 0.08, 0.42),
		CFrame.new(0.45, 3.9, 0.2) * CFrame.Angles(0, math.rad(-15), math.rad(20)),
		rgb(90, 170, 80),
		nil,
		"Body"
	)

	k:eyes(shell, 26, -2, { width = 0.46, height = 0.56, iris = rgb(40, 30, 80) }, "Body")
	k:mouth(
		Kit.on(shell, 0, -26, 0),
		{ width = 0.46, height = 0.2, skin = BERRY, style = "Grin", radius = 1.1 },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:blush(Kit.on(shell, side * 44, -16, 0.02), 0.32, "Body")
	end

	-- Eight curling tentacles
	for i = 0, 7 do
		local angle = i * math.pi * 2 / 8 + math.pi / 8
		local out = v3(math.sin(angle), 0, -math.cos(angle))
		local curl = if i % 2 == 0 then 1 else -1
		local side = out:Cross(Vector3.yAxis) * curl
		local points = {
			v3(0, 1.8, 0) + out * 0.6,
			v3(0, 0.75, 0) + out * 1.0,
			v3(0, 0.25, 0) + out * 1.5,
			v3(0, 0.45, 0) + out * 2.0 + side * 0.25,
			v3(0, 0.85, 0) + out * 1.9 + side * 0.4,
		}
		local rig = if math.sin(angle) < -0.5 then "ArmL" elseif math.sin(angle) > 0.5 then "ArmR" else "Body"
		Parts.tube(
			k,
			"Tentacle",
			points,
			{ 0.32, 0.26, 0.2, 0.15, 0.1 },
			BERRY,
			nil,
			rig,
			{ density = 2, overlap = 7, maxSteps = 2 }
		)
		k:ball("Sucker", 0.14, points[3] + v3(0, -0.12, 0) + out * 0.05, SUCKER, nil, rig)
	end
	k.model:SetAttribute("ArmLJoint", v3(-0.8, 1.8, 0))
	k.model:SetAttribute("ArmRJoint", v3(0.8, 1.8, 0))
	return body
end

---------------------------------------------------------------------------
-- Spioniro Golubiro: a pigeon spy in a trench coat
---------------------------------------------------------------------------

Rare.SpioniroGolubiro = function(k: Kit): BasePart
	local PIGEON = rgb(150, 156, 178)
	local NECK = rgb(96, 168, 150)
	local COAT = rgb(196, 156, 98)
	local COAT_DARK = rgb(150, 112, 64)
	local HAT = rgb(58, 54, 62)

	Parts.birdLegs(k, 0.95, 0.38, rgb(236, 124, 112))
	local shell: Kit.Shell = { center = v3(0, 1.95, 0.05), radii = v3(0.95, 1.1, 0.95) }
	local body = k:ellipsoid("Coat", shell.radii * 2, CFrame.new(shell.center), COAT, Enum.Material.Fabric, "Body")
	k:ellipsoid("CoatHem", v3(2.0, 0.6, 1.95), CFrame.new(0, 1.12, 0.05), COAT, Enum.Material.Fabric, "Body")
	k:band("Belt", shell, 1.75, 0.18, COAT_DARK, Enum.Material.Leather, "Body")
	k:part("Buckle", v3(0.26, 0.24, 0.06), Kit.on(shell, 0, -9, 0.02), rgb(220, 180, 80), Enum.Material.Metal, "Body")
	for _, side in { -1, 1 } do
		Parts.leaf(
			k,
			"Lapel",
			v3(side * 0.2, 2.8, -0.75),
			v3(side * 0.42, 2.05, -0.9),
			0.46,
			0.08,
			COAT_DARK,
			v3(0, 0.1, -1).Unit,
			Enum.Material.Fabric,
			"Body"
		)
		for i = 0, 1 do
			k:ball("Button", 0.12, (Kit.surface(shell, side * 20, 8 - i * 28)), rgb(80, 60, 40), nil, "Body")
		end
	end

	-- Pigeon head: shiny green neck, orange eyes behind spy shades, a fedora
	local head: Kit.Shell = { center = v3(0, 3.32, -0.1), radii = v3(0.64, 0.6, 0.62) }
	k:band("Neck", shell, 2.92, 0.32, NECK, Enum.Material.SmoothPlastic, "Body")
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), PIGEON, nil, "Body")
	Parts.cone(k, "Beak", v3(0, 3.2, -0.62), v3(0, 3.05, -1.05), 0.14, rgb(236, 172, 64), nil, "Body")
	k:ellipsoid("Cere", v3(0.18, 0.1, 0.16), CFrame.new(0, 3.3, -0.66), C.White, nil, "Body")
	Parts.sunglasses(k, head, 30, 12, 0.42, nil, nil, "Body")
	k:oval(
		"HatBrim",
		CFrame.new(0, 3.8, -0.05) * CFrame.Angles(math.rad(-8), 0, 0),
		1.7,
		1.6,
		0.08,
		HAT,
		Enum.Material.Fabric,
		"Body"
	)
	k:ellipsoid("HatCrown", v3(0.98, 0.66, 0.92), CFrame.new(0, 4.06, -0.02), HAT, Enum.Material.Fabric, "Body")
	k:oval("HatBand", CFrame.new(0, 3.9, -0.02), 1.0, 0.94, 0.12, rgb(170, 50, 50), Enum.Material.Fabric, "Body")

	-- Wing-arms in coat sleeves; one holds a magnifying glass up to its face
	Parts.arm(k, "ArmL", v3(-0.88, 2.5, 0), v3(-1.3, 1.7, -0.25), 0.36, COAT, PIGEON, 0.36)
	Parts.arm(k, "ArmR", v3(0.88, 2.5, 0), v3(0.95, 2.95, -0.75), 0.36, COAT, PIGEON, 0.36)
	local lens = CFrame.new(0.72, 3.45, -1.05) * CFrame.Angles(0, math.rad(-15), 0)
	k:limb(
		"GlassHandle",
		v3(0.95, 2.95, -0.8),
		(lens * CFrame.new(0, -0.3, 0)).Position,
		0.1,
		rgb(90, 60, 40),
		Enum.Material.Wood,
		"ArmR"
	)
	Parts.ring(
		k,
		"GlassRim",
		lens * CFrame.Angles(math.pi / 2, 0, 0),
		0.3,
		0.07,
		rgb(220, 180, 80),
		Enum.Material.Metal,
		"ArmR",
		10
	)
	local glass = k:disc("Glass", 0.56, 0.03, lens, rgb(200, 235, 255), Enum.Material.Glass, "ArmR")
	glass.Transparency = 0.4
	glass:SetAttribute("KeepColor", true)
	return body
end

return Rare
