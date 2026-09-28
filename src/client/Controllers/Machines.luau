-- Keeps the prison moving: the roll machines' chase lights, pulsing juice pipes and beacons, the
-- lever pull and rarity flash whenever someone rolls, plus blinking alarms, flickering lights,
-- sweeping searchlights, spinning disco balls and floating crystals.
--
-- Everything here is found by name or attribute (see ServerModules/Map), so the server only has
-- to build the parts: Bulb (Index), PipeCore, TankLiquid, Beacon, Lever (Pivot) inside machines;
-- Blink, Flicker, Spin, Float and Sweep attributes anywhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local Net = require(ReplicatedStorage.Modules.Net)

local Machines = {}

type Machine = {
	model: Model,
	bulbs: { BasePart },
	pipes: { BasePart },
	beacon: BasePart?,
	lever: { BasePart },
	leverBase: { CFrame },
	leverPivot: Vector3?,
	glow: Color3,
	rollingUntil: number,
	flash: Color3?,
}

local machines: { [string]: Machine } = {}
local BULB_ON = Color3.fromRGB(255, 236, 190)
local BULB_OFF = Color3.fromRGB(120, 96, 60)
local RAINBOW = {
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(255, 170, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(90, 230, 120),
	Color3.fromRGB(70, 170, 255),
	Color3.fromRGB(180, 100, 255),
}

-- Props animated by attribute
local blinkers: { BasePart } = {}
local spinners: { [BasePart]: CFrame } = {}
local floaters: { [BasePart]: CFrame } = {}
local sweepers: { [Model]: { parts: { BasePart }, base: { CFrame }, pivot: Vector3 } } = {}
local flickers: { Instance } = {}

local function addMachine(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local areaId = model:GetAttribute("AreaId")
	if typeof(areaId) ~= "string" then
		return
	end
	local machine: Machine = {
		model = model,
		bulbs = {},
		pipes = {},
		beacon = nil,
		lever = {},
		leverBase = {},
		leverPivot = nil,
		glow = Color3.new(1, 1, 1),
		rollingUntil = 0,
		flash = nil,
	}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "Bulb" then
				table.insert(machine.bulbs, part)
			elseif part.Name == "PipeCore" or part.Name == "TankLiquid" then
				table.insert(machine.pipes, part)
			elseif part.Name == "Beacon" then
				machine.beacon = part
				machine.glow = part.Color
			end
		end
	end
	table.sort(machine.bulbs, function(a, b)
		return ((a:GetAttribute("Index") :: number?) or 0) < ((b:GetAttribute("Index") :: number?) or 0)
	end)
	local lever = model:FindFirstChild("Lever")
	if lever then
		local pivot = lever:GetAttribute("Pivot")
		if typeof(pivot) == "Vector3" then
			machine.leverPivot = pivot
		end
		for _, part in lever:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(machine.lever, part)
				table.insert(machine.leverBase, part.CFrame)
			end
		end
	end
	machines[areaId] = machine
end

local function pullLever(machine: Machine)
	local pivot = machine.leverPivot
	if not pivot then
		return
	end
	local frame = machine.model:GetPivot()
	local axis = frame.RightVector
	for i, part in machine.lever do
		local base = machine.leverBase[i]
		local pulled = CFrame.new(pivot) * CFrame.fromAxisAngle(axis, math.rad(55)) * CFrame.new(-pivot) * base
		local down = TweenService:Create(
			part,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = pulled }
		)
		down:Play()
		down.Completed:Connect(function()
			TweenService:Create(part, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { CFrame = base }):Play()
		end)
	end
end

local function burst(machine: Machine, color: Color3)
	local beacon = machine.beacon
	if not beacon then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.8, 0)
	emitter.Parent = beacon
	emitter:Emit(40)
	task.delay(2, function()
		emitter:Destroy()
	end)
end

local function onMachineRoll(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.areaId) ~= "string" then
		return
	end
	local machine = machines[payload.areaId]
	if not machine then
		return
	end
	local duration = if typeof(payload.duration) == "number" then payload.duration else 3
	machine.rollingUntil = os.clock() + duration
	machine.flash = nil
	pullLever(machine)
	local rarity = if typeof(payload.rarity) == "string" then BrainrotData.RarityById[payload.rarity] else nil
	task.delay(duration, function()
		if rarity then
			machine.flash = rarity.color
			burst(machine, rarity.color)
			task.delay(2.5, function()
				machine.flash = nil
			end)
		end
	end)
end

