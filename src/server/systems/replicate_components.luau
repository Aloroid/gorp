--[[

	Handles replication of components to a client

]]

local active_connectors = require(script.Parent.Parent.active_connectors)
local convert_dict = require(script.Parent.Parent.Parent.modules.convert_dict)
local events = require(script.Parent.Parent.events)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local server_state = require(script.Parent.Parent.server_state)

local components_updated = queue(events.components_updated)
local connector_connecting = queue(remotes.request_servers)

return function()
	local function replicate_components(connector: remotes.connector)
		remotes.replicate_components:fire(connector, convert_dict.serialize(server_state.ctypes))
	end

	for connector in connector_connecting:iter() do
		connector = reverse_connector(connector)
		replicate_components(connector)
	end

	for _ in components_updated:iter() do
		for connector in active_connectors.connected do
			replicate_components(connector)
		end
		break
	end
end
