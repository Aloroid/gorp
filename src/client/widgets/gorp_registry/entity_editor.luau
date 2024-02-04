local rbxjson = require(script.Parent.Parent.Parent.Parent.modules.rbxjson)
local remotes = require(script.Parent.Parent.Parent.Parent.remotes)
local servers = require(script.Parent.Parent.Parent.servers)
local text_editor = require(script.Parent.Parent.text_editor)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local source = vide.source

type props = {

	registry_id: number,
	entity: unknown,
	ctype: number?,

	connector: remotes.connector,
}

return function(props: props)
	local text = source("Waiting for entity data ...")
	local disabled = source(true)

	local connector = props.connector
	local desired_ctype = props.ctype
	local entity = props.entity
	local server = servers[connector.namespace][connector.to :: number]
	local initial_type

	task.defer(function()
		local components, values = remotes.get_entity_data:invoke(connector, props.registry_id, entity)

		if desired_ctype then
			local index = table.find(components, desired_ctype)

			if not index then
				text("unable to find component")
				return
			end

			local associated_value = values[index]

			initial_type = typeof(associated_value)
			text(rbxjson.prettify(rbxjson.encode(associated_value)))
			disabled(false)
		else
			local dict = {}

			for index, ctype in components do
				dict[server.ctypes[ctype]] = values[index]
			end

			text(rbxjson.prettify(rbxjson.encode(dict)))
			disabled(false)
		end
	end)

	text_editor {

		text = text,
		disabled = disabled,

		on_save = function(current: string)
			local decoded = rbxjson.decode(current, initial_type)
			if not decoded then return end

			if desired_ctype then
				remotes.write_entity_data:fire(connector, props.registry_id, entity, { desired_ctype }, { decoded })
			else
				local ctypes = {}
				local values = {}

				local index = 1
				for name, value in decoded do
					local ctype = server.ctype_names[name]

					ctypes[index] = ctype
					values[index] = value
					index += 1
				end

				remotes.write_entity_data:fire(connector, props.registry_id, entity, ctypes, values)
			end
		end,
	}
end
