-- Wraps every client request: rate limit, require loaded data, catch errors.
-- Handlers get (player, data, ...args) and return a table like { ok = true } or Guard.fail("message").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Net = require(ReplicatedStorage.Modules.Net)
local RateLimiter = require(script.Parent.RateLimiter)
local Types = require(ReplicatedStorage.Modules.Types)

export type Response = { [string]: any }
type Handler = (Player, Types.PlayerData, ...any) -> Response

local Guard = {}

function Guard.fail(message: string): Response
	return { ok = false, message = message }
end

function Guard.invoke(name: string, handler: Handler)
	local limit = GameConfig.RATE_LIMITS[name] or GameConfig.RATE_LIMITS.default
	local limiter = RateLimiter.new(limit.count, limit.per)

	Net.func(name).OnServerInvoke = function(player: Player, ...: any): Response
		if not limiter:allow(player) then
			return Guard.fail("Slow down!")
		end
		local data = DataService.get(player)
		if not data then
			return Guard.fail("Still loading your prison records...")
		end
		local ok, result = pcall(handler, player, data, ...)
		if not ok then
			warn(`[{name}] failed for {player.Name}: {result}`)
			return Guard.fail("Something went wrong. Try again!")
		end
		return result
	end
end

-- True if `value` is a string key present in `lookup`.
function Guard.isKey(value: any, lookup: { [string]: any }): boolean
	return typeof(value) == "string" and #value <= 64 and lookup[value] ~= nil
end

return Guard
