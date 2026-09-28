-- Calls a server RemoteFunction and shows the server's error message (e.g. "Not enough coins!") if it fails.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnnouncementUI = require(script.Parent.Parent.UI.AnnouncementUI)
local Net = require(ReplicatedStorage.Modules.Net)
local Sounds = require(script.Parent.Sounds)

local Remote = {}

export type Response = { [string]: any }

function Remote.call(name: string, ...: any): Response
	local args = table.pack(...)
	local ok, result = pcall(function()
		return Net.func(name):InvokeServer(table.unpack(args, 1, args.n))
	end)
	local response: Response = if ok and type(result) == "table"
		then result
		else { ok = false, message = "Connection hiccup - try again!" }
	if not response.ok and response.message then
		AnnouncementUI.toast(response.message, "error")
		Sounds.play("Error")
	end
	return response
end

return Remote
