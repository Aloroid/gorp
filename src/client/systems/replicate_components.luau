local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local servers = require(script.Parent.Parent.servers)

local updated = ecr.queue(events.replicate_components)

local function replicate_components()
	for connector, components in updated:iter() do
		local context = servers[connector.namespace][connector.from]

		registry:set(context, cts.Components, components)
	end
end

return replicate_components
