-- Reusable character pieces built on the Kit: limbs, prison clothing, hats and accessories.

local Kit = require(script.Parent.Kit)

type Kit = Kit.Kit

local Parts = {}

local C = Kit.Colors
local v3 = Vector3.new
local rgb = Color3.fromRGB

-- Arm from shoulder to hand: sleeve, forearm and a round mitten hand. Records the shoulder joint
-- on the model so the client animator can swing the arm.
function Parts.arm(
	k: Kit,
	rig: string,
	shoulder: Vector3,
	hand: Vector3,
	sleeveD: number,
	sleeve: Color3,
	skin: Color3,
	handD: number?,
	sleeveMaterial: Enum.Material?
)
	local elbow = shoulder:Lerp(hand, 0.6)
	k:limb("Sleeve", shoulder, elbow, sleeveD, sleeve, sleeveMaterial or Enum.Material.Fabric, rig)
	k:limb("Forearm", elbow, hand, sleeveD * 0.74, skin, nil, rig)
	k:ball("Hand", handD or sleeveD * 1.1, hand, skin, nil, rig)
	k.model:SetAttribute(rig .. "Joint", shoulder)
end

-- A bare arm (no sleeve), for animals and creatures.
function Parts.bareArm(k: Kit, rig: string, shoulder: Vector3, hand: Vector3, d: number, skin: Color3, handD: number?)
	k:limb("Arm", shoulder, hand, d, skin, nil, rig)
	k:ball("Hand", handD or d * 1.25, hand, skin, nil, rig)
	k.model:SetAttribute(rig .. "Joint", shoulder)
end

-- Pant legs with cuffs and chunky shoes.
function Parts.legs(
	k: Kit,
	hipY: number,
	spread: number,
	legD: number,
	pants: Color3,
	shoe: Color3,
	sole: Color3?,
	shoeSize: number?,
	cuff: Color3?
)
	for _, side in { -1, 1 } do
		local hip = v3(side * spread, hipY, 0)
		local ankle = v3(side * (spread + 0.04), 0.5, 0)
		k:limb("Leg", hip, ankle, legD, pants, Enum.Material.Fabric, "Legs")
		k:cylinder(
			"Cuff",
			0.18,
			legD * 1.12,
			CFrame.new(ankle + v3(0, 0.12, 0)),
			cuff or pants:Lerp(Color3.new(0, 0, 0), 0.15),
			Enum.Material.Fabric,
			"Legs"
		)
		k:shoe(ankle, shoeSize or 1, shoe, sole, "Legs")
	end
end

export type SneakerColors = {
	upper: Color3,
	sole: Color3?,
	-- Side stripe, heel tab and laces.
	accent: Color3?,
	lace: Color3?,
	collar: Color3?,
}

