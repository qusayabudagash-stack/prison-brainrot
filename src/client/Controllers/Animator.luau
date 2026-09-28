-- Brings the Brainrots standing around the prison to life. Designs tag their parts with a rig
-- group (see Modules/Brainrots/Kit); this controller moves each group every frame:
--   Body        a gentle idle bob            ArmL/ArmR   a slow swing at the shoulder
--   WingL/WingR flapping at the wing root    Orbit       circling the character
--   Spin        turning in place (halos)     Glory       the Divine sunburst, turning slowly
--   Legs        planted (never moves)
-- Models tagged "Spin" (the machines' featured Brainrots) also turn as a whole.
-- Only anchored models are animated: welded ones (escaped Brainrots) are moved by the server.

local RunService = game:GetService("RunService")

local Animator = {}

type Track = {
	parts: { BasePart },
	base: { CFrame },
	groups: { string },
	phase: number,
	scale: number,
	spin: boolean,
	joints: { [string]: Vector3 },
	spinCenter: Vector3,
}

local tracked: { [Model]: Track } = {}
local RANGE = 160
local STEP = 1 / 30

local bulkMove: ((parts: { BasePart }, cframes: { CFrame }) -> ())? = nil

local function moveParts(parts: { BasePart }, cframes: { CFrame })
	if bulkMove then
		bulkMove(parts, cframes)
		return
	end
	for i, part in parts do
		part.CFrame = cframes[i]
	end
end

local function register(model: Model)
	if tracked[model] or not model:GetAttribute("BrainrotId") then
		return
	end
	local root = model.PrimaryPart
	if not root or not root.Anchored then
		return
	end
	local spin = model:HasTag("Spin")
	local pivot = model:GetPivot()
	local track: Track = {
		parts = {},
		base = {},
		groups = {},
		phase = math.random() * 10,
		scale = (model:GetAttribute("Scale") :: number?) or 1,
		spin = spin,
		joints = {},
		spinCenter = Vector3.zero,
	}
	local spinSum, spinCount = Vector3.zero, 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root and descendant.Anchored then
			local rig = descendant:GetAttribute("Rig")
			local group = if typeof(rig) == "string" then rig else ""
			-- Legs and untagged parts only move when the whole model spins
			if spin or (group ~= "" and group ~= "Legs") then
				local offset = pivot:ToObjectSpace(descendant.CFrame)
				table.insert(track.parts, descendant)
				table.insert(track.base, offset)
				table.insert(track.groups, group)
				if group == "Spin" then
					spinSum += offset.Position
					spinCount += 1
				end
			end
		end
	end
	if spinCount > 0 then
		track.spinCenter = spinSum / spinCount
	end
	for _, name in { "ArmL", "ArmR", "WingL", "WingR", "Glory" } do
		local joint = model:GetAttribute(name .. "Joint")
		if typeof(joint) == "Vector3" then
			track.joints[name] = joint * track.scale
		end
	end
	if #track.parts > 0 then
		tracked[model] = track
	end
end

local function about(point: Vector3, rotation: CFrame): CFrame
	return CFrame.new(point) * rotation * CFrame.new(-point)
end

-- Motion of one rig group at time t, in the model's pivot space.
local function motion(track: Track, group: string, t: number): CFrame
	local s = track.scale
	local bob = CFrame.new(0, math.sin(t * 2.2) * 0.09 * s, 0)
	if group == "Body" then
		return bob
	elseif group == "ArmL" or group == "ArmR" then
		local joint = track.joints[group]
		if not joint then
			return bob
		end
		local side = if group == "ArmL" then -1 else 1
		return bob * about(joint, CFrame.Angles(0, 0, math.sin(t * 2.2 + 0.6) * 0.14 * side))
	elseif group == "WingL" or group == "WingR" then
		local joint = track.joints[group]
		if not joint then
			return bob
		end
		local side = if group == "WingL" then -1 else 1
		return bob * about(joint, CFrame.Angles(0, math.sin(t * 5.5) * 0.3 * side, 0))
	elseif group == "Orbit" then
		return bob * CFrame.Angles(0, t * 1.3, 0)
	elseif group == "Spin" then
		return bob * about(track.spinCenter, CFrame.Angles(0, t * 1.6, 0))
	elseif group == "Glory" then
		local joint = track.joints.Glory
		return if joint then about(joint, CFrame.Angles(0, 0, t * 0.35)) else CFrame.identity
	end
	return CFrame.identity
end

local accumulated = 0

local function step(dt: number)
	accumulated += dt
	if accumulated < STEP then
		return
	end
	accumulated = 0
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local now = os.clock()
	local parts, cframes = {}, {}
	for model, track in tracked do
		if not model.Parent then
			tracked[model] = nil
			continue
		end
		local pivot = model:GetPivot()
		if (pivot.Position - eye).Magnitude > RANGE then
			continue
		end
		local t = now + track.phase
		local spin = if track.spin then CFrame.Angles(0, now * 0.9, 0) else CFrame.identity
		local cache: { [string]: CFrame } = {}
		for i, part in track.parts do
			if part.Parent then
				local group = track.groups[i]
				local move = cache[group]
				if not move then
					move = motion(track, group, t)
					cache[group] = move
				end
				table.insert(parts, part)
				table.insert(cframes, pivot * spin * move * track.base[i])
			end
		end
	end
	if #parts > 0 then
		moveParts(parts, cframes)
	end
end

function Animator.init()
	local ok = pcall(function()
		local probe = (workspace :: any).BulkMoveTo
		assert(typeof(probe) == "function", "BulkMoveTo unavailable")
	end)
	if ok then
		bulkMove = function(parts, cframes)
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") then
			register(descendant)
		end
	end
	workspace.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("Model") and descendant:GetAttribute("BrainrotId") then
			-- Let the rest of the model replicate first
			task.defer(function()
				register(descendant)
			end)
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return Animator
