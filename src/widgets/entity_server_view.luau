--[[

	Displays a widget containing all the entities on the client.

]]

local ecr = require(script.Parent.Parent.Parent.ecr)
local vide = require(script.Parent.Parent.Parent.vide)

local dynamic_ecs_query = require(script.Parent.Parent.dynamic_ecs_query)

local entity_client_view = require(script.Parent.entity_client_view)
local remotes = require(script.Parent.Parent.remotes)

local source = vide.source
local effect = vide.effect
local derive = vide.derive

local n = 0
return function(name: string, registry: number)
	local id_query = n
	local query = source("")
	local world = ecr.registry()

	n += 1
	-- update the server cts

	local parsed_query = derive(
		function() return dynamic_ecs_query.parse_ecs_query(query()) end
	)

	local destroy = vide.mount(function()
		effect(function()
			if parsed_query().ok == false then
				task.spawn(function()
					world:clear()
					remotes.set_query:InvokeServer(id_query, registry, "")
				end)
				return
			end

			task.spawn(function()
				world:clear()
				local new_ids, new_values =
					remotes.set_query:InvokeServer(id_query, registry, query())
				local query = parsed_query()
				assert(query.ok)

				for index, values in new_values do
					local id = new_ids[index]

					if not world:contains(id) then world:create(id) end

					for ctype_index, value in values do
						local ctype = query.included_no_tags[ctype_index]
						world:set(id, ctype, value)
					end
				end
			end)
		end)
	end)

	local connection = remotes.query_updated.OnClientEvent:Connect(
		function(server_query, id, data)
			if server_query ~= id_query then return end

			if data and not world:contains(id) then
				world:create(id)
			elseif not data and world:contains(id) then
				world:destroy(id)
				return
			end

			if not data then return end

			local query = parsed_query()
			assert(query.ok)

			for ctype_index, value in data do
				local ctype = query.included_no_tags[ctype_index]
				world:set(id, ctype, value)
			end
		end
	)

	return entity_client_view {

		query = query,
		world = { world = world, name = `{name} (server)` },
		cleanup = function()
			connection:Disconnect()
			remotes.set_query:InvokeServer(id_query, registry, "")
			destroy()
		end,
	}
end
