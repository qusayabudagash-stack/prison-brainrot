-- DIVINE Brainrots: the showpieces. The most detailed builds in the game, with smooth lofted bodies
-- and premium touches, so they read as special even without their rarity effects.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local C = Kit.Colors
local rgb = Color3.fromRGB
local v3 = Vector3.new

local Divine: { [string]: (Kit) -> BasePart } = {}

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
	-- A cheaper build for when several sharks share one model: simpler face, fins and shoes.
	lite: boolean?,
}

-- One shark on three legs, built in the frame `at` (facing its -Z) at size `s`. Returns the widest
-- body part.
local function shark(k: Kit, at: CFrame, s: number, style: SharkStyle?): BasePart
	local look: SharkStyle = style or {}
	local lite = look.lite == true
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
	if lite then
		k:ellipsoid("Skin", v3(0.62, 0.6, 2.2) * s, CFrame.new(p(0, 3.2, 1.9)) * at.Rotation, skin, nil, "Body")
	else
		k:loft("Skin", top, skin, nil, "Body", { density = 1, overlap = 9 })
		k:loft("Belly", under, BELLY, nil, "Body", { density = 1, overlap = 9 })
	end

	-- Gill slits
	if not lite then
		local flank: Kit.Shell = { center = p(0, 3.02, -1.25), radii = v3(1.12, 1.06, 1.3) * s, rotation = at.Rotation }
		for _, side in { -1, 1 } do
			for i = 0, 1 do
				Parts.patch(k, "Gill", flank, side * (100 + i * 11), 4, 0.08 * s, 0.62 * s, dark, nil, "Body", side * 8)
			end
		end
	end

	-- Fins: thin lofts, their chords running front to back
	local fore = dir(0, 0, -1)
	local function fin(name: string, points: { { number } }, color: Color3, up: Vector3?, density: number?)
		local sections: { Kit.Section } = {}
		for _, q in points do
			table.insert(sections, { at = p(q[1], q[2], q[3]), w = q[4] * s, h = q[5] * s })
		end
		k:loft(name, sections, color, nil, "Body", {
			up = up or fore,
			density = (density or 0.38) * (if lite then 1.8 else 1),
			overlap = 4.5,
			minSpacing = (if lite then 0.3 else 0.16) * s,
		})
	end
	if lite then
		-- One flattened ellipsoid per fin
		local function blade(name: string, size: Vector3, x: number, y: number, z: number, pitch: number, roll: number)
			k:ellipsoid(
				name,
				size * s,
				CFrame.new(p(x, y, z)) * at.Rotation * CFrame.Angles(math.rad(pitch), 0, math.rad(roll)),
				skin,
				nil,
				"Body"
			)
		end
		blade("DorsalFin", v3(0.16, 1.5, 0.9), 0, 4.45, -0.1, -35, 0)
		blade("TailFin", v3(0.14, 1.3, 0.55), 0, 3.95, 3.25, -40, 0)
		blade("TailFin", v3(0.14, 0.9, 0.45), 0, 2.95, 3.2, 40, 0)
		for _, side in { -1, 1 } do
			blade("PectoralFin", v3(1.4, 0.14, 0.6), side * 1.4, 2.25, -1.0, 0, side * -22)
		end
	else
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
	end
	if not lite then
		fin("SmallFin", { { 0, 3.55, 1.85, 0.07, 0.22 }, { 0, 3.9, 2.15, 0.03, 0.04 } }, skin, nil, 0.8)
		fin("SmallFin", { { 0, 2.8, 2.05, 0.06, 0.18 }, { 0, 2.55, 2.32, 0.03, 0.04 } }, BELLY, nil, 0.8)
	end

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
	if lite then
		k:mouth(
			Kit.on(head, 0, -16, 0),
			{ width = 1.3 * s, height = 0.42 * s, skin = BELLY, style = "Teeth", radius = 1.1 * s },
			"Body"
		)
	else
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
	end

	-- Three legs in white socks and blue sneakers: two up front, one behind
	for _, leg in { { -0.56, -1.3 }, { 0.56, -1.3 }, { 0, 0.85 } } do
		local x, z = leg[1], leg[2]
		local hip, knee, ankle = p(x, 2.45, z), p(x * 1.08, 1.25, z - 0.1), p(x * 1.08, 0.5, z)
		if lite then
			k:limb("Leg", hip, ankle, 0.5 * s, LEG, nil, "Legs")
		else
			k:loft("Leg", {
				{ at = hip, w = 0.3 * s, h = 0.3 * s },
				{ at = knee, w = 0.25 * s, h = 0.25 * s },
				{ at = ankle, w = 0.22 * s, h = 0.22 * s },
			}, LEG, nil, "Legs", { density = 3.2, overlap = 7 })
		end
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
		if lite then
			local shoe = CFrame.new(p(x * 1.08, 0, z - 0.22)) * at.Rotation
			k:oval(
				"Sole",
				shoe * CFrame.new(0, 0.1 * s, 0),
				0.95 * s,
				1.5 * s,
				0.2 * s,
				C.White,
				Enum.Material.Rubber,
				"Legs"
			)
			k:ellipsoid(
				"Shoe",
				v3(0.86, 0.6, 1.3) * s,
				shoe * CFrame.new(0, 0.34 * s, 0),
				look.sneaker or SNEAKER,
				Enum.Material.Leather,
				"Legs"
			)
		else
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

