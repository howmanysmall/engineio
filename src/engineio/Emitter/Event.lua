local Event = {}
Event.__index = Event

function Event.new()
	return setmetatable({
		BindableEvent = Instance.new("BindableEvent");
	}, Event)
end

function Event:Fire(...)
	local Arguments = table.pack(...)
	self.BindableEvent:Fire(function()
		return table.unpack(Arguments, 1, Arguments.n)
	end)
end

function Event:Connect(Function)
	return self.BindableEvent.Event:Connect(function(Arguments)
		Function(Arguments())
	end)
end

function Event:Wait()
	return self.BindableEvent.Event:Wait()()
end

local NULL = nil

function Event:Destroy()
	self.BindableEvent = self.BindableEvent:Destroy()
	setmetatable(self, NULL)
end

return Event