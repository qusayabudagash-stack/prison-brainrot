-- A small builder for world props. Every shape is placed relative to an origin CFrame, so a prop is
-- written once in its own space (front facing -Z, floor at y = 0) and can be dropped anywhere.
--
--   local s = Shapes.model(parent, "Bench", CFrame.new(10, 1, 4))
--   s:box("Seat", Vector3.new(6, 0.4, 2), CFrame.new(0, 1.6, 0), Palette.Wood, Enum.Material.WoodPlanks)
--
-- `box`, `cyl`, `ball` and `wedge` make solid parts; pass solid = false (or use `deco`) for details
-- players should walk through. Details never block queries or touches.

local Build = require(script.Parent.Parent.Build)

local Shapes = {}
Shapes.__index = Shapes

export type Shapes = typeof(setmetatable({} :: { parent: Instance, origin: CFrame }, Shapes))

function Shapes.new(parent: Instance, origin: CFrame?): Shapes
	return setmetatable({ parent = parent, origin = origin or CFrame.new() }, Shapes)
end

-- A builder that puts its parts in a new Model called `name`.
function Shapes.model(parent: Instance, name: string, origin: CFrame?): Shapes
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return Shapes.new(model, origin)
end

-- A builder for a sub-part of this prop, offset from its origin, in the same parent.
function Shapes.at(self: Shapes, offset: CFrame): Shapes
	return Shapes.new(self.parent, self.origin * offset)
end

-- A builder for a child Model of this prop.
function Shapes.child(self: Shapes, name: string, offset: CFrame?): Shapes
	return Shapes.model(self.parent, name, self.origin * (offset or CFrame.new()))
end

local function finish(part: Part, solid: boolean?): Part
	part.CanTouch = false
	if solid == false then
		part.CanCollide = false
		part.CanQuery = false
	end
	return part
end

function Shapes.box(
	self: Shapes,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	return finish(Build.part(self.parent, name, size, self.origin * cframe, color, material), solid)
end

-- Non-colliding detail.
function Shapes.deco(
	self: Shapes,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return self:box(name, size, cframe, color, material, false)
end

-- Glowing detail: neon, no collisions, no shadow.
function Shapes.glow(self: Shapes, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = self:deco(name, size, cframe, color, Enum.Material.Neon)
	part.CastShadow = false
	return part
end

-- Cylinder whose axis runs along the CFrame's UpVector.
function Shapes.cyl(
	self: Shapes,
	name: string,
	length: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	local part = self:box(
		name,
		Vector3.new(length, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		solid
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Shapes.ball(
	self: Shapes,
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	local part = self:box(name, Vector3.new(diameter, diameter, diameter), CFrame.new(position), color, material, solid)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Wedge: the slope faces the CFrame's front (-Z) and up.
function Shapes.wedge(
	self: Shapes,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	local part = self:box(name, size, cframe, color, material, solid)
	part.Shape = Enum.PartType.Wedge
	return part
end

-- A rod between two local points (pipes, rails, chains, cables).
function Shapes.rod(
	self: Shapes,
	name: string,
	from: Vector3,
	to: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	local axis = to - from
	local up = axis.Unit
	local right = if math.abs(up.Y) > 0.99 then Vector3.xAxis else up:Cross(Vector3.yAxis).Unit
	local back = right:Cross(up).Unit
	local cframe = CFrame.fromMatrix((from + to) / 2, right, up, back)
	return self:cyl(name, axis.Magnitude, diameter, cframe, color, material, solid)
end

function Shapes.light(
	_self: Shapes,
	part: BasePart,
	color: Color3,
	range: number,
	brightness: number?,
	shadows: boolean?
): PointLight
	local light = Build.light(part, color, range, brightness)
	light.Shadows = shadows == true
	return light
end

-- A cone of light shining out of `face` of the part.
function Shapes.spot(
	_self: Shapes,
	part: BasePart,
	color: Color3,
	range: number,
	brightness: number,
	angle: number,
	face: Enum.NormalId?
): SpotLight
	local light = Instance.new("SpotLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Angle = angle
	light.Face = face or Enum.NormalId.Bottom
	light.Shadows = true
	light.Parent = part
	return light
end

function Shapes.text(
	_self: Shapes,
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	options: Build.TextOptions?
): TextLabel
	return Build.surfaceText(part, face, text, options)
end

-- World-space CFrame of a local offset (for prompts, lights or anything placed by other code).
function Shapes.world(self: Shapes, cframe: CFrame): CFrame
	return self.origin * cframe
end

return Shapes
