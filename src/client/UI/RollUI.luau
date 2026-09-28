-- The roll animation: ROLLING... -> Brainrots flash by faster than you can read -> they slow down ->
-- rarer results get a suspense pause -> big reveal with flashes, rays, confetti and screen shake that
-- scale with rarity. The result itself always comes from the server before the animation starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local Format = require(ReplicatedStorage.Modules.Format)
local Formulas = require(ReplicatedStorage.Modules.Formulas)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Net = require(ReplicatedStorage.Modules.Net)
local RollSystem = require(ReplicatedStorage.Modules.RollSystem)
local Signal = require(ReplicatedStorage.Modules.Signal)
local Types = require(ReplicatedStorage.Modules.Types)
local Remote = require(script.Parent.Parent.Controllers.Remote)
local Sounds = require(script.Parent.Parent.Controllers.Sounds)
local State = require(script.Parent.Parent.Controllers.State)
local Theme = require(script.Parent.Theme)
local Viewport = require(script.Parent.Viewport)

local RollUI = {}

-- Fires true when a roll starts and false when the result screen closes.
RollUI.BusyChanged = Signal.new()
-- Fires with the RollResult once the player has seen it.
RollUI.Finished = Signal.new()

local C = Theme.Colors
local rng = Random.new()

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 170, 50),
	Color3.fromRGB(255, 240, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(190, 90, 255),
}

local HEADLINES = {
	Common = "COMMON",
	Uncommon = "UNCOMMON!",
	Rare = "✨ RARE! ✨",
	Epic = "💜 EPIC! 💜",
	Legendary = "🎉 LEGENDARY! 🎉",
	Mythic = "🌟 MYTHIC!!! 🌟",
	Divine = "☄️ DIVINE!!! ☄️",
	Secret = "🚨 SECRET!!! 🚨",
}

-- How often each rarity flashes past during the spin (more rares than the real odds, for excitement).
local SPIN_WEIGHTS: { [string]: number } =
	{ Common = 30, Uncommon = 24, Rare = 18, Epic = 12, Legendary = 8, Mythic = 5, Divine = 3 }

type UIRefs = {
	screen: ScreenGui,
	dim: Frame,
	flash: Frame,
	rays: Frame,
	card: Frame,
	cardStroke: UIStroke,
	title: TextLabel,
	viewport: ViewportFrame,
	mystery: TextLabel,
	nameLabel: TextLabel,
	rarityLabel: TextLabel,
	incomeLabel: TextLabel,
	variantLabel: TextLabel,
	newBadge: TextLabel,
	headline: TextLabel,
	pityLabel: TextLabel,
	hint: TextLabel,
	confetti: Frame,
	catcher: TextButton,
}

local ui: UIRefs
local busy = false
local queue: { Types.RollResult } = {}
local raysConnection: RBXScriptConnection? = nil

---------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------

local function flash(strength: number, seconds: number, color: Color3?)
	ui.flash.BackgroundColor3 = color or C.White
	ui.flash.BackgroundTransparency = 1 - strength
	Theme.tween(ui.flash, seconds, { BackgroundTransparency = 1 })
end

local function burst(count: number, colors: { Color3 })
	for _ = 1, count do
		local piece = Theme.frame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(rng:NextInteger(8, 16), rng:NextInteger(12, 24)),
			BackgroundColor3 = colors[rng:NextInteger(1, #colors)],
			Rotation = rng:NextNumber(0, 360),
			Parent = ui.confetti,
		})
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.2, 0.75)
		local seconds = rng:NextNumber(0.9, 1.7)
		Theme.tween(piece, seconds, {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * distance * 0.65, 0.45 + math.sin(angle) * distance),
			Rotation = piece.Rotation + rng:NextNumber(-540, 540),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quint)
		task.delay(seconds + 0.1, function()
			piece:Destroy()
		end)
	end
end

