-- The UI toolkit: colors, fonts, and helpers for bouncy buttons, rounded panels and tweens.
-- Every screen in the game is built from these so the style stays consistent.
--
-- The look: chunky rounded shapes with a thin dark outline, a lit top and a subtle darker "lip"
-- along the bottom so buttons read as pressable keys; white text with a dark stroke; one strong
-- color per function (gold = money, green = income/buy, red = roll, blue = upgrades, purple =
-- rebirth) and the rarity colors from BrainrotData for anything about rarity.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Sounds = require(script.Parent.Parent.Controllers.Sounds)

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
-- Small print (captions, descriptions) reads better in a tighter font.
Theme.SmallFont = Enum.Font.GothamBold

Theme.Colors = {
	White = Color3.fromRGB(255, 255, 255),
	Cream = Color3.fromRGB(244, 242, 252),
	Card = Color3.fromRGB(226, 223, 242),
	Dark = Color3.fromRGB(34, 30, 62),
	Panel = Color3.fromRGB(28, 26, 50),
	Shadow = Color3.fromRGB(16, 12, 34),
	Muted = Color3.fromRGB(150, 146, 184),
	Gold = Color3.fromRGB(255, 196, 40),
	Green = Color3.fromRGB(60, 204, 96),
	Lime = Color3.fromRGB(150, 236, 80),
	Red = Color3.fromRGB(242, 58, 72),
	Blue = Color3.fromRGB(58, 140, 255),
	Purple = Color3.fromRGB(150, 88, 255),
	Pink = Color3.fromRGB(255, 92, 176),
	Orange = Color3.fromRGB(255, 138, 36),
	Gray = Color3.fromRGB(128, 126, 150),
}

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Instance creation
---------------------------------------------------------------------------

function Theme.apply(instance: Instance, props: { [string]: any })
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
end

function Theme.new(className: string, props: { [string]: any }): any
	local instance = Instance.new(className)
	Theme.apply(instance, props)
	return instance
end

function Theme.corner(parent: Instance, radius: number?): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 14), Parent = parent })
end

-- Outlines are kept thin (70% of the requested weight) so panels read clean rather than heavy.
function Theme.stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	return Theme.new("UIStroke", {
		Color = color or Theme.Colors.Shadow,
		Thickness = (thickness or 3) * 0.7,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Theme.textStroke(parent: Instance, thickness: number?): UIStroke
	return Theme.new("UIStroke", {
		Color = Theme.Colors.Shadow,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

-- Vertical gradient: lighter at the top.
function Theme.gradient(parent: Instance, color: Color3): UIGradient
	return Theme.new("UIGradient", {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.15)),
		Rotation = 90,
		Parent = parent,
	})
end

-- The 3D key look: full color on top, gently shaded, with a darker lip along the bottom edge.
-- (UIGradient multiplies the background, so white keeps the color and grey darkens it.)
function Theme.keyGradient(parent: Instance, lip: number?): UIGradient
	local edge = 1 - (lip or 0.12)
	local g = Color3.fromRGB
	return Theme.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, g(255, 255, 255)),
			ColorSequenceKeypoint.new(edge * 0.55, g(246, 246, 246)),
			ColorSequenceKeypoint.new(edge - 0.001, g(226, 226, 226)),
			ColorSequenceKeypoint.new(edge, g(178, 178, 178)),
			ColorSequenceKeypoint.new(1, g(170, 170, 170)),
		}),
		Rotation = 90,
		Parent = parent,
	})
end

-- A red notification dot with a number or "!" in the top-right corner of a button.
function Theme.badge(parent: Instance, text: string?): TextLabel
	local dot = Theme.new("TextLabel", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Theme.Colors.Red,
		Font = Theme.Font,
		Text = text or "!",
		TextScaled = true,
		TextColor3 = Theme.Colors.White,
		ZIndex = 5,
		Parent = parent,
	})
	Theme.corner(dot, 14)
	Theme.stroke(dot, Theme.Colors.White, 2)
	Theme.new("UIPadding", {
		PaddingTop = UDim.new(0.15, 0),
		PaddingBottom = UDim.new(0.15, 0),
		Parent = dot,
	})
	return dot
end

export type ProgressBar = { frame: Frame, fill: Frame, label: TextLabel, set: (fraction: number, text: string) -> () }

-- A rounded progress bar with a label on top of the fill.
function Theme.progressBar(
	props: { size: UDim2, position: UDim2?, anchor: Vector2?, color: Color3, parent: Instance }
): ProgressBar
	local frame = Theme.frame({
		Size = props.size,
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.15,
		Parent = props.parent,
	})
	Theme.corner(frame, 10)
	Theme.stroke(frame, Theme.Colors.Shadow, 2)
	local fill = Theme.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = props.color, Parent = frame })
	Theme.corner(fill, 10)
	Theme.keyGradient(fill, 0.3)
	local label = Theme.label({
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.fromOffset(8, 3),
		ZIndex = 2,
		Parent = frame,
	})
	local bar: ProgressBar
	bar = {
		frame = frame,
		fill = fill,
		label = label,
		set = function(fraction: number, text: string)
			Theme.tween(fill, 0.3, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) })
			label.Text = text
		end,
	}
	return bar
