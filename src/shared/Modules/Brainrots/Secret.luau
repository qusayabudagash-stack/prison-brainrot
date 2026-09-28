-- SECRET Brainrot: the rarest thing in the prison. The biggest and most elaborate build, a whole
-- little planet with its own moons.

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)

type Kit = Kit.Kit

local rgb = Color3.fromRGB
local v3 = Vector3.new

local Secret: { [string]: (Kit) -> BasePart } = {}

---------------------------------------------------------------------------
-- La Vaca Saturno Saturnita: a cow whose body is the planet Saturn
---------------------------------------------------------------------------

Secret.LaVacaSaturnoSaturnita = function(k: Kit): BasePart
	local PLANET = rgb(244, 222, 170)
	local BANDS = { rgb(226, 176, 104), rgb(206, 146, 84), rgb(236, 200, 136) }
	local RING = rgb(236, 212, 158)
	local RING_DARK = rgb(196, 160, 104)
	local COW = rgb(252, 250, 246)
	local SPOT = rgb(40, 38, 44)
	local SNOUT = rgb(255, 176, 186)
	local HOOF = rgb(70, 60, 64)

	-- Four cow legs under the planet
	for _, x in { -0.8, 0.8 } do
		for _, z in { -0.55, 0.65 } do
			k:limb("Leg", v3(x, 2.0, z), v3(x * 1.05, 0.4, z), 0.5, COW, nil, "Legs")
			k:oval("Hoof", CFrame.new(x * 1.05, 0.16, z), 0.56, 0.56, 0.32, HOOF, nil, "Legs")
			if x < 0 and z < 0 then
				Parts.patch(
					k,
					"LegSpot",
					{ center = v3(x * 1.02, 1.2, z), radii = v3(0.25, 0.8, 0.25) },
					30,
					10,
					0.3,
					0.4,
					SPOT,
					nil,
					"Legs"
				)
			end
		end
	end

	-- Saturn: a banded planet with a wide tilted ring
	local planet: Kit.Shell = { center = v3(0, 3.35, 0), radii = v3(1.75, 1.7, 1.75) }
	local body = k:ellipsoid("Planet", planet.radii * 2, CFrame.new(planet.center), PLANET, nil, "Body")
	for i, y in { 2.3, 2.85, 3.95, 4.45 } do
		k:band("PlanetBand", planet, y, 0.26 - (i % 2) * 0.06, BANDS[(i - 1) % #BANDS + 1], nil, "Body")
	end
	Parts.patch(k, "Storm", planet, -55, -14, 0.6, 0.36, rgb(214, 130, 80), nil, "Body")
	local ringFrame = CFrame.new(planet.center) * CFrame.Angles(math.rad(-14), 0, math.rad(12))
	-- Each ring segment is long along the ring and overlaps its neighbours, so the band reads as one
	-- continuous ring with an inner darker lane
	local segments = 22
	for i = 0, segments - 1 do
		local angle = i * math.pi * 2 / segments
		local chord = 2 * 2.75 * math.sin(math.pi / segments)
		local at = ringFrame * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -2.75)
		k:ellipsoid("Ring", v3(chord * 1.7, 0.08, 1.0), at, RING, nil, "Body")
		k:ellipsoid("RingInner", v3(chord * 1.5, 0.09, 0.36), at * CFrame.new(0, 0, 0.3), RING_DARK, nil, "Body")
	end

	-- The cow's head on top of the planet: horns, ears, pink snout, spots and a golden bell
	local head: Kit.Shell = { center = v3(0, 5.55, -0.45), radii = v3(0.92, 0.82, 0.86) }
	k:ellipsoid("Head", head.radii * 2, CFrame.new(head.center), COW, nil, "Body")
	Parts.patch(k, "CowSpot", head, 40, 30, 0.7, 0.6, SPOT, nil, "Body")
	Parts.patch(k, "CowSpot", head, -120, 10, 0.8, 0.7, SPOT, nil, "Body")
	local snout: Kit.Shell = { center = v3(0, 5.2, -1.12), radii = v3(0.72, 0.48, 0.42) }
	k:ellipsoid("Snout", snout.radii * 2, CFrame.new(snout.center), SNOUT, nil, "Body")
	for _, side in { -1, 1 } do
		k:ellipsoid("Nostril", v3(0.16, 0.22, 0.1), Kit.on(snout, side * 26, 6, -0.02), rgb(170, 90, 100), nil, "Body")
		Parts.cone(
			k,
			"Horn",
			v3(side * 0.55, 6.15, -0.3),
			v3(side * 1.05, 6.6, -0.2),
			0.16,
			rgb(250, 238, 206),
			nil,
			"Body"
		)
		Parts.leaf(
			k,
			"Ear",
			v3(side * 0.85, 5.8, -0.35),
			v3(side * 1.45, 5.62, -0.5),
			0.48,
			0.12,
			COW,
			v3(0, 0.2, -1).Unit,
			nil,
			"Body"
		)
		k:blush(Kit.on(head, side * 44, -18, 0.02), 0.34, "Body")
	end
	k:eyes(head, 30, 16, { width = 0.4, height = 0.48, iris = rgb(60, 40, 30), lid = 0.15, skin = COW }, "Body")
	k:mouth(
		Kit.on(snout, 0, -30, 0),
		{ width = 0.5, height = 0.16, skin = SNOUT, style = "Smile", radius = 0.5 },
		"Body"
	)
	k:band(
		"Collar",
		{ center = v3(0, 4.8, -0.35), radii = v3(0.72, 1, 0.72) },
		4.8,
		0.16,
		rgb(90, 60, 180),
		Enum.Material.Leather,
		"Body"
	)
	k:ball("Bell", 0.5, v3(0, 4.55, -1.08), rgb(255, 204, 60), Enum.Material.Metal, "Body")
	k:ball("BellClapper", 0.14, v3(0, 4.33, -1.2), rgb(180, 130, 40), Enum.Material.Metal, "Body")

	-- A tail with a tuft, and two little moons in orbit
	Parts.tube(
		k,
		"Tail",
		{ v3(0, 3.0, 1.65), v3(0.3, 2.4, 2.0), v3(0.5, 1.8, 2.0) },
		{ 0.1, 0.08, 0.07 },
		COW,
		nil,
		"Body",
		{ density = 3 }
	)
	k:ellipsoid("TailTuft", v3(0.3, 0.46, 0.3), CFrame.new(0.52, 1.6, 2.0), SPOT, nil, "Body")
	k:ball("Moon", 0.62, v3(-2.9, 5.2, 0.4), rgb(226, 228, 238), nil, "Orbit")
	k:ball("MoonCrater", 0.16, v3(-3.1, 5.3, 0.15), rgb(186, 188, 204), nil, "Orbit")
	k:ball("Moon", 0.42, v3(2.7, 2.2, -1.2), rgb(190, 214, 255), nil, "Orbit")
	for i = 1, 6 do
		local angle = i * 1.1
		k:ball(
			"Star",
			0.14,
			v3(math.cos(angle) * 3.2, 4.6 + math.sin(i * 2.3) * 1.2, math.sin(angle) * 1.6 + 1),
			rgb(255, 236, 150),
			Enum.Material.Neon,
			"Orbit"
		)
	end
	return body
end

return Secret
