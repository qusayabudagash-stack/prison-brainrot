-- Builds each cell cosmetic out of parts. Coordinates are in cell space (see Map/CellWing):
-- floor at y = 0, bars at z = -8 (the front), back wall at z = +8, side walls at x = -9 and +9.
--
-- Every cell comes furnished. Some cosmetics are upgrades of that furniture and replace it
-- (the Comfy Bed replaces the steel bunk, the toilets replace the steel toilet); the rest are
-- extras. `apply` puts a cell in the right state for a set of shown cosmetics.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Palette = require(script.Parent.Map.Palette)
local Shapes = require(script.Parent.Map.Shapes)

local CosmeticBuilder = {}

local M = Enum.Material
local v3 = Vector3.new
local rgb = Color3.fromRGB

local RAINBOW = {
	rgb(255, 70, 70),
	rgb(255, 160, 50),
	rgb(255, 235, 60),
	rgb(80, 220, 90),
	rgb(60, 150, 255),
	rgb(170, 90, 255),
}

-- Default furniture each cosmetic replaces.
CosmeticBuilder.REPLACES = {
	Bed = "Bunk",
	Toilet = "Toilet",
	GoldToilet = "Toilet",
} :: { [string]: string }

-- When two shown cosmetics would sit in the same spot, the first one listed wins.
local OVERRIDES = {
	Toilet = "GoldToilet",
}

type Builder = (s: Shapes.Shapes, bestBrainrot: string?) -> ()

local function toilet(s: Shapes.Shapes, color: Color3, material: Enum.Material, seat: Color3)
	s:box("Tank", v3(2.6, 2.4, 1.2), CFrame.new(0, 3, 1.2), color, material)
	s:deco("TankLid", v3(2.8, 0.3, 1.4), CFrame.new(0, 4.35, 1.2), color, material)
	s:deco("Handle", v3(0.5, 0.15, 0.2), CFrame.new(-0.9, 3.8, 0.55), Palette.Chrome, M.Metal)
	s:cyl("Bowl", 1.6, 2, CFrame.new(0, 0.8, -0.2), color, material)
	s:cyl("BowlBase", 0.4, 1.4, CFrame.new(0, 0.2, 0), color, material, false)
	s:cyl("Seat", 0.3, 2.3, CFrame.new(0, 1.75, -0.2), seat, M.Fabric, false)
	s:deco("Lid", v3(2.1, 2.4, 0.2), CFrame.new(0, 2.9, 0.5) * CFrame.Angles(math.rad(-10), 0, 0), seat, M.Fabric)
end

