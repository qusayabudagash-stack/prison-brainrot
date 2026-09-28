--!nocheck
-- A small stand-in for the Roblox engine, built on Lune's `roblox` library, so the game's real
-- scripts can run outside Studio. It loads the place file Rojo builds, runs scripts from it, and
-- fills in what Lune doesn't provide: events, remotes, DataStores, Players, pivots, tweens and time.
--
-- Only used by the tests in this folder; nothing here ships with the game.

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Engine = {}
Engine.__index = Engine

---------------------------------------------------------------------------
-- Signals (RBXScriptSignal)
---------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handler = { fn = fn, connected = true }
	table.insert(self.handlers, handler)
	local connection = { Connected = true }
	function connection:Disconnect()
		handler.connected = false
		connection.Connected = false
	end
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	for _, handler in table.clone(self.handlers) do
		if handler.connected then
			task.spawn(handler.fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

Engine.Signal = Signal

local signals = {}
local function signalOf(instance, name)
	local perInstance = signals[instance]
	if not perInstance then
		perInstance = {}
		signals[instance] = perInstance
	end
	local signal = perInstance[name]
	if not signal then
		signal = Signal.new()
		perInstance[name] = signal
	end
	return signal
end
Engine.signalOf = signalOf

local function defineSignal(className, name)
	roblox.implementProperty(className, name, function(self)
		return signalOf(self, name)
	end)
end

---------------------------------------------------------------------------
-- Globals Lune lacks
---------------------------------------------------------------------------

local RandomMock = {}
RandomMock.__index = RandomMock
function RandomMock.new(_seed)
	return setmetatable({}, RandomMock)
end
function RandomMock:NextNumber(min, max)
	min = min or 0
	max = max or 1
	return min + (max - min) * math.random()
end
function RandomMock:NextInteger(min, max)
	return math.random(min, max)
end

-- Lune's CFrame.lookAt faces the opposite way to Roblox's; scripts get this corrected version.
local function lookAt(at, target, up)
	up = up or roblox.Vector3.new(0, 1, 0)
	local look = (target - at).Unit
	if math.abs(look:Dot(up)) > 0.9999 then
		up = roblox.Vector3.new(0, 0, 1)
	end
	local right = look:Cross(up).Unit
	local newUp = right:Cross(look).Unit
	return roblox.CFrame.fromMatrix(at, right, newUp, -look)
end
local CFrameFixed = setmetatable({ lookAt = lookAt }, { __index = roblox.CFrame })

local TweenInfoMock = {
	new = function(time, style, direction, repeatCount, reverses, delayTime)
		return {
			Time = time or 1,
			EasingStyle = style,
			EasingDirection = direction,
			RepeatCount = repeatCount or 0,
			Reverses = reverses or false,
			DelayTime = delayTime or 0,
		}
	end,
}

---------------------------------------------------------------------------
-- DataStores
---------------------------------------------------------------------------

local function checkStorable(value, path)
	local kind = type(value)
	if kind == "table" then
		local hasString, hasNumber, count = false, false, 0
		for key, child in value do
			count += 1
			if type(key) == "string" then
				hasString = true
			elseif type(key) == "number" then
				hasNumber = true
			else
				error(`DataStore value has a {type(key)} key at {path}`)
			end
			checkStorable(child, `{path}.{key}`)
		end
		if hasString and hasNumber then
			error(`DataStore value mixes array and dictionary keys at {path}`)
		end
		if hasNumber and count ~= #value then
			error(`DataStore array has holes at {path}`)
		end
	elseif kind ~= "string" and kind ~= "number" and kind ~= "boolean" then
		error(`DataStore value contains a {kind} at {path}`)
	elseif kind == "number" and (value ~= value or value == math.huge or value == -math.huge) then
		error(`DataStore value contains NaN/inf at {path}`)
	end
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end
	return copy
end

function Engine:newStore(name, ordered)
	self.storage[name] = self.storage[name] or {}
	local data = self.storage[name]
	local engine = self
	local store = {}

	local function call(method)
		engine.dataStoreCalls += 1
		task.wait()
		if engine.dataStoreFailures > 0 then
			error(`{method} failed: mock DataStore outage`)
		end
	end

	function store:UpdateAsync(key, transform)
		call("UpdateAsync")
		local current = deepCopy(data[key])
		local result = transform(current)
		if result ~= nil then
			checkStorable(result, key)
			data[key] = deepCopy(result)
			return deepCopy(result)
		end
		return current
	end
	function store:GetAsync(key)
		call("GetAsync")
		return deepCopy(data[key])
	end
	function store:SetAsync(key, value)
		call("SetAsync")
		checkStorable(value, key)
		if ordered then
			assert(
				type(value) == "number" and math.floor(value) == value,
				`OrderedDataStore needs integers, got {value}`
			)
		end
		data[key] = deepCopy(value)
	end
	function store:GetSortedAsync(ascending, pageSize)
		call("GetSortedAsync")
		local entries = {}
		for key, value in data do
			table.insert(entries, { key = key, value = value })
		end
		table.sort(entries, function(a, b)
			if ascending then
				return a.value < b.value
			end
			return a.value > b.value
		end)
		local page = {}
		for i = 1, math.min(pageSize, #entries) do
			page[i] = entries[i]
		end
		return {
			GetCurrentPage = function()
				return page
			end,
		}
	end
	return store
end

---------------------------------------------------------------------------
-- Engine methods Lune lacks, registered once
---------------------------------------------------------------------------

local current = nil -- the running Engine

local function installOnce()
	for _, pair in
		{
			{ "Players", "PlayerAdded" },
			{ "Players", "PlayerRemoving" },
			{ "Player", "CharacterAdded" },
			{ "ProximityPrompt", "Triggered" },
			{ "ProximityPromptService", "PromptTriggered" },
			{ "RemoteEvent", "OnServerEvent" },
			{ "RemoteEvent", "OnClientEvent" },
			{ "TextChatCommand", "Triggered" },
			{ "GuiObject", "InputBegan" },
			{ "GuiObject", "MouseEnter" },
			{ "GuiObject", "MouseLeave" },
			{ "GuiButton", "MouseButton1Down" },
			{ "GuiButton", "MouseButton1Up" },
			{ "GuiButton", "Activated" },
			{ "Sound", "Ended" },
			{ "RunService", "RenderStepped" },
			{ "RunService", "Heartbeat" },
			{ "UserInputService", "InputBegan" },
			{ "Instance", "DescendantAdded" },
			{ "Instance", "ChildAdded" },
		}
	do
		defineSignal(pair[1], pair[2])
	end

	roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(self, name)
		current:watchAttribute(self, name)
		return signalOf(self, "Attribute:" .. name)
	end)
	roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(self, name)
		return signalOf(self, "Property:" .. name)
	end)
	roblox.implementMethod("Instance", "WaitForChild", function(self, name, timeout)
		local started = os.clock()
		while true do
			local child = self:FindFirstChild(name)
			if child then
				return child
			end
			if timeout and os.clock() - started > timeout then
				return nil
			end
			task.wait(0.05)
		end
	end)

	roblox.implementMethod("DataModel", "BindToClose", function(_self, callback)
		table.insert(current.closeCallbacks, callback)
	end)
	roblox.implementProperty("DataModel", "JobId", function()
		return current.jobId
	end)

	roblox.implementMethod("RunService", "IsStudio", function()
		return current.studio
	end)
	roblox.implementMethod("RunService", "IsServer", function()
		return current.side == "server"
	end)
	roblox.implementMethod("RunService", "IsClient", function()
		return current.side == "client"
	end)
	roblox.implementMethod("RunService", "BindToRenderStep", function() end)
	roblox.implementMethod("RunService", "UnbindFromRenderStep", function() end)

	roblox.implementMethod("Workspace", "GetServerTimeNow", function()
		return current:now()
	end)

	roblox.implementMethod("DataStoreService", "GetDataStore", function(_self, name)
		return current:newStore(name, false)
	end)
	roblox.implementMethod("DataStoreService", "GetOrderedDataStore", function(_self, name)
		return current:newStore("Ordered:" .. name, true)
	end)

	roblox.implementMethod("Players", "GetPlayers", function()
		return table.clone(current.players)
	end)
	roblox.implementMethod("Players", "GetPlayerByUserId", function(_self, userId)
		for _, player in current.players do
			if player.UserId == userId then
				return player
			end
		end
		return nil
	end)
	roblox.implementMethod("Players", "GetNameFromUserIdAsync", function(_self, userId)
		return `Prisoner{userId}`
	end)
	roblox.implementProperty("Players", "LocalPlayer", function()
		return current.localPlayer
	end)
	roblox.implementMethod("Player", "Kick", function(self, message)
		current.kicks[self.UserId] = message or ""
		task.spawn(function()
			current:removePlayer(self)
		end)
	end)
	roblox.implementMethod("Player", "LoadCharacterAsync", function(self)
		current.respawns[self.UserId] = (current.respawns[self.UserId] or 0) + 1
	end)

	roblox.implementMethod("TweenService", "Create", function(_self, instance, _info, goals)
		local completed = Signal.new()
		return {
			Completed = completed,
			Play = function()
				for key, value in goals do
					instance[key] = value
				end
				completed:Fire()
			end,
			Cancel = function() end,
		}
	end)

	roblox.implementMethod("CollectionService", "AddTag", function(_self, instance, tag)
		instance:AddTag(tag)
	end)
	roblox.implementMethod("CollectionService", "GetTagged", function(_self, tag)
		local result = {}
		for _, descendant in current.game:GetDescendants() do
			if descendant:HasTag(tag) then
				table.insert(result, descendant)
			end
		end
		return result
	end)
	roblox.implementMethod("CollectionService", "GetInstanceAddedSignal", function(self, tag)
		return signalOf(self, "Added:" .. tag)
	end)
	roblox.implementMethod("CollectionService", "GetInstanceRemovedSignal", function(self, tag)
		return signalOf(self, "Removed:" .. tag)
	end)

	roblox.implementMethod("RemoteEvent", "FireClient", function(self, player, ...)
		current:recordClientEvent(self, player, ...)
	end)
	roblox.implementMethod("RemoteEvent", "FireAllClients", function(self, ...)
		current:recordClientEvent(self, nil, ...)
	end)
	roblox.implementMethod("RemoteEvent", "FireServer", function(self, ...)
		self.OnServerEvent:Fire(current.localPlayer, ...)
	end)
	local invokeHandlers = {}
	roblox.implementProperty("RemoteFunction", "OnServerInvoke", function(self)
		return invokeHandlers[self]
	end, function(self, handler)
		invokeHandlers[self] = handler
	end)
	roblox.implementMethod("RemoteFunction", "InvokeServer", function(self, ...)
		local handler = invokeHandlers[self]
		assert(handler, `No OnServerInvoke for {self.Name}`)
		return handler(current.localPlayer, ...)
	end)

	roblox.implementMethod("Sound", "Play", function() end)

	roblox.implementMethod("Model", "GetPivot", function(self)
		local primary = self.PrimaryPart
		if primary then
			return primary.CFrame * primary.PivotOffset
		end
		return self.WorldPivot
	end)
	roblox.implementMethod("Model", "PivotTo", function(self, target)
		local delta = target * self:GetPivot():Inverse()
		for _, descendant in self:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CFrame = delta * descendant.CFrame
			end
		end
		if not self.PrimaryPart then
			self.WorldPivot = target
		end
	end)
	roblox.implementMethod("Model", "ScaleTo", function(self, scale)
		local pivot = self:GetPivot()
		local primary = self.PrimaryPart
		for _, descendant in self:GetDescendants() do
			if descendant:IsA("BasePart") then
				local offset = pivot:ToObjectSpace(descendant.CFrame)
				descendant.Size *= scale
				descendant.CFrame = pivot * (offset.Rotation + offset.Position * scale)
			end
		end
		if primary then
			local offset = primary.PivotOffset
			primary.PivotOffset = offset.Rotation + offset.Position * scale
		end
	end)
