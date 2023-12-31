local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local servers = require(script.Parent.Parent.servers)

local replicate_core_data = queue(remotes.replicate_core_data)

return function()
	for connector, registries, schedulers in replicate_core_data:iter() do
		connector = reverse_connector(connector)

		local namespace = connector.namespace
		local actor_id = connector.to :: number

		local server = servers[namespace][actor_id]

		-- create a new server
		if server == nil then
			--print("created server on the client for", namespace, actor_id)
			server = {
				actor_id = actor_id,

				ctype_names = {},
				ctypes = {},

				registries = {},
				schedulers = {},
			}
			servers[namespace][actor_id] = server
		end

		for _, entry in registries do
			server.registries[entry.id] = entry
		end

		for _, entry in schedulers do
			--print("creating scheduler", entry.id, actor_id, namespace)
			server.schedulers[entry.id] = entry
		end
	end
end
