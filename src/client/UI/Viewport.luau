-- Shows a 3D Brainrot model inside a ViewportFrame (for roll cards and the Brainrot Book).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotModel = require(ReplicatedStorage.Modules.BrainrotModel)

local Viewport = {}

local spinning: { [ViewportFrame]: number } = {}
local spinConnection: RBXScriptConnection? = nil

function Viewport.new(props: { [string]: any }): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(190, 190, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-0.6, -1, 0.8)
	for key, value in props do
		if key ~= "Parent" then
			(viewport :: any)[key] = value
		end
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = props.Parent
	return viewport
end

-- Replaces whatever is in the viewport with this Brainrot. `hidden` shows a black silhouette.
function Viewport.show(viewport: ViewportFrame, brainrotId: string, variant: string?, hidden: boolean?)
	for _, child in viewport:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	local model = BrainrotModel.build(brainrotId, { variant = variant })
	if hidden then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(25, 20, 40)
				descendant.Material = Enum.Material.SmoothPlastic
			elseif descendant:IsA("Light") or descendant:IsA("ParticleEmitter") then
				descendant:Destroy()
			end
		end
	end
	model:PivotTo(CFrame.new())
	model.Parent = viewport

	-- Frame the character by whichever is bigger: its height or its width.
	local bounds = BrainrotModel.bounds(brainrotId)
	local size = math.max(bounds.Y, bounds.X * 0.95)
	local camera = viewport:FindFirstChildOfClass("Camera")
	if camera then
		local focus = Vector3.new(0, bounds.Y * 0.5, 0)
		camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, size * 0.18, -size * 2.2), focus)
	end
	if spinning[viewport] then
		spinning[viewport] = 0
	end
end

local function step(dt: number)
	for viewport, angle in spinning do
		if not viewport.Parent then
			spinning[viewport] = nil
			continue
		end
		angle += dt * 1.2
		spinning[viewport] = angle
		local model = viewport:FindFirstChildOfClass("Model")
		if model and viewport.Visible then
			model:PivotTo(CFrame.Angles(0, math.sin(angle) * 0.6, 0))
		end
	end
	if next(spinning) == nil and spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end
end

-- Gently sways the model left and right while `enabled`.
function Viewport.setSpinning(viewport: ViewportFrame, enabled: boolean)
	if enabled then
		spinning[viewport] = 0
	else
		spinning[viewport] = nil
	end
	if enabled and not spinConnection then
		spinConnection = RunService.RenderStepped:Connect(step)
	end
end

return Viewport
