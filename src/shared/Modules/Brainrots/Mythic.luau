-- MYTHIC Brainrots: every one is a small spectacle with a signature silhouette you can read from
-- across the prison. Their auras and particles come from Effects.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Mythic: { [string]: (Kit) -> BasePart } = {}

local function label(part: BasePart, text: string, color: Color3, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.Parent = part
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true
	textLabel.TextColor3 = color
	textLabel.Text = text
	textLabel.Parent = gui
end

Mythic.CosmicPrisoner = function(k)
	local space = rgb(46, 30, 118)
	local nebulaPink = rgb(200, 80, 220)
	local nebulaBlue = rgb(70, 130, 245)
	local shell: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(1.75, 1.8, 1.65) }
	local suit: Kit.Shell = { center = v3(0, 2.0, 0), radii = v3(1.82, 1.12, 1.72) }

	-- A planet-sized inmate: deep space body with nebula clouds and stars
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), space, nil, "Body")
	for i, spec in
		{
			{ yaw = -62, pitch = 38, size = 1.5, color = nebulaPink },
			{ yaw = 66, pitch = 52, size = 1.2, color = nebulaBlue },
			{ yaw = 150, pitch = 25, size = 1.7, color = nebulaPink },
			{ yaw = -135, pitch = 50, size = 1.4, color = nebulaBlue },
			{ yaw = 12, pitch = 68, size = 1.1, color = nebulaBlue },
		}
	do
		local cloud = Parts.patch(
			k,
			"Nebula",
			shell,
			spec.yaw,
			spec.pitch,
			spec.size,
			spec.size * 0.55,
			spec.color,
			nil,
			"Body",
			i * 37
		)
		cloud.Transparency = 0.2
	end
	Parts.starSpecks(k, shell, 34, { C.White, rgb(255, 230, 150), rgb(150, 220, 255) }, -5, 85, "Body")

	-- Orange jumpsuit on the lower half
	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 2.52, 0.24, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, 8, 0.02), "#42", 0.8, "Body")

	-- Saturn ring around the middle, tilted towards the viewer
	local ring = CFrame.new(0, 2.95, 0)
		* CFrame.Angles(math.rad(-6), 0, math.rad(20))
		* CFrame.Angles(math.pi / 2, 0, 0)
	k:disc("PlanetRing", 5.0, 0.06, ring, rgb(255, 214, 160), nil, "Body")
	k:disc("PlanetRingBand", 4.55, 0.09, ring, rgb(235, 150, 255), Enum.Material.Neon, "Body")
	k:disc("PlanetRingInner", 4.25, 0.12, ring, rgb(255, 235, 200), nil, "Body")

	-- Starry-eyed, delighted face
	k:eyes(
		shell,
		22,
		24,
		{ width = 0.8, height = 0.95, iris = rgb(110, 200, 255), look = Vector2.new(0, 0.25), skin = space },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ball("EyeStar", 0.16, (Kit.on(shell, 22 * side + 4, 28, 0.2)).Position, C.White, Enum.Material.Neon, "Body")
		k:blush(Kit.on(shell, 42 * side, 8, -0.02), 0.5, "Body")
	end
	k:mouth(
		Kit.on(shell, 0, 4, -0.02),
		{ width = 0.95, height = 0.52, skin = space, style = "Grin", radius = 1.7 },
		"Body"
	)

	-- Arms thrown up in cosmic joy, white gloves
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "ArmR" else "ArmL"
		local shoulder = v3(side * 1.5, 3.35, -0.05)
		local hand = v3(side * 2.35, 4.35, -0.35)
		k:limb("Arm", shoulder, hand, 0.44, space, nil, rig)
		k:ball("Hand", 0.62, hand, C.White, nil, rig)
		k:cylinder(
			"GloveCuff",
			0.16,
			0.56,
			CFrame.lookAt(hand:Lerp(shoulder, 0.28), shoulder) * CFrame.Angles(math.pi / 2, 0, 0),
			C.White,
			nil,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end

	-- A little moon and a snack-sized planet in orbit
	local moon = v3(2.7, 4.9, 0.4)
	k:ball("Moon", 0.6, moon, rgb(225, 225, 235), nil, "Orbit")
	k:ball("MoonCrater", 0.16, moon + v3(-0.12, 0.08, -0.26), rgb(175, 175, 190), nil, "Orbit")
	k:ball("MoonCrater", 0.1, moon + v3(0.12, -0.12, -0.26), rgb(175, 175, 190), nil, "Orbit")
	local planet = v3(-2.8, 1.5, 0.6)
	k:ball("MiniPlanet", 0.5, planet, rgb(255, 150, 90), nil, "Orbit")
	k:disc(
		"MiniPlanetRing",
		0.85,
		0.04,
		CFrame.new(planet) * CFrame.Angles(math.pi / 2 - 0.3, 0, 0.2),
		rgb(255, 225, 170),
		nil,
		"Orbit"
	)

	Parts.legs(k, 1.2, 0.62, 0.6, C.Jumpsuit, C.White, rgb(150, 90, 230), 1, C.JumpsuitDark)
	return body
end

Mythic.SkullBoss = function(k)
	local bone = rgb(246, 240, 224)
	local boneShade = rgb(212, 202, 180)
	local socket = rgb(45, 32, 45)
	local jacket = rgb(32, 30, 38)
	local head: Kit.Shell = { center = v3(0, 4.7, -0.05), radii = v3(1.45, 1.35, 1.35) }
	local torso: Kit.Shell = { center = v3(0, 2.35, 0), radii = v3(1.35, 1.15, 1.1) }

	-- Leather jacket over an orange jumpsuit, gold chain
	local body = k:ellipsoid("Body", torso.radii * 2, CFrame.new(torso.center), jacket, Enum.Material.Leather, "Body")
	Parts.patch(k, "Shirt", torso, 0, 12, 0.95, 2.0, C.Jumpsuit, Enum.Material.Fabric, "Body")
	for _, side in { -1, 1 } do
		Parts.patch(
			k,
			"Lapel",
			torso,
			17 * side,
			22,
			0.42,
			1.25,
			rgb(48, 45, 55),
			Enum.Material.Leather,
			"Body",
			-14 * side
		)
	end
	Parts.goldChain(k, torso, 3.05, "gem", "Body")

	-- Skull: cranium, cheekbones, jaw and a row of teeth
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), bone, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid("Cheekbone", v3(0.9, 0.62, 0.75), CFrame.new(side * 0.78, 4.12, -0.78), bone, nil, "Body")
		k:ellipsoid(
			"Nostril",
			v3(0.2, 0.34, 0.12),
			Kit.on(head, 7 * side, -20, 0.01) * CFrame.Angles(0, 0, math.rad(-22 * side)),
			socket,
			nil,
			"Body"
		)
	end
	k:ellipsoid("Jaw", v3(1.75, 0.8, 1.45), CFrame.new(0, 3.55, -0.35), bone, nil, "Body")
	local gap = { center = v3(0, 3.86, -0.42), radii = v3(0.8, 0.16, 0.72) }
	k:ellipsoid("Mouth", gap.radii * 2, CFrame.new(gap.center), socket, nil, "Body")
	for i = -2, 2 do
		local x = i * 0.25
		local z = gap.center.Z - gap.radii.Z * math.sqrt(1 - (x / (gap.radii.X + 0.05)) ^ 2)
		local at = v3(x, gap.center.Y, z)
		k:part(
			"Teeth",
			v3(0.21, 0.3, 0.1),
			CFrame.lookAt(at, at + (at - gap.center) * v3(1, 0, 1)),
			C.White,
			nil,
			"Body"
		)
	end
	-- A battle crack on the forehead
	local crackA, crackB, crackC = Kit.surface(head, -38, 52), Kit.surface(head, -28, 38), Kit.surface(head, -40, 28)
	k:limb("Crack", crackA, crackB, 0.07, boneShade:Lerp(socket, 0.5), nil, "Body")
	k:limb("Crack", crackB, crackC, 0.06, boneShade:Lerp(socket, 0.5), nil, "Body")

	-- Shades at night, with a purple glint, and a tilted crown
	Parts.sunglasses(k, head, 26, 10, 0.98, C.Gold, rgb(18, 16, 26), "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"ShadesGlint",
			v3(0.5, 0.06, 0.04),
			Kit.on(head, 26 * side, 12, 0.19) * CFrame.Angles(0, 0, math.rad(28)),
			rgb(190, 110, 255),
			Enum.Material.Neon,
			"Body"
		)
	end
	Parts.crown(k, CFrame.new(0.2, 5.8, 0.05) * CFrame.Angles(0, 0, math.rad(-12)), 1.45, rgb(150, 70, 255), "Body")

	-- Bony hands, a gold-topped cane
	Parts.arm(k, "ArmR", v3(1.25, 3.0, 0), v3(1.95, 2.05, -0.55), 0.58, jacket, bone, 0.56, Enum.Material.Leather)
	k:limb("Cane", v3(2.0, 0.1, -0.7), v3(1.97, 2.35, -0.6), 0.16, rgb(35, 30, 40), nil, "ArmR")
	k:ball("CaneTop", 0.42, v3(1.97, 2.45, -0.6), C.Gold, Enum.Material.Foil, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.25, 3.0, 0), v3(-1.75, 1.85, -0.45), 0.58, jacket, bone, 0.56, Enum.Material.Leather)
	for _, side in { -1, 1 } do
		k:ball(
			"Knuckle",
			0.2,
			v3(side * 1.95, 2.05, -0.55) + v3(0, 0.12, -0.24),
			boneShade,
			nil,
			if side > 0 then "ArmR" else "ArmL"
		)
	end

	Parts.legs(k, 1.35, 0.58, 0.6, C.Jumpsuit, C.White, rgb(150, 70, 255), 1.05, C.JumpsuitDark)
	return body
