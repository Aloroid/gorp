local cts = require(script.Parent.Parent.cts)
local ecr7 = require(script.Parent.Parent.Parent.modules.ecr7)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local reverse_connector = require(script.Parent.Parent.reverse_connector)

local server_requested = ecr7.queue(events.request_servers)

local function update_receiving_targets()
	for connector in server_requested:iter() do
		local id = registry:create()
		registry:set(id, cts.Receiver, reverse_connector(connector))
	end
end

return update_receiving_targets
