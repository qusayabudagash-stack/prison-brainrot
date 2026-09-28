-- Reads the current server event. EventService sets it as attributes on ReplicatedStorage,
-- so the server and every client see the same event and multipliers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(script.Parent.GameConfig)

export type EventInfo = {
	id: string,
	name: string,
	description: string,
	duration: number,
	weight: number,
	color: Color3,
}

local Events = {}

Events.ById = {} :: { [string]: EventInfo }
for _, event in GameConfig.EVENTS.list do
	Events.ById[event.id] = event
end

function Events.currentId(): string?
	local id = ReplicatedStorage:GetAttribute("EventId")
	local endsAt = ReplicatedStorage:GetAttribute("EventEndsAt")
	if typeof(id) == "string" and id ~= "" and typeof(endsAt) == "number" and endsAt > workspace:GetServerTimeNow() then
		return id
	end
	return nil
end

function Events.endsAt(): number
	local endsAt = ReplicatedStorage:GetAttribute("EventEndsAt")
	return if typeof(endsAt) == "number" then endsAt else 0
end

function Events.isActive(id: string): boolean
	return Events.currentId() == id
end

function Events.incomeMultiplier(): number
	return if Events.isActive("DoubleIncome") then GameConfig.EVENTS.doubleIncomeMultiplier else 1
end

function Events.luckMultiplier(): number
	return if Events.isActive("LuckyHour") then GameConfig.EVENTS.luckyHourMultiplier else 1
end

function Events.rollSpeed(): number
	return if Events.isActive("CrazyRolls") then GameConfig.EVENTS.crazyRollSpeed else 1
end

return Events
