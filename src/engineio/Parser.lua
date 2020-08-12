local Parser = {
	Types = setmetatable({
		[0] = "open";
		[1] = "close";
		[2] = "ping";
		[3] = "pong";
		[4] = "message";

		-- unused
		[5] = "upgrade";
		[6] = "noop";
	}, {
		__index = function(self, Index)
			for Id, Type in next, self do
				if Type == Index then
					return Id
				end
			end
		end;
	});
}

function Parser:Encode(Packets): string
	local Payload = ""
	for _, Packet in ipairs(Packets) do
		Payload ..= string.format(
			"%d:%d%s",
			Packet.Data and #Packet.Data + 1 or 1,
			self.Types[Packet.Type],
			Packet.Data or ""
		)
	end

	return Payload
end

function Parser:Decode(String: string)
	local Packets = {}
	local PacketsLength = 0
	repeat
		local Length, Id, Data = string.match(String, "^(%d+):b?(%d)")
		String = string.sub(String, #Length + 1 + #Id + 1)
		local NewLength = tonumber(Length)
		local NewId = tonumber(Id)

		if NewLength > 1 then
			Data = string.sub(String, 1, NewLength - 1)
			String = string.sub(String, NewLength)
		end

		PacketsLength += 1
		Packets[PacketsLength] = {
			Type = self.Types[NewId];
			Data = Data;
		}
	until #String == 0

	return Packets
end

return Parser