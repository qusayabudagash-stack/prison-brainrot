-- Where everything in the prison is, and how each part of it feels. The server builds the map
-- from these bounds; the client uses the zones to blend lighting as you walk between rooms.
--
--   Main hall   x -40..40,  z -60..76   intake + checkpoint (north), roll hall (south)
--   Cell wing   x -104..-40             the player cells, west of the hall
--   Mess hall   x 40..96,   z -10..60   cafeteria, east of the hall
--   Yard        x 40..200,  z -60..64   outdoors, around the mess hall
--   Blocks      100 x 80 studs each, one after another toward -Z, starting at z = -60

local AreaData = require(script.Parent.AreaData)

local MapLayout = {}

export type Box = { x1: number, x2: number, z1: number, z2: number, height: number }

export type Mood = {
	ambient: Color3,
	outdoorAmbient: Color3,
	brightness: number,
	exposure: number,
	tint: Color3,
	saturation: number,
	contrast: number,
	haze: number,
	density: number,
	atmosphere: Color3,
	bloom: number,
}

export type Zone = { id: string, min: Vector3, max: Vector3, mood: string }

MapLayout.FLOOR_Y = 1

MapLayout.Hall = { x1 = -40, x2 = 40, z1 = -60, z2 = 76, height = 34 } :: Box
MapLayout.CHECKPOINT_Z = 34
MapLayout.CellWing = { x1 = -104, x2 = -40, z1 = -60, z2 = 60, height = 24 } :: Box
MapLayout.MessHall = { x1 = 40, x2 = 96, z1 = -10, z2 = 60, height = 24 } :: Box
MapLayout.Yard = { x1 = 40, x2 = 200, z1 = -60, z2 = 64, height = 0 } :: Box

MapLayout.BLOCK_LENGTH = 80
MapLayout.BLOCK_HALF_WIDTH = 50
MapLayout.BLOCK_HEIGHT = 30

-- North (entrance) and south (far) z of a prison block, and its half width. Block 1 is the main hall.
function MapLayout.blockBounds(order: number): (number, number, number)
	if order == 1 then
		return MapLayout.Hall.z2, MapLayout.Hall.z1, MapLayout.Hall.x2
	end
	local zStart = MapLayout.Hall.z1 - (order - 2) * MapLayout.BLOCK_LENGTH
	return zStart, zStart - MapLayout.BLOCK_LENGTH, MapLayout.BLOCK_HALF_WIDTH
end

local rgb = Color3.fromRGB

MapLayout.Moods = {
	Hall = {
		ambient = rgb(118, 112, 110),
		outdoorAmbient = rgb(138, 136, 142),
		brightness = 2.6,
		exposure = 0.12,
		tint = rgb(255, 248, 238),
		saturation = 0.14,
		contrast = 0.12,
		haze = 0.25,
		density = 0.16,
		atmosphere = rgb(214, 204, 190),
		bloom = 0.55,
	},
	CellWing = {
		ambient = rgb(110, 114, 126),
		outdoorAmbient = rgb(126, 130, 142),
		brightness = 2.4,
		exposure = 0.08,
		tint = rgb(248, 248, 255),
		saturation = 0.1,
		contrast = 0.12,
		haze = 0.3,
		density = 0.18,
		atmosphere = rgb(196, 200, 210),
		bloom = 0.5,
	},
	MessHall = {
		ambient = rgb(126, 116, 104),
		outdoorAmbient = rgb(146, 140, 130),
		brightness = 2.6,
		exposure = 0.12,
		tint = rgb(255, 244, 226),
		saturation = 0.14,
		contrast = 0.1,
		haze = 0.25,
		density = 0.16,
		atmosphere = rgb(214, 200, 176),
		bloom = 0.5,
	},
	Yard = {
		ambient = rgb(120, 120, 130),
		outdoorAmbient = rgb(156, 156, 166),
		brightness = 3.2,
		exposure = 0.05,
		tint = rgb(255, 252, 244),
		saturation = 0.16,
		contrast = 0.1,
		haze = 0.7,
		density = 0.2,
		atmosphere = rgb(200, 216, 234),
		bloom = 0.45,
	},
	CellBlock2 = {
		ambient = rgb(100, 110, 136),
		outdoorAmbient = rgb(118, 128, 152),
		brightness = 2.4,
		exposure = 0.05,
		tint = rgb(238, 244, 255),
		saturation = 0.1,
		contrast = 0.12,
		haze = 0.35,
		density = 0.2,
		atmosphere = rgb(176, 192, 222),
		bloom = 0.6,
	},
	MaxSecurity = {
		ambient = rgb(100, 96, 100),
		outdoorAmbient = rgb(116, 112, 118),
		brightness = 2.2,
		exposure = 0,
		tint = rgb(255, 238, 234),
		saturation = 0.02,
		contrast = 0.18,
		haze = 0.5,
		density = 0.24,
		atmosphere = rgb(170, 156, 156),
		bloom = 0.7,
	},
	DeathRow = {
		ambient = rgb(84, 96, 90),
		outdoorAmbient = rgb(98, 110, 104),
		brightness = 2.0,
		exposure = -0.02,
		tint = rgb(232, 255, 236),
		saturation = 0,
		contrast = 0.16,
		haze = 1.2,
		density = 0.32,
		atmosphere = rgb(130, 160, 130),
		bloom = 0.8,
	},
	AlienBlock = {
		ambient = rgb(80, 112, 116),
		outdoorAmbient = rgb(94, 128, 130),
		brightness = 2.2,
		exposure = 0.02,
		tint = rgb(226, 255, 248),
		saturation = 0.16,
		contrast = 0.12,
		haze = 0.9,
		density = 0.28,
		atmosphere = rgb(126, 204, 186),
		bloom = 0.9,
	},
	SecretBlock = {
		ambient = rgb(76, 62, 108),
		outdoorAmbient = rgb(86, 70, 122),
		brightness = 1.9,
		exposure = 0.02,
		tint = rgb(244, 228, 255),
		saturation = 0.24,
		contrast = 0.14,
		haze = 1.1,
		density = 0.3,
		atmosphere = rgb(128, 96, 190),
		bloom = 1.1,
	},
} :: { [string]: Mood }

-- Checked in order; the first zone containing you wins. Anything else uses the Yard mood.
MapLayout.Zones = {} :: { Zone }

local function zone(id: string, box: Box, mood: string)
	table.insert(MapLayout.Zones, {
		id = id,
		min = Vector3.new(box.x1, -10, box.z1),
		max = Vector3.new(box.x2, 80, box.z2),
		mood = mood,
	})
end

zone("Hall", MapLayout.Hall, "Hall")
zone("CellWing", MapLayout.CellWing, "CellWing")
zone("MessHall", MapLayout.MessHall, "MessHall")
for _, area in AreaData.Areas do
	if area.order > 1 then
		local zStart, zEnd, halfWidth = MapLayout.blockBounds(area.order)
		local box = { x1 = -halfWidth, x2 = halfWidth, z1 = zEnd, z2 = zStart, height = MapLayout.BLOCK_HEIGHT }
		zone(area.id, box, if MapLayout.Moods[area.id] then area.id else "Hall")
	end
end
zone("Yard", MapLayout.Yard, "Yard")

function MapLayout.zoneAt(position: Vector3): Zone?
	for _, entry in MapLayout.Zones do
		local min, max = entry.min, entry.max
		if position.X >= min.X and position.X <= max.X and position.Z >= min.Z and position.Z <= max.Z then
			return entry
		end
	end
	return nil
end

return MapLayout
