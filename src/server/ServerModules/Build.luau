-- Small helpers for building the map out of anchored parts, signs and prompts.

local Build = {}

local FONT = Enum.Font.FredokaOne

function Build.folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Build.model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Build.part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Decorative part: no collisions, no shadows.
function Build.deco(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Build.part(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

-- Upright cylinder.
function Build.cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Build.part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Build.ball(
	parent: Instance,
	name: string,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Build.part(parent, name, Vector3.new(diameter, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

function Build.light(parent: Instance, color: Color3, range: number, brightness: number?): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1.5
	light.Parent = parent
	return light
end

export type TextOptions = {
	textColor: Color3?,
	background: Color3?,
	strokeColor: Color3?,
	pixelsPerStud: number?,
}

-- Puts text on one face of a part. Returns the label so it can be updated later.
function Build.surfaceText(part: BasePart, face: Enum.NormalId, text: string, options: TextOptions?): TextLabel
	local opts: TextOptions = options or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.pixelsPerStud or 30
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = opts.background or Color3.new(0, 0, 0)
	label.BackgroundTransparency = if opts.background then 0 else 1
	label.Font = FONT
	label.TextScaled = true
	label.RichText = true
	label.TextColor3 = opts.textColor or Color3.new(1, 1, 1)
	label.TextStrokeColor3 = opts.strokeColor or Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.06, 0)
	padding.PaddingBottom = UDim.new(0.06, 0)
	padding.Parent = label
	return label
end

-- Floating text above a part. `size` is in studs.
function Build.billboard(adornee: BasePart, text: string, size: Vector2, offsetY: number, color: Color3?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(size.X, 0, size.Y, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Adornee = adornee
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.RichText = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = gui
	return label
end

-- A ProximityPrompt the client recognises by its Action attribute.
function Build.prompt(
	parent: Instance,
	action: string,
	actionText: string,
	objectText: string,
	attributes: { [string]: any }?
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Prompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", action)
	local extra: { [string]: any } = attributes or {}
	for key, value in extra do
		prompt:SetAttribute(key, value)
	end
	prompt.Parent = parent
	return prompt
end

return Build