local BUILDERS: { [string]: Builder } = {
	Bed = function(s)
		-- A cozy bed with a quilt, two pillows and a teddy
		local bed = s:at(CFrame.new(-4.4, 0, 5.6) * CFrame.Angles(0, math.pi / 2, 0))
		bed:box("BedFrame", v3(4.2, 1.4, 8), CFrame.new(0, 0.7, 0), Palette.Wood, M.WoodPlanks)
		bed:box("Headboard", v3(4.4, 4.4, 0.5), CFrame.new(0, 2.2, -4), Palette.WoodDark, M.WoodPlanks)
		bed:deco("Mattress", v3(3.9, 0.9, 7.6), CFrame.new(0, 1.85, 0.1), Palette.White, M.Fabric)
		bed:deco("Quilt", v3(4.1, 0.5, 5), CFrame.new(0, 2.3, 1.4), rgb(236, 110, 150), M.Fabric)
		bed:deco("QuiltStripe", v3(4.15, 0.52, 0.6), CFrame.new(0, 2.31, -0.6), rgb(255, 200, 220), M.Fabric)
		for _, x in { -0.95, 0.95 } do
			bed:deco("Pillow", v3(1.7, 0.7, 1.3), CFrame.new(x, 2.55, -2.9), rgb(250, 240, 245), M.Fabric)
		end
		bed:ball("TeddyBody", 1, v3(1, 2.9, 1.8), rgb(160, 110, 70), M.Fabric, false)
		bed:ball("TeddyHead", 0.75, v3(1, 3.65, 1.7), rgb(170, 120, 80), M.Fabric, false)
	end,

	Toilet = function(s)
		local spot = s:at(CFrame.new(6.6, 0, 6.2))
		toilet(spot, Palette.White, M.SmoothPlastic, rgb(170, 220, 255))
		spot:rod("Plunger", v3(-1.9, 0, -0.4), v3(-1.9, 3, -0.4), 0.2, Palette.Wood, M.Wood, false)
		spot:cyl("PlungerCup", 0.4, 0.9, CFrame.new(-1.9, 0.2, -0.4), Palette.Red, M.Rubber, false)
	end,

	GoldToilet = function(s)
		local spot = s:at(CFrame.new(6.6, 0, 6.2))
		toilet(spot, Palette.Gold, M.Foil, rgb(160, 40, 60))
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Palette.Gold
		sparkles.Parent = spot.parent:FindFirstChild("Bowl")
		spot:deco("RedCarpet", v3(3.6, 0.06, 4.4), CFrame.new(0, 0.13, -1.2), rgb(170, 30, 50), M.Fabric).CastShadow =
			false
	end,

	Poster = function(s)
		for i, poster in
			{
				{ text = "🥔\nPOTATO\nPRISONER", color = RAINBOW[1] },
				{ text = "🐸\nPRISON\nFROG", color = RAINBOW[4] },
				{ text = "👑\nTHE KING", color = RAINBOW[6] },
			}
		do
			local at = CFrame.new(-8.9, 8.2, -5 + (i - 1) * 3.6) * CFrame.Angles(0, -math.pi / 2, 0)
			local paper = s:deco("Poster", v3(3, 3.8, 0.05), at, poster.color)
			paper.CastShadow = false
			Build.surfaceText(
				paper,
				Enum.NormalId.Front,
				poster.text,
				{ textColor = Palette.White, strokeColor = poster.color:Lerp(Palette.Ink, 0.6), pixelsPerStud = 40 }
			)
		end
	end,

	TV = function(s)
		local at = CFrame.new(8.2, 7.4, -3.2) * CFrame.Angles(0, math.pi / 2, 0)
		s:deco("TVMount", v3(1, 1, 1.4), at * CFrame.new(0, 0, 0.9), Palette.SteelDark, M.Metal)
		s:deco("TVBody", v3(4.4, 2.8, 0.5), at, Palette.Ink, M.SmoothPlastic)
		local screen = s:glow("TVScreen", v3(4, 2.4, 0.06), at * CFrame.new(0, 0, -0.27), rgb(80, 180, 255))
		Build.surfaceText(
			screen,
			Enum.NormalId.Front,
			"🎰 ROLL TV\nLIVE",
			{ textColor = Palette.White, strokeColor = rgb(20, 60, 110), pixelsPerStud = 40 }
		)
		s:light(screen, rgb(120, 190, 255), 8, 0.7)
	end,

	Plant = function(s)
		local at = CFrame.new(-7.6, 0, -6.4)
		s:cyl("Pot", 1.6, 1.8, at * CFrame.new(0, 0.8, 0), rgb(196, 106, 66), M.SmoothPlastic)
		s:cyl("Soil", 0.1, 1.6, at * CFrame.new(0, 1.62, 0), Palette.Dirt, M.Ground, false)
		for i = 0, 4 do
			local angle = i * math.pi * 2 / 5
			s:ball(
				"Leaf",
				1.2,
				(at * CFrame.new(math.cos(angle) * 0.5, 2.3 + (i % 2) * 0.5, math.sin(angle) * 0.5)).Position,
				rgb(80, 170, 80),
				M.Grass,
				false
			)
		end
		s:ball("Flower", 0.6, (at * CFrame.new(0.2, 3.3, 0)).Position, rgb(255, 120, 170), M.SmoothPlastic, false)
	end,

	NeonLights = function(s)
		local colors = { rgb(255, 80, 200), rgb(80, 220, 255) }
		s:glow("NeonStrip", v3(17.6, 0.25, 0.25), CFrame.new(0, 11.4, 7.7), colors[1])
		for i, side in { -1, 1 } do
			local strip = s:glow("NeonStrip", v3(0.25, 0.25, 15.4), CFrame.new(side * 8.7, 11.4, 0), colors[i])
			s:light(strip, colors[i], 14, 1)
		end
	end,

	Statue = function(s, bestBrainrot)
		local at = CFrame.new(7.4, 0, -6.2)
		s:cyl("Plinth", 1.2, 2.6, at * CFrame.new(0, 0.6, 0), Palette.White, M.Marble)
		s:cyl("PlinthTop", 0.2, 2.8, at * CFrame.new(0, 1.3, 0), Palette.Gold, M.Foil, false)
		local statue = BrainrotModel.build(bestBrainrot or "TimCheese", { variant = "Golden", scale = 0.5 })
		statue.Name = "Statue"
		statue:PivotTo(s:world(at * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, math.rad(20), 0)))
		statue.Parent = s.parent
	end,

	DiscoBall = function(s)
		local center = v3(0, 9.6, 1)
		s:deco("DiscoString", v3(0.1, 1.8, 0.1), CFrame.new(center + v3(0, 1.4, 0)), Palette.SteelDark)
		local ball = s:ball("DiscoBall", 2, center, rgb(220, 220, 240), M.Foil, false)
		ball:SetAttribute("Spin", true)
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rgb(255, 150, 255)
		sparkles.Parent = ball
		s:light(ball, rgb(255, 120, 255), 16, 1.6)
	end,

	RainbowCarpet = function(s)
		for i, color in RAINBOW do
			s:deco("Carpet", v3(15, 0.06, 1), CFrame.new(0, 0.13, -6.6 + (i - 1) * 1), color, M.Fabric).CastShadow =
				false
		end
	end,
}

