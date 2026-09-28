-- RARE Brainrots: unique clothing and a stronger silhouette.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Rare: { [string]: (Kit) -> BasePart } = {}

Rare.CellBlockGoblin = function(k)
	local skin = rgb(125, 180, 105)
	local skinDark = rgb(90, 140, 80)
	local torso: Kit.Shell = { center = v3(0, 2.45, 0.15), radii = v3(1.2, 1.25, 1.1) }
	local head: Kit.Shell = { center = v3(0, 4.0, -0.4), radii = v3(1.1, 0.98, 1.02) }

	-- Hunched body in a torn, patched jumpsuit
	local body = k:ellipsoid(
		"Body",
		torso.radii * 2,
		CFrame.new(torso.center) * CFrame.Angles(math.rad(-12), 0, 0),
		C.Jumpsuit,
		Enum.Material.Fabric,
		"Body"
	)
	k:part(
		"Patch",
		v3(0.5, 0.45, 0.08),
		Kit.on(torso, -30, -10, 0.01) * CFrame.Angles(0, 0, 0.2),
		rgb(120, 90, 200),
		Enum.Material.Fabric,
		"Body"
	)
	k:part(
		"Patch",
		v3(0.4, 0.4, 0.08),
		Kit.on(torso, 35, 20, 0.01) * CFrame.Angles(0, 0, -0.3),
		rgb(80, 170, 220),
		Enum.Material.Fabric,
		"Body"
	)
	k:badge(Kit.on(torso, 0, 8, 0.02), "#666", 0.8, "Body")
	k:band("Belt", torso, 1.55, 0.25, rgb(90, 60, 40), nil, "Body")

	-- Big head, huge ears, crooked nose, fangy grin
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), skin, nil, "Body")
	for _, side in { -1, 1 } do
		local base = v3(side * 0.95, 4.25, -0.25)
		k:limb("Ear", base, base + v3(side * 1.0, 0.5, 0.25), 0.62, skin, nil, "Body")
		k:limb("EarTip", base + v3(side * 0.9, 0.45, 0.22), base + v3(side * 1.55, 0.95, 0.4), 0.3, skin, nil, "Body")
		k:ellipsoid(
			"EarInner",
			v3(0.9, 0.3, 0.12),
			CFrame.new(base + v3(side * 0.6, 0.3, -0.1)) * CFrame.Angles(0, 0, math.rad(28 * side)),
			rgb(220, 150, 150),
			nil,
			"Body"
		)
	end
	k:eyes(head, 26, 12, {
		width = 0.66,
		height = 0.66,
		iris = rgb(240, 200, 40),
		look = Vector2.new(0.2, -0.2),
		lid = 0.3,
		lidTilt = 22,
		skin = skin,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(Kit.on(head, 27 * side, 30, 0.04), 0.55, 26 * side, rgb(60, 80, 50), "Body")
		k:ball("Wart", 0.14, Kit.surface(head, 50 * side, -10 + side * 20), skinDark, nil, "Body")
	end
	local nose = Kit.on(head, 0, 2, 0.2)
	k:limb("Nose", nose.Position, nose.Position + v3(0.12, -0.35, -0.6), 0.42, skinDark:Lerp(skin, 0.4), nil, "Body")
	k:mouth(Kit.on(head, 0, -22, -0.03), { width = 1.1, height = 0.46, skin = skin, style = "Teeth" }, "Body")
	for _, side in { -1, 1 } do
		k:wedge(
			"Fang",
			v3(0.1, 0.26, 0.14),
			Kit.on(head, 16 * side, -28, 0.02) * CFrame.Angles(math.pi, 0, 0),
			C.White,
			nil,
			"Body"
		)
	end
	k:limb("HairTuft", v3(0, 4.9, -0.2), v3(0.2, 5.4, 0.1), 0.26, rgb(80, 60, 40), nil, "Body")

	-- Long arms: one jangling a stolen key ring
	Parts.arm(k, "ArmR", v3(1.1, 2.9, 0), v3(1.75, 2.3, -0.8), 0.42, C.Jumpsuit, skin, 0.55)
	local ring = CFrame.new(1.85, 1.85, -0.95)
	k:disc("KeyRing", 0.55, 0.08, ring * CFrame.Angles(0, math.rad(90), 0), C.Gold, Enum.Material.Metal, "ArmR")
	for i, offset in { -0.2, 0.05, 0.3 } do
		local key = ring * CFrame.new(offset, -0.35 - i * 0.05, -0.1) * CFrame.Angles(0, 0, math.rad(offset * 60))
		k:part("Key", v3(0.1, 0.55, 0.05), key, C.Gold, Enum.Material.Foil, "ArmR")
		k:part("KeyTooth", v3(0.18, 0.08, 0.05), key * CFrame.new(0.08, -0.2, 0), C.Gold, Enum.Material.Foil, "ArmR")
	end
	Parts.arm(k, "ArmL", v3(-1.1, 2.9, 0), v3(-1.7, 1.5, -0.3), 0.42, C.Jumpsuit, skin, 0.55)

	-- Bowed legs and big bare feet
	for _, side in { -1, 1 } do
		k:limb(
			"Leg",
			v3(side * 0.55, 1.4, 0.1),
			v3(side * 0.75, 0.5, 0),
			0.52,
			C.Jumpsuit,
			Enum.Material.Fabric,
			"Legs"
		)
		k:ellipsoid("Foot", v3(0.8, 0.45, 1.35), CFrame.new(side * 0.8, 0.22, -0.35), skin, nil, "Legs")
		for t = -1, 1 do
			k:ball("FootToe", 0.24, v3(side * 0.8 + t * 0.22, 0.2, -1.0), skin, nil, "Legs")
		end
	end
	return body
end

Rare.RichPrisoner = function(k)
	local pink = rgb(255, 170, 190)
	local pinkDark = rgb(235, 130, 155)
	local velvet = rgb(110, 50, 150)
	local shell: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(1.8, 1.75, 1.6) }
	local coat: Kit.Shell = { center = v3(0, 2.35, 0), radii = v3(1.88, 1.35, 1.68) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), pink, nil, "Body")

	-- Velvet coat with gold trim, over a striped prison shirt
	k:ellipsoid("Coat", coat.radii * 2, CFrame.new(coat.center), velvet, Enum.Material.Fabric, "Body")
	local bow = Kit.on(coat, 0, 34, 0.08)
	for _, side in { -1, 1 } do
		k:wedge(
			"BowTie",
			v3(0.12, 0.4, 0.34),
			bow * CFrame.new(side * 0.2, 0, 0) * CFrame.Angles(0, math.rad(90 * side), 0),
			rgb(30, 25, 35),
			nil,
			"Body"
		)
	end
	k:ball("BowKnot", 0.2, bow.Position, rgb(30, 25, 35), nil, "Body")
	for _, side in { -1, 1 } do
		k:limb(
			"Lapel",
			Kit.surface(coat, 18 * side, 38),
			Kit.surface(coat, 12 * side, -30),
			0.2,
			C.Gold,
			Enum.Material.Foil,
			"Body"
		)
		k:ball("CoatButton", 0.16, Kit.surface(coat, 26 * side, -8), C.Gold, Enum.Material.Foil, "Body")
	end
	k:band("CoatTrim", coat, 1.12, 0.22, C.Gold, Enum.Material.Foil, "Body")
	Parts.goldChain(k, shell, 2.95, "$", "Body")

	-- Pig face: snout, sunglasses, floppy ears, smug smirk
	local snout = Kit.on(shell, 0, 20, 0.12)
	k:ellipsoid("Snout", v3(0.95, 0.72, 0.5), snout, pinkDark, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Nostril",
			v3(0.18, 0.28, 0.1),
			snout * CFrame.new(side * 0.2, 0, -0.25),
			rgb(150, 70, 90),
			nil,
			"Body"
		)
		local ear = Kit.surface(shell, 40 * side, 62)
		k:ellipsoid(
			"Ear",
			v3(0.75, 0.95, 0.25),
			CFrame.new(ear) * CFrame.Angles(math.rad(-30), 0, math.rad(-40 * side)),
			pinkDark,
			nil,
			"Body"
		)
		k:blush(Kit.on(shell, 42 * side, 18, -0.02), 0.55, "Body")
	end
	Parts.sunglasses(k, shell, 21, 38, 0.72, C.Gold, rgb(40, 20, 60), "Body")
	k:mouth(Kit.on(shell, 6, 8, -0.03), { width = 0.9, height = 0.42, skin = pink, style = "Smirk" }, "Body")

	-- Top hat
	local hat = CFrame.new(0.1, 4.6, 0.1) * CFrame.Angles(0, 0, math.rad(-6))
	k:cylinder("HatBrim", 0.15, 2.1, hat, rgb(30, 25, 35), nil, "Body")
	k:cylinder("TopHat", 1.35, 1.35, hat * CFrame.new(0, 0.7, 0), rgb(30, 25, 35), nil, "Body")
	k:cylinder("HatBand", 0.28, 1.38, hat * CFrame.new(0, 0.25, 0), C.Gold, Enum.Material.Foil, "Body")

	-- Confident pose: hand on hip, the other on a gold-topped cane
	Parts.arm(k, "ArmL", v3(-1.72, 2.7, 0), v3(-1.95, 2.0, 0.35), 0.52, velvet, pink, 0.6)
	Parts.arm(k, "ArmR", v3(1.72, 2.7, 0), v3(2.25, 2.35, -0.6), 0.52, velvet, pink, 0.6)
	k:limb("Cane", v3(2.3, 2.55, -0.65), v3(2.4, 0.05, -0.7), 0.16, rgb(30, 25, 35), nil, "ArmR")
	k:ball("CaneTop", 0.36, v3(2.3, 2.7, -0.65), C.Gold, Enum.Material.Foil, "ArmR")
	k:limb("CurlyTail", v3(0, 2.2, 1.55), v3(0.2, 2.6, 1.85), 0.18, pinkDark, nil, "Body")

	-- Prison-striped trousers under all that luxury
	Parts.legs(k, 1.25, 0.72, 0.62, C.White, rgb(30, 25, 35), C.Gold, 1.05, C.Gold)
	for _, side in { -1, 1 } do
		for i = 0, 1 do
			k:cylinder(
				"TrouserStripe",
				0.16,
				0.68,
				CFrame.new(side * 0.74, 0.85 + i * 0.32, 0),
				C.Stripe,
				Enum.Material.Fabric,
				"Legs"
			)
		end
	end
	return body