end

---------------------------------------------------------------------------
-- Engine instance
---------------------------------------------------------------------------

export type Options = {
	placeFile: buffer | string,
	studio: boolean?,
	side: string?,
}

function Engine.new(placeData: string, options: { studio: boolean?, side: string? }?)
	local opts = options or {}
	if not current then
		current = true -- placeholder so installOnce's closures can read `current` later
		installOnce()
	end
	local self = setmetatable({}, Engine)
	current = self
	self.game = roblox.deserializePlace(placeData)
	self.game.JobId = "test-server"
	self.workspace = self.game:GetService("Workspace")
	self.Players = self.game:GetService("Players")
	self.ReplicatedStorage = self.game:GetService("ReplicatedStorage")
	self.camera = roblox.Instance.new("Camera")
	self.camera.ViewportSize = roblox.Vector2.new(1280, 720)
	self.camera.Parent = self.workspace
	self.workspace.CurrentCamera = self.camera
	self.studio = opts.studio == true
	self.side = opts.side or "server"
	self.jobId = "test-server"
	self.players = {}
	self.kicks = {}
	self.respawns = {}
	self.closeCallbacks = {}
	self.storage = {}
	self.dataStoreCalls = 0
	self.dataStoreFailures = 0
	self.clientEvents = {}
	self.warnings = {}
	self.modules = {}
	self.localPlayer = nil
	self.baseTime = os.time()
	self.baseClock = os.clock()
	self.timeOffset = 0
	self.watched = {}

	task.spawn(function()
		while current == self do
			self:pollAttributes()
			task.wait(0.03)
		end
	end)
	return self
