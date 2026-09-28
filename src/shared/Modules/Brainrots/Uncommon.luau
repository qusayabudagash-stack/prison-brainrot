-- UNCOMMON Brainrots: more accessories, more personality.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Uncommon: { [string]: (Kit) -> BasePart } = {}

Uncommon.PrisonFrog = function(k)
	local green = rgb(95, 195, 85)
	local greenDark = rgb(60, 150, 65)
	local belly = rgb(200, 238, 160)
	local shell: Kit.Shell = { center = v3(0, 2.35, 0), radii = v3(1.85, 1.4, 1.6) }
	-- Lower body in the jumpsuit: about as wide as the frog, so it reads as pants, not a swim ring
	local suit: Kit.Shell = { center = v3(0, 1.55, 0), radii = v3(1.8, 1.0, 1.55) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), green, nil, "Body")
	k:ellipsoid("Belly", v3(2.2, 1.5, 0.6), Kit.on(shell, 0, 5, -0.25), belly, nil, "Body")
	for _, spot in { { 60, 40 }, { -70, 30 }, { 150, 45 }, { -130, 55 } } do
		k:ellipsoid("Spot", v3(0.5, 0.4, 0.1), Kit.on(shell, spot[1], spot[2], -0.02), greenDark, nil, "Body")
	end

	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 1.9, 0.24, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, -8, 0.02), "#007", 0.9, "Body")

	-- Bulging eyes on top, half-lidded and smug
	for _, side in { -1, 1 } do
		local bump: Kit.Shell = { center = v3(side * 0.82, 3.55, -0.45), radii = v3(0.72, 0.68, 0.7) }
		k:ellipsoid("EyeBump", bump.radii * 2, CFrame.new(bump.center), green, nil, "Body")
		k:eye(Kit.on(bump, side * 8, 10, -0.08), {
			width = 0.95,
			height = 1.0,
			iris = rgb(200, 150, 30),
			look = Vector2.new(0.3, 0),
			lid = 0.42,
			lidTilt = -6,
			skin = green,
			side = side,
		}, "Body")
		k:blush(Kit.on(shell, 42 * side, 20, -0.02), 0.6, "Body")
	end
	k:mouth(Kit.on(shell, 0, 16, -0.03), { width = 2.1, height = 0.62, skin = green, style = "Smile" }, "Body")
	k:ellipsoid("TongueOut", v3(0.42, 0.55, 0.2), Kit.on(shell, 22, 11, 0.02), C.Tongue, nil, "Body")

	-- Tiny tilted prison cap between the eyes
	Parts.prisonCap(k, CFrame.new(0, 3.62, 0.25) * CFrame.Angles(0, 0, math.rad(12)), 0.95, "Body")

	-- Arms: one holding a spoon for digging out
	Parts.bareArm(k, "ArmR", v3(1.6, 2.3, -0.1), v3(2.25, 2.95, -0.6), 0.36, green, 0.48)
	k:limb(
		"SpoonHandle",
		v3(2.25, 2.7, -0.6),
		v3(2.3, 3.9, -0.7),
		0.14,
		rgb(200, 205, 215),
		Enum.Material.Metal,
		"ArmR"
	)
	k:ellipsoid(
		"SpoonBowl",
		v3(0.42, 0.62, 0.18),
		CFrame.new(2.31, 4.15, -0.72),
		rgb(210, 215, 225),
		Enum.Material.Metal,
		"ArmR"
	)
	Parts.bareArm(k, "ArmL", v3(-1.6, 2.3, -0.1), v3(-2.05, 1.55, -0.45), 0.36, green, 0.48)

	-- Folded frog legs and big webbed feet
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Thigh",
			v3(0.9, 1.1, 1.5),
			CFrame.new(side * 1.35, 1.0, 0.1) * CFrame.Angles(math.rad(-20), 0, math.rad(15 * side)),
			green,
			nil,
			"Legs"
		)
		local foot = v3(side * 1.1, 0.12, -0.55)
		k:ellipsoid("Foot", v3(1.1, 0.24, 1.2), CFrame.new(foot), greenDark, nil, "Legs")
		for _, toe in { -0.38, 0, 0.38 } do
			k:ball("Toe", 0.3, foot + v3(toe, 0.08, -0.62), greenDark, nil, "Legs")
		end
	end
	return body