end

Rare.JuiceSmuggler = function(k)
	local boxColor = rgb(120, 200, 255)
	local label = rgb(255, 250, 240)
	local coat = rgb(200, 160, 100)

	-- The juice box
	local body = k:part("Body", v3(2.2, 3.0, 1.5), CFrame.new(0, 3.0, 0), boxColor, nil, "Body")
	k:part("BoxTop", v3(2.1, 0.12, 1.4), CFrame.new(0, 4.55, 0), boxColor:Lerp(Color3.new(1, 1, 1), 0.3), nil, "Body")
	k:part("Label", v3(1.7, 1.6, 0.06), CFrame.new(0, 2.9, -0.77), label, nil, "Body")
	k:ball("LabelApple", 0.62, v3(0, 2.55, -0.78), rgb(235, 60, 60), nil, "Body")
	k:ellipsoid(
		"LabelLeaf",
		v3(0.25, 0.12, 0.05),
		CFrame.new(0.15, 2.92, -0.82) * CFrame.Angles(0, 0, 0.5),
		rgb(90, 190, 80),
		nil,
		"Body"
	)
	-- Bendy straw
	k:limb("Straw", v3(0.55, 4.5, 0.2), v3(0.6, 5.5, 0.2), 0.22, rgb(255, 120, 170), nil, "Body")
	k:limb("StrawBend", v3(0.6, 5.5, 0.2), v3(1.05, 5.8, 0.2), 0.22, rgb(255, 120, 170), nil, "Body")

	-- Trench coat thrown open over the sides, with smuggled mini juice boxes in the lining
	for _, side in { -1, 1 } do
		k:part("CoatPanel", v3(0.3, 3.2, 1.75), CFrame.new(side * 1.25, 2.65, 0.05), coat, Enum.Material.Fabric, "Body")
		k:part(
			"CoatFront",
			v3(0.55, 3.2, 0.2),
			CFrame.new(side * 1.2, 2.65, -0.85) * CFrame.Angles(0, math.rad(35 * side), 0),
			coat,
			Enum.Material.Fabric,
			"Body"
		)
		k:wedge(
			"CoatCollar",
			v3(0.3, 0.7, 0.6),
			CFrame.new(side * 1.2, 4.35, -0.55) * CFrame.Angles(0, math.rad(-90 * side), 0),
			coat:Lerp(Color3.new(0, 0, 0), 0.15),
			Enum.Material.Fabric,
			"Body"
		)
		k:ball("CoatButton", 0.14, v3(side * 1.32, 2.3, -1.0), rgb(90, 60, 40), nil, "Body")
	end
	k:part("CoatBack", v3(2.6, 3.2, 0.2), CFrame.new(0, 2.65, 0.9), coat, Enum.Material.Fabric, "Body")
	for i, color in { rgb(255, 170, 60), rgb(160, 110, 240) } do
		k:part(
			"MiniJuice",
			v3(0.28, 0.5, 0.35),
			CFrame.new(1.45, 1.75 + i * 0.62, -0.75) * CFrame.Angles(0, math.rad(35), 0),
			color,
			nil,
			"Body"
		)
	end

	-- Face: sunglasses and a sly grin on a second label, fedora on top
	k:part("FaceLabel", v3(1.7, 1.0, 0.05), CFrame.new(0, 4.0, -0.77), label, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Shades",
			v3(0.62, 0.4, 0.14),
			CFrame.new(side * 0.36, 4.15, -0.83),
			rgb(25, 25, 35),
			Enum.Material.Glass,
			"Body"
		)
		k:ball("ShadesShine", 0.1, v3(side * 0.36 - 0.12, 4.24, -0.9), rgb(200, 220, 255), nil, "Body")
	end
	k:part("ShadesBridge", v3(0.25, 0.08, 0.08), CFrame.new(0, 4.2, -0.85), rgb(25, 25, 35), nil, "Body")
	k:mouth(CFrame.new(0.05, 3.76, -0.8), { width = 0.66, height = 0.3, skin = label, style = "Smirk" }, "Body")
	local hat = CFrame.new(-0.15, 4.66, 0.1) * CFrame.Angles(0, 0, math.rad(8))
	k:cylinder("FedoraBrim", 0.12, 2.5, hat, rgb(70, 55, 45), nil, "Body")
	k:cylinder("Fedora", 0.75, 1.55, hat * CFrame.new(0, 0.38, 0), rgb(70, 55, 45), nil, "Body")
	k:cylinder("FedoraBand", 0.2, 1.58, hat * CFrame.new(0, 0.15, 0), rgb(30, 25, 25), nil, "Body")

	Parts.arm(k, "ArmR", v3(1.4, 3.3, 0), v3(2.0, 2.5, -0.45), 0.42, coat, boxColor, 0.5)
	Parts.arm(k, "ArmL", v3(-1.4, 3.3, 0), v3(-2.05, 3.7, -0.5), 0.42, coat, boxColor, 0.5)
	Parts.legs(k, 1.5, 0.55, 0.45, rgb(60, 60, 75), rgb(40, 35, 35), rgb(120, 110, 100), 0.9)
	return body
