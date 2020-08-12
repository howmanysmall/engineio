local HttpService = game:GetService("HttpService")
local Promise = require(script.Parent.Promise)
local t = require(script.Parent.t)

local HttpPromise = {}

local OptionalBoolean = t.optional(t.boolean)
local HeadersType = t.optional(t.keys(t.string))

local PromiseGetTuple = t.tuple(t.string, OptionalBoolean, HeadersType)
local PromisePostTuple = t.tuple(t.string, t.string, t.optional(t.enum(Enum.HttpContentType)), OptionalBoolean, HeadersType)

-- TODO: Rewrite this to use HttpService:RequestAsync.
function HttpPromise.PromiseGet(Url: string, NoCache, Headers)
	local TypeSuccess, TypeError = PromiseGetTuple(Url, NoCache, Headers)
	if not TypeSuccess then
		return Promise.reject(TypeError)
	end

	return Promise.defer(function(Resolve, Reject)
		local Success, Value = pcall(HttpService.GetAsync, HttpService, Url, NoCache, Headers);
		(Success and Resolve or Reject)(Value)
	end)
end

function HttpPromise.PromisePost(Url: string, Data: string, HttpContentType, Compress, Headers)
	local TypeSuccess, TypeError = PromisePostTuple(Url, Data, HttpContentType, Compress, Headers)
	if not TypeSuccess then
		return Promise.reject(TypeError)
	end

	return Promise.defer(function(Resolve, Reject)
		local Success, Value = pcall(HttpService.PostAsync, HttpService, Url, Url, Data, HttpContentType, Compress, Headers);
		(Success and Resolve or Reject)(Value)
	end)
end

return HttpPromise