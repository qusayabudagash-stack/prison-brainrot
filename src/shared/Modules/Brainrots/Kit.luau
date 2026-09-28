-- The character kit: the building blocks every Brainrot design is made from.
--
-- Designs are built facing -Z with the feet on y = 0. Surface features (eyes, mouths, badges...)
-- are placed by angle on an ellipsoid ("yaw" left/right, "pitch" up/down) so they sit correctly on
-- any body shape. Parts can be tagged with a rig group ("Body", "ArmL", "ArmR", "Head", "Spin"...)
-- which the client animator uses to make characters bob, wave and sway.

local Kit = {}
Kit.__index = Kit

export type Kit = typeof(setmetatable({} :: { model: Model, count: number }, Kit))

-- A body shape features can be placed on.
export type Shell = {
	center: Vector3,
	radii: Vector3,
	-- Optional rotation of the shell (a tilted head, a snout pointing up...).
	rotation: CFrame?,
}

-- One cross-section of a lofted body: its center, half-width and half-height.
export type Section = {
	at: Vector3,
	w: number,
	h: number,
}

export type LoftOptions = {
	-- Which way a section's height points (default up). Fins use their chord direction.
	up: Vector3?,
	-- Spacing between the ellipsoids as a fraction of the larger radius (default 0.6).
	density: number?,
	-- How long each ellipsoid is compared with the spacing (default 6). Higher hides the seams
	-- between ellipsoids; lower follows sharp tapers more closely.
	overlap: number?,
	-- Never place ellipsoids closer than this (keeps thin tails cheap).
	minSpacing: number?,
	-- At most this many ellipsoids between two sections (default 12).
	maxSteps: number?,
}

export type EyeOptions = {
	width: number,
	height: number,
	iris: Color3?,
	-- Where the eye looks, -1..1 on each axis.
	look: Vector2?,
	-- 0 = wide open, 1 = closed. The lid is the skin color.
	lid: number?,
	-- Degrees; positive tilts the lid's inner corner down (angry), negative (worried).
	lidTilt: number?,
	skin: Color3?,
	-- "Round" (default), "Happy" (closed ^ arcs), "Dot" (small black bead), "Glow" (neon)
	style: string?,
	glow: Color3?,
	side: number?,
}

export type MouthOptions = {
	width: number,
	height: number,
	skin: Color3,
	-- "Grin", "Smile", "Open", "Smirk", "Frown", "Tongue", "Teeth", "Flat"
	style: string?,
	teeth: boolean?,
	tongue: boolean?,
	buckTooth: boolean?,
	lip: Color3?,
	-- Radius of the surface the mouth sits on; wide mouths bend with it instead of floating off the sides
	radius: number?,
}

local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(30, 22, 30)
local MOUTH = Color3.fromRGB(95, 25, 40)
local TONGUE = Color3.fromRGB(255, 120, 140)
local BLUSH = Color3.fromRGB(255, 140, 150)

Kit.Colors = {
	White = WHITE,
	Ink = INK,
	Mouth = MOUTH,
	Tongue = TONGUE,
	Blush = BLUSH,
	Gold = Color3.fromRGB(255, 196, 45),
	GoldDark = Color3.fromRGB(215, 150, 30),
	Sole = Color3.fromRGB(235, 232, 225),
}

function Kit.new(model: Model): Kit
	return setmetatable({ model = model, count = 0 }, Kit)
end

---------------------------------------------------------------------------
-- Raw shapes
---------------------------------------------------------------------------

