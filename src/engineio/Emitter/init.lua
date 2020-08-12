local Event = require(script.Event)

local Emitter = {}
Emitter.__index = Emitter

local EventsMeta = {
	__index = function(self, Index)
		local Value = Event.new()
		self[Index] = Value
		return Value
	end;
}

function Emitter.new()
	return setmetatable({
		_Events = setmetatable({}, EventsMeta);
	}, Emitter)
end

function Emitter:Emit(EventName: string, ...)
	self._Events[EventName]:Fire(...)
end

function Emitter:On(EventName: string, Function)
	return self._Events[EventName]:Connect(Function)
end

function Emitter:Wait(EventName: string)
	return self._Events[EventName]:Wait()
end

return Emitter