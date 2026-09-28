-- MYTHIC Brainrots: big, busy silhouettes with moving parts (propellers, claws, steam) and the most
-- detailed costumes below the Divine tier.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Mythic: { [string]: (Kit) -> BasePart } = {}

-- A three-bladed propeller with a spinner, facing along `forward`.
local function propeller(k: Kit, hub: Vector3, forward: Vector3, size: number, rig: string)
	local frame = CFrame.lookAt(hub, hub + forward)
	Parts.cone(k, "Spinner", hub, hub + forward * size * 0.45, size * 0.2, rgb(220, 60, 50), nil, rig)
	for i = 0, 2 do
		k:ellipsoid(
			"PropBlade",
			v3(size * 0.2, size * 1.05, size * 0.05),
			frame
				* CFrame.Angles(0, 0, i * math.pi * 2 / 3)
				* CFrame.new(0, size * 0.5, 0)
				* CFrame.Angles(0, math.rad(20), 0),
			rgb(60, 58, 60),
			nil,
			rig
		)
	end
end

---------------------------------------------------------------------------
-- Bombardiro Crocodilo: a crocodile who is also a bomber plane
---------------------------------------------------------------------------

Mythic.BombardiroCrocodilo = function(k: Kit): BasePart
	local CROC = rgb(94, 138, 72)
	local CROC_DARK = rgb(64, 102, 52)
	local BELLY = rgb(214, 220, 160)
	local PLANE = rgb(118, 128, 82)
	local PLANE_DARK = rgb(84, 92, 60)

	-- Stubby crocodile legs as landing gear
	for _, spec in { { -0.75, -1.4 }, { 0.75, -1.4 }, { -0.6, 1.3 }, { 0.6, 1.3 } } do
		local x, z = spec[1], spec[2]
		k:limb("Leg", v3(x * 0.8, 1.45, z), v3(x, 0.35, z - 0.1), 0.5, CROC, nil, "Legs")
		for toe = -1, 1, 2 do
			k:ball("Claw", 0.18, v3(x + toe * 0.1, 0.1, z - 0.42), BELLY, nil, "Legs")
		end
		k:ellipsoid("Foot", v3(0.56, 0.28, 0.7), CFrame.new(x, 0.14, z - 0.25), CROC, nil, "Legs")
	end

	-- Fuselage: the crocodile's body, olive with a pale belly and a row of back scutes
	local body = k:loft("Fuselage", {
		{ at = v3(0, 2.75, -1.9), w = 0.85, h = 0.72 },
		{ at = v3(0, 2.8, -0.6), w = 1.0, h = 0.85 },
		{ at = v3(0, 2.85, 1.0), w = 0.85, h = 0.72 },
		{ at = v3(0, 3.0, 2.5), w = 0.45, h = 0.42 },
		{ at = v3(0, 3.2, 3.6), w = 0.18, h = 0.2 },
	}, CROC, nil, "Body", { density = 1.2, overlap = 7 })
	k:loft("Belly", {
		{ at = v3(0, 2.5, -1.9), w = 0.84, h = 0.5 },
		{ at = v3(0, 2.52, -0.6), w = 0.99, h = 0.62 },
		{ at = v3(0, 2.6, 1.0), w = 0.84, h = 0.52 },
		{ at = v3(0, 2.82, 2.5), w = 0.44, h = 0.3 },
	}, BELLY, nil, "Body", { density = 1.2, overlap = 7 })
	for i = 0, 6 do
		local z = -1.2 + i * 0.62
		local y = 3.62 - math.max(0, z - 0.5) * 0.18
		k:ellipsoid(
			"Scute",
			v3(0.16, 0.34, 0.36),
			CFrame.new(0, y, z) * CFrame.Angles(math.rad(-20), 0, 0),
			CROC_DARK,
			nil,
			"Body"
		)
	end
	local canopy = k:ellipsoid(
		"Cockpit",
		v3(0.9, 0.6, 1.2),
		CFrame.new(0, 3.55, -0.95),
		rgb(140, 210, 250),
		Enum.Material.Glass,
		"Body"
	)
	canopy.Transparency = 0.2
	canopy:SetAttribute("KeepColor", true)

	-- Bomber wings with an engine and propeller on each, a roundel near the tips
	for _, side in { -1, 1 } do
		k:loft("Wing", {
			{ at = v3(side * 0.8, 2.85, -0.4), w = 0.14, h = 0.8 },
			{ at = v3(side * 2.6, 2.95, -0.25), w = 0.11, h = 0.66 },
			{ at = v3(side * 3.6, 3.0, -0.15), w = 0.07, h = 0.42 },
		}, PLANE, Enum.Material.Metal, "Body", { up = v3(0, 0, -1), density = 0.8, overlap = 4 })
		local engine = v3(side * 1.8, 2.72, -0.75)
		k:loft("Engine", {
			{ at = engine + v3(0, 0, -0.5), w = 0.32, h = 0.32 },
			{ at = engine + v3(0, 0, 0.5), w = 0.26, h = 0.26 },
		}, PLANE_DARK, Enum.Material.Metal, "Body", { density = 1, overlap = 4 })
		propeller(k, engine + v3(0, 0, -0.78), v3(0, 0, -1), 1.3, "Body")
		local roundel = CFrame.new(side * 3.0, 3.03, -0.2) * CFrame.Angles(math.pi / 2, 0, 0)
		k:disc("Roundel", 0.62, 0.04, roundel, rgb(255, 214, 60), nil, "Body")
		k:disc("Roundel", 0.3, 0.05, roundel * CFrame.new(0, 0, -0.015), rgb(220, 60, 50), nil, "Body")
		-- Confetti bombs under the wings
		local bomb = v3(side * 1.2, 2.05, 0.15)
		k:loft("Bomb", {
			{ at = bomb + v3(0, 0, -0.45), w = 0.12, h = 0.12 },
			{ at = bomb, w = 0.26, h = 0.26 },
			{ at = bomb + v3(0, 0, 0.42), w = 0.13, h = 0.13 },
		}, rgb(236, 90, 150), nil, "Body", { density = 1.5, overlap = 4, maxSteps = 2 })
		for _, fin in { v3(0.6, 0.03, 0.22), v3(0.03, 0.6, 0.22) } do
			k:part("BombFin", fin, CFrame.new(bomb + v3(0, 0, 0.5)), rgb(255, 214, 60), nil, "Body")
		end
	end
	-- Tail plane and fin
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Stabilizer",
			v3(1.4, 0.1, 0.62),
			CFrame.new(side * 0.8, 3.18, 3.42) * CFrame.Angles(0, math.rad(side * 18), 0),
			PLANE,
			Enum.Material.Metal,
			"Body"
		)
	end
	Parts.leaf(
		k,
		"TailFin",
		v3(0, 3.3, 3.1),
		v3(0, 4.35, 3.7),
		0.8,
		0.08,
		PLANE,
		Vector3.xAxis,
		Enum.Material.Metal,
		"Body"
	)

	-- Crocodile head at the nose: long toothy snout, eyes on top, nostrils
	local head: Kit.Shell = { center = v3(0, 2.9, -2.1), radii = v3(0.82, 0.7, 0.7) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CROC, nil, "Body")
	k:loft("Snout", {
		{ at = v3(0, 2.85, -2.4), w = 0.72, h = 0.44 },
		{ at = v3(0, 2.78, -3.2), w = 0.55, h = 0.32 },
		{ at = v3(0, 2.76, -3.75), w = 0.46, h = 0.28 },
	}, CROC, nil, "Body", { density = 1, overlap = 5 })
	k:loft("Jaw", {
		{ at = v3(0, 2.52, -2.3), w = 0.66, h = 0.26 },
		{ at = v3(0, 2.46, -3.6), w = 0.4, h = 0.16 },
	}, BELLY, nil, "Body", { density = 1, overlap = 5 })
	for _, side in { -1, 1 } do
		for i = 0, 5 do
			local z = -2.6 - i * 0.2
			local x = side * (0.58 - i * 0.03)
			k:tooth(CFrame.lookAt(v3(x, 2.64, z), v3(x * 3, 2.64, z)), 0.14, 0.2, nil, "Body")
		end
		k:ball("Nostril", 0.14, v3(side * 0.15, 3.0, -3.85), CROC_DARK, nil, "Body")
		local bump: Kit.Shell = { center = v3(side * 0.38, 3.45, -2.2), radii = v3(0.28, 0.26, 0.28) }
		k:ellipsoid("EyeBump", bump.radii * 2, CFrame.new(bump.center), CROC, nil, "Body")
		k:eye(
			Kit.on(bump, side * 10, 8, -0.05),
			{ width = 0.32, height = 0.34, iris = rgb(236, 190, 40), lid = 0.3, lidTilt = 14, skin = CROC, side = side },
			"Body"
		)
	end
	Parts.leaf(
		k,
		"Scarf",
		v3(0.3, 3.1, -1.5),
		v3(1.2, 3.35, -0.6),
		0.36,
		0.06,
		rgb(236, 236, 240),
		Vector3.yAxis,
		Enum.Material.Fabric,
		"Body"
	)

	-- Sit the whole plane lower on its stubby legs
	for _, part in k.model:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("Rig") == "Body" then
			part.CFrame += v3(0, -0.6, 0)
		end
	end
	k:turn(-38)
	return body[2]
