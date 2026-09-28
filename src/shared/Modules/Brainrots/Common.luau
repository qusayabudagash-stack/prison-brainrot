-- COMMON Brainrots: simple, cute, few details.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Common: { [string]: (Kit) -> BasePart } = {}

Common.PotatoPrisoner = function(k)
	local skin = rgb(214, 166, 106)
	local skinDark = rgb(168, 118, 66)
	local potato: Kit.Shell = { center = v3(0, 3.25, 0), radii = v3(1.5, 2.0, 1.36) }
	local suit: Kit.Shell = { center = v3(0, 2.0, 0), radii = v3(1.6, 1.2, 1.46) }

	-- Lumpy potato body: bumps sit on the back and sides so the face stays clean.
	local body = k:ellipsoid(
		"Body",
		potato.radii * 2,
		CFrame.new(potato.center) * CFrame.Angles(0, 0, math.rad(4)),
		skin,
		nil,
		"Body"
	)
	k:ellipsoid(
		"Lump",
		v3(1.25, 1.0, 1.1),
		CFrame.new(0.85, 4.35, 0.6) * CFrame.Angles(0, 0, math.rad(-25)),
		skin,
		nil,
		"Body"
	)
	k:ellipsoid("Lump", v3(1.0, 1.25, 1.0), CFrame.new(-1.05, 3.5, 0.55), skin, nil, "Body")
	for _, spot in { { 125, 35 }, { -150, 20 }, { 165, 55 }, { 70, 50 }, { -80, 45 } } do
		k:ellipsoid("PotatoEye", v3(0.24, 0.18, 0.08), Kit.on(potato, spot[1], spot[2], -0.02), skinDark, nil, "Body")
	end

	-- Jumpsuit over the lower third
	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 2.62, 0.3, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, 8, 0.02), "#042", 0.95, "Body")
	k:ellipsoid("Pocket", v3(0.5, 0.42, 0.06), Kit.on(suit, 34, 8, 0), C.JumpsuitDark, Enum.Material.Fabric, "Body")

	-- Face
	k:eyes(
		potato,
		19,
		22,
		{ width = 0.84, height = 1.06, iris = rgb(95, 65, 40), look = Vector2.new(-0.3, 0.15), skin = skin },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:brow(Kit.on(potato, 21 * side, 43, 0.02), 0.7, -20 * side, rgb(90, 55, 30), "Body")
		k:blush(Kit.on(potato, 37 * side, 6, -0.02), 0.62, "Body")
	end
	k:ellipsoid("Nose", v3(0.34, 0.3, 0.34), Kit.on(potato, 0, 9, -0.06), skinDark:Lerp(skin, 0.45), nil, "Body")
	k:mouth(
		Kit.on(potato, 0, -3, -0.04),
		{ width = 1.2, height = 0.72, skin = skin, style = "Grin", buckTooth = true },
		"Body"
	)

	-- Sprout
	k:limb("Stem", v3(0.05, 5.15, 0.05), v3(0.25, 5.7, 0.1), 0.14, rgb(95, 170, 70), nil, "Body")
	k:ellipsoid(
		"Leaf",
		v3(0.62, 0.12, 0.34),
		CFrame.new(0.0, 5.77, 0.1) * CFrame.Angles(0, 0, math.rad(25)),
		rgb(110, 200, 80),
		nil,
		"Body"
	)
	k:ellipsoid(
		"Leaf",
		v3(0.5, 0.12, 0.3),
		CFrame.new(0.53, 5.75, 0.1) * CFrame.Angles(0, 0, math.rad(-30)),
		rgb(95, 180, 70),
		nil,
		"Body"
	)

	-- Arms: one waving hello, one relaxed
	Parts.arm(k, "ArmR", v3(1.38, 2.55, 0.05), v3(2.3, 3.75, -0.25), 0.5, C.Jumpsuit, skin, 0.58)
	Parts.arm(k, "ArmL", v3(-1.38, 2.5, 0.05), v3(-1.9, 1.6, -0.2), 0.5, C.Jumpsuit, skin, 0.58)

	Parts.legs(k, 1.15, 0.6, 0.64, C.Jumpsuit, rgb(250, 250, 245), rgb(210, 205, 195), 1, C.JumpsuitDark)
	k:ballAndChain(v3(-0.64, 0.55, 0), v3(-2.1, 0, 0.7), 0.64)
	return body
end

Common.ChickenThief = function(k)
	local feather = rgb(255, 250, 238)
	local orange = rgb(255, 160, 40)
	local red = rgb(235, 50, 60)
	local shell: Kit.Shell = { center = v3(0, 2.6, 0), radii = v3(1.45, 1.6, 1.4) }
	local shirt: Kit.Shell = { center = v3(0, 2.05, 0), radii = v3(1.53, 1.1, 1.48) }

	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), feather, nil, "Body")

	-- Striped prison shirt
	k:ellipsoid("Shirt", shirt.radii * 2, CFrame.new(shirt.center), C.White, Enum.Material.Fabric, "Body")
	Parts.stripes(k, shirt, 1.25, 2.85, 4, C.Stripe, "Body")
	k:band("ShirtCollar", shirt, 2.9, 0.22, C.Stripe, Enum.Material.Fabric, "Body")

	-- Tail feathers and comb
	for i, angle in { -30, 0, 30 } do
		local tip = v3(math.sin(math.rad(angle)) * 0.7, 3.7 + (if i == 2 then 0.25 else 0), 1.9)
		k:limb("TailFeather", v3(0, 2.7, 1.1), tip, 0.5, feather, nil, "Body")
	end
	for i, p in { v3(-0.28, 4.08, -0.35), v3(0.02, 4.28, -0.05), v3(0.3, 4.1, 0.25) } do
		k:ball("Comb", 0.55 - i * 0.04, p, red, nil, "Body")
	end

	-- Bandit mask across the eyes, tied at the back
	Parts.patch(k, "Mask", shell, 0, 26, 2.6, 0.8, C.Ink, Enum.Material.Fabric, "Body")
	for _, side in { -1, 1 } do
		k:limb(
			"MaskTail",
			v3(side * 0.15, 3.32, 1.35),
			v3(side * 0.55, 2.9, 1.85),
			0.18,
			C.Ink,
			Enum.Material.Fabric,
			"Body"
		)
	end

	-- Face
	k:eyes(shell, 22, 29, {
		width = 0.66,
		height = 0.8,
		iris = rgb(70, 60, 60),
		look = Vector2.new(0.5, -0.1),
		lid = 0.25,
		lidTilt = 18,
		skin = C.Ink,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(Kit.on(shell, 23 * side, 45, 0.02), 0.6, 20 * side, rgb(60, 50, 50), "Body")
	end
	local beak = Kit.on(shell, 0, 14, 0.18)
	k:ellipsoid("Beak", v3(0.75, 0.36, 0.8), beak * CFrame.Angles(math.rad(-10), 0, 0), orange, nil, "Body")
	k:ellipsoid(
		"BeakLower",
		v3(0.55, 0.22, 0.55),
		beak * CFrame.new(0, -0.25, 0.05) * CFrame.Angles(math.rad(15), 0, 0),
		orange:Lerp(Color3.new(0, 0, 0), 0.12),
		nil,
		"Body"
	)
	k:ellipsoid("Wattle", v3(0.3, 0.45, 0.25), Kit.on(shell, 0, 4, 0.05), red, nil, "Body")
	for _, side in { -1, 1 } do
		k:blush(Kit.on(shell, 38 * side, 12, -0.02), 0.5, "Body")
	end

	-- Wings: one clutching a stolen egg, one on the hip
	k:ellipsoid(
		"Wing",
		v3(0.45, 1.25, 1.0),
		CFrame.new(1.45, 2.55, -0.35) * CFrame.Angles(math.rad(35), 0, math.rad(25)),
		feather,
		nil,
		"ArmR"
	)
	k:ellipsoid(
		"StolenEgg",
		v3(0.72, 0.92, 0.72),
		CFrame.new(1.35, 2.15, -1.15) * CFrame.Angles(0, 0, math.rad(-12)),
		rgb(250, 238, 215),
		nil,
		"ArmR"
	)
	for _, speck in { v3(1.2, 2.35, -1.48), v3(1.45, 1.95, -1.5) } do
		k:ball("EggSpeck", 0.1, speck, rgb(200, 160, 110), nil, "ArmR")
	end
	k.model:SetAttribute("ArmRJoint", v3(1.3, 2.9, 0))
	k:ellipsoid(
		"Wing",
		v3(0.45, 1.25, 1.0),
		CFrame.new(-1.5, 2.45, 0.2) * CFrame.Angles(math.rad(-20), 0, math.rad(-35)),
		feather,
		nil,
		"ArmL"
	)
	k.model:SetAttribute("ArmLJoint", v3(-1.3, 2.9, 0))

	Parts.birdLegs(k, 1.25, 0.52, orange)
	return body
end

Common.BananaJailbird = function(k)
	local yellow = rgb(255, 222, 70)
	local yellowDark = rgb(225, 180, 40)
	local brown = rgb(105, 75, 40)
	local points = { v3(-0.15, 1.5, 0), v3(-0.05, 2.5, 0), v3(0.1, 3.45, 0), v3(0.35, 4.3, 0), v3(0.7, 4.95, 0) }
	local widths = { 1.45, 1.55, 1.5, 1.3, 1.0 }
	local body: BasePart = nil :: any
	for i = 1, #points - 1 do
		local segment = k:limb("Segment", points[i], points[i + 1], widths[i], yellow, nil, "Body")
		if i == 3 then
			body = segment
		end
	end
	-- Ridges down the peel and a brown stem
	for _, side in { -1, 1 } do
		k:limb(
			"Ridge",
			points[2] + v3(side * 0.66, 0, -0.1),
			points[4] + v3(side * 0.55, 0, -0.1),
			0.12,
			yellowDark,
			nil,
			"Body"
		)
	end
	k:limb("Stem", points[5], points[5] + v3(0.45, 0.35, 0), 0.32, brown, nil, "Body")
	k:ellipsoid(
		"StemTip",
		v3(0.34, 0.2, 0.34),
		CFrame.new(points[5] + v3(0.52, 0.42, 0)) * CFrame.Angles(0, 0, math.rad(-50)),
		rgb(70, 50, 30),
		nil,
		"Body"
	)

	local face: Kit.Shell = { center = v3(0.08, 3.35, 0), radii = v3(0.76, 1.2, 0.75) }
	local suit: Kit.Shell = { center = v3(-0.08, 1.75, 0), radii = v3(0.95, 1.0, 0.9) }

	k:ellipsoid("Jumpsuit", suit.radii * 2, CFrame.new(suit.center), C.Jumpsuit, Enum.Material.Fabric, "Body")
	k:band("Collar", suit, 2.5, 0.24, C.JumpsuitDark, Enum.Material.Fabric, "Body")
	k:badge(Kit.on(suit, 0, 30, 0.02), "#88", 0.6, "Body")

	k:eyes(
		face,
		25,
		26,
		{ width = 0.52, height = 0.68, iris = rgb(80, 55, 30), look = Vector2.new(0, 0.3), skin = yellow },
		"Body"
	)
	for _, side in { -1, 1 } do
		k:brow(Kit.on(face, 26 * side, 48, 0.02), 0.44, -14 * side, rgb(120, 85, 30), "Body")
	end
	k:mouth(Kit.on(face, 0, -8, -0.03), { width = 0.72, height = 0.42, skin = yellow, style = "Grin" }, "Body")

	-- Tilted striped prison cap
	Parts.prisonCap(k, CFrame.new(0.3, 4.55, -0.05) * CFrame.Angles(0, 0, math.rad(-22)), 1.05, "Body")

	Parts.arm(k, "ArmR", v3(0.85, 2.3, 0), v3(1.5, 2.9, -0.5), 0.36, C.Jumpsuit, yellow, 0.46)
	Parts.arm(k, "ArmL", v3(-0.95, 2.3, 0), v3(-1.45, 1.5, -0.1), 0.36, C.Jumpsuit, yellow, 0.46)
	Parts.legs(k, 1.0, 0.42, 0.46, C.Jumpsuit, rgb(250, 250, 245), rgb(210, 205, 195), 0.8, C.JumpsuitDark)
	return body
end

Common.SockSnatcher = function(k)
	local sock = rgb(245, 245, 250)
	local red = rgb(225, 55, 70)
	local patch = rgb(185, 40, 55)
	local tube: Kit.Shell = { center = v3(0, 2.85, 0.15), radii = v3(0.95, 1.7, 0.95) }

	-- An upright sock: the tube is the body, the foot at the bottom points forward.
	local body = k:limb("Body", v3(0, 1.35, 0.15), v3(0, 4.3, 0.15), 1.9, sock, Enum.Material.Fabric, "Body")
	Parts.stripes(k, tube, 1.45, 3.05, 3, red, "Body", 0.55)
	k:limb("Foot", v3(0, 0.85, 0.35), v3(0, 0.75, -1.25), 1.55, sock, Enum.Material.Fabric, "Body")
	k:ellipsoid("Heel", v3(1.45, 1.2, 0.9), CFrame.new(0, 0.95, 0.85), patch, Enum.Material.Fabric, "Body")
	k:ellipsoid("Toe", v3(1.5, 1.3, 1.0), CFrame.new(0, 0.78, -1.55), patch, Enum.Material.Fabric, "Body")

	-- Ribbed cuff and the dark opening, with a stolen sock poking out
	k:cylinder("Cuff", 0.55, 2.0, CFrame.new(0, 4.55, 0.15), red, Enum.Material.Fabric, "Body")
	for i = 0, 1 do
		k:cylinder("CuffRib", 0.12, 2.04, CFrame.new(0, 4.4 + i * 0.3, 0.15), C.White, Enum.Material.Fabric, "Body")
	end
	k:cylinder("Opening", 0.06, 1.6, CFrame.new(0, 4.83, 0.15), rgb(40, 30, 40), nil, "Body")
	k:limb("LootSock", v3(0.2, 4.7, 0.4), v3(0.55, 5.6, 0.55), 0.55, rgb(110, 210, 120), Enum.Material.Fabric, "Body")
	k:limb(
		"LootSockToe",
		v3(0.55, 5.6, 0.55),
		v3(0.95, 5.5, 0.2),
		0.52,
		rgb(90, 190, 100),
		Enum.Material.Fabric,
		"Body"
	)

	-- Sneaky side-eye and a nervous grin
	k:eyes(tube, 20, 25, {
		width = 0.62,
		height = 0.74,
		iris = rgb(60, 50, 50),
		look = Vector2.new(1, 0.1),
		lid = 0.3,
		lidTilt = -8,
		skin = sock,
	}, "Body")
	for _, side in { -1, 1 } do
		k:brow(Kit.on(tube, 22 * side, 41, 0.02), 0.55, 14 * side, rgb(70, 60, 60), "Body")
	end
	k:mouth(Kit.on(tube, 0, 8, -0.03), { width = 0.8, height = 0.45, skin = sock, style = "Teeth" }, "Body")
	k:ellipsoid(
		"SweatDrop",
		v3(0.22, 0.34, 0.14),
		Kit.on(tube, 42, 36, 0.08),
		rgb(140, 200, 255),
		Enum.Material.Glass,
		"Body"
	)

	Parts.bareArm(k, "ArmR", v3(0.9, 2.95, 0.1), v3(1.6, 3.5, -0.45), 0.34, sock, 0.48)
	Parts.bareArm(k, "ArmL", v3(-0.9, 2.95, 0.1), v3(-1.5, 2.2, -0.2), 0.34, sock, 0.48)
	return body
end

Common.BreadBandit = function(k)
	local crust = rgb(190, 122, 55)
	local crumb = rgb(250, 228, 180)
	local toasty = rgb(225, 180, 110)
	local black = rgb(30, 28, 32)

	-- A slice of toast standing up: crust shape with a soft crumb face
	local body = k:part("Body", v3(2.9, 2.2, 0.8), CFrame.new(0, 2.55, 0), crust, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid("CrustLobe", v3(1.75, 1.45, 0.8), CFrame.new(side * 0.68, 3.75, 0), crust, nil, "Body")
		k:ellipsoid("CrumbLobe", v3(1.5, 1.22, 0.1), CFrame.new(side * 0.68, 3.72, -0.41), crumb, nil, "Body")
	end
	k:part("Crumb", v3(2.6, 2.0, 0.1), CFrame.new(0, 2.6, -0.41), crumb, nil, "Body")
	for _, spot in { v3(-0.9, 1.9, -0.47), v3(0.95, 2.2, -0.47), v3(0.3, 4.05, -0.47) } do
		k:ellipsoid("ToastSpot", v3(0.4, 0.28, 0.02), CFrame.new(spot), toasty, nil, "Body")
	end
	k:part(
		"Butter",
		v3(0.7, 0.35, 0.55),
		CFrame.new(-0.7, 4.52, 0) * CFrame.Angles(0, math.rad(20), math.rad(6)),
		rgb(255, 230, 110),
		nil,
		"Body"
	)

	-- Bandit mask and face
	k:part("Mask", v3(2.95, 0.62, 0.06), CFrame.new(0, 3.35, -0.47), black, Enum.Material.Fabric, "Body")
	for _, side in { -1, 1 } do
		k:limb(
			"MaskTail",
			v3(side * 1.45, 3.35, -0.2),
			v3(side * 1.85, 2.95, 0.25),
			0.18,
			black,
			Enum.Material.Fabric,
			"Body"
		)
		k:eye(CFrame.new(side * 0.55, 3.35, -0.48), {
			width = 0.5,
			height = 0.56,
			iris = rgb(70, 50, 30),
			look = Vector2.new(0.4, 0),
			lid = 0.2,
			lidTilt = 20,
			skin = black,
			side = side,
		}, "Body")
		k:blush(CFrame.new(side * 0.95, 2.75, -0.47), 0.46, "Body")
	end
	k:mouth(CFrame.new(0, 2.5, -0.47), { width = 0.95, height = 0.55, skin = crumb, style = "Grin" }, "Body")

	-- Loot sack in one hand
	Parts.bareArm(k, "ArmR", v3(1.4, 2.5, 0), v3(2.0, 1.9, -0.4), 0.32, crust, 0.46)
	local sack = k:ellipsoid(
		"LootSack",
		v3(1.3, 1.4, 1.2),
		CFrame.new(2.2, 1.3, -0.35),
		rgb(215, 190, 135),
		Enum.Material.Fabric,
		"ArmR"
	)
	k:cylinder("SackTie", 0.22, 0.5, CFrame.new(2.1, 2.0, -0.4), rgb(150, 110, 60), Enum.Material.Fabric, "ArmR")
	local mark = k:part(
		"SackMark",
		v3(0.55, 0.55, 0.05),
		CFrame.new(2.2, 1.3, -0.97),
		rgb(215, 190, 135),
		Enum.Material.Fabric,
		"ArmR"
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = mark
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = rgb(60, 140, 60)
	label.Text = "$"
	label.Parent = gui
	local _ = sack
	Parts.bareArm(k, "ArmL", v3(-1.4, 2.5, 0), v3(-1.8, 1.75, 0.1), 0.32, crust, 0.46)

	Parts.legs(k, 1.5, 0.6, 0.42, crust, black, rgb(200, 200, 205), 0.85, crust)
	return body
end

return Common
