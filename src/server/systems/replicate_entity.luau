local generic_ecs_layer = require(script.Parent.Parent.Parent.generic_ecs_layer)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local server_state = require(script.Parent.Parent.server_state)

local write_entity_data = queue(remotes.write_entity_data)

return function()
	remotes.get_entity_data:set_callback(function(connector, registry_id, id)
		local registry = server_state.registries[registry_id]
		local components = generic_ecs_layer.get_all_components(registry.world, id)

		local keys = {}
		local values = {}

		for ctype, value in components do
			local index = server_state.map_ctype_index[ctype]
			table.insert(keys, index)
			table.insert(values, value)
		end

		return keys, values
	end)

	for _, registry, id, components, values in write_entity_data:iter() do
		local registry = server_state.registries[registry]
		local dict = {}

		for index, cindex in components do
			local ctype = server_state.ctype_index[cindex]
			dict[ctype] = values[index]
		end

		task.spawn(generic_ecs_layer.write, registry.world, id, dict)
	end
end
