-- The roll: a case-opening reel. A strip of Brainrot cards races past a gold marker, slows down
-- and stops on your result (rare results stay hidden as a glowing "?" card until it lands, then a
-- suspense beat). Then the big reveal: the Brainrot in 3D on a card in its rarity's colors, with a
-- ribbon, flashes, rays, confetti and screen shake that all scale with rarity.
-- The result always comes from the server before the animation starts.

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

-- How often each rarity shows up on the reel (more rares than the real odds, for excitement).
local SPIN_WEIGHTS: { [string]: number } =
	{ Common = 30, Uncommon = 24, Rare = 18, Epic = 12, Legendary = 8, Mythic = 5, Divine = 3 }

local REEL_CARDS = 46
local TARGET_INDEX = 40
local CARD_W, CARD_H, CARD_GAP = 150, 196, 12
local PITCH = CARD_W + CARD_GAP

type UIRefs = {
	screen: ScreenGui,
	dim: Frame,
	flash: Frame,
	rays: Frame,
	reelWindow: Frame,
	strip: Frame,
	marker: Frame,
	card: Frame,
	cardStroke: UIStroke,
	cardGradient: UIGradient,
	title: TextLabel,
	viewport: ViewportFrame,
	mystery: TextLabel,
	ribbon: Frame,
	ribbonLabel: TextLabel,
	nameLabel: TextLabel,
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

local function rarityColor(rarity: BrainrotData.Rarity): Color3
	return if rarity.id == "Secret" then C.Purple else rarity.color
end

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

---------------------------------------------------------------------------
-- The reel
---------------------------------------------------------------------------

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

-- One small card on the reel: rarity-colored, with the Brainrot's emoji and name.
local function reelCard(index: number, brainrotId: string?, mystery: Color3?): Frame
	local brainrot = if brainrotId then BrainrotData.ById[brainrotId] else nil
	local rarity = if brainrotId then BrainrotData.getRarity(brainrotId) else nil
	local color = mystery or (if rarity then rarityColor(rarity) else C.Gray)
	local card = Theme.frame({
		Name = `Card{index}`,
		Position = UDim2.fromOffset((index - 1) * PITCH, 0),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = color,
		Parent = ui.strip,
	})
	Theme.corner(card, 16)
	Theme.stroke(card, C.Shadow, 3)
	Theme.new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 120, 120)),
		Rotation = 90,
		Parent = card,
	})
	Theme.label({
		Name = "Icon",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 110),
		Text = if brainrot then brainrot.emoji else "❓",
		Parent = card,
	})
	local name = Theme.label({
		Name = "Name",
		Position = UDim2.fromOffset(8, 124),
		Size = UDim2.new(1, -16, 0, 30),
		Text = if brainrot then brainrot.name else "???",
		Parent = card,
	})
	name.Font = Theme.SmallFont
	local stripe = Theme.frame({
		Position = UDim2.new(0, 0, 1, -34),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.Shadow,
		BackgroundTransparency = 0.35,
		Parent = card,
	})
	Theme.corner(stripe, 12)
	Theme.label({
		Size = UDim2.new(1, -12, 1, -10),
		Position = UDim2.fromOffset(6, 5),
		Text = if rarity and not mystery then rarity.name else "?",
		TextColor3 = if rarity and not mystery then color:Lerp(C.White, 0.35) else C.White,
		Parent = stripe,
	})
	return card
end

-- Fills the strip; the result sits at TARGET_INDEX. Rare results are hidden behind a "?" card.
local function buildReel(result: Types.RollResult): Frame
	ui.strip:ClearAllChildren()
	local rarity = BrainrotData.RarityById[result.rarity]
	local hidden = rarity.order >= 5
	local target: Frame? = nil
	for index = 1, REEL_CARDS do
		if index == TARGET_INDEX then
			target =
				reelCard(index, if hidden then nil else result.brainrotId, if hidden then rarityColor(rarity) else nil)
		elseif index == TARGET_INDEX + 1 and rng:NextNumber() < 0.5 then
			-- A near miss right after the marker keeps every roll exciting
			reelCard(index, RollSystem.pickBrainrot(rng, if rng:NextNumber() < 0.5 then "Legendary" else "Mythic"))
		else
			reelCard(index, randomSpinBrainrot())
		end
	end
	return target :: Frame
