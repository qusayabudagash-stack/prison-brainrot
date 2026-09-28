-- EPIC Brainrots: more detail, glowing bits and props. (Rarity effects are added in Effects.)

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Epic: { [string]: (Kit) -> BasePart } = {}

Epic.AlienPrisoner = function(k)
	local skin = rgb(140, 245, 130)
	local skinDark = rgb(95, 200, 100)
	local head: Kit.Shell = { center = v3(0, 4.15, -0.1), radii = v3(1.55, 1.4, 1.35) }
	local torso: Kit.Shell = { center = v3(0, 2.2, 0), radii = v3(0.9, 0.95, 0.8) }

	-- Small body in a jumpsuit, huge head
	local body = k:ellipsoid("Body", head.radii * 2, CFrame.new(head.center), skin, nil, "Body")
	k:ellipsoid("Jaw", v3(1.6, 1.2, 1.4), CFrame.new(0, 3.3, -0.35), skin, nil, "Body")
	k:ellipsoid("Torso", torso.radii * 2, CFrame.new(torso.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", torso, 2.95, 0.22, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(torso, 0, 12, 0.02), "#51", 0.6, "Body")

	-- Big glossy almond eyes, tiny mouth, antennae
	for _, side in { -1, 1 } do
		local at = Kit.on(head, 28 * side, 0, -0.05) * CFrame.Angles(0, 0, math.rad(-28 * side))
		k:ellipsoid("AlienEye", v3(0.95, 1.35, 0.4), at, rgb(15, 15, 25), Enum.Material.Glass, "Body")
		k:ball("Highlight", 0.26, (at * CFrame.new(-0.18 * side, 0.3, -0.18)).Position, C.White, nil, "Body")
		k:ball("Highlight2", 0.12, (at * CFrame.new(0.15 * side, -0.25, -0.18)).Position, C.White, nil, "Body")
		local base = Kit.surface(head, 25 * side, 60)
		k:limb("Antenna", base, base + v3(side * 0.35, 1.1, 0.1), 0.12, skinDark, nil, "Body")
		k:ball("AntennaTip", 0.4, base + v3(side * 0.4, 1.25, 0.1), rgb(255, 120, 230), Enum.Material.Neon, "Body")
		k:blush(Kit.on(head, 45 * side, -18, -0.02), 0.45, "Body")
	end
	k:mouth(
		Kit.on({ center = v3(0, 3.3, -0.35), radii = v3(0.8, 0.6, 0.7) }, 0, -10, -0.03),
		{ width = 0.55, height = 0.28, skin = skin, style = "Smile" },
		"Body"
	)

	-- Ray gun and a glowing ankle monitor
	Parts.arm(k, "ArmR", v3(0.8, 2.6, 0), v3(1.45, 2.55, -0.65), 0.3, C.Jumpsuit, skin, 0.4)
	k:cylinder(
		"RayGun",
		0.7,
		0.3,
		CFrame.new(1.5, 2.65, -1.05) * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(200, 205, 220),
		Enum.Material.Metal,
		"ArmR"
	)
	k:ball("RayGunTip", 0.3, v3(1.5, 2.65, -1.45), rgb(120, 255, 200), Enum.Material.Neon, "ArmR")
	for i = 0, 1 do
		k:cylinder(
			"RayGunRing",
			0.08,
			0.4,
			CFrame.new(1.5, 2.65, -0.95 - i * 0.2) * CFrame.Angles(math.pi / 2, 0, 0),
			rgb(255, 120, 230),
			Enum.Material.Neon,
			"ArmR"
		)
	end
	Parts.arm(k, "ArmL", v3(-0.8, 2.6, 0), v3(-1.35, 1.9, -0.2), 0.3, C.Jumpsuit, skin, 0.4)
	Parts.legs(k, 1.4, 0.4, 0.4, C.Jumpsuit, rgb(60, 60, 75), C.White, 0.8, C.JumpsuitDark)
	k:part("AnkleMonitor", v3(0.45, 0.32, 0.3), CFrame.new(0.44, 0.78, -0.3), rgb(40, 40, 50), nil, "Legs")
	k:ball("MonitorLight", 0.14, v3(0.44, 0.82, -0.47), rgb(120, 255, 120), Enum.Material.Neon, "Legs")
	return body
end

Epic.DiamondCriminal = function(k)
	local gem = rgb(150, 235, 255)
	local gemDark = rgb(90, 190, 240)
	local girdleY = 3.6
	local radius = 1.55
	local depth = 2.1

	-- Faceted gem: a pavilion of flipped wedges pointing down, a crown and a table on top
	local body: BasePart = nil :: any
	for i = 0, 7 do
		local angle = i * math.pi * 2 / 8
		local facet = CFrame.new(math.sin(angle) * radius / 2, girdleY - depth / 2, -math.cos(angle) * radius / 2)
			* CFrame.Angles(0, -angle, 0)
			* CFrame.Angles(0, 0, math.pi)
		local part = k:wedge(
			"Facet",
			v3(1.3, depth, radius),
			facet,
			if i % 2 == 0 then gem else gemDark,
			Enum.Material.Glass,
			"Body"
		)
		if i == 0 then
			body = part
		end
	end
	k:cylinder(
		"Girdle",
		0.25,
		radius * 2 + 0.1,
		CFrame.new(0, girdleY, 0),
		rgb(200, 245, 255),
		Enum.Material.Glass,
		"Body"
	)
	-- Crown: eight facets sloping up to the table, so the face on the front facet looks up at you
	local crownH, tableR = 1.25, 1.0
	local slope = radius - tableR
	k:cylinder(
		"CrownCore",
		crownH,
		tableR * 2,
		CFrame.new(0, girdleY + crownH / 2, 0),
		gem,
		Enum.Material.Glass,
		"Body"
	)
	for i = 0, 7 do
		local angle = i * math.pi * 2 / 8
		k:wedge(
			"Facet",
			v3(1.3, crownH, slope),
			CFrame.new(
				math.sin(angle) * (tableR + slope / 2),
				girdleY + crownH / 2,
				-math.cos(angle) * (tableR + slope / 2)
			) * CFrame.Angles(0, -angle, 0),
			if i % 2 == 0 then gemDark else gem,
			Enum.Material.Glass,
			"Body"
		)
	end
	k:cylinder(
		"Table",
		0.14,
		tableR * 2,
		CFrame.new(0, girdleY + crownH + 0.07, 0),
		rgb(220, 250, 255),
		Enum.Material.Glass,
		"Body"
	)

	-- Cool face on the front facet: shades and a smug grin
	local normal = v3(0, slope, -crownH).Unit
	local function onFacet(t: number, x: number, out: number): CFrame
		local at = v3(x, girdleY + t * crownH, -(radius - t * slope)) + normal * out
		return CFrame.lookAt(at, at + normal)
	end
	for _, side in { -1, 1 } do
		local lens = onFacet(0.62, side * 0.3, 0.06)
		k:ellipsoid("Shades", v3(0.52, 0.36, 0.12), lens, rgb(25, 25, 40), Enum.Material.Glass, "Body")
		k:ball(
			"ShadesShine",
			0.1,
			(lens * CFrame.new(-0.1 * side, 0.06, -0.06)).Position,
			rgb(200, 220, 255),
			nil,
			"Body"
		)
	end
	k:part("ShadesBridge", v3(0.22, 0.07, 0.07), onFacet(0.66, 0, 0.08), C.Gold, Enum.Material.Metal, "Body")
	k:mouth(onFacet(0.24, 0, 0), { width = 0.66, height = 0.3, skin = gem, style = "Smirk", radius = 4 }, "Body")
	Parts.goldChain(k, { center = v3(0, girdleY - 0.5, 0), radii = v3(1.2, 1, 1.2) }, girdleY - 0.35, "$", "Body")

	-- Gold limbs, one arm resting a crowbar on the shoulder
	Parts.bareArm(k, "ArmR", v3(1.35, girdleY - 0.3, 0), v3(1.9, girdleY - 0.1, -0.5), 0.26, C.Gold, 0.4)
	k:limb(
		"Crowbar",
		v3(1.85, girdleY - 0.9, -0.55),
		v3(2.1, girdleY + 1.5, -0.45),
		0.16,
		rgb(220, 40, 50),
		Enum.Material.Metal,
		"ArmR"
	)
	k:limb(
		"CrowbarHook",
		v3(2.1, girdleY + 1.5, -0.45),
		v3(1.8, girdleY + 1.7, -0.45),
		0.16,
		rgb(220, 40, 50),
		Enum.Material.Metal,
		"ArmR"
	)
	Parts.bareArm(k, "ArmL", v3(-1.35, girdleY - 0.3, 0), v3(-1.7, girdleY - 1.1, -0.1), 0.26, C.Gold, 0.4)
	for _, side in { -1, 1 } do
		k:limb(
			"Leg",
			v3(side * 0.35, girdleY - 1.6, 0),
			v3(side * 0.6, 0.5, 0),
			0.28,
			C.Gold,
			Enum.Material.Foil,
			"Legs"
		)
		k:shoe(v3(side * 0.62, 0.5, 0), 0.85, rgb(30, 30, 40), C.Gold, "Legs")
	end
	return body
end

Epic.ClownConvict = function(k)
	local face = rgb(255, 245, 240)
	local shell: Kit.Shell = { center = v3(0, 4.05, -0.1), radii = v3(1.15, 1.1, 1.05) }
	local torso: Kit.Shell = { center = v3(0, 2.3, 0), radii = v3(1.25, 1.15, 1.1) }

	-- Striped prison suit with big pom-pom buttons
	local body = k:ellipsoid("Body", torso.radii * 2, CFrame.new(torso.center), C.White, Enum.Material.Fabric, "Body")
	Parts.stripes(k, torso, 1.4, 3.2, 4, C.Stripe, "Body")
	for i, color in { rgb(255, 60, 60), rgb(60, 150, 255), rgb(255, 220, 50) } do
		k:ball("PomButton", 0.34, Kit.surface(torso, 0, 30 - i * 22), color, Enum.Material.Fabric, "Body")
	end
	-- Ruffled collar
	for i = 0, 9 do
		local angle = i * math.pi * 2 / 10
		k:ellipsoid(
			"Ruffle",
			v3(0.7, 0.35, 0.7),
			CFrame.new(math.cos(angle) * 0.95, 3.35, math.sin(angle) * 0.9),
			if i % 2 == 0 then C.White else rgb(255, 210, 230),
			Enum.Material.Fabric,
			"Body"
		)
	end

	-- Painted clown face, red nose, rainbow afro
	k:ellipsoid("Head", shell.radii * 2, CFrame.new(shell.center), face, nil, "Body")
	k:eyes(
		shell,
		24,
		14,
		{ width = 0.55, height = 0.66, iris = rgb(60, 130, 230), look = Vector2.new(0, 0.2), skin = face },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"FacePaint",
			v3(0.3, 0.55, 0.06),
			Kit.on(shell, 24 * side, 34, 0.01),
			rgb(60, 130, 230),
			nil,
			"Body"
		)
		k:ellipsoid(
			"FacePaint",
			v3(0.2, 0.45, 0.06),
			Kit.on(shell, 24 * side, -4, 0.01),
			rgb(60, 130, 230),
			nil,
			"Body"
		)
	end
	k:ball("ClownNose", 0.52, Kit.surface(shell, 0, 0) + v3(0, 0, -0.12), rgb(245, 30, 40), nil, "Body")
	k:ellipsoid("SmilePaint", v3(1.4, 0.72, 0.1), Kit.on(shell, 0, -26, -0.02), rgb(230, 40, 60), nil, "Body")
	k:mouth(
		Kit.on(shell, 0, -26, -0.01),
		{ width = 1.05, height = 0.5, skin = rgb(230, 40, 60), style = "Grin" },
		"Body"
	)
	local afro = {
		rgb(255, 70, 70),
		rgb(255, 170, 40),
		rgb(255, 230, 60),
		rgb(80, 210, 90),
		rgb(60, 150, 255),
		rgb(170, 90, 255),
	}
	for i = 0, 11 do
		local yaw = (i % 6) * 60 - 150
		local pitch = if i < 6 then 35 else 70
		local point = Kit.surface(shell, yaw, pitch)
		k:ball("Afro", 0.95, point, afro[i % #afro + 1], Enum.Material.Fabric, "Body")
	end
	for _, side in { -1, 1 } do
		k:ball(
			"Afro",
			1.05,
			shell.center + v3(side * 1.2, 0.4, 0.3),
			afro[if side > 0 then 1 else 5],
			Enum.Material.Fabric,
			"Body"
		)
	end

	-- Juggling balls orbiting above the hands
	Parts.arm(k, "ArmR", v3(1.15, 2.85, 0), v3(1.7, 3.3, -0.5), 0.42, C.White, face, 0.52)
	Parts.arm(k, "ArmL", v3(-1.15, 2.85, 0), v3(-1.7, 3.3, -0.5), 0.42, C.White, face, 0.52)
	for i, color in { rgb(255, 60, 60), rgb(60, 150, 255), rgb(255, 220, 50) } do
		local angle = i * math.pi * 2 / 3
		k:ball("JuggleBall", 0.42, v3(math.cos(angle) * 1.6, 4.7 + math.sin(angle) * 0.4, -0.7), color, nil, "Orbit")
	end

	-- Enormous clown shoes
	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.5, 1.3, 0), v3(side * 0.55, 0.5, 0), 0.48, C.White, Enum.Material.Fabric, "Legs")
		k:ellipsoid("ClownShoe", v3(1.05, 0.7, 2.1), CFrame.new(side * 0.6, 0.33, -0.55), rgb(230, 40, 50), nil, "Legs")
		k:ellipsoid("ShoeSole", v3(1.1, 0.25, 2.15), CFrame.new(side * 0.6, 0.1, -0.55), C.White, nil, "Legs")
	end
	return body
end

Epic.NinjaNoodle = function(k)
	local bowl = rgb(215, 45, 50)
	local noodle = rgb(255, 225, 130)
	local broth: Kit.Shell = { center = v3(0, 2.75, 0), radii = v3(1.55, 1.25, 1.55) }

	-- Ramen bowl body with a white rim and a wave pattern
	local body = k:ellipsoid("Body", v3(3.1, 2.5, 3.1), CFrame.new(broth.center), bowl, nil, "Body")
	k:cylinder("BowlRim", 0.3, 3.3, CFrame.new(0, 3.72, 0), C.White, nil, "Body")
	k:cylinder("Broth", 0.12, 2.9, CFrame.new(0, 3.84, 0), rgb(220, 160, 90), nil, "Body")
	k:cylinder("BowlFoot", 0.4, 1.6, CFrame.new(0, 1.45, 0), bowl:Lerp(Color3.new(0, 0, 0), 0.2), nil, "Body")

	-- Noodle hair, a boiled egg and a fish cake on top
	for i = 0, 8 do
		local x = (i % 3 - 1) * 0.55
		local z = (i // 3 - 1) * 0.5
		k:limb(
			"Noodle",
			v3(x, 3.85, z),
			v3(x + math.sin(i) * 0.35, 4.75 + (i % 2) * 0.35, z + math.cos(i) * 0.2),
			0.2,
			noodle,
			nil,
			"Body"
		)
	end
	k:ellipsoid(
		"Egg",
		v3(0.85, 0.35, 0.65),
		CFrame.new(0.8, 3.95, -0.4) * CFrame.Angles(0, 0, 0.2),
		C.White,
		nil,
		"Body"
	)
	k:ellipsoid(
		"Yolk",
		v3(0.42, 0.2, 0.35),
		CFrame.new(0.8, 4.08, -0.45) * CFrame.Angles(0, 0, 0.2),
		rgb(255, 170, 40),
		nil,
		"Body"
	)
	k:disc(
		"FishCake",
		0.6,
		0.12,
		CFrame.new(-0.85, 4.05, -0.45) * CFrame.Angles(math.rad(-60), 0, 0),
		C.White,
		nil,
		"Body"
	)
	k:disc(
		"FishCakeSwirl",
		0.3,
		0.14,
		CFrame.new(-0.85, 4.07, -0.47) * CFrame.Angles(math.rad(-60), 0, 0),
		rgb(255, 120, 170),
		nil,
		"Body"
	)

	-- Ninja mask and headband with trailing tails
	k:band("NinjaMask", broth, 3.15, 0.42, rgb(30, 30, 40), Enum.Material.Fabric, "Body")
	k:band("Headband", broth, 3.55, 0.2, rgb(30, 30, 40), Enum.Material.Fabric, "Body")
	k:part(
		"HeadbandPlate",
		v3(0.8, 0.28, 0.08),
		Kit.on(broth, 0, 42, 0.12),
		rgb(200, 205, 215),
		Enum.Material.Metal,
		"Body"
	)
	for _, side in { -1, 1 } do
		k:limb(
			"BandTail",
			v3(side * 0.2, 3.55, 1.5),
			v3(side * 0.7, 3.1, 2.3),
			0.2,
			rgb(30, 30, 40),
			Enum.Material.Fabric,
			"Body"
		)
	end
	k:eyes(broth, 21, 18, {
		width = 0.62,
		height = 0.6,
		iris = rgb(200, 60, 60),
		look = Vector2.new(0.2, 0),
		lid = 0.22,
		lidTilt = 26,
		skin = rgb(30, 30, 40),
	}, "Body")
	k:mouth(Kit.on(broth, 0, -8, -0.02), { width = 0.6, height = 0.32, skin = bowl, style = "Smirk" }, "Body")

	-- Chopsticks crossed on the back like katanas
	for _, side in { -1, 1 } do
		k:limb(
			"Chopstick",
			v3(side * 0.9, 2.2, 1.35),
			v3(-side * 0.9, 5.2, 1.45),
			0.14,
			rgb(140, 90, 50),
			Enum.Material.Wood,
			"Body"
		)
	end
	Parts.bareArm(k, "ArmR", v3(1.5, 2.8, 0), v3(2.2, 3.1, -0.4), 0.3, rgb(250, 230, 200), 0.44)
	Parts.bareArm(k, "ArmL", v3(-1.5, 2.8, 0), v3(-2.1, 2.3, -0.4), 0.3, rgb(250, 230, 200), 0.44)
	Parts.legs(k, 1.4, 0.45, 0.4, rgb(30, 30, 40), rgb(30, 30, 40), rgb(200, 200, 205), 0.8)
	return body
end

Epic.PirateParrot = function(k)
	local red = rgb(230, 50, 50)
	local yellow = rgb(255, 210, 50)
	local blue = rgb(40, 120, 230)
	local shell: Kit.Shell = { center = v3(0, 2.85, 0), radii = v3(1.3, 1.7, 1.3) }
	local shirt: Kit.Shell = { center = v3(0, 2.3, 0), radii = v3(1.38, 1.1, 1.38) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), red, nil, "Body")
	k:ellipsoid("Shirt", shirt.radii * 2, CFrame.new(shirt.center), C.White, Enum.Material.Fabric, "Body")
	Parts.stripes(k, shirt, 1.4, 3.2, 3, rgb(40, 60, 140), "Body")
	k:band("Sash", shirt, 1.55, 0.3, rgb(20, 20, 30), Enum.Material.Fabric, "Body")
	k:part("SashBuckle", v3(0.35, 0.3, 0.08), Kit.on(shirt, 0, -48, 0.08), C.Gold, Enum.Material.Foil, "Body")

	-- Hooked beak, one eye and an eyepatch
	local beak = Kit.on(shell, 0, 18, 0.1)
	k:ellipsoid("Beak", v3(0.7, 0.75, 0.9), beak, yellow, nil, "Body")
	k:ellipsoid(
		"BeakHook",
		v3(0.35, 0.45, 0.35),
		beak * CFrame.new(0, -0.35, -0.3),
		yellow:Lerp(Color3.new(0, 0, 0), 0.25),
		nil,
		"Body"
	)
	k:eye(Kit.on(shell, 22, 34, -0.06), {
		width = 0.62,
		height = 0.72,
		iris = rgb(40, 40, 40),
		look = Vector2.new(-0.3, 0),
		lid = 0.2,
		lidTilt = 14,
		skin = red,
		side = 1,
	}, "Body")
	k:ellipsoid("EyePatch", v3(0.66, 0.66, 0.2), Kit.on(shell, -22, 34, 0.02), rgb(20, 20, 25), nil, "Body")
	k:band("PatchStrap", shell, 4.1, 0.1, rgb(20, 20, 25), nil, "Body")

	-- Tricorn hat with a skull
	local hat = CFrame.new(0, 4.4, 0.05)
	k:ellipsoid("TricornBrim", v3(2.8, 0.35, 2.1), hat, rgb(25, 25, 30), nil, "Body")
	k:ellipsoid("Tricorn", v3(1.9, 0.9, 1.5), hat * CFrame.new(0, 0.3, 0), rgb(25, 25, 30), nil, "Body")
	k:ellipsoid("SkullMark", v3(0.36, 0.34, 0.1), hat * CFrame.new(0, 0.35, -0.72), C.White, nil, "Body")
	k:part("HatTrim", v3(2.2, 0.08, 0.1), hat * CFrame.new(0, 0.12, -0.85), C.Gold, Enum.Material.Foil, "Body")

	-- Wings with blue and yellow tips, one holding a toy cutlass
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "ArmR" else "ArmL"
		local root = v3(side * 1.2, 3.0, 0.1)
		local tip = v3(side * 1.9, if side > 0 then 3.4 else 2.1, -0.4)
		k:limb("Wing", root, tip, 0.65, red, nil, rig)
		k:limb("WingTip", tip, tip + v3(side * 0.35, -0.35, 0.1), 0.45, blue, nil, rig)
		k:limb("WingTip", tip + v3(0, -0.25, 0), tip + v3(side * 0.25, -0.65, 0.1), 0.35, yellow, nil, rig)
		k.model:SetAttribute(rig .. "Joint", root)
	end
	k:limb("Cutlass", v3(2.0, 3.35, -0.55), v3(2.3, 4.9, -0.6), 0.14, rgb(210, 215, 225), Enum.Material.Metal, "ArmR")
	k:part("CutlassGuard", v3(0.5, 0.1, 0.2), CFrame.new(2.02, 3.45, -0.55), C.Gold, Enum.Material.Foil, "ArmR")
	for i, color in { blue, yellow, red } do
		k:limb("TailFeather", v3(0, 1.8, 1.1), v3((i - 2) * 0.3, 0.4, 1.8), 0.35, color, nil, "Body")
	end

	-- One bird leg, one peg leg
	k:limb("Leg", v3(0.45, 1.3, 0), v3(0.45, 0.2, 0), 0.22, yellow, nil, "Legs")
	for _, angle in { -30, 0, 30 } do
		k:limb(
			"Toe",
			v3(0.45, 0.18, 0),
			v3(0.45 + math.sin(math.rad(angle)) * 0.5, 0.1, -0.5),
			0.18,
			yellow,
			nil,
			"Legs"
		)
	end
	k:limb("PegLeg", v3(-0.45, 1.3, 0), v3(-0.45, 0.12, 0), 0.3, rgb(150, 100, 55), Enum.Material.Wood, "Legs")
	k:cylinder("PegTip", 0.12, 0.34, CFrame.new(-0.45, 0.06, 0), rgb(60, 50, 40), nil, "Legs")
	return body
end

return Epic
