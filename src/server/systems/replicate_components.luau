local common_actor_id = require(script.Parent.Parent.Parent.common_actor_id)
local cts = require(script.Parent.Parent.cts)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)

local components = registry:track(cts.Components)

local function replicate_components()
	for id, new in components do
		events.replicate_components:Fire(common_actor_id, new)
	end
end

return replicate_components
