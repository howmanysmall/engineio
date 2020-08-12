local Emitter = require(script.Parent.Emitter)
local HttpPromise = require(script.Parent.HttpPromise)
local Parser = require(script.Parent.Parser)
local t = require(script.Parent.t)

local Transport = setmetatable({}, Emitter)
Transport.__index = Transport

local IOptions = t.strictInterface {
	Host = t.string;
	Secure = t.boolean;
	Path = t.string;
}

function Transport.new(Options)
	assert(IOptions(Options))
	local self = setmetatable(Emitter.new(), Transport)
	self.Host = Options.Host
	self.Secure = Options.Secure
	self.Path = Options.Path

	self._WriteBuffer = {}
	self._Flushing = false
	self._Open = false

	self:Open()
	return self
end

function Transport:Open()
	self._Open = true
	HttpPromise.PromiseGet(self:URI(), true):andThen(function(Response)
		for _, Packet in ipairs(Parser:Decode(Response)) do
			self:Emit("packet", Packet)
		end

		self:Read()
	end):catch(function(ResponseError)
		self:Emit("error", tostring(ResponseError))
	end)
end

function Transport:Close()
	self._Open = false
end

function Transport:Read()
	if self._Open then
		HttpPromise.PromiseGet(self:URI(), true):andThen(function(Response)
			for _, Packet in ipairs(Parser:Decode(Response)) do
				self:Emit("packet", Packet)
			end

			self:Read()
		end):catch(function(ResponseError)
			self:Emit("error", ResponseError)
		end)
	end
end

function Transport:Write(Packet)
	table.insert(self._WriteBuffer, Packet)
	self:Flush()
end

function Transport:Flush(Force)
	if (self._Open and not self._Flushing and #self._WriteBuffer > 0) or Force then
		self._Flushing = true
		HttpPromise.PromisePost(self:URI(), Parser:Encode(self._WriteBuffer)):andThen(function()
			self._WriteBuffer = {}
			self._Flushing = false
			self:Flush()
		end):catch(function(ResponseError)
			self:Emit("error", tostring(ResponseError))
		end)
	end
end

function Transport:URI(): string
	local URI = string.format(
		"%s://%s%s",
		self.Secure and "https" or "http",
		self.Host,
		string.gsub(self.Path, "/$", "") .. "/"
	)

	local Query = {
		b64 = 1;
		transport = "polling";
		sid = self.Id;
	}

	local Parameters = {}
	local Length = 0

	for Key, Value in next, Query do
		Length += 1
		Parameters[Length] = Key .. "=" .. Value
	end

	return URI .. "?" .. table.concat(Parameters, "&")
end

return Transport