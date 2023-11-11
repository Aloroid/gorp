local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local servers = require(script.Parent.Parent.servers)

local updated = ecr.queue(events.replicate_components.Event)

local function replicate_components()
	for actor_id, components in updated do
		local context = servers["client"][actor_id]

		registry:set(context, cts.Components, components)
	end
end

return replicate_components
