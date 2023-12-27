local convert_dict = require(script.Parent.Parent.Parent.modules.convert_dict)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local servers = require(script.Parent.Parent.servers)

local replicate_components = queue(remotes.replicate_components)

return function()
	for connector, components in replicate_components:iter() do
		connector = reverse_connector(connector)

		local namespace = connector.namespace
		local actor_id = connector.to :: number

		local server = servers[namespace][actor_id]

		local ctypes = convert_dict.deserialize(components) :: { [unknown]: string }

		table.clear(server.ctype_names)
		table.clear(server.ctypes)

		for ctype, name in ctypes do
			server.ctype_names[name] = ctype
			server.ctypes[ctype] = name
		end
	end
end
