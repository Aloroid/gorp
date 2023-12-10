--[[

	contains a bunch of Events that you can listen to.

]]

local net = require(script.Parent.modules.net)

export type connector = net.connector

return {

	replicate_core_data = net.create_event("replicate_core_data"),
	replicate_components = net.create_event("replicate_components"),
	request_servers = net.create_event("request_servers"),

	get_new_replicated_query = net.create_callback("get_new_replicated_query"),
	stop_replicated_query = net.create_event("stop_query"),
	replicate_query_data = net.create_event("replicate_query_data"),
}