-- A chunky cartoon sneaker: rubber outsole, thick midsole, leather upper with a rounded toe box,
-- padded collar, tongue, laces, a side stripe on each side and a heel tab. `ankle` is the ankle
-- point (its height is ignored); `yaw` turns the toe in degrees.
function Parts.sneaker(k: Kit, ankle: Vector3, size: number, colors: SneakerColors, rig: string?, yaw: number?)
	local sole = colors.sole or C.Sole
	local accent = colors.accent or C.White
	local base = CFrame.new(ankle.X, 0, ankle.Z)
		* CFrame.Angles(0, math.rad(yaw or 0), 0)
		* CFrame.new(0, 0, -size * 0.22)
	local width, length = size * 0.96, size * 1.6
	k:oval(
		"Outsole",
		base * CFrame.new(0, size * 0.04, 0),
		width * 1.03,
		length * 1.02,
		size * 0.08,
		sole:Lerp(C.Ink, 0.45),
		Enum.Material.Rubber,
		rig
	)
	k:oval("Sole", base * CFrame.new(0, size * 0.16, 0), width, length, size * 0.2, sole, Enum.Material.Rubber, rig)
	local upper: Kit.Shell = {
		center = (base * CFrame.new(0, size * 0.33, size * 0.1)).Position,
		radii = v3(width * 0.45, size * 0.34, length * 0.42),
		rotation = base.Rotation,
	}
	k:ellipsoid(
		"Shoe",
		upper.radii * 2,
		CFrame.new(upper.center) * base.Rotation,
		colors.upper,
		Enum.Material.Leather,
		rig
	)
	k:ellipsoid(
		"ToeBox",
		v3(width * 0.86, size * 0.44, length * 0.5),
		base * CFrame.new(0, size * 0.29, -length * 0.25),
		colors.upper,
		Enum.Material.Leather,
		rig
	)
	k:oval(
		"Collar",
		base * CFrame.new(0, size * 0.6, size * 0.3),
		size * 0.64,
		size * 0.6,
		size * 0.14,
		colors.collar or colors.upper:Lerp(C.Ink, 0.3),
		Enum.Material.Fabric,
		rig
	)
	k:ellipsoid(
		"ShoeTongue",
		v3(size * 0.36, size * 0.44, size * 0.12),
		base * CFrame.new(0, size * 0.6, size * 0.02) * CFrame.Angles(math.rad(-28), 0, 0),
		colors.upper:Lerp(C.White, 0.15),
		Enum.Material.Leather,
		rig
	)
	for i = 0, 1 do
		k:ellipsoid(
			"Lace",
			v3(width * 0.4, size * 0.08, size * 0.09),
			Kit.on(upper, 0, 44 + i * 16, -size * 0.01),
			colors.lace or C.White,
			Enum.Material.Fabric,
			rig
		)
	end
	for _, side in { -1, 1 } do
		Parts.patch(k, "ShoeStripe", upper, 92 * side, -8, length * 0.5, size * 0.13, accent, nil, rig, -14 * side)
	end
	k:ellipsoid(
		"HeelTab",
		v3(size * 0.24, size * 0.3, size * 0.1),
		base * CFrame.new(0, size * 0.5, size * 0.66),
		accent,
		Enum.Material.Leather,
		rig
	)
end

-- Thin bird legs with three toes.
function Parts.birdLegs(k: Kit, hipY: number, spread: number, color: Color3)
	for _, side in { -1, 1 } do
		local hip = v3(side * spread, hipY, 0)
		local ankle = v3(side * spread, 0.18, -0.05)
		k:limb("Leg", hip, ankle, 0.24, color, nil, "Legs")
		for _, angle in { -35, 0, 35 } do
			local dir = v3(math.sin(math.rad(angle)), 0, -math.cos(math.rad(angle)))
			k:limb("Toe", ankle, ankle + dir * 0.65 + v3(0, -0.06, 0), 0.2, color, nil, "Legs")
		end
		k:limb("Toe", ankle, ankle + v3(0, -0.05, 0.4), 0.18, color, nil, "Legs")
	end
end

-- Dark prison stripes wrapped around a shell between two heights.
-- `fill` is how much of each stripe period is colored (0.5 = even stripes).
function Parts.stripes(
	k: Kit,
	shell: Kit.Shell,
	fromY: number,
	toY: number,
	count: number,
	color: Color3?,
	rig: string?,
	fill: number?
)
	for i = 1, count do
		local y = fromY + (toY - fromY) * (i - 0.5) / count
		k:band("Stripe", shell, y, (toY - fromY) / count * (fill or 0.5), color or C.Stripe, Enum.Material.Fabric, rig)
	end
end

-- Classic black-and-white striped prison cap, sitting on `cframe` (bottom center of the cap).
function Parts.prisonCap(k: Kit, cframe: CFrame, diameter: number, rig: string?)
	local h = diameter * 0.42
	k:cylinder("Cap", h, diameter, cframe * CFrame.new(0, h / 2, 0), C.White, Enum.Material.Fabric, rig)
	for i = 0, 1 do
		k:cylinder(
			"CapStripe",
			h * 0.22,
			diameter * 1.02,
			cframe * CFrame.new(0, h * (0.22 + i * 0.44), 0),
			C.Stripe,
			Enum.Material.Fabric,
			rig
		)
	end
	k:ellipsoid(
		"CapTop",
		v3(diameter, h * 0.45, diameter),
		cframe * CFrame.new(0, h, 0),
		C.White,
		Enum.Material.Fabric,
		rig
	)
end

