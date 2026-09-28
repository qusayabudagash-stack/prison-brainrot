-- Builds a Brainrot character from its design (see Brainrots/). Everything is made of plain parts,
-- so no uploaded assets are needed. Models face -Z, stand on y = 0 at their pivot, and can be
-- scaled with the `scale` option. Used by the server for cell displays and events, and by the
-- client for viewport cards.
--
-- Asset override: a Model named after a Brainrot id inside ReplicatedStorage.BrainrotAssets (for
-- example a MeshPart model you own or got from the Creator Store under a license that allows it) is
-- used instead of the built-in design. Face it towards -Z; it is centered and set on the ground
-- automatically, and a part named "Body" (or its PrimaryPart) gets the rarity effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(script.Parent.BrainrotData)
local Designs = require(script.Parent.Brainrots.Designs)
local Effects = require(script.Parent.Brainrots.Effects)
local Kit = require(script.Parent.Brainrots.Kit)
local Parts = require(script.Parent.Brainrots.Parts)

local BrainrotModel = {}

export type Options = {
	variant: string?,
	scale: number?,
	-- Weld every part to an anchored root so the whole model can be moved by moving the root.
	welded: boolean?,
	-- Put a crown on its head (the event King).
	crowned: boolean?,
}

local GOLD = Color3.fromRGB(255, 200, 50)
local DIAMOND = Color3.fromRGB(150, 240, 255)

-- Face parts that keep their colors on Golden and Diamond variants, so the character stays readable.
local FACE_PARTS = {
	Sclera = true,
	Iris = true,
	Pupil = true,
	Highlight = true,
	Highlight2 = true,
	Mouth = true,
	Teeth = true,
	Tongue = true,
	BuckTooth = true,
	GlowEye = true,
	EyeArc = true,
	Badge = true,
}

local function addVariantEffects(model: Model, body: BasePart, variantId: string)
	if variantId == "Normal" then
		return
	end
	local isGolden = variantId == "Golden"
	local color = if isGolden then GOLD else DIAMOND
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 and not descendant:GetAttribute("KeepColor") then
			descendant.Color = descendant.Color:Lerp(color, if isGolden then 0.85 else 0.8)
			descendant.Material = if isGolden then Enum.Material.Foil else Enum.Material.Glass
			if not isGolden then
				descendant.Transparency = 0.12
			end
		end
	end

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 2
	light.Parent = body

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "VariantSparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	emitter.LightEmission = 1
	emitter.Rate = if isGolden then 8 else 16
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(if isGolden then 0.35 else 0.5, 0)
	emitter.Parent = body
end

-- Axis-aligned bounds of the character itself (effects excluded): half-width and top.
local function measure(model: Model): (number, number)
	local halfWidth, top = 0, 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and not part:GetAttribute("Effect") then
			local cframe, half = part.CFrame, part.Size / 2
			local reachX = math.abs(cframe.RightVector.X) * half.X
				+ math.abs(cframe.UpVector.X) * half.Y
				+ math.abs(cframe.LookVector.X) * half.Z
			local reachY = math.abs(cframe.RightVector.Y) * half.X
				+ math.abs(cframe.UpVector.Y) * half.Y
				+ math.abs(cframe.LookVector.Y) * half.Z
			halfWidth = math.max(halfWidth, math.abs(cframe.Position.X) + reachX)
			top = math.max(top, cframe.Position.Y + reachY)
		end
	end
	return halfWidth, top
end

