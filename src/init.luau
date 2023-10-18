local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local dynamic_ecs_query = require(script.dynamic_ecs_query)
local remotes = require(script.remotes)
local rts = require(script.rts)
local scheduler = require(script.scheduler)
local state = require(script.state)
local vide = require(script.Parent.vide)

local worlds = state.worlds
local cts = state.cts

-- adds a world to the list of worlds.
local function add_world(world: rts.Registry, name: string?)
	local new_worlds = table.clone(worlds())
	local entry =
		{ world = world, name = name or `Registry #{#new_worlds + 1}` }

	table.insert(new_worlds, entry)

	state.current_client_world(entry)

	worlds(new_worlds)
end

-- allows the user to add a callback which would check if a user can or can't use the debugger.
-- this will be called on both the server and client.
local function check_if_user_allowed(callback: (player: Player) -> boolean)
	state.can_use_debugger = callback
end

-- spawns a new widget
type widgets = "entity_client_view" | "registry_selector"
local function spawn_widget(name: widgets, props: { [any]: any })
	if state.can_use_debugger(Players.LocalPlayer) == false then return end
	local widget = (require :: any)(script.widgets:FindFirstChild(name))

	vide.mount(
		function() return widget(props) end,
		Players.LocalPlayer:WaitForChild("PlayerGui")
	)
end

-- compatibility for ecr versions that didn't have ecr.get_names()
local function compat_set_cts<T>(user_cts: T & { [string]: any }): T
	local clone = table.clone(cts.ids())

	for name, id in user_cts :: any do
		clone[id] = name
	end

	cts.ids(clone)

	return user_cts
end

if RunService:IsServer() then
	remotes.check_if_permission.OnServerInvoke = state.can_use_debugger
	remotes.get_server_registries.OnServerInvoke = function(player)
		if not state.can_use_debugger(player) then return {} end

		local keys = {}
		for _, entry in worlds() do
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

	remotes.set_query.OnServerInvoke = function(player, query_id, index, query)
		if not state.can_use_debugger(player) then return {}, {} end

		remove_query(player, query_id)

		if query == "" then return {}, {} end

		local parsed = dynamic_ecs_query.parse_ecs_query(query)
		assert(parsed.ok, "query is not valid ?")
		local world = worlds()[index].world
		local observer = world
			:track(unpack(parsed.included))
			:exclude(unpack(parsed.excluded))

		local processed: { true } = {}
		local used_ids: { true } = {}

		local function get_data(id)
			local data = {}
			for i, value in { world:get(id, unpack(parsed.included_no_tags)) } do
				data[i] = tostring(value)
			end
			return data
		end

		set_queries[player] = set_queries[player] or {}
		set_queries[player][query_id] = {
			observer :: any,
			RunService.Heartbeat:Connect(function()
				for id in observer do
					used_ids[id] = true
					processed[id] = nil
					remotes.query_updated:FireClient(
						player,
						query_id,
						id,
						get_data(id)
					)
				end

				for id in processed do
					if
						world:has(id, unpack(parsed.included))
						and not world:has(id, unpack(parsed.excluded))
					then
						remotes.query_updated:FireClient(
							player,
							query_id,
							id,
							get_data(id)
						)
					elseif used_ids[id] then
						used_ids[id] = true
						remotes.query_updated:FireClient(player, query_id, id)
					end
				end

				processed = {}
			end),
		}

		for _, ctype in parsed.included do
			table.insert(
				set_queries[player][query_id],
				world
					:removing(ctype)
					:connect(function(id) processed[id] = true end)
			)
		end

		for _, ctype in parsed.excluded do
			table.insert(
				set_queries[player][query_id],
				world
					:added(ctype)
					:connect(function(id) processed[id] = true end)
			)

			table.insert(
				set_queries[player][query_id],
				world
					:removing(ctype)
					:connect(function(id) processed[id] = true end)
			)
		end

		local ids = {}
		local values = {}

		for id in
			world:view(unpack(parsed.included)):exclude(unpack(parsed.excluded))
		do
			used_ids[id] = true
			table.insert(ids, id)
			table.insert(values, get_data(id))
		end

		observer:clear()

		return ids, values
	end

	Players.PlayerRemoving:Connect(function(player)
		-- do something here to cleanup
		if set_queries[player] == nil then return end
		for id in set_queries[player] do
			remove_query(player, id)
		end

		set_queries[player] = nil
	end)
end

return {

	add_world = add_world,
	check_if_user_allowed = check_if_user_allowed,
	spawn_widget = spawn_widget,

	compat_set_cts = compat_set_cts,
	enabled = state.enabled,
	scheduler = scheduler,
}