end

---------------------------------------------------------------------------
-- Chef Crabracadabra: a magic crab chef
---------------------------------------------------------------------------

Mythic.ChefCrabracadabra = function(k: Kit): BasePart
	local CRAB = rgb(236, 82, 60)
	local CRAB_LIGHT = rgb(255, 170, 130)
	local HAT = rgb(252, 252, 250)
	local SCARF = rgb(60, 120, 220)
	local WOOD = rgb(200, 150, 90)

	-- Six little legs
	for _, side in { -1, 1 } do
		for i = 0, 2 do
			local z = -0.5 + i * 0.5
			local hip = v3(side * 1.0, 1.5, z)
			local knee = v3(side * 1.65, 1.4, z * 1.2)
			k:limb("Leg", hip, knee, 0.22, CRAB, nil, "Legs")
			k:limb("Leg", knee, v3(side * 1.9, 0.1, z * 1.3), 0.18, CRAB, nil, "Legs")
		end
	end
	local shell: Kit.Shell = { center = v3(0, 1.85, 0), radii = v3(1.35, 0.85, 1.0) }
	local body = k:ellipsoid("Shell", shell.radii * 2, CFrame.new(shell.center), CRAB, nil, "Body")
	Parts.patch(k, "Belly", shell, 0, -40, 1.6, 0.8, CRAB_LIGHT, nil, "Body")
	for i = 1, 8 do
		local yaw = ((i * 137.5) % 360) - 180
		if math.abs(yaw) > 40 then
			Parts.patch(k, "ShellSpot", shell, yaw, 20 + (i % 3) * 12, 0.24, 0.2, CRAB_LIGHT, nil, "Body")
		end
	end

	-- Eyes on stalks, a curly mustache and a big smile
	for _, side in { -1, 1 } do
		local top = v3(side * 0.42, 3.35, -0.55)
		k:limb("Stalk", v3(side * 0.3, 2.5, -0.55), top, 0.16, CRAB, nil, "Body")
		local eyeball: Kit.Shell = { center = top, radii = v3(0.28, 0.3, 0.28) }
		k:eye(
			Kit.on(eyeball, side * 6, 4, -0.08),
			{ width = 0.46, height = 0.5, iris = rgb(40, 30, 30), lid = 0.2, skin = CRAB, side = side },
			"Body"
		)
		k:ellipsoid("EyeBack", eyeball.radii * 2, CFrame.new(top + v3(0, 0, 0.08)), CRAB, nil, "Body")
		Parts.tube(k, "Mustache", {
			v3(side * 0.05, 2.0, -1.0),
			v3(side * 0.38, 1.98, -1.02),
			v3(side * 0.62, 2.1, -0.95),
			v3(side * 0.62, 2.28, -0.92),
		}, { 0.13, 0.12, 0.09, 0.06 }, rgb(60, 40, 36), nil, "Body", { density = 1.2, overlap = 4 })
	end
	k:mouth(Kit.on(shell, 0, -25, 0), { width = 0.7, height = 0.26, skin = CRAB, style = "Grin", radius = 1.1 }, "Body")

	-- A tall chef's hat and a neckerchief
	k:cylinder("HatBand", 0.6, 1.25, CFrame.new(0, 2.85, 0.05), HAT, Enum.Material.Fabric, "Body")
	for i = 0, 5 do
		local angle = i * math.pi * 2 / 6
		k:ball(
			"HatPuff",
			0.72,
			v3(math.cos(angle) * 0.42, 3.55, math.sin(angle) * 0.42 + 0.05),
			HAT,
			Enum.Material.Fabric,
			"Body"
		)
	end
	k:ball("HatPuff", 0.9, v3(0, 3.72, 0.05), HAT, Enum.Material.Fabric, "Body")
	Parts.leaf(
		k,
		"Neckerchief",
		v3(0, 2.2, -0.92),
		v3(0, 1.72, -1.08),
		0.5,
		0.08,
		SCARF,
		v3(0, 0.2, -1).Unit,
		Enum.Material.Fabric,
		"Body"
	)

	-- Two big claws: one holds a wooden spoon that doubles as a magic wand
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder = v3(side * 1.1, 2.1, -0.4)
		local elbow = v3(side * 1.85, 2.45, -0.75)
		local claw = if side < 0 then v3(-2.05, 3.1, -1.05) else v3(2.1, 2.2, -1.2)
		k:limb("Arm", shoulder, elbow, 0.3, CRAB, nil, rig)
		k:limb("Arm", elbow, claw, 0.34, CRAB, nil, rig)
		local frame = CFrame.lookAt(claw, claw + (claw - elbow).Unit)
		k:ellipsoid("Pincer", v3(0.62, 0.42, 0.95), frame * CFrame.new(0, -0.08, -0.35), CRAB, nil, rig)
		k:ellipsoid(
			"PincerTop",
			v3(0.36, 0.26, 0.8),
			frame * CFrame.new(0, 0.26, -0.45) * CFrame.Angles(math.rad(18), 0, 0),
			CRAB,
			nil,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	local grip = v3(2.1, 2.3, -1.55)
	k:limb("Spoon", grip + v3(0, -0.4, 0.1), grip + v3(0.05, 1.3, -0.25), 0.12, WOOD, Enum.Material.Wood, "ArmR")
	k:ellipsoid(
		"SpoonBowl",
		v3(0.4, 0.55, 0.14),
		CFrame.new(grip + v3(0.06, 1.55, -0.3)),
		WOOD,
		Enum.Material.Wood,
		"ArmR"
	)
	local sparkle = grip + v3(0.06, 2.05, -0.35)
	for i = 0, 3 do
		k:ellipsoid(
			"Sparkle",
			v3(0.5, 0.08, 0.08),
			CFrame.new(sparkle) * CFrame.Angles(0, 0, i * math.pi / 4),
			rgb(255, 230, 120),
			Enum.Material.Neon,
			"ArmR"
		)
	end
	return body
end

---------------------------------------------------------------------------
-- Espressona Signora: a grandma taking a bath in an espresso cup
---------------------------------------------------------------------------

Mythic.EspressonaSignora = function(k: Kit): BasePart
	local CUP = rgb(250, 246, 240)
	local SAUCER = rgb(236, 232, 226)
	local GOLD = rgb(210, 180, 90)
	local DRESS = rgb(140, 70, 150)
	local HAIR = rgb(220, 222, 230)
	local FACE = rgb(242, 204, 176)

	k:oval("Saucer", CFrame.new(0, 0.12, 0), 3.4, 3.4, 0.24, SAUCER, nil, "Body")
	k:oval("SaucerRing", CFrame.new(0, 0.26, 0), 2.1, 2.1, 0.06, GOLD, Enum.Material.Metal, "Body")
	Parts.cup(k, v3(0, 1.0, 0), 1.35, 1.3, { color = CUP, coffee = rgb(80, 46, 28), foam = rgb(196, 140, 90) })
	local body = k.model:FindFirstChild("Cup") :: BasePart
	Parts.handle(k, "CupHandle", v3(1.22, 2.0, 0), v3(1.22, 1.2, 0), v3(0.3, 0, 0), 0.2, CUP, nil, "Body")
	k:oval("CupStripe", CFrame.new(0, 2.05, 0), 2.64, 2.64, 0.14, GOLD, Enum.Material.Metal, "Body")

	-- Grandma sitting in the espresso: shoulders in a purple dress, pearls, curlers and glasses
	local torso: Kit.Shell = { center = v3(0, 2.75, 0.05), radii = v3(0.78, 0.55, 0.62) }
	k:ellipsoid("Dress", torso.radii * 2, CFrame.new(torso.center), DRESS, Enum.Material.Fabric, "Body")
	for i = 0, 8 do
		local angle = math.rad(-80 + i * 20)
		local pearl = v3(math.sin(angle) * 0.36, 3.2 - math.cos(angle) * 0.1, -math.cos(angle) * 0.34)
		k:ball("Pearl", 0.12, pearl, rgb(255, 250, 240), nil, "Body")
	end
	local head: Kit.Shell = { center = v3(0, 3.72, -0.05), radii = v3(0.66, 0.64, 0.62) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), FACE, nil, "Body")
	k:ellipsoid("Hair", v3(1.42, 0.9, 1.38), CFrame.new(0, 4.02, 0.08), HAIR, Enum.Material.Fabric, "Body")
	k:ball("HairBun", 0.72, v3(0, 4.52, 0.2), HAIR, Enum.Material.Fabric, "Body")
	for i = 0, 3 do
		k:cylinder(
			"Curler",
			0.42,
			0.22,
			CFrame.new(-0.45 + i * 0.3, 4.3, -0.42) * CFrame.Angles(0, 0, math.pi / 2),
			if i % 2 == 0 then rgb(255, 130, 170) else rgb(120, 200, 255),
			nil,
			"Body"
		)
	end
	for _, side in { -1, 1 } do
		local lens = Kit.on(head, side * 26, 6, 0.08)
		Parts.ring(
			k,
			"GlassesRim",
			lens * CFrame.Angles(math.pi / 2, 0, 0),
			0.2,
			0.05,
			GOLD,
			Enum.Material.Metal,
			"Body",
			8
		)
		k:ball("Earring", 0.14, (Kit.surface(head, side * 88, -20)), rgb(255, 250, 240), nil, "Body")
		k:blush(Kit.on(head, side * 38, -14, 0.02), 0.28, "Body")
	end
	k:part("GlassesBridge", v3(0.2, 0.05, 0.05), Kit.on(head, 0, 8, 0.1), GOLD, Enum.Material.Metal, "Body")
	k:eyes(head, 26, 6, { width = 0.24, height = 0.26, iris = rgb(80, 60, 50), lid = 0.2, skin = FACE }, "Body")
	k:mouth(
		Kit.on(head, 0, -24, 0),
		{ width = 0.34, height = 0.14, skin = FACE, style = "Smile", radius = 0.66 },
		"Body"
	)

	-- Arms resting on the rim, one lifting a tiny espresso spoon
	Parts.arm(k, "ArmL", v3(-0.72, 2.9, 0), v3(-1.35, 2.5, -0.3), 0.3, DRESS, FACE, 0.3)
	Parts.arm(k, "ArmR", v3(0.72, 2.9, 0), v3(1.05, 3.55, -0.55), 0.3, DRESS, FACE, 0.3)
	k:limb("Spoon", v3(1.05, 3.5, -0.55), v3(1.25, 4.15, -0.7), 0.07, rgb(210, 214, 224), Enum.Material.Metal, "ArmR")
	k:ellipsoid(
		"SpoonBowl",
		v3(0.2, 0.3, 0.08),
		CFrame.new(1.28, 4.25, -0.72),
		rgb(210, 214, 224),
		Enum.Material.Metal,
		"ArmR"
	)
	-- Steam curling up from the coffee
	for i = 0, 2 do
		local x = -0.7 + i * 0.25
		local steam = Parts.tube(
			k,
			"Steam",
			{ v3(x, 2.5, 0.7), v3(x + 0.15, 2.9, 0.75), v3(x - 0.1, 3.3, 0.8), v3(x + 0.08, 3.7, 0.85) },
			{ 0.08, 0.1, 0.08, 0.04 },
			C.White,
			nil,
			"Body",
			{ density = 2, overlap = 4 }
		)
		for _, puff in steam do
			puff.Transparency = 0.45
			puff.CastShadow = false
		end
	end
	return body
