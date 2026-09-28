-- Rarity effects layered on top of a finished design. Each tier keeps the effects of the tiers
-- below it and adds one new idea, so rarer Brainrots read as rarer at a glance:
--   Rare       sparkles
--   Epic       + a glowing pad on the ground
--   Legendary  + warm light and an aura rising from the feet
--   Mythic     + orbs in orbit
--   Divine     + a slowly turning burst of light rays behind it
--   Secret     all of it, in rainbow

local Kit = require(script.Parent.Kit)

local Effects = {}

local ORDER = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Secret = 8 }

-- Effect colors: softer than the UI rarity colors so they don't fight the character's own colors.
local TINT: { [string]: Color3 } = {
	Rare = Color3.fromRGB(120, 190, 255),
	Epic = Color3.fromRGB(190, 120, 255),
	Legendary = Color3.fromRGB(255, 205, 80),
	Mythic = Color3.fromRGB(255, 90, 150),
	Divine = Color3.fromRGB(150, 255, 240),
	Secret = Color3.fromRGB(200, 120, 255),
}

local SPECTRUM = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 160, 40),
	Color3.fromRGB(255, 230, 60),
	Color3.fromRGB(80, 225, 110),
	Color3.fromRGB(60, 170, 255),
	Color3.fromRGB(170, 90, 255),
}

local function rainbowSequence(): ColorSequence
	local keypoints = {}
	for i, color in SPECTRUM do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#SPECTRUM - 1), color))
	end
	return ColorSequence.new(keypoints)
end

local function sparkles(parent: BasePart, color: ColorSequence, rate: number, size: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "RaritySparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = color
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Speed = NumberRange.new(0.3, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = parent
end

local function effectPart(part: BasePart): BasePart
	part.CastShadow = false
	part:SetAttribute("KeepColor", true)
	part:SetAttribute("Effect", true)
	return part
end

-- `halfWidth` and `top` are the measured size of the design, so effects fit every silhouette.
function Effects.apply(model: Model, body: BasePart, rarityId: string, halfWidth: number, top: number)
	local tier = ORDER[rarityId] or 1
	if tier < ORDER.Rare then
		return
	end
	local k = Kit.new(model)
	local secret = rarityId == "Secret"
	local tint = TINT[rarityId]
	local color = if secret then rainbowSequence() else ColorSequence.new(tint, Color3.new(1, 1, 1))
	halfWidth = math.min(halfWidth, 3.2)

	sparkles(body, color, if tier >= ORDER.Mythic then 5 else 2.5, if tier >= ORDER.Legendary then 0.45 else 0.3)

	if tier >= ORDER.Epic then
		local radius = halfWidth + 0.5
		local glow =
			effectPart(k:cylinder("GlowPad", 0.04, radius * 2, CFrame.new(0, 0.03, 0), tint, Enum.Material.Neon))
		glow.Transparency = 0.72
		local rim =
			effectPart(k:cylinder("GlowPad", 0.03, radius * 2.35, CFrame.new(0, 0.02, 0), tint, Enum.Material.Neon))
		rim.Transparency = 0.88
		if secret then
			for i, band in SPECTRUM do
				local ring = effectPart(
					k:cylinder(
						"GlowPad",
						0.02,
						radius * (2.3 - i * 0.2),
						CFrame.new(0, 0.035 + i * 0.004, 0),
						band,
						Enum.Material.Neon
					)
				)
				ring.Transparency = 0.7
			end
		end
	end

	if tier >= ORDER.Legendary then
		local light = Instance.new("PointLight")
		light.Name = "RarityLight"
		light.Color = tint
		light.Range = 10 + tier
		light.Brightness = 1.2
		light.Parent = body

		local feet = effectPart(
			k:part("AuraSource", Vector3.new(halfWidth * 1.6, 0.1, halfWidth * 1.6), CFrame.new(0, 0.1, 0), tint)
		)
		feet.Transparency = 1
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "RarityAura"
		aura.Color = color
		aura.LightEmission = 1
		aura.LightInfluence = 0
		aura.EmissionDirection = Enum.NormalId.Top
		aura.Rate = if tier >= ORDER.Divine then 14 else 8
		aura.Lifetime = NumberRange.new(1, 1.8)
		aura.Speed = NumberRange.new(1.5, 3.5)
		aura.SpreadAngle = Vector2.new(8, 8)
		aura.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		aura.Transparency = NumberSequence.new(0.2, 1)
		aura.Parent = feet
	end

	if tier >= ORDER.Mythic then
		local radius = halfWidth + 0.9
		for i = 0, 2 do
			local angle = i * math.pi * 2 / 3
			local orbColor = if secret then SPECTRUM[i * 2 + 1] else tint
			local orb = effectPart(
				k:ball(
					"RarityOrb",
					0.38,
					Vector3.new(math.cos(angle) * radius, top * (0.35 + i * 0.2), math.sin(angle) * radius),
					orbColor,
					Enum.Material.Neon,
					"Orbit"
				)
			)
			local glow = Instance.new("PointLight")
			glow.Color = orbColor
			glow.Range = 4
			glow.Brightness = 1
			glow.Parent = orb
		end
	end

	if tier >= ORDER.Divine then
		-- A sunburst standing behind the character, turned slowly by the client animator.
		local center = Vector3.new(0, top * 0.55, 1.9)
		local length = top * 0.75
		for i = 0, 9 do
			local angle = i * math.pi * 2 / 10
			local rayColor = if secret then SPECTRUM[i % #SPECTRUM + 1] else tint:Lerp(Color3.new(1, 1, 1), 0.35)
			local ray = effectPart(
				k:ellipsoid(
					"LightRay",
					Vector3.new(0.55, length, 0.04),
					CFrame.new(center) * CFrame.Angles(0, 0, angle) * CFrame.new(0, length * 0.62, 0),
					rayColor,
					Enum.Material.Neon,
					"Glory"
				)
			)
			ray.Transparency = 0.55
		end
		model:SetAttribute("GloryJoint", center)
	end
end

return Effects
