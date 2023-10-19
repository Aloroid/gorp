local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ecr = require(script.Parent.ecr)
local group_hook = require(script.group_hook)
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
	group_hook(world)

	worlds(new_worlds)
end

-- allows the user to add a callback which would check if a user can or can't use the debugger.
-- this will be called on both the server and client.
local function check_if_user_allowed(callback: (player: Player) -> boolean)
	state.can_use_debugger = callback
end

-- spawns a new widget
type widgets = "entity_client_view" | "registry_selector"
local function spawn_widget(name: widgets)
	if state.can_use_debugger(Players.LocalPlayer) == false then return end
	local widget = (require :: any)(script.widgets:FindFirstChild(name))

	print("mounting", widget)
	vide.mount(
		function() return widget() end,
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
	remotes.check_if_permission.OnServerInvoke = function(player)
		return state.can_use_debugger(player)
	end

	require(script.server)
end

if RunService:IsClient() then
	-- get server cts
	local function update_cts(names)
		local map = state.cts.map()
		local ids = state.cts.ids()
		local keys = state.cts.keys()

		for name, server_ctype in names do
			local ctype = if keys[name] then keys[name] else ecr.component()
			map[server_ctype] = ctype
			ids[ctype] = name
		end

		state.cts.map(map)
		state.cts.ids(ids)
	end

	task.spawn(function()
		update_cts(remotes.get_server_cts:InvokeServer())
		remotes.update_server_cts.OnClientEvent:Connect(update_cts)
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