end

function Theme.padding(parent: Instance, pixels: number): UIPadding
	local amount = UDim.new(0, pixels)
	return Theme.new("UIPadding", {
		PaddingTop = amount,
		PaddingBottom = amount,
		PaddingLeft = amount,
		PaddingRight = amount,
		Parent = parent,
	})
end

function Theme.list(
	parent: Instance,
	direction: Enum.FillDirection?,
	spacing: number?,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	return Theme.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, spacing or 8),
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Center,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Theme.frame(props: { [string]: any }): Frame
	local frame = Theme.new("Frame", { BorderSizePixel = 0, BackgroundColor3 = Theme.Colors.Cream })
	Theme.apply(frame, props)
	return frame
end

function Theme.label(props: { [string]: any }): TextLabel
	local label = Theme.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextScaled = true,
		RichText = true,
		TextColor3 = Theme.Colors.White,
		Text = "",
	})
	Theme.apply(label, props)
	if label.TextColor3 == Theme.Colors.White then
		Theme.textStroke(label)
	end
	return label
end

---------------------------------------------------------------------------
-- Tweens and juice
---------------------------------------------------------------------------

function Theme.tween(
	instance: Instance,
	seconds: number,
	goals: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goals
	)
	tween:Play()
	return tween
end

local function scaleOf(guiObject: GuiObject): UIScale
	local scale = guiObject:FindFirstChild("PopScale")
	if scale and scale:IsA("UIScale") then
		return scale
	end
	return Theme.new("UIScale", { Name = "PopScale", Parent = guiObject })
end

-- Quick squash-and-stretch bounce.
function Theme.pop(guiObject: GuiObject, amount: number?)
	local scale = scaleOf(guiObject)
	scale.Scale = amount or 1.15
	Theme.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

---------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------

export type ButtonOptions = {
	text: string,
	color: Color3,
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance?,
	textColor: Color3?,
	layoutOrder: number?,
}

-- A chunky rounded button that grows on hover and squishes when pressed.
function Theme.button(options: ButtonOptions): TextButton
	local button: TextButton = Theme.new("TextButton", {
		Size = options.size,
		Position = options.position or UDim2.new(),
		AnchorPoint = options.anchor or Vector2.zero,
		BackgroundColor3 = options.color,
		AutoButtonColor = false,
		Font = Theme.Font,
		Text = options.text,
		TextScaled = true,
		RichText = true,
		TextColor3 = options.textColor or Theme.Colors.White,
		LayoutOrder = options.layoutOrder or 0,
		BorderSizePixel = 0,
	})
	Theme.corner(button, 14)
	Theme.stroke(button, Theme.Colors.Shadow, 3)
	Theme.keyGradient(button)
	Theme.textStroke(button)
	Theme.new("UIPadding", {
		PaddingTop = UDim.new(0.1, 0),
		PaddingBottom = UDim.new(0.22, 0),
		PaddingLeft = UDim.new(0.06, 0),
		PaddingRight = UDim.new(0.06, 0),
		Parent = button,
	})
	local scale = scaleOf(button)
	button.MouseEnter:Connect(function()
		Theme.tween(scale, 0.12, { Scale = 1.06 })
	end)
	button.MouseLeave:Connect(function()
		Theme.tween(scale, 0.12, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		Theme.tween(scale, 0.08, { Scale = 0.92 })
	end)
	button.MouseButton1Up:Connect(function()
		Theme.tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	button.Activated:Connect(function()
		Sounds.play("ButtonClick")
	end)
	if options.parent then
		button.Parent = options.parent
	end
	return button
end

export type TileOptions = {
	icon: string,
	caption: string,
	color: Color3,
	size: number,
	layoutOrder: number?,
	parent: Instance?,
}

export type Tile = { button: TextButton, icon: TextLabel, caption: TextLabel }

-- A square HUD button: a big emoji icon on a colored key, with a caption under it.
function Theme.tile(options: TileOptions): Tile
	local size = options.size
	local holder = Theme.frame({
		Name = options.caption,
		Size = UDim2.fromOffset(size, size + 20),
		BackgroundTransparency = 1,
		LayoutOrder = options.layoutOrder or 0,
		Parent = options.parent,
	})
	local button = Theme.button({
		text = "",
		color = options.color,
		size = UDim2.fromOffset(size, size),
		parent = holder,
	})
	button.Name = "Button"
	local icon = Theme.label({
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.43),
		Size = UDim2.fromScale(0.8, 0.8),
		Text = options.icon,
		Parent = button,
	})
	local caption = Theme.label({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 4, 0, 22),
		Text = options.caption,
		Parent = holder,
	})
	Theme.textStroke(caption, 3)
	return { button = button, icon = icon, caption = caption }
