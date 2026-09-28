-- Architecture: floors, painted walls with openings, pillars, roofs with beams and skylights.
-- Walls follow the prison's art direction: cream plaster above a teal painted band, a yellow stripe
-- where they meet, a dark baseboard, a cornice at the top and charcoal pilasters at a steady
-- rhythm, so long walls never read as flat slabs.

local Palette = require(script.Parent.Palette)
local Shapes = require(script.Parent.Shapes)

local Structure = {}

local M = Enum.Material
local v3 = Vector3.new

export type WallStyle = {
	wall: Color3,
	paint: Color3,
	-- Painted band height (0 for none).
	paintHeight: number?,
	material: Enum.Material?,
	thickness: number?,
	-- Which faces get the paint band: 1 = the +normal side, -1 = the -normal side, 0 = both.
	paintSide: number?,
	-- The painted stripe above the band (default Palette.Stripe; false for none).
	stripe: (Color3 | boolean)?,
	-- Distance between pilasters (default 16; 0 for none) and their color.
	pilasterEvery: number?,
	pilaster: Color3?,
	-- Material of the painted band (default SmoothPlastic; Brick for an outdoor plinth).
	paintMaterial: Enum.Material?,
}

export type Opening = {
	-- Distance along the wall from its start to the opening's center.
	at: number,
	width: number,
	height: number,
	-- A window instead of a doorway: bottom of the opening above the floor.
	sill: number?,
}

function Structure.floor(
	parent: Instance,
	name: string,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y: number,
	color: Color3,
	material: Enum.Material?
): Part
	local s = Shapes.new(parent)
	return s:box(
		name,
		v3(math.abs(x2 - x1), 1, math.abs(z2 - z1)),
		CFrame.new((x1 + x2) / 2, y - 0.5, (z1 + z2) / 2),
		color,
		material or M.Concrete
	)
end

-- A painted line or patch on the floor.
function Structure.floorMark(
	parent: Instance,
	name: string,
	cframe: CFrame,
	size: Vector2,
	color: Color3,
	y: number
): Part
	local s = Shapes.new(parent)
	local part = s:deco(
		name,
		v3(size.X, 0.06, size.Y),
		CFrame.new(cframe.Position.X, y + 0.03, cframe.Position.Z) * cframe.Rotation,
		color,
		M.SmoothPlastic
	)
	part.CastShadow = false
	return part
end

-- One solid wall piece plus its trims, spanning `length` along the local X of `frame`.
local function segment(
	s: Shapes.Shapes,
	frame: CFrame,
	from: number,
	to: number,
	bottom: number,
	top: number,
	height: number,
	style: WallStyle
)
	local length = to - from
	if length <= 0.05 or top - bottom <= 0.05 then
		return
	end
	local thickness = style.thickness or 2
	local x = (from + to) / 2
	s:box(
		"Wall",
		v3(length, top - bottom, thickness),
		frame * CFrame.new(x, (bottom + top) / 2, 0),
		style.wall,
		style.material or M.Plaster
	)
	local paintHeight = style.paintHeight or 7
	local side = style.paintSide or 0
	local stripe: Color3? = if style.stripe == false
		then nil
		elseif typeof(style.stripe) == "Color3" then style.stripe
		else Palette.Stripe
	for _, face in { -1, 1 } do
		if side == 0 or side == face then
			local z = face * (thickness / 2 + 0.03)
			if paintHeight > 0 and bottom < paintHeight then
				local paintTop = math.min(paintHeight, top)
				s:deco(
					"WallPaint",
					v3(length, paintTop - bottom, 0.06),
					frame * CFrame.new(x, (bottom + paintTop) / 2, z),
					style.paint,
					style.paintMaterial or M.SmoothPlastic
				)
				if top > paintHeight then
					-- A painted stripe where the band ends, or a steel rail if the wall has no stripe
					if stripe then
						s:deco(
							"WallStripe",
							v3(length, 0.5, 0.08),
							frame * CFrame.new(x, paintHeight + 0.2, face * (thickness / 2 + 0.05)),
							stripe,
							M.SmoothPlastic
						).CastShadow =
							false
					else
						s:deco(
							"ChairRail",
							v3(length, 0.3, 0.14),
							frame * CFrame.new(x, paintHeight, face * (thickness / 2 + 0.07)),
							Palette.Frame,
							M.Metal
						)
					end
				end
			end
			if bottom <= 0.01 then
				s:deco(
					"Baseboard",
					v3(length, 0.7, 0.14),
					frame * CFrame.new(x, 0.35, face * (thickness / 2 + 0.07)),
					Palette.Frame,
					M.SmoothPlastic
				)
			end
		end
	end
	if top >= height - 0.01 then
		s:deco(
			"WallCap",
			v3(length, 0.9, thickness + 0.5),
			frame * CFrame.new(x, height - 0.45, 0),
			Palette.Frame,
			M.Concrete
		)
		-- Pilasters on full-height stretches, kept clear of doorways
		local every = style.pilasterEvery or 16
		if every > 0 and bottom <= 0.01 then
			local first = math.ceil((from + 1.5) / every) * every
			for at = first, to - 1.5, every do
				for _, face in { -1, 1 } do
					if side == 0 or side == face then
						local z = face * (thickness / 2 + 0.3)
						s:deco(
							"Pilaster",
							v3(1.6, height - 0.9, 0.6),
							frame * CFrame.new(at, (height - 0.9) / 2, z),
							style.pilaster or Palette.Frame,
							M.Concrete
						)
					end
				end
			end
		end
	end
