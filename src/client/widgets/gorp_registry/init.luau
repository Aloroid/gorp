--[[

	wraps the registry_explorer widget

]]

local dynamic_ecs_query = require(script.Parent.Parent.Parent.modules.dynamic_ecs_query)
local registry_explorer = require(script.interface)
local remotes = require(script.Parent.Parent.Parent.remotes)
local servers = require(script.Parent.Parent.servers)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local derive = vide.derive
local effect = vide.effect
local cleanup = vide.cleanup

type Source<T> = vide.Source<T>

local function widget(namespace: "client" | "server", actor_id: number, registry_id: number, destroy: () -> ())
	local connector = {
		namespace = namespace,
		to = actor_id,
	}

	-- we get the component types
	local server = servers[namespace][actor_id]
	local map_names = server.ctype_names

	local previous_query_id = -1

	local current_raw_query = source("")
	local server_query_id = source(-1)

	-- aims to provide a minimal emulation of the world
	local ids: { [number]: number } = {}
	local world: Source<{ Source<{ unknown }> }> = source {}

	-- gets the index of an entity, or creates one if it doesn't exist
	local function get_entity_index(id: number)
		if ids[id] then return ids[id] end
		local index = #world() + 1

		world()[index] = source { id }
		ids[id] = index

		world(world())

		return index
	end

	-- performs swap removal
	local function destroy_entity(id: number)
		if not ids[id] then return end

		local index = ids[id]
		local highest = world()[#world()]
		local highest_id = highest()[1] :: number

		ids[highest_id] = index
		world()[index] = highest
		world()[#world()] = nil

		world(world())
	end

	local parsed_query = derive(function()
		return dynamic_ecs_query(current_raw_query(), map_names)
	end)

	effect(function()
		local query = current_raw_query()
		local parsed = parsed_query()

		-- kill the query on the server and remove any existing data
		if previous_query_id ~= -1 then
			remotes.stop_replicated_query:fire(connector, previous_query_id)
			table.clear(ids)

			world({})
		end

		previous_query_id = -1
		server_query_id(-1)

		task.spawn(function()
			-- if the query is invalid, the query_id will be -1. this is for types
			server_query_id(
				if parsed.ok == false
					then -1
					else remotes.get_new_replicated_query:invoke(connector, query, registry_id)
			)
			previous_query_id = server_query_id()

			print("received new query id", server_query_id())
		end)
	end)

	-- updates the internal registry to reflect the current world
	cleanup(remotes.replicate_query_data:connect(function(connector, query_id, all_changes, destroying)
		local inbound_namespace = connector.player and "client" or "server"

		if server_query_id() == -1 then task.wait() end -- yield a little so that the other packet gets processed first

		print("received new packet from", connector, query_id, "current query is", server_query_id())

		if namespace ~= inbound_namespace then return end
		if connector.from ~= actor_id then return end
		if server_query_id() ~= query_id then return end

		local parsed = parsed_query()
		if not parsed.ok then return end

		for _, changes in all_changes do
			local server_ctype, entities, values = changes[1], changes[2], changes[3]
			local ctype_index = table.find(parsed.included, server_ctype)

			if ctype_index == nil then continue end

			for index, entity in entities do
				local value = values[index]
				local entity = world()[get_entity_index(entity)]

				entity()[ctype_index + 1] = value
				print(entity())
				entity(entity())
			end
		end

		--[[for _, removing in all_removing do
			local server_ctype, entities = removing[1], removing[2]

			for index, entity in entities do
				if world:contains(entity) == false then continue end

				world:remove(entity, server_ctype)
			end
		end]]

		for _, entity in destroying do
			destroy_entity(entity)
		end

		print("received replication packet", world())
	end))

	return registry_explorer {

		query = current_raw_query,
		set_query = function(new_query: string)
			current_raw_query(new_query)
			return current_raw_query()
		end,

		world = world,
		registry_name = server.registries[registry_id].name,

		cts = map_names,

		on_click_field = function() end,

		on_cleanup = destroy,
	}
end

return function(namespace: "client" | "server", actor_id: number, registry_id: number)
	return vide.root(function(destroy)
		return widget(namespace, actor_id, registry_id, destroy)
	end)
end