-- A knitted beanie with a pom-pom, sitting on `cframe`.
function Parts.beanie(k: Kit, cframe: CFrame, diameter: number, color: Color3, pom: Color3?, rig: string?)
	k:ellipsoid(
		"Beanie",
		v3(diameter, diameter * 0.75, diameter),
		cframe * CFrame.new(0, diameter * 0.14, 0),
		color,
		Enum.Material.Fabric,
		rig
	)
	k:cylinder(
		"BeanieRim",
		diameter * 0.2,
		diameter * 1.02,
		cframe * CFrame.new(0, 0.02, 0),
		color:Lerp(Color3.new(0, 0, 0), 0.2),
		Enum.Material.Fabric,
		rig
	)
	if pom then
		k:ball(
			"Pom",
			diameter * 0.3,
			(cframe * CFrame.new(0, diameter * 0.52, 0)).Position,
			pom,
			Enum.Material.Fabric,
			rig
		)
	end
end

-- A golden crown with five points and gems, sitting on `cframe`.
function Parts.crown(k: Kit, cframe: CFrame, diameter: number, gem: Color3?, rig: string?)
	local h = diameter * 0.32
	k:cylinder("Crown", h, diameter, cframe * CFrame.new(0, h / 2, 0), C.Gold, Enum.Material.Foil, rig)
	k:cylinder(
		"CrownRim",
		h * 0.25,
		diameter * 1.06,
		cframe * CFrame.new(0, h * 0.1, 0),
		C.GoldDark,
		Enum.Material.Foil,
		rig
	)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		local at = cframe * CFrame.new(math.sin(angle) * diameter * 0.44, h, -math.cos(angle) * diameter * 0.44)
		k:ellipsoid(
			"CrownPoint",
			v3(diameter * 0.2, h * 1.2, diameter * 0.2),
			at * CFrame.new(0, h * 0.35, 0),
			C.Gold,
			Enum.Material.Foil,
			rig
		)
		k:ball("CrownTip", diameter * 0.12, (at * CFrame.new(0, h * 0.95, 0)).Position, C.Gold, Enum.Material.Foil, rig)
	end
	local front = cframe * CFrame.new(0, h * 0.5, -diameter * 0.5)
	k:ellipsoid(
		"CrownGem",
		v3(diameter * 0.2, diameter * 0.2, diameter * 0.1),
		front,
		gem or rgb(230, 40, 70),
		Enum.Material.Neon,
		rig
	)
	for _, side in { -1, 1 } do
		local at = cframe * CFrame.Angles(0, math.rad(40 * side), 0) * CFrame.new(0, h * 0.5, -diameter * 0.5)
		k:ellipsoid(
			"CrownGem",
			v3(diameter * 0.13, diameter * 0.13, diameter * 0.08),
			at,
			rgb(60, 170, 255),
			Enum.Material.Neon,
			rig
		)
	end
end

-- Rounded sunglasses on a face.
function Parts.sunglasses(
	k: Kit,
	shell: Kit.Shell,
	yaw: number,
	pitch: number,
	lensW: number,
	frame: Color3?,
	lens: Color3?,
	rig: string?
)
	for _, side in { -1, 1 } do
		local at = Kit.on(shell, yaw * side, pitch, 0.08)
		k:ellipsoid("Shades", v3(lensW, lensW * 0.7, 0.16), at, lens or rgb(25, 25, 35), Enum.Material.Glass, rig)
		k:ball(
			"ShadesShine",
			lensW * 0.18,
			(at * CFrame.new(-lensW * 0.2 * side, lensW * 0.12, -0.08)).Position,
			rgb(200, 220, 255),
			nil,
			rig
		)
	end
	local bridge = Kit.on(shell, 0, pitch + 2, 0.08)
	k:part("ShadesBridge", v3(lensW * 0.6, 0.1, 0.1), bridge, frame or rgb(25, 25, 35), Enum.Material.Metal, rig)
end

