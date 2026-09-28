-- Starts every server service. init() runs for all services first (so they can connect to each other's
-- signals), then start() runs for all of them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Modules.Net)
Net.setup()

local Services = ServerScriptService.Services

type Service = {
	init: (() -> ())?,
	start: (() -> ())?,
}

-- Order matters: the map must exist before cells and boards are used, and DataService.start
-- (which begins loading players) runs after every other service has hooked up its listeners.
local services: { Service } = {
	require(Services.MapService) :: any,
	require(Services.DataService) :: any,
	require(Services.AnnouncementService) :: any,
	require(Services.StateService) :: any,
	require(Services.EconomyService) :: any,
	require(Services.AchievementService) :: any,
	require(Services.BrainrotService) :: any,
	require(Services.RollService) :: any,
	require(Services.UpgradeService) :: any,
	require(Services.AreaService) :: any,
	require(Services.RebirthService) :: any,
	require(Services.ShopService) :: any,
	require(Services.CellService) :: any,
	require(Services.LeaderboardService) :: any,
	require(Services.EventService) :: any,
	require(Services.DevCommandService) :: any,
}

for _, service in services do
	if service.init then
		service.init()
	end
end

for _, service in services do
	if service.start then
		task.spawn(service.start)
	end
end

print("🧠 Prison Brainrot server started")
