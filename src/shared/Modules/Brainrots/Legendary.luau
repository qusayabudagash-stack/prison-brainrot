-- LEGENDARY Brainrots: the famous ones. Tall, full-body poses, premium materials and props.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Legendary: { [string]: (Kit) -> BasePart } = {}

local SKIN = rgb(240, 198, 162)

---------------------------------------------------------------------------
-- Ballerina Cappuccina: a ballerina with a cappuccino cup for a head
---------------------------------------------------------------------------

Legendary.BallerinaCappuccina = function(k: Kit): BasePart
	local CUP = rgb(250, 246, 240)
	local TUTU = rgb(255, 170, 200)
	local TUTU_LIGHT = rgb(255, 214, 230)
	local LEOTARD = rgb(246, 120, 168)
	local SHOE = rgb(255, 190, 200)

	-- Standing leg en pointe, the other lifted in a passé with its toe at the knee
	k:loft("Leg", {
		{ at = v3(-0.22, 2.2, 0), w = 0.22, h = 0.22 },
		{ at = v3(-0.26, 1.2, -0.02), w = 0.17, h = 0.17 },
		{ at = v3(-0.28, 0.36, 0), w = 0.12, h = 0.12 },
	}, SKIN, nil, "Legs", { density = 3, overlap = 7 })
	k:ellipsoid("PointeShoe", v3(0.26, 0.5, 0.3), CFrame.new(-0.28, 0.22, -0.02), SHOE, Enum.Material.Fabric, "Legs")
	k:ellipsoid("Ribbon", v3(0.28, 0.08, 0.28), CFrame.new(-0.28, 0.46, 0), SHOE, Enum.Material.Fabric, "Legs")
	local knee = v3(0.72, 1.55, -0.18)
	k:loft("Leg", {
		{ at = v3(0.22, 2.2, 0), w = 0.22, h = 0.22 },
		{ at = knee, w = 0.17, h = 0.17 },
		{ at = v3(-0.12, 1.25, -0.08), w = 0.12, h = 0.12 },
	}, SKIN, nil, "Legs", { density = 1.2, overlap = 4 })
	k:ellipsoid(
		"PointeShoe",
		v3(0.22, 0.28, 0.46),
		CFrame.new(-0.2, 1.22, -0.1) * CFrame.Angles(0, math.rad(70), math.rad(-20)),
		SHOE,
		Enum.Material.Fabric,
		"Legs"
	)

	-- A three-layer tutu with a ruffled edge, and a leotard
	for i, layer in
		{
			{ y = 2.35, size = 2.9, color = TUTU },
			{ y = 2.44, size = 2.5, color = TUTU_LIGHT },
			{ y = 2.53, size = 2.1, color = TUTU },
		}
	do
		k:oval(
			"Tutu",
			CFrame.new(0, layer.y, 0) * CFrame.Angles(math.rad(i * 2 - 4), 0, 0),
			layer.size,
			layer.size,
			0.12,
			layer.color,
			Enum.Material.Fabric,
			"Body"
		)
	end
	for i = 0, 15 do
		local angle = i * math.pi * 2 / 16
		k:ball(
			"Ruffle",
			0.34,
			v3(math.cos(angle) * 1.4, 2.33, math.sin(angle) * 1.4),
			if i % 2 == 0 then TUTU else TUTU_LIGHT,
			Enum.Material.Fabric,
			"Body"
		)
	end
	local torso: Kit.Shell = { center = v3(0, 3.0, 0), radii = v3(0.56, 0.72, 0.44) }
	local body =
		k:ellipsoid("Leotard", torso.radii * 2, CFrame.new(torso.center), LEOTARD, Enum.Material.Fabric, "Body")
	k:limb("Neck", v3(0, 3.4, 0), v3(0, 3.8, 0), 0.26, SKIN, nil, "Body")
	for i = 0, 6 do
		local angle = math.rad(-60 + i * 20)
		k:ball(
			"Pearl",
			0.1,
			v3(math.sin(angle) * 0.2, 3.52 - math.cos(angle) * 0.05, -math.cos(angle) * 0.14),
			rgb(255, 250, 240),
			nil,
			"Body"
		)
	end

	-- The cappuccino cup head, with lashes, rosy cheeks and a pink bow
	local cup = Parts.cup(k, v3(0, 4.2, 0), 1.15, 0.92, { color = CUP, heart = true })
	for _, side in { -1, 1 } do
		local eye = Parts.onCup(cup, side * 24, 4.72, -0.04)
		k:eye(eye, { width = 0.32, height = 0.38, iris = rgb(90, 60, 40), side = side }, "Body")
		for lash = -1, 1 do
			k:limb(
				"Lash",
				(eye * CFrame.new(side * (0.1 + lash * 0.05), 0.16, -0.08)).Position,
				(eye * CFrame.new(side * (0.18 + lash * 0.09), 0.3, -0.12)).Position,
				0.04,
				C.Ink,
				nil,
				"Body"
			)
		end
		k:blush(Parts.onCup(cup, side * 42, 4.42, 0.0), 0.3, "Body")
	end
	k:mouth(
		Parts.onCup(cup, 0, 4.38, 0),
		{ width = 0.34, height = 0.13, skin = CUP, style = "Smile", radius = 0.9 },
		"Body"
	)
	local bow = Parts.onCup(cup, -70, 5.05, 0.05)
	for _, side in { -1, 1 } do
		k:ellipsoid(
			"Bow",
			v3(0.34, 0.26, 0.14),
			bow * CFrame.new(side * 0.18, 0, 0) * CFrame.Angles(0, 0, math.rad(side * 20)),
			LEOTARD,
			Enum.Material.Fabric,
			"Body"
		)
	end
	k:ball("BowKnot", 0.14, (bow * CFrame.new(0, 0, -0.04)).Position, LEOTARD, Enum.Material.Fabric, "Body")

	-- Arms raised in an arc above the head (en couronne)
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder = v3(side * 0.42, 3.3, 0)
		local elbow = v3(side * 1.25, 4.4, -0.05)
		local hand = v3(side * 0.3, 5.75, -0.05)
		k:loft("Arm", {
			{ at = shoulder, w = 0.13, h = 0.13 },
			{ at = elbow, w = 0.12, h = 0.12 },
			{ at = hand, w = 0.1, h = 0.1 },
		}, SKIN, nil, rig, { density = 1.2, overlap = 4 })
		k:ball("Hand", 0.2, hand, SKIN, nil, rig)
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	return body
end

