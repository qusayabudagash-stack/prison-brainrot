-- LEGENDARY Brainrots: big, instantly recognizable silhouettes. Auras and particles come from Effects.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Legendary: { [string]: (Kit) -> BasePart } = {}

local function fire(part: BasePart, size: number, color: Color3, secondary: Color3)
	local flame = Instance.new("Fire")
	flame.Size = size
	flame.Heat = 8
	flame.Color = color
	flame.SecondaryColor = secondary
	flame.Parent = part
end

Legendary.PrisonKing = function(k)
	local skin = rgb(255, 196, 150)
	local velvet = rgb(190, 25, 45)
	local flame = rgb(255, 130, 30)
	local flameHot = rgb(255, 215, 70)
	local robe: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(1.95, 1.9, 1.75) }
	local head: Kit.Shell = { center = v3(0, 5.6, -0.25), radii = v3(1.2, 1.15, 1.1) }

	-- Royal robe in prison stripes, trimmed with gold
	local body = k:ellipsoid("Body", robe.radii * 2, CFrame.new(robe.center), C.White, Enum.Material.Fabric, "Body")
	Parts.stripes(k, robe, 1.35, 4.35, 5, C.Stripe, "Body", 0.42)
	k:limb("RobeTrim", Kit.surface(robe, 0, 50), Kit.surface(robe, 0, -55), 0.28, C.Gold, Enum.Material.Foil, "Body")
	k:band("RobeHem", robe, 1.35, 0.3, C.Gold, Enum.Material.Foil, "Body")
	k:band("Belt", robe, 2.55, 0.38, rgb(90, 40, 30), nil, "Body")
	k:part("BeltBuckle", v3(0.7, 0.55, 0.12), Kit.on(robe, 0, -14, 0.1), C.Gold, Enum.Material.Foil, "Body")

	-- Cape with an ermine collar
	Parts.cape(k, v3(0, 4.65, 0.75), 3.9, 4.1, velvet, C.White, "Body")
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		local at = v3(math.cos(angle) * 1.3, 4.7, math.sin(angle) * 1.15)
		k:ball("Ermine", 0.82, at, C.White, Enum.Material.Fabric, "Body")
		if i % 2 == 0 then
			k:ball(
				"ErmineSpot",
				0.16,
				at + v3(math.cos(angle) * 0.36, 0.05, math.sin(angle) * 0.36),
				rgb(25, 25, 30),
				nil,
				"Body"
			)
		end
	end

	-- Head: strong face, flaming beard and hair, big crown
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), skin, nil, "Body")
	k:eyes(head, 24, 16, {
		width = 0.56,
		height = 0.62,
		iris = rgb(90, 50, 20),
		look = Vector2.new(0, 0),
		lid = 0.32,
		lidTilt = -6,
		skin = skin,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(Kit.on(head, 25 * side, 33, 0.04), 0.62, 14 * side, rgb(200, 80, 20), "Body")
		k:ellipsoid(
			"Mustache",
			v3(0.85, 0.34, 0.3),
			Kit.on(head, 17 * side, -14, 0.1) * CFrame.Angles(0, 0, math.rad(-18 * side)),
			flame,
			nil,
			"Body"
		)
		k:ellipsoid(
			"MustacheTip",
			v3(0.4, 0.22, 0.22),
			Kit.on(head, 34 * side, -8, 0.12) * CFrame.Angles(0, 0, math.rad(30 * side)),
			flameHot,
			Enum.Material.Neon,
			"Body"
		)
	end
	k:ellipsoid("Nose", v3(0.42, 0.4, 0.4), Kit.on(head, 0, -2, 0.02), skin:Lerp(rgb(230, 130, 110), 0.4), nil, "Body")
	k:mouth(Kit.on(head, 0, -30, -0.02), { width = 0.7, height = 0.3, skin = skin, style = "Teeth" }, "Body")
	for i, spot in
		{ v3(0, 4.55, -1.05), v3(-0.55, 4.7, -0.95), v3(0.55, 4.7, -0.95), v3(-0.3, 4.3, -0.9), v3(0.3, 4.3, -0.9) }
	do
		local color = if i == 1 then flameHot else flame
		k:ellipsoid(
			"FlameBeard",
			v3(0.75, 1.0, 0.6),
			CFrame.new(spot) * CFrame.Angles(math.rad(15), 0, 0),
			color,
			nil,
			"Body"
		)
	end
	for i = -2, 2 do
		local tip = v3(i * 0.55, 7.2 - math.abs(i) * 0.35, 0.55)
		k:limb(
			"FlameHair",
			v3(i * 0.35, 5.8, 0.7),
			tip,
			0.55 - math.abs(i) * 0.06,
			if i % 2 == 0 then flame else flameHot,
			Enum.Material.Neon,
			"Body"
		)
	end
	Parts.crown(k, CFrame.new(0, 6.5, -0.2) * CFrame.Angles(0, 0, math.rad(-5)), 1.95, rgb(40, 200, 120), "Body")
	fire(k.model:FindFirstChild("Head") :: BasePart, 3, flame, rgb(255, 60, 20))

	-- Scepter topped with a giant golden prison key; other hand on the belly
	Parts.arm(k, "ArmR", v3(1.8, 3.85, 0), v3(2.55, 4.1, -0.55), 0.62, velvet, skin, 0.66)
	k:limb("Scepter", v3(2.55, 1.2, -0.6), v3(2.6, 5.7, -0.6), 0.22, C.Gold, Enum.Material.Foil, "ArmR")
	k:disc("KeyBow", 0.9, 0.2, CFrame.new(2.6, 6.1, -0.6), C.Gold, Enum.Material.Foil, "ArmR")
	k:disc("KeyBowHole", 0.42, 0.24, CFrame.new(2.6, 6.1, -0.6), rgb(190, 25, 45), Enum.Material.Neon, "ArmR")
	k:part("KeyTooth", v3(0.4, 0.14, 0.14), CFrame.new(2.8, 1.5, -0.6), C.Gold, Enum.Material.Foil, "ArmR")
	k:part("KeyTooth", v3(0.3, 0.14, 0.14), CFrame.new(2.75, 1.85, -0.6), C.Gold, Enum.Material.Foil, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.8, 3.85, 0), v3(-1.1, 2.9, -1.35), 0.62, velvet, skin, 0.66)

	-- Short legs in red royal boots
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.7, 1.4, 0), v3(side * 0.75, 0.6, 0), 0.62, C.White, Enum.Material.Fabric, "Legs")
		k:ellipsoid("RoyalBoot", v3(0.95, 0.85, 1.4), CFrame.new(side * 0.75, 0.42, -0.2), velvet, nil, "Legs")
		k:cylinder("BootCuff", 0.25, 0.85, CFrame.new(side * 0.75, 0.85, 0), C.Gold, Enum.Material.Foil, "Legs")
	end
	return body