---------------------------------------------------------------------------
-- Los Tralaleritos: three little Tralaleros riding one surfboard
---------------------------------------------------------------------------

Divine.LosTralaleritos = function(k: Kit): BasePart
	local board = CFrame.new(0, 0.18, 0.2)
	k:oval("Surfboard", board, 3.6, 6.2, 0.26, rgb(250, 248, 240), nil, "Legs")
	k:oval("SurfStripe", board * CFrame.new(0, 0.03, 0), 0.9, 6.0, 0.26, rgb(255, 120, 60), nil, "Legs")
	local body: BasePart? = nil
	for _, rider in
		{
			{ x = 0, z = -1.1, yaw = 0, sneaker = rgb(34, 100, 228), size = 0.62 },
			{ x = -1.05, z = 1.0, yaw = 14, sneaker = rgb(230, 50, 50), size = 0.54 },
			{ x = 1.05, z = 1.0, yaw = -14, sneaker = rgb(250, 190, 40), size = 0.54 },
		}
	do
		local at = CFrame.new(rider.x, 0.3, rider.z) * CFrame.Angles(0, math.rad(rider.yaw), 0)
		local part = shark(k, at, rider.size, { lite = true, sneaker = rider.sneaker })
		body = body or part
	end
	k:turn(-30)
	return body :: BasePart
end

---------------------------------------------------------------------------
-- Dragon Cannelloni: a dragon made of pasta, with lasagna wings
---------------------------------------------------------------------------

local PASTA = rgb(248, 214, 132)
local PASTA_DARK = rgb(222, 180, 104)
local RICOTTA = rgb(252, 250, 242)
local SAUCE = rgb(206, 50, 38)
local BASIL = rgb(58, 150, 62)
local PARMESAN = rgb(250, 238, 186)

