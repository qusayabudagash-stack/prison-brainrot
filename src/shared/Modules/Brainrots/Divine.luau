-- DIVINE Brainrots: heavenly, luminous and a little smug. Light rays and auras come from Effects.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Divine: { [string]: (Kit) -> BasePart } = {}

local RAINBOW = {
	rgb(255, 70, 80),
	rgb(255, 150, 40),
	rgb(255, 225, 50),
	rgb(70, 215, 100),
	rgb(60, 150, 255),
	rgb(165, 90, 255),
}

-- A five-pointed star facing along the CFrame's LookVector.
local function star(
	k: Kit,
	name: string,
	cframe: CFrame,
	size: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
)
	for i = 0, 4 do
		k:wedge(
			name,
			v3(size * 0.2, size * 0.5, size * 0.34),
			cframe * CFrame.Angles(0, 0, i * math.pi * 2 / 5) * CFrame.new(0, size * 0.38, 0),
			color,
			material,
			rig
		)
	end
	k:disc(name, size * 0.52, size * 0.2, cframe, color, material, rig)
end

Divine.GalaxyWarden = function(k)
	local cosmos = rgb(36, 30, 100)
	local navy = rgb(28, 30, 70)
	local starGold = rgb(255, 220, 110)
	local shell: Kit.Shell = { center = v3(0, 3.25, 0), radii = v3(1.55, 2.05, 1.45) }

	-- Tall egg made of night sky, in a warden's uniform
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), cosmos, nil, "Body")
	for i, spec in
		{
			{ yaw = -58, pitch = 20, size = 1.3, color = rgb(120, 70, 220) },
			{ yaw = 120, pitch = 35, size = 1.6, color = rgb(60, 110, 240) },
			{ yaw = -150, pitch = 10, size = 1.5, color = rgb(170, 70, 200) },
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
			i * 40
		)
		cloud.Transparency = 0.25
	end
	Parts.starSpecks(k, shell, 30, { C.White, starGold, rgb(160, 220, 255) }, -35, 80, "Body")
	k:band("Belt", shell, 2.15, 0.34, rgb(25, 22, 35), Enum.Material.Leather, "Body")
	k:part("BeltBuckle", v3(0.6, 0.44, 0.12), Kit.on(shell, 0, -34, 0.08), C.Gold, Enum.Material.Foil, "Body")
	star(k, "Badge", Kit.on(shell, -30, 2, 0.1), 0.72, starGold, Enum.Material.Neon, "Body")
	for i = 0, 2 do
		k:ball("UniformButton", 0.16, Kit.surface(shell, 0, -8 - i * 12), C.Gold, Enum.Material.Foil, "Body")
	end
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Epaulette",
			v3(0.95, 0.3, 0.85),
			CFrame.new(side * 1.12, 4.55, 0),
			C.Gold,
			Enum.Material.Foil,
			"Body"
		)
		for i = 0, 3 do
			k:ball("Fringe", 0.15, v3(side * 1.5, 4.36, -0.3 + i * 0.2), C.GoldDark, Enum.Material.Foil, "Body")
		end
	end

	-- Calm glowing eyes and a knowing smile
	k:eyes(shell, 22, 26, { width = 0.52, height = 0.68, style = "Glow", glow = rgb(170, 240, 255) }, "Body")
	k:mouth(
		Kit.on(shell, 0, 10, -0.02),
		{ width = 0.72, height = 0.3, skin = cosmos, style = "Smile", radius = 1.5 },
		"Body"
	)
	local smile = k.model:FindFirstChild("Mouth") :: BasePart
	smile.Color = rgb(170, 240, 255)
	smile.Material = Enum.Material.Neon

	-- Peaked warden cap with a star badge
	local cap = CFrame.new(0, 5.02, -0.02)
	k:cylinder("CapBand", 0.45, 1.95, cap, navy, Enum.Material.Fabric, "Body")
	k:ellipsoid("CapTop", v3(2.35, 0.6, 2.35), cap * CFrame.new(0, 0.36, 0), navy, Enum.Material.Fabric, "Body")
	k:cylinder("CapGold", 0.14, 1.98, cap * CFrame.new(0, -0.12, 0), C.Gold, Enum.Material.Foil, "Body")
	k:ellipsoid("Visor", v3(1.7, 0.16, 0.95), cap * CFrame.new(0, -0.22, -0.95), rgb(15, 15, 25), nil, "Body")
	star(k, "CapBadge", cap * CFrame.new(0, 0.14, -1.0), 0.5, starGold, Enum.Material.Neon, "Body")

	-- Star-studded cape
	Parts.cape(k, v3(0, 4.55, 0.7), 3.3, 3.9, rgb(70, 40, 150), nil, "Body")
	k:band(
		"CapeClasp",
		{ center = v3(0, 4.55, 0), radii = v3(1.2, 0.2, 1.1) },
		4.55,
		0.18,
		C.Gold,
		Enum.Material.Foil,
		"Body"
	)

	-- A staff topped with a burning star, and planets on patrol
	Parts.arm(k, "ArmR", v3(1.35, 3.95, 0), v3(2.1, 3.3, -0.5), 0.52, navy, C.White, 0.6)
	k:limb("Staff", v3(2.15, 0.2, -0.55), v3(2.1, 5.2, -0.55), 0.18, C.Gold, Enum.Material.Foil, "ArmR")
	star(k, "StaffStar", CFrame.new(2.1, 5.65, -0.55), 1.05, starGold, Enum.Material.Neon, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.35, 3.95, 0), v3(-1.85, 2.8, -0.55), 0.52, navy, C.White, 0.6)
	for i, spec in
		{
			{ at = v3(2.8, 2.2, 0), color = rgb(255, 150, 90), size = 0.5 },
			{ at = v3(-2.9, 4.4, 0), color = rgb(110, 200, 255), size = 0.42 },
			{ at = v3(-2.3, 1.2, 0), color = rgb(210, 120, 255), size = 0.35 },
		}
	do
		local angle = i * 2.2
		k:ball("Planet", spec.size, spec.at + v3(0, 0, math.sin(angle) * 0.8), spec.color, nil, "Orbit")
	end

	Parts.legs(k, 1.25, 0.6, 0.6, navy, rgb(20, 20, 28), C.Gold, 1.05, C.Gold)
	return body