end

Legendary.ElectricInmate = function(k)
	local yellow = rgb(255, 232, 80)
	local volt = rgb(120, 235, 255)
	local shell: Kit.Shell = { center = v3(0, 2.8, 0), radii = v3(1.6, 1.65, 1.5) }
	local suit: Kit.Shell = { center = v3(0, 1.95, 0), radii = v3(1.68, 1.1, 1.58) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), yellow, nil, "Body")
	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 2.55, 0.26, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, 10, 0.02), "#9V", 0.8, "Body")

	-- Three big lightning bolts shooting out of the scalp, built as flat zigzags with sharp corners
	local zigzag = { Vector2.new(0, -0.2), Vector2.new(0.38, 0.55), Vector2.new(-0.12, 0.72), Vector2.new(0.3, 1.5) }
	for i, spec in { { 0, 1.35, 0 }, { -42, 1.05, -1 }, { 42, 1.05, 1 } } do
		local yaw, size, lean = spec[1], spec[2], spec[3]
		local root = Kit.surface(shell, yaw, if i == 1 then 80 else 50)
		local frame = CFrame.new(root) * CFrame.Angles(0, math.rad(-yaw), 0) * CFrame.Angles(0, 0, math.rad(-lean * 32))
		for j = 1, 3 do
			local from, to = zigzag[j] * size, zigzag[j + 1] * size
			local mid, dir = (from + to) / 2, to - from
			local width = (0.4 - j * 0.07) * size
			k:part(
				"Bolt",
				v3(width, dir.Magnitude + width * 0.6, 0.16),
				frame * CFrame.new(mid.X, mid.Y, 0) * CFrame.Angles(0, 0, math.atan2(dir.Y, dir.X) - math.pi / 2),
				volt,
				Enum.Material.Neon,
				"Body"
			)
		end
		local tip = zigzag[4] * size
		k:wedge(
			"BoltTip",
			v3(0.08, 0.35 * size, 0.2 * size),
			frame * CFrame.new(tip.X, tip.Y + 0.1, 0) * CFrame.Angles(0, math.pi / 2, 0),
			C.White,
			Enum.Material.Neon,
			"Body"
		)
	end

	-- Wild, buzzing face
	k:eyes(
		shell,
		22,
		22,
		{ width = 0.78, height = 0.9, iris = rgb(60, 170, 255), look = Vector2.new(0, 0.2), skin = yellow },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:brow(Kit.on(shell, 23 * side, 44, 0.04), 0.6, -24 * side, rgb(150, 110, 20), "Body")
		k:blush(Kit.on(shell, 42 * side, 8, -0.02), 0.5, "Body")
	end
	k:mouth(
		Kit.on(shell, 0, 0, -0.03),
		{ width = 1.25, height = 0.62, skin = yellow, style = "Teeth", radius = 1.6 },
		"Body"
	)

	-- Rubber gloves and a big battery
	Parts.arm(k, "ArmR", v3(1.5, 2.6, 0), v3(2.2, 3.3, -0.5), 0.46, C.Jumpsuit, rgb(30, 30, 35), 0.62)
	k:cylinder("Battery", 1.3, 0.6, CFrame.new(2.3, 3.8, -0.55), rgb(40, 170, 90), nil, "ArmR")
	k:cylinder("BatteryTop", 0.35, 0.62, CFrame.new(2.3, 4.3, -0.55), C.Gold, Enum.Material.Foil, "ArmR")
	k:cylinder("BatteryNub", 0.15, 0.25, CFrame.new(2.3, 4.55, -0.55), rgb(200, 205, 215), Enum.Material.Metal, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.5, 2.6, 0), v3(-2.2, 3.3, -0.5), 0.46, C.Jumpsuit, rgb(30, 30, 35), 0.62)

	-- Sparks orbiting around
	for i = 0, 3 do
		local angle = i * math.pi / 2
		k:ball(
			"Spark",
			0.28,
			v3(math.cos(angle) * 2.3, 3.2 + (i % 2) * 0.8, math.sin(angle) * 2.3),
			volt,
			Enum.Material.Neon,
			"Orbit"
		)
	end

	Parts.legs(k, 1.2, 0.62, 0.62, C.Jumpsuit, rgb(255, 210, 40), rgb(40, 40, 45), 1, C.JumpsuitDark)
	return body
