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

	local function update_world(changed, removing)
		debug.profilebegin("updating world")
		local query = parsed_query()
		assert(query.ok)

		for index, ctype_changed in changed do
			local ctype = query.included[index]
			if ctype == nil then
				warn("old packet?")
				continue
			end -- old packet

			if ecr.is_tag(ctype) then
				for change_index, id in ctype_changed[1] do
					if world:contains(id) == false then world:create(id) end
					world:add(id, ctype)
				end
			else
				for change_index, id in ctype_changed[1] do
					if world:contains(id) == false then world:create(id) end
					world:set(id, ctype, ctype_changed[2][change_index])
				end
			end
		end

		for _, id in removing do
			if world:contains(id) == false then continue end
			world:destroy(id)
		end
		debug.profileend()
	end

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
				local changed, removing =
					remotes.set_query:InvokeServer(id_query, registry, query())
				update_world(changed, removing)
			end)
		end)
	end)

	local query_changed = remotes.query_changed.OnClientEvent:Connect(
		function(server_query, changed, removing)
			if server_query ~= id_query then return end
			update_world(changed, removing)
		end
	)

	return entity_client_view {

		query = query,
		world = { world = world, name = `{name} (server)` },
		cleanup = function()
			query_changed:Disconnect()
			remotes.set_query:InvokeServer(id_query, registry, "")
			destroy()
		end,
	}
end
