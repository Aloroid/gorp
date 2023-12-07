--[[

	this system replicates the components to new connectors

]]

local cts = require(script.Parent.Parent.cts)
local ecr7 = require(script.Parent.Parent.Parent.modules.ecr7)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local reverse_connector = require(script.Parent.Parent.reverse_connector)

local components_updated = registry:track(cts.Components)
local server_requested = ecr7.queue(events.request_servers)

local function replicate_components()
	for id, new in components_updated:iter() do
		for _, connector in registry:view(cts.Receiver) do
			events.replicate_components:fire(connector, registry:get(ecr7.context, cts.Components))
		end
	end

	for connector in server_requested:iter() do
		events.replicate_components:fire(reverse_connector(connector), registry:get(ecr7.context, cts.Components))
	end
end

return replicate_components
