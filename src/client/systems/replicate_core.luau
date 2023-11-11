local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local get_entity = require(script.Parent.Parent.get_entity)
local registry = require(script.Parent.Parent.registry)

local updated = ecr.queue(events.replicate_core_data.Event)

local function replicate_core()
	for actor_id, registries, schedulers in updated do
		for _, entry in registries do
			local name, id = entry.name, entry.id
			local ent = get_entity(actor_id, "client", id)

			registry:set(ent, cts.Name, name)
			registry:add(ent, cts.Registry)
		end

		for _, entry in schedulers do
			local name, id = entry.name, entry.id
			local ent = get_entity(actor_id, "client", id)

			registry:set(ent, cts.Name, name)
			registry:add(ent, cts.Scheduler)
		end
	end
end

return replicate_core
