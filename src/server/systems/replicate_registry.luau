local Players = game:GetService("Players")

local dynamic_ecs_query = require(script.Parent.Parent.Parent.modules.dynamic_ecs_query)
local generic_ecs_layer = require(script.Parent.Parent.Parent.generic_ecs_layer)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local server_state = require(script.Parent.Parent.server_state)

local stop_replicated_query = queue(remotes.stop_replicated_query)
local player_removing = queue(Players.PlayerRemoving)

local unique_query_id = 0
local active_queries = {}
local associated_with = {}

-- whitelisted datatypes that can be sent over network raw.
local whitelisted_datatypes = {
	"Instance",
	"EnumItem",
	"boolean",
	"number",
	"UDim",
	"UDim2",
	"Ray",
	"Faces",
	"Axes",
	"BrickColor",
	"Color3",
	"Vector2",
	"Vector3",
	"Instance",
	"Vector2int16",
	"Vector3int16",
	"NumberSequenceKeypoint",
	"ColorSequenceKeypoint",
	"NumberRange",
	"Rect",
	"PhysicalProperties",
	"CFrame",
	"NumberSequence",
	"ColorSequence",
	"table",
}

local function transform(value: any)
	if table.find(whitelisted_datatypes, typeof(value)) then
		return value
	else
		return tostring(value)
	end
end

local function resolve_query(query: dynamic_ecs_query.ParsedECSQuery, world: unknown): { number }
	assert(query.ok, "query is not valid")

	local included_components = query.included
	local excluded_components = query.excluded
	local equal_components = query.equal
	local equal_values = query.equal_values

	if #included_components == 0 then return {} end

	local view = generic_ecs_layer.query(world, included_components, excluded_components)
	local ids = {}

	for id in view do
		local fail = false
		for i, ctype in equal_components do
			if not equal_values[i](generic_ecs_layer.get(world, id, ctype)) then
				fail = true
				break
			end
		end
		if fail then continue end
		table.insert(ids, id)
	end

	return ids
end

local function generate_update_callback(
	query: dynamic_ecs_query.ParsedECSQuery,
	connector: remotes.connector,
	query_id: number,
	world: unknown
)
	assert(query.ok, "query is not OK")

	local target = reverse_connector(connector)
	print(target, connector, query_id)

	local changed = {}
	local connections = {}
	local currently_replicated = {}

	for i, ctype in query.included do
		local function add(id)
			changed[id] = changed[id] or {}
			changed[id][i] = true
		end

		local disconnect = generic_ecs_layer.on_change(world, ctype, add)

		table.insert(connections, disconnect)
	end

	local function send_new_packet_to_client()
		debug.profilebegin("making new packet")
		local new_replicated = {}

		local removing = {} -- entities to be removed from list
		local changing = {} -- entities that has changed values
		local did_change = false

		for index, ctype in query.included do
			changing[index] = { server_state.map_ctype_index[ctype] :: any, {}, {} }
		end

		for _, id in resolve_query(query, world) do
			new_replicated[id] = true

			if currently_replicated[id] then
				currently_replicated[id] = nil
				if changed[id] == nil then continue end
				-- go through each changed ctype and add it to the list

				for index in changed[id] do
					did_change = true
					local ctype = query.included[index]

					table.insert(changing[index][2], id)
					table.insert(changing[index][3], transform(generic_ecs_layer.get(world, id, ctype)))
				end
			else
				currently_replicated[id] = nil
				-- a new entity has been added so we add that too
				for index, ctype in query.included do
					did_change = true
					table.insert(changing[index][2], id)
					table.insert(changing[index][3], transform(generic_ecs_layer.get(world, id, ctype)))
				end
			end
		end

		-- get all entities that must be removed from the registry
		for id in currently_replicated do
			did_change = true
			table.insert(removing, id)
		end

		currently_replicated = new_replicated

		table.clear(changed)

		if did_change then
			print("sending new packet", changing, removing)
			remotes.replicate_query_data:fire(target, query_id, changing, removing)
		end

		debug.profileend()
	end

	-- we return a function that you can call every frame
	return send_new_packet_to_client
end

return function()
	remotes.get_new_replicated_query:set_callback(function(connector, query: string, world_id: number)
		-- attempt to find the registry
		-- when we return -1, it indicates the replicated query is invalid.
		local entry = server_state.registries[world_id]

		if entry == nil then return -1 end

		local map_name_to_ctype = server_state.ctype_names

		-- parses the query and checks if its valid
		local parsed = dynamic_ecs_query(query, map_name_to_ctype)

		if parsed.ok == false then return -1 end

		unique_query_id += 1
		active_queries[unique_query_id] = generate_update_callback(parsed, connector, unique_query_id, entry.world)
		associated_with[unique_query_id] = connector
		return unique_query_id
	end)

	for connector, query_id in stop_replicated_query:iter() do
		-- just nil the active query
		print("stopped query", query_id)
		active_queries[query_id] = nil
		associated_with[query_id] = nil
	end

	-- whenever a player leaves remove any remaining queries related to them
	for player in player_removing:iter() do
		for query_id, connector in associated_with do
			if connector.player ~= player then continue end
			associated_with[query_id] = nil
			active_queries[query_id] = nil
		end
	end

	-- go through every active query and call it
	for query_id, update_callback in active_queries do
		update_callback()
	end
end