end

-- A wall from `a` to `b` (x, z points on the floor at height `y`), `height` tall, with openings.
-- Doorways get a steel frame; windows get a sill, a frame and bars.
function Structure.wall(
	parent: Instance,
	a: Vector2,
	b: Vector2,
	y: number,
	height: number,
	style: WallStyle,
	openings: { Opening }?
)
	local direction = (b - a)
	local length = direction.Magnitude
	local angle = math.atan2(-direction.Y, direction.X)
	local frame = CFrame.new(a.X, y, a.Y) * CFrame.Angles(0, angle, 0)
	local s = Shapes.new(parent)
	local list: { Opening } = table.clone(openings or {})
	table.sort(list, function(p: Opening, q: Opening)
		return p.at < q.at
	end)
	local cursor = 0
	for _, opening in list do
		local left, right = opening.at - opening.width / 2, opening.at + opening.width / 2
		segment(s, frame, cursor, left, 0, height, height, style)
		local sill = opening.sill or 0
		segment(s, frame, left, right, 0, sill, height, style)
		segment(s, frame, left, right, sill + opening.height, height, height, style)
		Structure.frame(
			s,
			frame * CFrame.new(opening.at, 0, 0),
			opening.width,
			opening.height,
			sill,
			style.thickness or 2
		)
		cursor = right
	end
	segment(s, frame, cursor, length, 0, height, height, style)
end

-- Steel frame around an opening (a doorway when sill = 0, a window otherwise). Local X runs along the wall.
function Structure.frame(
	s: Shapes.Shapes,
	center: CFrame,
	width: number,
	height: number,
	sill: number,
	thickness: number
)
	local depth = thickness + 0.4
	for _, side in { -1, 1 } do
		s:deco(
			"Jamb",
			v3(0.6, height, depth),
			center * CFrame.new(side * (width / 2 - 0.3), sill + height / 2, 0),
			Palette.Frame,
			M.Metal
		)
	end
	s:deco("Header", v3(width, 0.6, depth), center * CFrame.new(0, sill + height - 0.3, 0), Palette.Frame, M.Metal)
	if sill > 0 then
		s:deco("Sill", v3(width + 0.4, 0.4, depth + 0.3), center * CFrame.new(0, sill + 0.2, 0), Palette.Frame, M.Metal)
	end
end

-- A fake window: the opening shows a bright sky panel behind bars, so interiors feel lit by day.
function Structure.window(s: Shapes.Shapes, center: CFrame, width: number, height: number, sill: number, sky: Color3?)
	local panel = s:glow(
		"WindowSky",
		v3(width - 0.6, height - 0.6, 0.1),
		center * CFrame.new(0, sill + height / 2, 0.4),
		sky or Color3.fromRGB(200, 228, 255)
	)
	panel.Transparency = 0.1
	local bars = math.max(2, math.floor(width / 1.2))
	for i = 1, bars - 1 do
		local x = -width / 2 + i * width / bars
		s:cyl(
			"WindowBar",
			height - 0.6,
			0.22,
			center * CFrame.new(x, sill + height / 2, 0),
			Palette.Bars,
			M.Metal,
			false
		)
	end
end

