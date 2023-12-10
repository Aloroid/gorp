local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local get_entity = require(script.Parent.Parent.get_entity)
local registry = require(script.Parent.Parent.registry)

local replicate_core_data = ecr.queue(events.replicate_core_data)

local function replicate_core()
	for connector, registries, schedulers in replicate_core_data:iter() do
		local namespace: "client" | "server" = if connector.player then "client" else "server"
		local actor_id = connector.from :: number
		for _, entry in registries do
			local name, id = entry.name, entry.id
			local ent = get_entity(actor_id, namespace, id)

			registry:set(ent, cts.Name, name)
			registry:add(ent, cts.Registry)
		end

		for _, entry in schedulers do
			local name, id = entry.name, entry.id
			local ent = get_entity(actor_id, namespace, id)

			registry:set(ent, cts.Name, name)
			registry:add(ent, cts.Scheduler)
		end
	end
end

return replicate_core