end

---------------------------------------------------------------------------
-- Frigo Camelo: a camel living in a fridge
---------------------------------------------------------------------------

Mythic.FrigoCamelo = function(k: Kit): BasePart
	local FRIDGE = rgb(172, 226, 206)
	local TRIM = rgb(118, 176, 160)
	local CHROME = rgb(215, 222, 232)
	local CAMEL = rgb(214, 170, 110)
	local CAMEL_DARK = rgb(170, 124, 72)
	local BOOT = rgb(120, 76, 48)
	local ICE = rgb(190, 232, 255)
	local SCARF = rgb(230, 60, 60)

	for _, x in { -0.62, 0.62 } do
		for _, z in { -0.5, 0.5 } do
			local hip, knee, ankle = v3(x, 2.0, z), v3(x, 1.2, z - 0.08), v3(x, 0.5, z)
			k:limb("Leg", hip, knee, 0.34, CAMEL, nil, "Legs")
			k:ball("Knee", 0.36, knee, CAMEL_DARK, nil, "Legs")
			k:limb("Leg", knee, ankle, 0.28, CAMEL, nil, "Legs")
			k:oval("Boot", CFrame.new(x, 0.35, z - 0.04), 0.5, 0.56, 0.62, BOOT, Enum.Material.Leather, "Legs")
			k:oval(
				"BootFur",
				CFrame.new(x, 0.7, z - 0.04),
				0.56,
				0.6,
				0.14,
				rgb(250, 246, 236),
				Enum.Material.Fabric,
				"Legs"
			)
			k:oval(
				"BootSole",
				CFrame.new(x, 0.05, z - 0.08),
				0.56,
				0.66,
				0.1,
				rgb(60, 50, 44),
				Enum.Material.Rubber,
				"Legs"
			)
		end
	end

	-- A rounded retro fridge in pastel mint: freezer door line, chrome handles, magnets, icicles
	local fridge = CFrame.new(0, 3.35, 0)
	local size = v3(2.1, 2.8, 1.6)
	local body = Parts.roundedBox(
		k,
		"Fridge",
		fridge * CFrame.Angles(0, math.pi / 2, 0),
		v3(size.Z, size.Y, size.X),
		0.5,
		FRIDGE,
		nil,
		"Body"
	)
	local front = -size.Z / 2
	k:part("FreezerLine", v3(size.X - 0.1, 0.05, 0.02), fridge * CFrame.new(0, 0.55, front - 0.01), TRIM, nil, "Body")
	k:part(
		"ChromeBase",
		v3(size.X - 0.3, 0.16, 0.04),
		fridge * CFrame.new(0, -1.25, front - 0.02),
		CHROME,
		Enum.Material.Metal,
		"Body"
	)
	for _, y in { 0.95, -0.35 } do
		local handle = k:part(
			"Handle",
			v3(0.1, 0.62, 0.1),
			fridge * CFrame.new(0.72, y, front - 0.16),
			CHROME,
			Enum.Material.Metal,
			"Body"
		)
		handle.Reflectance = 0.3
		for _, dy in { -0.28, 0.28 } do
			k:part(
				"HandleMount",
				v3(0.08, 0.08, 0.16),
				fridge * CFrame.new(0.72, y + dy, front - 0.08),
				TRIM,
				Enum.Material.Metal,
				"Body"
			)
		end
	end
	for _, magnet in
		{
			{ x = -0.55, y = -0.2, color = rgb(255, 90, 90) },
			{ x = -0.2, y = -0.75, color = rgb(255, 210, 60) },
			{ x = 0.3, y = 0.2, color = rgb(90, 180, 255) },
			{ x = -0.6, y = -0.95, color = rgb(120, 220, 120) },
		}
	do
		k:disc("Magnet", 0.26, 0.06, fridge * CFrame.new(magnet.x, magnet.y, front - 0.03), magnet.color, nil, "Body")
	end
	k:part(
		"Note",
		v3(0.5, 0.6, 0.02),
		fridge * CFrame.new(-0.2, -0.35, front - 0.02) * CFrame.Angles(0, 0, math.rad(6)),
		rgb(255, 246, 170),
		nil,
		"Body"
	)
	for i = 0, 5 do
		local x = (-0.9 + i * 0.36) * 0.8
		local top = fridge.Position + v3(x, size.Y / 2 - 0.3, front - 0.04)
		Parts.cone(k, "Icicle", top, top - v3(0, 0.32 + (i % 2) * 0.15, 0), 0.08, ICE, Enum.Material.Glass, "Body")
	end

	-- A hump poking out of the top and the camel's long neck and head leaning out over the front
	k:ellipsoid("Hump", v3(1.3, 1.1, 1.1), CFrame.new(0, 4.8, 0.3), CAMEL, Enum.Material.Fabric, "Body")
	Parts.tube(
		k,
		"Neck",
		{ v3(0, 4.55, -0.35), v3(0, 5.1, -0.85), v3(0, 5.6, -1.05), v3(0, 5.9, -1.2) },
		{ 0.34, 0.28, 0.26, 0.26 },
		CAMEL,
		Enum.Material.Fabric,
		"Body",
		{ density = 0.5, overlap = 6 }
	)
	local head: Kit.Shell = { center = v3(0, 6.05, -1.4), radii = v3(0.46, 0.44, 0.6) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), CAMEL, Enum.Material.Fabric, "Body")
	k:ellipsoid("Muzzle", v3(0.72, 0.56, 0.62), CFrame.new(0, 5.88, -1.85), CAMEL_DARK:Lerp(CAMEL, 0.5), nil, "Body")
	k:ellipsoid("Lip", v3(0.5, 0.2, 0.3), CFrame.new(0, 5.66, -2.02), CAMEL_DARK, nil, "Body")
	for _, side in { -1, 1 } do
		k:ball("Ear", 0.24, v3(side * 0.38, 6.42, -1.2), CAMEL_DARK, nil, "Body")
		k:ellipsoid("Nostril", v3(0.14, 0.06, 0.08), CFrame.new(side * 0.14, 5.98, -2.15), rgb(90, 60, 40), nil, "Body")
	end
	k:eyes(head, 34, 14, { width = 0.24, height = 0.28, iris = rgb(40, 30, 25), lid = 0.4, skin = CAMEL }, "Body")
	-- A winter scarf, since it lives in a fridge
	k:band(
		"Scarf",
		{ center = v3(0, 4.9, -0.7), radii = v3(0.4, 1, 0.4) },
		4.9,
		0.3,
		SCARF,
		Enum.Material.Fabric,
		"Body"
	)
	Parts.leaf(
		k,
		"ScarfTail",
		v3(0.25, 4.85, -0.95),
		v3(0.45, 4.1, -1.05),
		0.34,
		0.08,
		SCARF,
		v3(0, 0, -1),
		Enum.Material.Fabric,
		"Body"
	)
	k:turn(-22)
	return body
end

return Mythic