function Kit.part(
	self: Kit,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Anchored = true
	part.Massless = true
	if rig then
		part:SetAttribute("Rig", rig)
	end
	part.Parent = self.model
	self.count += 1
	return part
end

-- Ellipsoid that exactly fills `size`.
function Kit.ellipsoid(
	self: Kit,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(name, size, cframe, color, material, rig)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

function Kit.ball(
	self: Kit,
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(name, Vector3.new(diameter, diameter, diameter), CFrame.new(position), color, material, rig)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Cylinder whose axis runs along the CFrame's Y (up) axis.
function Kit.cylinder(
	self: Kit,
	name: string,
	length: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(
		name,
		Vector3.new(length, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		rig
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Flat disc facing along the CFrame's LookVector.
function Kit.disc(
	self: Kit,
	name: string,
	diameter: number,
	thickness: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(
		name,
		Vector3.new(thickness, diameter, diameter),
		cframe * CFrame.Angles(0, math.pi / 2, 0),
		color,
		material,
		rig
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Kit.wedge(
	self: Kit,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(name, size, cframe, color, material, rig)
	part.Shape = Enum.PartType.Wedge
	return part
end

-- A rounded "sausage" between two points: great for arms, legs, necks and tails.
function Kit.limb(
	self: Kit,
	name: string,
	from: Vector3,
	to: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local axis = to - from
	local length = axis.Magnitude
	local up = if length > 1e-4 then axis.Unit else Vector3.yAxis
	local right = if math.abs(up:Dot(Vector3.zAxis)) > 0.99 then Vector3.xAxis else up:Cross(Vector3.zAxis).Unit
	local back = right:Cross(up).Unit
	local cframe = CFrame.fromMatrix((from + to) / 2, right, up, back)
	return self:ellipsoid(name, Vector3.new(diameter, length + diameter * 0.9, diameter), cframe, color, material, rig)
end

---------------------------------------------------------------------------
-- Placing things on a body
---------------------------------------------------------------------------

-- Point and outward normal on an ellipsoid shell. yaw > 0 turns toward the character's right (+X),
-- pitch > 0 goes up. yaw = 0, pitch = 0 is the middle of the front (-Z).
function Kit.surface(shell: Shell, yaw: number, pitch: number): (Vector3, Vector3)
	local y, p = math.rad(yaw), math.rad(pitch)
	local dir = Vector3.new(math.sin(y) * math.cos(p), math.sin(p), -math.cos(y) * math.cos(p))
	local r = shell.radii
	local scaled = Vector3.new(dir.X / r.X, dir.Y / r.Y, dir.Z / r.Z)
	local offset = dir / scaled.Magnitude
	local normal = Vector3.new(offset.X / (r.X * r.X), offset.Y / (r.Y * r.Y), offset.Z / (r.Z * r.Z)).Unit
	local rotation = shell.rotation
	if rotation then
		return shell.center + rotation:VectorToWorldSpace(offset), rotation:VectorToWorldSpace(normal)
	end
	return shell.center + offset, normal
end

-- CFrame on the surface: LookVector points out of the body, UpVector roughly up. `out` pushes it
-- further out (or in, if negative); `spin` rolls it around the normal in degrees.
function Kit.on(shell: Shell, yaw: number, pitch: number, out: number?, spin: number?): CFrame
	local point, normal = Kit.surface(shell, yaw, pitch)
	local position = point + normal * (out or 0)
	local up = if math.abs(normal.Y) > 0.98 then Vector3.zAxis else Vector3.yAxis
	local cframe = CFrame.lookAt(position, position + normal, up)
	if spin and spin ~= 0 then
		cframe *= CFrame.Angles(0, 0, math.rad(spin))
	end
	return cframe
end

-- Horizontal half-widths of a shell at height y (for belts, collars and stripes).
function Kit.widthAt(shell: Shell, y: number): (number, number)
	local t = 1 - ((y - shell.center.Y) / shell.radii.Y) ^ 2
	local k = math.sqrt(math.max(t, 0))
	return shell.radii.X * k, shell.radii.Z * k
end

-- A flat-topped oval slab standing on `cframe` (soles, bases, lids, coins): an elliptical cylinder
-- `width` across X, `depth` along Z and `height` tall, centered on `cframe`.
function Kit.oval(
	self: Kit,
	name: string,
	cframe: CFrame,
	width: number,
	depth: number,
	height: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local part = self:part(
		name,
		Vector3.new(height, width, depth),
		cframe * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		rig
	)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = part
	return part
end

-- A band of even thickness hugging a shell at height y: collars, belts, stripes, masks.
-- The cylinder is a stretched SpecialMesh, so it follows oval bodies instead of poking out of them.
function Kit.band(
	self: Kit,
	name: string,
	shell: Shell,
	y: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	rig: string?
): Part
	local rx, rz = Kit.widthAt(shell, y)
	local cframe = CFrame.new(shell.center.X, y, shell.center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	local part = self:part(name, Vector3.new(thickness, rx * 2 + 0.1, rz * 2 + 0.1), cframe, color, material, rig)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = part
	return part
end

---------------------------------------------------------------------------
-- Smooth bodies
---------------------------------------------------------------------------

local function spline(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

local function splineNumber(a: number, b: number, c: number, d: number, t: number): number
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * b) + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (3 * b - a - 3 * c + d) * t3)
end

-- A smooth tapered body through a list of sections (a shark, a tail, a trunk, a fin). The path is a
-- Catmull-Rom curve, and overlapping ellipsoids are laid along it, so the outline has no steps.
function Kit.loft(
	self: Kit,
	name: string,
	sections: { Section },
	color: Color3,
	material: Enum.Material?,
	rig: string?,
	options: LoftOptions?
): { Part }
	local opts: LoftOptions = options or {}
	local density = opts.density or 0.6
	local overlap = opts.overlap or 6
	local minSpacing = opts.minSpacing or 0.12
	local upHint = opts.up or Vector3.yAxis
	local count = #sections
	local samples: { Section } = {}
	for i = 1, count - 1 do
		local a, b = sections[i], sections[i + 1]
		local before, after = sections[math.max(i - 1, 1)], sections[math.min(i + 2, count)]
		local length = (b.at - a.at).Magnitude
		-- Spacing follows the section's larger radius: that is the outline people see (a fin's
		-- chord, not its thickness)
		local radius = (math.max(a.w, a.h) + math.max(b.w, b.h)) / 2
		local steps = math.clamp(math.ceil(length / math.max(radius * density, minSpacing)), 1, opts.maxSteps or 12)
		for step = 0, steps - 1 do
			local t = step / steps
			table.insert(samples, {
				at = spline(before.at, a.at, b.at, after.at, t),
				w = math.max(splineNumber(before.w, a.w, b.w, after.w, t), 0.02),
				h = math.max(splineNumber(before.h, a.h, b.h, after.h, t), 0.02),
			})
		end
	end
	table.insert(samples, sections[count])

	-- Distance of every sample along the path, so ellipsoids near the ends are kept short enough to
	-- stop at the first and last sections (rounded caps instead of long overhangs).
	local along = { 0 }
	for i = 2, #samples do
		along[i] = along[i - 1] + (samples[i].at - samples[i - 1].at).Magnitude
	end
	local total = along[#samples]

	local parts = {}
	for i, sample in samples do
		local prev = samples[math.max(i - 1, 1)].at
		local nextAt = samples[math.min(i + 1, #samples)].at
		local span = nextAt - prev
		local tangent = if span.Magnitude > 1e-4 then span.Unit else Vector3.zAxis
		local intervals = math.min(i + 1, #samples) - math.max(i - 1, 1)
		local spacing = span.Magnitude / math.max(intervals, 1)
		local up = upHint - tangent * upHint:Dot(tangent)
		up = if up.Magnitude > 1e-4 then up.Unit else Vector3.xAxis:Cross(tangent).Unit
		local right = up:Cross(tangent)
		local cframe = CFrame.fromMatrix(sample.at, right, up)
		local cap = math.min(sample.w, sample.h) * 1.8
		local room = 2 * math.min(along[i], total - along[i]) + cap
		local length = math.max(math.min(spacing * overlap, room), cap)
		-- On a bend, a long straight ellipsoid would stick out of the curve: keep its sag within
		-- about a third of the radius (sag = length^2 / 8R)
		if i > 1 and i < #samples then
			local a = (sample.at - samples[i - 1].at).Unit
			local b = (samples[i + 1].at - sample.at).Unit
			local bend = math.acos(math.clamp(a:Dot(b), -1, 1))
			if bend > 1e-3 then
				local bendRadius = spacing / bend
				local limit = math.sqrt(2.4 * math.max(sample.w, sample.h) * bendRadius)
				length = math.max(math.min(length, limit), spacing * 1.6, cap)
			end
		end
		table.insert(
			parts,
			self:ellipsoid(name, Vector3.new(sample.w * 2, sample.h * 2, length), cframe, color, material, rig)
		)
	end
	return parts
end

-- A pointed tooth: a thin wedge whose flat top sits at `cframe` (LookVector out of the mouth) and
-- whose point hangs `length` below it (or above it, with a negative length).
function Kit.tooth(self: Kit, cframe: CFrame, width: number, length: number, color: Color3?, rig: string?): Part
	local down = if length >= 0 then -cframe.UpVector else cframe.UpVector
	local h = math.abs(length)
	local out = cframe.LookVector
	local frame = CFrame.fromMatrix(cframe.Position + down * (h / 2), out, down)
	local part = self:part("Tooth", Vector3.new(0.06, h, width), frame, color or WHITE, nil, rig)
	part.Shape = Enum.PartType.Wedge
	return part
end

-- Turns everything built so far around the vertical axis (for a three-quarter display pose), along
-- with the joints the animator swings things around.
function Kit.turn(self: Kit, degrees: number)
	local rotation = CFrame.Angles(0, math.rad(degrees), 0)
	for _, descendant in self.model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "Root" then
			descendant.CFrame = rotation * descendant.CFrame
		end
	end
	for key, value in self.model:GetAttributes() do
		if typeof(value) == "Vector3" then
			self.model:SetAttribute(key, rotation * value)
		end
	end
end

---------------------------------------------------------------------------
-- Faces
---------------------------------------------------------------------------

-- An eye at `cframe` (LookVector out of the face). Built from sclera, iris, pupil, two highlights,
-- and an optional skin-colored lid for sleepy, sly or angry looks.
function Kit.eye(self: Kit, cframe: CFrame, opts: EyeOptions, rig: string?)
	local w, h = opts.width, opts.height
	local depth = math.min(w, h) * 0.55
	local style = opts.style or "Round"
	local side = opts.side or 1

	if style == "Dot" then
		self:ellipsoid(
			"Pupil",
			Vector3.new(w * 0.55, h * 0.7, depth * 0.6),
			cframe * CFrame.new(0, 0, -depth * 0.12),
			INK,
			nil,
			rig
		)
		self:ball(
			"Highlight",
			w * 0.18,
			(cframe * CFrame.new(-w * 0.1, h * 0.14, -depth * 0.38)).Position,
			WHITE,
			nil,
			rig
		)
		return
	end
	if style == "Happy" then
		-- A closed, smiling ^ eye: dark arc with a skin cap covering its lower half.
		local skin = opts.skin or WHITE
		self:ellipsoid(
			"EyeArc",
			Vector3.new(w, h * 0.55, depth * 0.5),
			cframe * CFrame.new(0, 0, -depth * 0.05),
			INK,
			nil,
			rig
		)
		self:ellipsoid(
			"EyeArcCap",
			Vector3.new(w * 1.05, h * 0.5, depth * 0.56),
			cframe * CFrame.new(0, -h * 0.13, -depth * 0.06),
			skin,
			nil,
			rig
		)
		return
	end
	if style == "Glow" then
		local glow = opts.glow or Color3.fromRGB(190, 120, 255)
		local eye = self:ellipsoid(
			"GlowEye",
			Vector3.new(w, h, depth),
			cframe * CFrame.new(0, 0, -depth * 0.15),
			glow,
			Enum.Material.Neon,
			rig
		)
		local light = Instance.new("PointLight")
		light.Color = glow
		light.Range = 7
		light.Brightness = 1.5
		light.Parent = eye
		return
	end

	self:ellipsoid("Sclera", Vector3.new(w, h, depth), cframe * CFrame.new(0, 0, -depth * 0.1), WHITE, nil, rig)
	local look = opts.look or Vector2.new(0, 0)
	local irisSize = math.min(w, h) * 0.66
	local frontZ = -depth * 0.1 - depth * 0.5
	local lookOffset = CFrame.new(look.X * w * 0.16 * side, look.Y * h * 0.16, frontZ + depth * 0.12)
	local irisColor = opts.iris or Color3.fromRGB(60, 45, 40)
	self:ellipsoid(
		"Iris",
		Vector3.new(irisSize, irisSize * 1.08, depth * 0.3),
		cframe * lookOffset,
		irisColor,
		nil,
		rig
	)
	self:ellipsoid(
		"Pupil",
		Vector3.new(irisSize * 0.55, irisSize * 0.6, depth * 0.3),
		cframe * lookOffset * CFrame.new(0, 0, -depth * 0.05),
		INK,
		nil,
		rig
	)
	self:ball(
		"Highlight",
		irisSize * 0.3,
		(cframe * lookOffset * CFrame.new(-irisSize * 0.2 * side, irisSize * 0.22, -depth * 0.12)).Position,
		WHITE,
		nil,
		rig
	)
	self:ball(
		"Highlight2",
		irisSize * 0.14,
		(cframe * lookOffset * CFrame.new(irisSize * 0.18 * side, -irisSize * 0.18, -depth * 0.1)).Position,
		WHITE,
		nil,
		rig
	)

	local lid = opts.lid or 0
	if lid > 0 then
		-- A cap centered on the eye's top edge: it covers `lid` of the eye and barely rises above it.
		local tilt = math.rad((opts.lidTilt or 0) * side)
		local lidHeight = 2 * lid * h * 1.05
		self:ellipsoid(
			"Eyelid",
			Vector3.new(w * 1.1, lidHeight, depth * 1.12),
			cframe * CFrame.Angles(0, 0, tilt) * CFrame.new(0, h * 0.5, -depth * 0.1),
			opts.skin or WHITE,
			nil,
			rig
		)
	end
end

function Kit.brow(self: Kit, cframe: CFrame, width: number, angle: number, color: Color3?, rig: string?): Part
	return self:ellipsoid(
		"Brow",
		Vector3.new(width, width * 0.32, width * 0.32),
		cframe * CFrame.Angles(0, 0, math.rad(angle)),
		color or INK,
		nil,
		rig
	)
end

-- A mouth flush with the face. Crescent shapes are made by covering part of a dark shape with a thin
-- skin-colored cap, so everything stays close to the surface instead of sticking out like a lip.
function Kit.mouth(self: Kit, cframe: CFrame, opts: MouthOptions, rig: string?)
	local w, h = opts.width, opts.height
	local style = opts.style or "Grin"
	local skin = opts.skin
	local radius = opts.radius or 1.5
	-- A flat disc on a round head floats at its edges. Deepen each layer so its front follows the
	-- head's curvature (depth ~ width^2 / 2r), then push it back so it only shows by `front`.
	local function layer(name: string, size: Vector3, offset: Vector3, front: number, color: Color3): Part
		local depth = math.max(size.Z, size.X * size.X / (2 * radius))
		return self:ellipsoid(
			name,
			Vector3.new(size.X, size.Y, depth),
			cframe * CFrame.new(offset.X, offset.Y, depth / 2 - front),
			color,
			nil,
			rig
		)
	end

	if style == "Smile" or style == "Frown" then
		local dir = if style == "Smile" then 1 else -1
		layer("Mouth", Vector3.new(w, h, 0.16), Vector3.new(0, 0, 0), 0.1, MOUTH)
		layer("MouthCap", Vector3.new(w * 1.12, h * 0.92, 0.19), Vector3.new(0, h * 0.26 * dir, 0), 0.13, skin)
		return
	end
	if style == "Flat" then
		layer("Mouth", Vector3.new(w, h * 0.22, 0.13), Vector3.new(0, 0, 0), 0.08, INK)
		return
	end
	if style == "Smirk" then
		local smirk = CFrame.Angles(0, 0, math.rad(-12))
		cframe = cframe * smirk
		layer("Mouth", Vector3.new(w, h * 0.7, 0.16), Vector3.new(0, 0, 0), 0.1, MOUTH)
		layer("MouthCap", Vector3.new(w * 1.1, h * 0.7, 0.19), Vector3.new(-w * 0.08, h * 0.24, 0), 0.13, skin)
		return
	end

	-- Open mouths: Grin (wide D shape), Open (round "O"), Tongue (tongue out), Teeth (clenched grin)
	local mouthH = if style == "Open" then h * 1.1 else h
	local mouthW = if style == "Open" then w * 0.65 else w
	layer("Mouth", Vector3.new(mouthW, mouthH, 0.16), Vector3.new(0, 0, 0), 0.1, MOUTH)
	if style == "Grin" or style == "Tongue" or style == "Teeth" then
		-- flatten the top into a D: thin skin cap over the upper edge
		layer("MouthCap", Vector3.new(w * 1.14, h * 0.6, 0.19), Vector3.new(0, h * 0.47, 0), 0.13, skin)
	end
	if opts.teeth ~= false and (style == "Grin" or style == "Teeth") then
		local teethH = if style == "Teeth" then h * 0.55 else h * 0.26
		layer("Teeth", Vector3.new(w * 0.76, teethH, 0.1), Vector3.new(0, h * 0.1, 0), 0.11, WHITE)
	end
	if opts.buckTooth then
		self:part(
			"BuckTooth",
			Vector3.new(w * 0.15, h * 0.3, 0.05),
			cframe * CFrame.new(w * 0.08, h * 0.04, -0.1),
			WHITE,
			nil,
			rig
		)
	end
	if opts.tongue ~= false and (style == "Grin" or style == "Open" or style == "Tongue") then
		local tongueOut = if style == "Tongue" then 1 else 0
		layer(
			"Tongue",
			Vector3.new(w * 0.5, h * (0.45 + tongueOut * 0.5), 0.112 + tongueOut * 0.2),
			Vector3.new(w * 0.04, -h * (0.2 + tongueOut * 0.35), 0),
			0.116 + tongueOut * 0.25,
			TONGUE
		)
	end
end

function Kit.blush(self: Kit, cframe: CFrame, size: number, rig: string?): Part
	local part = self:ellipsoid(
		"Blush",
		Vector3.new(size, size * 0.55, size * 0.12),
		cframe * CFrame.new(0, 0, -size * 0.02),
		BLUSH,
		nil,
		rig
	)
	part.Transparency = 0.25
	return part
end

-- A complete pair of eyes placed symmetrically on a shell.
function Kit.eyes(self: Kit, shell: Shell, yaw: number, pitch: number, opts: EyeOptions, rig: string?)
	for _, side in { -1, 1 } do
		local eyeOpts = table.clone(opts)
		eyeOpts.side = side
		self:eye(Kit.on(shell, yaw * side, pitch, -math.min(opts.width, opts.height) * 0.12), eyeOpts, rig)
	end
end

---------------------------------------------------------------------------
-- Clothing and gear
---------------------------------------------------------------------------

-- A white chest badge with a prison number printed on it.
function Kit.badge(self: Kit, cframe: CFrame, text: string, width: number, rig: string?): Part
	local badge =
		self:part("Badge", Vector3.new(width, width * 0.45, 0.06), cframe * CFrame.new(0, 0, -0.03), WHITE, nil, rig)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.6
	gui.MaxDistance = 60
	gui.Parent = badge
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = INK
	label.Text = text
	label.Parent = gui
	return badge
end

return Kit
