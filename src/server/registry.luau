local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local dynamic_ecs_query = require(script.Parent.Parent.dynamic_ecs_query)
local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)

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

local players_receiving = {}
local function get_server_registries(player)
	if not state.can_use_debugger(player) then return {} end
	players_receiving[player] = true

	local keys = {}
	for _, entry in state.all_worlds.entries :: any do
		table.insert(keys, entry.name)
	end

	return keys
end

local set_queries = {}
local function remove_query(player: Player, id: number)
	if set_queries[player] == nil or set_queries[player][id] == nil then
		return
	end

	for _, connection in set_queries[player][id] do
		(connection :: any):disconnect()
	end
end

local function transform(value: any)
	if table.find(whitelisted_datatypes, typeof(value)) then
		return value
	else
		return tostring(value)
	end
end

local function set_query(player, query_id, index, query)
	if not state.can_use_debugger(player) then return {}, {} end

	remove_query(player, query_id)

	if query == "" then return {}, {} end

	local parsed = dynamic_ecs_query.parse_ecs_query(query)
	local world = state.worlds()[index].world

	assert(parsed.ok, "query is not valid")
	local new_query = dynamic_ecs_query.convert_ecs_query(parsed, world)

	-- contains everything that is changed
	local changed = {}
	local connections = {}
	local currently_replicated = {}

	for i, ctype in parsed.included do
		local function add(id)
			changed[id] = changed[id] or {}
			changed[id][i] = true
		end

		local ctype_changed = world:changed(ctype):connect(add)

		table.insert(connections, ctype_changed)
	end

	local function get_new_packet()
		debug.profilebegin("making new packet")
		local new_replicated = {}

		local removing = {} -- entities to be removed from list
		local changing = {} -- entities that has changed values

		for index in parsed.included do
			changing[index] = { {}, {} }
		end

		dynamic_ecs_query.invalidate_query(new_query)

		for _, id in dynamic_ecs_query.resolve_query(new_query) do
			new_replicated[id] = true

			if currently_replicated[id] then
				currently_replicated[id] = nil
				if changed[id] == nil then continue end
				-- go through each changed ctype

				for index in changed[id] do
					local ctype = parsed.included[index]

					table.insert(changing[index][1], id)
					table.insert(
						changing[index][2],
						transform(world:get(id, ctype))
					)
				end
			else
				currently_replicated[id] = nil
				-- new entity (woa)
				for index, ctype in parsed.included do
					table.insert(changing[index][1], id)
					table.insert(
						changing[index][2],
						transform(world:get(id, ctype))
					)
				end
			end
		end

		-- get all entities that must be removed from the registry
		for id in currently_replicated do
			table.insert(removing, id)
		end

		currently_replicated = new_replicated

		table.clear(changed)
		debug.profileend()
		return changing, removing
	end

	local i = 0
	local heartbeat = RunService.Heartbeat:Connect(function(delta_time)
		i += 1
		if i % 3 ~= 0 then return end -- replicate at 20 frames per second
		remotes.query_changed:FireClient(player, query_id, get_new_packet())
	end)

	table.insert(connections, heartbeat :: any)
	set_queries[player] = set_queries[player] or {}
	set_queries[player][query_id] = connections

	return get_new_packet()
end

local function update_entities(player, registry_index, changed, removing)
	if not state.can_use_debugger(player) then
		task.delay(math.random(7, 30), player.Kick, player)
		warn("unauthorized player tried modifying entities")
		return
	end

	local world = state.worlds()[registry_index].world
	assert(world)

	for _, changing in changed do
		local ctype, ids, values = unpack(changing)

		for index, id in ids do
			local value = values[index]
			--print("updated entity", id, ctype, value)
			world:set(id, ctype, value)
		end
	end

	for _, removing in removing do
		local ctype, ids = unpack(removing)

		for _, id in ids do
			world:remove(id, ctype)
		end
	end
end

local function get_all_entity_values(player, registry_index, entity)
	assert(state.can_use_debugger(player))

	local world = state.worlds()[registry_index].world
	assert(world and world:contains(entity), "entity or world is invalid")

	local ctypes = {}
	local values = {}
	for ctype in state.cts.ids() do
		if world:has(entity, ctype) then
			table.insert(ctypes, ctype)
			table.insert(values, world:get(entity, ctype))
		end
	end

	return ctypes, values
end

local old_size = state.all_worlds.size
RunService.Heartbeat:Connect(function()
	if old_size == state.all_worlds.size then return end

	local worlds = {}

	for i, entry in state.all_worlds.entries :: any do
		table.insert(worlds, entry.name)
	end

	for player in players_receiving do
		remotes.updated_server_registries:FireClient(player, worlds)
	end

	old_size = state.all_worlds.size
end)

Players.PlayerRemoving:Connect(
	function(player) players_receiving[player] = nil end
)

return {

	get_server_registries = get_server_registries,
	get_all_entity_values = get_all_entity_values,
	update_entities = update_entities,
	set_query = set_query,
}