-- Builds one cosmetic into `parent`, placed in the cell whose pivot is `origin`.
function CosmeticBuilder.build(cosmeticId: string, parent: Instance, origin: CFrame, bestBrainrot: string?): Model?
	local builder = BUILDERS[cosmeticId]
	if not builder then
		return nil
	end
	local s = Shapes.model(parent, cosmeticId, origin)
	builder(s, bestBrainrot)
	return s.parent :: Model
end

-- Shows or hides a piece of default furniture (remembering each part's own transparency).
local function setVisible(model: Instance, visible: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local base = part:GetAttribute("BaseTransparency")
			if base == nil then
				base = part.Transparency
				part:SetAttribute("BaseTransparency", base)
				part:SetAttribute("BaseCollide", part.CanCollide)
			end
			part.Transparency = if visible then base :: number else 1
			part.CanCollide = visible and part:GetAttribute("BaseCollide") == true
		end
	end
end

-- Puts a cell's decorations in line with `shown` (cosmetic id -> shown).
function CosmeticBuilder.apply(cell: Model, shown: { [string]: boolean }, bestBrainrot: string?)
	local decor = cell:FindFirstChild("Decor")
	if not decor then
		return
	end
	decor:ClearAllChildren()
	local replaced = {}
	for cosmeticId, isShown in shown do
		local winner = OVERRIDES[cosmeticId]
		if isShown and not (winner and shown[winner]) then
			if CosmeticBuilder.build(cosmeticId, decor, cell:GetPivot(), bestBrainrot) then
				local default = CosmeticBuilder.REPLACES[cosmeticId]
				if default then
					replaced[default] = true
				end
			end
		end
	end
	for _, default in CosmeticBuilder.REPLACES do
		local furniture = cell:FindFirstChild(default)
		if furniture then
			setVisible(furniture, not replaced[default])
		end
	end
end

return CosmeticBuilder
