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

---------------------------------------------------------------------------
-- Tralalero Tralala: the three-legged shark in sneakers
---------------------------------------------------------------------------

local SHARK = rgb(66, 140, 222)
local SHARK_DARK = rgb(44, 104, 186)
local BELLY = rgb(240, 244, 250)
local LEG = rgb(236, 190, 150)
local SNEAKER = rgb(34, 100, 228)

export type SharkStyle = {
	skin: Color3?,
	dark: Color3?,
	sneaker: Color3?,
}

-- One shark on three legs, built in the frame `at` (facing its -Z) at size `s`. Returns the widest
-- body part.
local function shark(k: Kit, at: CFrame, s: number, style: SharkStyle?): BasePart
	local look: SharkStyle = style or {}
	local skin = look.skin or SHARK
	local dark = look.dark or SHARK_DARK
	local function p(x: number, y: number, z: number): Vector3
		return (at * CFrame.new(x * s, y * s, z * s)).Position
	end
	local function dir(x: number, y: number, z: number): Vector3
		return at:VectorToWorldSpace(v3(x, y, z))
	end

	-- Head: a real ellipsoid, nose tipped up a little, so the face features sit exactly on it
	local tilt = at.Rotation * CFrame.Angles(math.rad(6), 0, 0)
	local head: Kit.Shell = { center = p(0, 3.1, -2.02), radii = v3(1.1, 1.02, 1.38) * s, rotation = tilt }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center) * tilt, skin, nil, "Body")
	k:ellipsoid(
		"Chin",
		v3(1.08, 0.78, 1.3) * 2 * s,
		CFrame.new(head.center) * tilt * CFrame.new(0, -0.3 * s, -0.02 * s),
		BELLY,
		nil,
		"Body"
	)

	-- Body: one long torso ellipsoid (smooth, no seams) and a tapering tail, countershaded with a
	-- white belly that shows below the midline
	local torsoAt = CFrame.new(p(0, 3.04, -0.95)) * at.Rotation
	local torso = k:ellipsoid("Skin", v3(1.15, 1.08, 2.15) * 2 * s, torsoAt, skin, nil, "Body")
	-- Blends the head into the torso so there is no neck crease
	k:ellipsoid("Skin", v3(1.12, 1.05, 1.1) * 2 * s, CFrame.new(p(0, 3.07, -1.75)) * at.Rotation, skin, nil, "Body")
	k:ellipsoid("Belly", v3(1.17, 0.82, 2.13) * 2 * s, torsoAt * CFrame.new(0, -0.32 * s, 0), BELLY, nil, "Body")
	local tail = {
		{ z = -0.3, y = 3.04, w = 0.98, h = 0.93 },
		{ z = 0.6, y = 3.08, w = 0.8, h = 0.77 },
		{ z = 1.4, y = 3.16, w = 0.57, h = 0.55 },
		{ z = 2.2, y = 3.27, w = 0.35, h = 0.36 },
		{ z = 3.0, y = 3.36, w = 0.19, h = 0.21 },
	}
	local top: { Kit.Section } = {}
	local under: { Kit.Section } = {}
	for _, point in tail do
		table.insert(top, { at = p(0, point.y, point.z), w = point.w * s, h = point.h * s })
		table.insert(
			under,
			{ at = p(0, point.y - point.h * 0.3, point.z), w = (point.w + 0.02) * s, h = point.h * 0.76 * s }
		)
	end
	k:loft("Skin", top, skin, nil, "Body", { density = 1, overlap = 9 })
	k:loft("Belly", under, BELLY, nil, "Body", { density = 1, overlap = 9 })

	-- Gill slits
	local flank: Kit.Shell = { center = p(0, 3.02, -1.25), radii = v3(1.12, 1.06, 1.3) * s, rotation = at.Rotation }
	for _, side in { -1, 1 } do
		for i = 0, 1 do
			Parts.patch(k, "Gill", flank, side * (100 + i * 11), 4, 0.08 * s, 0.62 * s, dark, nil, "Body", side * 8)
		end
	end

	-- Fins: thin lofts, their chords running front to back
	local fore = dir(0, 0, -1)
	local function fin(name: string, points: { { number } }, color: Color3, up: Vector3?, density: number?)
		local sections: { Kit.Section } = {}
		for _, q in points do
			table.insert(sections, { at = p(q[1], q[2], q[3]), w = q[4] * s, h = q[5] * s })
		end
		k:loft(
			name,
			sections,
			color,
			nil,
			"Body",
			{ up = up or fore, density = density or 0.38, overlap = 4.5, minSpacing = 0.16 * s }
		)
	end
	fin("DorsalFin", {
		{ 0, 3.7, -0.65, 0.17, 0.8 },
		{ 0, 4.45, -0.28, 0.13, 0.52 },
		{ 0, 5.02, 0.22, 0.08, 0.25 },
		{ 0, 5.32, 0.6, 0.035, 0.05 },
	}, skin)
	for _, side in { -1, 1 } do
		fin("PectoralFin", {
			{ side * 0.8, 2.55, -1.4, 0.13, 0.52 },
			{ side * 1.5, 2.2, -1.02, 0.09, 0.34 },
			{ side * 2.05, 1.98, -0.55, 0.035, 0.06 },
		}, skin, nil, 0.55)
	end
	local aft = dir(0, 0, 1)
	fin("TailFin", {
		{ 0, 3.36, 2.8, 0.11, 0.36 },
		{ 0, 3.95, 3.28, 0.08, 0.3 },
		{ 0, 4.62, 3.78, 0.03, 0.05 },
	}, skin, aft, 0.45)
	fin("TailFin", {
		{ 0, 3.3, 2.9, 0.1, 0.28 },
		{ 0, 2.86, 3.26, 0.07, 0.19 },
		{ 0, 2.52, 3.52, 0.03, 0.05 },
	}, dark, aft, 0.5)
	fin("SmallFin", { { 0, 3.55, 1.85, 0.07, 0.22 }, { 0, 3.9, 2.15, 0.03, 0.04 } }, skin, nil, 0.8)
	fin("SmallFin", { { 0, 2.8, 2.05, 0.06, 0.18 }, { 0, 2.55, 2.32, 0.03, 0.04 } }, BELLY, nil, 0.8)

	-- Face: smug half-lidded eyes, nostrils and a big toothy grin
	k:eyes(head, 33, 20, {
		width = 0.52 * s,
		height = 0.58 * s,
		iris = rgb(30, 36, 52),
		skin = skin,
	}, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"BrowRidge",
			v3(0.78, 0.2, 0.4) * s,
			Kit.on(head, side * 31, 37, 0) * CFrame.Angles(0, 0, math.rad(side * -18)),
			dark,
			nil,
			"Body"
		)
	end
	for _, side in { -1, 1 } do
		k:ellipsoid("Nostril", v3(0.12, 0.06, 0.08) * s, Kit.on(head, side * 13, 8, -0.02 * s), dark, nil, "Body")
	end
	local function smile(yaw: number): number
		return -19 + 14 * (yaw / 60) ^ 2
	end
	local function gap(yaw: number): number
		return 13 - 9.5 * (math.abs(yaw) / 64) ^ 1.6
	end
	local mouth: { Kit.Section } = {}
	for yaw = -64, 64, 12.8 do
		local point, normal = Kit.surface(head, yaw, smile(yaw))
		table.insert(mouth, { at = point - normal * 0.02 * s, w = 0.07 * s, h = gap(yaw) / 57.3 * 0.94 * s })
	end
	k:loft("Mouth", mouth, rgb(72, 20, 34), nil, "Body", { density = 3, overlap = 2.6, minSpacing = 0.3 * s })
	k:ellipsoid(
		"Tongue",
		v3(0.5, 0.14, 0.14) * s,
		Kit.on(head, 0, smile(0) - gap(0) * 0.45, 0.01 * s),
		Kit.Colors.Tongue,
		nil,
		"Body"
	)
	for yaw = -44, 44, 11 do
		local edge = smile(yaw) + gap(yaw) * 0.95
		local tooth = gap(yaw) / 57.3 * 0.94 * s * 1.3
		k:tooth(Kit.on(head, yaw, edge, 0.035 * s), 0.17 * s, tooth, nil, "Body")
	end
	for yaw = -38.5, 38.5, 11 do
		if math.abs(yaw) > 10 then
			local edge = smile(yaw) - gap(yaw) * 0.95
			local tooth = gap(yaw) / 57.3 * 0.94 * s * 1.15
			k:tooth(Kit.on(head, yaw, edge, 0.035 * s), 0.16 * s, -tooth, nil, "Body")
		end
	end

	-- Three legs in white socks and blue sneakers: two up front, one behind
	for _, leg in { { -0.56, -1.3 }, { 0.56, -1.3 }, { 0, 0.85 } } do
		local x, z = leg[1], leg[2]
		local hip, knee, ankle = p(x, 2.45, z), p(x * 1.08, 1.25, z - 0.1), p(x * 1.08, 0.5, z)
		k:loft("Leg", {
			{ at = hip, w = 0.3 * s, h = 0.3 * s },
			{ at = knee, w = 0.25 * s, h = 0.25 * s },
			{ at = ankle, w = 0.22 * s, h = 0.22 * s },
		}, LEG, nil, "Legs", { density = 3.2, overlap = 7 })
		k:oval(
			"Sock",
			CFrame.new(p(x * 1.08, 0.66, z)) * at.Rotation,
			0.56 * s,
			0.56 * s,
			0.36 * s,
			C.White,
			Enum.Material.Fabric,
			"Legs"
		)
		k:oval(
			"SockStripe",
			CFrame.new(p(x * 1.08, 0.74, z)) * at.Rotation,
			0.58 * s,
			0.58 * s,
			0.07 * s,
			SNEAKER,
			Enum.Material.Fabric,
			"Legs"
		)
		Parts.sneaker(k, p(x * 1.08, 0, z), 0.95 * s, { upper = look.sneaker or SNEAKER }, "Legs", 0)
	end
	k.model:SetAttribute("HeadTop", p(0, 4.05, -2.2))
	k.model:SetAttribute("HeadWidth", 1.3 * s)
	return torso
end

Divine.TralaleroTralala = function(k: Kit): BasePart
	local body = shark(k, CFrame.identity, 1)
	k:turn(-38)
	return body
end

return Divine