end

Legendary.GoldenWarden = function(k)
	local gold = rgb(245, 190, 50)
	local goldDark = rgb(200, 140, 30)
	local navy = rgb(30, 45, 100)
	local skin = rgb(240, 190, 150)
	local torso: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(1.4, 1.5, 1.15) }
	local head: Kit.Shell = { center = v3(0, 5.15, -0.1), radii = v3(0.98, 1.08, 0.95) }

	-- Gold uniform with navy tie, buttons, star badge and epaulettes
	local body = k:ellipsoid("Body", torso.radii * 2, CFrame.new(torso.center), gold, Enum.Material.Foil, "Body")
	k:ellipsoid(
		"Collar",
		v3(1.5, 0.45, 1.25),
		CFrame.new(0, 4.3, -0.05),
		rgb(245, 240, 225),
		Enum.Material.Fabric,
		"Body"
	)
	k:ellipsoid("TieKnot", v3(0.34, 0.3, 0.2), Kit.on(torso, 0, 52, 0.02), navy, Enum.Material.Fabric, "Body")
	k:ellipsoid("Tie", v3(0.46, 1.35, 0.2), Kit.on(torso, 0, 28, -0.02), navy, Enum.Material.Fabric, "Body")
	k:ellipsoid(
		"TieStripe",
		v3(0.5, 0.1, 0.16),
		Kit.on(torso, 0, 30, 0.04) * CFrame.Angles(0, 0, math.rad(-25)),
		C.Gold,
		Enum.Material.Foil,
		"Body"
	)
	for i = 0, 2 do
		k:ball("UniformButton", 0.16, Kit.surface(torso, 12, 30 - i * 25), goldDark, Enum.Material.Metal, "Body")
	end
	local star = Kit.on(torso, -26, 25, 0.08)
	for i = 0, 4 do
		k:wedge(
			"StarPoint",
			v3(0.08, 0.34, 0.16),
			star * CFrame.Angles(0, 0, i * math.pi * 2 / 5) * CFrame.new(0, 0.2, 0),
			rgb(255, 245, 200),
			Enum.Material.Foil,
			"Body"
		)
	end
	k:disc("StarCenter", 0.3, 0.1, star, rgb(255, 245, 200), Enum.Material.Foil, "Body")
	k:band("Belt", torso, 2.05, 0.32, rgb(35, 30, 30), nil, "Body")
	k:part(
		"BeltBuckle",
		v3(0.5, 0.4, 0.12),
		Kit.on(torso, 0, -38, 0.1),
		rgb(210, 215, 225),
		Enum.Material.Metal,
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Epaulette",
			v3(0.9, 0.3, 0.8),
			CFrame.new(side * 1.25, 4.15, 0),
			goldDark,
			Enum.Material.Foil,
			"Body"
		)
		for i = 0, 3 do
			k:ball(
				"Fringe",
				0.14,
				v3(side * (1.55 + i * 0.02), 3.95, -0.3 + i * 0.2),
				goldDark,
				Enum.Material.Foil,
				"Body"
			)
		end
	end
	-- The twist: the warden has a prison number too
	k:badge(Kit.on(torso, 30, 5, 0.03), "#001", 0.6, "Body")

	-- Head: aviators, enormous mustache, peaked cap with a star badge
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), skin, nil, "Body")
	k:ellipsoid("Chin", v3(1.3, 0.8, 1.1), CFrame.new(0, 4.4, -0.35), skin, nil, "Body")
	Parts.sunglasses(k, head, 22, 14, 0.62, C.Gold, rgb(30, 60, 90), "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Mustache",
			v3(0.95, 0.42, 0.38),
			Kit.on(head, 18 * side, -20, 0.12) * CFrame.Angles(0, 0, math.rad(-14 * side)),
			rgb(110, 70, 40),
			nil,
			"Body"
		)
		k:ellipsoid(
			"Ear",
			v3(0.25, 0.45, 0.35),
			CFrame.new(head.center + v3(side * 0.98, -0.05, 0.1)),
			skin,
			nil,
			"Body"
		)
	end
	k:ellipsoid("Nose", v3(0.36, 0.42, 0.4), Kit.on(head, 0, -4, 0.05), skin:Lerp(rgb(220, 140, 120), 0.4), nil, "Body")
	k:mouth(Kit.on(head, 0, -36, -0.02), { width = 0.5, height = 0.2, skin = skin, style = "Flat", radius = 1 }, "Body")
	local cap = CFrame.new(0, 6.05, -0.05)
	k:cylinder("CapBand", 0.45, 2.0, cap, navy, Enum.Material.Fabric, "Body")
	k:ellipsoid("CapTop", v3(2.35, 0.55, 2.35), cap * CFrame.new(0, 0.35, 0), navy, Enum.Material.Fabric, "Body")
	k:cylinder("CapGold", 0.14, 2.03, cap * CFrame.new(0, -0.12, 0), gold, Enum.Material.Foil, "Body")
	k:ellipsoid("Visor", v3(1.7, 0.16, 0.95), cap * CFrame.new(0, -0.22, -0.95), rgb(20, 20, 25), nil, "Body")
	k:disc("CapBadge", 0.5, 0.1, cap * CFrame.new(0, 0.12, -1.02), gold, Enum.Material.Foil, "Body")

	-- Baton in one hand, keys on the belt, whistle
	Parts.arm(k, "ArmR", v3(1.35, 3.9, 0), v3(1.95, 3.0, -0.55), 0.55, gold, skin, 0.6, Enum.Material.Foil)
	k:limb("Baton", v3(1.95, 2.6, -0.6), v3(2.05, 4.1, -0.7), 0.24, rgb(25, 25, 30), nil, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.35, 3.9, 0), v3(-1.6, 2.35, 0.2), 0.55, gold, skin, 0.6, Enum.Material.Foil)
	k:disc("KeyRing", 0.5, 0.08, CFrame.new(-1.15, 1.8, -0.75), rgb(210, 215, 225), Enum.Material.Metal, "Body")
	for i = -1, 1 do
		k:part(
			"Key",
			v3(0.08, 0.45, 0.05),
			CFrame.new(-1.15 + i * 0.14, 1.5, -0.8) * CFrame.Angles(0, 0, i * 0.3),
			C.Gold,
			Enum.Material.Foil,
			"Body"
		)
	end
	k:limb(
		"WhistleCord",
		Kit.surface(torso, 22, 45),
		Kit.surface(torso, 30, 15),
		0.06,
		rgb(210, 215, 225),
		Enum.Material.Metal,
		"Body"
	)
	k:cylinder(
		"Whistle",
		0.35,
		0.22,
		Kit.on(torso, 30, 12, 0.12) * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(210, 215, 225),
		Enum.Material.Metal,
		"Body"
	)

	Parts.legs(k, 1.55, 0.6, 0.62, navy, rgb(25, 25, 30), rgb(60, 60, 70), 1.05, navy)
	return body
