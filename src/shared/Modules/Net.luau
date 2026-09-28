-- Every RemoteEvent and RemoteFunction in the game, kept in ReplicatedStorage.Remotes.
-- The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- Server -> client (plus CompleteTutorial, client -> server)
Net.Events = {
	"State",
	"Announce",
	"Notify",
	"ServerRoll",
	"Effect",
	"CompleteTutorial",
}

-- Client -> server requests. The server validates every one of them.
Net.Functions = {
	"Roll",
	"BuyUpgrade",
	"UnlockArea",
	"Rebirth",
	"Combine",
	"CombineAll",
	"BuyCosmetic",
	"ToggleCosmetic",
	"ClaimFreeBoost",
}

local function remotesFolder(): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if existing then
			return existing
		end
		local folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild("Remotes")
end

local function getRemote(name: string, className: string): Instance
	local folder = remotesFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing
		end
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name)
end

function Net.event(name: string): RemoteEvent
	assert(table.find(Net.Events, name), `Unknown RemoteEvent "{name}"`)
	return getRemote(name, "RemoteEvent") :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	assert(table.find(Net.Functions, name), `Unknown RemoteFunction "{name}"`)
	return getRemote(name, "RemoteFunction") :: RemoteFunction
end

-- Called once by the server at startup so clients never wait on a missing remote.
function Net.setup()
	for _, name in Net.Events do
		Net.event(name)
	end
	for _, name in Net.Functions do
		Net.func(name)
	end
end

return Net
