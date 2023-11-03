local efficient_pack_int = require(script.Parent.efficient_pack_int)
local filterable = require(script.Parent.filterable)
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

local function create_server_bridge<T...>(
	key,
	behavior: behavior?,
	runtime: ((T...) -> boolean)?
)
	local id = efficient_pack_int.unpack(identifier_create("event", key), true)
	local signal: Signal<(Player, T...)>, fire = signal()
	local typeguard = runtime or function() return true end :: never

	local self = {

		class_name = "Event",

		key = key,
		id = id,
		on_server_event = signal,
		behavior = behavior or "unordered" :: behavior,
	}

	stored_bridges[id + 1] = self

	self.on_server_event = signal

	function self:fire_clients(...)
		local filter = filterable()
		local packet = pack_packet(...)

		network_queue.server_send_packet_to(filter, self.behavior, id, packet)

		return filter
	end

	local latest = 0
	function self:_receive_packet(
		player: Player,
		timestamp: number,
		packet: any
	)
		local s, ok = pcall(typeguard, unpack_packet(packet))
		if not s and ok == true then return end
		if behavior == "unreliable_drop_old_packets" then
			if latest > timestamp then return end
			latest = timestamp
		end

		timestamps.set_timestamp(timestamp)
		fire(player, unpack_packet(packet))
		timestamps.set_timestamp(0)
	end

	return table.freeze(self)
end

local cached = {}
return function<T...>(
	key,
	behavior,
	runtime: ((...any) -> (true, T...) | false)?
): typeof(create_server_bridge())
	if cached[key] then
		assert(
			cached[key].behavior == behavior or behavior == nil,
			`behavior does not match the existing behavior of "{cached[key]}"`
		)
		return cached[key]
	end

	cached[key] = create_server_bridge(key, behavior, runtime)
	return cached[key]
end