local function setRays(visible: boolean, colors: { Color3 }?)
	ui.rays.Visible = visible
	if raysConnection then
		raysConnection:Disconnect()
		raysConnection = nil
	end
	if not visible then
		return
	end
	local rays = ui.rays:GetChildren()
	for index, ray in rays do
		if ray:IsA("Frame") and colors then
			ray.BackgroundColor3 = colors[(index - 1) % #colors + 1]
		end
	end
	raysConnection = RunService.RenderStepped:Connect(function(dt: number)
		ui.rays.Rotation = (ui.rays.Rotation + dt * 25) % 360
	end)
end

local function shakeCamera(seconds: number, magnitude: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local name = "PrisonBrainrotShake"
	pcall(function()
		RunService:UnbindFromRenderStep(name)
	end)
	local started = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - started
		if t > seconds then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local m = magnitude * (1 - t / seconds)
		camera.CFrame *= CFrame.new(rng:NextNumber(-m, m), rng:NextNumber(-m, m), 0)
	end)
end

local function shakeCard(seconds: number, pixels: number)
	local started = os.clock()
	while os.clock() - started < seconds do
		ui.card.Position = UDim2.new(0.5, rng:NextInteger(-pixels, pixels), 0.5, rng:NextInteger(-pixels, pixels))
		task.wait(0.03)
	end
	ui.card.Position = UDim2.fromScale(0.5, 0.5)
end

---------------------------------------------------------------------------
-- Card
---------------------------------------------------------------------------

local function paintCard(color: Color3)
	ui.card.BackgroundColor3 = color:Lerp(C.White, 0.45)
	ui.cardStroke.Color = color
end

local function showBrainrot(brainrotId: string, variant: string)
	local brainrot = BrainrotData.ById[brainrotId]
	local rarity = BrainrotData.getRarity(brainrotId)
	ui.viewport.Visible = true
	ui.mystery.Visible = false
	Viewport.show(ui.viewport, brainrotId, variant)
	ui.nameLabel.Text = `{brainrot.emoji} {BrainrotData.displayName(brainrotId, variant)}`
	ui.rarityLabel.Text = rarity.name
	ui.rarityLabel.TextColor3 = if rarity.id == "Secret" then C.Pink else rarity.color
	ui.incomeLabel.Text = `+{Format.money(BrainrotData.income(brainrotId, variant))}/sec`
	paintCard(if rarity.id == "Secret" then C.Purple else rarity.color)
end

local function showMystery(color: Color3)
	ui.viewport.Visible = false
	ui.mystery.Visible = true
	ui.nameLabel.Text = "???"
	ui.rarityLabel.Text = "..."
	ui.rarityLabel.TextColor3 = color
	ui.incomeLabel.Text = ""
	paintCard(color)
end

local function randomSpinBrainrot(): string
	local total = 0
	for _, weight in SPIN_WEIGHTS do
		total += weight
	end
	local pick = rng:NextNumber() * total
	for _, rarity in BrainrotData.Rarities do
		local weight = SPIN_WEIGHTS[rarity.id]
		if weight then
			if pick < weight then
				return RollSystem.pickBrainrot(rng, rarity.id)
			end
			pick -= weight
		end
	end
	return RollSystem.pickBrainrot(rng, "Common")
end

---------------------------------------------------------------------------
-- The animation
---------------------------------------------------------------------------

local function reset()
	ui.dim.BackgroundTransparency = 0.35
	ui.flash.BackgroundTransparency = 1
	ui.headline.Text = ""
	ui.headline.Visible = false
	ui.variantLabel.Visible = false
	ui.newBadge.Visible = false
	ui.hint.Visible = false
	ui.pityLabel.Text = ""
	ui.catcher.Visible = false
	ui.card.Position = UDim2.fromScale(0.5, 0.5)
	ui.confetti:ClearAllChildren()
	setRays(false)
	Viewport.setSpinning(ui.viewport, false)
end

local function setBusy(value: boolean)
	busy = value
	RollUI.BusyChanged:Fire(value)
end

local function spin(speed: number)
	local duration = GameConfig.ROLL.spinTime / speed
	local elapsed = 0
	while elapsed < duration do
		local progress = elapsed / duration
		showBrainrot(randomSpinBrainrot(), "Normal")
		Sounds.play("RollTick", 1 + progress * 0.7)
		Theme.pop(ui.card, 1.05)
		local interval = (0.05 + 0.34 * progress ^ 2.2) / speed
		task.wait(interval)
		elapsed += interval
	end
end

local function suspense(rarity: BrainrotData.Rarity, speed: number)
	local seconds = rarity.revealExtra / speed
	if seconds <= 0 then
		return
	end
	if rarity.id == "Secret" then
		Theme.tween(ui.dim, 0.4, { BackgroundTransparency = 0 })
		showMystery(Color3.fromRGB(40, 20, 60))
		local glitch = { "? ? ?", "?!?", "¿¿¿", "? ! ?", "???" }
		local started = os.clock()
		local beat = 0
		while os.clock() - started < seconds do
			beat += 1
			ui.title.Text = glitch[beat % #glitch + 1]
			ui.title.TextColor3 = RAINBOW[beat % #RAINBOW + 1]
			Theme.pop(ui.card, 1.12)
			Sounds.play("RollTick", 0.5)
			task.wait(0.35 / speed)
		end
		return
	end

	showMystery(rarity.color)
	ui.title.Text = if rarity.order >= 5 then "✨ SOMETHING RARE... ✨" else "!!"
	if rarity.order >= 5 then
		Theme.tween(ui.dim, 0.4, { BackgroundTransparency = 0.1 })
		local started = os.clock()
		while os.clock() - started < seconds do
			Theme.pop(ui.card, 1.1)
			Sounds.play("RollTick", 0.7)
			task.wait(0.4 / speed)
		end
	else
		shakeCard(seconds, 6)
	end
end

local function reveal(result: Types.RollResult)
	local rarity = BrainrotData.RarityById[result.rarity]
	local order = rarity.order
	local variant = BrainrotData.VariantById[result.variant]

	showBrainrot(result.brainrotId, result.variant)
	Viewport.setSpinning(ui.viewport, true)
	Sounds.play(`Reveal{rarity.id}`)
	ui.title.Text = if result.source == "PrisonKing" then "👑 THE KING'S ROLL 👑" else "YOU GOT..."
	ui.title.TextColor3 = C.White

	ui.headline.Visible = true
	ui.headline.Text = HEADLINES[rarity.id] or rarity.name
	ui.headline.TextColor3 = if rarity.id == "Secret" then C.Pink else rarity.color
	Theme.pop(ui.headline, 1.6)
	Theme.pop(ui.card, 1 + order * 0.05)

	local colors = { rarity.color, C.White, rarity.color:Lerp(C.White, 0.5) }
	if order >= 7 then
		colors = RAINBOW
	end

	if order >= 3 then
		flash(
			math.min(0.4 + order * 0.08, 1),
			0.3 + order * 0.1,
			if order >= 7 then C.White else rarity.color:Lerp(C.White, 0.6)
		)
		burst(10 + (order - 2) * 18, colors)
	end
	if order >= 4 then
		setRays(true, if order >= 7 then RAINBOW else { rarity.color, rarity.color:Lerp(C.White, 0.5) })
		shakeCamera(0.2 + order * 0.1, 0.1 + order * 0.04)
	end
	if order >= 5 then
		Theme.tween(ui.dim, 0.5, { BackgroundTransparency = 0.3 })
		task.delay(0.5, function()
			burst(40, colors)
		end)
	end
	if order >= 8 then
		for i = 1, 6 do
			task.delay(i * 0.25, function()
				flash(0.7, 0.3, RAINBOW[i])
				burst(25, RAINBOW)
			end)
		end
	end

	if variant and variant.id ~= "Normal" then
		ui.variantLabel.Visible = true
		ui.variantLabel.Text = `{variant.prefix}{string.upper(variant.name)}! {variant.multiplier}x INCOME`
		ui.variantLabel.TextColor3 = variant.color
		Theme.pop(ui.variantLabel, 1.5)
		burst(30, { variant.color, C.White })
		paintCard(variant.color)
	end
	if result.isNew then
		ui.newBadge.Visible = true
		ui.newBadge.Text = "NEW!"
		Theme.pop(ui.newBadge, 1.6)
	elseif result.isNewVariant then
		ui.newBadge.Visible = true
		ui.newBadge.Text = "NEW LOOK!"
		Theme.pop(ui.newBadge, 1.6)
	end

	local pity = RollSystem.pityInfo(result.pity)
	ui.pityLabel.Text = if RollSystem.resetsPity(result.rarity)
		then "🍀 Lucky rolls used! Counter reset."
		elseif pity.guaranteed then "🍀 NEXT ROLL: GUARANTEED LEGENDARY+!"
		else `🍀 LUCKY ROLLS: {pity.count}/{pity.target}`
end

local function play(result: Types.RollResult)
	setBusy(true)
	reset()
	ui.screen.Enabled = true
	local speed = math.max(result.speed or 1, 0.5)
	local rarity = BrainrotData.RarityById[result.rarity]

	ui.title.Text = "🎰 ROLLING... 🎰"
	ui.title.TextColor3 = C.Gold
	Theme.pop(ui.card, 0.6)
	Sounds.play("RollStart")

	spin(speed)
	suspense(rarity, speed)
	reveal(result)

	task.wait(0.6)
	ui.hint.Visible = true
	ui.catcher.Visible = true
	local deadline = os.clock() + 2.5 + rarity.order * 0.5
	local continued = false
	local connection = ui.catcher.Activated:Connect(function()
		continued = true
	end)
	while not continued and os.clock() < deadline do
		task.wait()
	end
	connection:Disconnect()

	ui.screen.Enabled = false
	reset()
	setBusy(false)
	RollUI.Finished:Fire(result)

	local nextResult = table.remove(queue, 1)
	if nextResult then
		task.defer(play, nextResult)
	end
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------

function RollUI.isBusy(): boolean
	return busy
end

-- Asks the server to roll at a block's machine (or use the daily free roll), then plays the result.
function RollUI.requestRoll(areaId: string, free: boolean?)
	if busy then
		return
	end
	setBusy(true)
	local response = Remote.call("Roll", areaId, free == true)
	if response.ok and type(response.result) == "table" then
		play(response.result)
	else
		setBusy(false)
		local queued = table.remove(queue, 1)
		if queued then
			task.spawn(play, queued)
		end
	end
end

function RollUI.requestDailyRoll()
	local data = State.data()
	if data then
		RollUI.requestRoll(Formulas.bestArea(data).id, true)
	end
end

function RollUI.init()
	local screen = Theme.screen("RollUI", 20)
	screen.Enabled = false

	local dim = Theme.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Parent = screen,
	})

	local rays = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	})
	for i = 0, 11 do
		local ray = Theme.frame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(46, 1500),
			BackgroundColor3 = C.Gold,
			BackgroundTransparency = 0.55,
			Rotation = i * 15,
			Parent = rays,
		})
		Theme.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = 90,
			Parent = ray,
		})
	end

	local stage = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(700, 720),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(stage)

	local title = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(620, 60),
		Text = "🎰 ROLLING... 🎰",
		TextColor3 = C.Gold,
		Parent = stage,
	})
	Theme.textStroke(title, 3)

	local headline = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(680, 70),
		Visible = false,
		Parent = stage,
	})
	Theme.textStroke(headline, 4)

	local card = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 420),
		BackgroundColor3 = C.White,
		Parent = stage,
	})
	Theme.corner(card, 26)
	local cardStroke = Theme.stroke(card, C.Gold, 7)
	Theme.gradient(card, C.White)

	local viewport = Viewport.new({
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 0, 250),
		Parent = card,
	})
	local mystery = Theme.label({
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 0, 250),
		Text = "❓",
		Visible = false,
		Parent = card,
	})
	local nameLabel =
		Theme.label({ Position = UDim2.fromOffset(12, 270), Size = UDim2.new(1, -24, 0, 50), Parent = card })
	local rarityLabel =
		Theme.label({ Position = UDim2.fromOffset(12, 320), Size = UDim2.new(1, -24, 0, 40), Parent = card })
	Theme.textStroke(rarityLabel, 2)
	local incomeLabel = Theme.label({
		Position = UDim2.fromOffset(12, 362),
		Size = UDim2.new(1, -24, 0, 42),
		TextColor3 = Color3.fromRGB(120, 255, 120),
		Parent = card,
	})
	Theme.textStroke(incomeLabel, 2)

	local newBadge = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -10, 0, 12),
		Size = UDim2.fromOffset(130, 46),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Red,
		Rotation = 12,
		Text = "NEW!",
		Visible = false,
		Parent = card,
	})
	Theme.corner(newBadge, 12)
	Theme.stroke(newBadge, C.Shadow, 3)

	local variantLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 222),
		Size = UDim2.fromOffset(560, 50),
		Visible = false,
		Parent = stage,
	})
	Theme.textStroke(variantLabel, 3)

	local pityLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 276),
		Size = UDim2.fromOffset(520, 34),
		TextColor3 = C.Lime,
		Parent = stage,
	})
	Theme.textStroke(pityLabel, 2)

	local hint = Theme.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(420, 32),
		Text = "Tap anywhere to continue",
		Visible = false,
		Parent = stage,
	})

	local confetti = Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = screen })
	local flashFrame = Theme.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local catcher = Theme.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	})

	ui = {
		screen = screen,
		dim = dim,
		flash = flashFrame,
		rays = rays,
		card = card,
		cardStroke = cardStroke,
		title = title,
		viewport = viewport,
		mystery = mystery,
		nameLabel = nameLabel,
		rarityLabel = rarityLabel,
		incomeLabel = incomeLabel,
		variantLabel = variantLabel,
		newBadge = newBadge,
		headline = headline,
		pityLabel = pityLabel,
		hint = hint,
		confetti = confetti,
		catcher = catcher,
	}

	Net.event("ServerRoll").OnClientEvent:Connect(function(result: Types.RollResult)
		if busy then
			table.insert(queue, result)
		else
			task.spawn(play, result)
		end
	end)
end

return RollUI
