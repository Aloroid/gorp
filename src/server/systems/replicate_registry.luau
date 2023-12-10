--[[

	When a client requests for a registry, we selectively select the entities to replicate and to not replicate

]]

local cts = require(script.Parent.Parent.cts)
local dynamic_ecs_query = require(script.Parent.Parent.Parent.modules.dynamic_ecs_query)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local ecr7 = require(script.Parent.Parent.Parent.modules.ecr7)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local reverse_connector = require(script.Parent.Parent.reverse_connector)
local rts = require(script.Parent.Parent.Parent.rts)

local stop_replicated_query = ecr7.queue(events.stop_replicated_query)

local unique_query_id = 0
local active_queries = {}

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

local function generate_update_callback(
	world: rts.Registry,
	parsed: dynamic_ecs_query.ParsedECSQuery,
	connector: events.connector,
	query_id: number
)
	assert(parsed.ok)

	local target = reverse_connector(connector)
	local query = dynamic_ecs_query.convert_ecs_query(parsed, world)

	local changed = {}
	local connections = {}
	local currently_replicated = {}

	for i, ctype in parsed.included do
		local function add(id)
			changed[id] = changed[id] or {}
			changed[id][i] = true
		end

		local ctype_changed = world:on_change(ctype):connect(add)

		table.insert(connections, ctype_changed)
	end

	local function send_new_packet_to_client()
		debug.profilebegin("making new packet")
		local new_replicated = {}

		local removing = {} -- entities to be removed from list
		local changing = {} -- entities that has changed values
		local did_change = false

		for index, ctype in parsed.included do
			changing[index] = { ctype :: any, {}, {} }
		end

		dynamic_ecs_query.invalidate_query(query)

		for _, id in dynamic_ecs_query.resolve_query(query) do
			new_replicated[id] = true

			if currently_replicated[id] then
				currently_replicated[id] = nil
				if changed[id] == nil then continue end
				-- go through each changed ctype and add it to the list

				for index in changed[id] do
					did_change = true
					local ctype = parsed.included[index]

					table.insert(changing[index][2], id)
					table.insert(changing[index][3], transform(world:get(id, ctype)))
				end
			else
				currently_replicated[id] = nil
				-- a new entity has been added so we add that too
				for index, ctype in parsed.included do
					did_change = true
					table.insert(changing[index][2], id)
					table.insert(changing[index][3], transform(world:get(id, ctype)))
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
			--print("sending new packet", changing, removing)
			events.replicate_query_data:fire(target, query_id, changing, removing)
		end

		debug.profileend()
	end

	-- we return a function that you can call every frame
	return send_new_packet_to_client
end

local function replicate_registry()
	events.get_new_replicated_query:set_callback(function(connector, query: string, world_id: number)
		-- attempt to find the registry. (might need to optimize this but whatever)
		local world = registry:try_get(world_id, cts.Registry)

		if world == nil then return -1 end

		local map_ctype_to_name = registry:get(ecr7.context, cts.Components)
		-- convert to keys
		local map_name_to_ctype = {}

		for ctype, name in map_ctype_to_name do
			map_name_to_ctype[name] = ctype
		end

		-- parses the query and checks if its valid
		local parsed = dynamic_ecs_query.parse_ecs_query(query, map_name_to_ctype, ecr)

		if parsed.ok == false then return -1 end

		unique_query_id += 1
		active_queries[unique_query_id] = generate_update_callback(world, parsed, connector, unique_query_id)
		print("returning query")
		return unique_query_id
	end)

	for connector, query_id in stop_replicated_query:iter() do
		-- just nil the active query
		print("stopped query", query_id)
		active_queries[query_id] = nil
	end

	-- go through every active query and call it
	for query_id, update_callback in active_queries do
		update_callback()
	end
end

return replicate_registry