function BrainrotModel.build(brainrotId: string, options: Options?): Model
	local brainrot = BrainrotData.ById[brainrotId]
	assert(brainrot, `Unknown Brainrot {brainrotId}`)
	local design = Designs[brainrotId]
	assert(design, `No design for Brainrot {brainrotId}`)
	local opts: Options = options or {}

	local model = Instance.new("Model")
	model.Name = brainrotId
	local kit = Kit.new(model)
	-- Root: invisible, at the feet, holds the model's pivot.
	local root = kit:part("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	root.CastShadow = false
	root.PivotOffset = CFrame.new(0, -0.5, 0)
	model.PrimaryPart = root

	local override = BrainrotModel.override(brainrotId)
	local body = if override then BrainrotModel.useOverride(model, override) else design(kit)
	body.Name = "Body"
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and FACE_PARTS[descendant.Name] then
			descendant:SetAttribute("KeepColor", true)
		end
	end
	if opts.crowned then
		-- Designs can mark where their head's crown goes; otherwise it sits on the highest point
		local headTop = model:GetAttribute("HeadTop")
		local headWidth = model:GetAttribute("HeadWidth")
		local _, measuredTop = measure(model)
		local at = if typeof(headTop) == "Vector3" then headTop else Vector3.new(0, measuredTop - 0.2, 0)
		local width = if type(headWidth) == "number" then headWidth else 1.4
		Parts.crown(kit, CFrame.new(at), width, nil, "Body")
	end
	local halfWidth, top = measure(model)
	model:SetAttribute("BrainrotId", brainrotId)
	model:SetAttribute("Rarity", brainrot.rarity)
	model:SetAttribute("Width", halfWidth * 2)
	model:SetAttribute("Height", top)
	model:SetAttribute("Scale", opts.scale or 1)

	Effects.apply(model, body, brainrot.rarity, halfWidth, top)
	addVariantEffects(model, body, opts.variant or "Normal")

	if opts.welded then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant ~= root then
				descendant.Anchored = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
	if opts.scale and opts.scale ~= 1 then
		model:ScaleTo(opts.scale)
	end
	return model
end

-- The replacement model for a Brainrot from ReplicatedStorage.BrainrotAssets, if there is one.
function BrainrotModel.override(brainrotId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("BrainrotAssets")
	local asset = folder and folder:FindFirstChild(brainrotId)
	return if asset and asset:IsA("Model") then asset else nil
end

-- Copies an override model's parts into `model`, standing on y = 0 and centered, and returns its body.
function BrainrotModel.useOverride(model: Model, asset: Model): BasePart
	local copy = asset:Clone()
	-- World-axis bounds of every part, so the asset is centered and grounded whatever its pivot
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	local parts: { BasePart } = {}
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("BasePart") then
			local cframe, half = descendant.CFrame, descendant.Size / 2
			local reach = Vector3.new(
				math.abs(cframe.RightVector.X) * half.X
					+ math.abs(cframe.UpVector.X) * half.Y
					+ math.abs(cframe.LookVector.X) * half.Z,
				math.abs(cframe.RightVector.Y) * half.X
					+ math.abs(cframe.UpVector.Y) * half.Y
					+ math.abs(cframe.LookVector.Y) * half.Z,
				math.abs(cframe.RightVector.Z) * half.X
					+ math.abs(cframe.UpVector.Z) * half.Y
					+ math.abs(cframe.LookVector.Z) * half.Z
			)
			low = low:Min(cframe.Position - reach)
			high = high:Max(cframe.Position + reach)
			table.insert(parts, descendant)
		end
	end
	local shift = Vector3.new(-(low.X + high.X) / 2, -low.Y, -(low.Z + high.Z) / 2)
	for _, part in parts do
		part.CFrame += shift
	end
	local body = copy:FindFirstChild("Body", true) or copy.PrimaryPart
	for _, child in copy:GetChildren() do
		child.Parent = model
	end
	copy:Destroy()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			if descendant.Name ~= "Root" then
				body = body or descendant
			end
		end
	end
	return body :: BasePart
end

local boundsCache: { [string]: Vector2 } = {}

-- Width and height of an unscaled model (cached), for framing cameras and placing labels.
function BrainrotModel.bounds(brainrotId: string): Vector2
	local cached = boundsCache[brainrotId]
	if cached then
		return cached
	end
	local model = BrainrotModel.build(brainrotId)
	local bounds = Vector2.new(model:GetAttribute("Width") :: number, model:GetAttribute("Height") :: number)
	model:Destroy()
	boundsCache[brainrotId] = bounds
	return bounds
end

-- Height of an unscaled model plus a little headroom, for placing labels above it.
function BrainrotModel.height(brainrotId: string): number
	return BrainrotModel.bounds(brainrotId).Y + 1
end

-- How far above the model's Body part a label should float to clear the top of a built model.
function BrainrotModel.labelOffset(model: Model, margin: number): number
	local body = model:FindFirstChild("Body") :: BasePart
	local scale = (model:GetAttribute("Scale") :: number?) or 1
	local top = model:GetPivot().Position.Y + ((model:GetAttribute("Height") :: number?) or 5) * scale
	return top - body.CFrame.Position.Y + margin
end

return BrainrotModel