end

Divine.RainbowCriminal = function(k)
	local pale = rgb(242, 238, 250)
	local black = rgb(28, 26, 34)
	-- A capsule: straight middle (so the stolen rainbow wraps it in clean stripes), round dome head
	local waist: Kit.Shell = { center = v3(0, 2.6, 0), radii = v3(1.7, 99, 1.55) }
	local head: Kit.Shell = { center = v3(0, 3.3, 0), radii = v3(1.75, 1.55, 1.6) }

	local body = k:band("Body", waist, 2.6, 1.4, pale, nil, "Body")
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), pale, nil, "Body")
	k:ellipsoid("Seat", v3(3.5, 1.5, 3.2), CFrame.new(0, 1.9, 0), black, Enum.Material.Fabric, "Body")
	local striped: Kit.Shell = { center = waist.center, radii = waist.radii + v3(0.03, 0, 0.03) }
	for i, color in RAINBOW do
		k:band("Stripe", striped, 3.19 - (i - 1) * 0.22, 0.22, color, Enum.Material.Fabric, "Body")
	end
	k:badge(CFrame.new(0.75, 2.75, -1.62), "#RGB", 0.62, "Body")

	-- Burglar mask, beanie, sneaky grin
	Parts.patch(k, "Mask", head, 0, 28, 2.3, 0.72, black, Enum.Material.Fabric, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"MaskTie",
			v3(0.14, 0.34, 0.5),
			CFrame.new(side * 1.5, 4.1, 0.65) * CFrame.Angles(math.rad(30), 0, math.rad(-20 * side)),
			black,
			Enum.Material.Fabric,
			"Body"
		)
	end
	k:eyes(head, 20, 28, {
		width = 0.62,
		height = 0.68,
		iris = rgb(60, 60, 80),
		look = Vector2.new(0.55, 0),
		lid = 0.22,
		lidTilt = 10,
		skin = black,
	}, "Body")
	k:mouth(Kit.on(head, 0, 9, -0.02), { width = 0.9, height = 0.4, skin = pale, style = "Grin", radius = 1.7 }, "Body")
	Parts.beanie(k, CFrame.new(0, 4.62, 0.08), 2.15, black, nil, "Body")

	-- A loot sack over the shoulder, bursting with colors
	local sack = v3(2.1, 4.0, 0.75)
	k:ellipsoid(
		"LootSack",
		v3(1.8, 2.0, 1.6),
		CFrame.new(sack) * CFrame.Angles(0, 0, math.rad(-20)),
		rgb(205, 175, 125),
		Enum.Material.Fabric,
		"ArmR"
	)
	for i, color in RAINBOW do
		local angle = (i - 1) * math.pi * 2 / #RAINBOW
		local at = sack
			+ v3(0.35 + math.cos(angle) * 0.45, 1.0 + math.abs(math.sin(angle)) * 0.25, math.sin(angle) * 0.4)
		k:ball("Loot", 0.5, at, color, Enum.Material.Neon, "ArmR")
	end
	Parts.arm(k, "ArmR", v3(1.4, 3.2, -0.1), v3(1.75, 4.45, -0.25), 0.46, pale, pale, 0.56)
	Parts.arm(k, "ArmL", v3(-1.4, 3.0, 0), v3(-2.05, 2.25, -0.5), 0.46, pale, pale, 0.56)

	-- Black pants, sneakers with rainbow-bright soles (tiptoeing)
	Parts.legs(k, 1.35, 0.6, 0.56, black, C.White, rgb(255, 90, 170), 1, black)
	return body
