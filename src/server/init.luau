--[[

	servers can be created across parallel instances and must provide a strong
	interface purely only through signals and functions for the client.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local common_actor_id = require(script.Parent.common_actor_id)
local events = require(script.events)
local generic_ecs_layer = require(script.Parent.generic_ecs_layer)
local remotes = require(script.Parent.remotes)
local scheduler = require(script.scheduler)
local server_state = require(script.server_state)
local traffic_check = require(script.Parent.modules.traffic_check)

local remove_active_connectors = require(script.systems.remove_active_connectors)
local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local replicate_entity = require(script.systems.replicate_entity)
local replicate_registry = require(script.systems.replicate_registry)
local replicate_scheduler = require(script.systems.replicate_scheduler)
local replicate_system_performance = require(script.systems.replicate_system_performance)

--- Adds the given world
local function add_world<T>(world: T, name: string?): T
	local default_name = `World {#server_state.registries}`
	world = generic_ecs_layer.on_hook_world(world)

	local entry = {
		name = name or default_name,
		world = world,
	}

	events.world_created:fire(entry)

	table.insert(server_state.registries, entry)
	return world
end

--- Adds all the components provided here
local function names<T>(components: T & { [string]: unknown }): T
	for name, ctype in components :: any do
		name = string.lower(name)
		local index = #server_state.ctype_index + 1

		server_state.ctype_index[index] = ctype
		server_state.ctype_names[name] = ctype
		server_state.map_ctype_index[ctype] = index
		server_state.ctype_index_names[name] = index
		server_state.ctypes[index] = name
	end

	events.components_updated:fire(true)
	return components
end

local function get_worlds()
	local worlds = {}
	for _, world in server_state.registries do
		table.insert(worlds, world.world)
	end
	return worlds
end

local function get_components()
	return {

		ctype_index = server_state.ctype_index,
		ctype_names = server_state.ctype_names,
		map_ctype_index = server_state.map_ctype_index,
		ctype_index_names = server_state.ctype_index_names,
		ctypes = server_state.ctypes,
	}
end

local server = {
	hook_world = add_world,
	get_worlds = get_worlds,
	get_components = get_components,
	names = names,
	scheduler = scheduler,
}

local server_scheduler = scheduler(`gorpserver:{common_actor_id}`)

RunService.Heartbeat:Connect(function()
	server_scheduler:system("remove_active_connectors", remove_active_connectors)
	server_scheduler:system("replicate_core", replicate_core)
	server_scheduler:system("replicate_components", replicate_components)
	server_scheduler:system("replicate_registry", replicate_registry)
	server_scheduler:system("replicate_scheduler", replicate_scheduler)
	server_scheduler:system("replicate_system_performance", replicate_system_performance)
	server_scheduler:system("replicate_entity", replicate_entity)

	server_scheduler:finish()
end)

task.spawn(function()
	-- we broadcast the existance of the server to everyone
	if RunService:IsServer() then
		for _, player in Players:GetPlayers() do
			if traffic_check.is_player_permitted(player) == false then continue end
			local connector = {
				namespace = "client" :: "client",
				player = player,
			}

			remotes.new_server:fire(connector)
		end
	else
		if traffic_check.is_player_permitted(Players.LocalPlayer) == false then return end
		local connector = {
			namespace = "client" :: "client",
		}

		remotes.new_server:fire(connector)
	end
end)

return server
