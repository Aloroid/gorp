--[[

	contains a bunch of Events that you can listen to.

]]

local net = require(script.Parent.modules.net)

export type connector = net.connector

type Entity = unknown
type ComponentReference = number
type Value = unknown

type NetEvent<T...> = net.NetEvent<T...>
type NetCallback<T..., U...> = net.NetCallback<T..., U...>

type SchedulerPacket = {
	average_times: buffer,
	paused: buffer,
	system_order_changes: {
		[number]: { name: string, old: number, new: number } | { old: number },
	},
}

return {

	replicate_core_data = net.create_event("replicate_core_data"),
	replicate_components = net.create_event("replicate_components"),
	request_servers = net.create_event("request_servers"),
	new_server = net.create_event("new_server"),

	get_new_replicated_query = net.create_callback("get_new_replicated_query"),
	stop_replicated_query = net.create_event("stop_query"),
	replicate_query_data = net.create_event("replicate_query_data"),

	subscribe_scheduler = net.create_callback("subscribe_to_scheduler"),
	unsubscribe_scheduler = net.create_event("unsubscribe_to_scheduler"),
	replicate_scheduler = net.create_event("replicate_scheduler"),
	pause_system = net.create_event("pause_system"),

	subscribe_system = net.create_callback("subscribe_system"),
	unsubscribe_system = net.create_event("unsubscribe_system"),
	replicate_system_times = net.create_event("replicate_system_times", true),

	get_entity_data = net.create_callback("get_entity_data"),
	write_entity_data = net.create_event("write_entity_data"),
} :: {

	replicate_core_data: NetEvent<{ { name: string, id: number } }, { { name: string, id: number } }>,
	replicate_components: NetEvent<{ [ComponentReference]: string }>,
	request_servers: NetEvent<>,
	new_server: NetEvent<>,

	get_new_replicated_query: NetCallback<(string, number), (number)>,
	stop_replicated_query: NetEvent<number>,
	replicate_query_data: NetEvent<number, { { any } }, { number }>,

	subscribe_scheduler: NetCallback<(number), (number)>,
	unsubscribe_scheduler: NetEvent<number>,
	replicate_scheduler: NetEvent<number, SchedulerPacket>,
	pause_system: NetEvent<number, string, boolean>,

	--- Requests to subscribe to a specific system and returns a subscription id which can be used to cancel
	--- (scheduler_id: number, system_name: string) -> (subscription_id: number)
	subscribe_system: NetCallback<(number, string), (number)>,
	--- Requests to cancel the given subscription id for a system subscription
	unsubscribe_system: NetEvent<(number)>,
	--- Gives us the active subscription_id and the associated system's time that it took to run for the last frame.
	--- (packet: buffer)
	replicate_system_times: NetEvent<(buffer, { { any } })>,

	get_entity_data: NetCallback<(number, Entity), ({ ComponentReference }, { Value })>,
	write_entity_data: NetEvent<(number, Entity, { ComponentReference }, { Value })>,
}
