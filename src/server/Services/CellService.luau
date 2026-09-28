-- Gives every player a cell showing their name, their best Brainrots and the cosmetics they bought.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Build = require(script.Parent.Parent.ServerModules.Build)
local CosmeticBuilder = require(script.Parent.Parent.ServerModules.CosmeticBuilder)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapService = require(script.Parent.MapService)
local Types = require(ReplicatedStorage.Modules.Types)

local CellService = {}

local assigned: { [Player]: Model } = {}
local refreshToken: { [Player]: number } = {}

local function clearChildren(folder: Instance?)
	if folder then
		folder:ClearAllChildren()
	end
end

local function setOwnerText(cell: Model, text: string)
	local sign = cell:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("OwnerText", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Best distinct Brainrots (by income) for the pedestals.
local function bestForDisplay(data: Types.PlayerData): { Formulas.Stack }
	local result = {}
	for _, stack in Formulas.stacks(data) do
		table.insert(result, stack)
		if #result >= GameConfig.CELL_DISPLAY_COUNT then
			break
		end
	end
	return result
end

local function refresh(player: Player)
	local cell = assigned[player]
	local data = DataService.get(player)
	if not cell or not data then
		return
	end

	setOwnerText(cell, `🧠 {string.upper(player.DisplayName)}'S CELL`)

	local displays = cell:FindFirstChild("Displays")
	clearChildren(displays)
	local best = bestForDisplay(data)
	for index, stack in best do
		local anchor = cell:FindFirstChild(`Display{index}`)
		if anchor and anchor:IsA("BasePart") and displays then
			-- Fit every Brainrot on its pedestal, from a small Common to a long Divine shark
			local bounds = BrainrotModel.bounds(stack.id)
			local scale = math.min(0.85, 4.8 / math.max(bounds.X, 1), 5.6 / math.max(bounds.Y, 1))
			local model = BrainrotModel.build(stack.id, { variant = stack.variant, scale = scale })
			model:PivotTo(anchor.CFrame)
			model.Parent = displays
			local body = model:FindFirstChild("Body")
			if body and body:IsA("BasePart") then
				local rarity = BrainrotData.getRarity(stack.id)
				Build.billboard(
					body,
					`{BrainrotData.displayName(stack.id, stack.variant)}\n<font color="#{rarity.color:ToHex()}">{rarity.name}</font> • +{Format.money(
						stack.income
					)}/s`,
					Vector2.new(7, 1.8),
					BrainrotModel.labelOffset(model, 1.1)
				)
			end
		end
	end

	CosmeticBuilder.apply(cell, data.cosmetics, if best[1] then best[1].id else nil)
end

-- Batches refreshes. After a roll, waits until the reveal animation is over so the cell doesn't spoil it.
local function scheduleRefresh(player: Player, delaySeconds: number)
	local token = (refreshToken[player] or 0) + 1
	refreshToken[player] = token
	task.delay(delaySeconds, function()
		if refreshToken[player] == token then
			refresh(player)
		end
	end)
end

local function assign(player: Player)
	if assigned[player] then
		return
	end
	for _, cell in MapService.cells do
		if cell:GetAttribute("OwnerId") == 0 then
			cell:SetAttribute("OwnerId", player.UserId)
			assigned[player] = cell
			refresh(player)
			return
		end
	end
end

local function unassign(player: Player)
	local cell = assigned[player]
	assigned[player] = nil
	refreshToken[player] = nil
	if cell then
		cell:SetAttribute("OwnerId", 0)
		setOwnerText(cell, "🔓 EMPTY CELL")
		clearChildren(cell:FindFirstChild("Displays"))
		CosmeticBuilder.apply(cell, {})
	end
end

function CellService.getCell(player: Player): Model?
	return assigned[player]
end

function CellService.init()
	DataService.Loaded:Connect(assign)
	DataService.Changed:Connect(function(player, _data, reason)
		if reason == "roll" then
			scheduleRefresh(player, 6)
		elseif reason == "brainrots" or reason == "cosmetics" or reason == "rebirth" then
			scheduleRefresh(player, 0.2)
		end
	end)
	Players.PlayerRemoving:Connect(unassign)
end

return CellService