end

local function spinReel(result: Types.RollResult, speed: number): Frame
	local target = buildReel(result)
	local windowWidth = 960
	local startX = windowWidth / 2 - CARD_W / 2
	local endX = windowWidth / 2
		- ((TARGET_INDEX - 1) * PITCH + CARD_W / 2 + rng:NextNumber(-CARD_W * 0.35, CARD_W * 0.35))
	ui.strip.Position = UDim2.fromOffset(startX, 0)
	ui.reelWindow.Visible = true
	ui.marker.Visible = true
	local duration = GameConfig.ROLL.spinTime / speed
	local tween = Theme.tween(ui.strip, duration, { Position = UDim2.fromOffset(endX, 0) }, Enum.EasingStyle.Quart)
	-- A tick every time a card passes the marker, rising in pitch as the reel slows
	local lastIndex = -1
	local started = os.clock()
	local ticking = RunService.RenderStepped:Connect(function()
		local x = ui.strip.Position.X.Offset
		local index = math.floor((windowWidth / 2 - x) / PITCH)
		if index ~= lastIndex then
			lastIndex = index
			Sounds.play("RollTick", 1 + math.min(1, (os.clock() - started) / duration) * 0.6)
		end
	end)
	local done = false
	tween.Completed:Connect(function()
		done = true
	end)
	local deadline = os.clock() + duration + 0.5
	while not done and os.clock() < deadline do
		task.wait()
	end
	ticking:Disconnect()
	ui.strip.Position = UDim2.fromOffset(endX, 0)
	return target
end

---------------------------------------------------------------------------
-- The reveal card
---------------------------------------------------------------------------

local function paintCard(color: Color3)
	ui.card.BackgroundColor3 = color
	ui.cardStroke.Color = color:Lerp(C.White, 0.5)
	ui.ribbon.BackgroundColor3 = color:Lerp(C.Shadow, 0.15)
end

local function showBrainrot(brainrotId: string, variant: string)
	local brainrot = BrainrotData.ById[brainrotId]
	local rarity = BrainrotData.getRarity(brainrotId)
	ui.viewport.Visible = true
	ui.mystery.Visible = false
	Viewport.show(ui.viewport, brainrotId, variant)
	ui.nameLabel.Text = `{brainrot.emoji} {BrainrotData.displayName(brainrotId, variant)}`
	ui.ribbonLabel.Text = rarity.name
	ui.incomeLabel.Text = `💵 +{Format.money(BrainrotData.income(brainrotId, variant))}/sec`
	paintCard(rarityColor(rarity))
end

---------------------------------------------------------------------------
-- The animation
---------------------------------------------------------------------------

local function reset()
	ui.dim.BackgroundTransparency = 0.3
	ui.flash.BackgroundTransparency = 1
	ui.headline.Text = ""
	ui.headline.Visible = false
	ui.variantLabel.Visible = false
	ui.newBadge.Visible = false
	ui.hint.Visible = false
	ui.pityLabel.Text = ""
	ui.catcher.Visible = false
	ui.card.Visible = false
	ui.card.Position = UDim2.fromScale(0.5, 0.52)
	ui.reelWindow.Visible = false
	ui.marker.Visible = false
	ui.strip:ClearAllChildren()
	ui.confetti:ClearAllChildren()
	setRays(false)
	Viewport.setSpinning(ui.viewport, false)
end

local function setBusy(value: boolean)
	busy = value
	RollUI.BusyChanged:Fire(value)
end

