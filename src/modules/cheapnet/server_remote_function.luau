--[[

	Wrapper for a remote, allowing it to be used as a RemoteFunction

]]

local server_event_bridge = require(script.Parent.server_event_bridge)

local function create_remote_function<T...>(key: string, runtime: (T...) -> boolean)
	local event = server_event_bridge(key, "unordered", runtime)
	local self = {

		id = event.id,
		class_name = "Function",

		on_invoke = function(...) return ... end,
	}

	local function process_packet(player: Player, id: string, ...: any)
		local function handle_error(err)
			task.spawn(error, debug.traceback("", 2))
		end

		local packet = { xpcall(self.on_invoke, handle_error, player, ...) }

		event:fire_clients(id, { unpack(packet, 2) }):include(player)
	end

	event.on_server_event:connect(process_packet)

	return self
end

local cached = {}
return function(key, runtime)
	if cached[key] then return cached[key] end

	cached[key] = create_remote_function(key, runtime)
	return cached[key]
end