-- A gold chain hanging around a body at height y, with a medallion.
function Parts.goldChain(k: Kit, shell: Kit.Shell, y: number, medallion: string?, rig: string?)
	k:band("GoldChain", shell, y, 0.16, C.Gold, Enum.Material.Foil, rig)
	local at =
		Kit.on(shell, 0, math.deg(math.asin(math.clamp((y - 0.35 - shell.center.Y) / shell.radii.Y, -1, 1))), 0.06)
	k:disc("Medallion", 0.55, 0.12, at, C.Gold, Enum.Material.Foil, rig)
	if medallion then
		k:ellipsoid(
			"MedallionGem",
			v3(0.24, 0.24, 0.1),
			at * CFrame.new(0, 0, -0.07),
			rgb(40, 200, 120),
			Enum.Material.Neon,
			rig
		)
	end
end

-- A cape hanging from `top` (the neck, at the back), made of a draped sheet and a fur trim.
function Parts.cape(k: Kit, top: Vector3, width: number, length: number, color: Color3, trim: Color3?, rig: string?)
	local sheet = CFrame.new(top + v3(0, -length / 2, 0.25)) * CFrame.Angles(math.rad(-10), 0, 0)
	k:ellipsoid("Cape", v3(width, length, 0.35), sheet, color, Enum.Material.Fabric, rig)
	k:part(
		"CapeHem",
		v3(width * 0.72, 0.18, 0.3),
		sheet * CFrame.new(0, -length * 0.44, 0.02),
		color:Lerp(Color3.new(0, 0, 0), 0.25),
		Enum.Material.Fabric,
		rig
	)
	if trim then
		k:ellipsoid(
			"CapeTrim",
			v3(width * 0.85, 0.6, 1.1),
			CFrame.new(top + v3(0, 0.05, 0.1)),
			trim,
			Enum.Material.Fabric,
			rig
		)
		for i = -2, 2 do
			k:ball("TrimSpot", 0.12, top + v3(i * width * 0.14, 0.12, -0.42), rgb(30, 30, 30), nil, rig)
		end
	end
end

-- A smooth glowing halo ring, optionally tilted (degrees around Z).
function Parts.halo(k: Kit, center: Vector3, radius: number, color: Color3?, tilt: number?, rig: string?)
	local glow = color or rgb(255, 235, 130)
	local frame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(tilt or 0))
	local segments = 14
	local first: Part? = nil
	for i = 0, segments - 1 do
		local a0, a1 = i * math.pi * 2 / segments, (i + 1) * math.pi * 2 / segments
		local p0 = (frame * CFrame.new(math.cos(a0) * radius, 0, math.sin(a0) * radius)).Position
		local p1 = (frame * CFrame.new(math.cos(a1) * radius, 0, math.sin(a1) * radius)).Position
		local part = k:limb("Halo", p0, p1, radius * 0.24, glow, Enum.Material.Neon, rig or "Spin")
		first = first or part
	end
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 10
	light.Brightness = 1.2
	light.Parent = first
end

-- A feathered wing from `root`, spreading to one side: an arched wing arm with five long feathers
-- hanging from it, longer and brighter toward the tip.
function Parts.wing(k: Kit, root: Vector3, side: number, span: number, color: Color3, tip: Color3?, rig: string?)
	local rigName = rig or (if side > 0 then "WingR" else "WingL")
	local tipColor = tip or color
	local flat = span * 0.13
	local elbow = root + v3(side * span * 0.5, span * 0.42, span * 0.12)
	local wrist = root + v3(side * span * 0.95, span * 0.3, span * 0.2)
	for _, segment in { { from = root, to = elbow, d = span * 0.34 }, { from = elbow, to = wrist, d = span * 0.26 } } do
		local part = k:limb("WingArm", segment.from, segment.to, segment.d, color, nil, rigName)
		part.Size = v3(part.Size.X, part.Size.Y, flat)
	end
	for i = 0, 4 do
		local t = i / 4
		local anchor = if t < 0.5 then root:Lerp(elbow, 0.35 + t * 1.3) else elbow:Lerp(wrist, (t - 0.5) * 2)
		local dir = v3(side * (0.15 + t * 0.7), -1, 0.05).Unit
		local feather = k:limb(
			"Feather",
			anchor,
			anchor + dir * span * (0.5 + t * 0.4),
			span * 0.24,
			color:Lerp(tipColor, t),
			nil,
			rigName
		)
		feather.Size = v3(feather.Size.X, feather.Size.Y, flat * 0.8)
	end
	k.model:SetAttribute(rigName .. "Joint", root)