end

function Engine:now()
	return self.baseTime + (os.clock() - self.baseClock) + self.timeOffset
end

function Engine:watchAttribute(instance, name)
	for _, entry in self.watched do
		if entry.instance == instance and entry.name == name then
			return
		end
	end
	table.insert(self.watched, { instance = instance, name = name, value = instance:GetAttribute(name) })
end

function Engine:pollAttributes()
	for _, entry in self.watched do
		local value = entry.instance:GetAttribute(entry.name)
		if value ~= entry.value then
			entry.value = value
			signalOf(entry.instance, "Attribute:" .. entry.name):Fire()
		end
	end
end

function Engine:recordClientEvent(remote, player, ...)
	local args = table.pack(...)
	table.insert(self.clientEvents, { name = remote.Name, player = player, args = args })
	if self.localPlayer and (player == nil or player == self.localPlayer) then
		remote.OnClientEvent:Fire(table.unpack(args, 1, args.n))
	end
end

function Engine:eventsNamed(name, player)
	local result = {}
	for _, event in self.clientEvents do
		if event.name == name and (player == nil or event.player == nil or event.player == player) then
			table.insert(result, event)
		end
	end
	return result
end

function Engine:environment(scriptInstance)
	local engine = self
	return {
		game = self.game,
		workspace = self.workspace,
		script = scriptInstance,
		require = function(module)
			return engine:require(module)
		end,
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrameFixed,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		Rect = roblox.Rect,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		TweenInfo = TweenInfoMock,
		Random = RandomMock,
		task = task,
		warn = function(...)
			local parts = table.pack(...)
			for i = 1, parts.n do
				parts[i] = tostring(parts[i])
			end
			local text = table.concat(parts, " ")
			table.insert(engine.warnings, text)
			print("  [warn] " .. text)
		end,
		os = {
			time = function()
				return math.floor(engine:now())
			end,
			clock = os.clock,
			date = os.date,
		},
	}