end

-- Greys a button out (or restores its color) without changing its text.
function Theme.setEnabled(button: TextButton, enabled: boolean, color: Color3)
	button.BackgroundColor3 = if enabled then color else Theme.Colors.Gray
	button.AutoButtonColor = false
	button.Active = enabled
end

---------------------------------------------------------------------------
-- Screens, scaling and panels
---------------------------------------------------------------------------

local scaled: { UIScale } = {}

local function screenScale(): number
	local camera = workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return math.clamp(math.min(size.X / 1280, size.Y / 720), 0.55, 1.15)
end

local function updateScales()
	local value = screenScale()
	for _, scale in scaled do
		scale.Scale = value
	end
end

-- Makes a top-level container shrink on small (phone) screens. It scales around its AnchorPoint.
function Theme.autoScale(guiObject: GuiObject)
	local scale = Theme.new("UIScale", { Name = "ScreenScale", Scale = screenScale(), Parent = guiObject })
	table.insert(scaled, scale)
end

function Theme.screen(name: string, displayOrder: number?): ScreenGui
	return Theme.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder or 0,
		Parent = player:WaitForChild("PlayerGui"),
	})
end

export type Panel = {
	screen: ScreenGui,
	window: Frame,
	content: Frame,
	isOpen: () -> boolean,
	open: () -> (),
	close: () -> (),
}

local panels: { [string]: Panel } = {}
local openHandlers: { [string]: (...any) -> () } = {}

-- A pop-up window with a colored title bar, a close button and a dimmed background.
function Theme.panel(name: string, title: string, size: Vector2, color: Color3): Panel
	local screen = Theme.screen(name, 5)
	screen.Enabled = false

	local dim = Theme.frame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Active = true,
		Parent = screen,
	})

	local window = Theme.frame({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = Theme.Colors.Cream,
		Parent = screen,
	})
	Theme.corner(window, 22)
	Theme.stroke(window, Theme.Colors.Shadow, 5)
	Theme.autoScale(window)

	-- A colored banner across the top, with the title in big outlined letters
	local header =
		Theme.frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = color, Parent = window })
	Theme.corner(header, 22)
	Theme.keyGradient(header, 0.14)
	-- Square off the bottom corners of the header.
	local squareOff = Theme.frame({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.42),
		Parent = header,
	})
	squareOff.ZIndex = 0
	Theme.frame({
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Shadow,
		Parent = header,
	})
	local titleLabel = Theme.label({
		Size = UDim2.new(1, -140, 0, 46),
		Position = UDim2.fromOffset(22, 7),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = header,
	})
	Theme.textStroke(titleLabel, 3)

	local content = Theme.frame({
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 76),
		Size = UDim2.new(1, -32, 1, -92),
		Parent = window,
	})

	local panel: Panel
	local function close()
		if not screen.Enabled then
			return
		end
		screen.Enabled = false
	end
	local function open()
		for otherName, other in panels do
			if otherName ~= name then
				other.close()
			end
		end
		screen.Enabled = true
		Theme.pop(window, 0.8)
	end

	local closeButton = Theme.button({
		text = "X",
		color = Theme.Colors.Red,
		size = UDim2.fromOffset(54, 54),
		position = UDim2.new(1, 14, 0, -14),
		anchor = Vector2.new(1, 0),
		parent = header,
	})
	closeButton.ZIndex = 3
	local round = closeButton:FindFirstChildOfClass("UICorner")
	if round then
		round.CornerRadius = UDim.new(0.5, 0)
	end
	closeButton.Activated:Connect(close)
	dim.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			close()
		end
	end)

	panel = {
		screen = screen,
		window = window,
		content = content,
		isOpen = function()
			return screen.Enabled
		end,
		open = open,
		close = close,
	}
	panels[name] = panel
	return panel
end

-- Lets any script open a panel by name, e.g. Theme.openPanel("Shop", "Upgrades").
function Theme.onOpen(name: string, handler: (...any) -> ())
	openHandlers[name] = handler
end

function Theme.openPanel(name: string, ...: any)
	local handler = openHandlers[name]
	if handler then
		handler(...)
	end
end

function Theme.togglePanel(name: string, ...: any)
	local panel = panels[name]
	if panel and panel.isOpen() then
		panel.close()
	else
		Theme.openPanel(name, ...)
	end
end

function Theme.closeAll()
	for _, panel in panels do
		panel.close()
	end
end

task.defer(function()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScales)
	end
	updateScales()
end)

return Theme
