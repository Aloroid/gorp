local Players = game:GetService("Players")

local rts = require(script.rts)
local state = require(script.state)
local vide = require(script.Parent.vide)

local worlds = state.worlds
local cts = state.cts

-- adds a world to the list of worlds.
local function add_world(world: rts.Registry, name: string?)
	local new_worlds = table.clone(worlds())

	table.insert(
		new_worlds,
		{ world = world, name = name or `Registry #{#new_worlds + 1}` }
	)

	worlds(new_worlds)
end

-- allows the user to add a callback which would check if a user can or can't use the debugger.
-- this will be called on both the server and client.
local function check_if_user_allowed(callback: (player: Player) -> boolean)
	state.can_use_debugger = callback
end

-- spawns a new widget
type widgets = "entity_client_view"
local function spawn_widget(name: widgets, props: { [any]: any })
	local widget = (require :: any)(script.widgets:FindFirstChild(name))

	vide.mount(
		function() return widget(props) end,
		Players.LocalPlayer:WaitForChild("PlayerGui")
	)
end

-- compatibility for ecr versions that didn't have ecr.get_names()
local function compat_set_cts(user_cts: { [string]: any })
	local clone = table.clone(cts.ids())

	for name, id in user_cts do
		clone[id] = name
	end

	cts.ids(clone)

	return user_cts
end

vide.strict = false

return {

	add_world = add_world,
	check_if_user_allowed = check_if_user_allowed,
	spawn_widget = spawn_widget,

	compat_set_cts = compat_set_cts,
}