end

Rare.RoboRascal = function(k)
	local metal = rgb(185, 195, 210)
	local metalDark = rgb(120, 130, 150)
	local screen = rgb(20, 25, 35)
	local glow = rgb(90, 240, 255)

	-- Round barrel torso with a chest panel
	local body = k:cylinder("Body", 1.9, 2.3, CFrame.new(0, 2.35, 0), metal, Enum.Material.Metal, "Body")
	k:cylinder("TorsoRing", 0.2, 2.4, CFrame.new(0, 3.2, 0), C.Jumpsuit, nil, "Body")
	k:cylinder("TorsoRing", 0.2, 2.4, CFrame.new(0, 1.5, 0), C.Jumpsuit, nil, "Body")
	k:part("ChestPanel", v3(1.2, 0.9, 0.1), CFrame.new(0, 2.4, -1.12), metalDark, Enum.Material.Metal, "Body")
	for i, color in { rgb(255, 70, 70), rgb(255, 220, 60), rgb(80, 230, 110) } do
		k:ball("ChestLight", 0.22, v3(-0.55 + i * 0.3, 2.55, -1.18), color, Enum.Material.Neon, "Body")
	end
	k:badge(CFrame.new(0, 2.15, -1.18), "R-2", 0.8, "Body")

	-- TV-screen head with glowing eyes and an antenna
	local head = CFrame.new(0, 4.3, -0.05)
	k:part("Head", v3(2.2, 1.7, 1.8), head, metal, Enum.Material.Metal, "Body")
	k:part("Screen", v3(1.8, 1.25, 0.1), head * CFrame.new(0, 0, -0.91), screen, Enum.Material.Glass, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"GlowEye",
			v3(0.42, 0.5, 0.06),
			head * CFrame.new(side * 0.42, 0.15, -0.97),
			glow,
			Enum.Material.Neon,
			"Body"
		)
		k:cylinder(
			"EarBolt",
			0.3,
			0.55,
			head * CFrame.new(side * 1.2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2),
			metalDark,
			Enum.Material.Metal,
			"Body"
		)
	end
	for i = -2, 2 do
		k:part(
			"MouthPixel",
			v3(0.18, 0.12, 0.05),
			head * CFrame.new(i * 0.2, -0.32 + (if i % 2 == 0 then 0 else -0.08), -0.97),
			glow,
			Enum.Material.Neon,
			"Body"
		)
	end
	k:limb(
		"Antenna",
		(head * CFrame.new(0.3, 0.85, 0)).Position,
		(head * CFrame.new(0.5, 1.6, 0)).Position,
		0.1,
		metalDark,
		Enum.Material.Metal,
		"Body"
	)
	k:ball(
		"AntennaBulb",
		0.34,
		(head * CFrame.new(0.52, 1.7, 0)).Position,
		rgb(255, 60, 60),
		Enum.Material.Neon,
		"Body"
	)

	-- Segmented arms with claws
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "ArmR" else "ArmL"
		local shoulder = v3(side * 1.25, 2.95, 0)
		local elbow = v3(side * 1.7, 2.3, -0.25)
		local hand = v3(side * 1.8, 1.7 + (if side > 0 then 1.2 else 0), -0.5)
		k:ball("Shoulder", 0.55, shoulder, metalDark, Enum.Material.Metal, rig)
		k:limb("UpperArm", shoulder, elbow, 0.28, metal, Enum.Material.Metal, rig)
		k:ball("Elbow", 0.38, elbow, metalDark, Enum.Material.Metal, rig)
		k:limb("Forearm", elbow, hand, 0.28, metal, Enum.Material.Metal, rig)
		for _, claw in { -1, 1 } do
			k:wedge(
				"Claw",
				v3(0.12, 0.4, 0.2),
				CFrame.new(hand + v3(claw * 0.14, -0.2, -0.05)) * CFrame.Angles(math.pi, 0, 0),
				metalDark,
				Enum.Material.Metal,
				rig
			)
		end
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end

	-- Stubby legs, big boots, and an ankle monitor
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.6, 1.4, 0), v3(side * 0.62, 0.55, 0), 0.4, metalDark, Enum.Material.Metal, "Legs")
		k:ellipsoid("Boot", v3(0.95, 0.6, 1.3), CFrame.new(side * 0.62, 0.3, -0.15), metal, Enum.Material.Metal, "Legs")
	end
	k:part("AnkleMonitor", v3(0.5, 0.35, 0.3), CFrame.new(-0.62, 0.8, -0.3), C.Jumpsuit, nil, "Legs")
	k:ball("MonitorLight", 0.12, v3(-0.62, 0.85, -0.47), rgb(255, 40, 40), Enum.Material.Neon, "Legs")
	return body
