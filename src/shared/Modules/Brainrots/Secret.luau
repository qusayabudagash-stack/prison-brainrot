-- SECRET Brainrot: a glitching shadow nobody can explain. Its rainbow aura comes from Effects.

local Kit = require(script.Parent.Kit)

type Kit = Kit.Kit

local rgb = Color3.fromRGB
local v3 = Vector3.new

local Secret: { [string]: (Kit) -> BasePart } = {}

local SPECTRUM = {
	rgb(255, 70, 90),
	rgb(255, 160, 40),
	rgb(255, 230, 60),
	rgb(80, 225, 110),
	rgb(60, 170, 255),
	rgb(170, 90, 255),
}

Secret.SecretBrainrot = function(k)
	local void = rgb(24, 18, 36)
	local glow = rgb(235, 240, 255)
	local shell: Kit.Shell = { center = v3(0, 3.3, 0), radii = v3(1.7, 1.8, 1.6) }

	-- A floating void with a glitch: magenta and cyan ghosts slip out of each side
	local body = k:ellipsoid("Body", shell.radii * 2, CFrame.new(shell.center), void, nil, "Body")
	for _, spec in { { x = -0.12, color = rgb(40, 230, 255) }, { x = 0.12, color = rgb(255, 60, 200) } } do
		-- shallower than the body, so the ghosts only show at the silhouette's edges
		local ghost = k:ellipsoid(
			"Glitch",
			v3(shell.radii.X * 2, shell.radii.Y * 2, shell.radii.Z * 1.6),
			CFrame.new(shell.center + v3(spec.x, 0.03, 0)),
			spec.color,
			Enum.Material.Neon,
			"Body"
		)
		ghost.Transparency = 0.35
	end
	for i, y in { 2.6, 3.5, 4.1 } do
		local rx, rz = Kit.widthAt(shell, y)
		local slice = k:part(
			"GlitchSlice",
			v3(rx * 2 + 0.25, 0.1, rz * 1.4),
			CFrame.new((if i % 2 == 0 then -1 else 1) * 0.18, y, -0.3),
			void,
			nil,
			"Body"
		)
		slice.CastShadow = false
	end

	-- Mismatched glowing eyes, no mouth
	k:eye(Kit.on(shell, -22, 22, -0.1), { width = 0.78, height = 0.98, style = "Glow", glow = glow }, "Body")
	k:eye(Kit.on(shell, 24, 16, -0.08), { width = 0.52, height = 0.62, style = "Glow", glow = glow }, "Body")
	k:badge(Kit.on(shell, 0, -30, 0.02), "#???", 0.8, "Body")

	-- Wispy tail instead of legs
	local wisp = { v3(0, 1.6, 0), v3(0.3, 0.95, 0.1), v3(-0.15, 0.45, 0.25), v3(0.25, 0.15, 0.35) }
	for i = 1, #wisp - 1 do
		k:limb("Wisp", wisp[i], wisp[i + 1], 1.3 - i * 0.35, void, nil, "Body")
	end

	-- Floating white gloves
	for _, side in { -1, 1 } do
		local rig = if side > 0 then "ArmR" else "ArmL"
		local hand = v3(side * 2.35, 3.0 + (if side > 0 then 0.5 else 0), -0.35)
		k:ellipsoid("Hand", v3(0.62, 0.7, 0.55), CFrame.new(hand), rgb(250, 250, 255), nil, rig)
		k:ellipsoid(
			"Thumb",
			v3(0.26, 0.34, 0.26),
			CFrame.new(hand + v3(-side * 0.28, 0.12, -0.12)),
			rgb(250, 250, 255),
			nil,
			rig
		)
		k:cylinder(
			"GloveCuff",
			0.18,
			0.62,
			CFrame.new(hand + v3(side * 0.28, -0.05, 0.05)) * CFrame.Angles(0, 0, math.pi / 2),
			rgb(250, 250, 255),
			nil,
			rig
		)
		k.model:SetAttribute(rig .. "Joint", v3(side * 1.5, 3.2, 0))
	end

	-- A spectrum question mark hovering overhead
	local center = v3(0, 6.65, 0)
	local points = {}
	for i = 0, 5 do
		local angle = math.rad(160 - i * 42)
		table.insert(points, center + v3(math.cos(angle) * 0.5, math.sin(angle) * 0.5, 0))
	end
	table.insert(points, center + v3(0, -0.72, 0))
	for i = 1, #points - 1 do
		k:limb("Question", points[i], points[i + 1], 0.26, SPECTRUM[i], Enum.Material.Neon, "Spin")
	end
	k:ball("QuestionDot", 0.3, center + v3(0, -1.12, 0), SPECTRUM[6], Enum.Material.Neon, "Spin")

	-- Tiny "?" cards in orbit
	for i = 0, 2 do
		local angle = i * math.pi * 2 / 3
		local card = k:part(
			"QuestionCard",
			v3(0.55, 0.7, 0.05),
			CFrame.new(math.cos(angle) * 2.6, 4.3 + i * 0.35, math.sin(angle) * 2.6) * CFrame.Angles(0, -angle, 0),
			void,
			nil,
			"Orbit"
		)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Parent = card
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = SPECTRUM[i * 2 + 1]
		text.Text = "?"
		text.Parent = gui
	end
	return body
end

return Secret