---------------------------------------------------------------------------
-- Tung Tung Tung Sahur: a wooden log with a baseball bat
---------------------------------------------------------------------------

Legendary.TungTungTungSahur = function(k: Kit): BasePart
	local WOOD = rgb(214, 160, 104)
	local GRAIN = rgb(176, 122, 74)
	local CUT = rgb(240, 206, 150)
	local BAT = rgb(190, 130, 70)

	for _, side in { -1, 1 } do
		k:limb("Leg", v3(side * 0.4, 1.55, 0), v3(side * 0.48, 0.3, -0.05), 0.24, WOOD, Enum.Material.Wood, "Legs")
		k:ellipsoid("Foot", v3(0.4, 0.24, 0.66), CFrame.new(side * 0.5, 0.12, -0.2), WOOD, Enum.Material.Wood, "Legs")
	end
	-- The log: a tall wooden cylinder with a rounded top, grain lines and a knot
	local radius, bottom, top = 0.85, 1.4, 4.7
	local body = k:cylinder(
		"Log",
		top - bottom,
		radius * 2,
		CFrame.new(0, (bottom + top) / 2, 0),
		WOOD,
		Enum.Material.Wood,
		"Body"
	)
	k:ellipsoid(
		"LogBottom",
		v3(radius * 2, 0.7, radius * 2),
		CFrame.new(0, bottom, 0),
		WOOD,
		Enum.Material.Wood,
		"Body"
	)
	k:oval(
		"LogTop",
		CFrame.new(0, top + 0.02, 0),
		radius * 2 - 0.02,
		radius * 2 - 0.02,
		0.06,
		CUT,
		Enum.Material.Wood,
		"Body"
	)
	for i, ring in { 1.3, 0.85, 0.4 } do
		k:oval(
			"TreeRing",
			CFrame.new(0, top + 0.05 + i * 0.002, 0),
			ring,
			ring,
			0.02,
			GRAIN,
			Enum.Material.Wood,
			"Body"
		)
		k:oval(
			"TreeRing",
			CFrame.new(0, top + 0.055 + i * 0.002, 0),
			ring - 0.1,
			ring - 0.1,
			0.02,
			CUT,
			Enum.Material.Wood,
			"Body"
		)
	end
	local log: Parts.Cup = { center = v3(0, (bottom + top) / 2, 0), bottom = bottom, top = top, radius = radius }
	for _, spec in
		{
			{ 70, 2.4, 1.6 },
			{ 110, 3.2, 1.2 },
			{ 150, 2.6, 1.8 },
			{ -80, 2.2, 1.4 },
			{ -125, 3.3, 1.6 },
			{ 180, 3.0, 2.0 },
		}
	do
		k:part(
			"Grain",
			v3(0.06, spec[3], 0.06),
			Parts.onCup(log, spec[1], spec[2], -0.01),
			GRAIN,
			Enum.Material.Wood,
			"Body"
		)
	end
	k:ellipsoid("Knot", v3(0.34, 0.24, 0.12), Parts.onCup(log, -55, 2.05, -0.02), GRAIN, Enum.Material.Wood, "Body")

	-- The famous stare and wide open mouth
	for _, side in { -1, 1 } do
		local eye = Parts.onCup(log, side * 24, 3.75, -0.05)
		k:eye(eye, { width = 0.5, height = 0.58, iris = rgb(30, 24, 20), side = side }, "Body")
		k:ellipsoid(
			"Brow",
			v3(0.56, 0.14, 0.14),
			eye * CFrame.new(0, 0.42, -0.02) * CFrame.Angles(0, 0, math.rad(side * -8)),
			rgb(90, 60, 36),
			nil,
			"Body"
		)
	end
	k:mouth(
		Parts.onCup(log, 0, 2.95, 0),
		{ width = 0.9, height = 0.5, skin = WOOD, style = "Grin", radius = 0.85 },
		"Body"
	)

	-- Thin arms; the right hand grips a baseball bat resting on the shoulder
	Parts.bareArm(k, "ArmL", v3(-0.8, 3.1, 0), v3(-1.3, 2.25, -0.2), 0.22, WOOD, 0.3)
	Parts.bareArm(k, "ArmR", v3(0.8, 3.1, 0), v3(1.25, 2.7, -0.45), 0.22, WOOD, 0.3)
	local grip = v3(1.25, 2.7, -0.45)
	local batTip = v3(1.0, 5.35, 0.55)
	Parts.tube(
		k,
		"Bat",
		{ grip - (batTip - grip).Unit * 0.35, grip:Lerp(batTip, 0.35), grip:Lerp(batTip, 0.75), batTip },
		{ 0.09, 0.1, 0.19, 0.22 },
		BAT,
		Enum.Material.Wood,
		"ArmR",
		{ density = 1.5, overlap = 5 }
	)
	k:ball("BatKnob", 0.22, grip - (batTip - grip).Unit * 0.38, rgb(120, 80, 45), Enum.Material.Wood, "ArmR")
	k.model:SetAttribute("HeadTop", v3(0, top + 0.05, 0))
	k.model:SetAttribute("HeadWidth", radius * 1.9)
	return body
