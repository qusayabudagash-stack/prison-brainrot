-- Blends the lighting as you walk around: the warm hall, the cooler cell wing, the sunny yard,
-- the cold blue of Cell Block 2, the gloom of Death Row, the glow of the Secret Block...
-- Zones and moods live in Modules/MapLayout; the effects themselves are set up in the project
-- file (Lighting: Atmosphere, Bloom, ColorCorrection).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MapLayout = require(ReplicatedStorage.Modules.MapLayout)

local Ambience = {}

local BLEND = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local current: string? = nil

local function tween(instance: Instance?, goals: { [string]: any })
	if instance then
		TweenService:Create(instance, BLEND, goals):Play()
	end
end

local function apply(moodId: string)
	local mood = MapLayout.Moods[moodId]
	if not mood then
		return
	end
	tween(Lighting, {
		Ambient = mood.ambient,
		OutdoorAmbient = mood.outdoorAmbient,
		Brightness = mood.brightness,
		ExposureCompensation = mood.exposure,
	})
	tween(Lighting:FindFirstChildOfClass("ColorCorrectionEffect"), {
		TintColor = mood.tint,
		Saturation = mood.saturation,
		Contrast = mood.contrast,
	})
	tween(Lighting:FindFirstChildOfClass("Atmosphere"), {
		Haze = mood.haze,
		Density = mood.density,
		Color = mood.atmosphere,
	})
	tween(Lighting:FindFirstChildOfClass("BloomEffect"), { Intensity = mood.bloom })
end

local function where(): Vector3?
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.CFrame.Position
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.Focus.Position else nil
end

function Ambience.init()
	task.spawn(function()
		while true do
			local position = where()
			if position then
				local zone = MapLayout.zoneAt(position)
				local mood = if zone then zone.mood else "Yard"
				if mood ~= current then
					current = mood
					apply(mood)
				end
			end
			task.wait(0.4)
		end
	end)
end

return Ambience