end

Mythic.IQInmate = function(k)
	local pink = rgb(250, 140, 178)
	local ridge = rgb(255, 172, 200)
	local groove = rgb(205, 90, 130)
	local brain: Kit.Shell = { center = v3(0, 4.35, 0), radii = v3(1.78, 1.42, 1.62) }
	local torso: Kit.Shell = { center = v3(0, 2.05, 0), radii = v3(1.15, 1.0, 1.0) }

	-- The brain is the head: raised folds over both hemispheres and a deep middle groove
	local body = k:ellipsoid("Body", brain.radii * 2, CFrame.new(brain.center), pink, nil, "Body")
	for _, side in { -1, 1 } do
		for r = 0, 3 do
			local pitch = 38 + r * 13
			local points = {}
			for j = 0, 4 do
				local yaw = side * (14 + j * 38 - r * 4)
				table.insert(points, (Kit.surface(brain, yaw, pitch + math.sin(j * 1.9 + r) * 6)))
			end
			for j = 1, #points - 1 do
				k:limb("Fold", points[j], points[j + 1], 0.36, ridge, nil, "Body")
			end
		end
	end
	local fissure = {
		Kit.surface(brain, 0, 40),
		Kit.surface(brain, 0, 66),
		Kit.surface(brain, 0, 89),
		(Kit.surface(brain, 180, 60)),
	}
	for j = 1, #fissure - 1 do
		k:limb("Groove", fissure[j], fissure[j + 1], 0.16, groove, nil, "Body")
	end

	-- Face under the folds: big round glasses, one eyebrow raised, smug smirk
	for _, side in { -1, 1 } do
		local eye = Kit.on(brain, 24 * side, 5, 0)
		k:disc("GlassesRim", 1.08, 0.08, eye * CFrame.new(0, 0, -0.03), rgb(30, 30, 40), nil, "Body")
		k:disc(
			"GlassesLens",
			0.96,
			0.05,
			eye * CFrame.new(0, 0, -0.32),
			rgb(200, 235, 255),
			Enum.Material.Glass,
			"Body"
		).Transparency =
			0.65
		k:brow(
			Kit.on(brain, 24 * side, 24 + (if side > 0 then 4 else 0), 0.03),
			0.55,
			if side > 0 then -16 else 6,
			groove,
			"Body"
		)
	end
	k:eyes(
		brain,
		24,
		5,
		{ width = 0.6, height = 0.68, iris = rgb(70, 140, 230), look = Vector2.new(0.3, 0.1), lid = 0.2, skin = pink },
		"Body"
	)
	k:part("GlassesBridge", v3(0.45, 0.08, 0.08), Kit.on(brain, 0, 8, 0.1), rgb(30, 30, 40), nil, "Body")
	k:mouth(
		Kit.on(brain, 0, -26, -0.02),
		{ width = 0.7, height = 0.28, skin = pink, style = "Smirk", radius = 1.5 },
		"Body"
	)

	-- Small body in a jumpsuit with a pocket protector full of pens
	k:ellipsoid("Torso", torso.radii * 2, CFrame.new(torso.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(torso, 22, 18, 0.02), "#9000", 0.62, "Body")
	local pocket = Kit.on(torso, -26, 18, 0.03)
	k:part("Pocket", v3(0.5, 0.4, 0.08), pocket, rgb(245, 245, 250), Enum.Material.Plastic, "Body")
	for i, color in { rgb(40, 110, 230), rgb(230, 50, 60), rgb(40, 40, 50) } do
		k:cylinder("Pen", 0.42, 0.08, pocket * CFrame.new((i - 2) * 0.13, 0.22, 0.02), color, nil, "Body")
	end

	-- A textbook in one hand, the other pointing up with an idea
	Parts.arm(k, "ArmL", v3(-1.05, 2.5, 0), v3(-1.5, 1.8, -0.55), 0.46, C.Jumpsuit, pink, 0.5)
	local book = k:part(
		"Book",
		v3(0.95, 1.2, 0.3),
		CFrame.new(-1.5, 2.05, -0.8) * CFrame.Angles(0, math.rad(20), math.rad(8)),
		rgb(40, 90, 200),
		nil,
		"ArmL"
	)
	label(book, "E=mc²", C.Gold)
	k:part("BookPages", v3(0.85, 1.1, 0.24), book.CFrame * CFrame.new(0.07, 0, 0), rgb(250, 248, 235), nil, "ArmL")
	Parts.arm(k, "ArmR", v3(1.05, 2.5, 0), v3(1.55, 3.55, -0.4), 0.46, C.Jumpsuit, pink, 0.5)
	k:limb("Finger", v3(1.55, 3.7, -0.42), v3(1.58, 4.1, -0.44), 0.18, pink, nil, "ArmR")
	k:ball("IdeaSpark", 0.3, v3(1.7, 4.55, -0.45), rgb(255, 240, 120), Enum.Material.Neon, "ArmR")

	Parts.gradCap(k, CFrame.new(0.45, 5.66, 0.15) * CFrame.Angles(0, math.rad(20), math.rad(-16)), 1.35, "Body")
	Parts.legs(k, 1.25, 0.5, 0.5, C.Jumpsuit, rgb(120, 80, 60), rgb(60, 40, 30), 0.9, C.JumpsuitDark)
	return body
end

Mythic.VolcanoVillain = function(k)
	local rock = rgb(112, 74, 58)
	local rockDark = rgb(80, 54, 46)
	local lava = rgb(255, 110, 20)
	local lavaHot = rgb(255, 205, 70)
	-- A tall shell sunk into the ground reads as a mountain; a wide skirt flares its foot.
	local cone: Kit.Shell = { center = v3(0, -1.5, 0), radii = v3(2.5, 5.8, 2.3) }
	local skirt: Kit.Shell = { center = v3(0, 0.25, 0), radii = v3(2.95, 0.8, 2.75) }

	local body = k:ellipsoid("Body", cone.radii * 2, CFrame.new(cone.center), rock, Enum.Material.Slate, "Body")
	k:ellipsoid("Skirt", skirt.radii * 2, CFrame.new(skirt.center), rockDark, Enum.Material.Slate, "Body")
	for i, spec in { { -120, 45, 0.9 }, { 140, 52, 0.8 }, { 95, 40, 1.0 }, { -70, 48, 0.7 }, { 175, 62, 0.7 } } do
		Parts.patch(
			k,
			"Boulder",
			cone,
			spec[1],
			spec[2],
			spec[3],
			spec[3] * 0.7,
			if i % 2 == 0 then rockDark else rock:Lerp(C.White, 0.08),
			Enum.Material.Slate,
			"Body"
		)
	end

	-- Crater: dark rim, bubbling lava cap, fire and smoke
	k:band("CraterRim", cone, 3.72, 0.34, rockDark, Enum.Material.Slate, "Body")
	local pool = k:ellipsoid("Lava", v3(2.2, 1.0, 2.0), CFrame.new(0, 3.95, 0), lava, Enum.Material.Neon, "Body")
	k:ball("LavaBlob", 0.5, v3(-0.3, 4.45, 0.05), lavaHot, Enum.Material.Neon, "Body")
	k:ball("LavaBlob", 0.34, v3(0.35, 4.7, -0.1), lavaHot, Enum.Material.Neon, "Body")
	k:ball("LavaBlob", 0.22, v3(0.05, 5.05, 0.1), lavaHot, Enum.Material.Neon, "Body")
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 12
	fire.Color = lava
	fire.SecondaryColor = rgb(255, 60, 20)
	fire.Parent = pool
	local smoke = Instance.new("Smoke")
	smoke.Color = rgb(90, 80, 80)
	smoke.Opacity = 0.12
	smoke.RiseVelocity = 4
	smoke.Size = 1.5
	smoke.Parent = pool

	-- Lava running down the slopes, glowing cracks near the foot
	for _, yaw in { -150, -62, 58, 148 } do
		local a = Kit.surface(cone, yaw, 76)
		local b = Kit.surface(cone, yaw + 5, 66)
		local c = Kit.surface(cone, yaw + 12, 52 - math.abs(yaw) / 25)
		k:limb("LavaDrip", a, b, 0.34, lava, Enum.Material.Neon, "Body")
		k:limb("LavaDrip", b, c, 0.28, lava, Enum.Material.Neon, "Body")
		k:ball("LavaDrop", 0.36, c, lavaHot, Enum.Material.Neon, "Body")
	end
	for _, yaw in { -40, 35, 120, -150 } do
		local p1 = Kit.surface(skirt, yaw, 30)
		local p2 = Kit.surface(skirt, yaw + 9, 5)
		k:limb("Crack", p1, p2, 0.12, lava, Enum.Material.Neon, "Body")
	end

	-- Furious face: glowing eyes under heavy rock brows, gritted teeth
	k:eyes(
		cone,
		20,
		70,
		{ width = 0.72, height = 0.78, iris = lava, look = Vector2.new(0, -0.3), lid = 0.34, lidTilt = 20, skin = rock },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Brow",
			v3(0.95, 0.34, 0.4),
			Kit.on(cone, 20 * side, 73.5, 0.04) * CFrame.Angles(0, 0, math.rad(-24 * side)),
			rockDark,
			Enum.Material.Slate,
			"Body"
		)
	end
	k:mouth(
		Kit.on(cone, 0, 61, -0.02),
		{ width = 1.05, height = 0.46, skin = rock, style = "Teeth", radius = 2.0 },
		"Body"
	)
	k:badge(Kit.on(cone, 26, 50, 0.02), "#666", 0.7, "Body")

	-- Rock fists: one clutching a losing hand of cards, one shaking in fury
	Parts.bareArm(k, "ArmR", v3(1.75, 2.1, -0.2), v3(2.65, 2.55, -0.75), 0.58, rock, 0.8)
	for i = -1, 1 do
		local card = k:part(
			"Card",
			v3(0.62, 0.88, 0.03),
			CFrame.new(2.7, 3.1, -1.0) * CFrame.Angles(0, 0, math.rad(-i * 18)) * CFrame.new(0, 0.25, -i * 0.02),
			C.White,
			nil,
			"ArmR"
		)
		label(
			card,
			if i == 0 then "2" else if i < 0 then "3" else "7",
			if i == 0 then rgb(220, 40, 50) else rgb(30, 30, 40)
		)
	end
	Parts.bareArm(k, "ArmL", v3(-1.75, 2.1, -0.2), v3(-2.6, 3.4, -0.5), 0.58, rock, 0.82)
	Parts.cuff(k, v3(-2.42, 3.13, -0.44), 0.58, "ArmL")

	k:ballAndChain(v3(-1.3, 0.5, -2.1), v3(-2.3, 0.45, -2.9), 0.5)
	return body
end

return Mythic
