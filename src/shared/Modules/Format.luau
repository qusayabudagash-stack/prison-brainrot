-- Turns numbers and times into short, kid-readable text like "$12,500", "1.25M" or "4:05".

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function withCommas(n: number): string
	local text = string.format("%d", math.floor(n))
	local count
	repeat
		text, count = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return text
end

local function trimZeros(text: string): string
	if string.find(text, "%.") then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text
end

function Format.number(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)
	if n < 1e6 then
		return sign .. withCommas(n)
	end
	local index = 0
	local scaled = n
	while scaled >= 1000 and index < #SUFFIXES do
		scaled /= 1000
		index += 1
	end
	local digits = if scaled < 10 then "%.2f" elseif scaled < 100 then "%.1f" else "%.0f"
	return sign .. trimZeros(string.format(digits, scaled)) .. SUFFIXES[index]
end

function Format.money(n: number): string
	return "$" .. Format.number(n)
end

function Format.time(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

-- `fraction` is a probability between 0 and 1.
function Format.chance(fraction: number): string
	local percent = fraction * 100
	if percent <= 0 then
		return "0%"
	end
	local digits = if percent >= 10
		then "%.1f"
		elseif percent >= 1 then "%.2f"
		elseif percent >= 0.1 then "%.3f"
		elseif percent >= 0.001 then "%.4f"
		else "%.6f"
	return trimZeros(string.format(digits, percent)) .. "%"
end

function Format.oneIn(fraction: number): string
	if fraction <= 0 then
		return "never"
	end
	return "1 in " .. Format.number(math.max(1, math.floor(1 / fraction + 0.5)))
end

function Format.multiplier(x: number): string
	local text = string.format("%.2f", x)
	text = string.gsub(text, "0$", "")
	return text .. "x"
end

return Format
