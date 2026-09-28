-- Random server-wide events every few minutes:
--   DOUBLE INCOME, LUCKY HOUR and CRAZY ROLLS change multipliers (see Modules/Events).
--   PRISON KING puts a giant golden King in Cell Block 1 who gives each player a free 3x lucky roll.
--   ESCAPED BRAINROTS sends giant Brainrots wandering around Cell Block 1; catch them for coins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnnouncementService = require(script.Parent.AnnouncementService)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)
local Build = require(script.Parent.Parent.ServerModules.Build)
local EconomyService = require(script.Parent.EconomyService)
local Events = require(ReplicatedStorage.Modules.Events)
local Format = require(ReplicatedStorage.Modules.Format)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local MapService = require(script.Parent.MapService)
local RollService = require(script.Parent.RollService)

local EventService = {}

local CONFIG = GameConfig.EVENTS
local rng = Random.new()
local running = false

local function setEvent(id: string?, endsAt: number)
	ReplicatedStorage:SetAttribute("EventEndsAt", endsAt)
	ReplicatedStorage:SetAttribute("EventId", id or "")
end

local function pickEvent(): Events.EventInfo
	local total = 0
	for _, event in CONFIG.list do
		total += event.weight
	end
	local pick = rng:NextNumber() * total
	for _, event in CONFIG.list do
		if pick < event.weight then
			return event
		end
		pick -= event.weight
	end
	return CONFIG.list[1]
end

local function addPrompt(part: BasePart, actionText: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 22
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function spawnPrisonKing(): () -> ()
	local model = BrainrotModel.build("TungTungTungSahur", { variant = "Golden", scale = 2.6, crowned = true })
	model.Name = "EventPrisonKing"
	model:PivotTo(MapService.kingCFrame)
	model.Parent = MapService.eventFolder

	local body = model:FindFirstChild("Body") :: BasePart
	Build.billboard(
		body,
		"👑 THE PRISON KING 👑\nFree 3x lucky roll!",
		Vector2.new(16, 4),
		BrainrotModel.labelOffset(model, 3),
		Color3.fromRGB(255, 220, 60)
	)
	local prompt = addPrompt(body, "Get a lucky roll!", "👑 Prison King")

	local claimed: { [Player]: boolean } = {}
	prompt.Triggered:Connect(function(player)
		if claimed[player] then
			AnnouncementService.notify(player, "👑 The King already gave you a gift!", "error")
			return
		end
		claimed[player] = true
		RollService.grantFreeRoll(player, CONFIG.prisonKingLuck, "PrisonKing")
	end)

	return function()
		model:Destroy()
	end
end

-- Walks a welded Brainrot model between random points until it is caught or the event ends.
local function wander(model: Model, root: BasePart)
	task.spawn(function()
		while model.Parent do
			local target = MapService.roamPoints[rng:NextInteger(1, #MapService.roamPoints)]
			local from = model:GetPivot().Position
			local flatTarget = Vector3.new(target.X, from.Y, target.Z)
			if (flatTarget - from).Magnitude > 1 then
				local pivot = CFrame.lookAt(from, flatTarget)
				local goal = CFrame.lookAt(flatTarget, flatTarget + pivot.LookVector) * root.PivotOffset:Inverse()
				root.CFrame = pivot * root.PivotOffset:Inverse()
				local duration = (flatTarget - from).Magnitude / 10
				TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = goal }):Play()
				task.wait(duration)
			end
			task.wait(rng:NextNumber(0.2, 1))
		end
	end)
end

local function spawnEscapees(): () -> ()
	local models: { Model } = {}
	local pool = {}
	for _, brainrot in BrainrotData.Brainrots do
		if brainrot.rarity ~= "Secret" then
			table.insert(pool, brainrot)
		end
	end

	for _ = 1, CONFIG.escapedCount do
		local brainrot = pool[rng:NextInteger(1, #pool)]
		local model = BrainrotModel.build(brainrot.id, { scale = 2.5, welded = true })
		model.Name = "Escaped" .. brainrot.id
		local start = MapService.roamPoints[rng:NextInteger(1, #MapService.roamPoints)]
		model:PivotTo(CFrame.new(start))
		model.Parent = MapService.eventFolder
		table.insert(models, model)

		local body = model:FindFirstChild("Body") :: BasePart
		local root = model.PrimaryPart :: BasePart
		Build.billboard(
			body,
			`💀 ESCAPED!\n{brainrot.name}`,
			Vector2.new(10, 3),
			BrainrotModel.labelOffset(model, 2.5),
			Color3.fromRGB(255, 120, 120)
		)
		local prompt = addPrompt(body, "Catch!", `Escaped {brainrot.name}`)

		prompt.Triggered:Connect(function(player)
			if not model.Parent then
				return
			end
			local reward = math.max(
				CONFIG.escapedMinReward,
				math.floor(EconomyService.getIncome(player) * CONFIG.escapedRewardSeconds)
			)
			EconomyService.add(player, reward)
			AnnouncementService.floatText(body.CFrame.Position, `+{Format.money(reward)}`)
			AnnouncementService.notify(
				player,
				`💀 You caught the escaped {brainrot.name}! +{Format.money(reward)}`,
				"success"
			)
			model:Destroy()
		end)

		wander(model, root)
	end

	return function()
		for _, model in models do
			model:Destroy()
		end
	end
end

local function runEvent(event: Events.EventInfo)
	running = true
	setEvent(event.id, workspace:GetServerTimeNow() + event.duration)
	AnnouncementService.announce(
		`{event.name}\n{event.description}`,
		{ color = event.color, duration = 6, style = "big" }
	)

	local cleanup: (() -> ())? = nil
	if event.id == "PrisonKing" then
		cleanup = spawnPrisonKing()
	elseif event.id == "EscapedBrainrots" then
		cleanup = spawnEscapees()
	end

	task.wait(event.duration)
	if cleanup then
		cleanup()
	end
	setEvent(nil, 0)
	AnnouncementService.announce(`{event.name} is over!`, { color = event.color, duration = 3, sound = "" })
	running = false
end

-- Starts an event right away (used by the Studio test commands). Returns false if one is already running.
function EventService.trigger(eventId: string): boolean
	local event = Events.ById[eventId]
	if not event or running then
		return false
	end
	task.spawn(runEvent, event)
	return true
end

function EventService.init()
	setEvent(nil, 0)
end

function EventService.start()
	task.spawn(function()
		task.wait(CONFIG.firstDelay)
		while true do
			if not running then
				runEvent(pickEvent())
			end
			task.wait(rng:NextNumber(CONFIG.minGap, CONFIG.maxGap))
		end
	end)
end

return EventService
