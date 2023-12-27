--[[

	contains a bunch of Events that you can listen to.

]]

local net = require(script.Parent.modules.net)

export type connector = net.connector

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
}
