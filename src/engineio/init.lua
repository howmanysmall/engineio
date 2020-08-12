local HttpService = game:GetService("HttpService")
local Emitter = require(script.Emitter)
local Promise = require(script.Promise)
local Timer = require(script.Timer)
local Transport = require(script.Transport)

local Socket = setmetatable({}, Emitter)
Socket.__index = Socket

function Socket.new(Uri, Path)
	local self = setmetatable(Emitter.new(), Socket)
	if Uri then
		local Schema = string.match(Uri, "^(%w+)://")
		local Host = string.match(string.gsub(Uri, "^%w+://", ""), "^([%w%.-]+:?%d*)")

		self.Host = Host
		self.Secure = Schema == "https" or Schema == "wss"
	else
		self.Host = "localhost"
		self.Secure = false
	end

	self.Path = Path or "/engine.io"
	self:Open()
	return self
end

function Socket:Open()
	self._Transport = Transport.new {
		Host = self.Host;
		Secure = self.Secure;
		Path = self.Path;
	}

	self._Transport:On("packet", function(Packet)
		if Packet.Type == "open" then
			local Data = HttpService:JSONDecode(Packet.Data)
			self._Transport.Id = Data.sid

			self._PingTimeout = Data.pingTimeout / 1000
			self._PingInterval = Data.pingInterval / 1000

			self._PingTimer = Timer.new(function()
				self:Ping()
			end):Start(self._PingInterval)
		end

		if Packet.Type == "error" then
			self:Close(true)
		else
			self:Emit(Packet.Type, Packet.Data)
		end
	end)

	self._Transport:On("error", function()
		self:Close(true)
	end)
end

local PING_TYPE = {Type = "ping"}
local CLOSE_TYPE = {Type = "close"}

function Socket:Ping()
	self:Emit("ping")
	Promise.try(function()
		local Success = false
		Promise.delay(self._PingTimeout):andThen(function()
			if not Success then
				self:Close(true)
			end
		end)

		self._Transport:Write(PING_TYPE)
		self:Wait("pong")
		Success = true
	end)
end

function Socket:Send(Data)
	self._Transport:Write {
		Type = "message";
		Data = Data;
	}
end

function Socket:Close(Error)
	if Error then
		self:Emit("close", true)
	else
		self._Transport:Write(CLOSE_TYPE)
		self._Transport:Flush(true)
	end

	self._Transport:Close()
	if self._PingTimer then
		self._PingTimer:Stop()
	end
end

return Socket