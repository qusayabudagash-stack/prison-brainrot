-- Local-only changes to the world for this player:
--   * gates to blocks you've unlocked open (for you only - the server still checks unlocks when rolling):
--     the bars slide up into the frame the moment you unlock one
--   * roll machine screens show YOUR discounted price, or LOCKED
-- (Controllers/Animator spins the machines' featured Brainrots.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local State = require(script.Parent.State)

local World = {}

-- Gates we've already shown as open, so the slide only plays when a gate actually opens.
local opened: { [Model]: boolean } = {}
local seen: { [Model]: boolean } = {}

local function findGate(instance: Instance): Model?
	local current: Instance? = instance
	while current and current ~= workspace do
		if current:IsA("Model") and current.Name == "Gate" and current:GetAttribute("AreaId") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function applyGate(gate: Model)
	local areaId = gate:GetAttribute("AreaId")
	local area = if typeof(areaId) == "string" then AreaData.ById[areaId] else nil
	local data = State.data()
	if not area or not data then
		return
	end
	local unlocked = data.unlockedAreas[area.id] == true
	-- Slide the bars up only if we watched this gate go from locked to unlocked
	local animate = unlocked and seen[gate] == true and not opened[gate]
	seen[gate] = true
	if unlocked then
		opened[gate] = true
	end
	for _, descendant in gate:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "Collider" then
				descendant.CanCollide = not unlocked
				descendant.Transparency = if unlocked then 1 else 0.3
			elseif descendant.Name == "Bar" then
				if animate then
					local goal = descendant.CFrame + Vector3.new(0, 12, 0)
					local slide =
						TweenService:Create(descendant, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { CFrame = goal })
					slide:Play()
					slide.Completed:Connect(function()
						descendant.Transparency = 1
					end)
				else
					descendant.Transparency = if unlocked then 1 else 0
				end
			end
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = not unlocked
		elseif
			descendant:IsA("TextLabel")
			and descendant.Parent
			and descendant.Parent.Parent
			and descendant.Parent.Parent.Name == "Sign"
		then
			descendant.Text = if unlocked
				then `{area.emoji} {area.name}\n✅ OPEN`
				else `{area.emoji} {area.name}\n🔒 {Format.money(area.unlockCost)}`
		end
	end
end

local function applyMachine(machine: Instance)
	local areaId = machine:GetAttribute("AreaId")
	local area = if typeof(areaId) == "string" then AreaData.ById[areaId] else nil
	local data = State.data()
	if not area or not data then
		return
	end
	local unlocked = data.unlockedAreas[area.id] == true
	local cost = Formulas.rollCost(data, area)
	local screen = machine:FindFirstChild("ScreenText", true)
	if screen and screen:IsA("TextLabel") then
		screen.Text = if unlocked
			then `🎰 BRAINROT ROLL\nCost: {Format.money(cost)}\n🍀 Block Luck: {Format.multiplier(area.luck)}`
			else `🔒 LOCKED\nUnlock for {Format.money(area.unlockCost)}\n🍀 Block Luck: {Format.multiplier(
				area.luck
			)}`
	end
	local prompt = machine:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.ObjectText = `🎰 {area.name} - {Format.money(cost)}`
	end
end

local function applyAll()
	local prison = workspace:FindFirstChild("Prison")
	if prison then
		for _, descendant in prison:GetDescendants() do
			if descendant:IsA("Model") and descendant.Name == "Gate" then
				applyGate(descendant)
			end
		end
	end
	local machines = workspace:FindFirstChild("RollMachines")
	if machines then
		for _, machine in machines:GetChildren() do
			applyMachine(machine)
		end
	end
end

function World.init()
	State.Changed:Connect(applyAll)

	-- With streaming, parts can arrive after the data does, so re-apply when they show up.
	task.spawn(function()
		local prison = workspace:WaitForChild("Prison", 30)
		if prison then
			prison.DescendantAdded:Connect(function(descendant)
				local gate = findGate(descendant)
				if gate then
					applyGate(gate)
				end
			end)
		end
		local machines = workspace:WaitForChild("RollMachines", 30)
		if machines then
			machines.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("TextLabel") or descendant:IsA("ProximityPrompt") then
					for _, machine in machines:GetChildren() do
						if descendant:IsDescendantOf(machine) then
							applyMachine(machine)
							break
						end
					end
				end
			end)
		end
		applyAll()
	end)
end

return World
