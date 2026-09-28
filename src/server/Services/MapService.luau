-- Builds the whole prison out of parts when the server starts. The layout lives in
-- Modules/MapLayout (shared with the client's lighting zones); the rooms are built by the
-- modules in ServerModules/Map:
--   Workspace.Lobby         the main hall (Cell Block 1), the cell wing, the mess hall, the yard
--   Workspace.Prison        the blocks you unlock, each behind a gate
--   Workspace.CellBlocks    one furnished cell per player (in the cell wing)
--   Workspace.RollMachines  one Brainrot Roller per block
--   Workspace.Leaderboards  four wall-mounted leaderboards
--   Workspace.Events        where event Brainrots appear

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Build = require(script.Parent.Parent.ServerModules.Build)
local Map = script.Parent.Parent.ServerModules.Map
local Blocks = require(Map.Blocks)
local Boards = require(Map.Boards)
local CellWing = require(Map.CellWing)
local Hall = require(Map.Hall)
local MessHall = require(Map.MessHall)
local RollMachine = require(Map.RollMachine)
local Themes = require(Map.Themes)
local Yard = require(Map.Yard)

export type Board = Boards.Board

local MapService = {}

MapService.cells = {} :: { Model }
MapService.boards = {} :: { [string]: Board }
MapService.kingCFrame = CFrame.new()
MapService.roamPoints = {} :: { Vector3 }
MapService.eventFolder = nil :: Folder?

function MapService.init()
	local lobby = Build.folder(workspace, "Lobby")
	local prison = Build.folder(workspace, "Prison")
	local cellFolder = Build.folder(workspace, "CellBlocks")
	local machines = Build.folder(workspace, "RollMachines")
	local boards = Build.folder(workspace, "Leaderboards")
	MapService.eventFolder = Build.folder(workspace, "Events")

	Hall.build(Build.folder(lobby, "MainHall"))
	MessHall.build(Build.folder(lobby, "MessHall"))
	local wing = Build.folder(lobby, "CellWing")
	MapService.cells = CellWing.build(wing)
	for _, cell in MapService.cells do
		cell.Parent = cellFolder
	end
	MapService.roamPoints = Yard.build(Build.folder(lobby, "Yard"))
	MapService.kingCFrame = Yard.KING
	MapService.boards = Boards.build(boards)

	for _, area in AreaData.Areas do
		local cframe = if area.order == 1 then Hall.MACHINE_CFRAME else Blocks.machineCFrame(area)
		RollMachine.build(machines, area, cframe, Themes[area.id].machine)
		if area.order > 1 then
			Blocks.build(prison, area)
		end
	end
end

return MapService
