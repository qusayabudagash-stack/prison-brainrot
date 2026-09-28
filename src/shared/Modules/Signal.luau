-- A tiny event object for letting services react to each other's changes without requiring each other.

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: () -> (),
}

export type Signal = typeof(setmetatable({} :: { _handlers: { (...any) -> () } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, handler: (...any) -> ()): Connection
	table.insert(self._handlers, handler)
	return {
		Disconnect = function()
			local index = table.find(self._handlers, handler)
			if index then
				table.remove(self._handlers, index)
			end
		end,
	}
end

function Signal.Fire(self: Signal, ...: any)
	for _, handler in table.clone(self._handlers) do
		task.spawn(handler, ...)
	end
end

return Signal
