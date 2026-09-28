-- Builds each cell cosmetic out of parts. Coordinates are in cell space:
-- floor at y = 0, x from -9 to 9, back wall at z = -7, bars (the open side) at z = +7.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)

local CosmeticBuilder = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local GOLD = Color3.fromRGB(255, 200, 50)

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(170, 90, 255),
}

type Builder = (model: Model, origin: CFrame, bestBrainrot: string?) -> ()

local function toilet(model: Model, origin: CFrame, color: Color3, material: Enum.Material)
	Build.cylinder(model, "Bowl", 1.4, 1.8, origin * CFrame.new(0, 0.7, 0), color, material)
	Build.cylinder(
		model,
		"Seat",
		0.2,
		2,
		origin * CFrame.new(0, 1.5, 0),
		color:Lerp(Color3.new(0, 0, 0), 0.1),
		material
	)
	Build.part(model, "Tank", Vector3.new(0.9, 2.2, 1.8), origin * CFrame.new(1.1, 1.6, 0), color, material)
end

local BUILDERS: { [string]: Builder } = {
	Bed = function(model, origin)
		local base = origin * CFrame.new(-6.3, 0, 1.5)
		Build.part(
			model,
			"BedFrame",
			Vector3.new(4.2, 1.2, 7),
			base * CFrame.new(0, 0.6, 0),
			Color3.fromRGB(150, 100, 60)
		)
		Build.part(model, "Mattress", Vector3.new(3.8, 0.6, 6.6), base * CFrame.new(0, 1.5, 0), WHITE)
		Build.part(
			model,
			"Blanket",
			Vector3.new(3.9, 0.3, 4.2),
			base * CFrame.new(0, 1.85, 1.1),
			Color3.fromRGB(255, 120, 150)
		)
		Build.part(
			model,
			"Pillow",
			Vector3.new(3, 0.5, 1.3),
			base * CFrame.new(0, 2, -2.4),
			Color3.fromRGB(170, 220, 255)
		)
	end,

	Toilet = function(model, origin)
		toilet(
			model,
			origin * CFrame.new(7.4, 0, 5) * CFrame.Angles(0, math.rad(90), 0),
			WHITE,
			Enum.Material.SmoothPlastic
		)
	end,

	GoldToilet = function(model, origin)
		local base = origin * CFrame.new(0, 0, 2)
		toilet(model, base, GOLD, Enum.Material.Foil)
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = GOLD
		sparkles.Parent = model:FindFirstChild("Bowl")
	end,

	Poster = function(model, origin)
		for i, emoji in { "🥔", "🐸", "👑" } do
			local poster = Build.deco(
				model,
				"Poster",
				Vector3.new(3.2, 4, 0.1),
				origin * CFrame.new(-6 + (i - 1) * 6, 8, -6.9),
				RAINBOW[i * 2 - 1]
			)
			Build.surfaceText(poster, Enum.NormalId.Back, emoji, { pixelsPerStud = 20 })
		end
	end,

	TV = function(model, origin)
		local base = origin * CFrame.new(7.5, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
		Build.part(
			model,
			"TVStand",
			Vector3.new(3, 2.4, 1.4),
			base * CFrame.new(0, 1.2, 0),
			Color3.fromRGB(120, 80, 50)
		)
		Build.part(
			model,
			"TVBody",
			Vector3.new(3.6, 2.6, 0.5),
			base * CFrame.new(0, 3.7, 0),
			Color3.fromRGB(40, 40, 50)
		)
		local screen = Build.deco(
			model,
			"TVScreen",
			Vector3.new(3.2, 2.2, 0.1),
			base * CFrame.new(0, 3.7, -0.3),
			Color3.fromRGB(80, 200, 255),
			Enum.Material.Neon
		)
		Build.surfaceText(screen, Enum.NormalId.Front, "🎰 ROLL TV", { textColor = WHITE, pixelsPerStud = 25 })
	end,

	Plant = function(model, origin)
		local base = origin * CFrame.new(-7.8, 0, 5.8)
		Build.cylinder(model, "Pot", 1.4, 1.6, base * CFrame.new(0, 0.7, 0), Color3.fromRGB(200, 110, 70))
		for i = 0, 3 do
			local angle = i * math.pi / 2
			Build.ball(
				model,
				"Leaf",
				1.3,
				base * CFrame.new(math.cos(angle) * 0.5, 2 + i * 0.3, math.sin(angle) * 0.5),
				Color3.fromRGB(80, 190, 80)
			)
		end
	end,

	NeonLights = function(model, origin)
		local colors = { Color3.fromRGB(255, 80, 200), Color3.fromRGB(80, 220, 255) }
		Build.deco(
			model,
			"NeonStrip",
			Vector3.new(17, 0.3, 0.3),
			origin * CFrame.new(0, 11.4, -6.8),
			colors[1],
			Enum.Material.Neon
		)
		for i, side in { -1, 1 } do
			local strip = Build.deco(
				model,
				"NeonStrip",
				Vector3.new(0.3, 0.3, 13.5),
				origin * CFrame.new(side * 8.8, 11.4, -0.3),
				colors[i],
				Enum.Material.Neon
			)
			Build.light(strip, colors[i], 14, 1)
		end
	end,

	Statue = function(model, origin, bestBrainrot)
		local base = origin * CFrame.new(4.2, 0, 4.2)
		Build.cylinder(model, "Plinth", 1, 2.6, base * CFrame.new(0, 0.5, 0), WHITE)
		local statue = BrainrotModel.build(bestBrainrot or "PotatoPrisoner", { variant = "Golden", scale = 0.6 })
		statue.Name = "Statue"
		statue:PivotTo(base * CFrame.new(0, 1, 0) * CFrame.Angles(0, math.pi, 0))
		statue.Parent = model
	end,

	DiscoBall = function(model, origin)
		local center = origin * CFrame.new(0, 10, 0)
		Build.deco(
			model,
			"DiscoString",
			Vector3.new(0.1, 2, 0.1),
			center * CFrame.new(0, 2, 0),
			Color3.fromRGB(80, 80, 80)
		)
		local ball = Build.ball(model, "DiscoBall", 2.2, center, Color3.fromRGB(220, 220, 240), Enum.Material.Foil)
		ball.CanCollide = false
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 150, 255)
		sparkles.Parent = ball
		Build.light(ball, Color3.fromRGB(255, 120, 255), 18, 2)
	end,

	RainbowCarpet = function(model, origin)
		for i, color in RAINBOW do
			Build.deco(
				model,
				"Carpet",
				Vector3.new(9, 0.06, 1.1),
				origin * CFrame.new(0, 0.33, -2 + (i - 1) * 1.1),
				color
			)
		end
	end,
}

function CosmeticBuilder.build(cosmeticId: string, parent: Instance, origin: CFrame, bestBrainrot: string?): Model?
	local builder = BUILDERS[cosmeticId]
	if not builder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = cosmeticId
	builder(model, origin, bestBrainrot)
	model.Parent = parent
	return model
end

return CosmeticBuilder
