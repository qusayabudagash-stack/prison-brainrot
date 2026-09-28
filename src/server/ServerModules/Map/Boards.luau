-- The physical leaderboards: wall-mounted screens in steel frames on the intake's north wall,
-- either side of the front doors. LeaderboardService fills in the rows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapLayout = require(ReplicatedStorage.Modules.MapLayout)
local Palette = require(script.Parent.Palette)
local Shapes = require(script.Parent.Shapes)

local Boards = {}

export type Board = {
	title: TextLabel,
	rows: { TextLabel },
}

local M = Enum.Material
local v3 = Vector3.new
local rgb = Color3.fromRGB

local WIDTH, HEIGHT = 13, 11
local SLOTS = { -31, -15.5, 15.5, 31 }

local function build(parent: Instance, id: string, titleText: string, x: number): Board
	local z = MapLayout.Hall.z2 - 0.4
	local s = Shapes.new(parent, CFrame.new(x, MapLayout.FLOOR_Y + 12.5, z))
	s:deco("BoardFrame", v3(WIDTH + 1, HEIGHT + 1, 0.6), CFrame.new(0, 0, 0.1), Palette.SteelDark, M.Metal)
	for _, y in { HEIGHT / 2 + 0.55, -HEIGHT / 2 - 0.55 } do
		s:glow("BoardTrim", v3(WIDTH + 1, 0.18, 0.7), CFrame.new(0, y, 0.05), Palette.Gold)
	end
	local board = s:deco(`Board_{id}`, v3(WIDTH, HEIGHT, 0.4), CFrame.new(0, 0, -0.2), rgb(22, 24, 38), M.SmoothPlastic)
	board.CastShadow = false
	s:deco("BoardMount", v3(0.6, 2, 0.8), CFrame.new(0, HEIGHT / 2 + 1.4, 0.2), Palette.SteelDark, M.Metal)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 200
	gui.Parent = board

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.fromScale(1, 0.15)
	header.BackgroundColor3 = rgb(40, 44, 70)
	header.BorderSizePixel = 0
	header.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Palette.Gold
	title.TextStrokeTransparency = 0.4
	title.Text = titleText
	title.Parent = header

	local list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.05, 0.18)
	list.Size = UDim2.fromScale(0.9, 0.8)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local rows = {}
	for rank = 1, GameConfig.LEADERBOARD.size do
		local row = Instance.new("TextLabel")
		row.Name = `Row{rank}`
		row.LayoutOrder = rank
		row.Size = UDim2.fromScale(1, 1 / GameConfig.LEADERBOARD.size)
		row.BackgroundColor3 = if rank % 2 == 0 then rgb(30, 33, 52) else rgb(22, 24, 38)
		row.BackgroundTransparency = 0
		row.BorderSizePixel = 0
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.RichText = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if rank == 1
			then Palette.Gold
			elseif rank == 2 then rgb(215, 220, 230)
			elseif rank == 3 then rgb(230, 160, 100)
			else Palette.White
		row.TextStrokeTransparency = 0.5
		row.Text = `#{rank}  ...`
		row.Parent = list
		table.insert(rows, row)
	end
	return { title = title, rows = rows }
end

function Boards.build(parent: Instance): { [string]: Board }
	local boards = {}
	for i, board in GameConfig.LEADERBOARD.boards do
		boards[board.id] = build(parent, board.id, board.title, SLOTS[i] or (i - 2.5) * 16)
	end
	return boards
end

return Boards
