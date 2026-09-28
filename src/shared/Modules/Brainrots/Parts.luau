-- Reusable character pieces built on the Kit: limbs, shoes, tubes, fins and leaves, cups, rings,
-- hats and accessories.

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

-- A smooth round tube through `points` with a radius at each point (tails, trunks, necks, fuses).
function Parts.tube(
	k: Kit,
	name: string,
	points: { Vector3 },
	radii: { number },
	color: Color3,
	material: Enum.Material?,
	rig: string?,
	options: Kit.LoftOptions?
): { Part }
	local sections: { Kit.Section } = {}
	for i, point in points do
		table.insert(sections, { at = point, w = radii[i], h = radii[i] })
	end
	return k:loft(name, sections, color, material, rig, options)
end

-- A tapered cone from `base` to `tip` (horns, drills, claws, carrot noses).
function Parts.cone(
	k: Kit,
	name: string,
	base: Vector3,
	tip: Vector3,
	radius: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): { Part }
	return Parts.tube(
		k,
		name,
		{ base, base:Lerp(tip, 0.5), tip },
		{ radius, radius * 0.55, radius * 0.08 },
		color,
		material,
		rig,
		{ density = 0.9, overlap = 6, maxSteps = 2 }
	)
end

-- A flat pointed shape from `base` to `tip`: ears, leaves, feathers, fins, flames. `face` is the
-- direction its flat side faces.
function Parts.leaf(
	k: Kit,
	name: string,
	base: Vector3,
	tip: Vector3,
	width: number,
	thickness: number,
	color: Color3,
	face: Vector3,
	material: Enum.Material?,
	rig: string?
): { Part }
	local axis = (tip - base).Unit
	local chord = face:Cross(axis)
	chord = if chord.Magnitude > 1e-4 then chord.Unit else Vector3.xAxis
	return k:loft(
		name,
		{
			{ at = base, w = thickness / 2, h = width * 0.42 },
			{ at = base:Lerp(tip, 0.45), w = thickness * 0.42, h = width * 0.5 },
			{ at = tip, w = thickness * 0.2, h = width * 0.04 },
		},
		color,
		material,
		rig,
		{
			up = chord,
			density = 0.8,
			overlap = 4,
			minSpacing = math.max(width * 0.22, (tip - base).Magnitude * 0.09),
			maxSteps = 3,
		}
	)
end

-- A ring (torus) of short limbs lying in the XZ plane of `frame`.
function Parts.ring(
	k: Kit,
	name: string,
	frame: CFrame,
	radius: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?,
	segments: number?
): { Part }
	local count = segments or 12
	local parts = {}
	for i = 0, count - 1 do
		local a0, a1 = i * math.pi * 2 / count, (i + 1) * math.pi * 2 / count
		local p0 = (frame * CFrame.new(math.cos(a0) * radius, 0, math.sin(a0) * radius)).Position
		local p1 = (frame * CFrame.new(math.cos(a1) * radius, 0, math.sin(a1) * radius)).Position
		table.insert(parts, k:limb(name, p0, p1, thickness, color, material, rig))
	end
	return parts
end

-- A C-shaped handle from `a` to `b`, bulging `out` (a direction and distance) at its middle.
function Parts.handle(
	k: Kit,
	name: string,
	a: Vector3,
	b: Vector3,
	out: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
)
	local control = (a + b) / 2 + out * 2
	local previous = a
	for i = 1, 5 do
		local t = i / 5
		local point = a * (1 - t) ^ 2 + control * 2 * t * (1 - t) + b * t * t
		k:limb(name, previous, point, thickness, color, material, rig)
		previous = point
	end
end

-- A flat sandal: a sole with a toe strap and an ankle strap. `ankle` as for sneakers.
function Parts.sandal(k: Kit, ankle: Vector3, size: number, sole: Color3, strap: Color3, rig: string?, yaw: number?)
	local base = CFrame.new(ankle.X, 0, ankle.Z)
		* CFrame.Angles(0, math.rad(yaw or 0), 0)
		* CFrame.new(0, 0, -size * 0.2)
	k:oval(
		"SandalSole",
		base * CFrame.new(0, size * 0.07, 0),
		size * 0.9,
		size * 1.5,
		size * 0.14,
		sole,
		Enum.Material.Leather,
		rig
	)
	for _, z in { -0.35, 0.12 } do
		k:ellipsoid(
			"SandalStrap",
			v3(size * 0.86, size * 0.3, size * 0.16),
			base * CFrame.new(0, size * 0.22, size * z),
			strap,
			Enum.Material.Leather,
			rig
		)
	end