-- One cannelloni tube from `a` to `b`: pasta with ricotta showing at both ends and sauce on top.
local function cannelloni(k: Kit, a: Vector3, b: Vector3, diameter: number, rig: string, sauce: boolean?): Part
	local axis = (b - a).Unit
	local frame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0)
	local tube = k:cylinder("Cannelloni", (b - a).Magnitude, diameter, frame, PASTA, nil, rig)
	for _, point in { { at = a, sign = -1 }, { at = b, sign = 1 } } do
		local at = point.at
		local out = axis * point.sign
		k:disc("Ricotta", diameter * 0.72, 0.06, CFrame.lookAt(at + out * 0.01, at + out * 2), RICOTTA, nil, rig)
	end
	if sauce ~= false then
		local up = Vector3.yAxis - axis * axis.Y
		up = if up.Magnitude > 0.1 then up.Unit else Vector3.zAxis
		local top = (a + b) / 2 + up * diameter * 0.42
		k:ellipsoid(
			"Sauce",
			v3(diameter * 0.9, 0.22, (b - a).Magnitude * 0.75),
			CFrame.lookAt(top, top + axis),
			SAUCE,
			nil,
			rig
		)
		-- Two drips running down the front
		local front = up:Cross(axis).Unit
		front = if front.Z > 0 then -front else front
		for _, t in { 0.3, 0.68 } do
			local drip = a:Lerp(b, t) + front * diameter * 0.44 + up * diameter * 0.12
			k:ellipsoid("SauceDrip", v3(0.16, diameter * 0.5, 0.12), CFrame.lookAt(drip, drip + front), SAUCE, nil, rig)
		end
	end
	return tube
end

-- A wing made of three wavy lasagna strips fanning out from the shoulder, each with a sauce layer.
local function lasagnaWing(k: Kit, root: Vector3, side: number)
	local rig = if side < 0 then "WingL" else "WingR"
	for i, spread in { 0.25, 0.65, 1.05 } do
		local dir = v3(side * math.cos(spread), math.sin(spread) + 0.25, 0.35).Unit
		local length = 2.5 - i * 0.3
		local tip = root + dir * length
		local face = dir:Cross(Vector3.zAxis).Unit
		local strip = CFrame.fromMatrix((root + tip) / 2, face, dir)
		k:ellipsoid("Lasagna", v3(0.12, length, 0.9), strip, PASTA, nil, rig)
		k:ellipsoid("LasagnaSauce", v3(0.18, length * 0.8, 0.46), strip * CFrame.new(0, 0.1, -0.05), SAUCE, nil, rig)
		k:ellipsoid("LasagnaEdge", v3(0.14, length * 0.9, 0.2), strip * CFrame.new(0, 0, 0.45), PASTA_DARK, nil, rig)
	end
	k.model:SetAttribute(rig .. "Joint", root)
end

