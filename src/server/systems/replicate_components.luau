local common_actor_id = require(script.Parent.Parent.Parent.common_actor_id)
local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)

local components = registry:track(cts.Components)
local server_requested = ecr.queue(events.request_servers.Event)

registry:added(cts.Components):connect(print)
registry:changed(cts.Components):connect(print)

local function replicate_components()
	for id, new in components do
		events.replicate_components:Fire(common_actor_id, new)
	end

	for _ in server_requested do
		for id, new in registry:view(cts.Components) do
			events.replicate_components:Fire(common_actor_id, new)
		end
	end
end

return replicate_components
