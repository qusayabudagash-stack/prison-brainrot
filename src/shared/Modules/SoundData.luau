-- Sound effects. Each entry is played by name, e.g. Sounds.play("RollTick").
-- The defaults use sounds built into every Roblox client (rbxasset://), pitched differently per rarity.
-- To use your own, paste an asset id such as "rbxassetid://1234567890" into `id`.
-- Leave `id` as "" to silence a sound.

export type SoundInfo = {
	id: string,
	volume: number,
	speed: number,
}

local CLICK = "rbxasset://sounds/clickfast.wav"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local SWOOSH = "rbxasset://sounds/swoosh.wav"

local SoundData = {
	ButtonClick = { id = CLICK, volume = 0.5, speed = 1 },
	RollStart = { id = SWOOSH, volume = 0.6, speed = 1 },
	RollTick = { id = CLICK, volume = 0.35, speed = 1.5 },
	RevealCommon = { id = PING, volume = 0.5, speed = 0.8 },
	RevealUncommon = { id = PING, volume = 0.55, speed = 0.9 },
	RevealRare = { id = PING, volume = 0.6, speed = 1 },
	RevealEpic = { id = PING, volume = 0.7, speed = 1.15 },
	RevealLegendary = { id = PING, volume = 0.8, speed = 1.3 },
	RevealMythic = { id = PING, volume = 0.9, speed = 1.45 },
	RevealDivine = { id = PING, volume = 1, speed = 1.6 },
	RevealSecret = { id = PING, volume = 1, speed = 0.6 },
	CoinReward = { id = PING, volume = 0.35, speed = 1.9 },
	Rebirth = { id = SWOOSH, volume = 0.9, speed = 0.7 },
	UnlockArea = { id = PING, volume = 0.8, speed = 1.2 },
	Announcement = { id = PING, volume = 0.7, speed = 0.7 },
	Error = { id = CLICK, volume = 0.5, speed = 0.6 },
} :: { [string]: SoundInfo }

return SoundData
