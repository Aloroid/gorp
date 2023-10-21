local RunService = game:GetService("RunService")
--[[

	Displays a widget containing all the entities on the client.

]]

local ecr = require(script.Parent.Parent.Parent.ecr)
local vide = require(script.Parent.Parent.Parent.vide)

local dynamic_ecs_query = require(script.Parent.Parent.dynamic_ecs_query)

local entity_client_view = require(script.Parent.entity_client_view)
local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)

local source = vide.source
local effect = vide.effect
local derive = vide.derive
local cleanup = vide.cleanup

local n = 0
return function(name: string, registry: number)
	local id_query = n
	local query = source("")
	local world = ecr.registry()

	local connections = {}

	n += 1
	-- update the server cts

	local parsed_query = derive(
		function() return dynamic_ecs_query.parse_ecs_query(query()) end
	)

	local function disconnect()
		for _, connection in
			connections :: { { disconnect: (any) -> (), reconnect: (any) -> () } }
		do
			connection:disconnect()
		end
	end

	local function reconnect()
		for _, connection in
			connections :: { { disconnect: (any) -> (), reconnect: (any) -> () } }
		do
			connection:reconnect()
		end
	end

	local function update_world(changed, removing)
		debug.profilebegin("updating world")
		local query = parsed_query()
		assert(query.ok)

		disconnect()

		for index, ctype_changed in changed do
			local ctype = query.included[index]
			if ctype == nil then
				warn("old packet?")
				continue
			end -- old packet

			disconnect()

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

		reconnect()

		debug.profileend()
	end

	local destroy = vide.mount(function()
		effect(function()
			if parsed_query().ok == false then
				task.spawn(function()
					disconnect()
					world:clear()
					reconnect()
					remotes.set_query:InvokeServer(id_query, registry, "")
				end)
				return
			end

			task.spawn(function()
				disconnect()
				world:clear()
				reconnect()
				local changed, removing =
					remotes.set_query:InvokeServer(id_query, registry, query())
				update_world(changed, removing)
			end)
		end)
	end)

	local changed = setmetatable({}, {
		__index = function(t, k)
			t[k] = {}
			return t[k]
		end,
	})
	local removing = setmetatable({}, {
		__index = function(t, k)
			t[k] = {}
			return t[k]
		end,
	})

	local query_changed = remotes.query_changed.OnClientEvent:Connect(
		function(server_query, changed, removing)
			if server_query ~= id_query then return end
			update_world(changed, removing)
		end
	)

	effect(function()
		cleanup(function()
			for _, connection in connections :: { { disconnect: (any) -> () } } do
				connection:disconnect()
			end
		end)

		for _, ctype in state.cts.keys() do
			local added = world:added(ctype):connect(function(id, value)
				changed[ctype][id] = value
				removing[ctype][id] = nil
			end)
			local changing = world:changed(ctype):connect(function(id, value)
				changed[ctype][id] = value
				removing[ctype][id] = nil
			end)
			local removing = world:removing(ctype):connect(function(id)
				changed[ctype][id] = nil
				removing[ctype][id] = true
			end)

			table.insert(connections, added)
			table.insert(connections, changing)
			table.insert(connections, removing)
		end
	end)

	local heartbeat = RunService.Heartbeat:Connect(function()
		local packets_changed = {}
		local packets_removing = {}

		local reverse = state.cts.reverse()

		for ctype, ids in changed :: any do
			local changed_ids = {}
			local changed_values = {}
			table.insert(packets_changed, {
				reverse[ctype],
				changed_ids,
				changed_values,
			} :: { any })

			for id, value in ids do
				table.insert(changed_ids, id)
				table.insert(changed_values, value)
			end
		end

		for ctype, ids in removing :: any do
			local removing = {}
			table.insert(packets_removing, {
				reverse[ctype],
				removing,
			} :: { any })
			for id in ids do
				table.insert(removing, id)
			end
		end

		remotes.update_entities:FireServer(
			registry,
			packets_changed,
			packets_removing
		)

		table.clear(changed :: any)
		table.clear(removing :: any)
	end)

	return entity_client_view {

		query = query,
		world = { world = world, name = `{name} (server)` },
		cleanup = function()
			disconnect()
			query_changed:Disconnect()
			heartbeat:Disconnect()
			remotes.set_query:InvokeServer(id_query, registry, "")
			destroy()
		end,

		_ignore_heuristic = true,
		function(id: number)
			local ctypes, values =
				remotes.get_all_entity_values:InvokeServer(registry, id)
			local entity = {}

			for index, ctype in ctypes do
				entity[ctype] = values[index]
			end

			return entity
		end,
	}
end