end

-- A tapered horn from `base` along `dir`.
function Parts.horn(k: Kit, base: Vector3, dir: Vector3, length: number, diameter: number, color: Color3, rig: string?)
	local mid = base + dir.Unit * length * 0.5
	local tip = base + dir.Unit * length
	k:limb("Horn", base, mid, diameter, color, nil, rig)
	k:limb("HornTip", mid, tip, diameter * 0.55, color, nil, rig)
end

-- A metal handcuff ring around a wrist.
function Parts.cuff(k: Kit, wrist: Vector3, diameter: number, rig: string?)
	k:cylinder("Handcuff", diameter * 0.4, diameter * 1.3, CFrame.new(wrist), C.Iron, Enum.Material.Metal, rig)
end

-- A patch of color hugging a shell (spots, nebulae, pockets). It is made deep enough to follow the
-- curve, so wide patches don't float off the body at their edges.
function Parts.patch(
	k: Kit,
	name: string,
	shell: Kit.Shell,
	yaw: number,
	pitch: number,
	w: number,
	h: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?,
	spin: number?
): Part
	local r = math.min(shell.radii.X, shell.radii.Y, shell.radii.Z)
	-- A little flatter than the body's curve, so the edges stay just above the surface
	local depth = math.max(0.12, 0.6 * math.max(w, h) ^ 2 / (2 * r))
	return k:ellipsoid(name, v3(w, h, depth), Kit.on(shell, yaw, pitch, 0.06 - depth / 2, spin), color, material, rig)
end

-- Tiny glowing stars spread evenly over a shell (a Fibonacci spiral, so every copy looks the same).
-- Stars inside the face area (|yaw| < 50, pitch -30..45) are skipped.
function Parts.starSpecks(
	k: Kit,
	shell: Kit.Shell,
	count: number,
	colors: { Color3 },
	minPitch: number,
	maxPitch: number,
	rig: string?
)
	local lo, hi = math.sin(math.rad(minPitch)), math.sin(math.rad(maxPitch))
	for i = 1, count do
		local yaw = ((i * 137.508) % 360) - 180
		local pitch = math.deg(math.asin(lo + (hi - lo) * (i - 0.5) / count))
		if not (math.abs(yaw) < 50 and pitch > -30 and pitch < 45) then
			local size = 0.09 + (i * 7 % 5) * 0.025
			k:ball("Star", size, Kit.surface(shell, yaw, pitch), colors[i % #colors + 1], Enum.Material.Neon, rig)
		end
	end
end

-- A graduation cap (mortarboard) sitting on `cframe`, with a gold tassel hanging off one corner.
function Parts.gradCap(k: Kit, cframe: CFrame, size: number, rig: string?)
	local black = rgb(25, 25, 32)
	k:cylinder(
		"CapBase",
		size * 0.24,
		size * 0.68,
		cframe * CFrame.new(0, size * 0.12, 0),
		black,
		Enum.Material.Fabric,
		rig
	)
	local board = cframe * CFrame.new(0, size * 0.26, 0) * CFrame.Angles(0, math.rad(45), 0)
	k:part("CapBoard", v3(size, size * 0.06, size), board, black, Enum.Material.Fabric, rig)
	local button = (board * CFrame.new(0, size * 0.04, 0)).Position
	k:ball("CapButton", size * 0.1, button, C.Gold, Enum.Material.Foil, rig)
	local corner = (board * CFrame.new(size * 0.47, size * 0.03, -size * 0.47)).Position
	k:limb("TasselCord", button, corner, size * 0.035, C.Gold, nil, rig)
	k:limb("Tassel", corner, corner - v3(0, size * 0.42, 0), size * 0.09, C.Gold, nil, rig)
end

-- A ground glow ring (used for rare Brainrots).
function Parts.glowRing(k: Kit, radius: number, color: Color3)
	local ring = k:cylinder("GlowRing", 0.06, radius * 2, CFrame.new(0, 0.04, 0), color, Enum.Material.Neon)
	ring.Transparency = 0.55
	ring.CastShadow = false
	return ring
end

return Parts