end

---------------------------------------------------------------------------
-- Bombombini Gusini: a goose fighter jet
---------------------------------------------------------------------------

Legendary.BombombiniGusini = function(k: Kit): BasePart
	local JET = rgb(172, 182, 198)
	local JET_DARK = rgb(112, 122, 140)
	local GOOSE = rgb(250, 250, 248)
	local BEAK = rgb(255, 150, 40)
	local FEET = rgb(255, 140, 50)

	-- Webbed goose feet for landing gear
	for _, spec in { { -0.6, -0.9 }, { 0.6, -0.9 }, { 0, 1.5 } } do
		local x, z = spec[1], spec[2]
		k:limb("Leg", v3(x, 1.7, z), v3(x, 0.3, z), 0.16, FEET, nil, "Legs")
		for _, angle in { -32, 0, 32 } do
			local dir = v3(math.sin(math.rad(angle)), 0, -math.cos(math.rad(angle)))
			k:limb("Toe", v3(x, 0.2, z), v3(x, 0.14, z) + dir * 0.55, 0.14, FEET, nil, "Legs")
		end
		k:ellipsoid("Web", v3(0.7, 0.06, 0.5), CFrame.new(x, 0.1, z - 0.28), FEET, nil, "Legs")
	end

	-- Fuselage, canopy, swept wings, twin tails and a glowing exhaust
	local body = k:loft("Fuselage", {
		{ at = v3(0, 2.35, -2.2), w = 0.5, h = 0.5 },
		{ at = v3(0, 2.4, -1.2), w = 0.82, h = 0.72 },
		{ at = v3(0, 2.45, 0.4), w = 0.8, h = 0.7 },
		{ at = v3(0, 2.5, 1.9), w = 0.55, h = 0.5 },
		{ at = v3(0, 2.55, 2.5), w = 0.46, h = 0.42 },
	}, JET, Enum.Material.Metal, "Body", { density = 1.2, overlap = 7 })
	k:ellipsoid("Belly", v3(1.5, 0.9, 3.6), CFrame.new(0, 2.15, 0), GOOSE, nil, "Body")
	local canopy = k:ellipsoid(
		"Canopy",
		v3(0.8, 0.62, 1.4),
		CFrame.new(0, 3.02, -0.2),
		rgb(120, 200, 250),
		Enum.Material.Glass,
		"Body"
	)
	canopy.Transparency = 0.2
	canopy:SetAttribute("KeepColor", true)
	for _, side in { -1, 1 } do
		k:loft("Wing", {
			{ at = v3(side * 0.6, 2.4, 0.2), w = 0.12, h = 0.95 },
			{ at = v3(side * 1.9, 2.3, 0.85), w = 0.08, h = 0.55 },
			{ at = v3(side * 2.8, 2.25, 1.25), w = 0.05, h = 0.26 },
		}, JET, Enum.Material.Metal, "Body", { up = v3(0, 0, -1), density = 0.6, overlap = 4 })
		k:ellipsoid("WingStripe", v3(0.5, 0.22, 0.5), CFrame.new(side * 2.2, 2.32, 1.02), rgb(230, 60, 60), nil, "Body")
		Parts.leaf(
			k,
			"TailFin",
			v3(side * 0.3, 2.8, 2.0),
			v3(side * 0.62, 3.75, 2.55),
			0.7,
			0.08,
			JET_DARK,
			v3(side, 0, 0),
			Enum.Material.Metal,
			"Body"
		)
		-- A cartoon bomb under each wing
		local bomb = v3(side * 1.55, 1.8, 0.7)
		k:loft("Bomb", {
			{ at = bomb + v3(0, 0, -0.5), w = 0.12, h = 0.12 },
			{ at = bomb, w = 0.26, h = 0.26 },
			{ at = bomb + v3(0, 0, 0.45), w = 0.14, h = 0.14 },
		}, rgb(70, 76, 90), Enum.Material.Metal, "Body", { density = 1, overlap = 4 })
		k:limb("Pylon", bomb + v3(0, 0.22, 0), bomb + v3(0, 0.5, 0), 0.08, JET_DARK, Enum.Material.Metal, "Body")
		k:oval(
			"BombBand",
			CFrame.lookAt(bomb, bomb + Vector3.zAxis) * CFrame.Angles(math.pi / 2, 0, 0),
			0.55,
			0.55,
			0.08,
			rgb(255, 214, 60),
			nil,
			"Body"
		)
	end
	k:cylinder(
		"Exhaust",
		0.2,
		0.72,
		CFrame.new(0, 2.55, 2.72) * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(50, 52, 60),
		Enum.Material.Metal,
		"Body"
	)
	k:disc("Afterburner", 0.5, 0.06, CFrame.new(0, 2.55, 2.84), rgb(255, 150, 60), Enum.Material.Neon, "Body")

	-- The goose: long neck curving up from the nose, head with an orange beak
	Parts.tube(
		k,
		"Neck",
		{ v3(0, 2.6, -1.9), v3(0, 3.3, -2.35), v3(0, 4.0, -2.2), v3(0, 4.45, -2.35) },
		{ 0.34, 0.26, 0.24, 0.26 },
		GOOSE,
		nil,
		"Body",
		{ density = 0.45, overlap = 6 }
	)
	local head: Kit.Shell = { center = v3(0, 4.6, -2.45), radii = v3(0.42, 0.4, 0.5) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), GOOSE, nil, "Body")
	k:loft("Beak", {
		{ at = v3(0, 4.52, -2.85), w = 0.2, h = 0.15 },
		{ at = v3(0, 4.46, -3.3), w = 0.13, h = 0.08 },
	}, BEAK, nil, "Body", { density = 1, overlap = 4 })
	k:ball("BeakKnob", 0.2, v3(0, 4.66, -2.86), rgb(40, 40, 46), nil, "Body")
	k:eyes(
		head,
		42,
		14,
		{ width = 0.22, height = 0.26, iris = rgb(40, 30, 30), lid = 0.3, lidTilt = 16, skin = GOOSE },
		"Body"
	)
	-- Pilot goggles
	k:band("GoggleStrap", head, 4.72, 0.1, rgb(90, 60, 40), Enum.Material.Leather, "Body")
	k:turn(-35)
	return body[3]
