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
		ambient = rgb(128, 122, 116),
		outdoorAmbient = rgb(140, 138, 146),
		brightness = 2.4,
		exposure = 0.1,
		tint = rgb(255, 249, 240),
		saturation = 0.06,
		contrast = 0.08,
		haze = 0.6,
		density = 0.22,
		atmosphere = rgb(206, 196, 184),
		bloom = 0.9,
	},
	CellWing = {
		ambient = rgb(104, 110, 122),
		outdoorAmbient = rgb(120, 126, 140),
		brightness = 2.2,
		exposure = 0,
		tint = rgb(242, 246, 255),
		saturation = -0.04,
		contrast = 0.1,
		haze = 0.8,
		density = 0.25,
		atmosphere = rgb(180, 188, 200),
		bloom = 0.8,
	},
	MessHall = {
		ambient = rgb(136, 126, 110),
		outdoorAmbient = rgb(146, 140, 130),
		brightness = 2.4,
		exposure = 0.1,
		tint = rgb(255, 246, 228),
		saturation = 0.08,
		contrast = 0.06,
		haze = 0.6,
		density = 0.22,
		atmosphere = rgb(210, 196, 170),
		bloom = 0.8,
	},
	Yard = {
		ambient = rgb(118, 118, 128),
		outdoorAmbient = rgb(150, 150, 162),
		brightness = 3,
		exposure = 0.05,
		tint = rgb(255, 255, 250),
		saturation = 0.12,
		contrast = 0.08,
		haze = 1.2,
		density = 0.28,
		atmosphere = rgb(200, 214, 230),
		bloom = 0.7,
	},
	CellBlock2 = {
		ambient = rgb(98, 108, 132),
		outdoorAmbient = rgb(118, 126, 150),
		brightness = 2.2,
		exposure = 0,
		tint = rgb(236, 243, 255),
		saturation = 0,
		contrast = 0.1,
		haze = 0.8,
		density = 0.26,
		atmosphere = rgb(170, 186, 214),
		bloom = 0.9,
	},
	MaxSecurity = {
		ambient = rgb(96, 94, 100),
		outdoorAmbient = rgb(112, 110, 118),
		brightness = 2,
		exposure = -0.05,
		tint = rgb(255, 238, 236),
		saturation = -0.08,
		contrast = 0.18,
		haze = 1,
		density = 0.3,
		atmosphere = rgb(160, 150, 150),
		bloom = 1,
	},
	DeathRow = {
		ambient = rgb(78, 90, 84),
		outdoorAmbient = rgb(92, 104, 98),
		brightness = 1.8,
		exposure = -0.1,
		tint = rgb(226, 255, 232),
		saturation = -0.14,
		contrast = 0.16,
		haze = 2,
		density = 0.42,
		atmosphere = rgb(120, 150, 120),
		bloom = 1.1,
	},
	AlienBlock = {
		ambient = rgb(76, 108, 110),
		outdoorAmbient = rgb(90, 124, 126),
		brightness = 2,
		exposure = 0,
		tint = rgb(222, 255, 246),
		saturation = 0.12,
		contrast = 0.12,
		haze = 1.4,
		density = 0.34,
		atmosphere = rgb(120, 200, 180),
		bloom = 1.2,
	},
	SecretBlock = {
		ambient = rgb(70, 56, 102),
		outdoorAmbient = rgb(80, 64, 116),
		brightness = 1.6,
		exposure = 0,
		tint = rgb(242, 224, 255),
		saturation = 0.22,
		contrast = 0.14,
		haze = 1.6,
		density = 0.38,
		atmosphere = rgb(120, 90, 180),
		bloom = 1.5,
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
