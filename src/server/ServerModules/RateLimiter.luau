-- Per-player token bucket: allows `count` calls per `per` seconds, refilling smoothly.

local Players = game:GetService("Players")

local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, last: number }

export type RateLimiter = typeof(setmetatable(
	{} :: { count: number, per: number, buckets: { [Player]: Bucket } },
	RateLimiter
))

local limiters: { RateLimiter } = {}

function RateLimiter.new(count: number, per: number): RateLimiter
	local self = setmetatable({ count = count, per = per, buckets = {} }, RateLimiter)
	table.insert(limiters, self)
	return self
end

function RateLimiter.allow(self: RateLimiter, player: Player): boolean
	local now = os.clock()
	local bucket = self.buckets[player]
	if not bucket then
		bucket = { tokens = self.count, last = now }
		self.buckets[player] = bucket
	end
	bucket.tokens = math.min(self.count, bucket.tokens + (now - bucket.last) * self.count / self.per)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player)
	for _, limiter in limiters do
		limiter.buckets[player] = nil
	end
end)

return RateLimiter