end

export type Cup = {
	center: Vector3,
	bottom: number,
	top: number,
	radius: number,
}

export type CupStyle = {
	color: Color3,
	coffee: Color3?,
	foam: Color3?,
	-- Latte art on the foam.
	heart: boolean?,
	rig: string?,
}

-- A coffee cup: straight sides over a rounded bowl, a foot ring, and coffee with foam on top.
-- `base` is the bottom center of the straight part; returns the wall for placing faces with onCup.
function Parts.cup(k: Kit, base: Vector3, height: number, radius: number, style: CupStyle): Cup
	local rig = style.rig or "Body"
	local wall = k:cylinder("Cup", height, radius * 2, CFrame.new(base + v3(0, height / 2, 0)), style.color, nil, rig)
	wall.Reflectance = 0.05
	k:ellipsoid("CupBowl", v3(radius * 2, radius * 1.1, radius * 2), CFrame.new(base), style.color, nil, rig)
	k:oval(
		"CupFoot",
		CFrame.new(base - v3(0, radius * 0.5, 0)),
		radius * 1.1,
		radius * 1.1,
		0.14,
		style.color,
		nil,
		rig
	)
	local top = base.Y + height
	k:oval(
		"Coffee",
		CFrame.new(base.X, top + 0.02, base.Z),
		radius * 2 - 0.16,
		radius * 2 - 0.16,
		0.06,
		style.coffee or rgb(120, 72, 42),
		nil,
		rig
	)
	k:oval(
		"Foam",
		CFrame.new(base.X, top + 0.05, base.Z),
		radius * 1.55,
		radius * 1.55,
		0.06,
		style.foam or rgb(242, 222, 188),
		nil,
		rig
	)
	if style.heart then
		local coffee = style.coffee or rgb(120, 72, 42)
		for _, side in { -1, 1 } do
			k:oval(
				"LatteHeart",
				CFrame.new(base.X + side * radius * 0.16, top + 0.08, base.Z - radius * 0.1),
				radius * 0.38,
				radius * 0.38,
				0.04,
				coffee,
				nil,
				rig
			)
		end
		local tip = k:part(
			"LatteHeart",
			v3(radius * 0.38, 0.04, radius * 0.38),
			CFrame.new(base.X, top + 0.08, base.Z + radius * 0.14) * CFrame.Angles(0, math.rad(45), 0),
			coffee,
			nil,
			rig
		)
		tip.CastShadow = false
	end
	return { center = base + v3(0, height / 2, 0), bottom = base.Y, top = top, radius = radius }
end

-- A CFrame on a cup's wall at `yaw` degrees (0 = front) and height `y`, looking out of the wall.
function Parts.onCup(cup: Cup, yaw: number, y: number, out: number?): CFrame
	local angle = math.rad(yaw)
	local normal = v3(math.sin(angle), 0, -math.cos(angle))
	local point = v3(cup.center.X, y, cup.center.Z) + normal * (cup.radius + (out or 0))
	return CFrame.lookAt(point, point + normal)
end

-- A box with its four edges along X rounded off (a loaf-like profile from the side).
function Parts.roundedBox(
	k: Kit,
	name: string,
	cframe: CFrame,
	size: Vector3,
	radius: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local core = k:part(name, v3(size.X, size.Y - radius * 2, size.Z), cframe, color, material, rig)
	k:part(name, v3(size.X, size.Y, size.Z - radius * 2), cframe, color, material, rig)
	for _, y in { -1, 1 } do
		for _, z in { -1, 1 } do
			k:cylinder(
				name,
				size.X,
				radius * 2,
				cframe
					* CFrame.new(0, y * (size.Y / 2 - radius), z * (size.Z / 2 - radius))
					* CFrame.Angles(0, 0, math.pi / 2),
				color,
				material,
				rig
			)
		end
	end
	return core
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

return Parts
