-- Server-wide announcements, personal notifications and visual effects sent to clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Modules.Net)

export type AnnounceOptions = {
	color: Color3?,
	duration: number?,
	sound: string?,
	-- "normal", "big" or "secret" (full-screen rainbow for everyone).
	style: string?,
}

local AnnouncementService = {}

function AnnouncementService.announce(text: string, options: AnnounceOptions?)
	local opts: AnnounceOptions = options or {}
	Net.event("Announce"):FireAllClients({
		text = text,
		color = opts.color or Color3.fromRGB(255, 220, 60),
		duration = opts.duration or 5,
		sound = opts.sound or "Announcement",
		style = opts.style or "normal",
	})
end

-- kind: "info", "success", "error", "achievement" or "unlock".
function AnnouncementService.notify(player: Player, text: string, kind: string?)
	Net.event("Notify"):FireClient(player, { text = text, kind = kind or "info" })
end

-- Floating text in the world, e.g. "+$5,000" where an escaped Brainrot was caught.
function AnnouncementService.floatText(position: Vector3, text: string, color: Color3?)
	Net.event("Effect"):FireAllClients("FloatText", {
		position = position,
		text = text,
		color = color or Color3.fromRGB(255, 230, 80),
	})
end

return AnnouncementService
