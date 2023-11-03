--[[

	Wrapper for a remote, allowing it to be used as a RemoteFunction

]]

local client_event_bridge = require(script.Parent.client_event_bridge)

local function create_remote_function<T...>(key: string, runtime: (T...) -> boolean)
	local event = client_event_bridge(key, "unordered", runtime)
	local self = {

		id = event.id,
		class_name = "Function",
	}

	local id = 0
	function self:invoke(...: T...)
		id = (id + 1) % 2 ^ 16
		local special_id = string.pack("H", id)

		event:fire_server(special_id, ...)

		local connection
		local thread = coroutine.running()

		connection = event.on_client_event:connect(function(received_id, packet)
			if special_id ~= received_id then return end

			connection:disconnect()
			coroutine.resume(thread, unpack(packet))
		end)

		return coroutine.yield()
	end

	return self
end

local cached = {}
return function(key, runtime)
	if cached[key] then return cached[key] end

	cached[key] = create_remote_function(key, runtime)
	return cached[key]
end
