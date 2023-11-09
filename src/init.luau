local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ecr = require(script.Parent.ecr)
local group_hook = require(script.group_hook)
local register_custom_widget = require(script.register_custom_widget)
local remotes = require(script.remotes)
local rts = require(script.rts)
local scheduler = require(script.scheduler)
local state = require(script.state)
local vide = require(script.Parent.vide)

-- adds a world to the list of worlds.
local function add_world(world: rts.Registry, name: string?)
	local new_worlds = table.clone(state.worlds())
	local entry =
		{ world = world, name = name or `Registry #{#new_worlds + 1}` }

	table.insert(new_worlds, entry)

	state.current_client_world(entry)
	group_hook(world)

	state.worlds(new_worlds)

	if RunService:IsServer() then
		local id = SharedTable.increment(state.all_worlds, "size", 1)
		local actor = state.actor_id

		SharedTable.update(
			state.all_worlds.entries,
			id,
			function()
				return { name = name, index = #new_worlds, actor = actor }
			end
		)
	end
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

	vide.mount(
		function() return widget() end,
		Players.LocalPlayer:WaitForChild("PlayerGui")
	)
end

-- compatibility for ecr versions that didn't have ecr.get_names()
local function compat_set_cts<T>(user_cts: T & { [string]: any }): T
	local ids = state.cts.ids()
	local map = state.cts.map()
	local keys = state.cts.keys()
	local reverse = state.cts.reverse()

	for name, id in user_cts :: { [string]: any } do
		-- replace the server_ctype
		if keys[name] then
			local ctype = keys[name]
			local server_ctype = reverse[ctype]
			map[server_ctype] = id
			ids[ctype] = nil
		end

		ids[id] = name
	end

	state.cts.ids(ids)

	return user_cts
end

local function using_actor(actor: Actor?)
	state.actor = actor
	state.actor_id = SharedTable.increment(state.actors, "size", 1)

	if RunService:IsServer() then
		if not actor then
			remotes.check_if_permission.OnServerInvoke = function(player)
				return state.can_use_debugger(player)
			end
		end

		require(script.server)
	end
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

vide.strict = true

return {

	add_world = add_world,
	check_if_user_allowed = check_if_user_allowed,
	spawn_widget = spawn_widget,

	server_init = using_actor,

	compat_set_cts = compat_set_cts,
	enabled = state.enabled,
	scheduler = scheduler,

	register_custom_widget = register_custom_widget,

	state = state,
	components = {

		background = require(script.components.background),
		border = require(script.components.border),
		button = require(script.components.button),
		container = require(script.components.container),
		corner = require(script.components.corner),
		foreground = require(script.components.foreground),
		gap = require(script.components.gap),
		layout = require(script.components.layout),
		padding = require(script.components.padding),
		pane = require(script.components.pane),
		resizeable_bar = require(script.components.resizeable_bar),
		scroller = require(script.components.scroller),
		scrolling_frame = require(script.components.scrolling_frame),
		shadow = require(script.components.shadow),
		tabs = require(script.components.tabs),
		text = require(script.components.text),
		text_input = require(script.components.text_input),
		widget = require(script.components.widget),
	},
}