local function updateMachine(machine: Machine, now: number)
	local rolling = now < machine.rollingUntil
	local count = #machine.bulbs
	if count > 0 then
		local speed = if rolling then 18 else 5
		local head = math.floor(now * speed) % count
		for i, bulb in machine.bulbs do
			if rolling then
				bulb.Color = RAINBOW[(i + math.floor(now * 12)) % #RAINBOW + 1]
			elseif machine.flash then
				bulb.Color = if math.floor(now * 8) % 2 == 0 then machine.flash else BULB_ON
			else
				local lit = (i - 1 - head) % 4 == 0 or (i - 1 - head) % 4 == 1
				bulb.Color = if lit then BULB_ON else BULB_OFF
			end
		end
	end
	for i, pipe in machine.pipes do
		local rate = if rolling then 12 else 3
		pipe.Transparency = 0.15 + 0.3 * (0.5 + 0.5 * math.sin(now * rate + i))
	end
	local beacon = machine.beacon
	if beacon then
		if machine.flash then
			beacon.Color = machine.flash
		elseif rolling then
			beacon.Color = RAINBOW[math.floor(now * 10) % #RAINBOW + 1]
		else
			beacon.Color = machine.glow:Lerp(Color3.new(1, 1, 1), 0.3 + 0.3 * math.sin(now * 2))
		end
	end
end

---------------------------------------------------------------------------
-- Props
---------------------------------------------------------------------------

local function addProp(instance: Instance)
	if instance:IsA("BasePart") then
		if instance:GetAttribute("Blink") then
			table.insert(blinkers, instance)
		end
		if instance:GetAttribute("Spin") then
			spinners[instance] = instance.CFrame
		end
		if instance:GetAttribute("Float") then
			floaters[instance] = instance.CFrame
		end
		if instance:GetAttribute("Sweep") then
			local model = instance.Parent
			if model and model:IsA("Model") and not sweepers[model] then
				local parts, base = {}, {}
				for _, part in model:GetChildren() do
					if part:IsA("BasePart") and (part.Name == "Searchlight" or part.Name == "SearchlightLens") then
						table.insert(parts, part)
						table.insert(base, part.CFrame)
					end
				end
				sweepers[model] = { parts = parts, base = base, pivot = instance.CFrame.Position }
			end
		end
	elseif instance:IsA("Model") and instance:GetAttribute("Flicker") then
		table.insert(flickers, instance)
	end
end

local function updateProps(now: number, dt: number)
	local blinkOn = math.floor(now * 1.6) % 2 == 0
	for i = #blinkers, 1, -1 do
		local part = blinkers[i]
		if not part.Parent then
			table.remove(blinkers, i)
		else
			part.Transparency = if blinkOn then 0 else 0.75
		end
	end
	for part, base in spinners do
		if not part.Parent then
			spinners[part] = nil
		else
			-- Discs spin in their own plane (a cylinder's axis is its X)
			local disc = part:IsA("Part") and (part :: Part).Shape == Enum.PartType.Cylinder
			part.CFrame = base * (if disc then CFrame.Angles(now * 0.8, 0, 0) else CFrame.Angles(0, now * 0.8, 0))
		end
	end
	for part, base in floaters do
		if not part.Parent then
			floaters[part] = nil
		else
			local seed = base.Position.X
			part.CFrame = base
				* CFrame.new(0, math.sin(now * 1.3 + seed) * 0.8, 0)
				* CFrame.Angles(now * 0.5, now * 0.7, 0)
		end
	end
	for model, sweep in sweepers do
		if not model.Parent then
			sweepers[model] = nil
		else
			local yaw = CFrame.Angles(0, math.sin(now * 0.4 + sweep.pivot.X) * 0.7, 0)
			for i, part in sweep.parts do
				part.CFrame = CFrame.new(sweep.pivot) * yaw * CFrame.new(-sweep.pivot) * sweep.base[i]
			end
		end
	end
	-- Flickering lights: now and then a tube cuts out for a moment
	for _, lamp in flickers do
		local tube = lamp:FindFirstChild("Tube")
		if tube and tube:IsA("BasePart") then
			local off = math.random() < dt * 0.8
			if off then
				tube.Transparency = 0.8
				local light = tube:FindFirstChildWhichIsA("Light")
				if light then
					light.Enabled = false
				end
				task.delay(0.06 + math.random() * 0.12, function()
					tube.Transparency = 0
					if light then
						light.Enabled = true
					end
				end)
			end
		end
	end
end

function Machines.init()
	task.spawn(function()
		local folder = workspace:WaitForChild("RollMachines", 30)
		if folder then
			for _, model in folder:GetChildren() do
				addMachine(model)
			end
			folder.ChildAdded:Connect(function(model)
				task.defer(addMachine, model)
			end)
		end
	end)
	for _, instance in workspace:GetDescendants() do
		addProp(instance)
	end
	workspace.DescendantAdded:Connect(addProp)
	Net.event("Effect").OnClientEvent:Connect(function(effect, payload)
		if effect == "MachineRoll" then
			onMachineRoll(payload)
		end
	end)

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 1 / 20 then
			return
		end
		local elapsed = accumulated
		accumulated = 0
		local now = os.clock()
		for _, machine in machines do
			if machine.model.Parent then
				updateMachine(machine, now)
			end
		end
		updateProps(now, elapsed)
	end)
end

return Machines