end

Legendary.DragonDropout = function(k)
	local teal = rgb(40, 185, 145)
	local tealDark = rgb(25, 130, 110)
	local belly = rgb(255, 225, 160)
	local membrane = rgb(130, 90, 200)
	local torso: Kit.Shell = { center = v3(0, 2.65, 0.1), radii = v3(1.5, 1.55, 1.4) }
	local head: Kit.Shell = { center = v3(0, 4.55, -0.35), radii = v3(1.15, 1.02, 1.08) }

	local body = k:ellipsoid("Body", torso.radii * 2, CFrame.new(torso.center), teal, nil, "Body")
	local bellyShell: Kit.Shell = { center = torso.center + v3(0, -0.15, -0.6), radii = v3(1.12, 1.3, 0.9) }
	k:ellipsoid("Belly", bellyShell.radii * 2, CFrame.new(bellyShell.center), belly, nil, "Body")
	for i = 0, 3 do
		k:band("BellyGroove", bellyShell, 1.85 + i * 0.45, 0.06, rgb(225, 180, 110), nil, "Body")
	end
	for i = 0, 4 do
		local at = Kit.surface(torso, 180, 55 - i * 25) + v3(0, 0, 0.05)
		k:wedge(
			"BackSpike",
			v3(0.12, 0.55, 0.5),
			CFrame.new(at + v3(0, 0.1, 0.1)) * CFrame.Angles(math.rad(-20 + i * 18), 0, 0),
			belly,
			nil,
			"Body"
		)
	end

	-- Head with snout, horns, ear fins
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), teal, nil, "Body")
	local snout = CFrame.new(0, 4.25, -1.3)
	k:ellipsoid("Snout", v3(1.3, 0.85, 1.25), snout, teal, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid("Nostril", v3(0.16, 0.12, 0.1), snout * CFrame.new(side * 0.3, 0.2, -0.58), tealDark, nil, "Body")
		Parts.horn(k, head.center + v3(side * 0.55, 0.7, 0.2), v3(side * 0.35, 1, 0.45), 1.15, 0.36, belly, "Body")
		k:ellipsoid(
			"EarFin",
			v3(0.18, 0.7, 0.6),
			CFrame.new(head.center + v3(side * 1.1, 0.1, 0.2)) * CFrame.Angles(0, 0, math.rad(25 * side)),
			membrane,
			nil,
			"Body"
		)
	end
	k:eyes(head, 30, 24, {
		width = 0.66,
		height = 0.72,
		iris = rgb(255, 170, 30),
		look = Vector2.new(0.3, 0),
		lid = 0.4,
		lidTilt = -10,
		skin = teal,
	}, "Body")
	k:mouth(
		snout * CFrame.new(0, -0.3, -0.5),
		{ width = 0.9, height = 0.3, skin = teal, style = "Smirk", radius = 0.8 },
		"Body"
	)
	local ember = k:ball(
		"Ember",
		0.22,
		(snout * CFrame.new(0.3, 0.3, -0.75)).Position,
		rgb(255, 150, 40),
		Enum.Material.Neon,
		"Body"
	)
	fire(ember, 1.2, rgb(255, 150, 40), rgb(255, 60, 20))

	-- Graduation cap, knocked sideways
	Parts.gradCap(k, CFrame.new(-0.35, 5.3, -0.35) * CFrame.Angles(0, math.rad(-15), math.rad(18)), 1.9, "Body")

	-- Bat wings
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "WingR" else "WingL"
		local root = v3(side * 0.9, 3.6, 0.9)
		local tips =
			{ root + v3(side * 1.6, 1.5, 0.4), root + v3(side * 2.1, 0.5, 0.5), root + v3(side * 1.7, -0.5, 0.5) }
		for _, tip in tips do
			k:limb("WingBone", root, tip, 0.16, tealDark, nil, rig)
			k:ball("WingClaw", 0.2, tip, belly, nil, rig)
		end
		local edges = { tips[1], tips[2], tips[3], root + v3(side * 0.7, -1.1, 0.3) }
		for i = 1, 3 do
			local a, b = edges[i], edges[i + 1]
			local mid = (a + b) / 2
			local along = mid - root
			local normal = along:Cross(b - a).Unit
			local across = normal:Cross(along.Unit).Unit
			local center = root + along * 0.55
			k:ellipsoid(
				"WingMembrane",
				v3(along.Magnitude * 1.1, (b - a).Magnitude * 0.95, 0.07),
				CFrame.fromMatrix(center, along.Unit, across, normal),
				membrane,
				nil,
				rig
			)
		end
		k.model:SetAttribute(rig .. "Joint", root)
	end

	-- Tail with a spade tip
	local t1, t2, t3 = v3(0, 1.8, 1.3), v3(0.6, 1.2, 2.3), v3(1.4, 1.0, 2.7)
	k:limb("Tail", t1, t2, 0.7, teal, nil, "Body")
	k:limb("Tail", t2, t3, 0.5, teal, nil, "Body")
	k:wedge(
		"TailSpade",
		v3(0.15, 0.7, 0.7),
		CFrame.new(t3 + v3(0.35, 0.05, 0)) * CFrame.Angles(0, math.rad(90), math.rad(-60)),
		membrane,
		nil,
		"Body"
	)

	-- Arms holding a failed exam
	Parts.bareArm(k, "ArmR", v3(1.35, 3.1, 0), v3(2.05, 3.85, -0.45), 0.42, teal, 0.5)
	Parts.bareArm(k, "ArmL", v3(-1.35, 3.1, 0), v3(-1.75, 2.25, -0.45), 0.42, teal, 0.5)
	local exam = k:part(
		"Exam",
		v3(1.05, 1.25, 0.05),
		CFrame.new(2.2, 4.45, -0.62) * CFrame.Angles(0, math.rad(-12), math.rad(-8)),
		rgb(250, 250, 245),
		nil,
		"ArmR"
	)
	for i = 0, 2 do
		k:part(
			"ExamLine",
			v3(0.7, 0.05, 0.02),
			exam.CFrame * CFrame.new(0, -0.3 - i * 0.15, -0.035),
			rgb(150, 160, 190),
			nil,
			"ArmR"
		)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = exam
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = rgb(220, 40, 40)
	label.Size = UDim2.fromScale(1, 0.55)
	label.Text = "F-"
	label.Parent = gui

	-- Stubby clawed legs
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.75, 1.45, 0.1), v3(side * 0.8, 0.45, -0.05), 0.72, teal, nil, "Legs")
		k:ellipsoid("Foot", v3(0.95, 0.5, 1.2), CFrame.new(side * 0.8, 0.25, -0.3), teal, nil, "Legs")
		for c = -1, 1 do
			k:wedge(
				"Claw",
				v3(0.12, 0.2, 0.25),
				CFrame.new(side * 0.8 + c * 0.28, 0.12, -0.95) * CFrame.Angles(0, math.pi, 0),
				belly,
				nil,
				"Legs"
			)
		end
	end
	return body
end

return Legendary