end

---------------------------------------------------------------------------
-- Girafa Celestre: a giraffe astronaut
---------------------------------------------------------------------------

Legendary.GirafaCelestre = function(k: Kit): BasePart
	local GIRAFFE = rgb(250, 204, 92)
	local SPOT = rgb(186, 110, 50)
	local SUIT = rgb(52, 76, 170)
	local SUIT_TRIM = rgb(236, 240, 250)
	local BOOT = rgb(200, 204, 214)

	for _, x in { -0.55, 0.55 } do
		for _, z in { -0.6, 0.7 } do
			k:limb("Leg", v3(x, 2.1, z), v3(x, 0.45, z), 0.3, GIRAFFE, nil, "Legs")
			k:oval("Boot", CFrame.new(x, 0.3, z), 0.48, 0.48, 0.6, BOOT, Enum.Material.Fabric, "Legs")
			k:oval(
				"BootSole",
				CFrame.new(x, 0.05, z - 0.04),
				0.5,
				0.56,
				0.1,
				rgb(70, 72, 84),
				Enum.Material.Rubber,
				"Legs"
			)
			k:oval("BootTrim", CFrame.new(x, 0.62, z), 0.5, 0.5, 0.08, SUIT_TRIM, nil, "Legs")
		end
	end
	-- Body in a spacesuit vest, with a jetpack
	local shell: Kit.Shell = { center = v3(0, 2.55, 0.05), radii = v3(0.85, 0.72, 1.2) }
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), GIRAFFE, nil, "Body")
	k:ellipsoid("SpaceSuit", v3(1.86, 1.5, 2.3), CFrame.new(0, 2.6, 0.0), SUIT, Enum.Material.Fabric, "Body")
	k:band("SuitTrim", { center = v3(0, 2.6, -0.1), radii = v3(0.9, 0.65, 0.95) }, 2.3, 0.1, SUIT_TRIM, nil, "Body")
	k:disc(
		"MissionPatch",
		0.5,
		0.06,
		CFrame.new(0.62, 2.78, -0.62) * CFrame.Angles(0, math.rad(-40), 0),
		SUIT_TRIM,
		nil,
		"Body"
	)
	k:ball("PatchStar", 0.2, v3(0.66, 2.79, -0.68), rgb(255, 220, 80), nil, "Body")
	-- A constellation of little stars across the suit
	local suitShell: Kit.Shell = { center = v3(0, 2.6, 0), radii = v3(0.93, 0.75, 1.15) }
	for i = 1, 9 do
		local yaw = ((i * 137.5) % 300) - 150
		local pitch = -10 + (i * 37) % 60
		k:ball(
			"SuitStar",
			0.1 + (i % 3) * 0.03,
			(Kit.surface(suitShell, yaw, pitch)),
			rgb(255, 226, 110),
			Enum.Material.Neon,
			"Body"
		)
	end
	local pack = CFrame.new(0, 3.1, 0.75)
	k:part("Jetpack", v3(1.0, 0.9, 0.5), pack, rgb(200, 205, 220), Enum.Material.Metal, "Body")
	for _, side in { -1, 1 } do
		k:cylinder(
			"Thruster",
			0.5,
			0.34,
			pack * CFrame.new(side * 0.32, -0.55, 0.05),
			rgb(90, 95, 110),
			Enum.Material.Metal,
			"Body"
		)
		local nozzle = (pack * CFrame.new(side * 0.32, -0.82, 0.05)).Position
		Parts.cone(k, "Flame", nozzle, nozzle + v3(0, -0.55, 0.1), 0.15, rgb(255, 170, 60), Enum.Material.Neon, "Body")
	end
	Parts.tube(
		k,
		"Tail",
		{ v3(0, 2.6, 1.2), v3(0, 2.1, 1.45), v3(0, 1.6, 1.5) },
		{ 0.08, 0.07, 0.06 },
		GIRAFFE,
		nil,
		"Body",
		{ density = 3 }
	)
	k:ellipsoid("TailTuft", v3(0.22, 0.4, 0.22), CFrame.new(0, 1.45, 1.5), SPOT, nil, "Body")

	-- The long spotted neck and head inside a glass helmet
	local neckPoints = { v3(0, 2.9, -0.8), v3(0, 3.9, -1.0), v3(0, 4.8, -1.05) }
	Parts.tube(k, "Neck", neckPoints, { 0.38, 0.3, 0.26 }, GIRAFFE, nil, "Body", { density = 1, overlap = 6 })
	for i, spot in { { 3.4, -1.3, 0 }, { 4.1, -1.25, 50 }, { 3.7, -0.72, 110 }, { 4.5, -1.1, -60 } } do
		local _ = i
		k:ellipsoid(
			"Spot",
			v3(0.26, 0.3, 0.1),
			CFrame.lookAt(
				v3(math.sin(math.rad(spot[3])) * 0.3, spot[1], spot[2]),
				v3(math.sin(math.rad(spot[3])) * 2, spot[1], spot[2] - 1)
			),
			SPOT,
			nil,
			"Body"
		)
	end
	for _, spot in { { 70, 20 }, { -70, 10 }, { 110, -20 }, { -120, 0 }, { 150, 30 } } do
		Parts.patch(k, "Spot", shell, spot[1], spot[2], 0.42, 0.34, SPOT, nil, "Body")
	end
	local head: Kit.Shell = { center = v3(0, 5.15, -1.2), radii = v3(0.5, 0.45, 0.62) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), GIRAFFE, nil, "Body")
	k:ellipsoid("Muzzle", v3(0.7, 0.5, 0.6), CFrame.new(0, 5.0, -1.65), rgb(245, 222, 170), nil, "Body")
	for _, side in { -1, 1 } do
		k:limb("Ossicone", v3(side * 0.2, 5.5, -1.1), v3(side * 0.26, 5.9, -1.05), 0.12, GIRAFFE, nil, "Body")
		k:ball("OssiconeTip", 0.2, v3(side * 0.26, 5.95, -1.05), SPOT, nil, "Body")
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.38, 5.35, -1.05),
			v3(side * 0.75, 5.45, -0.95),
			0.24,
			0.06,
			GIRAFFE,
			v3(0, 0.3, -1).Unit,
			nil,
			"Body"
		)
		k:ball("Nostril", 0.07, v3(side * 0.14, 5.08, -1.94), rgb(120, 80, 50), nil, "Body")
	end
	k:eyes(head, 38, 16, { width = 0.24, height = 0.28, iris = rgb(40, 30, 30) }, "Body")
	k:mouth(
		CFrame.new(0, 4.86, -1.9),
		{ width = 0.3, height = 0.1, skin = rgb(245, 222, 170), style = "Smile", radius = 0.4 },
		"Body"
	)
	local helmet = k:ball("Helmet", 1.75, v3(0, 5.25, -1.25), rgb(210, 235, 255), Enum.Material.Glass, "Body")
	helmet.Transparency = 0.55
	helmet.CastShadow = false
	helmet:SetAttribute("KeepColor", true)
	k:ball("HelmetShine", 0.22, v3(-0.4, 5.72, -1.9), C.White, nil, "Body")
	k:oval(
		"HelmetRing",
		CFrame.new(0, 4.42, -1.12) * CFrame.Angles(math.rad(-8), 0, 0),
		1.0,
		1.0,
		0.16,
		SUIT_TRIM,
		Enum.Material.Metal,
		"Body"
	)
	k:turn(-28)
	return body
end

return Legendary
