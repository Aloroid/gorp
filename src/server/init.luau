--[[

	servers can be created across parallel instances and must provide a strong
	interface purely only through signals and functions for the client.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local common_actor_id = require(script.Parent.common_actor_id)
local components = require(script.components)
local cts = require(script.cts)
local events = require(script.Parent.events)
local registry = require(script.registry)
local rts = require(script.Parent.rts)
local scheduler = require(script.scheduler)
local traffic_check = require(script.Parent.modules.traffic_check)

local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local replicate_registry = require(script.systems.replicate_registry)
local update_receiving_targets = require(script.systems.update_receiving_targets)

local function add_world(world: rts.Registry, name: string?)
	local ent = registry:create()
	local default_name = `Registry {common_actor_id}:{#registry:view(cts.Registry) + 1}`

	registry:set(ent, cts.Name, name or default_name)
	registry:set(ent, cts.Registry, world)
	return ent
end

local server = {
	hook_world = add_world,
	names = components.names,
	scheduler = scheduler,
}

local server_scheduler = scheduler(`gorpserver:{common_actor_id}`)

RunService.Heartbeat:Connect(function()
	server_scheduler:system("replicate_core", replicate_core)
	server_scheduler:system("replicate_components", replicate_components)
	server_scheduler:system("update_receiving_targets", update_receiving_targets)
	server_scheduler:system("replicate_registry", replicate_registry)
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

			events.new_server:fire(connector)
		end
	else
		if traffic_check.is_player_permitted(Players.LocalPlayer) == false then return end
		local connector = {
			namespace = "client" :: "client",
		}

		events.new_server:fire(connector)
	end
end)

return server