Divine.DragonCannelloni = function(k: Kit): BasePart
	-- Legs: thick cannelloni thighs, pasta feet and parmesan claws
	for _, side in { -1, 1 } do
		cannelloni(k, v3(side * 0.62, 1.65, 0.1), v3(side * 0.7, 0.45, 0.0), 0.62, "Legs", false)
		k:ellipsoid("Foot", v3(0.72, 0.36, 1.0), CFrame.new(side * 0.72, 0.18, -0.2), PASTA_DARK, nil, "Legs")
		for toe = -1, 1 do
			k:limb(
				"Claw",
				v3(side * 0.72 + toe * 0.2, 0.16, -0.62),
				v3(side * 0.72 + toe * 0.24, 0.1, -0.88),
				0.14,
				PARMESAN,
				nil,
				"Legs"
			)
		end
	end
	-- The body: a stack of three cannelloni, widest at the bottom
	local body = cannelloni(k, v3(-0.95, 2.15, 0), v3(0.95, 2.15, 0), 1.0, "Body")
	cannelloni(k, v3(-0.85, 2.95, -0.05), v3(0.85, 2.95, -0.05), 0.92, "Body")
	cannelloni(k, v3(-0.72, 3.7, -0.1), v3(0.72, 3.7, -0.1), 0.84, "Body")
	-- Little arms
	for _, side in { -1, 1 } do
		local rig = if side < 0 then "ArmL" else "ArmR"
		local shoulder = v3(side * 0.85, 3.2, -0.2)
		local hand = v3(side * 1.4, 2.6, -0.7)
		cannelloni(k, shoulder, hand, 0.34, rig, false)
		for toe = -1, 1, 2 do
			k:limb("Claw", hand, hand + v3(side * 0.1 + toe * 0.1, -0.2, -0.28), 0.12, PARMESAN, nil, rig)
		end
		k.model:SetAttribute(rig .. "Joint", shoulder)
	end
	-- Lasagna wings
	lasagnaWing(k, v3(-0.55, 3.7, 0.45), -1)
	lasagnaWing(k, v3(0.55, 3.7, 0.45), 1)
	-- Neck of two short tubes and a fierce pasta head
	cannelloni(k, v3(0, 3.95, -0.15), v3(0, 4.6, -0.45), 0.6, "Body", false)
	cannelloni(k, v3(0, 4.55, -0.42), v3(0, 5.05, -0.85), 0.54, "Body", false)
	local head: Kit.Shell = { center = v3(0, 5.35, -1.0), radii = v3(0.68, 0.56, 0.7) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), PASTA, nil, "Body")
	k:loft("Snout", {
		{ at = v3(0, 5.2, -1.3), w = 0.5, h = 0.38 },
		{ at = v3(0, 5.1, -1.95), w = 0.38, h = 0.3 },
	}, PASTA, nil, "Body", { density = 1, overlap = 5 })
	k:ellipsoid("SauceDrip", v3(0.9, 0.2, 0.9), CFrame.new(0, 5.86, -0.95), SAUCE, nil, "Body")
	for _, side in { -1, 1 } do
		Parts.cone(k, "Horn", v3(side * 0.34, 5.7, -0.75), v3(side * 0.62, 6.35, -0.35), 0.16, PARMESAN, nil, "Body")
		k:ball("Nostril", 0.12, v3(side * 0.14, 5.3, -2.2), PASTA_DARK, nil, "Body")
		k:tooth(CFrame.lookAt(v3(side * 0.24, 4.92, -1.9), v3(side * 0.24, 4.92, -2.9)), 0.14, 0.24, nil, "Body")
		Parts.leaf(
			k,
			"Frill",
			v3(side * 0.6, 5.35, -0.8),
			v3(side * 1.05, 5.55, -0.55),
			0.32,
			0.06,
			SAUCE,
			v3(side, 0.3, -0.4).Unit,
			nil,
			"Body"
		)
	end
	k:eyes(
		head,
		36,
		20,
		{ width = 0.34, height = 0.38, iris = rgb(236, 170, 30), lid = 0.3, lidTilt = 20, skin = PASTA },
		"Body"
	)
	k:mouth(
		CFrame.new(0, 4.98, -1.78),
		{ width = 0.6, height = 0.18, skin = PASTA, style = "Smirk", radius = 0.5 },
		"Body"
	)
	Parts.leaf(
		k,
		"Basil",
		v3(0.1, 5.9, -0.9),
		v3(0.45, 6.25, -1.1),
		0.36,
		0.06,
		BASIL,
		v3(0, 1, -0.3).Unit,
		nil,
		"Body"
	)
	Parts.leaf(
		k,
		"Basil",
		v3(-0.05, 5.9, -0.9),
		v3(-0.35, 6.2, -0.7),
		0.3,
		0.06,
		BASIL,
		v3(0, 1, 0.2).Unit,
		nil,
		"Body"
	)
	-- A tail of shrinking tubes curling behind, tipped with a basil leaf
	local previous = v3(0, 2.3, 0.45)
	for i, point in { v3(0.5, 1.8, 1.2), v3(1.2, 1.35, 1.55), v3(1.95, 1.2, 1.45) } do
		cannelloni(k, previous, point, 0.6 - i * 0.12, "Body", i == 1)
		previous = point
	end
	Parts.leaf(k, "Basil", previous, previous + v3(0.55, 0.35, -0.2), 0.42, 0.06, BASIL, Vector3.yAxis, nil, "Body")
	for i = 1, 5 do
		local yaw = (i * 71) % 360 - 180
		k:part(
			"Parmesan",
			v3(0.14, 0.04, 0.1),
			CFrame.new(math.sin(math.rad(yaw)) * 0.5, 4.08, math.cos(math.rad(yaw)) * 0.3 - 0.1)
				* CFrame.Angles(0, math.rad(yaw), 0),
			PARMESAN,
			nil,
			"Body"
		)
	end
	k:turn(-18)
	return body
end

return Divine
