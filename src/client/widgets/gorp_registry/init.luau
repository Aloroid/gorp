--[[

	wraps the registry_explorer widget

]]

local cts = require(script.Parent.Parent.cts)
local dynamic_ecs_query = require(script.Parent.Parent.Parent.modules.dynamic_ecs_query)
local ecr7 = require(script.Parent.Parent.Parent.modules.ecr7)
local events = require(script.Parent.Parent.Parent.events)
local get_entity = require(script.Parent.Parent.get_entity)
local registry = require(script.Parent.Parent.registry)
local registry_explorer = require(script.interface)
local servers = require(script.Parent.Parent.servers)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup

type Source<T> = vide.Source<T>

local cached_ctypes = setmetatable({}, {
	__index = function(self, n)
		assert(type(n) == "number", "key must be a number")
		self[n] = ecr7.component()
		return self[n]
	end,
})

return function(props: {
	registry_id: number,
})
	vide.root(function(destroy)
		local namespace: "client" | "server", actor_id, registry_id =
			registry:get(props.registry_id, cts.ReplicatedFrom :: any, cts.ActorId, cts.ServerId)

		local connector = {
			namespace = namespace,
			to = actor_id,
		}

		-- we create a world where the replicated data is put into
		local world = ecr7.registry()

		-- we get the component types
		local server_id = servers[namespace][actor_id]
		local server_ctypes = registry:get(server_id, cts.Components) -- static value from 0.8
		local map_ctypes = {} -- maps the server components to client components
		local map_keys = {}

		-- get the registry name
		local name = registry:get(get_entity(actor_id, namespace :: any, registry_id), cts.Name)

		for server_ctype, name in server_ctypes do
			map_ctypes[server_ctype] = cached_ctypes[server_ctype]
			map_keys[name] = cached_ctypes[server_ctype]
		end

		local previous_query_id = -1

		local current_raw_query = source("")
		local server_query_id = source(-1)

		effect(function()
			local query = current_raw_query()
			local parsed = dynamic_ecs_query.parse_ecs_query(query, map_keys, ecr7)

			-- kill the query on the server and remove any existing data
			if previous_query_id ~= -1 then
				events.stop_replicated_query:fire(connector, previous_query_id)
				world:clear()
			end

			previous_query_id = -1
			server_query_id(-1)

			task.spawn(function()
				-- if the query is invalid, the query_id will be -1. this is for types
				server_query_id(
					if parsed.ok == false
						then -1
						else events.get_new_replicated_query:invoke(connector, query, registry_id)
				)
				previous_query_id = server_query_id()

				print("received new query id", server_query_id())
			end)
		end)

		-- updates the internal registry to reflect the current world
		cleanup(events.replicate_query_data:connect(function(connector, query_id, all_changes, destroying)
			local inbound_namespace = connector.player and "client" or "server"
			if server_query_id() == -1 then task.wait() end -- yield a little so that the other packet gets processed first
			print("received new packet from", connector, query_id, "current query is", server_query_id())

			if namespace ~= inbound_namespace then return end
			if connector.from ~= actor_id then return end
			if server_query_id() ~= query_id then return end

			for _, changes in all_changes do
				local server_ctype, entities, values = changes[1], changes[2], changes[3]
				local ctype = map_ctypes[server_ctype]

				print("received new packet", server_ctype, entities, values)

				for index, entity in entities do
					if world:contains(entity) == false then
						print("created new entity", entity)
						world:create(entity)
					end

					local value = values[index]
					world:set(entity, ctype, value)
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
				world:destroy(entity)
			end

			print("received replication packet")
		end))

		return registry_explorer {

			query = current_raw_query,
			set_query = function(new_query: string)
				current_raw_query(new_query)
				return current_raw_query()
			end,

			registry = world :: any,
			registry_name = name,

			cts = map_keys,

			on_click_field = function() end,

			on_cleanup = function() destroy() end,
		}
	end)
end