end

Rare.CheeseEscapee = function(k)
	local cheese = rgb(255, 210, 70)
	local hole = rgb(220, 160, 35)

	-- A wedge of cheese; the slope faces forward and holds the face
	local body = k:wedge("Body", v3(2.8, 2.9, 2.6), CFrame.new(0, 2.8, 0.1), cheese, nil, "Body")
	k:part("Rind", v3(2.82, 2.92, 0.2), CFrame.new(0, 2.8, 1.35), rgb(240, 180, 50), nil, "Body")
	for _, spot in
		{ { -0.8, 1.9, -0.55, 0.55 }, { 0.9, 2.4, -0.1, 0.45 }, { 0.2, 3.6, 0.65, 0.4 }, { -0.95, 3.2, 0.35, 0.35 } }
	do
		local slope = CFrame.new(spot[1], spot[2], spot[3]) * CFrame.Angles(math.rad(-48), 0, 0)
		k:disc("Hole", spot[4], 0.1, slope, hole, nil, "Body")
	end
	for _, spot in { v3(1.41, 2.2, 0.7), v3(1.41, 3.2, 0.9), v3(-1.41, 2.4, 0.8) } do
		local side = if spot.X > 0 then 1 else -1
		k:disc("Hole", 0.45, 0.1, CFrame.new(spot) * CFrame.Angles(0, math.rad(90 * side), 0), hole, nil, "Body")
	end

	-- Groucho disguise: glasses, big nose and mustache
	local face = CFrame.new(0, 2.8, -0.2) * CFrame.Angles(math.rad(-48), 0, 0)
	for _, side in { -1, 1 } do
		k:eye(
			face * CFrame.new(side * 0.5, 0.35, -0.05),
			{ width = 0.52, height = 0.58, iris = rgb(90, 60, 30), look = Vector2.new(0.3, 0.3), side = side },
			"Body"
		)
		k:disc("GlassesRim", 0.72, 0.1, face * CFrame.new(side * 0.5, 0.35, -0.22), rgb(30, 25, 25), nil, "Body")
		k:disc(
			"GlassesLens",
			0.58,
			0.12,
			face * CFrame.new(side * 0.5, 0.35, -0.24),
			rgb(200, 235, 255),
			Enum.Material.Glass,
			"Body"
		).Transparency =
			0.6
		k:ellipsoid(
			"Mustache",
			v3(0.62, 0.26, 0.2),
			face * CFrame.new(side * 0.3, -0.35, -0.2) * CFrame.Angles(0, 0, math.rad(-12 * side)),
			rgb(60, 40, 30),
			nil,
			"Body"
		)
	end
	k:part("GlassesBridge", v3(0.3, 0.08, 0.08), face * CFrame.new(0, 0.42, -0.24), rgb(30, 25, 25), nil, "Body")
	k:ellipsoid("FakeNose", v3(0.5, 0.45, 0.55), face * CFrame.new(0, -0.05, -0.3), rgb(255, 170, 150), nil, "Body")
	k:mouth(face * CFrame.new(0, -0.72, 0), { width = 0.8, height = 0.36, skin = cheese, style = "Grin" }, "Body")

	-- Knotted bedsheet rope trailing from one hand
	Parts.bareArm(k, "ArmR", v3(1.3, 2.4, 0.2), v3(1.95, 3.15, -0.45), 0.36, cheese, 0.48)
	local last = v3(2.0, 3.0, -0.45)
	for i = 1, 4 do
		local nextPoint = last + v3(0.12 * (if i % 2 == 0 then 1 else -1), -0.62, 0.1)
		k:limb("Bedsheet", last, nextPoint, 0.3, C.White, Enum.Material.Fabric, "ArmR")
		k:ball("Knot", 0.36, nextPoint, rgb(230, 230, 235), Enum.Material.Fabric, "ArmR")
		last = nextPoint
	end
	Parts.bareArm(k, "ArmL", v3(-1.3, 2.4, 0.2), v3(-1.8, 1.7, -0.2), 0.36, cheese, 0.48)

	-- Striped prison shorts
	k:part("Shorts", v3(2.2, 0.6, 1.6), CFrame.new(0, 1.35, 0.3), C.White, Enum.Material.Fabric, "Body")
	k:part("ShortsStripe", v3(2.22, 0.2, 1.62), CFrame.new(0, 1.35, 0.3), C.Stripe, Enum.Material.Fabric, "Body")
	Parts.legs(k, 1.2, 0.55, 0.42, cheese, rgb(60, 60, 70), C.White, 0.85, cheese)
	return body
end

return Rare
