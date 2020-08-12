local Promise = require(script.Parent.Promise)

local Timer = {}
Timer.__index = Timer

function Timer.new(Function)
	return setmetatable({
		Function = Function;
		Active = false;
	}, Timer)
end

function Timer:Start(Time: number)
	self.Active = true
	self.Time = Time

	Promise.try(function()
		while self.Active do
			Promise.delay(self.Time):await()
			if not self.Active then
				break
			end

			Promise.try(self.Function)
		end
	end)

	return self
end

function Timer:Stop()
	self.Active = false
end

return Timer