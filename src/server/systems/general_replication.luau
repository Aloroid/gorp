local common_actor_id = require(script.Parent.Parent.Parent.common_actor_id)
local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)

local changed = {}
local removed = {}
local destroying = {}

for name, ctype in cts :: { [string]: any } do
	changed[ctype] = {}
	removed[ctype] = {}

	registry:added(ctype):connect(function(ent) changed[ctype][ent] = true end)

	registry
		:changed(ctype)
		:connect(function(ent) changed[ctype][ent] = true end)

	registry:removing(ctype):connect(function(ent)
		changed[ctype][ent] = nil
		removed[ctype][ent] = true
	end)
end

registry
	:removing(ecr.entity)
	:connect(function(ent) table.insert(destroying, ent) end)

local function general_replication()
	local changing_entities = {}
	local changing_values = {}
	local removing = {}

	for ctype, ents in changed do
		local values = {}
		local entities = {}

		local is_tag = ecr.is_tag(ctype) or ctype == cts.Registry

		for ent in ents do
			local value = registry:get(ent, ctype)
			if ctype == cts.Average then value = value:average() end

			table.insert(entities, ent)
			table.insert(values, if is_tag then true else value)
		end

		table.clear(ents)

		changing_entities[ctype] = entities
		changing_values[ctype] = values
	end

	for ctype, ents in removed do
		local entities = {}

		for ent in ents do
			table.insert(entities, ent)
		end

		table.clear(ents)

		removing[ctype] = entities
	end

	events.general_replication:Fire(
		common_actor_id,
		changing_entities,
		changing_values,
		removing,
		destroying
	)

	table.clear(destroying)
end

events.get_initial_state:SetInvoke(function()
	local changing_entities = {}
	local changing_values = {}

	for name, ctype in cts :: any do
		local values = {}
		local entities = {}
		local is_tag = ecr.is_tag(ctype) or ctype == cts.Registry

		for ent, value in registry:view(ctype) do
			table.insert(entities, ent)
			table.insert(values, if is_tag then true else value)
		end

		changing_entities[ctype] = entities
		changing_values[ctype] = values
	end

	return changing_entities, changing_values
end)

return general_replication