end

Uncommon.EscapeDuck = function(k)
	local yellow = rgb(255, 214, 60)
	local orange = rgb(255, 140, 35)
	local shell: Kit.Shell = { center = v3(0, 2.35, 0.05), radii = v3(1.45, 1.4, 1.5) }
	local head: Kit.Shell = { center = v3(0, 4.0, -0.25), radii = v3(1.08, 1.02, 1.02) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), yellow, nil, "Body")
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), yellow, nil, "Body")
	k:limb("TailTuft", v3(0, 2.6, 1.3), v3(0, 3.2, 1.8), 0.55, yellow, nil, "Body")
	k:badge(Kit.on(shell, 0, 22, 0.02), "#010", 0.8, "Body")

	-- Face, bill and swim goggles pushed up on the forehead
	k:eyes(
		head,
		26,
		12,
		{ width = 0.62, height = 0.74, iris = rgb(60, 110, 200), look = Vector2.new(0, 0.3), skin = yellow },
		"Body"
	)
	local bill = Kit.on(head, 0, -10, 0.2)
	k:ellipsoid("Bill", v3(1.1, 0.34, 0.95), bill, orange, nil, "Body")
	k:ellipsoid(
		"BillLower",
		v3(0.9, 0.24, 0.7),
		bill * CFrame.new(0, -0.25, 0.1) * CFrame.Angles(math.rad(18), 0, 0),
		orange:Lerp(Color3.new(0, 0, 0), 0.1),
		nil,
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ball("Nostril", 0.08, (bill * CFrame.new(side * 0.15, 0.12, -0.44)).Position, rgb(150, 70, 20), nil, "Body")
		k:blush(Kit.on(head, 42 * side, -4, -0.02), 0.45, "Body")
	end
	k:band("GoggleStrap", head, 4.55, 0.2, rgb(40, 110, 220), nil, "Body")
	for _, side in { -1, 1 } do
		local lens = Kit.on(head, 22 * side, 38, 0.05)
		k:disc("GoggleRim", 0.62, 0.16, lens, rgb(40, 110, 220), nil, "Body")
		k:disc("GoggleLens", 0.48, 0.2, lens * CFrame.new(0, 0, -0.03), rgb(150, 230, 255), Enum.Material.Glass, "Body")
	end

	-- Inflatable swim ring around the waist
	for i = 0, 15 do
		local angle = i * math.pi * 2 / 16
		local color = if (i // 2) % 2 == 0 then rgb(235, 55, 60) else C.White
		k:ellipsoid(
			"SwimRing",
			v3(0.85, 0.72, 0.85),
			CFrame.new(math.cos(angle) * 1.62, 1.95, math.sin(angle) * 1.66),
			color,
			nil,
			"Body"
		)
	end

	Parts.bareArm(k, "ArmR", v3(1.35, 2.75, 0), v3(2.15, 3.35, -0.35), 0.42, yellow, 0.52)
	Parts.bareArm(k, "ArmL", v3(-1.35, 2.75, 0), v3(-2.1, 3.3, -0.3), 0.42, yellow, 0.52)
	Parts.birdLegs(k, 1.2, 0.55, orange)
	for _, side in { -1, 1 } do
		k:ellipsoid("Webbing", v3(0.95, 0.12, 0.9), CFrame.new(side * 0.55, 0.1, -0.4), orange, nil, "Legs")
	end
	return body
end

Uncommon.PizzaCriminal = function(k)
	local cheese = rgb(255, 205, 85)
	local crust = rgb(205, 135, 60)
	local width, height, thick = 1.75, 3.3, 0.55
	local baseY = 1.55
	local center = baseY + height / 2

	-- Upright slice: two mirrored wedges make the triangle, tip up
	local body = k:wedge(
		"Body",
		v3(thick, height, width),
		CFrame.new(width / 2, center, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		cheese,
		nil,
		"Body"
	)
	k:wedge(
		"SliceLeft",
		v3(thick, height, width),
		CFrame.new(-width / 2, center, 0) * CFrame.Angles(0, math.pi / 2, 0),
		cheese,
		nil,
		"Body"
	)
	k:cylinder(
		"Crust",
		width * 2 + 0.3,
		0.85,
		CFrame.new(0, baseY, 0.05) * CFrame.Angles(0, 0, math.pi / 2),
		crust,
		nil,
		"Body"
	)
	for _, drip in { v3(-0.9, 1.9, -0.3), v3(0.4, 2.0, -0.3), v3(1.1, 1.95, -0.3) } do
		k:ellipsoid("CheeseDrip", v3(0.3, 0.55, 0.22), CFrame.new(drip - v3(0, 0.3, 0)), cheese, nil, "Body")
	end
	for _, spot in { v3(-0.85, 2.45, -0.3), v3(0.85, 2.5, -0.3), v3(0.15, 4.05, -0.3), v3(-0.3, 2.05, -0.3) } do
		k:disc("Pepperoni", 0.55, 0.08, CFrame.new(spot), rgb(205, 55, 45), nil, "Body")
	end
	for _, spot in { v3(0.5, 3.6, -0.3), v3(-0.95, 1.95, -0.3) } do
		k:disc("Olive", 0.26, 0.08, CFrame.new(spot), rgb(40, 40, 40), nil, "Body")
		k:disc("OliveHole", 0.1, 0.1, CFrame.new(spot), rgb(110, 90, 60), nil, "Body")
	end

	-- Face
	for _, side in { -1, 1 } do
		k:eye(CFrame.new(side * 0.42, 3.05, -0.3), {
			width = 0.52,
			height = 0.62,
			iris = rgb(90, 60, 30),
			look = Vector2.new(-0.4, 0),
			lid = 0.28,
			lidTilt = 15,
			skin = cheese,
			side = side,
		}, "Body")
		k:brow(CFrame.new(side * 0.44, 3.5, -0.3), 0.46, 18 * side, rgb(150, 80, 30), "Body")
	end
	k:mouth(CFrame.new(0, 2.6, -0.3), { width = 0.7, height = 0.34, skin = cheese, style = "Smirk" }, "Body")

	-- Chef hat on the tip, rolling pin in hand
	k:cylinder(
		"ChefHatBand",
		0.35,
		0.72,
		CFrame.new(0, 5.0, 0) * CFrame.Angles(0, 0, math.rad(-12)),
		C.White,
		Enum.Material.Fabric,
		"Body"
	)
	k:ellipsoid(
		"ChefHatPuff",
		v3(1.05, 0.72, 1.0),
		CFrame.new(0.08, 5.35, 0) * CFrame.Angles(0, 0, math.rad(-12)),
		C.White,
		Enum.Material.Fabric,
		"Body"
	)
	Parts.bareArm(k, "ArmR", v3(1.35, 2.3, 0), v3(1.95, 2.8, -0.5), 0.3, crust, 0.44)
	k:limb("RollingPin", v3(1.6, 2.35, -0.6), v3(2.3, 3.45, -0.55), 0.36, rgb(200, 150, 90), Enum.Material.Wood, "ArmR")
	Parts.bareArm(k, "ArmL", v3(-1.35, 2.3, 0), v3(-1.9, 1.65, -0.2), 0.3, crust, 0.44)

	Parts.legs(k, 1.4, 0.55, 0.4, crust, rgb(220, 40, 50), C.White, 0.8, crust)
	return body
end

Uncommon.DonutDetainee = function(k)
	local dough = rgb(225, 165, 95)
	local frosting = rgb(255, 135, 185)
	local ringR, tubeD = 1.35, 1.3
	local centerY = 3.0

	-- The donut stands on its edge; its hole is a big gaping mouth.
	local body: BasePart = nil :: any
	for i = 0, 15 do
		local angle = i * math.pi * 2 / 16
		local at = v3(math.cos(angle) * ringR, centerY + math.sin(angle) * ringR, 0)
		local part = k:ellipsoid("Dough", v3(tubeD, tubeD, tubeD * 0.95), CFrame.new(at), dough, nil, "Body")
		if i == 4 then
			body = part
		end
		if math.sin(angle) > -0.45 then
			k:ellipsoid(
				"Frosting",
				v3(tubeD * 0.95, tubeD * 0.95, 0.4),
				CFrame.new(at + v3(0, 0.02, -0.5)),
				frosting,
				nil,
				"Body"
			)
		end
	end
	for i, drip in { -2.1, -1.25, 1.1, 2.0 } do
		local x = math.cos(drip) * ringR * 1.15
		local y = centerY + math.sin(drip) * ringR * 0.6
		k:ellipsoid(
			"FrostingDrip",
			v3(0.34, 0.6 + (i % 2) * 0.2, 0.2),
			CFrame.new(x, y - 0.3, -0.6),
			frosting,
			nil,
			"Body"
		)
	end
	local sprinkleColors = { rgb(255, 255, 255), rgb(90, 190, 255), rgb(255, 230, 80), rgb(130, 230, 120) }
	for i = 0, 13 do
		local angle = i * math.pi * 2 / 14 + 0.2
		if math.sin(angle) > -0.35 then
			local at =
				v3(math.cos(angle) * (ringR + 0.25 * ((i % 3) - 1)), centerY + math.sin(angle) * (ringR + 0.2), -0.72)
			k:part(
				"Sprinkle",
				v3(0.3, 0.1, 0.08),
				CFrame.new(at) * CFrame.Angles(0, 0, i * 1.3),
				sprinkleColors[i % #sprinkleColors + 1],
				nil,
				"Body"
			)
		end
	end

	-- Teeth along the top of the hole, a tongue at the bottom, eyes above
	for i = -1, 1 do
		k:part("Tooth", v3(0.34, 0.34, 0.2), CFrame.new(i * 0.4, centerY + 0.62, -0.45), C.White, nil, "Body")
	end
	k:ellipsoid("HoleTongue", v3(0.9, 0.4, 0.6), CFrame.new(0, centerY - 0.62, -0.3), C.Tongue, nil, "Body")
	for _, side in { -1, 1 } do
		k:eye(
			CFrame.new(side * 0.55, centerY + 1.45, -0.75),
			{ width = 0.62, height = 0.74, iris = rgb(110, 60, 40), look = Vector2.new(0, -0.3), side = side },
			"Body"
		)
		k:brow(CFrame.new(side * 0.58, centerY + 1.98, -0.72), 0.5, -16 * side, rgb(120, 50, 70), "Body")
	end

	Parts.prisonCap(
		k,
		CFrame.new(0.2, centerY + ringR + tubeD * 0.4, 0) * CFrame.Angles(0, 0, math.rad(-10)),
		1.0,
		"Body"
	)

	-- Arms: one wearing a dangling handcuff
	Parts.bareArm(k, "ArmR", v3(ringR + 0.55, centerY - 0.2, 0), v3(2.5, 3.6, -0.4), 0.34, dough, 0.46)
	Parts.cuff(k, v3(2.35, 3.35, -0.35), 0.4, "ArmR")
	k:limb("CuffChain", v3(2.35, 3.25, -0.35), v3(2.45, 2.7, -0.4), 0.1, C.Iron, Enum.Material.Metal, "ArmR")
	Parts.cuff(k, v3(2.45, 2.55, -0.4), 0.36, "ArmR")
	Parts.bareArm(k, "ArmL", v3(-ringR - 0.55, centerY - 0.2, 0), v3(-2.3, 2.1, -0.2), 0.34, dough, 0.46)

	Parts.legs(k, 1.55, 0.55, 0.42, dough, rgb(90, 190, 255), C.White, 0.85, dough)
	return body
end

Uncommon.CactusCrook = function(k)
	local green = rgb(80, 170, 90)
	local greenDark = rgb(55, 130, 70)
	local spine = rgb(250, 245, 215)
	local pot = rgb(200, 100, 60)
	local column: Kit.Shell = { center = v3(0, 3.35, 0), radii = v3(0.85, 1.9, 0.85) }

	-- Saguaro column with ribs, arms raised: "caught!"
	local body = k:limb("Body", v3(0, 1.9, 0), v3(0, 4.9, 0), 1.7, green, nil, "Body")
	for _, angle in { -140, -40, 40, 140 } do
		local p1 = Kit.surface(column, angle, -35)
		local p2 = Kit.surface(column, angle, 45)
		k:limb("Rib", p1, p2, 0.16, greenDark, nil, "Body")
	end
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "ArmR" else "ArmL"
		local shoulder = v3(side * 0.7, 3.1, 0)
		local elbow = v3(side * 1.55, 3.05, 0)
		local hand = v3(side * 1.6, 4.25, 0)
		k:limb("CactusArm", shoulder, elbow, 0.75, green, nil, rig)
		k:limb("CactusArm", elbow, hand, 0.7, green, nil, rig)
		k.model:SetAttribute(rig .. "Joint", shoulder)
		for i = 0, 2 do
			k:ball("Spine", 0.12, hand + v3(side * 0.34, -0.3 * i, -0.1), spine, nil, rig)
		end
	end
	for i = 0, 11 do
		local yaw = (i * 67) % 360 - 180
		local pitch = -40 + (i * 29) % 90
		if math.abs(yaw) > 40 or pitch > 55 or pitch < -25 then
			local point = Kit.surface(column, yaw, pitch)
			k:ball("Spine", 0.14, point, spine, nil, "Body")
		end
	end

	-- Pink flower on top
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		k:ellipsoid(
			"Petal",
			v3(0.5, 0.2, 0.5),
			CFrame.new(math.cos(angle) * 0.32, 5.62, math.sin(angle) * 0.32),
			rgb(255, 110, 170),
			nil,
			"Body"
		)
	end
	k:ball("FlowerCenter", 0.36, v3(0, 5.72, 0), rgb(255, 225, 70), nil, "Body")

	-- Grumpy face
	k:eyes(column, 22, 18, {
		width = 0.52,
		height = 0.62,
		iris = rgb(60, 50, 40),
		look = Vector2.new(0, 0),
		lid = 0.35,
		lidTilt = 16,
		skin = green,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(Kit.on(column, 22 * side, 35, 0.03), 0.5, 22 * side, rgb(40, 60, 40), "Body")
	end
	k:mouth(Kit.on(column, 0, 0, -0.03), { width = 0.62, height = 0.32, skin = green, style = "Frown" }, "Body")

	-- Terracotta pot with a painted number, legs poking out underneath
	k:cylinder("Pot", 1.35, 2.1, CFrame.new(0, 1.7, 0), pot, nil, "Body")
	k:cylinder("PotRim", 0.35, 2.35, CFrame.new(0, 2.45, 0), pot:Lerp(Color3.new(1, 1, 1), 0.12), nil, "Body")
	k:cylinder("Soil", 0.1, 2.0, CFrame.new(0, 2.6, 0), rgb(90, 60, 40), nil, "Body")
	k:badge(CFrame.new(0, 1.7, -1.06), "#13", 0.8, "Body")
	Parts.legs(k, 1.1, 0.5, 0.42, pot, rgb(60, 60, 70), C.White, 0.85, pot)
	return body
end

return Uncommon