end

Divine.HaloHooligan = function(k)
	local cream = rgb(255, 246, 228)
	local gold = rgb(255, 220, 100)
	local shell: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(1.65, 1.75, 1.55) }
	local suit: Kit.Shell = { center = v3(0, 2.0, 0), radii = v3(1.72, 1.1, 1.62) }

	-- Angelic body, orange jumpsuit
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), cream, nil, "Body")
	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 2.5, 0.24, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, 8, 0.02), "#777", 0.8, "Body")

	-- Innocent? The face says otherwise
	k:eyes(shell, 22, 22, {
		width = 0.66,
		height = 0.76,
		iris = rgb(80, 170, 255),
		look = Vector2.new(0.5, 0.1),
		lid = 0.36,
		lidTilt = 14,
		skin = cream,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(
			Kit.on(shell, 23 * side, 38 + (if side > 0 then 4 else 0), 0.04),
			0.55,
			if side > 0 then -12 else 20,
			rgb(200, 150, 70),
			"Body"
		)
		k:blush(Kit.on(shell, 40 * side, 6, -0.02), 0.5, "Body")
	end
	k:mouth(
		Kit.on(shell, 0, 2, -0.02),
		{ width = 0.85, height = 0.38, skin = cream, style = "Smirk", radius = 1.6 },
		"Body"
	)
	k:part("SmirkTooth", v3(0.14, 0.14, 0.05), Kit.on(shell, 8, 5, 0.06), C.White, nil, "Body")

	-- A slightly crooked halo
	Parts.halo(k, v3(0.15, 5.3, 0.05), 0.92, gold, -12, "Body")

	-- Feathered wings... and a tiny devil tail peeking out
	for _, side in { -1, 1 } do
		Parts.wing(k, v3(side * 0.8, 3.4, 1.15), side, 2.15, C.White, rgb(255, 230, 160))
	end
	local t1, t2, t3 = v3(0.3, 1.4, 1.45), v3(0.9, 1.1, 2.0), v3(1.3, 1.5, 2.25)
	k:limb("DevilTail", t1, t2, 0.18, rgb(210, 35, 45), nil, "Body")
	k:limb("DevilTail", t2, t3, 0.16, rgb(210, 35, 45), nil, "Body")
	k:wedge(
		"DevilTailTip",
		v3(0.1, 0.4, 0.4),
		CFrame.new(t3 + v3(0.1, 0.18, 0)) * CFrame.Angles(0, math.rad(90), math.rad(-30)),
		rgb(210, 35, 45),
		nil,
		"Body"
	)

	-- Slingshot at the ready
	Parts.arm(k, "ArmR", v3(1.45, 3.0, 0), v3(2.05, 3.8, -0.55), 0.46, C.Jumpsuit, cream, 0.56)
	local grip = v3(2.1, 3.8, -0.6)
	local fork = grip + v3(0, 0.55, 0)
	k:limb("Slingshot", grip - v3(0, 0.3, 0), fork, 0.14, rgb(130, 85, 45), nil, "ArmR")
	k:limb("Slingshot", fork, fork + v3(-0.28, 0.45, 0), 0.12, rgb(130, 85, 45), nil, "ArmR")
	k:limb("Slingshot", fork, fork + v3(0.28, 0.45, 0), 0.12, rgb(130, 85, 45), nil, "ArmR")
	k:limb("SlingBand", fork + v3(-0.28, 0.45, 0), fork + v3(0, 0.3, 0.35), 0.06, rgb(255, 110, 150), nil, "ArmR")
	k:limb("SlingBand", fork + v3(0.28, 0.45, 0), fork + v3(0, 0.3, 0.35), 0.06, rgb(255, 110, 150), nil, "ArmR")
	Parts.arm(k, "ArmL", v3(-1.45, 3.0, 0), v3(-1.95, 2.3, -0.4), 0.46, C.Jumpsuit, cream, 0.56)

	Parts.legs(k, 1.2, 0.62, 0.6, C.Jumpsuit, C.White, gold, 1, C.JumpsuitDark)
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"ShoeWing",
			v3(0.1, 0.35, 0.55),
			CFrame.new(side * 1.12, 0.45, 0.05) * CFrame.Angles(math.rad(-30), 0, math.rad(20 * side)),
			C.White,
			nil,
			"Legs"
		)
	end
	return body
end

return Divine
