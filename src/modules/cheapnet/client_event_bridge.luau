local efficient_pack_int = require(script.Parent.efficient_pack_int)
local identifier_create = require(script.Parent.identifier_create)
local network_queue = require(script.Parent.network_queue)
local signal = require(script.Parent.Parent.signal)
local stored_bridges = require(script.Parent.stored_bridges)
local timestamps = require(script.Parent.timestamps)

type Signal<T...> = signal.Signal<T...>
type behavior =
	"ordered"
	| "unordered"
	| "unreliable"
	| "unreliable_drop_old_packets"

local function unpack_packet(packet: any)
	if type(packet) == "table" then
		return unpack(packet)
	else
		return packet
	end
end

local function pack_packet(...)
	local a = ...

	if select("#", ...) ~= 1 or a == nil or type(a) == "table" then
		return { ... }
	else
		return a
	end
end

local function create_client_bridge<T...>(key, behavior: behavior?)
	local id =
		efficient_pack_int.unpack(identifier_create("event", key, true), true)
	local signal: Signal<T...>, fire = signal()

	local self = {

		id = id,
		class_name = "Event",

		on_client_event = signal,
		behavior = behavior or "unordered" :: behavior,
	}

	stored_bridges[id + 1] = self

	function self:fire_server(...)
		local packet = pack_packet(...)

		network_queue.client_send_packet(self.behavior, id, packet)
	end

	local latest = 0
	function self:_receive_packet(timestamp: number, packet: any)
		if behavior == "unreliable_drop_old_packets" then
			if latest > timestamp then return end
			latest = timestamp
		end

		timestamps.set_timestamp(timestamp)
		fire(unpack_packet(packet))
		timestamps.set_timestamp(0)
	end

	return table.freeze(self)
end

local cached = {}
return function<T...>(
	key,
	behavior,
	runtime: ((...any) -> (true, T...) | false)?
): typeof(create_client_bridge())
	if cached[key] then
		assert(
			cached[key].behavior == behavior or behavior == nil,
			`behavior does not match the existing behavior of "{cached[key]}"`
		)
		return cached[key]
	end

	cached[key] = create_client_bridge(key, behavior)
	return cached[key]
end
