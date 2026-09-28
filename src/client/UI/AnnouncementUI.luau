-- Everything that pops up to tell the player something:
--   * server announcements (big banner at the top; a full-screen rainbow for the Secret Brainrot)
--   * the live event banner with its countdown
--   * small toasts in the corner (errors, achievements, purchases)
--   * floating "+$5,000" text in the world

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = require(ReplicatedStorage.Modules.Events)
local Format = require(ReplicatedStorage.Modules.Format)
local Net = require(ReplicatedStorage.Modules.Net)
local Sounds = require(script.Parent.Parent.Controllers.Sounds)
local Theme = require(script.Parent.Theme)

local AnnouncementUI = {}

local C = Theme.Colors
local KIND_COLORS = {
	info = C.Blue,
	success = C.Green,
	error = C.Red,
	achievement = C.Gold,
	unlock = C.Purple,
}

local screen: ScreenGui
local bannerHolder: Frame
local eventBanner: TextLabel
local toastHolder: Frame
local rainbowOverlay: Frame

local bannerQueue: { { [string]: any } } = {}
local showingBanner = false

local function showNextBanner()
	if showingBanner or #bannerQueue == 0 then
		return
	end
	showingBanner = true
	local info = table.remove(bannerQueue, 1) :: { [string]: any }
	local big = info.style == "big" or info.style == "secret"

	-- A dark glass banner with the announcement's color as an accent, so it informs without
	-- covering the middle of the screen in a slab of color
	local banner = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -120),
		Size = UDim2.fromOffset(if big then 640 else 520, if big then 78 else 56),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.08,
		Parent = bannerHolder,
	})
	Theme.corner(banner, 16)
	Theme.stroke(banner, info.color, 2)
	local accent = Theme.frame({
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(0, 6, 1, -20),
		BackgroundColor3 = info.color,
		Parent = banner,
	})
	Theme.corner(accent, 3)
	Theme.label({
		Position = UDim2.fromOffset(28, 8),
		Size = UDim2.new(1, -44, 1, -16),
		Text = info.text,
		Parent = banner,
	})

	if info.sound and info.sound ~= "" then
		Sounds.play(info.sound)
	end
	Theme.tween(banner, 0.45, { Position = UDim2.new(0.5, 0, 0, 0) }, Enum.EasingStyle.Back)
	if big then
		Theme.pop(banner, 1.2)
	end
	task.delay(info.duration or 4, function()
		Theme.tween(
			banner,
			0.3,
			{ Position = UDim2.new(0.5, 0, 0, -140) },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
		task.wait(0.35)
		banner:Destroy()
		showingBanner = false
		showNextBanner()
	end)
end

-- The whole server sees this when someone finds the Secret Brainrot.
local function secretFlash()
	rainbowOverlay.Visible = true
	local gradient = rainbowOverlay:FindFirstChildOfClass("UIGradient")
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if gradient then
			gradient.Rotation = (t * 240) % 360
		end
		rainbowOverlay.BackgroundTransparency = 0.35 + 0.3 * math.abs(math.sin(t * 6))
		if t > 4 then
			connection:Disconnect()
			rainbowOverlay.Visible = false
		end
	end)
	Sounds.play("RevealSecret")
end

-- Banners waiting to be shown; older ones are dropped so a busy server never shows stale news.
local MAX_QUEUED = 4

function AnnouncementUI.announce(info: { [string]: any })
	table.insert(bannerQueue, info)
	while #bannerQueue > MAX_QUEUED do
		local dropIndex = 1
		for index, queued in bannerQueue do
			if queued.style ~= "secret" then
				dropIndex = index
				break
			end
		end
		table.remove(bannerQueue, dropIndex)
	end
	if info.style == "secret" then
		secretFlash()
	end
	showNextBanner()
end

function AnnouncementUI.toast(text: string, kind: string?)
	local color = KIND_COLORS[kind or "info"] or C.Blue
	local toast = Theme.frame({
		Size = UDim2.fromOffset(360, 58),
		BackgroundColor3 = C.Cream,
		LayoutOrder = math.floor(os.clock() * 100),
		Parent = toastHolder,
	})
	Theme.corner(toast, 14)
	Theme.stroke(toast, color, 3)
	local bar = Theme.frame({ Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = color, Parent = toast })
	Theme.corner(bar, 14)
	Theme.label({
		Size = UDim2.new(1, -28, 1, -12),
		Position = UDim2.fromOffset(20, 6),
		Text = text,
		TextColor3 = C.Dark,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toast,
	})
	Theme.pop(toast, 0.7)
	if kind == "achievement" or kind == "unlock" then
		Sounds.play("UnlockArea")
	elseif kind == "success" then
		Sounds.play("CoinReward")
	end

	local toasts = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts > 5 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end

	task.delay(if kind == "achievement" then 5 else 3.5, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

-- "+$5,000" rising from a spot in the world.
function AnnouncementUI.floatText(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 70)
	gui.AlwaysOnTop = true
	gui.Adornee = anchor
	gui.Parent = anchor
	local label = Theme.label({ Size = UDim2.fromScale(1, 1), Text = text, TextColor3 = color, Parent = gui })
	Theme.textStroke(label, 3)

	Theme.tween(gui, 1.6, { StudsOffsetWorldSpace = Vector3.new(0, 8, 0) })
	Theme.tween(label, 1.6, { TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(1.7, function()
		anchor:Destroy()
	end)
end

local function updateEventBanner()
	local id = Events.currentId()
	local event = id and Events.ById[id]
	if not event then
		eventBanner.Visible = false
		return
	end
	eventBanner.Visible = true
	eventBanner.BackgroundColor3 = event.color
	eventBanner.Text = `{event.name}  {Format.time(Events.endsAt() - workspace:GetServerTimeNow())}`
end

function AnnouncementUI.init()
	screen = Theme.screen("AnnouncementUI", 30)

	rainbowOverlay = Theme.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.4,
		Visible = false,
		Parent = screen,
	})
	Theme.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 180, 50)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 220, 90)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
		}),
		Parent = rainbowOverlay,
	})

	bannerHolder = Theme.frame({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 150),
		Size = UDim2.fromOffset(800, 140),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.autoScale(bannerHolder)

	eventBanner = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 60),
		Size = UDim2.fromOffset(330, 46),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Orange,
		Visible = false,
		Parent = screen,
	})
	Theme.corner(eventBanner, 14)
	Theme.stroke(eventBanner, C.Shadow, 3)
	Theme.padding(eventBanner, 6)
	Theme.autoScale(eventBanner)

	toastHolder = Theme.frame({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -150),
		Size = UDim2.fromOffset(360, 380),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	Theme.list(
		toastHolder,
		Enum.FillDirection.Vertical,
		8,
		Enum.HorizontalAlignment.Right,
		Enum.VerticalAlignment.Bottom
	)
	Theme.autoScale(toastHolder)

	Net.event("Announce").OnClientEvent:Connect(AnnouncementUI.announce)
	Net.event("Notify").OnClientEvent:Connect(function(info)
		AnnouncementUI.toast(info.text, info.kind)
	end)
	Net.event("Effect").OnClientEvent:Connect(function(effect, payload)
		if effect == "FloatText" then
			AnnouncementUI.floatText(payload.position, payload.text, payload.color)
		end
	end)

	ReplicatedStorage:GetAttributeChangedSignal("EventId"):Connect(updateEventBanner)
	task.spawn(function()
		while true do
			updateEventBanner()
			task.wait(0.5)
		end
	end)
end

return AnnouncementUI
