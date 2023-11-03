--[[

	The reason cheapnet is imported manually into gorp and not as a wally
	package is because it's modified slightly. Certain features may be added or
	removed from and to cheapnet.

	cheapnet is licensed under 0BSD
	
	Any changes that are made must be documented below here:

	03/11/2023 signal is now a external dependency
	03/11/2023 added class names
	03/11/2023 leaky_bucket is removed
		- dead code and likely unused.

]]

local RunService = game:GetService("RunService")

local client_bridge = require(script.client_event_bridge)
local client_remote_function = require(script.client_remote_function)
local efficient_pack_int = require(script.efficient_pack_int)
local filterable = require(script.filterable)
local get_identifier_namespace = require(script.get_identifier_namespace)
local identifier_create = require(script.identifier_create)
local identifier_get = require(script.identifier_get)
local packet_decoder = require(script.packet_decoder)
local packet_encoder = require(script.packet_encoder)
local server_bridge = require(script.server_event_bridge)
local server_remote_function = require(script.server_remote_function)
local signal = require(script.Parent.signal)
local timestamps = require(script.timestamps)

type Signal<T...> = signal.Signal<T...>
type behavior =
	"ordered"
	| "unordered"
	| "unreliable"
	| "unreliable_drop_old_packets"
export type Filterable = filterable.Filterable
export type Event<T...> = {

	id: number,
	class_name: "Event",
	behavior: behavior,

	on_client_event: Signal<T...>,
	on_server_event: Signal<(Player, T...)>,

	fire_server: (Event<T...>, T...) -> (),
	fire_clients: (Event<T...>, T...) -> Filterable,
}
export type Function<T..., U...> = {

	id: number,
	class_name: "Function",

	on_invoke: (Player, T...) -> U...,
	invoke: (Function<T..., U...>, T...) -> U...,
}

return {

	create_identifier = function(value: unknown, namespace: any?)
		return identifier_create(namespace or "_global", value)
	end,

	get_value = function(key: string, namespace: any?)
		return identifier_get(namespace or "_global", key)
	end,

	event = (if RunService:IsServer()
		then server_bridge :: any
		else client_bridge :: any) :: <T...>(
		key: any,
		behavior: behavior?,
		typecheck: ((T...) -> boolean)?
	) -> Event<T...>,
	r_function = (if RunService:IsServer()
		then server_remote_function :: any
		else client_remote_function :: any) :: <T..., U...>(
		key: any,
		typecheck: ((T...) -> boolean)?
	) -> Function<T..., U...>,

	pack = efficient_pack_int.pack,
	unpack = efficient_pack_int.unpack,

	timestamps = timestamps.timestamps,
	get_timestamp = timestamps.get_timestamp,

	player_warning = timestamps.invalid_timestamp,

	_private = {
		identifier_create = identifier_create,
		identifier_get = identifier_get,
		get_identifier_namespace = get_identifier_namespace,

		packet_encoder = packet_encoder,
		packet_decoder = packet_decoder,

		filterable = filterable,
	},
}