-- The beat after the reel stops: rarer results make you wait (and glow) a little longer.
local function suspense(rarity: BrainrotData.Rarity, target: Frame, speed: number)
	Theme.pop(target, 1.18)
	local seconds = rarity.revealExtra / speed
	if seconds <= 0 then
		return
	end
	if rarity.id == "Secret" then
		Theme.tween(ui.dim, 0.4, { BackgroundTransparency = 0 })
		local glitch = { "? ? ?", "?!?", "¿¿¿", "? ! ?", "???" }
		local started = os.clock()
		local beat = 0
		while os.clock() - started < seconds do
			beat += 1
			ui.title.Text = glitch[beat % #glitch + 1]
			ui.title.TextColor3 = RAINBOW[beat % #RAINBOW + 1]
			target.BackgroundColor3 = RAINBOW[beat % #RAINBOW + 1]
			Theme.pop(target, 1.2)
			Sounds.play("RollTick", 0.5)
			task.wait(0.35 / speed)
		end
		return
	end
	if rarity.order >= 5 then
		ui.title.Text = "✨ SOMETHING RARE... ✨"
		Theme.tween(ui.dim, 0.4, { BackgroundTransparency = 0.1 })
		local started = os.clock()
		while os.clock() - started < seconds do
			Theme.pop(target, 1.16)
			Sounds.play("RollTick", 0.7)
			task.wait(0.4 / speed)
		end
	else
		task.wait(seconds)
	end
end

local function reveal(result: Types.RollResult)
	local rarity = BrainrotData.RarityById[result.rarity]
	local order = rarity.order
	local variant = BrainrotData.VariantById[result.variant]

	ui.reelWindow.Visible = false
	ui.marker.Visible = false
	ui.card.Visible = true
	showBrainrot(result.brainrotId, result.variant)
	Viewport.setSpinning(ui.viewport, true)
	Sounds.play(`Reveal{rarity.id}`)
	ui.title.Text = if result.source == "PrisonKing" then "👑 THE KING'S ROLL 👑" else "YOU GOT..."
	ui.title.TextColor3 = C.White

	ui.headline.Visible = true
	ui.headline.Text = HEADLINES[rarity.id] or rarity.name
	ui.headline.TextColor3 = if rarity.id == "Secret" then C.Pink else rarity.color
	Theme.pop(ui.headline, 1.6)
	Theme.pop(ui.card, 0.55)

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
		Theme.tween(ui.dim, 0.5, { BackgroundTransparency = 0.25 })
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
	Sounds.play("RollStart")

	local target = spinReel(result, speed)
	suspense(rarity, target, speed)
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

local function buildRays(screen: ScreenGui): Frame
	local rays = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
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
	return rays
end

local function buildReelWindow(stage: Frame): (Frame, Frame, Frame)
	local window = Theme.frame({
		Name = "Reel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(960, CARD_H + 36),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.05,
		ClipsDescendants = true,
		Visible = false,
		Parent = stage,
	})
	Theme.corner(window, 24)
	Theme.stroke(window, C.Gold, 4)
	local strip = Theme.frame({
		Name = "Strip",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(0, REEL_CARDS * PITCH, 0, CARD_H),
		BackgroundTransparency = 1,
		Parent = window,
	})
	-- Dark fades at both ends so cards slide in and out of view
	for _, side in { 0, 1 } do
		local fade = Theme.frame({
			AnchorPoint = Vector2.new(side, 0),
			Position = UDim2.fromScale(side, 0),
			Size = UDim2.new(0, 180, 1, 0),
			BackgroundColor3 = C.Panel,
			ZIndex = 3,
			Parent = window,
		})
		Theme.new("UIGradient", {
			Transparency = NumberSequence.new(if side == 0 then 0 else 1, if side == 0 then 1 else 0),
			Parent = fade,
		})
	end
	-- The marker: a gold line with arrows, over the middle of the window
	local marker = Theme.frame({
		Name = "Marker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, CARD_H + 70),
		BackgroundColor3 = C.Gold,
		ZIndex = 4,
		Visible = false,
		Parent = stage,
	})
	Theme.stroke(marker, C.Shadow, 2)
	for _, y in { 0, 1 } do
		local arrow = Theme.label({
			AnchorPoint = Vector2.new(0.5, y),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.fromOffset(40, 34),
			Text = if y == 0 then "▼" else "▲",
			TextColor3 = C.Gold,
			ZIndex = 5,
			Parent = marker,
		})
		Theme.textStroke(arrow, 3)
	end
	return window, strip, marker
end

function RollUI.init()
	local screen = Theme.screen("RollUI", 20)
	screen.Enabled = false

	local dim = Theme.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 6, 20),
		BackgroundTransparency = 0.3,
		Parent = screen,
	})
	-- Darker at the top and bottom, like a spotlight on the middle
	Theme.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0.5),
			NumberSequenceKeypoint.new(0.65, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
		Parent = dim,
	})

	local rays = buildRays(screen)

	local stage = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1000, 720),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(stage)

	local title = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 36),
		Size = UDim2.fromOffset(620, 56),
		Text = "🎰 ROLLING... 🎰",
		TextColor3 = C.Gold,
		Parent = stage,
	})
	Theme.textStroke(title, 3)

	local headline = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(700, 66),
		Visible = false,
		Parent = stage,
	})
	Theme.textStroke(headline, 4)

	local reelWindow, strip, marker = buildReelWindow(stage)

	-- The reveal card
	local card = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(360, 430),
		BackgroundColor3 = C.Gold,
		Visible = false,
		Parent = stage,
	})
	Theme.corner(card, 28)
	local cardStroke = Theme.stroke(card, C.White, 6)
	local cardGradient = Theme.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 90, 90)),
		}),
		Rotation = 90,
		Parent = card,
	})
	-- A soft light panel behind the model
	local stageLight = Theme.frame({
		Position = UDim2.fromOffset(18, 44),
		Size = UDim2.new(1, -36, 0, 236),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.72,
		Parent = card,
	})
	Theme.corner(stageLight, 20)
	local viewport = Viewport.new({
		Position = UDim2.fromOffset(18, 44),
		Size = UDim2.new(1, -36, 0, 236),
		Parent = card,
	})
	local mystery = Theme.label({
		Position = UDim2.fromOffset(18, 44),
		Size = UDim2.new(1, -36, 0, 236),
		Text = "❓",
		Visible = false,
		Parent = card,
	})
	-- Rarity ribbon across the top edge
	local ribbon = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(250, 50),
		BackgroundColor3 = C.Gold,
		Parent = card,
	})
	Theme.corner(ribbon, 14)
	Theme.stroke(ribbon, C.Shadow, 4)
	Theme.keyGradient(ribbon, 0.18)
	local ribbonLabel = Theme.label({
		Size = UDim2.new(1, -20, 1, -14),
		Position = UDim2.fromOffset(10, 5),
		Text = "",
		Parent = ribbon,
	})
	Theme.textStroke(ribbonLabel, 3)
	local nameLabel =
		Theme.label({ Position = UDim2.fromOffset(12, 290), Size = UDim2.new(1, -24, 0, 48), Parent = card })
	Theme.textStroke(nameLabel, 3)
	local incomePill = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(250, 52),
		BackgroundColor3 = Color3.fromRGB(28, 60, 36),
		BackgroundTransparency = 0.1,
		Parent = card,
	})
	Theme.corner(incomePill, 16)
	Theme.stroke(incomePill, C.Shadow, 3)
	local incomeLabel = Theme.label({
		Size = UDim2.new(1, -20, 1, -14),
		Position = UDim2.fromOffset(10, 7),
		TextColor3 = Color3.fromRGB(120, 255, 140),
		Parent = incomePill,
	})
	Theme.textStroke(incomeLabel, 2)

	local newBadge = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 52),
		Size = UDim2.fromOffset(120, 44),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Red,
		Rotation = 14,
		Text = "NEW!",
		Visible = false,
		ZIndex = 3,
		Parent = card,
	})
	Theme.corner(newBadge, 12)
	Theme.stroke(newBadge, C.White, 3)

	local variantLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.52, 222),
		Size = UDim2.fromOffset(560, 42),
		Visible = false,
		Parent = stage,
	})
	Theme.textStroke(variantLabel, 3)

	local pityLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.52, 266),
		Size = UDim2.fromOffset(520, 28),
		TextColor3 = C.Lime,
		Parent = stage,
	})
	Theme.textStroke(pityLabel, 2)

	local hint = Theme.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(420, 30),
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
		reelWindow = reelWindow,
		strip = strip,
		marker = marker,
		card = card,
		cardStroke = cardStroke,
		cardGradient = cardGradient,
		title = title,
		viewport = viewport,
		mystery = mystery,
		ribbon = ribbon,
		ribbonLabel = ribbonLabel,
		nameLabel = nameLabel,
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
