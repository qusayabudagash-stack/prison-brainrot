-- Local-only changes to the world for this player:
--   * gates to blocks you've unlocked open (for you only - the server still checks unlocks when rolling)
--   * roll machine screens show YOUR discounted price, or LOCKED
--   * the featured Brainrots on top of the machines spin

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AreaData = require(ReplicatedStorage.Modules.AreaData)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local State = require(script.Parent.State)

local World = {}

local spinners: { [Model]: CFrame } = {}

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
	for _, descendant in gate:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "Collider" then
				descendant.CanCollide = not unlocked
				descendant.Transparency = if unlocked then 1 else 0.3
			elseif descendant.Name == "Bar" then
				descendant.Transparency = if unlocked then 1 else 0
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

local function addSpinner(instance: Instance)
	if instance:IsA("Model") then
		spinners[instance] = instance:GetPivot()
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

	for _, model in CollectionService:GetTagged("Spin") do
		addSpinner(model)
	end
	CollectionService:GetInstanceAddedSignal("Spin"):Connect(addSpinner)
	CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(instance)
		if instance:IsA("Model") then
			spinners[instance] = nil
		end
	end)
	RunService.RenderStepped:Connect(function()
		local angle = os.clock() * 0.9
		for model, base in spinners do
			if model.Parent then
				model:PivotTo(base * CFrame.Angles(0, angle, 0))
			else
				spinners[model] = nil
			end
		end
	end)
end

return World
