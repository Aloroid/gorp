--[[

	contains a bunch of Events that you can listen to.

]]

local net = require(script.Parent.modules.net)

export type connector = net.connector

return {

	replicate_core_data = net.create_event("replicate_core_data"),
	replicate_components = net.create_event("replicate_components"),
	request_servers = net.create_event("request_servers"),
}