end

function Engine:require(module)
	local cached = self.modules[module]
	if cached then
		return cached.value
	end
	assert(module and module:IsA("ModuleScript"), `require expects a ModuleScript, got {module}`)
	local chunk = luau.load(module.Source, { debugName = module:GetFullName(), environment = self:environment(module) })
	local value = chunk()
	self.modules[module] = { value = value }
	return value
end

-- Runs a Script or LocalScript from the place, like the engine would.
function Engine:run(scriptInstance)
	local chunk = luau.load(scriptInstance.Source, {
		debugName = scriptInstance:GetFullName(),
		environment = self:environment(scriptInstance),
	})
	task.spawn(chunk)
end

function Engine:addPlayer(userId, name)
	local player = roblox.Instance.new("Player")
	player.Name = name
	player.DisplayName = name
	player.UserId = userId
	player.Parent = self.Players
	table.insert(self.players, player)
	self.Players.PlayerAdded:Fire(player)
	return player
end

function Engine:removePlayer(player)
	local index = table.find(self.players, player)
	if not index then
		return
	end
	table.remove(self.players, index)
	self.Players.PlayerRemoving:Fire(player)
	task.wait()
	player.Parent = nil
end

-- Makes `player` the local player and gives them a PlayerGui, so client scripts can run.
function Engine:attachClient(player)
	local playerGui = roblox.Instance.new("PlayerGui")
	playerGui.Name = "PlayerGui"
	playerGui.Parent = player
	self.localPlayer = player
	self.Players.LocalPlayer = player
	return playerGui
end

function Engine:invoke(player, name, ...)
	local remote = self.ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild(name)
	assert(remote, `No remote {name}`)
	local handler = remote.OnServerInvoke
	assert(handler, `No handler for {name}`)
	return handler(player, ...)
end

function Engine:fireServer(player, name, ...)
	local remote = self.ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild(name)
	remote.OnServerEvent:Fire(player, ...)
end

function Engine:shutdown()
	local running = #self.closeCallbacks
	for _, callback in self.closeCallbacks do
		task.spawn(function()
			callback()
			running -= 1
		end)
	end
	local started = os.clock()
	while running > 0 and os.clock() - started < 30 do
		task.wait(0.05)
	end
end

function Engine.waitUntil(condition: () -> boolean, timeout: number?, label: string?): boolean
	local started = os.clock()
	while not condition() do
		if os.clock() - started > (timeout or 5) then
			print(`\nFAIL  Timed out waiting for {label or "condition"}`)
			require("@lune/process").exit(1)
		end
		task.wait(0.02)
	end
	return true
end

return Engine
