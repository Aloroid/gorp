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
}

local function get_server_registries(player)
	if not state.can_use_debugger(player) then return {} end

	local keys = {}
	for _, entry in state.worlds() do
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
	elseif type(value) == "string" then
		return `"{value}"`
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

		for id in
			world:view(unpack(parsed.included)):exclude(unpack(parsed.excluded))
		do
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

return {

	get_server_registries = get_server_registries,
	set_query = set_query,
}
