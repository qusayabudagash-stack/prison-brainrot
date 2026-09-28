-- Plays the sound effects listed in Modules/SoundData, locally for this player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundData = require(ReplicatedStorage.Modules.SoundData)

local Sounds = {}

local templates: { [string]: Sound } = {}

local function template(name: string): Sound?
	local info = SoundData[name]
	if not info or info.id == "" then
		return nil
	end
	local existing = templates[name]
	if existing then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = info.id
	sound.Volume = info.volume
	templates[name] = sound
	return sound
end

-- `pitch` multiplies the configured playback speed, e.g. to make roll ticks rise in pitch.
function Sounds.play(name: string, pitch: number?)
	local base = template(name)
	if not base then
		return
	end
	local sound = base:Clone()
	sound.PlaybackSpeed = SoundData[name].speed * (pitch or 1)
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sounds
