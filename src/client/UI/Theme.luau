-- The UI toolkit: colors, fonts, and helpers for bouncy buttons, rounded panels and tweens.
-- Every screen in the game is built from these so the style stays consistent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Sounds = require(script.Parent.Parent.Controllers.Sounds)

local Theme = {}

Theme.Font = Enum.Font.FredokaOne

Theme.Colors = {
	White = Color3.fromRGB(255, 255, 255),
	Cream = Color3.fromRGB(255, 248, 235),
	Dark = Color3.fromRGB(45, 35, 75),
	Shadow = Color3.fromRGB(20, 15, 40),
	Gold = Color3.fromRGB(255, 200, 40),
	Green = Color3.fromRGB(70, 210, 90),
	Lime = Color3.fromRGB(150, 240, 80),
	Red = Color3.fromRGB(255, 70, 80),
	Blue = Color3.fromRGB(70, 150, 255),
	Purple = Color3.fromRGB(160, 90, 255),
	Pink = Color3.fromRGB(255, 100, 190),
	Orange = Color3.fromRGB(255, 150, 40),
	Gray = Color3.fromRGB(150, 150, 165),
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

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	return Theme.new("UIStroke", {
		Color = color or Theme.Colors.Shadow,
		Thickness = thickness or 3,
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
	Theme.gradient(button, Theme.Colors.White)
	Theme.textStroke(button)
	Theme.new("UIPadding", {
		PaddingTop = UDim.new(0.12, 0),
		PaddingBottom = UDim.new(0.12, 0),
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

	local header =
		Theme.frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = color, Parent = window })
	Theme.corner(header, 22)
	-- Square off the bottom corners of the header.
	Theme.frame({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = color,
		Parent = header,
	})
	Theme.label({
		Size = UDim2.new(1, -140, 0, 48),
		Position = UDim2.fromOffset(20, 8),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = header,
	})

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
		size = UDim2.fromOffset(52, 52),
		position = UDim2.new(1, -60, 0, 6),
		parent = header,
	})
	closeButton.ZIndex = 3
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
