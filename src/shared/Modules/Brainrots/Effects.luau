-- Rarity effects layered on top of a finished design. They are deliberately light: the character
-- itself carries its rarity (rarer Brainrots are bigger, more detailed and use richer materials),
-- and effects only add a little atmosphere on top, never neon shapes that hide the model.
--   Rare       a few sparkles
--   Epic       more sparkles
--   Legendary  + a warm light and a soft aura rising from the feet
--   Mythic     + a stronger aura
--   Divine     + a slow shimmer of light around the whole body
--   Secret     all of it, in rainbow

local Effects = {}

local ORDER = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Secret = 8 }

-- Effect colors: softer than the UI rarity colors so they don't fight the character's own colors.
local TINT: { [string]: Color3 } = {
	Rare = Color3.fromRGB(150, 205, 255),
	Epic = Color3.fromRGB(205, 150, 255),
	Legendary = Color3.fromRGB(255, 214, 110),
	Mythic = Color3.fromRGB(255, 130, 175),
	Divine = Color3.fromRGB(170, 255, 240),
	Secret = Color3.fromRGB(210, 150, 255),
}

local SPECTRUM = {
	Color3.fromRGB(255, 90, 105),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 232, 80),
	Color3.fromRGB(100, 225, 125),
	Color3.fromRGB(80, 180, 255),
	Color3.fromRGB(180, 110, 255),
}

local function rainbowSequence(): ColorSequence
	local keypoints = {}
	for i, color in SPECTRUM do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#SPECTRUM - 1), color))
	end
	return ColorSequence.new(keypoints)
end

local function emitter(parent: Instance, name: string, color: ColorSequence): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Name = name
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = color
	particles.LightEmission = 0.8
	particles.LightInfluence = 0
	particles.Parent = parent
	return particles
end

-- `halfWidth` and `top` are the measured size of the design, so effects fit every silhouette.
function Effects.apply(model: Model, body: BasePart, rarityId: string, halfWidth: number, _top: number)
	local tier = ORDER[rarityId] or 1
	if tier < ORDER.Rare then
		return
	end
	local secret = rarityId == "Secret"
	local tint = TINT[rarityId]
	local color = if secret then rainbowSequence() else ColorSequence.new(tint, Color3.new(1, 1, 1))

	-- Sparkles drifting around the body
	local sparkles = emitter(body, "RaritySparkle", color)
	sparkles.Rate = if tier >= ORDER.Epic then 2.5 else 1.2
	sparkles.Lifetime = NumberRange.new(0.8, 1.5)
	sparkles.Speed = NumberRange.new(0.2, 0.7)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rotation = NumberRange.new(0, 360)
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, if tier >= ORDER.Legendary then 0.32 else 0.24),
		NumberSequenceKeypoint.new(1, 0),
	})

	if tier < ORDER.Legendary then
		return
	end
	local light = Instance.new("PointLight")
	light.Name = "RarityLight"
	light.Color = tint
	light.Range = 8 + tier
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = body

	-- An invisible plate at the feet the aura rises from
	local feet = Instance.new("Part")
	feet.Name = "AuraSource"
	feet.Size = Vector3.new(math.min(halfWidth, 3) * 1.4, 0.1, math.min(halfWidth, 3) * 1.4)
	feet.CFrame = CFrame.new(0, 0.1, 0)
	feet.Transparency = 1
	feet.CanCollide = false
	feet.CanTouch = false
	feet.CanQuery = false
	feet.CastShadow = false
	feet.Anchored = true
	feet.Massless = true
	feet:SetAttribute("Effect", true)
	feet:SetAttribute("KeepColor", true)
	feet.Parent = model
	local aura = emitter(feet, "RarityAura", color)
	aura.EmissionDirection = Enum.NormalId.Top
	aura.Rate = if tier >= ORDER.Mythic then 7 else 4
	aura.Lifetime = NumberRange.new(1, 1.8)
	aura.Speed = NumberRange.new(1.2, 2.8)
	aura.SpreadAngle = Vector2.new(6, 6)
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	aura.Transparency = NumberSequence.new(0.3, 1)

	if tier >= ORDER.Divine then
		-- A slow shimmer across the whole silhouette
		local shimmer = emitter(body, "RarityShimmer", color)
		shimmer.Rate = if secret then 10 else 6
		shimmer.Lifetime = NumberRange.new(1.4, 2.2)
		shimmer.Speed = NumberRange.new(0.05, 0.2)
		shimmer.SpreadAngle = Vector2.new(180, 180)
		shimmer.Shape = Enum.ParticleEmitterShape.Box
		shimmer.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		shimmer.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		shimmer.Transparency = NumberSequence.new(0.35, 1)
	end
end

return Effects