function Structure.pillar(parent: Instance, position: Vector3, width: number, height: number, color: Color3)
	local s = Shapes.new(parent, CFrame.new(position))
	s:box("Pillar", v3(width, height, width), CFrame.new(0, height / 2, 0), color, M.Plaster)
	s:deco("PillarBase", v3(width + 0.6, 1.4, width + 0.6), CFrame.new(0, 0.7, 0), Palette.Frame, M.Concrete)
	s:deco("PillarBand", v3(width + 0.2, 0.5, width + 0.2), CFrame.new(0, 7.4, 0), Palette.Stripe, M.SmoothPlastic)
	s:deco("PillarCap", v3(width + 0.8, 1, width + 0.8), CFrame.new(0, height - 0.5, 0), Palette.Frame, M.Concrete)
end

export type RoofOptions = {
	-- Space between steel beams under the ceiling (0 for none).
	beamEvery: number?,
	-- Skylights: rectangles { x1, x2, z1, z2 } left open with glass.
	skylights: { { number } }?,
	ceiling: Color3?,
}

-- Roof slab at `y` covering x1..x2, z1..z2. Parts are named "Roof…" so previews can hide them.
function Structure.roof(
	parent: Instance,
	x1: number,
	x2: number,
	z1: number,
	z2: number,
	y: number,
	options: RoofOptions?
)
	local opts: RoofOptions = options or {}
	local s = Shapes.new(parent)
	local ceiling = opts.ceiling or Palette.Roof
	local holes: { { number } } = opts.skylights or {}
	-- Build the slab as strips along Z between skylight columns, so openings stay open.
	local xs = { x1, x2 }
	for _, hole in holes do
		table.insert(xs, hole[1])
		table.insert(xs, hole[2])
	end
	table.sort(xs)
	for i = 1, #xs - 1 do
		local a, b = xs[i], xs[i + 1]
		if b - a > 0.01 then
			local cuts = {}
			for _, hole in holes do
				if hole[1] <= a + 0.01 and hole[2] >= b - 0.01 then
					table.insert(cuts, { hole[3], hole[4] })
				end
			end
			table.sort(cuts, function(p, q)
				return p[1] < q[1]
			end)
			local cursor = z1
			local function strip(from: number, to: number)
				if to - from > 0.01 then
					local part = s:box(
						"Roof",
						v3(b - a, 1.2, to - from),
						CFrame.new((a + b) / 2, y + 0.6, (from + to) / 2),
						ceiling,
						M.Concrete
					)
					part.CastShadow = true
				end
			end
			for _, cut in cuts do
				strip(cursor, cut[1])
				cursor = cut[2]
			end
			strip(cursor, z2)
		end
	end
	for _, hole in holes do
		local glass = s:deco(
			"RoofSkylight",
			v3(hole[2] - hole[1], 0.2, hole[4] - hole[3]),
			CFrame.new((hole[1] + hole[2]) / 2, y + 1.1, (hole[3] + hole[4]) / 2),
			Palette.Glass,
			M.Glass
		)
		glass.Transparency = 0.6
		glass.CastShadow = false
		local frames = math.max(1, math.floor((hole[4] - hole[3]) / 6))
		for i = 0, frames do
			local z = hole[3] + i * (hole[4] - hole[3]) / frames
			s:deco(
				"RoofSkylightFrame",
				v3(hole[2] - hole[1], 0.5, 0.4),
				CFrame.new((hole[1] + hole[2]) / 2, y + 1, z),
				Palette.Frame,
				M.Metal
			)
		end
	end
	-- A dark parapet around the roof edge so the building reads well from the yard
	local parapet = ceiling:Lerp(Palette.Ink, 0.35)
	for _, z in { z1 + 0.4, z2 - 0.4 } do
		s:deco("RoofParapet", v3(x2 - x1, 1.4, 0.8), CFrame.new((x1 + x2) / 2, y + 1.9, z), parapet, M.Concrete)
	end
	for _, x in { x1 + 0.4, x2 - 0.4 } do
		s:deco("RoofParapet", v3(0.8, 1.4, z2 - z1), CFrame.new(x, y + 1.9, (z1 + z2) / 2), parapet, M.Concrete)
	end
	local every = opts.beamEvery or 0
	if every > 0 then
		local count = math.floor((z2 - z1) / every)
		for i = 1, count - 1 do
			local z = z1 + i * (z2 - z1) / count
			local beam =
				s:deco("RoofBeam", v3(x2 - x1, 1.4, 0.8), CFrame.new((x1 + x2) / 2, y - 0.7, z), Palette.Frame, M.Metal)
			beam:SetAttribute("Roof", true)
		end
	end
end

return Structure
